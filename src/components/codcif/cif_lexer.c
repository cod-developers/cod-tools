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

FILE *yyin;

static char *current_line;
size_t currentl_line_length;
size_t current_pos;

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

void cif_flex_reset_counters( void )
{
    lineCnt = 1;
    currLine = prevLine = 1;
    current_pos = nextPos = 0;
}
/* end of old Flex scanner functions */

static void advance_mark( void )
{
    lastTokenPos = thisTokenPos;
    thisTokenPos = current_pos - 1;
}

int yylex( void )
{
    if( !yyin )
        yyin = stdin;
    return cif_lexer( yyin, NULL );
}

void yyrestart( void )
{
    /* FIXME: Nothing so far, to be expanded... */
}

static int starts_with_keyword( char *keyword, char *string );
static int is_integer( char *s );
static int is_real( char *s );

static void pushchar( char **buf, size_t *length, size_t pos, int ch );
static void ungetlinec( char ch, FILE *in );
static int getlinec( FILE *in, cexception_t *ex );

static char *clean_string( char *src, int is_textfield, cexception_t *ex );
static int string_has_high_bytes( unsigned char *s );
static char *check_and_clean( char *token, int is_textfield,
                              cexception_t *ex );

int cif_lexer( FILE *in, cexception_t *ex )
{
    int ch = '\0';
    static char prevchar = '\0';
    static char *token = NULL;
    static size_t length = 0;
    int pos;

    while( ch != EOF ) {
        /* It is important that the predicate that checks for spaces
           in the fi() statement below is the same as the ispace()
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
            thisTokenPos = current_pos > 0 ? current_pos - 1 : 0;
            if( cif_lexer_has_flags
                (CIF_FLEX_LEXER_FIX_CTRL_Z) ) {
                yynote( "DOS EOF symbol ^Z was encountered and ignored", ex );
            } else {
                yyerror( "DOS EOF symbol ^Z was encountered, "
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
                char before = ch;
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
            yylval.s = clean_string( token, /* is_textfield = */ 0, ex );
            if( yy_flex_debug ) {
                printf( ">>> TAG: '%s'\n", token );
            }
            return _TAG;
            break;

        case '.': case '+': case '-': case '0': case '1': case '2': case '3':
        case '4': case '5': case '6': case '7': case '8': case '9':
            pos = 0;
            advance_mark();
            pushchar( &token, &length, pos++, ch );
            while( !isspace( ch ) && ch != EOF ) {
                pushchar( &token, &length, pos++, ch = getlinec( in, ex ));
            }
            ungetlinec( ch, in );
            pos --;
            prevchar = token[pos-1];
            pushchar( &token, &length, pos, '\0' );
            yylval.s = clean_string( token, /* is_textfield = */ 0, ex );
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
                       real number without explicitly impossing that it 
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
                unsigned char quote = ch;
                advance_mark();
                pos = 0;
                while( (ch = getlinec( in, ex )) != EOF ) {
                    if( ch == '\n' || ch == '\r' )
                        break;
                    if( ch != quote ) {
                        pushchar( &token, &length, pos++, ch );
                    } else {
                        /* check if the quote terminates the string: */
                        char before = ch;
                        ch = getlinec( in, ex );
                        if( ch == EOF || isspace(ch) ) {
                            /* The quoted string is properly terminated: */
                            ungetlinec( ch, in );
                            prevchar = token[pos-1];
                            pushchar( &token, &length, pos, '\0' );
                            yylval.s = check_and_clean
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
                yylval.s = check_and_clean( token, /* is_textfield = */ 0,
                                            ex );
                switch( quote ) {
                    case '"':
                        if( cif_lexer_has_flags
                            (CIF_FLEX_LEXER_FIX_MISSING_CLOSING_DOUBLE_QUOTE)
                            ) {
                            yywarning( "double-quoted string is missing "
                                       "a closing quote -- fixed", ex );
                        } else {
                            yyerror( "incorrect CIF syntax" );
                        }
                        break;
                    case '\'':
                        if( cif_lexer_has_flags
                            (CIF_FLEX_LEXER_FIX_MISSING_CLOSING_SINGLE_QUOTE)
                            ) {
                            yywarning( "single-quoted string is missing "
                                       "a closing quote -- fixed", ex );
                        } else {
                            yyerror( "incorrect CIF syntax" );
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
                pos = 0;
                while( ch != EOF ) {
                    prevchar = ch;
                    ch = getlinec( in, ex );
                    if( ch == ';' &&
                        ( prevchar == '\n' || prevchar == '\r' )) {
                        /* end of the text field detected: */
                        prevchar = ch;
                        char after = getlinec( in, ex );
                        ungetlinec( after, in );
                        if( !isspace( after ) && after != EOF ) {
                            yyerror( "incorrect CIF syntax" );
                        }
                        token[pos-1] = '\0'; /* delete the last '\n' char */
                        if( yy_flex_debug ) {
                            printf( ">>> TEXT FIELD: '%s'\n", token );
                        }
                        yylval.s = clean_string( token, /* is_textfield = */ 1,
                                                 ex );
                        return _TEXT_FIELD;
                    }
                    pushchar( &token, &length, pos++, ch );
                }
                /* Unterminated text field: */
                yyerrorf( "unterminated text field" );
            }
            /* else this is an ordinary unquoted string -- drop
               through to the 'default:' case (no break here,
               deliberately!): */
        default:
            pos = 0;
            advance_mark();
            pushchar( &token, &length, pos++, ch );
            while( !isspace( ch ) && ch != EOF ) {
                pushchar( &token, &length, pos++, ch = getlinec( in, ex ));
            }
            ungetlinec( ch, in );
            prevchar = token[pos-1];
            pos --;
            assert( pos < length );
            assert( pos >= 0 );
            token[pos] = '\0';
            if( starts_with_keyword( "data_", token )) {
                /* data block header: */
                if( yy_flex_debug ) {
                    printf( ">>> DATA_: '%s'\n", token + 5 );
                }
                yylval.s = clean_string( token + 5, /* is_textfield = */ 0,
                                         ex );
                return _DATA_;
            } else if( starts_with_keyword( "loop_", token )) {
                /* loop header: */
                if( yy_flex_debug ) {
                    printf( ">>> LOOP_\n" );
                }
                yylval.s = clean_string( token, /* is_textfield = */ 0, ex );
                return _LOOP_;
            } else if( starts_with_keyword( "stop_", token ) &&
                strlen( token ) == 5 ) {
                /* stop field: */
                yyerrorf( "STOP_ symbol detected in line %i, pos. %i -- "
                          "it is not acceptable in this version",
                          cif_flex_current_line_number(),
                          cif_flex_current_position() );
            } else {
                if( token[0] == '[' ) {
                    /* bracket is a reserved symbol, unquoted strings
                       may not start with it: */
                    if( !cif_lexer_has_flags
                        (CIF_FLEX_LEXER_ALLOW_UQSTRING_BRACKETS)) {
                        yyerror( "opening square brackets are reserved "
                                 "and may not start an unquoted string" );
                    }
                }
                if( token[0] == '$' ) {
                    /* dollar is a reserved symbol, unquoted strings
                       may not start with it: */
                    yyerror( "dollar symbol ('$') must not start an "
                             "unquoted string" );
                }
                if( token[0] != '[' && token[0] != '$' ) {
                    if( yy_flex_debug ) {
                        printf( ">>> UQSTRING: '%s'\n", token );
                    }
                    yylval.s = check_and_clean( token, /* is_textfield = */ 0,
                                                ex );
                    return _UQSTRING;
                } else {
                    if( yy_flex_debug ) {
                        printf( ">>> SQSTRING (corrected bracket): '%s'\n", token );
                    }
                    yylval.s = check_and_clean( token, /* is_textfield = */ 0,
                                                ex );
                    return _SQSTRING;
                }
            }
        }
    }

    return 0;
}

static int starts_with_keyword( char *keyword, char *string )
{
    size_t length1 = strlen( keyword );
    size_t length2 = strlen( string );
    size_t length = length1 < length2 ? length1 : length2;

    if( length < length1 )
        return 0;

    while( length-- > 0 ) {
        if( *keyword++ != tolower(*string++) ) {
            return 0;
        }
    }
    return 1;
}

static int is_integer( char *s )
{
    int has_opening_brace = 0;

    if( !s ) return 0;

    if( !isdigit(*s) && *s != '+' && *s != '-' ) {
        return 0;
    }

    if( *s == '+' || *s == '-' ) s++;

    if( !isdigit(*s) ) return 0;

    while( *s && *s != '(' ) {
        if( !isdigit(*s++) ) {
            return 0;
        }
    }

    if( *s && *s != '(' ) return 0;
    if( *s && *s == '(' ) {
        s++;
        has_opening_brace = 1;
    }

    while( *s && *s != ')' ) {
        if( !isdigit(*s++) ) {
            return 0;
        }        
    }

    if( *s != ')' && has_opening_brace ) return 0;
    if( *s == ')' ) s++;

    if( *s != '\0' ) return 0;

    return 1;
}

static int is_real( char *s )
{
    int has_decimal = 0, has_digits = 0;

    if( !s || !*s ) return 0;

    if( !isdigit(*s) && *s != '+' && *s != '-' && *s != '.' ) {
        return 0;
    }

    if( *s == '+' || *s == '-' ) s++;

    /* decimal point may follow the sign, as in +.0123 */
    if( *s == '.' ) {
        s ++;
        has_decimal = 1;
    }

    if( !isdigit(*s) ) return 0;

    while( isdigit(*s) ) {
        s++;
        has_digits = 1;
    }

    if( *s == '.' ) {
        if( has_decimal ) {
            return 0;
        } else {
            has_decimal = 1;
            s ++;
        }
    }

    while( isdigit(*s) ) {
        s++;
        has_digits = 1;
    }

    if( !has_digits ) return 0;

    /* By now, of we have seen digits and the string has ended, we
       accept reg real number. We could insist here that we have a
       decimal point so that integers are not counte das reals, but
       since integer will be checked before reals we can happily
       accept integers as reals as well (which is mathematically more
       correct ;): */
    if( *s == '\0' ) return 1;

    if( *s != '(' &&
        *s != 'E' && *s != 'e' &&
        *s != 'D' && *s != 'd' /* Fortranish :) */
        ) {
        return 0;
    }

    if( *s == 'E' || *s == 'e' ||
        *s == 'D' || *s == 'd' ) {
        s ++;
        if( *s == '+' || *s == '-' ) s++;
        if( !isdigit(*s) ) {
            return 0;
        }
        while( isdigit(*s) ) s++;
    }

    if( *s == '\0' ) return 1;
    if( *s != '(' )
        return 0;
    else
        s++;
    if( !isdigit(*s) ) return 0;
    while( isdigit(*s) ) s++;
    if( *s == ')' ) s++;
    if( *s != '\0' ) return 0;

    return 1;
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
                cexception_raise( NULL, -99, "can not double the buffer size" );
            }
        }
        *length *= 2;
        if( yy_flex_debug ) {
            printf( ">>> reallocating lex token buffer to %d\n", *length );
        }
        *buf = reallocx( *buf, *length, NULL );
    }

    str = *buf;

    assert( pos < *length );
    str[pos] = ch;
}

void ungetlinec( char ch, FILE *in )
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
                if( current_line )
                    lastTokenLine = strdupx( current_line, ex );
                else
                    lastTokenLine = NULL;
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
            if( ( (*src & 255 ) < 16 || (*src & 255 ) > 127 )
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
                            print_message( "WARNING", "non-ascii symbols "
                                           "encountered in the text",
                                           cif_flex_current_line_number(),
                                           cif_flex_current_position()+1,
                                           ex );
#if 0
                            fprintf( stderr, "'%s'\n", 
                                     cif_flex_current_line() );
#else
                            print_current_trace( ex );
#endif
                            non_ascii_explained = 1;
                        } else {
                            print_message( "WARNING", "non-ascii symbols "
                                           "encountered in the text field, "
                                           "replaced by XML entities",
                                           cif_flex_current_line_number(),
                                           -1, ex );
#if 0
                            fprintf( stderr, ";%s\n;\n\n", start );
#else
                            print_current_text_field( start, ex );
#endif
                            non_ascii_explained = 1;
                        }
                    }
                } else {
                    if( is_textfield == 0 ) {
                        yyerror( "incorrect CIF syntax" );
                    } else if( non_ascii_explained == 0 ) {
                        print_message( "WARNING", "non-ascii symbols "
                                       "encountered "
                                       "in the text field",
                                       cif_flex_current_line_number(),
                                       -1, ex );
#if 0
                        fprintf( stderr, ";%s\n;\n\n", start );
#else
                        print_current_text_field( start, ex );
#endif
                        yyincrease_error_counter();
                        non_ascii_explained = 1;
                    }
                    dest--; /* Omit non-ascii symbols */
                }
            } else if( (*src & 255 ) == '\t' ) {
                *dest = '\0';
                length += 3;
                new = realloc( new, length + 1 );
                strcat( new, "    " );
                dest = new + strlen( new ) - 1;
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
        if( *s++ > 127 )
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
            yyerror( "incorrect CIF syntax" );
            s = strdupx( token, ex );
        }
    } else {
        s = strdupx( token, ex );
    }
    return s;
}
