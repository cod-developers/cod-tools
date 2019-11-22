/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#ifndef __CIF2_LEXER_H
#define __CIF2_LEXER_H

#include <stdio.h>
#include <unistd.h> /* for ssize_t */
#include <cif_compiler.h>

int cif2lex( void );
void cif2restart( void );

void cif2_lexer_set_compiler( CIF_COMPILER *ccc );

int cif2_lexer_set_report_long_items( int flag );
int cif2_lexer_report_long_items( void );
size_t cif2_lexer_set_line_length_limit( size_t max_length );
size_t cif2_lexer_set_tag_length_limit( size_t max_length );

extern int cif2error( const char *message );

#endif
