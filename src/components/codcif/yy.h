
/* external declarations specific to yacc */

#ifndef __YY_H
#define __YY_H

#include <stdio.h>
#include <stdarg.h>
#include <cexceptions.h>

extern FILE *yyin;

extern int yyparse( void );

/* For testing of lexical analysers: */
extern int yylex( void );
extern char *yytext;

#ifdef YYDEBUG   
   extern int yydebug;
   extern int yy_flex_debug;
#endif

#endif

void yyerrorf( const char *message, ... );
void yyverrorf( const char *message, va_list ap );
