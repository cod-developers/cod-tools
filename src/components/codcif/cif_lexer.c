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
#include <common.h>
#include <yy.h>
#include <cxprintf.h>
#include <allocx.h>
#include <stringx.h>
#include <assert.h>

static CIF_COMPILER *cif_cc;

static char *current_line;
static size_t currentl_line_length;
static size_t current_pos;

/* Inherited from the Flex scanner: */
static char * thisTokenLine = NULL;
static char * lastTokenLine = NULL;
static char * currentLine = NULL;
static int lineCnt = 1;
static int currLine = 1;
static int prevLine = 1;
static int nextPos;

static int lastTokenPos = 0;
static int thisTokenPos = 0;

static char *token = NULL;
static size_t length = 0;

static int ungot_ch = 0;

static int cif_mandated_line_length = 80;
static int cif_mandated_tag_length = 74;
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

int cif_lexer_set_line_length_limit( int max_length )
{
    int old_value = cif_mandated_line_length;
    cif_mandated_line_length = max_length;
    return old_value;
}

int cif_lexer_set_tag_length_limit( int max_length )
{
    int old_value = cif_mandated_tag_length;
    cif_mandated_tag_length = max_length;
    return old_value;
}

void cif_flex_reset_counters( void )
{
    lineCnt = 1;
    currLine = prevLine = 1;
    current_pos = nextPos = 0;
}
/* end of old Flex scanner functions */

void cif_lexer_set_compiler( CIF_COMPILER *ccc )
{
    cif_cc = ccc;
}

void cif_lexer_cleanup( void )
{
    if( token ) freex( token );
    token = NULL;
    length = 0;
}

static void advance_mark( void )
{
    lastTokenPos = thisTokenPos;
    thisTokenPos = current_pos - 1;
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

static void pushchar( char **buf, size_t *length, size_t pos, int ch );
static void ungetlinec( int ch, FILE *in );
static int getlinec( FILE *in, cexception_t *ex );

static char *clean_string( char *src, int is_textfield, cexception_t *ex );

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
            ch = getlinec( in, ex );
            continue;
        }
        switch( ch ) {
        case '\032': /* DOS EOF (^Z, Ctrl-Z) character */
            thisTokenPos = current_pos > 0 ? current_pos - 1 : 0;
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
            pos = current_pos;
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
            pushchar( &token, &length, pos++, ch );
            while( !is_cif_space(ch) && ch != EOF ) {
                ch = getlinec( in, ex );
                pushchar( &token, &length, pos++, tolower(ch) );
            }
            ungetlinec( ch, in );
            pos --;
            prevchar = token[pos-1];
            pushchar( &token, &length, pos, '\0' );
            ciflval.s = clean_string( token, /* is_textfield = */ 0, ex );
            /* Underscore must be followed by one or more non-empty
               symbol to pass as a correct tag name. */
            if( pos == 1 )
                ciferror( "incorrect CIF syntax" );
            if( yy_flex_debug ) {
                printf( ">>> TAG: '%s'\n", token );
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
            pushchar( &token, &length, pos++, ch );
            while( !is_cif_space( ch ) && ch != EOF ) {
                pushchar( &token, &length, pos++, ch = getlinec( in, ex ));
            }
            ungetlinec( ch, in );
            pos --;
            prevchar = token[pos-1];
            pushchar( &token, &length, pos, '\0' );
            ciflval.s = clean_string( token, /* is_textfield = */ 0, ex );
            if( is_integer( token )) {
                if( yy_flex_debug ) {
                    printf( ">>> INTEGER: '%s'\n", token );
                }
                return _INTEGER_CONST;
            } else if( is_real( token )) {
                if( yy_flex_debug ) {
                    printf( ">>> REAL: '%s'\n", token );
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
                    printf( ">>> UQSTRING (not a number): '%s'\n", token );
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
                        pushchar( &token, &length, pos++, ch );
                    } else {
                        /* check if the quote terminates the string: */
                        int before = ch;
                        ch = getlinec( in, ex );
                        if( ch == EOF || is_cif_space(ch) ) {
                            /* The quoted string is properly terminated: */
                            ungetlinec( ch, in );
                            pushchar( &token, &length, pos, '\0' );
                            ciflval.s = clean_string
                                ( token, /* is_textfield = */ 0, ex );
                            if( yy_flex_debug ) {
                                printf( ">>> *QSTRING (%c): '%s'\n",
                                        quote, token );
                            }
                            return quote == '"' ? _DQSTRING : _SQSTRING;
                        } else {
                            /* The quote does not terminate the
                               string, it is a part of the value: */
                            ungetlinec( ch, in );
                            prevchar = before;
                            pushchar( &token, &length, pos++, before );
                        }
                    }
                }
                /* Unterminated quoted string: */
                prevchar = token[pos-1];
                pushchar( &token, &length, pos, '\0' );
                ciflval.s = clean_string( token, /* is_textfield = */ 0, ex );
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
                        if( !is_cif_space( after ) && after != EOF ) {
                            ciferror( "incorrect CIF syntax" );
                        }
                        token[pos-1] = '\0'; /* delete the last '\n' char */
                        if( yy_flex_debug ) {
                            printf( ">>> TEXT FIELD: '%s'\n", token );
                        }
                        ciflval.s = clean_string( token, /* is_textfield = */ 1,
                                                  ex );
                        return _TEXT_FIELD;
                    }
                    pushchar( &token, &length, pos++, ch );
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
            pushchar( &token, &length, pos++, ch );
            while( !is_cif_space( ch ) && ch != EOF ) {
                pushchar( &token, &length, pos++, ch = getlinec( in, ex ));
            }
            ungetlinec( ch, in );
            prevchar = token[pos-1];
            pos --;
            assert( pos < length );
            assert( pos >= 0 );
            token[pos] = '\0';
            if( starts_with_keyword( "data_", token ) ) {
                /* data block header: */
                if( strlen( token ) == 5 ) {
                    if( cif_lexer_has_flags(CIF_FLEX_LEXER_FIX_DATABLOCK_NAMES) ) {
                        yywarning_token( cif_cc, "zero-length data block name detected "
                                         "-- ignored",
                                         cif_flex_previous_line_number(), -1, ex );
                    } else {
                        ciferror( "zero-length data block name detected" );
                    }
                }
                if( yy_flex_debug ) {
                    printf( ">>> DATA_: '%s'\n", token + 5 );
                }
                ciflval.s = clean_string( token + 5, /* is_textfield = */ 0,
                                          ex );
                return _DATA_;
            } else if( starts_with_keyword( "save_", token )) {
                /* save frame header or terminator: */
                if( strlen( token ) == 5 /* strlen( "save_" ) */ ) {
                    /* This is a save frame terminator: */
                    if( yy_flex_debug ) {
                        printf( ">>> SAVE_\n" );
                    }
                    ciflval.s = NULL;
                    return _SAVE_FOOT;
                } else {
                    if( yy_flex_debug ) {
                        printf( ">>> SAVE_: '%s'\n", token + 5 );
                    }
                    ciflval.s = clean_string( token + 5, /* is_textfield = */ 0,
                                              ex );
                    return _SAVE_HEAD;
                }
            } else if( starts_with_keyword( "loop_", token ) &&
                strlen( token ) == 5) {
                /* loop header: */
                if( yy_flex_debug ) {
                    printf( ">>> LOOP_\n" );
                }
                ciflval.s = clean_string( token, /* is_textfield = */ 0, ex );
                return _LOOP_;
            } else if( starts_with_keyword( "stop_", token ) &&
                strlen( token ) == 5 ) {
                /* stop field: */
                ciferror( "STOP_ symbol detected -- "
                         "it is not acceptable in CIF v1.1" );
            } else if( starts_with_keyword( "global_", token ) &&
                strlen( token ) == 7 ) {
                /* global field: */
                ciferror( "GLOBAL_ symbol detected -- "
                         "it is not acceptable in CIF v1.1" );
            } else {
                if( token[0] == '[' ) {
                    /* opening bracket is a reserved symbol, unquoted strings
                       may not start with it: */
                    if( !cif_lexer_has_flags
                        (CIF_FLEX_LEXER_ALLOW_UQSTRING_BRACKETS)) {
                        ciferror( "opening square brackets are reserved "
                                 "and may not start an unquoted string" );
                    }
                }
                if( token[0] == ']' ) {
                    /* closing bracket is a reserved symbol, unquoted strings
                       may not start with it: */
                    if( !cif_lexer_has_flags
                        (CIF_FLEX_LEXER_ALLOW_UQSTRING_BRACKETS)) {
                        ciferror( "closing square brackets are reserved "
                                 "and may not start an unquoted string" );
                    }
                }
                if( token[0] == '$' ) {
                    /* dollar is a reserved symbol, unquoted strings
                       may not start with it: */
                    ciferror( "dollar symbol ('$') must not start an "
                             "unquoted string" );
                }
                if( token[0] != '[' &&
                    token[0] != ']' &&
                    token[0] != '$' ) {
                    if( yy_flex_debug ) {
                        printf( ">>> UQSTRING: '%s'\n", token );
                    }
                    ciflval.s = clean_string( token, /* is_textfield = */ 0,
                                              ex );
                    return _UQSTRING;
                } else {
                    if( yy_flex_debug ) {
                        printf( ">>> SQSTRING (corrected bracket): '%s'\n", token );
                    }
                    ciflval.s = clean_string( token, /* is_textfield = */ 0,
                                              ex );
                    return _SQSTRING;
                }
            }
        }
    }

    return 0;
}

static void pushchar( char **buf, size_t *length, size_t pos, int ch )
{
    char *str;

    if( !buf || pos >= *length ) {
        size_t max_size = (size_t)-1;
        if( *length == 0 ) {
            *length = 128;
        } else {
            if( *length > max_size / 2 ) {
                cexception_raise( NULL, -99, "cannot double the buffer size" );
            }
        }
        *length *= 2;
        if( yy_flex_debug ) {
            printf( ">>> reallocating lex token buffer to %lu\n", *length );
        }
        *buf = reallocx( *buf, *length, NULL );
    }

    str = *buf;

    assert( pos < *length );
    str[pos] = ch;
}

void ungetlinec( int ch, FILE *in )
{
    ungot_ch = 1;
    /* CHECKME: see if the lines are switched correctly when '\n' is
       pushed back at the end of a DOS new line: */
    if( ch == '\n' || ch == '\r' ) {
        thisTokenLine = lastTokenLine;
        currLine --;
    }
    ungetc( ch, in );
}

static int getlinec( FILE *in, cexception_t *ex )
{
    int ch = getc( in );
    static char prevchar;

    if( ch != EOF && !ungot_ch ) {
        if( ch == '\n' || ch == '\r' ) {
            if( ch == '\r' || (ch == '\n' && prevchar != '\r' &&
                               prevchar != '\n')) {
                prevLine = lineCnt;
                if( lastTokenLine )
                    freex( lastTokenLine );
                if( current_line ) {
                    lastTokenLine = strdupx( current_line, ex );
                    if( report_long_items ) {
                        if( strlen( current_line ) > cif_mandated_line_length ) {
                            yynote_token( cif_cc, cxprintf( "line exceeds %d characters", 
                                              cif_mandated_line_length ),
                                  cif_flex_previous_line_number(), -1, ex );
                        }
                    }
                } else {
                    lastTokenLine = NULL;
                }
            }
            if( ch == '\r' || (ch == '\n' && prevchar != '\r' )) {
                lineCnt ++;
                current_pos = 0;
            }
            pushchar( &current_line, &currentl_line_length, 0, '\0' );
        } else {
            pushchar( &current_line, &currentl_line_length, current_pos++, ch );
            pushchar( &current_line, &currentl_line_length, current_pos, '\0' );
        }
        prevchar = ch;
        currentLine = thisTokenLine = current_line;
        /* printf( ">>> lastTokenLine = '%s'\n", lastTokenLine ); */
        /* printf( ">>> thisTokenLine = '%s'\n", thisTokenLine ); */
    }
    currLine = lineCnt;
    ungot_ch = 0;
    return ch;
}

int cif_flex_current_line_number( void ) { return currLine; }
int cif_flex_previous_line_number( void ) { return prevLine; }
void cif_flex_set_current_line_number( ssize_t line ) { lineCnt = line; }
int cif_flex_current_position( void ) { return thisTokenPos; }
int cif_flex_previous_position( void ) { return lastTokenPos; }
void cif_flex_set_current_position( ssize_t pos ) { current_pos = pos - 1; }
const char *cif_flex_current_line( void ) { return thisTokenLine; }
const char *cif_flex_previous_line( void ) { return lastTokenLine; }

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
                        } else {
                            print_message( cif_cc, "WARNING", "non-ascii symbols "
                                           "encountered in the text field -- "
                                           "replaced with XML entities", ":",
                                           cif_flex_current_line_number(),
                                           -1, ex );
                            print_current_text_field( cif_cc, start, ex );
                        }
                        non_ascii_explained = 1;
                    }
                } else {
                    if( non_ascii_explained == 0 ) {
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
                        }
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
