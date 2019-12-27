/*---------------------------------------------------------------------------*\
**$Author$
**$Date$
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

/* exports: */
#include <cif_lexer.h>

/* uses: */
#include <string.h>
#include <ctype.h>
#include <cif_grammar_flex.h>
#include <cif_grammar_y.h>
#include <cif_grammar.tab.h>
#include <cif_lex_buffer.h>
#include <common.h>
#include <yy.h>
#include <cxprintf.h>
#include <allocx.h>
#include <stringx.h>
#include <assert.h>

static CIF_COMPILER *cif_cc;

static size_t cif_mandated_tag_length = 74;
static int report_long_tags = 0;

int cif_lexer_set_report_long_tags( int flag )
{
    int old_value = report_long_tags;
    report_long_tags = flag;
    return old_value;
}

int cif_lexer_report_long_tags( void )
{
    return report_long_tags;
}

size_t cif_lexer_set_tag_length_limit( size_t max_length )
{
    size_t old_value = cif_mandated_tag_length;
    cif_mandated_tag_length = max_length;
    return old_value;
}

void cif_lexer_set_compiler( CIF_COMPILER *ccc )
{
    cif_cc = ccc;
}

static int cif_lexer( FILE *in, cexception_t *ex );

int ciflex( void )
{
    if( !cif_compiler_file( cif_cc ) )
        cif_compiler_set_file( cif_cc, stdin );
    return cif_lexer( cif_compiler_file( cif_cc ), NULL );
}

void cifrestart( void )
{
    /* FIXME: Nothing so far, to be expanded... */
}

static int cif_lexer( FILE *in, cexception_t *ex )
{
    int ch = '\0';
    static int prevchar = '\0';
    int pos;

    while( ch != EOF ) {
        /* It is important that the predicate that checks for spaces
           in the if() statement below is the same as is used in the
           predicate in the 'default:' branch of the next switch
           statement; otherwise we can end up in an infinite loop if a
           character is regarded as space by the 'default:' branch but
           not skipped here. S.G. */
        if( is_cif_space( ch ) || ch == '\0' ) {
            /* skip spaces: */
            prevchar = ch;
            ch = getlinec( in, cif_cc, ex );
            continue;
        }
        switch( ch ) {
        case '\032': /* DOS EOF (^Z, Ctrl-Z) character */
            backstep_mark();
            if( cif_lexer_has_flags
                (CIF_FLEX_LEXER_FIX_CTRL_Z) ) {
                yywarning_token( cif_cc, "DOS EOF symbol ^Z was encountered and ignored",
                                 cif_flex_previous_line_number(), -1, ex );
            } else {
                ciferror( "DOS EOF symbol ^Z was encountered, "
                          "it is not permitted in CIFs" );
            }
            prevchar = ch;
            ch = getlinec( in, cif_cc, ex );
            break;
        case '#':
            if( yy_flex_debug ) {
                printf( ">>> comment: " );
                putchar( ch );
            }
            /* skip comments: */
            pos = cif_flex_current_mark_position();
            while( ch != EOF && ch != '\n' && ch != '\r' ) {
                ch = getlinec( in, cif_cc, ex );
                pos ++;
                if( yy_flex_debug ) {
                    putchar( ch );
                }
                if( ch != EOF && ((ch < 32 && ch != 9 && ch != 10 && ch != 13) || ch >= 127) ) {
                    if( cif_lexer_has_flags
                        (CIF_FLEX_LEXER_FIX_NON_ASCII_SYMBOLS) ) {
                            yynote_token( cif_cc, "unallowed symbol in CIF comment "
                                                  "was encountered and ignored",
                                          cif_flex_current_line_number(), pos, ex );
                    } else {
                        yywarning_token( cif_cc, "unallowed symbol in CIF comment",
                                         cif_flex_current_line_number(), pos, ex );
                    }
                }
            }
            if( ch == '\r' ) {
                /* check and process the DOS newlines: */
                int before = ch;
                ch = getlinec( in, cif_cc, ex );
                if( ch != '\n' ) {
                    ungetlinec( ch, in );
                    ch = before;
                } else {
                    if( yy_flex_debug ) {
                        putchar( '\n' );
                    }
                }
            }
            prevchar = ch;
            ch = getlinec( in, cif_cc, ex );
            break;
        case '_':
            /* data name, or "tag": */
            advance_mark();
            pos = 0;
            pushchar( pos++, ch );
            while( !is_cif_space(ch) && ch != EOF ) {
                ch = getlinec( in, cif_cc, ex );
                pushchar( pos++, tolower(ch) );
            }
            ungetlinec( ch, in );
            pos --;
            prevchar = cif_flex_token()[pos-1];
            pushchar( pos, '\0' );
            ciflval.s = clean_string( cif_flex_token(), /* is_textfield = */ 0, cif_cc, ex );
            /* Underscore must be followed by one or more non-empty
               symbol to pass as a correct tag name. */
            if( pos == 1 )
                ciferror( "incorrect CIF syntax" );
            if( yy_flex_debug ) {
                printf( ">>> TAG: '%s'\n", cif_flex_token() );
            }
            if( report_long_tags ) {
                if( strlen( ciflval.s ) > cif_mandated_tag_length ) {
                    yynote_token( cif_cc, cxprintf( "data name '%s' exceeds %d characters",
                                      ciflval.s, cif_mandated_tag_length ),
                                  cif_flex_previous_line_number(), -1, ex );
                }
            }
            return _TAG;
            break;

        case '.': case '+': case '-': case '0': case '1': case '2': case '3':
        case '4': case '5': case '6': case '7': case '8': case '9':
            pos = 0;
            advance_mark();
            pushchar( pos++, ch );
            while( !is_cif_space( ch ) && ch != EOF ) {
                pushchar( pos++, ch = getlinec( in, cif_cc, ex ));
            }
            ungetlinec( ch, in );
            pos --;
            prevchar = cif_flex_token()[pos-1];
            pushchar( pos, '\0' );
            ciflval.s = clean_string( cif_flex_token(), /* is_textfield = */ 0, cif_cc, ex );
            if( is_integer( cif_flex_token() )) {
                if( yy_flex_debug ) {
                    printf( ">>> INTEGER: '%s'\n", cif_flex_token() );
                }
                return _INTEGER_CONST;
            } else if( is_real( cif_flex_token() )) {
                if( yy_flex_debug ) {
                    printf( ">>> REAL: '%s'\n", cif_flex_token() );
                }
                return _REAL_CONST;
            } else {
                if( yy_flex_debug ) {
                /* !!! FIXME: check whether it is really a real number.
                       Currently it is assumed that a sequence of digits 
                       that is not an integer number is automatically a 
                       real number without explicitly imposing that it 
                       should not contain any other symbols besides 
                       [.0-9] */
                    printf( ">>> UQSTRING (not a number): '%s'\n", cif_flex_token() );
                }
                return _UQSTRING;
            }
            break;
        case '"': case '\'':
            {
                /* quoted strings: */
                int quote = ch;
                advance_mark();
                pos = 0;
                while( (ch = getlinec( in, cif_cc, ex )) != EOF ) {
                    if( ch == '\n' || ch == '\r' )
                        break;
                    if( ch != quote ) {
                        pushchar( pos++, ch );
                    } else {
                        /* check if the quote terminates the string: */
                        int before = ch;
                        ch = getlinec( in, cif_cc, ex );
                        if( ch == EOF || is_cif_space(ch) ) {
                            /* The quoted string is properly terminated: */
                            ungetlinec( ch, in );
                            pushchar( pos, '\0' );
                            ciflval.s = clean_string
                                ( cif_flex_token(), /* is_textfield = */ 0, cif_cc, ex );
                            if( yy_flex_debug ) {
                                printf( ">>> *QSTRING (%c): '%s'\n",
                                        quote, cif_flex_token() );
                            }
                            return quote == '"' ? _DQSTRING : _SQSTRING;
                        } else {
                            /* The quote does not terminate the
                               string, it is a part of the value: */
                            ungetlinec( ch, in );
                            prevchar = before;
                            pushchar( pos++, before );
                        }
                    }
                }
                /* Unterminated quoted string: */
                prevchar = cif_flex_token()[pos-1];
                pushchar( pos, '\0' );
                ciflval.s = clean_string( cif_flex_token(), /* is_textfield = */ 0,
                                          cif_cc, ex );
                switch( quote ) {
                    case '"':
                        if( cif_lexer_has_flags
                            (CIF_FLEX_LEXER_FIX_MISSING_CLOSING_DOUBLE_QUOTE)
                            ) {
                            yywarning_token( cif_cc, "double-quoted string is missing "
                                             "a closing quote -- fixed",
                                             cif_flex_previous_line_number(), -1, ex );
                        } else {
                            yyerror_token( cif_cc, "incorrect CIF syntax",
                                           cif_flex_current_line_number()-1,
                                           cif_flex_current_position()+1,
                                           (char*)cif_flex_previous_line(),
                                           ex );
                        }
                        break;
                    case '\'':
                        if( cif_lexer_has_flags
                            (CIF_FLEX_LEXER_FIX_MISSING_CLOSING_SINGLE_QUOTE)
                            ) {
                            yywarning_token( cif_cc, "single-quoted string is missing "
                                             "a closing quote -- fixed",
                                             cif_flex_previous_line_number(), -1, ex );
                        } else {
                            yyerror_token( cif_cc, "incorrect CIF syntax",
                                           cif_flex_current_line_number()-1,
                                           cif_flex_current_position()+1,
                                           (char*)cif_flex_previous_line(),
                                           ex );
                        }
                        break;
                }
                return quote == '"' ? _DQSTRING : _SQSTRING;
            }
            break;
        case ';':
            if( prevchar == '\n' || prevchar == '\0' ) {
                /* multi-line text field: */
                advance_mark();
                ssize_t textfield_start = cif_flex_current_line_number();
                pos = 0;
                while( ch != EOF ) {
                    prevchar = ch;
                    ch = getlinec( in, cif_cc, ex );
                    if( ch == ';' &&
                        ( prevchar == '\n' || prevchar == '\r' )) {
                        /* end of the text field detected: */
                        prevchar = ch;
                        int after = getlinec( in, cif_cc, ex );
                        ungetlinec( after, in );
                        if( !is_cif_space( after ) && after != EOF ) {
                            ciferror( "incorrect CIF syntax" );
                        }
                        cif_flex_token()[pos-1] = '\0'; /* delete the last '\n' char */
                        if( yy_flex_debug ) {
                            printf( ">>> TEXT FIELD: '%s'\n", cif_flex_token() );
                        }
                        ciflval.s = clean_string( cif_flex_token(), /* is_textfield = */ 1,
                                                  cif_cc, ex );
                        return _TEXT_FIELD;
                    }
                    pushchar( pos++, ch );
                }
                /* Unterminated text field: */
                yyerror_token( cif_cc,
                     cxprintf( "end of file encountered while in "
                               "text field starting in line %d, "
                               "possible runaway closing semicolon (';')",
                               textfield_start ),
                               cif_flex_current_line_number()-1, -1,
                               NULL, ex );
            }
            /* else this is an ordinary unquoted string -- drop
               through to the 'default:' case (no break here,
               deliberately!): */
        default:
            pos = 0;
            advance_mark();
            pushchar( pos++, ch );
            while( !is_cif_space( ch ) && ch != EOF ) {
                pushchar( pos++, ch = getlinec( in, cif_cc, ex ));
            }
            ungetlinec( ch, in );
            prevchar = cif_flex_token()[pos-1];
            pos --;
            // assert( pos < length );
            assert( pos >= 0 );
            cif_flex_token()[pos] = '\0';
            if( starts_with_keyword( "data_", cif_flex_token() ) ) {
                /* data block header: */
                if( pos == 5 ) {
                    if( cif_lexer_has_flags(CIF_FLEX_LEXER_FIX_DATABLOCK_NAMES) ) {
                        yywarning_token( cif_cc, "zero-length data block name detected "
                                         "-- ignored",
                                         cif_flex_previous_line_number(), -1, ex );
                    } else {
                        ciferror( "zero-length data block name detected" );
                    }
                }
                if( yy_flex_debug ) {
                    printf( ">>> DATA_: '%s'\n", cif_flex_token() + 5 );
                }
                ciflval.s = clean_string( cif_flex_token() + 5, /* is_textfield = */ 0,
                                          cif_cc, ex );
                return _DATA_;
            } else if( starts_with_keyword( "save_", cif_flex_token() )) {
                /* save frame header or terminator: */
                if( pos == 5 /* strlen( "save_" ) */ ) {
                    /* This is a save frame terminator: */
                    if( yy_flex_debug ) {
                        printf( ">>> SAVE_\n" );
                    }
                    ciflval.s = NULL;
                    return _SAVE_FOOT;
                } else {
                    if( yy_flex_debug ) {
                        printf( ">>> SAVE_: '%s'\n", cif_flex_token() + 5 );
                    }
                    ciflval.s = clean_string( cif_flex_token() + 5, /* is_textfield = */ 0,
                                              cif_cc, ex );
                    return _SAVE_HEAD;
                }
            } else if( starts_with_keyword( "loop_", cif_flex_token() ) && pos == 5) {
                /* loop header: */
                if( yy_flex_debug ) {
                    printf( ">>> LOOP_\n" );
                }
                ciflval.s = clean_string( cif_flex_token(), /* is_textfield = */ 0, cif_cc, ex );
                return _LOOP_;
            } else if( starts_with_keyword( "stop_", cif_flex_token() ) && pos == 5 ) {
                /* stop field: */
                ciferror( "STOP_ symbol detected -- "
                         "it is not acceptable in CIF v1.1" );
            } else if( starts_with_keyword( "global_", cif_flex_token() ) && pos == 7 ) {
                /* global field: */
                ciferror( "GLOBAL_ symbol detected -- "
                         "it is not acceptable in CIF v1.1" );
            } else {
                if( cif_flex_token()[0] == '[' ) {
                    /* opening bracket is a reserved symbol, unquoted strings
                       may not start with it: */
                    if( !cif_lexer_has_flags
                        (CIF_FLEX_LEXER_ALLOW_UQSTRING_BRACKETS)) {
                        ciferror( "opening square brackets are reserved "
                                 "and may not start an unquoted string" );
                    }
                }
                if( cif_flex_token()[0] == ']' ) {
                    /* closing bracket is a reserved symbol, unquoted strings
                       may not start with it: */
                    if( !cif_lexer_has_flags
                        (CIF_FLEX_LEXER_ALLOW_UQSTRING_BRACKETS)) {
                        ciferror( "closing square brackets are reserved "
                                 "and may not start an unquoted string" );
                    }
                }
                if( cif_flex_token()[0] == '$' ) {
                    /* dollar is a reserved symbol, unquoted strings
                       may not start with it: */
                    ciferror( "dollar symbol ('$') must not start an "
                             "unquoted string" );
                }
                if( cif_flex_token()[0] != '[' &&
                    cif_flex_token()[0] != ']' &&
                    cif_flex_token()[0] != '$' ) {
                    if( yy_flex_debug ) {
                        printf( ">>> UQSTRING: '%s'\n", cif_flex_token() );
                    }
                    ciflval.s = clean_string( cif_flex_token(), /* is_textfield = */ 0,
                                              cif_cc, ex );
                    return _UQSTRING;
                } else {
                    if( yy_flex_debug ) {
                        printf( ">>> SQSTRING (corrected bracket): '%s'\n", cif_flex_token() );
                    }
                    ciflval.s = clean_string( cif_flex_token(), /* is_textfield = */ 0,
                                              cif_cc, ex );
                    return _SQSTRING;
                }
            }
        }
    }

    return 0;
}
