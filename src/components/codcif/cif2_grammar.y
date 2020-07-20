/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

%{
/* exports: */
#include <cif2_grammar_y.h>

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
#include <cif2_lexer.h>
#include <cif_compiler.h>
#include <cif_lex_buffer.h>
#include <assert.h>
#include <ciftable.h>
#include <common.h>

static CIF_COMPILER * volatile cif_cc; /* CIF current compiler */

static cexception_t *px; /* parser exception */

static typed_value *typed_value_from_value( CIFVALUE *v, cexception_t *ex );
%}

%code requires {
    #include <cif_compiler.h>
}

%union {
    char *s;
    typed_value *typed_value;
}

%token <s> _DATA_
%token <s> _SAVE_HEAD
%token _SAVE_FOOT
%token <s> _TAG
%token <s> _LOOP_
%token <s> _DQSTRING
%token <s> _SQSTRING
%token <s> _UQSTRING
%token <s> _DQ3STRING
%token <s> _SQ3STRING
%token <s> _TEXT_FIELD
%token <s> _INTEGER_CONST
%token <s> _REAL_CONST
%token _TABLE_ENTRY_SEP

%type <s> data_heading
%type <typed_value> data_value_list
%type <typed_value> data_value
%type <typed_value> number
%type <typed_value> string
%type <typed_value> textfield
%type <typed_value> quoted_string
%type <typed_value> any_quoted_string
%type <typed_value> triple_quoted_string
%type <typed_value> list
%type <typed_value> table
%type <typed_value> table_entry_list

%%

cif_file
    :	// empty
    |	data_block_list
    |	headerless_data_block
    |	headerless_data_block data_block_list
    |	stray_data_value_list
    |	stray_data_value_list data_block_list
;

stray_data_value_list
        : data_value
        {
            if( isset_fix_errors( cif_cc ) ||
                isset_fix_data_header( cif_cc ) ) {
                    print_message( cif_cc, "WARNING", "stray CIF values at the "
                                   "beginning of the input file", "",
                                   typed_value_line( $1 ), -1, px );
            } else {
                    print_message( cif_cc, "ERROR", "stray CIF values at the "
                                   "beginning of the input file", "",
                                   typed_value_line( $1 ), -1, px );
                    cif_compiler_increase_nerrors( cif_cc );
            }
            delete_typed_value( $1 );
        }
        | data_value data_value_list
        {
            if( isset_fix_errors( cif_cc ) ||
                isset_fix_data_header( cif_cc ) ) {
                    print_message( cif_cc, "WARNING", "stray CIF values at the "
                                   "beginning of the input file", "",
                                   typed_value_line( $1 ), -1, px );
            } else {
                    print_message( cif_cc, "ERROR", "stray CIF values at the "
                                   "beginning of the input file", "",
                                   typed_value_line( $1 ), -1, px );
                    cif_compiler_increase_nerrors( cif_cc );
            }
            delete_typed_value( $1 );
            delete_typed_value( $2 );
        }
;

//  data_value_list
//      : data_value
//      | data_value_list data_value
//  ;

data_block_list
	:	data_block_list data_block
	|	data_block
;

headerless_data_block
	:	block_content
        {
            if( isset_fix_errors( cif_cc ) ||
                isset_fix_data_header( cif_cc ) ) {
                    print_message( cif_cc,
                              "WARNING", "no data block heading " 
                              "(i.e. data_somecif) found", "",
                              cif_flex_previous_line_number(), -1, px );
            } else {
                    print_message( cif_cc,
                              "ERROR", "no data block heading "
                              "(i.e. data_somecif) found", "",
                              cif_flex_previous_line_number(), -1, px );
                    cif_compiler_increase_nerrors( cif_cc );
            }
        }
	|	block_content
        {
            if( isset_fix_errors( cif_cc ) ||
                isset_fix_data_header( cif_cc ) ) {
                    print_message( cif_cc,
                              "WARNING", "no data block heading " 
                              "(i.e. data_somecif) found", "",
                              cif_flex_previous_line_number(), -1, px );
            } else {
                    print_message( cif_cc,
                              "ERROR", "no data block heading "
                              "(i.e. data_somecif) found", "",
                              cif_flex_previous_line_number(), -1, px );
                    cif_compiler_increase_nerrors( cif_cc );
            }
        }
		block_content_list
;

data_block
	:	data_heading block_content_list
    |   data_heading //  empty data item list
;

block_content_list
	:	block_content_list block_content
	|	block_content
;

data_heading
	:	_DATA_
        {
            cif_start_datablock( cif_compiler_cif( cif_cc ), $1, px );
            freex( $1 );
        }
	|	_DATA_ data_value_list
        {
            CIFLIST *list = value_list( typed_value_value( $2 ) );

            /* only simple data items can be concatenated,
             * thus we have to make sure that data value
             * list does not contain lists or tables: */
            if( (isset_fix_errors( cif_cc ) ||
                 isset_fix_string_quotes( cif_cc ) ||
                 isset_fix_datablock_names( cif_cc )) &&
                !list_contains_list_or_table( list )) {

                char *data_list = list_concat( list, '_', px );
                char buf[strlen($1)+strlen(data_list)+2];
                strcpy( buf, $1 );
                buf[strlen($1)] = '_';
                buf[strlen($1)+1] = '\0';
                strcat( buf, data_list );
                buf[strlen($1)+strlen(data_list)+1] = '\0';
                cif_start_datablock( cif_compiler_cif( cif_cc ), buf, px );
                if( isset_fix_errors( cif_cc ) ||
                    isset_fix_string_quotes( cif_cc ) ) {
                    yywarning_token( cif_cc, "the dataname apparently had spaces "
                                     "in it -- replaced spaces with underscores",
                                     typed_value_line( $2 ), -1, px );
                }
                freex( data_list );
            } else {
                cif_start_datablock( cif_compiler_cif( cif_cc ), $1, px );
                yyerror_token( cif_cc, "incorrect CIF syntax",
                               typed_value_line( $2 ),
                               typed_value_pos( $2 ) + 1,
                               typed_value_content( $2 ), px );
            }
            freex( $1 );
            delete_typed_value( $2 );
        }
;

block_content
	:	data
	|	save_frame
// 	|	error
;

data_list
	:	data_list data
	|	data
;

data
	:	cif_entry
	|	loop
;

cif_entry
	:	_TAG data_value
        {
            assert_datablock_exists( cif_cc, px );
            add_tag_value( cif_cc, $1, $2, px );
            freex( $1 );
            typed_value_detach_value( $2 ); // protecting v from free()ing
            delete_typed_value( $2 );
        }
        | _TAG data_value data_value_list
            {
                assert_datablock_exists( cif_cc, px );
                CIFLIST *list = value_list( typed_value_value( $3 ) );
                list_unshift( list, typed_value_value( $2 ), px );
                typed_value_detach_value( $2 );

                /* only simple data items can be concatenated,
                 * thus we have to make sure that data value
                 * list does not contain lists or tables: */
                if( list_contains_list_or_table( list ) ) {
                    yyerror_token( cif_cc, "incorrect CIF syntax",
                                   typed_value_line( $2 ),
                                   typed_value_pos( $2 ) + 1,
                                   typed_value_content( $2 ), px );
                } else if( isset_fix_errors( cif_cc ) ||
                            isset_fix_string_quotes( cif_cc ) ) {
                    yywarning_token( cif_cc, "string with spaces without quotes -- fixed",
                                     typed_value_line( $2 ), -1, px );
                    char *buf = list_concat( list, ' ', px );
                    cif_value_type_t tag_type = CIF_SQSTRING;
                    if( index( buf, '\n' ) != NULL ||
                        index( buf, '\r' ) != NULL ||
                        index( buf, '\'' ) != NULL ||
                        index( buf, '\"' ) != NULL ) {
                        tag_type = CIF_TEXT;
                    }
                    typed_value *tv = new_typed_value( typed_value_line( $3 ),
                                                        typed_value_pos( $3 ),
                                                        typed_value_content( $3 ),
                                                        new_value_from_scalar( buf, tag_type, px ) );
                    add_tag_value( cif_cc, $1, tv, px );
                    typed_value_detach_value( tv ); // preventing v from free()'ing
                    delete_typed_value( tv );
                    typed_value_detach_content( $3 ); // preventing from free()ing
                    typed_value_detach_value( $3 );   // repeatedly
                } else {
                    yyerror_token( cif_cc, "incorrect CIF syntax",
                                   typed_value_line( $3 ),
                                   typed_value_pos( $3 ) + 1,
                                   typed_value_content( $3 ), px );
                }
                freex( $1 );
                delete_typed_value( $2 );
                delete_typed_value( $3 );
            }
;

data_value_list
        :       data_value
        {
            CIFLIST *list = new_list( px );
            list_push( list, typed_value_value( $1 ), px );
            typed_value_set_value( $1, new_value_from_list( list, px ) );
        }
        |       data_value_list data_value
        {
            list_push( value_list( typed_value_value( $1 ) ),
                       typed_value_value( $2 ), px );
            typed_value_detach_value( $2 ); /* protecting v from free'ing */
            delete_typed_value( $2 );
        }
;

loop
       :	_LOOP_ 
       {
           assert_datablock_exists( cif_cc, px );
           cif_compiler_start_loop( cif_cc, cif_flex_current_line_number() );
           cif_start_loop( cif_compiler_cif( cif_cc ), px );
           freex( $1 );
       } 
       loop_tags loop_values
       {
           if( cif_compiler_loop_value_count( cif_cc ) %
               cif_compiler_loop_tag_count( cif_cc ) != 0 ) {
               cif2error( cxprintf( "wrong number of elements in the "
                                  "loop starting at line %d",
                                   cif_compiler_loop_start_line( cif_cc ) ) );
#if 0
               if( cif_compiler_cif( cif_cc ) ) {
                   cif_set_yyretval( cif_compiler_cif( cif_cc ), -1 );
               }
               cexception_raise( px, CIF_UNRECOVERABLE_ERROR,
                   cxprintf( "wrong number of elements in the "
                             "loop starting at line %d",
                              cif_compiler_loop_start_line( cif_cc ) ) );
#endif
           }
           cif_finish_loop( cif_compiler_cif( cif_cc ), px );
       } 
       ;

loop_tags
	:	loop_tags _TAG
        {
            ssize_t tag_nr = cif_tag_index( cif_compiler_cif( cif_cc ), $2 );
            if( tag_nr != -1 ) {
                yyerror_token( cif_cc, cxprintf( "tag %s appears more than once", $2 ),
                               cif_flex_current_line_number(), -1, NULL, px );
            }
            cif_compiler_increase_loop_tags( cif_cc );
            cif_insert_cifvalue( cif_compiler_cif( cif_cc ), $2, NULL, px );
            freex( $2 );
        }
	|	_TAG
        {
            ssize_t tag_nr = cif_tag_index( cif_compiler_cif( cif_cc ), $1 );
            if( tag_nr != -1 ) {
                yyerror_token( cif_cc, cxprintf( "tag %s appears more than once", $1 ),
                               cif_flex_current_line_number(), -1, NULL, px );
            }
            cif_compiler_increase_loop_tags( cif_cc );
            cif_insert_cifvalue( cif_compiler_cif( cif_cc ), $1, NULL, px );
            freex( $1 );
        }
;

loop_values
	:	loop_values data_value
        {
            cif_compiler_increase_loop_values( cif_cc );
            cif_push_loop_cifvalue( cif_compiler_cif( cif_cc ),
                                    typed_value_value( $2 ), px );
            typed_value_detach_value( $2 ); /* protecting v from free'ing */
            delete_typed_value( $2 );
        }
	|	data_value
        {
            cif_compiler_increase_loop_values( cif_cc );
            cif_push_loop_cifvalue( cif_compiler_cif( cif_cc ),
                                    typed_value_value( $1 ), px );
            typed_value_detach_value( $1 ); /* protecting v from free'ing */
            delete_typed_value( $1 );
        }
;

save_frame
	:   _SAVE_HEAD
        {
            assert_datablock_exists( cif_cc, px );
            cif_start_save_frame( cif_compiler_cif( cif_cc ), /* name = */ $1, px );
            freex( $1 );
        }
        data_list
        _SAVE_FOOT
        {
            cif_finish_save_frame( cif_compiler_cif( cif_cc ) );
        }
    |   _SAVE_HEAD
        _SAVE_FOOT /* empty save frame */
;

data_value
	:	string
	|	number
	|	textfield
    |   list
    |   table
;

string
    :   any_quoted_string
	|	_UQSTRING
        {
            $$ = typed_value_from_value( new_value_from_scalar( $1, CIF_UQSTRING, px ), px );
        }
;

any_quoted_string
    :   quoted_string
    |   triple_quoted_string
;

quoted_string
    :   _SQSTRING
        {
            $$ = typed_value_from_value( new_value_from_scalar( $1, CIF_SQSTRING, px ), px );
        }
	|	_DQSTRING
        {
            $$ = typed_value_from_value( new_value_from_scalar( $1, CIF_DQSTRING, px ), px );
        }
;

triple_quoted_string
    :   _SQ3STRING
        {
            $$ = typed_value_from_value( new_value_from_scalar( $1, CIF_SQ3STRING, px ), px );
        }
	|	_DQ3STRING
        {
            $$ = typed_value_from_value( new_value_from_scalar( $1, CIF_DQ3STRING, px ), px );
        }
;

textfield
        :	_TEXT_FIELD
        {
          char *text = $1;

          int unprefixed = 0;
          if( isset_do_not_unprefix_text( cif_cc ) == 0 ) {
              size_t str_len = strlen( text );
              char *unprefixed_text =
                    cif_unprefix_textfield( text );
              freex( text );
              text = unprefixed_text;
              if( str_len != strlen( unprefixed_text ) ) {
                  unprefixed = 1;
              }
          }
          int unfolded = 0;
          if( isset_do_not_unfold_text( cif_cc ) == 0 &&
              text[0] == '\\' ) {
              size_t str_len = strlen( text );
              char *unfolded_text =
                    cif_unfold_textfield( text );
              freex( text );
              text = unfolded_text;
              if( str_len != strlen( unfolded_text ) ) {
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
              char *str = text;
              if( str[0] == '\n' ) {
                  size_t i = 0;
                  while( str[i] != '\0' ) {
                      str[i] = str[i+1];
                      i++;
                  }
                  str[i] = '\0';
              }
          }

          $$ = typed_value_from_value( new_value_from_scalar( text, CIF_TEXT, px ), px );
        }
;

number
	:	_REAL_CONST
        {
            $$ = typed_value_from_value( new_value_from_scalar( $1, CIF_FLOAT, px ), px );
        }
	|	_INTEGER_CONST
        {
            $$ = typed_value_from_value( new_value_from_scalar( $1, CIF_INT, px ), px );
        }
;

list
    :   '[' data_value_list ']'
    {
        $$ = $2;
    }
    |   '[' ']'
    {
        $$ = typed_value_from_value( new_value_from_list( new_list( px ), px ), px );
    }
;

table
    :   '{' table_entry_list '}'
    {
        $$ = $2;
    }
    |   '{' '}'
    {
        $$ = typed_value_from_value( new_value_from_table( new_table( px ), px ), px );
    }
;

table_entry_list
	:	table_entry_list
        any_quoted_string _TABLE_ENTRY_SEP data_value
    {
        if( table_get( value_table( typed_value_value( $1 ) ),
                       value_scalar( typed_value_value( $2 ) ) ) != NULL ) {
            yyerror_token( cif_cc, cxprintf( "key '%s' appears more than once "
                                     "in the same table",
                                      value_scalar( typed_value_value( $2 ) ) ),
                           typed_value_line( $2 ), -1, NULL, px );
        }
        table_add( value_table( typed_value_value( $1 ) ),
                   value_scalar( typed_value_value( $2 ) ),
                   typed_value_value( $4 ), px );
        typed_value_detach_value( $4 ); // protecting from free()ing
        delete_typed_value( $2 );
        delete_typed_value( $4 );
    }
	|	any_quoted_string _TABLE_ENTRY_SEP data_value
    {
        $$ = new_typed_value( typed_value_line( $1 ), typed_value_pos( $1 ),
                              strdupx( typed_value_content( $1 ), px ),
                              new_value_from_table( new_table( px ), px ) );
        /* check for the existence of key does not have to be
         * performed, since the table is empty */
        table_add( value_table( typed_value_value( $$ ) ),
                   value_scalar( typed_value_value( $1 ) ),
                   typed_value_value( $3 ), px );
        typed_value_detach_value( $3 ); // protecting from free()ing
        delete_typed_value( $1 );
        delete_typed_value( $3 );
    }
;

%%

static void cif_compile_file( FILE *in, char *filename, cexception_t *ex )
{
    cexception_t inner;
    int yyretval = 0;

    cexception_guard( inner ) {
        cif_compiler_set_file( cif_cc, in );
        px = &inner; /* catch all parser-generated exceptions */
        if( (yyretval = cif2parse()) != 0 ) {
            if( cif_compiler_cif( cif_cc ) ) {
                int errcount = cif_compiler_nerrors( cif_cc );
                cif_set_yyretval( cif_compiler_cif( cif_cc ), yyretval );
                cif_set_nerrors( cif_compiler_cif( cif_cc ), errcount );
                cexception_raise( &inner, CIF_UNRECOVERABLE_ERROR,
                    cxprintf( "compiler could not recover "
                        "from errors, quitting now -- "
                        "%d error(s) detected",
                        errcount ));
            }
        }
    }
    cexception_catch {
        if( cif_compiler_file( cif_cc ) ) {
            cif_compiler_set_file( cif_cc, NULL );
        }
        cexception_reraise( inner, ex );
    }
}

CIF *new_cif_from_cif2_file( FILE *in, char *filename, cif_option_t co, cexception_t *ex )
{
    volatile int nerrors;
    cexception_t inner;
    CIF * volatile cif = NULL;
    extern void cif2restart( void );

    assert( !cif_cc );
    cif_cc = new_cif_compiler( filename, co, ex );
    cif_flex_reset_counters();
    cif2_lexer_set_compiler( cif_cc );
    set_lexer_allow_high_chars(); // always allowed for CIF 2.0

    if( co & CO_COUNT_LINES_FROM_2 ) {
        cif_flex_set_current_line_number( 2 );
    }

    cexception_guard( inner ) {
        cif_compile_file( in, filename, &inner );
    }
    cexception_catch {
        cif2restart();
        if( !isset_suppress_messages( cif_cc ) ) {
            delete_cif_compiler( cif_cc );
            cif_cc = NULL;
            cexception_reraise( inner, ex );
        } else {
            cexception_t inner2;
            cexception_try( inner2 ) {
                if( cif_yyretval( cif_compiler_cif( cif_cc ) ) == 0 ) {
                    cif_set_yyretval( cif_compiler_cif( cif_cc ), -1 );
                }
                cif_set_version( cif_compiler_cif( cif_cc ), 2, 0 );
                cif_set_nerrors( cif_compiler_cif( cif_cc ),
                                 cif_nerrors( cif_compiler_cif( cif_cc ) ) + 1 );
                cif_set_message( cif_compiler_cif( cif_cc ),
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

    cif = cif_compiler_cif( cif_cc );
    cif_set_version( cif, 2, 0 );
    nerrors = cif_compiler_nerrors( cif_cc );
    if( cif && nerrors > 0 ) {
        cif_set_nerrors( cif, nerrors );
    }

    cif_lexer_cleanup();
    cif_compiler_detach_cif( cif_cc );
    delete_cif_compiler( cif_cc );
    cif_cc = NULL;

    cif_revert_message_list( cif );
    return cif;
}

int cif2error( const char *message )
{
    if( strcmp( message, "syntax error" ) == 0 ) {
        message = "incorrect CIF syntax";
    }
    print_message( cif_cc, "ERROR", message, ":",
                   cif_flex_current_line_number(),
                   cif_flex_current_position()+1, px );
    print_trace( cif_cc, (char*)cif_flex_current_line(),
                 cif_flex_current_position()+1, px );
    cif_compiler_increase_nerrors( cif_cc );
    return 0;
}

static typed_value *typed_value_from_value( CIFVALUE *v, cexception_t *ex )
{
    return new_typed_value( cif_flex_current_line_number(),
                             cif_flex_current_position(),
                             strdupx( cif_flex_current_line(), px ),
                             v );
}

/*
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
*/

void cif2_yy_debug_on( void )
{
#ifdef YYDEBUG
    cif2debug = 1;
#endif
}

void cif2_yy_debug_off( void )
{
#ifdef YYDEBUG
    cif2debug = 0;
#endif
}
