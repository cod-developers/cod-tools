
/* external declarations specific to yacc */

#ifndef __YY_H
#define __YY_H

extern int yyparse( void );

/* For testing of lexical analysers: */
extern int yylex( void );
extern char *yytext;

#ifdef YYDEBUG   
   extern int yydebug;
   extern int yy_flex_debug;
#endif

#endif
