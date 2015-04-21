/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#ifndef __CIF_GRAMMAR_FLEX_H
#define __CIF_GRAMMAR_FLEX_H

#include <stdio.h>
#include <unistd.h> /* for ssize_t */
#include <cexceptions.h>

typedef enum {
  CIF_FLEX_LEXER_FIX_CTRL_Z = 0x01,
  CIF_FLEX_LEXER_FIX_NON_ASCII_SYMBOLS = 0x02,
  CIF_FLEX_LEXER_FIX_MISSING_CLOSING_DOUBLE_QUOTE = 0x04,
  CIF_FLEX_LEXER_FIX_MISSING_CLOSING_SINGLE_QUOTE = 0x08,
  CIF_FLEX_LEXER_ALLOW_UQSTRING_BRACKETS = 0x16,
} CIF_FLEX_LEXER_FLAGS;

extern int yy_flex_debug;

void cif_flex_debug_off( void );
void cif_flex_debug_yyflex( void );
void cif_flex_debug_yylval( void );
void cif_flex_debug_yytext( void );
void cif_flex_debug_lines( void );

int cif_lexer_has_flags( int flags );

void set_lexer_fix_ctrl_z( void );
void set_lexer_fix_non_ascii_symbols( void );
void set_lexer_fix_missing_closing_double_quote( void );
void set_lexer_fix_missing_closing_single_quote( void );
void set_lexer_allow_uqstring_brackets( void );

void cif_flex_push_state( FILE *replace_yyin, cexception_t *ex );
void cif_flex_pop_state( void );

#endif
