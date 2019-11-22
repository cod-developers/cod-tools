/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#ifndef __CIF_LEXER_H
#define __CIF_LEXER_H

#include <stdio.h>
#include <unistd.h> /* for ssize_t */
#include <cif_compiler.h>

int ciflex( void );
void cifrestart( void );

void cif_lexer_set_compiler( CIF_COMPILER *ccc );

int cif_lexer_set_report_long_tags( int flag );
int cif_lexer_report_long_tags( void );
size_t cif_lexer_set_tag_length_limit( size_t max_length );

extern int ciferror( const char *message );

#endif
