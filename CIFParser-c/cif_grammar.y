/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

%{
/* exports: */
#include <cif_grammar_y.h>

/* uses: */
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <cexceptions.h>
#include <cxprintf.h>
#include <allocx.h>
#include <stringx.h>
#include <stdiox.h>
#include <cif_grammar_flex.h>
#include <yy.h>
#include <assert.h>

typedef struct {
    char *filename;
} CIF_COMPILER;

static void delete_cif_compiler( CIF_COMPILER *c )
{
    if( c ) {
        if( c->filename ) free( c->filename );
        free( c );
    }
}

static CIF_COMPILER *new_cif_compiler( char *filename,
                                       cexception_t *ex )
{
    cexception_t inner;
    CIF_COMPILER *cc = callocx( 1, sizeof(CIF_COMPILER), ex );

    cexception_guard( inner ) {
        if( filename ) {
            cc->filename = strdupx( filename, &inner );
        }
    }
    cexception_catch {
        delete_cif_compiler( cc );
        cexception_reraise( inner, ex );
    }
    return cc;
}

static CIF_COMPILER * volatile cif_cc;

static cexception_t *px; /* parser exception */

%}

%union {
    long i;
    double d;
    char *s;
    int token;           /* token value returned by lexer */
}

%token __IDENTIFIER
%token __STRING_CONST
%token __INTEGER_CONST
%token __REAL_CONST

%%

CIF
  :   {
      }
  ;

%%

static void cif_compile_file( char *filename, cexception_t *ex )
{
    cexception_t inner;

    cexception_guard( inner ) {
        yyin = fopenx( filename, "r", ex );
	if( yyparse() != 0 ) {
	    int errcount = cif_yy_error_number();
	    cexception_raise( &inner, CIF_UNRECOVERABLE_ERROR,
			      cxprintf( "compiler could not recover "
					"from errors, quitting now\n"
					"%d error(s) detected\n",
					errcount ));
	} else {
	    int errcount = cif_yy_error_number();
	    if( errcount != 0 ) {
	        cexception_raise( &inner, CIF_COMPILATION_ERROR,
				  cxprintf( "%d error(s) detected\n",
					    errcount ));
	    }
	}
    }
    cexception_catch {
        if( yyin ) fclosex( yyin, ex );
	cexception_reraise( inner, ex );
    }
    fclosex( yyin, ex );
}

CIF *new_cif_from_cif_file( char *filename, cexception_t *ex )
{
    CIF *code;

    assert( !cif_cc );
    cif_cc = new_cif_compiler( filename, ex );

    cif_compile_file( filename, ex );

    delete_cif_compiler( cif_cc );
    cif_cc = NULL;

    return code;
}

void cif_printf( cexception_t *ex, char *format, ... )
{
    cexception_t inner;
    va_list ap;

    va_start( ap, format );
    assert( format );
    assert( cif_cc );

    cexception_guard( inner ) {
        vprintf( format, ap );
    }
    cexception_catch {
	va_end( ap );
	cexception_reraise( inner, ex );
    }
    va_end( ap );
}

static int errcount = 0;

int cif_yy_error_number( void )
{
    return errcount;
}

void cif_yy_reset_error_count( void )
{
    errcount = 0;
}

int yyerror( char *message )
{
    extern char *progname;
    /* if( YYRECOVERING ) return; */
    errcount++;
    fflush(NULL);
    if( strcmp( message, "syntax error" ) == 0 ) {
	message = "incorrect syntax";
    }
    fprintf(stderr, "%s: %s(%d,%d): ERROR, %s\n", 
	    progname, cif_cc->filename,
	    cif_flex_current_line_number(),
	    cif_flex_current_position(),
	    message );
    fprintf(stderr, "%s\n", cif_flex_current_line() );
    fprintf(stderr, "%*s\n", cif_flex_current_position(), "^" );
    fflush(NULL);
    return 0;
}

int yywrap()
{
#if 0
    if( cif_cc->include_files ) {
	compiler_close_include_file( cif_cc, px );
	return 0;
    } else {
	return 1;
    }
#else
    return 1;
#endif
}

void cif_yy_debug_on( void )
{
#ifdef YYDEBUG
    yydebug = 1;
#endif
}

void cif_yy_debug_off( void )
{
#ifdef YYDEBUG
    yydebug = 0;
#endif
}
