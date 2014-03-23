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
    return cif_lexer( yyin );
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
static int getlinec( FILE *in );

static char *clean_string( char *src, int is_textfield );
static int string_has_high_bytes( unsigned char *s );
static char *check_and_clean( char *token, int is_textfield );

int cif_lexer( FILE *in )
{
    int ch = '\0';
    static char prevchar = '\0';
    static char *token = NULL;
    static size_t length = 0;
    int pos;

    while( ch != EOF ) {
        switch( ch ) {
        case '\032': /* DOS EOF (^Z, Ctrl-Z) character */
            thisTokenPos = current_pos > 0 ? current_pos - 1 : 0;
            if( cif_lexer_has_flags
                (CIF_FLEX_LEXER_FIX_CTRL_Z) ) {
                yynote( "DOS EOF symbol ^Z was encountered and ignored" );
            } else {
                yyerror( "DOS EOF symbol ^Z was encountered, "
                         "it is not permitted in CIFs" );
            }
            prevchar = ch;
            ch = getlinec( in );
            break;
        case '\n': case '\r': case ' ': case '\t': case '\0':
            /* skip spaces after comments: */
            prevchar = ch;
            ch = getlinec( in );
            break;
        case '#':
            if( yy_flex_debug ) {
                printf( ">>> comment: " );
                putchar( ch );
            }
            /* skip comments: */
            while( ch != EOF && ch != '\n' && ch != '\r' ) {
                ch = getlinec( in );
                if( yy_flex_debug ) {
                    putchar( ch );
                }
            }
            if( ch == '\r' ) {
                /* check and process the DOS newlines: */
                char before = ch;
                ch = getlinec( in );
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
            ch = getlinec( in );
            break;
        case '_':
            /* data name, or "tag": */
            advance_mark();
            pos = 0;
            pushchar( &token, &length, pos++, ch );
            pushchar( &token, &length, pos++, tolower(ch = getlinec( in )) );
            /* !!! FIXME: check whether a quote or a semicolon
                   immediatly after the tag is a part of the tag or a
                   part of the subsequent quoted/unquoted value: */
            while( !isspace(ch) ) {
                pushchar( &token, &length, pos++, tolower(ch = getlinec( in )) );
            }
            ungetlinec( ch, in );
            pos --;
            prevchar = token[pos-1];
            pushchar( &token, &length, pos, '\0' );
            yylval.s = clean_string( token, /* is_textfield = */ 0 );
            if( yy_flex_debug ) {
                printf( ">>> TAG: '%s'\n", token );
            }
            return _TAG;
            break;

        case '+': case '-': case '0': case '1': case '2': case '3':
        case '4': case '5': case '6': case '7': case '8': case '9':
            pos = 0;
            advance_mark();
            pushchar( &token, &length, pos++, ch );
            while( !isspace( ch ) && ch != EOF ) {
                pushchar( &token, &length, pos++, ch = getlinec( in ));
            }
            ungetlinec( ch, in );
            pos --;
            prevchar = token[pos-1];
            pushchar( &token, &length, pos, '\0' );
            yylval.s = clean_string( token, /* is_textfield = */ 0 );
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
                while( (ch = getlinec( in )) != EOF ) {
                    if( ch == '\n' || ch == '\r' )
                        break;
                    if( ch != quote ) {
                        pushchar( &token, &length, pos++, ch );
                    } else {
                        /* check if the quote terminates the string: */
                        char before = ch;
                        ch = getlinec( in );
                        if( ch == EOF || isspace(ch) ) {
                            /* The quoted string is properly terminated: */
                            ungetlinec( ch, in );
                            prevchar = token[pos-1];
                            pushchar( &token, &length, pos, '\0' );
                            yylval.s = check_and_clean
                                ( token, /* is_textfield = */ 0 );
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
                yylval.s = check_and_clean( token, /* is_textfield = */ 0 );
                if( cif_lexer_has_flags
                    (CIF_FLEX_LEXER_FIX_MISSING_CLOSING_DOUBLE_QUOTE) ) {
                    yynote( "warning, double-quoted string is missing "
                            "a closing quote -- fixed" );
                } else {
                    yyerror( "syntax error" );
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
                    ch = getlinec( in );
                    if( ch == ';' &&
                        ( prevchar == '\n' || prevchar == '\r' )) {
                        /* end of the text field detected: */
                        prevchar = ch;
                        token[pos-1] = '\0'; /* delete the last '\n' char */
                        if( yy_flex_debug ) {
                            printf( ">>> TEXT FIELD: '%s'\n", token );
                        }
                        yylval.s = clean_string( token, /* is_textfield = */ 1 );
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
                pushchar( &token, &length, pos++, ch = getlinec( in ));
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
                yylval.s = clean_string( token + 5, /* is_textfield = */ 0 );
                return _DATA_;
            } else if( starts_with_keyword( "loop_", token )) {
                /* loop header: */
                if( yy_flex_debug ) {
                    printf( ">>> LOOP_\n" );
                }
                yylval.s = clean_string( token, /* is_textfield = */ 0 );
                return _LOOP_;
            } else {
                if( yy_flex_debug ) {
                    printf( ">>> UQSTRING: '%s'\n", token );
                }
                yylval.s = check_and_clean( token, /* is_textfield = */ 0 );
                return _UQSTRING;
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
    }
    ungetc( ch, in );
}

static int getlinec( FILE *in )
{
    int ch = getc( in );
    static char prevchar;

    if( ch != EOF && !ungot_ch ) {
        if( ch == '\n' || ch == '\r' ) {
            if( ch == '\r' || (ch == '\n' && prevchar != '\r' &&
                               prevchar != '\n')) {
                prevLine = lineCnt;
                if( lastTokenLine )
                    free( lastTokenLine );
                if( current_line )
                    lastTokenLine = strclone( current_line );
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
    ungot_ch = 0;
    return ch;
}

int cif_flex_current_line_number( void ) { return lineCnt; }
int cif_flex_previous_line_number( void ) { return prevLine; }
void cif_flex_set_current_line_number( ssize_t line ) { lineCnt = line; }
int cif_flex_current_position( void ) { return thisTokenPos; }
int cif_flex_previous_position( void ) { return lastTokenPos; }
void cif_flex_set_current_position( ssize_t pos ) { current_pos = pos - 1; }
const char *cif_flex_current_line( void ) { return thisTokenLine; }
const char *cif_flex_previous_line( void ) { return lastTokenLine; }

static char *clean_string( char *src, int is_textfield )
{
    int DELTA = 8;
    ssize_t length = strlen( src );
    char *new = malloc( length + 1 );
    /* !!! FIXME: the result of malloc() MUST be checked before use! */
    char *dest = new;
    char *start = src;
    int non_ascii_explained = 0;
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
                new = realloc( new, length + 1 );
                /* !!! FIXME: the result of realloc() MUST be checked
                       before use, it MAY return NULL! */
                /* !!! FIXME: if returning NULL, realloc *does not*
                       free the origial block -- it MUST be freed
                       afterwards to avoid memory leaks. */
                strcat( new, cxprintf( "&#x%04X;", *src & 255 ) );
                dest = new + strlen( new ) - 1;
                if( non_ascii_explained == 0 ) {
                    if( is_textfield == 0 ) {
                        print_message( "warning, non-ascii symbols "
                                       "encountered in the text:",
                                       cif_flex_current_line_number(),
                                       -1 );
                        fprintf( stderr, "'%s'\n", cif_flex_current_line() );
                        non_ascii_explained = 1;
                    } else {
                        print_message( "warning, non-ascii symbols "
                                       "encountered in the text field, "
                                       "replaced by XML entities:",
                                        cif_flex_current_line_number(), -1 );
                        fprintf( stderr, ";%s\n;\n\n", start );
                        non_ascii_explained = 1;
                    }
                }
            } else {
                if( is_textfield == 0 ) {
                    yyerror( "syntax error:" );
                } else if( non_ascii_explained == 0 ) {
                    print_message( "non-ascii symbols encountered in the "
                                   "text field:",
                                    cif_flex_current_line_number(), -1 );
                    fprintf( stderr, ";%s\n;\n\n", start );
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

static char *check_and_clean( char *token, int is_textfield )
{
    char *s;

    if( string_has_high_bytes
        ( (unsigned char*)token )) {
        if( cif_lexer_has_flags
            (CIF_FLEX_LEXER_FIX_NON_ASCII_SYMBOLS) ) {
            s = clean_string( token, is_textfield );
        } else {
            yyerror( "syntax error" );
            s = strclone( token );
        }
    } else {
        s = strclone( token );
    }
    return s;
}
