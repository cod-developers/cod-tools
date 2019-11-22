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

static size_t cif_mandated_line_length = 80;
static size_t cif_mandated_tag_length = 74;
static int report_long_items = 0;

int cif_lexer_set_report_long_items( int flag )
{
    int old_value = report_long_items;
    report_long_items = flag;
    return old_value;
}

int cif_lexer_report_long_items( void )
{
    return report_long_items;
}

size_t cif_lexer_set_line_length_limit( size_t max_length )
{
    size_t old_value = cif_mandated_line_length;
    cif_mandated_line_length = max_length;
    return old_value;
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

static char *clean_string( char *src, int is_textfield, cexception_t *ex );
static int string_has_high_bytes( unsigned char *s );
static char *check_and_clean( char *token, int is_textfield,
                              cexception_t *ex );

static int cif_lexer( FILE *in, cexception_t *ex )
{
    int ch = '\0';
    static int prevchar = '\0';
    int pos;

    while( ch != EOF ) {
        /* It is important that the predicate that checks for spaces
           in the if() statement below is the same as the ispace()
           predicate in the 'default:' branch of the next switch
           statement; otherwise we can end up in an infinite loop if a
           character is regarded as space by the 'default:' branch but
           not skipped here. S.G. */
        if( isspace( ch ) || ch == '\0' ) {
            /* skip spaces: */
            prevchar = ch;
            ch = getlinec( in, ex );
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
            ch = getlinec( in, ex );
            break;
        case '#':
            if( yy_flex_debug ) {
                printf( ">>> comment: " );
                putchar( ch );
            }
            /* skip comments: */
            pos = cif_flex_current_mark_position();
            while( ch != EOF && ch != '\n' && ch != '\r' ) {
                ch = getlinec( in, ex );
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
                ch = getlinec( in, ex );
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
            ch = getlinec( in, ex );
            break;
        case '_':
            /* data name, or "tag": */
            advance_mark();
            pos = 0;
            pushchar( pos++, ch );
            /* !!! FIXME: check whether a quote or a semicolon
                   immediatly after the tag is a part of the tag or a
                   part of the subsequent quoted/unquoted value: */
            while( !isspace(ch) ) {
                ch = getlinec( in, ex );
                pushchar( pos++, tolower(ch) );
                if( ch == EOF )
                    break;
            }
            ungetlinec( ch, in );
            pos --;
            prevchar = cif_flex_token()[pos-1];
            pushchar( pos, '\0' );
            ciflval.s = clean_string( cif_flex_token(), /* is_textfield = */ 0, ex );
            /* Underscore must be followed by one or more non-empty
               symbol to pass as a correct tag name. */
            if( pos == 1 )
                break;
            if( yy_flex_debug ) {
                printf( ">>> TAG: '%s'\n", cif_flex_token() );
            }
            if( report_long_items ) {
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
            while( !isspace( ch ) && ch != EOF ) {
                pushchar( pos++, ch = getlinec( in, ex ));
            }
            ungetlinec( ch, in );
            pos --;
            prevchar = cif_flex_token()[pos-1];
            pushchar( pos, '\0' );
            ciflval.s = clean_string( cif_flex_token(), /* is_textfield = */ 0, ex );
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
                while( (ch = getlinec( in, ex )) != EOF ) {
                    if( ch == '\n' || ch == '\r' )
                        break;
                    if( ch != quote ) {
                        pushchar( pos++, ch );
                    } else {
                        /* check if the quote terminates the string: */
                        int before = ch;
                        ch = getlinec( in, ex );
                        if( ch == EOF || isspace(ch) ) {
                            /* The quoted string is properly terminated: */
                            ungetlinec( ch, in );
                            pushchar( pos, '\0' );
                            ciflval.s = check_and_clean
                                ( cif_flex_token(), /* is_textfield = */ 0, ex );
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
                ciflval.s = check_and_clean( cif_flex_token(), /* is_textfield = */ 0,
                                            ex );
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
                    ch = getlinec( in, ex );
                    if( ch == ';' &&
                        ( prevchar == '\n' || prevchar == '\r' )) {
                        /* end of the text field detected: */
                        prevchar = ch;
                        int after = getlinec( in, ex );
                        ungetlinec( after, in );
                        if( !isspace( after ) && after != EOF ) {
                            ciferror( "incorrect CIF syntax" );
                        }
                        cif_flex_token()[pos-1] = '\0'; /* delete the last '\n' char */
                        if( yy_flex_debug ) {
                            printf( ">>> TEXT FIELD: '%s'\n", cif_flex_token() );
                        }
                        ciflval.s = clean_string( cif_flex_token(), /* is_textfield = */ 1,
                                                  ex );
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
            while( !isspace( ch ) && ch != EOF ) {
                pushchar( pos++, ch = getlinec( in, ex ));
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
                                         ex );
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
                                             ex );
                    return _SAVE_HEAD;
                }
            } else if( starts_with_keyword( "loop_", cif_flex_token() ) && pos == 5) {
                /* loop header: */
                if( yy_flex_debug ) {
                    printf( ">>> LOOP_\n" );
                }
                ciflval.s = clean_string( cif_flex_token(), /* is_textfield = */ 0, ex );
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
                    ciflval.s = check_and_clean( cif_flex_token(), /* is_textfield = */ 0,
                                                ex );
                    return _UQSTRING;
                } else {
                    if( yy_flex_debug ) {
                        printf( ">>> SQSTRING (corrected bracket): '%s'\n", cif_flex_token() );
                    }
                    ciflval.s = check_and_clean( cif_flex_token(), /* is_textfield = */ 0,
                                                ex );
                    return _SQSTRING;
                }
            }
        }
    }

    return 0;
}

static char *clean_string( char *src, int is_textfield, cexception_t *ex )
{
    int DELTA = 8;
    ssize_t length = strlen( src );
    char *volatile new = mallocx( length + 1, ex );
    char *dest = new;
    char *start = src;
    int non_ascii_explained = 0;

    cexception_t inner;
    cexception_guard( inner ) {
        while( *src != '\0' ) {
            if( ( (*src & 255 ) < 32 || (*src & 255 ) >= 127 )
                && (*src & 255 ) != '\n'
                && (*src & 255 ) != '\t'
                && (*src & 255 ) != '\r' ) {
                if( cif_lexer_has_flags
                (CIF_FLEX_LEXER_FIX_NON_ASCII_SYMBOLS)) {
                    /* Do magic with non-ascii symbols */
                    *dest = '\0';
                    length += DELTA;
                    new = reallocx( new, length + 1, &inner );
                    strcat( new, cxprintf( "&#x%04X;", *src & 255 ) );
                    dest = new + strlen( new ) - 1;
                    if( non_ascii_explained == 0 ) {
                        if( is_textfield == 0 ) {
                            print_message( cif_cc, "WARNING", "non-ascii symbols "
                                           "encountered in the text", ":",
                                           cif_flex_current_line_number(),
                                           cif_flex_current_position()+1,
                                           ex );
                            print_trace( cif_cc, (char*)cif_flex_current_line(),
                                         cif_flex_current_position()+1, ex );
                            non_ascii_explained = 1;
                        } else {
                            print_message( cif_cc, "WARNING", "non-ascii symbols "
                                           "encountered in the text field -- "
                                           "replaced with XML entities", ":",
                                           cif_flex_current_line_number(),
                                           -1, ex );
                            print_current_text_field( cif_cc, start, ex );
                            non_ascii_explained = 1;
                        }
                    }
                } else {
                    if( is_textfield == 0 ) {
                        ciferror( "incorrect CIF syntax" );
                    } else if( non_ascii_explained == 0 ) {
                        print_message( cif_cc, "ERROR", "non-ascii symbols "
                                       "encountered "
                                       "in the text field", ":",
                                       cif_flex_current_line_number(),
                                       -1, ex );
                        print_current_text_field( cif_cc, start, ex );
                        cif_compiler_increase_nerrors( cif_cc );
                        non_ascii_explained = 1;
                    }
                    dest--; /* Omit non-ascii symbols */
                }
            } else if( (*src & 255) == '\r' ) {
                dest--; /* Skip carriage return symbols */
            } else {
                *dest = *src;
            }
            src++;
            dest++;
        }
    }
    cexception_catch {
        freex( new );
        cexception_reraise( inner, ex );
    }
    *dest = '\0';
    return new;
}

static int string_has_high_bytes( unsigned char *s )
{
    if( !s ) return 0;

    while( *s ) {
        if( *s++ >= 127 )
            return 1;
    }
    return 0;
}

static char *check_and_clean( char *token, int is_textfield, cexception_t *ex )
{
    char *s;

    if( string_has_high_bytes
        ( (unsigned char*)token )) {
        if( cif_lexer_has_flags
            (CIF_FLEX_LEXER_FIX_NON_ASCII_SYMBOLS) ) {
            s = clean_string( token, is_textfield, ex );
        } else {
            ciferror( "incorrect CIF syntax" );
            s = strdupx( token, ex );
        }
    } else {
        s = strdupx( token, ex );
    }
    return s;
}
