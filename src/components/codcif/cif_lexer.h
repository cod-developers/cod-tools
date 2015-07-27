/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#ifndef __CIF_LEXER_H
#define __CIF_LEXER_H

#include <stdio.h>
#include <stdlib.h> /* for ssize_t */
#include <cexceptions.h>

int yylex( void );
void yyrestart( void );

int cif_lexer( FILE *in, cexception_t *ex );

void cif_flex_reset_counters( void );

int cif_flex_current_line_number( void );
void cif_flex_set_current_line_number( ssize_t line );
int cif_flex_current_position( void );
void cif_flex_set_current_position( ssize_t pos );
const char *cif_flex_current_line( void );

int cif_flex_previous_line_number( void );
int cif_flex_previous_position( void );
const char *cif_flex_previous_line( void );

int cif_lexer_report_long_lines( int flag );

#endif
