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

struct COMPILER_OPTIONS {
    int options;
};

typedef struct {
    char *filename;
    CIF *cif;
    COMPILER_OPTIONS *options;
} CIF_COMPILER;

typedef enum {
    DO_NOT_UNPREFIX_TEXT = 1,
    DO_NOT_UNFOLD_TEXT   = 2,
    FIX_ERRORS           = 4,
    FIX_DUPLICATE_TAGS_WITH_SAME_VALUES  = 8,
    FIX_DUPLICATE_TAGS_WITH_EMPTY_VALUES = 16,
    FIX_DATA_HEADER      = 32,
    FIX_DATABLOCK_NAMES  = 64,
    FIX_STRING_QUOTES    = 128,
} compiler_option;

COMPILER_OPTIONS *new_compiler_options( cexception_t *ex )
{
    COMPILER_OPTIONS *co = callocx( 1, sizeof(COMPILER_OPTIONS), ex );
    co->options = 0;
    /* Setting of default options should be done here */
    return co;
}

static void delete_cif_compiler( CIF_COMPILER *c )
{
    if( c ) {
        if( c->filename ) free( c->filename );
        if( c->cif ) delete_cif( c->cif );
        free( c );
    }
}

static CIF_COMPILER *new_cif_compiler( char *filename,
                                       COMPILER_OPTIONS *co,
                                       cexception_t *ex )
{
    cexception_t inner;
    CIF_COMPILER *cc = callocx( 1, sizeof(CIF_COMPILER), ex );
    if( co == NULL ) {
        co = new_compiler_options( ex );
    }

    cexception_guard( inner ) {
        cc->options  = co;
        if( filename ) {
            cc->filename = strdupx( filename, &inner );
        }
        cc->cif = new_cif( &inner );
    }
    cexception_catch {
        delete_cif_compiler( cc );
        cexception_reraise( inner, ex );
    }
    cif_yy_reset_error_count();
    return cc;
}

static CIF_COMPILER * volatile cif_cc;

static cexception_t *px; /* parser exception */

void assert_datablock_exists( cexception_t *ex );
void add_tag_value( char * tag, char * value, cif_value_type_t type,
    cexception_t *ex );

int isset_do_not_unprefix_text( COMPILER_OPTIONS * co );
int isset_do_not_unfold_text( COMPILER_OPTIONS * co );
int isset_fix_errors( COMPILER_OPTIONS * co );
int isset_fix_duplicate_tags_with_same_values( COMPILER_OPTIONS * co );
int isset_fix_duplicate_tags_with_empty_values( COMPILER_OPTIONS * co );
int isset_fix_data_header( COMPILER_OPTIONS * co );
int isset_fix_datablock_names( COMPILER_OPTIONS * co );
int isset_fix_string_quotes( COMPILER_OPTIONS * co );

%}

%union {
    char *s;
    struct {
        char *vstr;
        cif_value_type_t vtype;
    } typed_value;
}

%token <s> _DATA_
%token _SAVE_HEAD
%token _SAVE_FOOT
%token <s> _TAG
%token _LOOP_
%token <s> _DQSTRING
%token <s> _SQSTRING
%token <s> _UQSTRING
%token <s> _TEXT_FIELD
%token <s> _INTEGER_CONST
%token <s> _REAL_CONST

%type <s> data_block_head
%type <typed_value> cif_value_list
%type <typed_value> cif_value;
%type <typed_value> number
%type <typed_value> string
%type <typed_value> textfield

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
        {
            if( isset_fix_errors( cif_cc->options ) ||
                isset_fix_data_header( cif_cc->options ) ) {
                    yynote( "warning: stray CIF values at the "
                            "beginning of the input file" );
            } else {
                    yywarning( "stray CIF values at the "
                               "beginning of the input file" );
            }
        }
        | cif_value
        {
            if( isset_fix_errors( cif_cc->options ) ||
                isset_fix_data_header( cif_cc->options ) ) {
                    yynote( "warning, stray CIF values at the "
                            "beginning of the input file" );
            } else {
                    yywarning( "stray CIF values at the "
                               "beginning of the input file" );
            }
        }
        cif_value_list
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
        {
            cif_start_datablock( cif_cc->cif, $1, px );
        }
	|	_DATA_ cif_value_list
        {
            char buf[strlen($1)+strlen($2.vstr)+2];
            strcpy( buf, $1 );
            buf[strlen($1)] = '_';
            int i;
            for( i = 0; i < strlen($2.vstr); i++ ) {
                if( $2.vstr[i] != ' ' ) {
                    buf[strlen($1)+1+i] = $2.vstr[i];
                } else {
                    buf[strlen($1)+1+i] = '_';
                } 
            }
            buf[strlen($1)+strlen($2.vstr)+1] = '\0';
            cif_start_datablock( cif_cc->cif, buf, px );
            if( !isset_fix_errors( cif_cc->options ) &&
                !isset_fix_datablock_names( cif_cc->options ) ) {
                yyerror_previous( "syntax error:" );
            }
            if( isset_fix_errors( cif_cc->options ) ||
                isset_fix_string_quotes( cif_cc->options ) ) {
                yynote( "warning, the dataname apparently had spaces "
                        "in it - replaced spaces by underscores" );
            }
        }
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
        {
            assert_datablock_exists( px );
            add_tag_value( $1, $2.vstr, $2.vtype, px );
        }
        | _TAG cif_value cif_value_list
    	    {
                assert_datablock_exists( px );
                if( isset_fix_errors( cif_cc->options ) ||
                    isset_fix_string_quotes( cif_cc->options ) ) {
                    yynote( "warning, string with spaces without quotes" );
                    char *buf = mallocx(strlen($2.vstr)+strlen($3.vstr)+2,px);
                    buf = strcpy( buf, $2.vstr );
                    buf = strcat( buf, " \0" );
                    buf = strcat( buf, $3.vstr );
                    add_tag_value( $1, buf, CIF_SQSTRING, px );
                } else {
                    yyerror_previous( "syntax error:" );
                }
            }
;

cif_value_list
        :       cif_value
        {
            $$.vstr  = $1.vstr;
            $$.vtype = $1.vtype;
        }
        |       cif_value_list cif_value
        {
            char *buf = mallocx( strlen($1.vstr) + strlen($2.vstr) + 2, px );
            buf = strcpy( buf, $1.vstr );
            buf = strcat( buf, " \0" );
            buf = strcat( buf, $2.vstr );
            $$.vstr  = buf;
            $$.vtype = CIF_UNKNOWN;
        }
;

loop
       :	_LOOP_ 
       {
           cif_start_loop( cif_cc->cif, px );
       } 
       loop_tags loop_values
       {
           cif_finish_loop( cif_cc->cif, px );
       } 
       ;

loop_tags
	:	loop_tags _TAG
        {
            size_t tag_nr = cif_tag_index( cif_cc->cif, $2 );
            if( tag_nr != -1 ) {
                yywarning( cxprintf( "tag %s appears more than once", $2 ) );
            }
            cif_insert_value( cif_cc->cif, $2, NULL, CIF_UNKNOWN, px );
        }
	|	_TAG
        {
            size_t tag_nr = cif_tag_index( cif_cc->cif, $1 );
            if( tag_nr != -1 ) {
                yywarning( cxprintf( "tag %s appears more than once", $1 ) );
            }
            cif_insert_value( cif_cc->cif, $1, NULL, CIF_UNKNOWN, px );
        }
;

loop_values
	:	loop_values cif_value
        {
            cif_push_loop_value( cif_cc->cif, $2.vstr, $2.vtype, px );
        }
	|	cif_value
        {
            cif_push_loop_value( cif_cc->cif, $1.vstr, $1.vtype, px );
        }
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
        { $$.vstr = $1; $$.vtype = CIF_SQSTRING; }
	|	_DQSTRING
        { $$.vstr = $1; $$.vtype = CIF_DQSTRING; }
	|	_UQSTRING
        { $$.vstr = $1; $$.vtype = CIF_UQSTRING; }
;

textfield
        :	_TEXT_FIELD
        { $$.vstr = $1;
          if( isset_do_not_unprefix_text( cif_cc->options ) == 0 ) {
              $$.vstr = cif_unprefix_textfield( $$.vstr );
          }
          if( isset_do_not_unfold_text( cif_cc->options ) == 0 &&
              $$.vstr[0] == '\\' ) {
              $$.vstr = cif_unfold_textfield( $$.vstr );
          }
          $$.vtype = CIF_TEXT; }
;

number
	:	_REAL_CONST
        { $$.vstr = $1; $$.vtype = CIF_FLOAT; }
	|	_INTEGER_CONST
        { $$.vstr = $1; $$.vtype = CIF_INT; }
;

%%

static void cif_compile_file( char *filename, cexception_t *ex )
{
    cexception_t inner;

    cexception_guard( inner ) {
        if( filename ) {
            yyin = fopenx( filename, "r", ex );
        }
        px = &inner; /* catch all parser-generated exceptions */
        if( yyparse() != 0 ) {
            int errcount = cif_yy_error_number();
            cexception_raise( &inner, CIF_UNRECOVERABLE_ERROR,
                cxprintf( "compiler could not recover "
                    "from errors, quitting now\n"
                    "%d error(s) detected\n",
                    errcount ));
        }
    }
    cexception_catch {
        if( yyin ) fclosex( yyin, ex );
	    cexception_reraise( inner, ex );
    }
    fclosex( yyin, ex );
}

CIF *new_cif_from_cif_file( char *filename, COMPILER_OPTIONS * co, cexception_t *ex )
{
    volatile int nerrors;
    cexception_t inner;
    CIF * volatile cif = NULL;
    extern void yyrestart();

    assert( !cif_cc );
    cif_cc = new_cif_compiler( filename, co, ex );
    cif_flex_reset_counters();

    cexception_guard( inner ) {
        cif_compile_file( filename, &inner );
        nerrors = cif_yy_error_number();
    }
    cexception_catch {
        delete_cif_compiler( cif_cc );
        cif_cc = NULL;
        yyrestart();
        cexception_reraise( inner, ex );
    }

    cif = cif_cc->cif;
    cif_cc->cif = NULL;
    delete_cif_compiler( cif_cc );
    cif_cc = NULL;

    if( cif && nerrors > 0 ) {
        cif_set_nerrors( cif, nerrors );
    }

    return cif;
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

char * cif_unprefix_textfield( char * tf )
{
    int length = strlen(tf);
    char * unprefixed = malloc( (length + 1) * sizeof( char ) );
    char * src = tf;
    char * dest = unprefixed;
    int prefix_length = 0;
    int is_prefix = 0;
    while(  src[0] != '\n' && src[0] != '\0' ) {
        if( src[0] != '\\' ) {
            prefix_length++;
            dest[0] = src[0];
            src++;
            dest++;
        } else {
            if( prefix_length > 0 &&
                ( src[1] == '\n' ||
                    ( src[1] == '\\' && src[2] == '\n' ) ) ) {
                is_prefix = 1;
                dest = unprefixed;
            } else {
                dest[0] = src[0];
                dest++;
            }
            src++;
            break;
        }
    }
    int unprefix_line =  is_prefix;
    int line_offset   = -1;
    while(  src[0] != '\0' ) {
        if( src[0] == '\n' ) {
            line_offset = -1;
            unprefix_line = is_prefix;
        }
        if( line_offset >= 0 && line_offset < prefix_length
            && unprefix_line == 1 ) {
            if( src[0] == tf[line_offset] ) {
                line_offset++;
                src++;
            } else {
                src-=line_offset;
                unprefix_line =  0;
                line_offset   = -1;
            }
        } else {
            dest[0] = src[0];
            src++;
            dest++;
            line_offset++;
        }
    }
    dest[0] = '\0';
    return unprefixed;
}

char * cif_unfold_textfield( char * tf )
{
    int length = strlen(tf);
    char * unfolded = malloc( (length + 1) * sizeof( char ) );
    char * src = tf;
    char * dest = unfolded;
    while(  src[0] != '\0' ) {
        if( src[0] == '\\' && src[1] == '\n' ) {
            src+=2;
        } else {
            dest[0] = src[0];
            src++;
            dest++;
        }
    }
    dest[0] = '\0';
    return unfolded;
}

int is_tag_value_unknown( char * tv )
{
    int question_mark = 0;
    char * iter = tv;
    while(  iter[0] != '\0' ) {
        if( iter[0] ==  '?' ) {
            question_mark = 1;
        } else if( iter[0] != ' '  &&
                   iter[0] != '\t' &&
                   iter[0] != '\r' &&
                   iter[0] != '\n' ) {
            return 0;
        }
        iter++;
    }
    return question_mark;
}

void assert_datablock_exists( cexception_t *ex )
{
    if( cif_last_datablock( cif_cc->cif ) == NULL ) {
        if( isset_fix_errors( cif_cc->options ) ||
            isset_fix_data_header( cif_cc->options ) ) {
                print_message( "warning, no data block heading (i.e. "
                               "data_somecif) found",
                                cif_flex_current_line_number() - 1, -1 );
                cif_start_datablock( cif_cc->cif, "", px );
            } else {
                print_message( "no data block heading (i.e. "
                               "data_somecif) found",
                                cif_flex_current_line_number() - 1, -1 );
                cexception_raise( px, CIF_UNRECOVERABLE_ERROR,
                    "no data block heading (i.e. "
                    "data_somecif) found" );
            }
    }
}

void add_tag_value( char * tag, char * value, cif_value_type_t type,
    cexception_t *ex ) {
    if( cif_tag_index( cif_cc->cif, tag ) == -1 ) {
        cif_insert_value( cif_cc->cif, tag, value, type, ex );
    } else {
        ssize_t tag_nr = cif_tag_index( cif_cc->cif, tag );
        ssize_t * value_lengths = 
            datablock_value_lengths(cif_last_datablock(cif_cc->cif));
        if( value_lengths[tag_nr] == 1) {
            if( strcmp(
                datablock_value( cif_last_datablock(cif_cc->cif), tag_nr, 0),
                value ) == 0 && (
                    isset_fix_errors(cif_cc->options) == 1 ||
                    isset_fix_duplicate_tags_with_same_values(cif_cc->options) == 1)) {
                    yynote( cxprintf( "warning, tag %s appears more than "
                                      "once with the same value", tag ) );
                } else {
                    if( isset_fix_errors(cif_cc->options) == 1 ||
                        isset_fix_duplicate_tags_with_empty_values(cif_cc->options) == 1 ) {
                        if( is_tag_value_unknown( value ) ) {
                            yynote(
                                    cxprintf( "warning, tag %s appears more "
                                              "than once, the second occurence "
                                              "'%s' is ignored",
                                              tag, value )
                                  );
                        } else if( is_tag_value_unknown(
                            datablock_value(cif_last_datablock(cif_cc->cif),
                            tag_nr, 0) ) ) {
                            yynote(
                                    cxprintf( "warning, tag %s appears more "
                                              "than once, the previous value "
                                              "'%s' is overwritten", tag,
                                        datablock_value(
                                            cif_last_datablock(cif_cc->cif),
                                            tag_nr, 0) )
                                  );
                            cif_overwrite_value( cif_cc->cif, tag_nr, 0,
                                                 value, type );
                        }
                    } else {
                        yywarning(
                            cxprintf( "tag %s appears more than once", tag )
                                 );
                    }
            }
        } else {
            yywarning( cxprintf( "tag %s appears more than once", tag ) );
        }
    }
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

void print_message( char *message, int line, int position )
{
    extern char *progname;
    fflush(NULL);
    if( strlen( progname ) > 0 ) {
        fprintf( stderr, "%s: %s", progname,
            cif_cc->filename );
    }
    if( line != -1 ) {
        fprintf( stderr, "(%d", line );
        if( position != -1 ) {
            fprintf( stderr, ",%d", position );
        }
        fprintf( stderr, ")" );
    }
    if( cif_cc->cif && cif_last_datablock( cif_cc->cif ) ) {
        fprintf( stderr, " data_%s",
            datablock_name( cif_last_datablock( cif_cc->cif ) ) );
    }
    fprintf( stderr, ": %s\n", message );
    fflush(NULL);
}

void print_current_trace( void ) {
    fflush(NULL);
    fprintf( stderr, "%s\n%*s\n",
            cif_flex_current_line(),
            cif_flex_current_position()+1, "^" );
    fflush(NULL);
}

void print_previous_trace( void ) {
    fflush(NULL);
    fprintf( stderr, "%s\n%*s\n",
            cif_flex_previous_line(),
            cif_flex_previous_position()+1, "^" );
    fflush(NULL);
}

int yyerror( char *message )
{
    print_message( message, cif_flex_current_line_number(),
                            cif_flex_current_position()+1 );
    print_current_trace();
    errcount++;
    return 0;
}

int yyerror_previous( char *message )
{
    print_message( message, cif_flex_previous_line_number(),
                            cif_flex_previous_position()+1 );
    print_previous_trace();
    errcount++;
    return 0;
}

int yynote( char *message )
{
    print_message( message, cif_flex_previous_line_number(), -1 );
    return 0;
}

void yyincrease_error_counter( void )
{
    errcount++;
}

int yywarning( char *message )
{
    yynote( message );
    errcount++;
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

void set_do_not_unprefix_text( COMPILER_OPTIONS * co )
{
    compiler_option copt = DO_NOT_UNPREFIX_TEXT;
    co->options |= copt;
}

void set_do_not_unfold_text( COMPILER_OPTIONS * co )
{
    compiler_option copt = DO_NOT_UNFOLD_TEXT;
    co->options |= copt;
}

void set_fix_errors( COMPILER_OPTIONS * co )
{
    set_lexer_fix_ctrl_z();
    set_lexer_fix_non_ascii_symbols();
    set_lexer_fix_missing_closing_double_quote();
    set_lexer_fix_missing_closing_single_quote();
    compiler_option copt = FIX_ERRORS;
    co->options |= copt;
}

void set_fix_duplicate_tags_with_same_values( COMPILER_OPTIONS * co )
{
    compiler_option copt = FIX_DUPLICATE_TAGS_WITH_SAME_VALUES;
    co->options |= copt;
}

void set_fix_duplicate_tags_with_empty_values( COMPILER_OPTIONS * co )
{
    compiler_option copt = FIX_DUPLICATE_TAGS_WITH_EMPTY_VALUES;
    co->options |= copt;
}

void set_fix_data_header( COMPILER_OPTIONS * co )
{
    compiler_option copt = FIX_DATA_HEADER;
    co->options |= copt;
}

void set_fix_datablock_names( COMPILER_OPTIONS * co )
{
    compiler_option copt = FIX_DATABLOCK_NAMES;
    co->options |= copt;
}

void set_fix_string_quotes( COMPILER_OPTIONS * co )
{
    compiler_option copt = FIX_STRING_QUOTES;
    co->options |= copt;
}

void set_fix_missing_closing_double_quote()
{
    set_lexer_fix_missing_closing_double_quote();
}

void set_fix_missing_closing_single_quote()
{
    set_lexer_fix_missing_closing_single_quote();
}

void set_fix_ctrl_z( void )
{
    set_lexer_fix_ctrl_z();
}

void set_fix_non_ascii_symbols( void )
{
    set_lexer_fix_non_ascii_symbols();
}

int isset_do_not_unprefix_text( COMPILER_OPTIONS * co )
{
    compiler_option copt = DO_NOT_UNPREFIX_TEXT;
    return ( ( co->options & copt ) != 0 );
}

int isset_do_not_unfold_text( COMPILER_OPTIONS * co )
{
    compiler_option copt = DO_NOT_UNFOLD_TEXT;
    return ( ( co->options & copt ) != 0 );
}

int isset_fix_errors( COMPILER_OPTIONS * co )
{
    compiler_option copt = FIX_ERRORS;
    return ( ( co->options & copt ) != 0 );
}

int isset_fix_duplicate_tags_with_same_values( COMPILER_OPTIONS * co )
{
    compiler_option copt = FIX_DUPLICATE_TAGS_WITH_SAME_VALUES;
    return ( ( co->options & copt ) != 0 );
}

int isset_fix_duplicate_tags_with_empty_values( COMPILER_OPTIONS * co )
{
    compiler_option copt = FIX_DUPLICATE_TAGS_WITH_EMPTY_VALUES;
    return ( ( co->options & copt ) != 0 );
}

int isset_fix_data_header( COMPILER_OPTIONS * co )
{
    compiler_option copt = FIX_DATA_HEADER;
    return ( ( co->options & copt ) != 0 );
}

int isset_fix_datablock_names( COMPILER_OPTIONS * co )
{
    compiler_option copt = FIX_DATABLOCK_NAMES;
    return ( ( co->options & copt ) != 0 );
}

int isset_fix_string_quotes( COMPILER_OPTIONS * co )
{
    compiler_option copt = FIX_STRING_QUOTES;
    return ( ( co->options & copt ) != 0 );
}
