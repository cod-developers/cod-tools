/*---------------------------------------------------------------------------*\
**$Author$
**$Date$
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

/* exports: */
#include <cif_lex_buffer.h>

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

static size_t cif_mandated_line_length = 80;
static int report_long_lines = 0;

static char *current_line;
static size_t current_line_length;
static size_t current_pos;

/* Inherited from the Flex scanner: */
static char * thisTokenLine = NULL;
static char * lastTokenLine = NULL;
static int lineCnt = 1;
static int currLine = 1;
static int prevLine = 1;
static int nextPos;

static int lastTokenPos = 0;
static int thisTokenPos = 0;

static char *token = NULL;
static size_t length = 0;

static int ungot_ch = 0;

void cif_flex_reset_counters( void )
{
    lineCnt = 1;
    currLine = prevLine = 1;
    current_pos = nextPos = 0;
}

void cif_lexer_cleanup( void )
{
    if( token ) freex( token );
    token = NULL;
    length = 0;
}

int cif_lexer_set_report_long_lines( int flag )
{
    int old_value = report_long_lines;
    report_long_lines = flag;
    return old_value;
}

int cif_lexer_report_long_lines( void )
{
    return report_long_lines;
}

size_t cif_lexer_set_line_length_limit( size_t max_length )
{
    size_t old_value = cif_mandated_line_length;
    cif_mandated_line_length = max_length;
    return old_value;
}

void advance_mark( void )
{
    lastTokenPos = thisTokenPos;
    thisTokenPos = current_pos - 1;
}

void backstep_mark( void )
{
    thisTokenPos = current_pos > 0 ? current_pos - 1 : 0;
}

static void _pushchar( char **buf, size_t *length, size_t pos, int ch )
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

void pushchar( size_t pos, int ch )
{
    _pushchar( &token, &length, pos, ch );
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

int getlinec( FILE *in, CIF_COMPILER *cif_cc, cexception_t *ex )
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
                    if( cif_lexer_report_long_lines() ) {
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
            _pushchar( &current_line, &current_line_length, 0, '\0' );
        } else {
            _pushchar( &current_line, &current_line_length, current_pos++, ch );
            _pushchar( &current_line, &current_line_length, current_pos, '\0' );
        }
        prevchar = ch;
        thisTokenLine = current_line;
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
int cif_flex_current_mark_position( void ) { return current_pos; }
void cif_flex_set_current_position( ssize_t pos ) { current_pos = pos - 1; }
const char *cif_flex_current_line( void ) { return thisTokenLine; }
const char *cif_flex_previous_line( void ) { return lastTokenLine; }
char *cif_flex_token( void ) { return token; }
