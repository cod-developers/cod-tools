/*--*-C-*------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Locker: saulius $
* $Revision$
* $Source: /home/saulius/src/compilers/hlc/RCS/hlc.flex,v $
* $State: Exp $
\*-------------------------------------------------------------------------*/

 /* %option yylineno */

%x	text

UQSTRING       [^ \t\n\r\#\[\'\"][^ \t\n\r]*

DECIMAL_DIGIT  [0-9]
INTEGER	       [-+]?{DECIMAL_DIGIT}+
FIXED	       [-+]?(({DECIMAL_DIGIT}+"."{DECIMAL_DIGIT}*)|("."{DECIMAL_DIGIT}+))
REAL           {FIXED}([eE]([-+]?)[0-9]+)?

INTEGER_ESD    {INTEGER}(\({INTEGER}\))?
REAL_ESD       {REAL}(\({INTEGER}\))?

 /* Double and single quoted strings */

DSTRING         \"([^\"\n]|\"[^ \t\n\r])*\"?\"
SSTRING         '([^'\n]|\'[^ \t\n\r])*\'?'
STRING          {DSTRING}|{SSTRING}

 /* Unterminated double and single quoted strings */

UDSTRING        \"[^\"\n\r]*
USSTRING        '[^'\n\r]*
USTRING         {UDSTRING}|{USSTRING}

%{
/* exports: */
#include <cif_grammar_flex.h>

/* uses: */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <assert.h>
#include <common.h>
#include <yy.h>
#include <cif_grammar_y.h>
#include <cif_grammar.tab.h>
#include <allocx.h>
#include <cexceptions.h>

typedef enum {
  CIF_FLEX_DEBUG_OFF = 0x00,
  CIF_FLEX_DEBUG_TEXT = 0x01,
  CIF_FLEX_DEBUG_YYLVAL = 0x02,
  CIF_FLEX_DEBUG_YYFLEX = 0x04,
  CIF_FLEX_DEBUG_LINES = 0x08,
} CIF_FLEX_DEBUG_FLAGS;

static int cif_flex_debug_flags = 0;

typedef enum {
  CIF_FLEX_LEXER_FIX_CTRL_Z = 0x01,
  CIF_FLEX_LEXER_FIX_NON_ASCII_SYMBOLS = 0x02,
  CIF_FLEX_LEXER_FIX_MISSING_CLOSING_DOUBLE_QUOTE = 0x04,
  CIF_FLEX_LEXER_FIX_MISSING_CLOSING_SINGLE_QUOTE = 0x08,
} CIF_FLEX_LEXER_FLAGS;

static int cif_flex_lexer_flags = 0;

static char * thisTokenLine = NULL;
static char * lastTokenLine = NULL;
static char * currentLine = NULL;
static int currentLineLength = 0;
static int lineCnt = 1;
static int currLine = 1;
static int prevLine = 1;
static int linePos, nextPos;

static int lastTokenPos = 0;
static int thisTokenPos = 0;

void cif_flex_reset_counters( void )
{
    lineCnt = 1;
    linePos = nextPos = 0;
}

/* The following macros are used to save context for error reporting
routines (notably yyerror()). MARK remembers the start position of the
current token. If yacc fails, we know that it is this token that
caused an error, and can inform user about this.*/

#define COUNT_LINES lineCnt += yyleng;
#define REMEMBER if( lastTokenLine != thisTokenLine && \
    lastTokenLine != currentLine ) { free( lastTokenLine ); } \
    lastTokenLine = thisTokenLine; thisTokenLine = currentLine; \
    lastTokenPos = thisTokenPos; thisTokenPos = linePos; linePos = nextPos;    
#define MARK linePos = nextPos; nextPos += yyleng; prevLine = currLine; \
    currLine = lineCnt; REMEMBER
#define ADVANCE_MARK nextPos += yyleng
#define RESET_MARK linePos = nextPos = 0

static void storeCurrentLine( char *line, int length );
char *clean_string( char *src );

%}

%%

 /********* store line for better error reporting ***********/

^.*   %{
            storeCurrentLine(yytext, yyleng);
            RESET_MARK;
            yyless(0);
          %}
\n    COUNT_LINES; /** count lines **/

 /**************** eat up comments **************************/

"#".*

 /**************** process multi-line text fields **************************/

\n;.*			    %{    MARK;
                          lineCnt++;
                          BEGIN(text);
                          yylval.s = strclone( yytext + 2 );
                          if( strlen( yylval.s ) > 0
                              && yylval.s[strlen( yylval.s )-1] == '\r' ) {
                              yylval.s[strlen( yylval.s )-1] = '\0';
                          }
                          yylval.s = clean_string( yylval.s );
                        %}
<text>^[^;].*		%{
                          RESET_MARK;
                          REMEMBER;
                          storeCurrentLine(yytext, yyleng);
                          if( strlen( yytext ) > 0
                              && yytext[strlen( yytext )-1] == '\r' ) {
                              yytext[strlen( yytext )-1] = '\0';
                          }
                          yylval.s = clean_string( 
                              strappend( yylval.s, yytext ) );
                        %}
<text>\n+		{ COUNT_LINES; yylval.s = strappend( yylval.s, yytext ); }
<text>^;	        %{ 
                          ssize_t length = strlen( yylval.s );
                          ADVANCE_MARK;
                          BEGIN(INITIAL);
                          if( length > 0 ) {
                              yylval.s[length-1] = '\0'; /* remove the last "\n" character from the value */
                          }
                          if( length > 1 && yylval.s[length-2] == '\r') {
                              yylval.s[length-2] = '\0'; /* remove the last "\r" character from the value */
                          }
                          yylval.s = clean_string( yylval.s );
                          return _TEXT_FIELD; 
                        %}

<text><<EOF>>           %{
                          length = strlen( yylval.s );
                          yyerrorf( "unterminated text field" );
                          BEGIN(INITIAL);
                          if( length > 1 ) {
                              yylval.s[length-1] = '\0'; /* remove the last "\n" character from the value */
                          }
                          yylval.s = clean_string( yylval.s );
                          return _TEXT_FIELD;
                        %}

 /**************** eat up whitespace ************************/

[ \t\r]+			ADVANCE_MARK;

 /*********************** keywords ***************************/

data_[^ \t\n\r]+ { MARK; yylval.s = clean_string(yytext + 5); return _DATA_; }
data_            { MARK; yylval.s = NULL;  return _DATA_; }
loop_            { MARK; return _LOOP_; }
_[^ \t\n\r]+    %{
                           MARK;
                           yylval.s = strclone(yytext);
                           int i;
                           for( i = 0; i < strlen( yylval.s ); i++ ) {
                               yylval.s[i] = tolower(yylval.s[i]);
                           }
                           yylval.s = clean_string( yylval.s );
                           return _TAG;
            %}

 /********************* literal constants *********************/

{REAL_ESD}		%{
                           MARK;
                           yylval.s = strnclone(yytext, yyleng);
			   /* sscanf( yytext, "%lf", &yylval.r ); */
			   return _REAL_CONST;
			%}

{INTEGER_ESD}		%{
                           MARK;
                           yylval.s = strnclone(yytext, yyleng);
			   return _INTEGER_CONST;
			%}

 /************************* strings **********************************/

{DSTRING}		%{
                           MARK;
                           assert(yyleng > 1);
                           yylval.s = clean_string( 
                               strnclone(yytext + 1, yyleng - 2) );
                           return _DQSTRING;
			%}

{UDSTRING}/[\r\n]    %{
                           MARK;
                           assert(yyleng > 0);
                           if( (cif_flex_lexer_flags &
                                CIF_FLEX_LEXER_FIX_MISSING_CLOSING_DOUBLE_QUOTE) > 0 ) {
                               yynote( "warning, double-quoted string is missing "
                                       "a closing quote -- fixed" );
                           } else {
                               yyerror( "syntax error: " );
                           }
                           yylval.s = yyleng > 1 ?
                                         clean_string(
                                             strnclone(yytext + 1, yyleng - 1)
                                         ) : strclone("");
                           return _DQSTRING;
			%}

{SSTRING}		%{
                           MARK;
                           assert(yyleng > 1);
                           yylval.s = clean_string(
                               strnclone(yytext + 1, yyleng - 2) );
                           return _SQSTRING;
			%}

{USSTRING}/[\r\n]    %{
                           MARK;
                           assert(yyleng > 0);
                           if( (cif_flex_lexer_flags &
                                CIF_FLEX_LEXER_FIX_MISSING_CLOSING_SINGLE_QUOTE) > 0 ) {
                               yynote( "warning, single-quoted string is missing "
                                       "a closing quote -- fixed" );
                           } else {
                               yyerror( "syntax error: " );
                           }
                           yylval.s = yyleng > 1 ?
                                         clean_string(
                                             strnclone(yytext + 1, yyleng - 1)
                                         ) : strclone("");
                           return _SQSTRING;
			%}

 /******************** single DOS EOF character *******************/

\x1a                %{
                           MARK;
                           if( ( cif_flex_lexer_flags &
                                     CIF_FLEX_LEXER_FIX_CTRL_Z ) > 0 ) {
                               print_message( "warning, DOS EOF symbol ^Z was "
                                              "encountered and ignored",
                                               cif_flex_current_line_number(),
                                               -1 );
                           } else {
                               print_message( "DOS EOF symbol ^Z was "
                                              "encountered, it is not "
                                              "permitted in CIFs",
                                               cif_flex_current_line_number(),
                                               -1 );
                               yyerror( "syntax error:" );
                           }
            %}

 /********************** unquoted strings *************************/

{UQSTRING}	        %{
                           MARK;
                           if( cif_flex_debug_flags &
			           CIF_FLEX_DEBUG_YYLVAL )
                               printf("yylval.s = %s\n", yytext);
                           yylval.s = clean_string(yytext);
                           return _UQSTRING;
			%}

.			{ MARK; return clean_string(yytext); }

%%

void cif_flex_debug_off( void )
{
    cif_flex_debug_flags = 0;
#ifdef YYDEBUG
    yy_flex_debug = 0;
#endif
}

void cif_flex_debug_yyflex( void )
{
    cif_flex_debug_flags |= CIF_FLEX_DEBUG_YYFLEX;
#ifdef YYDEBUG
    yy_flex_debug = 1;
#endif
}

void cif_flex_debug_yylval( void )
{
    cif_flex_debug_flags |= CIF_FLEX_DEBUG_YYLVAL;
}

void cif_flex_debug_yytext( void )
{
    cif_flex_debug_flags |= CIF_FLEX_DEBUG_TEXT;
}

void cif_flex_debug_lines( void )
{
    cif_flex_debug_flags |= CIF_FLEX_DEBUG_LINES;
}

void set_lexer_fix_ctrl_z( void )
{
    cif_flex_lexer_flags |= CIF_FLEX_LEXER_FIX_CTRL_Z;
}

void set_lexer_fix_non_ascii_symbols( void )
{
    cif_flex_lexer_flags |= CIF_FLEX_LEXER_FIX_NON_ASCII_SYMBOLS;
}

void set_lexer_fix_missing_closing_double_quote( void )
{
    cif_flex_lexer_flags |= CIF_FLEX_LEXER_FIX_MISSING_CLOSING_DOUBLE_QUOTE;
}

void set_lexer_fix_missing_closing_single_quote( void )
{
    cif_flex_lexer_flags |= CIF_FLEX_LEXER_FIX_MISSING_CLOSING_SINGLE_QUOTE;
}

int cif_flex_current_line_number( void ) { return lineCnt; }
int cif_flex_previous_line_number( void ) { return prevLine; }
void cif_flex_set_current_line_number( ssize_t line ) { lineCnt = line; }
int cif_flex_current_position( void ) { return linePos; }
int cif_flex_previous_position( void ) { return lastTokenPos; }
void cif_flex_set_current_position( ssize_t pos ) { linePos = pos - 1; }
const char *cif_flex_current_line( void ) { return thisTokenLine; }
const char *cif_flex_previous_line( void ) { return lastTokenLine; }

static void storeCurrentLine( char *line, int length )
{
   assert( line != NULL );
  
   #ifdef YYDEBUG
   if( cif_flex_debug_flags & CIF_FLEX_DEBUG_TEXT )
       printf("\t%3d : %s\n", lineCnt, line);
   if( cif_flex_debug_flags & CIF_FLEX_DEBUG_YYLVAL )
       printf("length = %d\nline = %s\n", length, line);
   #endif

   currentLine = strnclone( line, length );
   currentLineLength = length;
   if( length > 0 && currentLine[length-1] == '\r' ) {
       currentLine[length-1] = '\0';
   }

   if( cif_flex_debug_flags & CIF_FLEX_DEBUG_LINES ) {
       char *first_nonblank = currentLine;
       while( isspace( *first_nonblank )) first_nonblank++;
       if( *first_nonblank == '#' ) {
           cif_printf( NULL, "%s\n", currentLine );
       } else {
           cif_printf( NULL, "#\n# %s\n#\n", currentLine );
       }
   }
}

char *clean_string( char *src )
{
    int DELTA = 8;
    ssize_t length = strlen( src );
    char *new = malloc( length + 1 );
    char *dest = new;
    int ctrl_z_explained = 0;
    int non_ascii_explained = 0;
    while( *src != '\0' ) {
        if( (*src & 255) == 26 ) {
            /* Inform about DOS newline */
            *dest = ' ';
            if( ctrl_z_explained == 0 ) {
                if( ( cif_flex_lexer_flags &
                      CIF_FLEX_LEXER_FIX_CTRL_Z ) > 0 ) {
                        print_message( "warning, DOS EOF symbol ^Z was "
                                       "encountered and ignored",
                                       cif_flex_current_line_number(),
                                       -1 );
                } else {
                        print_message( "DOS EOF symbol ^Z was "
                                       "encountered, it is not "
                                       "permitted in CIFs",
                                       cif_flex_current_line_number(),
                                       -1 );
                        yyerror( "syntax error:" );
                }
                ctrl_z_explained = 1;
            }
        } else if( ( (*src & 255 ) < 16 || (*src & 255 ) > 127 )
            && (*src & 255 ) != 10 ) {
            if( ( cif_flex_lexer_flags &
                  CIF_FLEX_LEXER_FIX_NON_ASCII_SYMBOLS ) > 0 ) {
                /* Do magic with non-ascii symbols */
                *dest = '\0';
                length += DELTA;
                new = realloc( new, length + 1 );
                strcat( new, cxprintf( "&#x%04X;", *src & 255 ) );
                dest = new + strlen( new ) - 1;
                if( non_ascii_explained == 0 ) {
                    print_message( "warning, non-ascii symbols "
                                   "encountered in the text:",
                                   cif_flex_current_line_number(),
                                   -1 );
                    fprintf( stderr, "'%s'\n", cif_flex_current_line() );
                    non_ascii_explained = 1;
                }
            } else {
                yyerror( "syntax error:" );
                dest--; /* Omit non-ascii symbols */
            }
        } else {
            *dest = *src;
        }
        src++;
        dest++;
    }
    *dest = '\0';
    return new;
}
