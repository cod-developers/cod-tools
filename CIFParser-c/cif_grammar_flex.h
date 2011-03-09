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

void cif_flex_debug_off( void );
void cif_flex_debug_yyflex( void );
void cif_flex_debug_yylval( void );
void cif_flex_debug_yytext( void );
void cif_flex_debug_lines( void );

void cif_flex_reset_counters( void );

int cif_flex_current_line_number( void );
void cif_flex_set_current_line_number( ssize_t line );
int cif_flex_current_position( void );
void cif_flex_set_current_position( ssize_t pos );
const char *cif_flex_current_line( void );

void cif_flex_push_state( FILE *replace_yyin, cexception_t *ex );
void cif_flex_pop_state( void );

#endif
