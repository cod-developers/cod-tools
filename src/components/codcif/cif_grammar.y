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
#include <cif_lexer.h>
#include <assert.h>

typedef struct CIF_COMPILER {
    char *filename;
    CIF *cif;
    cif_option_t options;
} CIF_COMPILER;

static void delete_cif_compiler( CIF_COMPILER *c )
{
    if( c ) {
        if( c->filename ) free( c->filename );
        if( c->cif ) delete_cif( c->cif );
        free( c );
    }
}

static CIF_COMPILER *new_cif_compiler( char *filename,
                                       cif_option_t co,
                                       cexception_t *ex )
{
    cexception_t inner;
    CIF_COMPILER *cc = callocx( 1, sizeof(CIF_COMPILER), ex );

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

static CIF_COMPILER * volatile cif_cc; /* CIF current compiler */

static cexception_t *px; /* parser exception */

void assert_datablock_exists( cexception_t *ex );
void add_tag_value( char * tag, char * value, cif_value_type_t type,
    cexception_t *ex );
int yyerror_previous( const char *message, cexception_t *ex );
int yyerror_token( const char *message, int line, int pos, cexception_t *ex );
int yywarning_token( const char *message, int line, int pos, cexception_t *ex );

int isset_do_not_unprefix_text( CIF_COMPILER *co );
int isset_do_not_unfold_text( CIF_COMPILER *co );
int isset_fix_errors( CIF_COMPILER *co );
int isset_fix_duplicate_tags_with_same_values( CIF_COMPILER *co );
int isset_fix_duplicate_tags_with_empty_values( CIF_COMPILER *co );
int isset_fix_data_header( CIF_COMPILER *co );
int isset_fix_datablock_names( CIF_COMPILER *co );
int isset_fix_string_quotes( CIF_COMPILER *co );

int loop_tag_count = 0;
int loop_value_count = 0;
int loop_start = 0;

typedef struct typed_value {
    char *vstr;
    cif_value_type_t vtype;
    int vline;
    int vpos;
} typed_value;

void free_typed_value( typed_value t );

%}

%union {
    char *s;
    typed_value typed_value;
}

%token <s> _DATA_
%token <s> _SAVE_HEAD
%token _SAVE_FOOT
%token <s> _TAG
%token <s> _LOOP_
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
            if( isset_fix_errors( cif_cc ) ||
                isset_fix_data_header( cif_cc ) ) {
                    print_message( "WARNING", "stray CIF values at the "
                                   "beginning of the input file", "",
                                   $1.vline, -1, px );
            } else {
                    print_message( "ERROR", "stray CIF values at the "
                                   "beginning of the input file", "",
                                   $1.vline, -1, px );
                    yyincrease_error_counter();
            }
            free_typed_value( $1 );
        }
        | cif_value cif_value_list
        {
            if( isset_fix_errors( cif_cc ) ||
                isset_fix_data_header( cif_cc ) ) {
                    print_message( "WARNING", "stray CIF values at the "
                                   "beginning of the input file", "",
                                   $1.vline, -1, px );
            } else {
                    print_message( "ERROR", "stray CIF values at the "
                                   "beginning of the input file", "",
                                   $1.vline, -1, px );
                    yyincrease_error_counter();
            }
            free_typed_value( $1 );
            free_typed_value( $2 );
        }
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
        {
            if( isset_fix_errors( cif_cc ) ||
                isset_fix_data_header( cif_cc ) ) {
                    print_message( 
                              "WARNING", "no data block heading " 
                              "(i.e. data_somecif) found", "",
                              cif_flex_previous_line_number(), -1, px );
            } else {
                    print_message( 
                              "ERROR", "no data block heading "
                              "(i.e. data_somecif) found", "",
                              cif_flex_previous_line_number(), -1, px );
                    yyincrease_error_counter();
            }
        }
	|	data_item
        {
            if( isset_fix_errors( cif_cc ) ||
                isset_fix_data_header( cif_cc ) ) {
                    print_message( 
                              "WARNING", "no data block heading " 
                              "(i.e. data_somecif) found", "",
                              cif_flex_previous_line_number(), -1, px );
            } else {
                    print_message( 
                              "ERROR", "no data block heading "
                              "(i.e. data_somecif) found", "",
                              cif_flex_previous_line_number(), -1, px );
                    yyincrease_error_counter();
            }
        }
		data_item_list
;

data_block
	:	data_block_head data_item_list
        {
            if( $1 == NULL ) {
                yywarning( "data block header has no data block name", px );
            }
        }
        |       data_block_head //  empty data item list
        {
            if( $1 == NULL ) {
                yywarning( "data block header has no data block name", px );
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
            freex( $1 );
        }
	|	_DATA_ cif_value_list
        {
            if( isset_fix_errors( cif_cc ) ||
                isset_fix_string_quotes( cif_cc ) ||
                isset_fix_datablock_names( cif_cc ) ) {
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
                if( isset_fix_errors( cif_cc ) ||
                    isset_fix_string_quotes( cif_cc ) ) {
                    yywarning_token( "the dataname apparently had spaces "
                                     "in it -- replaced spaces with underscores",
                                     $2.vline, -1, px );
                }
            } else {
                cif_start_datablock( cif_cc->cif, $1, px );
                yyerror_token( "incorrect CIF syntax",
                               $2.vline, $2.vpos+1, px );
            }
            freex( $1 );
            free_typed_value( $2 );
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
            freex( $1 );
            free_typed_value( $2 );
        }
        | _TAG cif_value cif_value_list
            {
                assert_datablock_exists( px );
                if( isset_fix_errors( cif_cc ) ||
                    isset_fix_string_quotes( cif_cc ) ) {
                    yywarning_token( "string with spaces without quotes -- fixed",
                                     $2.vline, -1, px );
                    char *buf = mallocx(strlen($2.vstr)+strlen($3.vstr)+2,px);
                    buf = strcpy( buf, $2.vstr );
                    buf = strcat( buf, " \0" );
                    buf = strcat( buf, $3.vstr );
                    cif_value_type_t tag_type = CIF_SQSTRING;
                    if( index( buf, '\n' ) != NULL ||
                        index( buf, '\r' ) != NULL ||
                        index( buf, '\'' ) != NULL ||
                        index( buf, '\"' ) != NULL ) {
                        tag_type = CIF_TEXT;
                    }
                    add_tag_value( $1, buf, tag_type, px );
                    freex( buf );
                } else {
                    yyerror_token( "incorrect CIF syntax", $3.vline, $3.vpos+1, px );
                }
                freex( $1 );
                free_typed_value( $2 );
                free_typed_value( $3 );
            }
;

cif_value_list
        :       cif_value
        {
            $$.vstr  = $1.vstr;
            $$.vtype = $1.vtype;
            $$.vline = $1.vline;
            $$.vpos  = $1.vpos;
        }
        |       cif_value_list cif_value
        {
            char *buf = mallocx( strlen($1.vstr) + strlen($2.vstr) + 2, px );
            buf = strcpy( buf, $1.vstr );
            buf = strcat( buf, " \0" );
            buf = strcat( buf, $2.vstr );
            free_typed_value( $1 );
            free_typed_value( $2 );
            $$.vstr  = buf;
            $$.vtype = CIF_UNKNOWN;
            $$.vline = $1.vline;
            $$.vpos  = $1.vpos;
        }
;

loop
       :	_LOOP_ 
       {
           assert_datablock_exists( px );
           loop_tag_count = 0;
           loop_value_count = 0;
           loop_start = cif_flex_current_line_number();
           cif_start_loop( cif_cc->cif, px );
           freex( $1 );
       } 
       loop_tags loop_values
       {
           if( loop_value_count % loop_tag_count != 0 ) {
               yyerror( cxprintf( "wrong number of elements in the "
                                  "loop starting at line %d",
                                  loop_start ) );
#if 0
               if( cif_cc->cif ) {
                   cif_set_yyretval( cif_cc->cif, -1 );
               }
               cexception_raise( px, CIF_UNRECOVERABLE_ERROR,
                   cxprintf( "wrong number of elements in the "
                             "loop starting at line %d",
                              loop_start ) );
#endif
           }
           cif_finish_loop( cif_cc->cif, px );
       } 
       ;

loop_tags
	:	loop_tags _TAG
        {
            size_t tag_nr = cif_tag_index( cif_cc->cif, $2 );
            if( tag_nr != -1 ) {
                yyerror_token( cxprintf( "tag %s appears more than once", $2 ),
                               cif_flex_current_line_number(), -1, px );
            }
            loop_tag_count++;
            cif_insert_value( cif_cc->cif, $2, NULL, CIF_UNKNOWN, px );
            freex( $2 );
        }
	|	_TAG
        {
            size_t tag_nr = cif_tag_index( cif_cc->cif, $1 );
            if( tag_nr != -1 ) {
                yyerror_token( cxprintf( "tag %s appears more than once", $1 ),
                               cif_flex_current_line_number(), -1, px );
            }
            loop_tag_count++;
            cif_insert_value( cif_cc->cif, $1, NULL, CIF_UNKNOWN, px );
            freex( $1 );
        }
;

loop_values
	:	loop_values cif_value
        {
            loop_value_count++;
            cif_push_loop_value( cif_cc->cif, $2.vstr, $2.vtype, px );
        }
	|	cif_value
        {
            loop_value_count++;
            cif_push_loop_value( cif_cc->cif, $1.vstr, $1.vtype, px );
        }
;

save_block
	: _SAVE_HEAD
        {
            cif_start_save_frame( cif_cc->cif, /* name = */ $1, px );
            freex( $1 );
        }
        save_item_list
        _SAVE_FOOT
        {
            cif_finish_save_frame( cif_cc->cif );
        }
;

cif_value
	:	string
	|	number
	|	textfield
;

string
	:	_SQSTRING
        { $$.vstr = $1; $$.vtype = CIF_SQSTRING;
          $$.vline = cif_flex_current_line_number();
          $$.vpos  = cif_flex_current_position(); }
	|	_DQSTRING
        { $$.vstr = $1; $$.vtype = CIF_DQSTRING;
          $$.vline = cif_flex_current_line_number();
          $$.vpos  = cif_flex_current_position(); }
	|	_UQSTRING
        { $$.vstr = $1; $$.vtype = CIF_UQSTRING;
          $$.vline = cif_flex_current_line_number();
          $$.vpos  = cif_flex_current_position(); }
;

textfield
        :	_TEXT_FIELD
        { $$.vstr = $1;
          int unprefixed = 0;
          if( isset_do_not_unprefix_text( cif_cc ) == 0 ) {
              size_t str_len = strlen( $$.vstr );
              char * unprefixed_text = cif_unprefix_textfield( $$.vstr );
              free( $$.vstr );
              $$.vstr = unprefixed_text;
              if( str_len != strlen( $$.vstr ) ) {
                  unprefixed = 1;
              }
          }
          int unfolded = 0;
          if( isset_do_not_unfold_text( cif_cc ) == 0 &&
              $$.vstr[0] == '\\' ) {
              size_t str_len = strlen( $$.vstr );
              char * unfolded_text = cif_unfold_textfield( $$.vstr );
              free( $$.vstr );
              $$.vstr = unfolded_text;
              if( str_len != strlen( $$.vstr ) ) {
                  unfolded = 1;
              }
          }

        /*
         * Unprefixing transforms the first line to either "/\n" or "\n".
         * These symbols signal whether the processed text should be
         * unfolded or not (if the unfolding option is also set).
         * As a result, if the text was unprefixed, but not unfolded
         * an unnescessary empty line might occur at the begining of
         * the text field. This empty line should be removed.
         */
          if( unprefixed == 1 && unfolded == 0 ) {
              if( $$.vstr[0] == '\n' ) {
                  size_t i = 0;
                  while($$.vstr[i] != '\0') {
                      $$.vstr[i] = $$.vstr[i+1];
                      i++;
                  }
                  $$.vstr[i] = '\0';
              }
          }

          $$.vtype = CIF_TEXT;
          $$.vline = cif_flex_current_line_number();
          $$.vpos  = cif_flex_current_position(); }
;

number
	:	_REAL_CONST
        { $$.vstr = $1; $$.vtype = CIF_FLOAT;
          $$.vline = cif_flex_current_line_number();
          $$.vpos  = cif_flex_current_position(); }
	|	_INTEGER_CONST
        { $$.vstr = $1; $$.vtype = CIF_INT;
          $$.vline = cif_flex_current_line_number();
          $$.vpos  = cif_flex_current_position(); }
;

%%

static void cif_compile_file( char *filename, cexception_t *ex )
{
    cexception_t inner;
    int yyretval = 0;

    cexception_guard( inner ) {
        if( filename ) {
            yyin = fopenx( filename, "r", ex );
        } else {
            yyin = stdin;
        }
        px = &inner; /* catch all parser-generated exceptions */
        if( (yyretval = yyparse()) != 0 ) {
            int errcount = cif_yy_error_number();
            if( cif_cc->cif ) {
                cif_set_yyretval( cif_cc->cif, yyretval );
                cif_set_nerrors( cif_cc->cif, errcount );
            }
            cexception_raise( &inner, CIF_UNRECOVERABLE_ERROR,
                cxprintf( "compiler could not recover "
                    "from errors, quitting now -- "
                    "%d error(s) detected",
                    errcount ));
        }
    }
    cexception_catch {
        if( yyin ) {
            fclosex( yyin, ex );
            yyin = NULL;
        }
        cexception_reraise( inner, ex );
    }
    fclosex( yyin, ex );
}

CIF *new_cif_from_cif_file( char *filename, cif_option_t co, cexception_t *ex )
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
    }
    cexception_catch {
        yyrestart();
        if( !(cif_cc->options & CO_SUPPRESS_MESSAGES)) {
            delete_cif_compiler( cif_cc );
            cif_cc = NULL;
            cexception_reraise( inner, ex );
        } else {
            cexception_t inner2;
            cexception_try( inner2 ) {
                if( cif_yyretval( cif_cc->cif ) == 0 ) {
                    cif_set_yyretval( cif_cc->cif, -1 );
                }
                cif_set_nerrors( cif_cc->cif, cif_nerrors( cif_cc->cif ) + 1 );
                cif_set_message( cif_cc->cif,
                                 filename, "ERROR",
                                 cexception_message( &inner ),
                                 cexception_syserror( &inner ),
                                 &inner2 );
            }
            cexception_catch {
                cexception_raise
                    ( ex, CIF_OUT_OF_MEMORY_ERROR, "not enough memory to "
                      "record CIF error message" );
            }
        }
    }

    cif = cif_cc->cif;
    cif_cc->cif = NULL;
    delete_cif_compiler( cif_cc );
    cif_cc = NULL;

    nerrors = cif_yy_error_number();
    if( cif && nerrors > 0 ) {
        cif_set_nerrors( cif, nerrors );
    }

    cif_revert_message_list( cif );
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
        cif_start_datablock( cif_cc->cif, "", px );
    }
}

void add_tag_value( char * tag, char * value, cif_value_type_t type,
                    cexception_t *ex )
{
    if( cif_tag_index( cif_cc->cif, tag ) == -1 ) {
        cif_insert_value( cif_cc->cif, tag, value, type, ex );
    } else {
        ssize_t tag_nr = cif_tag_index( cif_cc->cif, tag );
        ssize_t * value_lengths = 
            datablock_value_lengths(cif_last_datablock(cif_cc->cif));
        if( value_lengths[tag_nr] == 1) {
            if( strcmp
                (datablock_value
                 (cif_last_datablock(cif_cc->cif), tag_nr, 0), value) == 0 &&
                (isset_fix_errors(cif_cc) == 1 ||
                 isset_fix_duplicate_tags_with_same_values
                 (cif_cc) == 1)) {
                yywarning( cxprintf( "tag %s appears more than once "
                                     "with the same value '%s'", tag, value ),
                           ex );
            } else {
                if( isset_fix_errors(cif_cc) == 1 ||
                    isset_fix_duplicate_tags_with_empty_values
                    (cif_cc) == 1 ) {
                    if( is_tag_value_unknown( value ) ) {
                        yywarning( cxprintf( "tag %s appears more than once, "
                                             "the second occurrence '%s' is "
                                             "ignored", tag, value ), ex );
                    } else if( is_tag_value_unknown
                               (datablock_value
                                (cif_last_datablock(cif_cc->cif),
                                 tag_nr, 0))) {
                        yywarning( cxprintf( "tag %s appears more than once, "
                                             "the previous value '%s' is "
                                             "overwritten", tag,
                                             datablock_value
                                             (cif_last_datablock(cif_cc->cif),
                                              tag_nr, 0)), ex );
                        cif_overwrite_value( cif_cc->cif, tag_nr, 0,
                                             value, type, ex );
                    } else {
                        yyerror_previous
                            ( cxprintf( "tag %s appears more than once", tag ),
                              ex );
                    }
                } else {
                    yyerror_previous
                        ( cxprintf( "tag %s appears more than once", tag ),
                          ex );
                }
            }
        } else {
            yyerror_previous( cxprintf( "tag %s appears more than once", tag ),
                              ex );
        }
    }
}

static int errcount = 0;
static int warncount = 0;
static int notecount = 0;

int cif_yy_error_number( void )
{
    return errcount;
}

void cif_yy_reset_error_count( void )
{
    errcount = 0;
}

void fprintf_escaped( const char *message,
                      int escape_parenthesis, int escape_space ) {
    const char *p = message;
    while( *p ) {
        switch( *p ) {
            case '&':
                fprintf( stderr, "&amp;" );
                break;
            case ':':
                fprintf( stderr, "&colon;" );
                break;
            default:
                if(        *p == '(' && escape_parenthesis != 0 ) {
                    fprintf( stderr, "&lpar;" );
                } else if( *p == ')' && escape_parenthesis != 0 ) {
                    fprintf( stderr, "&rpar;" );
                } else if( *p == ' '&& escape_space != 0 ) {
                    fprintf( stderr, "&nbsp;" );
                } else {
                    fprintf( stderr, "%c", *p );
                }
        }
        p++;
    }
}

static
void output_message( const char *errlevel, const char *message,
                     const char *suffix, int line, int position )
{
    extern char *progname;

    char *filename = cif_cc->filename;

    char *datablock = NULL;
    if( cif_cc->cif && cif_last_datablock( cif_cc->cif ) && 
        strlen( datablock_name( cif_last_datablock( cif_cc->cif ) ) ) > 0 ) {
        datablock = datablock_name( cif_last_datablock( cif_cc->cif ) );
    }

    fflush(NULL);
    if( progname && strlen( progname ) > 0 ) {
        fprintf_escaped( progname, 0, 1 );
        fprintf( stderr, ": " );
        fprintf_escaped( filename ? filename : "-", 1, 1 );
    }
    if( line != -1 ) {
        fprintf( stderr, "(%d", line );
        if( position != -1 ) {
            fprintf( stderr, ",%d", position );
        }
        fprintf( stderr, ")" );
    }
    if( datablock ) {
        fprintf( stderr, " data_" );
        fprintf_escaped( datablock, 0, 1 );
    }
    fprintf( stderr, ": %s, ", errlevel );
    fprintf_escaped( message, 0, 0 );
    fprintf( stderr, "%s\n", suffix );
    fflush(NULL);
}

void print_message( const char *errlevel, const char *message,
                    const char *suffix, /* ":" or "", dependenig on the
                                           subsequent citation or not of the
                                           code line. S.G. */
                    int line, int position, cexception_t *ex )
{
    if( !(cif_cc->options & CO_SUPPRESS_MESSAGES) ) {
        output_message( errlevel, message, suffix, line, position );
    }
    if( cif_cc->cif ) {
        char *datablock = NULL;
        if( cif_cc->cif && cif_last_datablock( cif_cc->cif ) && 
            strlen( datablock_name( cif_last_datablock( cif_cc->cif ))) > 0 ) {
            datablock = datablock_name( cif_last_datablock( cif_cc->cif ) );
        }
        cif_insert_message
            ( cif_cc->cif,
              new_cifmessage_from_data
              ( /* next = */ cif_messages( cif_cc->cif ),
                /* progname = */ NULL,
                /* filename = */ cif_cc->filename ? cif_cc->filename : "-",
                line, position,
                /* addPos = */ datablock,
                /* status = */ (char*)errlevel,
                /* message = */ (char*)message,
                /* explanation = */ NULL,
                /* separator = */ NULL,
                ex )
            );
    }
}

static ssize_t countchars( char c, char *s )
{
    ssize_t sum = 0;

    if( !s || !*s ) return 0;
    while( *s ) {
        if( *s++ == c ) sum ++;
    }
    return sum;
}

void print_current_text_field( char *text, cexception_t *ex )
{
    if( !(cif_cc->options & CO_SUPPRESS_MESSAGES) ) {
        ssize_t length = strlen( text ) + countchars( '\n', text ) + 1;
        char *prefixed = length > 0 ? mallocx( length, ex ) : NULL;
        char *p = prefixed, *t = text;
        if( p ) {
            while( t && *t ) {
                if( *t == '\n' ) {
                    *p++ = '\n';
                    *p = ' ';
                } else {
                    *p = *t;
                }
                t++; p++;
            }
            *p = '\0';
        }
        fflush(NULL);
        fprintf( stderr, " ;%s\n ;\n\n", prefixed );
        fflush(NULL);
        if( prefixed ) freex( prefixed );
    }
    if( cif_cc->cif ) {
        CIFMESSAGE *current_message = cif_messages( cif_cc->cif );
        assert( current_message );

        char *buf = mallocx( strlen(text) + 5, ex );
        sprintf( buf, ";%s\n;\n", text );
        cifmessage_set_line( current_message, buf, ex );
        if( buf ) freex( buf );
    }
}

void print_current_trace( cexception_t *ex )
{
    if( !(cif_cc->options & CO_SUPPRESS_MESSAGES) ) {
        fflush(NULL);
        fprintf( stderr, " %s\n %*s\n",
                 cif_flex_current_line(),
                 cif_flex_current_position()+1, "^" );
        fflush(NULL);
    }
    if( cif_cc->cif ) {
        CIFMESSAGE *current_message = cif_messages( cif_cc->cif );
        assert( current_message );
        cifmessage_set_line( current_message, 
                             (char*)cif_flex_current_line(), ex );
    }
}

void print_previous_trace( cexception_t *ex )
{
    if( !(cif_cc->options & CO_SUPPRESS_MESSAGES) ) {
        fflush(NULL);
        fprintf( stderr, " %s\n %*s\n",
                 cif_flex_previous_line(),
                 cif_flex_previous_position()+1, "^" );
        fflush(NULL);
    }
    if( cif_cc->cif ) {
        CIFMESSAGE *current_message = cif_messages( cif_cc->cif );
        assert( current_message );
        cifmessage_set_line( current_message,
                             (char*)cif_flex_previous_line(), ex );
    }
}

int yyerror( const char *message )
{
    if( strcmp( message, "syntax error" ) == 0 ) {
        message = "incorrect CIF syntax";
    }
    print_message( "ERROR", message, ":", cif_flex_current_line_number(),
                   cif_flex_current_position()+1, px );
    print_current_trace( px );
    errcount++;
    return 0;
}

int yyerror_previous( const char *message, cexception_t *ex )
{
    print_message( "ERROR", message, ":", cif_flex_previous_line_number(),
                   cif_flex_previous_position()+1, ex );
    print_previous_trace( ex );
    errcount++;
    return 0;
}

int yyerror_token( const char *message, int line, int pos, cexception_t *ex )
{
    print_message( "ERROR", message, ":", line, pos, ex );
    print_previous_trace( ex );
    errcount++;
    return 0;
}

void yyincrease_error_counter( void )
{
    errcount++;
}

int yynote( const char *message, cexception_t *ex )
{
    print_message( "NOTE", message, "", cif_flex_previous_line_number(), -1,
                   ex );
    notecount++;
    return 0;
}

int yywarning( const char *message, cexception_t *ex )
{
    print_message( "WARNING", message, "", cif_flex_previous_line_number(), -1,
                   ex );
    warncount++;
    return 0;
}

int yywarning_token( const char *message, int line, int pos, cexception_t *ex )
{
    print_message( "WARNING", message, "", line, pos,
                   ex );
    warncount++;
    return 0;
}

void free_typed_value( typed_value t ) {
    freex( t.vstr );
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

int isset_do_not_unprefix_text( CIF_COMPILER *ccc )
{
    cif_option_t copt = DO_NOT_UNPREFIX_TEXT;
    assert( ccc ); return ( ( ccc->options & copt ) != 0 );
}

int isset_do_not_unfold_text( CIF_COMPILER *ccc )
{
    cif_option_t copt = DO_NOT_UNFOLD_TEXT;
    assert( ccc ); return ( ( ccc->options & copt ) != 0 );
}

int isset_fix_errors( CIF_COMPILER *ccc )
{
    cif_option_t copt = FIX_ERRORS;
    assert( ccc ); return ( ( ccc->options & copt ) != 0 );
}

int isset_fix_duplicate_tags_with_same_values( CIF_COMPILER *ccc )
{
    cif_option_t copt = FIX_DUPLICATE_TAGS_WITH_SAME_VALUES;
    assert( ccc ); return ( ( ccc->options & copt ) != 0 );
}

int isset_fix_duplicate_tags_with_empty_values( CIF_COMPILER *ccc )
{
    cif_option_t copt = FIX_DUPLICATE_TAGS_WITH_EMPTY_VALUES;
    assert( ccc ); return ( ( ccc->options & copt ) != 0 );
}

int isset_fix_data_header( CIF_COMPILER *ccc )
{
    cif_option_t copt = FIX_DATA_HEADER;
    assert( ccc ); return ( ( ccc->options & copt ) != 0 );
}

int isset_fix_datablock_names( CIF_COMPILER *ccc )
{
    cif_option_t copt = FIX_DATABLOCK_NAMES;
    assert( ccc ); return ( ( ccc->options & copt ) != 0 );
}

int isset_fix_string_quotes( CIF_COMPILER *ccc )
{
    cif_option_t copt = FIX_STRING_QUOTES;
    assert( ccc ); return ( ( ccc->options & copt ) != 0 );
}
