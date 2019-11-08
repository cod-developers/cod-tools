/*---------------------------------------------------------------------------*\
**$Author$
**$Date$
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

/* exports: */
#include <cif2_lexer.h>

/* uses: */
#include <string.h>
#include <ctype.h>
#include <cif_grammar_flex.h>
#include <cif_grammar_y.h>
#include <cif2_grammar.tab.h>
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

static int ungot_ch = 0;

/* was the last returned symbol a quoted string? */
static int qstring_seen = 0;

static size_t cif_mandated_line_length = 80;
static size_t cif_mandated_tag_length = 74;
static int report_long_items = 0;

int cif2_lexer_set_report_long_items( int flag )
{
    int old_value = report_long_items;
    report_long_items = flag;
    return old_value;
}

int cif2_lexer_report_long_items( void )
{
    return report_long_items;
}

size_t cif2_lexer_set_line_length_limit( size_t max_length )
{
    size_t old_value = cif_mandated_line_length;
    cif_mandated_line_length = max_length;
    return old_value;
}

size_t cif2_lexer_set_tag_length_limit( size_t max_length )
{
    size_t old_value = cif_mandated_tag_length;
    cif_mandated_tag_length = max_length;
    return old_value;
}

void cif2_flex_reset_counters( void )
{
    lineCnt = 1;
    currLine = prevLine = 1;
    current_pos = nextPos = 0;
}
/* end of old Flex scanner functions */

void cif2_lexer_set_compiler( CIF_COMPILER *ccc )
{
    cif_cc = ccc;
}

static void advance_mark( void )
{
    lastTokenPos = thisTokenPos;
    thisTokenPos = current_pos - 1;
}

static int cif_lexer( FILE *in, cexception_t *ex );

int cif2lex( void )
{
    if( !cif_compiler_file( cif_cc ) )
        cif_compiler_set_file( cif_cc, stdin );
    return cif_lexer( cif_compiler_file( cif_cc ), NULL );
}

void cif2restart( void )
{
    /* FIXME: Nothing so far, to be expanded... */
}

static void pushchar( char **buf, size_t *length, size_t pos, int ch );
static void ungetlinec( int ch, FILE *in );
static int getlinec( FILE *in, cexception_t *ex );

static char *clean_string( char *src, int is_textfield, cexception_t *ex );
static void check_utf8( unsigned char *s );
static char *check_and_clean( char *token, int is_textfield,
                              cexception_t *ex );

static int cif_lexer( FILE *in, cexception_t *ex )
{
    int ch = '\0';
    static int prevchar = '\0';
    static char *token = NULL;
    static size_t length = 0;
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
            if( isspace( prevchar ) ) {
                qstring_seen = 0;
            }
            continue;
        }
        switch( ch ) {
        case '\032': /* DOS EOF (^Z, Ctrl-Z) character */
            thisTokenPos = current_pos > 0 ? current_pos - 1 : 0;
            if( cif_lexer_has_flags
                (CIF_FLEX_LEXER_FIX_CTRL_Z) ) {
                yywarning_token( cif_cc, "DOS EOF symbol ^Z was encountered and ignored",
                                 cif2_flex_previous_line_number(), -1, ex );
            } else {
                cif2error( "DOS EOF symbol ^Z was encountered, "
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
            while( ch != EOF && ch != '\n' && ch != '\r' ) {
                ch = getlinec( in, ex );
                if( yy_flex_debug ) {
                    putchar( ch );
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
            pushchar( &token, &length, pos++,
                      tolower(ch = getlinec( in, ex )) );
            /* !!! FIXME: check whether a quote or a semicolon
                   immediatly after the tag is a part of the tag or a
                   part of the subsequent quoted/unquoted value: */
            while( !isspace(ch) ) {
                pushchar( &token, &length, pos++,
                          tolower(ch = getlinec( in, ex )) );
            }
            ungetlinec( ch, in );
            pos --;
            prevchar = token[pos-1];
            pushchar( &token, &length, pos, '\0' );
            check_utf8( (unsigned char *)token );
            cif2lval.s = clean_string( token, /* is_textfield = */ 0, ex );
            if( yy_flex_debug ) {
                printf( ">>> TAG: '%s'\n", token );
            }
            if( report_long_items ) {
                if( strlen( cif2lval.s ) > cif_mandated_tag_length ) {
                    yynote_token( cif_cc, cxprintf( "data name '%s' exceeds %d characters",
                                      cif2lval.s, cif_mandated_tag_length ),
                                  cif2_flex_previous_line_number(), -1, ex );
                }
            }
            qstring_seen = 0;
            return _TAG;
            break;

        case '.': case '+': case '-': case '0': case '1': case '2': case '3':
        case '4': case '5': case '6': case '7': case '8': case '9':
            pos = 0;
            advance_mark();
            pushchar( &token, &length, pos++, ch );
            while( !isspace( ch ) && ch != EOF &&
                    ch != '[' && ch != ']' && ch != '{' && ch != '}' ) {
                pushchar( &token, &length, pos++, ch = getlinec( in, ex ));
            }
            ungetlinec( ch, in );
            pos --;
            prevchar = token[pos-1];
            pushchar( &token, &length, pos, '\0' );
            check_utf8( (unsigned char*)token );
            cif2lval.s = clean_string( token, /* is_textfield = */ 0, ex );
            if( is_integer( token )) {
                if( yy_flex_debug ) {
                    printf( ">>> INTEGER: '%s'\n", token );
                }
                qstring_seen = 0;
                return _INTEGER_CONST;
            } else if( is_real( token )) {
                if( yy_flex_debug ) {
                    printf( ">>> REAL: '%s'\n", token );
                }
                qstring_seen = 0;
                return _REAL_CONST;
            } else {
                if( yy_flex_debug ) {
                /* !!! FIXME: check whether it is really a real number.
                       Currently it is assumed that a sequence of digits 
                       that is not an integer number is automatically a 
                       real number without explicitly impossing that it 
                       should not contain any other symbols besides 
                       [.0-9] */
                    printf( ">>> UQSTRING (not a number): '%s'\n", token );
                }
                qstring_seen = 0;
                return _UQSTRING;
            }
            break;
        case '"': case '\'':
            {
                /* quoted strings: */
                int quote = ch;
                advance_mark();
                pos = 0;
                int quote_count = 1;
                while( (ch = getlinec( in, ex )) == quote ) {
                    quote_count++;                    
                }
                ungetlinec( ch, in );
                int type = quote == '"' ? _DQSTRING : _SQSTRING;
                if(        quote_count == 1 ) {
                    /* start of quote-delimited string */
                } else if( quote_count == 2 ) {
                    /* empty quote-delimited string */
                    ch = getlinec( in, ex );
                    if( !isspace( ch ) && ch != EOF && ch != ':' &&
                        ch != '[' && ch != ']' && ch != '{' && ch != '}' ) {
                        /* quoted string must be followed by a space
                         * or ':' in case of table keys */
                        cif2error( "incorrect CIF syntax" );
                    }
                    ungetlinec( ch, in );
                    token[0] = '\0';
                    cif2lval.s = strdupx( token, ex );
                    if( yy_flex_debug ) {
                        printf( ">>> *QSTRING (%c): ''\n",
                                quote );
                    }
                    qstring_seen = 1;
                    return type;
                } else if( quote_count == 3 ) {
                    /* start of triple quote-delimited string */
                    type = quote == '"' ? _DQ3STRING : _SQ3STRING;
                } else if( quote_count >= 4 && quote_count <= 5 ) {
                    /* quote(s) inside triple quote-delimited string */
                    int i;
                    for( i = 0; i < quote_count - 3; i++ ) {
                        ungetlinec( quote, in );
                    }
                    type = quote == '"' ? _DQ3STRING : _SQ3STRING;
                } else {
                    /* empty triple quote-delimited string with
                     * something quoted attached to its end */
                    int i;
                    for( i = 0; i < quote_count - 6; i++ ) {
                        ungetlinec( quote, in );
                    }
                    ch = getlinec( in, ex );
                    if( !isspace( ch ) && ch != EOF && ch != ':' &&
                        ch != '[' && ch != ']' && ch != '{' && ch != '}' ) {
                        /* quoted string must be followed by a space
                           or ':' in case of table keys */
                        cif2error( "incorrect CIF syntax" );
                    }
                    ungetlinec( ch, in );
                    token[0] = '\0';
                    cif2lval.s = strdupx( token, ex );
                    type = quote == '"' ? _DQ3STRING : _SQ3STRING;
                    if( yy_flex_debug ) {
                        printf( ">>> *Q3STRING (%c): ''\n",
                                quote );
                    }
                    qstring_seen = 1;
                    return type;
                }
                quote_count = 0;
                while( (ch = getlinec( in, ex )) != EOF ) {
                    if( type == _DQSTRING || type == _SQSTRING ) {
                        if( ch == '\n' || ch == '\r' ) {
                            break;
                        }
                        if( ch == quote ) {
                            /* properly terminated quote-delimited string: */
                            ch = getlinec( in, ex );
                            if( !isspace( ch ) && ch != EOF && ch != ':' &&
                                ch != '[' && ch != ']' && ch != '{' && ch != '}' ) {
                                /* quoted string must be followed by a space
                                 * or ':' in case of table keys */
                                cif2error( "incorrect CIF syntax" );
                            }
                            ungetlinec( ch, in );
                            pushchar( &token, &length, pos, '\0' );
                            cif2lval.s = check_and_clean
                                ( token, /* is_textfield = */ 0, ex );
                            if( yy_flex_debug ) {
                                printf( ">>> *QSTRING (%c): '%s'\n",
                                        quote, token );
                            }
                            qstring_seen = 1;
                            return type;
                        }                        
                    } else {
                        if( ch == quote ) {
                            quote_count++;
                        } else if( quote_count >= 3 ) {
                            /* terminated triple-quoted string: */
                            ungetlinec( ch, in );
                            if( !isspace( ch ) && ch != EOF && ch != ':' &&
                                ch != '[' && ch != ']' && ch != '{' && ch != '}' ) {
                                /* quoted string must be followed by a space
                                 * or ':' in case of table keys */
                                cif2error( "incorrect CIF syntax" );
                            }
                            pushchar( &token, &length, pos-3, '\0' );
                            cif2lval.s = check_and_clean
                                ( token, /* is_textfield = */ 0, ex );
                            if( yy_flex_debug ) {
                                printf( ">>> *Q3STRING (%c): '%s'\n",
                                        quote, token );
                            }
                            qstring_seen = 1;
                            return type;
                        } else {
                            quote_count = 0;
                        }                        
                    }
                    pushchar( &token, &length, pos++, ch );
                }
                /* Unterminated quoted string: */
                prevchar = token[pos-1];
                pushchar( &token, &length, pos, '\0' );
                cif2lval.s = check_and_clean( token, /* is_textfield = */ 0,
                                            ex );
                switch( quote ) {
                    case '"':
                        if( cif_lexer_has_flags
                            (CIF_FLEX_LEXER_FIX_MISSING_CLOSING_DOUBLE_QUOTE)
                            ) {
                            yywarning_token( cif_cc, "double-quoted string is missing "
                                             "a closing quote -- fixed",
                                             cif2_flex_previous_line_number(), -1, ex );
                        } else {
                            yyerror_token( cif_cc, "incorrect CIF syntax",
                                           cif2_flex_current_line_number()-1,
                                           cif2_flex_current_position()+1,
                                           (char*)cif2_flex_previous_line(),
                                           ex );
                        }
                        break;
                    case '\'':
                        if( cif_lexer_has_flags
                            (CIF_FLEX_LEXER_FIX_MISSING_CLOSING_SINGLE_QUOTE)
                            ) {
                            yywarning_token( cif_cc, "single-quoted string is missing "
                                             "a closing quote -- fixed",
                                             cif2_flex_previous_line_number(), -1, ex );
                        } else {
                            yyerror_token( cif_cc, "incorrect CIF syntax",
                                           cif2_flex_current_line_number()-1,
                                           cif2_flex_current_position()+1,
                                           (char*)cif2_flex_previous_line(),
                                           ex );
                        }
                        break;
                }
                qstring_seen = 1;
                return quote == '"' ? _DQSTRING : _SQSTRING;
            }
            break;
        case '[': case ']': case '{': case '}':
            advance_mark();
            qstring_seen = 0;
            int after = getlinec( in, ex );
            ungetlinec( after, in );
            if( (ch == ']' || ch == '}') &&
                (after != EOF && !isspace( after ) && after != ']' && after != '}') ) {
                cif2error( "incorrect CIF syntax" );
            }
            if( yy_flex_debug ) {
                printf( ">>> LIST/TABLE DELIMITER\n" );
            }
            return ch;
        case ':':
            if( qstring_seen == 1 ) {
                /* table entry separator */
                if( yy_flex_debug ) {
                    printf( ">>> TABLE ENTRY SEPARATOR: ':'\n" );
                }
                qstring_seen = 0;
                return _TABLE_ENTRY_SEP;
            }
            /* else this is an ordinary unquoted string -- drop
               through to the 'default:' case (no break here,
               deliberately!): */
        case ';':
            /* the character has to be checked to be equal to ';' in order
               to detect whether the lexer has arrived here after matching
               ';' or dropped through from ':': */
            if( ch == ';' && ( prevchar == '\n' || prevchar == '\0' ) ) {
                /* multi-line text field: */
                advance_mark();
                ssize_t textfield_start = cif2_flex_current_line_number();
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
                            cif2error( "incorrect CIF syntax" );
                        }
                        token[pos-1] = '\0'; /* delete the last '\n' char */
                        if( yy_flex_debug ) {
                            printf( ">>> TEXT FIELD: '%s'\n", token );
                        }
                        check_utf8( (unsigned char*)token );
                        cif2lval.s = clean_string( token, /* is_textfield = */ 1,
                                                 ex );
                        qstring_seen = 0;
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
                               cif2_flex_current_line_number()-1, -1,
                               NULL, ex );
            }
            /* else this is an ordinary unquoted string -- drop
               through to the 'default:' case (no break here,
               deliberately!): */
        default:
            pos = 0;
            advance_mark();
            pushchar( &token, &length, pos++, ch );
            int is_container_code = 0;
            while( !isspace( ch ) && ch != EOF &&
                   (is_container_code ||
                    (ch != '[' && ch != ']' && ch != '{' && ch != '}')) ) {
                pushchar( &token, &length, pos++, ch = getlinec( in, ex ));
                if( pos == 5 &&
                    ( starts_with_keyword( "data_", token ) ||
                      starts_with_keyword( "save_", token ) ) ) {
                    is_container_code = 1;
                }
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
                                         cif2_flex_previous_line_number(), -1, ex );
                    } else {
                        cif2error( "zero-length data block name detected" );
                    }
                }
                if( yy_flex_debug ) {
                    printf( ">>> DATA_: '%s'\n", token + 5 );
                }
                check_utf8( (unsigned char*)token );
                cif2lval.s = clean_string( token + 5, /* is_textfield = */ 0,
                                         ex );
                qstring_seen = 0;
                return _DATA_;
            } else if( starts_with_keyword( "save_", token )) {
                /* save frame header or terminator: */
                if( strlen( token ) == 5 /* strlen( "save_" ) */ ) {
                    /* This is a save frame terminator: */
                    if( yy_flex_debug ) {
                        printf( ">>> SAVE_\n" );
                    }
                    cif2lval.s = NULL;
                    qstring_seen = 0;
                    return _SAVE_FOOT;
                } else {
                    if( yy_flex_debug ) {
                        printf( ">>> SAVE_: '%s'\n", token + 5 );
                    }
                    check_utf8( (unsigned char*)token );
                    cif2lval.s = clean_string( token + 5, /* is_textfield = */ 0,
                                             ex );
                    qstring_seen = 0;
                    return _SAVE_HEAD;
                }
            } else if( starts_with_keyword( "loop_", token ) &&
                strlen( token ) == 5) {
                /* loop header: */
                if( yy_flex_debug ) {
                    printf( ">>> LOOP_\n" );
                }
                check_utf8( (unsigned char*)token );
                cif2lval.s = clean_string( token, /* is_textfield = */ 0, ex );
                qstring_seen = 0;
                return _LOOP_;
            } else if( starts_with_keyword( "stop_", token ) &&
                strlen( token ) == 5 ) {
                /* stop field: */
                cif2error( "STOP_ symbol detected -- "
                         "it is not acceptable in CIF v2.0" );
            } else if( starts_with_keyword( "global_", token ) &&
                strlen( token ) == 7 ) {
                /* global field: */
                cif2error( "GLOBAL_ symbol detected -- "
                         "it is not acceptable in CIF v2.0" );
            } else {
                cif2lval.s = check_and_clean( token, /* is_textfield = */ 0,
                                            ex );
                qstring_seen = 0;
                if( token[0] == '$' ) {
                    /* dollar is a reserved symbol, unquoted strings
                       may not start with it: */
                    cif2error( "dollar symbol ('$') must not start an "
                               "unquoted string" );
                    if( yy_flex_debug ) {
                        printf( ">>> SQSTRING (corrected dollar): '%s'\n", token );
                    }
                    return _SQSTRING;
                } else {
                    if( yy_flex_debug ) {
                        printf( ">>> UQSTRING: '%s'\n", token );
                    }
                    return _UQSTRING;
                }
            }
        }
    }

    qstring_seen = 0;
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
                                  cif2_flex_previous_line_number(), -1, ex );
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

int cif2_flex_current_line_number( void ) { return currLine; }
int cif2_flex_previous_line_number( void ) { return prevLine; }
void cif2_flex_set_current_line_number( ssize_t line ) { lineCnt = line; }
int cif2_flex_current_position( void ) { return thisTokenPos; }
int cif2_flex_previous_position( void ) { return lastTokenPos; }
void cif2_flex_set_current_position( ssize_t pos ) { current_pos = pos - 1; }
const char *cif2_flex_current_line( void ) { return thisTokenLine; }
const char *cif2_flex_previous_line( void ) { return lastTokenLine; }

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
            if( ((*src & 255 ) < 32 &&
                (*src & 255 ) != '\n' &&
                (*src & 255 ) != '\t' &&
                (*src & 255 ) != '\r' ) || ( *src & 255 ) == 127 ) {
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
                                           cif2_flex_current_line_number(),
                                           cif2_flex_current_position()+1,
                                           ex );
                            print_trace( cif_cc, (char*)cif2_flex_current_line(),
                                         cif2_flex_current_position()+1, ex );
                            non_ascii_explained = 1;
                        } else {
                            print_message( cif_cc, "WARNING", "non-ascii symbols "
                                           "encountered in the text field -- "
                                           "replaced with XML entities", ":",
                                           cif2_flex_current_line_number(),
                                           -1, ex );
                            print_current_text_field( cif_cc, start, ex );
                            non_ascii_explained = 1;
                        }
                    }
                } else {
                    if( is_textfield == 0 ) {
                        cif2error( "incorrect CIF syntax" );
                    } else if( non_ascii_explained == 0 ) {
                        print_message( cif_cc, "ERROR", "non-ascii symbols "
                                       "encountered "
                                       "in the text field", ":",
                                       cif2_flex_current_line_number(),
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

static int string_has_control_chars( unsigned char *s )
{
    if( !s ) return 0;

    while( *s ) {
        if( (*s < 32 && *s != '\n' && *s != '\t' && *s != '\r' ) ||
            *s == 127 )
            return 1;
        s++;
    }
    return 0;
}

static void check_utf8( unsigned char *s )
{
    if( !s ) return;
    int continuation_bytes = 0;
    unsigned long ch = 0;

    while( *s ) {
        if( continuation_bytes && *s >= 0x80 && *s < 0xC0 ) {
            continuation_bytes--;
            ch = (ch << 6) | (*s & 0x3F );
            if( continuation_bytes == 0 ) {
                if( (ch > 0x007E && ch < 0x00A0) ||
                    (ch > 0xD7FF && ch < 0xE000) ||
                    (ch > 0xFDCF && ch < 0xFDF0) ||
                    ((ch & 0xFFFF) == 0xFFFE) ||
                    ((ch & 0xFFFF) == 0xFFFF) ) {
                    cif2error( cxprintf( "Unicode codepoint U+%04X is not "
                                         "allowed in CIF v2.0", ch ) );
                }
            }
        } else if( continuation_bytes ) {
            cif2error( "incorrect UTF-8" );
            continuation_bytes = 0;
            ch = 0;
        } else if( *s >= 0x80 && *s < 0xC0 ) {
            cif2error( "stray UTF-8 continuation byte" );
        } else if( (*s & 0xF8) == 0xF0 ) {
            continuation_bytes = 3;
            ch = *s & 7;
        } else if( (*s & 0xF0) == 0xE0 ) {
            continuation_bytes = 2;
            ch = *s & 15;
        } else if( (*s & 0xE0) == 0xC0 ) {
            continuation_bytes = 1;
            ch = *s & 31;
        } else if( *s >= 0xF8 ) {
            cif2error( "more than 4 byte UTF-8 codepoints "
                       "are not allowed" );
        }
        s++;
    }

    if( continuation_bytes ) {
        cif2error( "prematurely terminated UTF-8 codepoint" );
    }
}

static char *check_and_clean( char *token, int is_textfield, cexception_t *ex )
{
    char *s;

    check_utf8( (unsigned char*)token );

    if( string_has_control_chars
        ( (unsigned char*)token )) {
        if( cif_lexer_has_flags
            (CIF_FLEX_LEXER_FIX_NON_ASCII_SYMBOLS) ) {
            s = clean_string( token, is_textfield, ex );
        } else {
            cif2error( "incorrect CIF syntax" );
            s = strdupx( token, ex );
        }
    } else {
        s = strdupx( token, ex );
    }
    return s;
}
