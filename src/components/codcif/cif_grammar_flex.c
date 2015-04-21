/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

/* exports: */
#include <cif_grammar_flex.h>

/* uses: */
#include <string.h>
#include <ctype.h>
#include <assert.h>
#include <common.h>
#include <cif_grammar_y.h>

typedef enum {
  CIF_FLEX_DEBUG_OFF = 0x00,
  CIF_FLEX_DEBUG_TEXT = 0x01,
  CIF_FLEX_DEBUG_YYLVAL = 0x02,
  CIF_FLEX_DEBUG_YYFLEX = 0x04,
  CIF_FLEX_DEBUG_LINES = 0x08,
} CIF_FLEX_DEBUG_FLAGS;

static int cif_flex_debug_flags = 0;

int yy_flex_debug;

static int cif_flex_lexer_flags = 0;

void cif_flex_debug_off( void )
{
    cif_flex_debug_flags = 0;
#if YYDEBUG
    yy_flex_debug = 0;
#endif
}

void cif_flex_debug_yyflex( void )
{
    cif_flex_debug_flags |= CIF_FLEX_DEBUG_YYFLEX;
#if YYDEBUG
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

void set_lexer_allow_uqstring_brackets( void )
{
    cif_flex_lexer_flags |= CIF_FLEX_LEXER_ALLOW_UQSTRING_BRACKETS;
}

int cif_lexer_has_flags( int flags )
{
    return cif_flex_lexer_flags & flags;
}
