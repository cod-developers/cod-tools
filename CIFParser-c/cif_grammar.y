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

#if 0
static cexception_t *px; /* parser exception */
#endif

%}

%union {
    long i;
    double d;
    char *s;
    int token;           /* token value returned by lexer */
}

%token <s> _DATA_
%token _SAVE_HEAD
%token _SAVE_FOOT
%token _TAG
%token _LOOP_
%token _DQSTRING
%token _SQSTRING
%token _UQSTRING
%token _TEXT_FIELD
%token _INTEGER_CONST
%token _REAL_CONST

%type <s> data_block_head

%%

cif_file
       :	// empty
	|	data_block_list
	|	headerless_data_block
	|	headerless_data_block data_block_list
	|	stray_cif_value_list
	|	stray_cif_value_list data_block_list
;

stray_cif_value_list
        : cif_value 
        | cif_value cif_value_list
;

//  cif_value_list
//      : cif_value
//      | cif_value_list cif_value
//  ;

data_block_list
	:	data_block_list data_block
	|	data_block
;

headerless_data_block
	:	data_item
		data_item_list
;

data_block
	:	data_block_head data_item_list
        {
            if( $1 == NULL ) {
                yywarning( "data block header has no data block name" );
            }
        }
        |       data_block_head //  empty data item list
        {
            if( $1 == NULL ) {
                yywarning( "data block header has no data block name" );
            }
        }
;

data_item_list
	:	data_item_list data_item
	|	data_item
;

data_block_head
	:	_DATA_
	|	_DATA_ cif_value_list
;

data_item
	:	save_item
	|	save_block
// 	|	error
;

save_item_list
	:	save_item_list save_item
	|	save_item
;

save_item
	:	cif_entry
	|	loop
;

cif_entry
	:	_TAG cif_value
        |       _TAG cif_value cif_value_list
	{
	    yywarning( "unterminated string" );
	}
;

cif_value_list
        :       cif_value
        |       cif_value_list cif_value
;

loop
    :	_LOOP_ loop_tags loop_values
;

loop_tags
	:	loop_tags _TAG
	|	_TAG
;

loop_values
	:	loop_values cif_value
	|	cif_value
;

save_block
	:	_SAVE_HEAD save_item_list _SAVE_FOOT
;

cif_value
	:	string
	|	number
	|	textfield
;

string
	:	_SQSTRING
	|	_DQSTRING
	|	_UQSTRING
;

textfield
        :	_TEXT_FIELD
;

number
	:	_REAL_CONST
	|	_INTEGER_CONST
;

%%

static void cif_compile_file( char *filename, cexception_t *ex )
{
    cexception_t inner;

    cexception_guard( inner ) {
        if( filename ) {
            yyin = fopenx( filename, "r", ex );
        }
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
    CIF *code = NULL;

    assert( !cif_cc );
    cif_cc = new_cif_compiler( filename, ex );
    cif_flex_reset_counters();

    cif_compile_file( filename, ex );

    if( cif_yy_error_number() == 0 ) {
        code = new_cif( ex );
    }

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

int yywarning( char *message )
{
    return yyerror( message );
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
