/*--*-C-*------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Locker: saulius $
* $Revision$
* $Source: /home/saulius/src/compilers/hlc/RCS/hlc.flex,v $
* $State: Exp $
\*-------------------------------------------------------------------------*/

 /* %option yylineno */

%x	comment
%x	m2comment

DECIMAL_DIGIT  [0-9]
NAME	       [a-zA-Z_][a-zA-Z0-9_]*
INTEGER	       {DECIMAL_DIGIT}+
FIXED	       ({DECIMAL_DIGIT}+"."{DECIMAL_DIGIT}*)|("."{DECIMAL_DIGIT}+)
REAL           {FIXED}([eE]([-+]?)[0-9]+)?

 /* Double and single quoted strings */

DSTRING         \"(([^\"\n]|\\\")*)*\"
SSTRING         '(([^'\n]|\\')*)*'
STRING          {DSTRING}|{SSTRING}

UDSTRING        \"[^\"\n]*
USSTRING        '[^'\n]*
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

static char * currentLine = NULL;
static int currentLineLength = 0;
static int lineCnt = 1;
static int linePos, nextPos;

/* The following macros are used to save context for error reporting
routines (notably yyerror()). MARK remembers the start position of the
current token. If yacc fails, we know that it is this token that
caused an error, and can inform user about this.*/

#define COUNT_LINES lineCnt += yyleng;
#define MARK linePos = nextPos; nextPos += yyleng;
#define ADVANCE_MARK nextPos += yyleng
#define RESET_MARK linePos = nextPos = 0

static void storeCurrentLine( char *line, int length );

%}

%%

 /********* store line for better error reporting ***********/

^.*   { storeCurrentLine(yytext, yyleng); RESET_MARK; yyless(0); }
 \n+   COUNT_LINES; /** count lines **/

 /**************** eat up comments **************************/

"//".*
"#".*

"/*"			{ MARK; BEGIN(comment); }
<comment>^.*		{ RESET_MARK; storeCurrentLine(yytext, yyleng); yyless(0); }
<comment>\n+		{ COUNT_LINES; }
<comment>[^*\n]*	{ ADVANCE_MARK; }
<comment>"*"+[^*/\n]*	{ ADVANCE_MARK; }
<comment>"*"+"/"	{ ADVANCE_MARK; BEGIN(INITIAL); }

"(*"			{ MARK; BEGIN(m2comment); }
<m2comment>^.*		{ RESET_MARK; storeCurrentLine(yytext, yyleng); yyless(0); }
<m2comment>\n+		{ COUNT_LINES; }
<m2comment>[^*\n]*	{ ADVANCE_MARK; }
<m2comment>"*"+[^*)\n]*	{ ADVANCE_MARK; }
<m2comment>"*"+")"	{ ADVANCE_MARK; BEGIN(INITIAL); }

 /**************** eat up whitespace ************************/

[ \t]+			ADVANCE_MARK;

 /**************** multi-character tokens *********************/

 /* ":="                    { MARK; yylval.op = ':'/\*OP_COPY*\/; return __ASSIGN; } */
 /* "->"                    { MARK; yylval.op = ':'/\*OP_COPY*\/; return __ARROW; } */
 /* "="                     { MARK; yylval.op = ':'/\*OP_COPY*\/; return '='; } */

 /*********************** keywords ***************************/

 /* and        { MARK; return _AND; } */
 /* any        { MARK; return _ANY; } */
 /* array      { MARK; return _ARRAY; } */
 /* begin      { MARK; return '{'; } */

 /********************** identifiers *************************/

{NAME}			%{
                           MARK;
                           if( cif_flex_debug_flags &
			           CIF_FLEX_DEBUG_YYLVAL )
                               printf("yylval.s = %s\n", yytext);
                           yylval.s = strclone(yytext);
                           return __IDENTIFIER;
			%}

 /********************* literal constants *********************/

{INTEGER}".."		%{
                           yyless(strlen(yytext) - 2);
                           MARK;
                           yylval.s = strnclone(yytext, yyleng);
                           yylval.s = process_escapes(yylval.s);
			   return __INTEGER_CONST;
			%}

{INTEGER}		%{
                           MARK;
                           yylval.s = strnclone(yytext, yyleng);
                           yylval.s = process_escapes(yylval.s);
			   return __INTEGER_CONST;
			%}

{REAL}			%{
                           MARK;
                           yylval.s = strnclone(yytext, yyleng);
                           yylval.s = process_escapes(yylval.s);
			   /* sscanf( yytext, "%lf", &yylval.r ); */
			   return __REAL_CONST;
			%}

 /************************* strings **********************************/

{STRING}		%{
                           MARK;
                           assert(yyleng > 1);
                           yylval.s = strnclone(yytext + 1, yyleng - 2);
                           yylval.s = process_escapes(yylval.s);
                           return __STRING_CONST;
			%}

({USTRING})$		%{
                           MARK;
                           assert(yyleng > 0);
                           yyerror("unterminated string");
                           yylval.s = yyleng > 1 ?
                                         strnclone(yytext + 1, yyleng - 2) :
                                         strclone("");
                           yylval.s = process_escapes(yylval.s);
                           return __STRING_CONST;
			%}

.			{ MARK; return yytext[0]; }

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

int cif_flex_current_line_number( void ) { return lineCnt; }
void cif_flex_set_current_line_number( ssize_t line ) { lineCnt = line; }
int cif_flex_current_position( void ) { return linePos+1; }
void cif_flex_set_current_position( ssize_t pos ) { linePos = pos - 1; }
const char *cif_flex_current_line( void ) { return currentLine; }

static void storeCurrentLine( char *line, int length )
{
   assert( line != NULL );
  
   #ifdef YYDEBUG
   if( cif_flex_debug_flags & CIF_FLEX_DEBUG_TEXT )
       printf("\t%3d : %s\n", lineCnt, line);
   if( cif_flex_debug_flags & CIF_FLEX_DEBUG_YYLVAL )
       printf("length = %d\nline = %s\n", length, line);
   #endif

   if( currentLineLength < length ) {
      currentLine = realloc(currentLine, length+1);
      assert(currentLine != NULL);
      currentLineLength = length;
   }
   strncpy(currentLine, line, length);
   currentLine[length] = '\0';
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
