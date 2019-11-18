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
#include <cexceptions.h>
#include <cif_compiler.h>

int cif2lex( void );
void cif2restart( void );
void cif2_lexer_cleanup( void );

void cif2_lexer_set_compiler( CIF_COMPILER *ccc );

void cif2_flex_reset_counters( void );

int cif2_flex_current_line_number( void );
void cif2_flex_set_current_line_number( ssize_t line );
int cif2_flex_current_position( void );
void cif2_flex_set_current_position( ssize_t pos );
const char *cif2_flex_current_line( void );

int cif2_flex_previous_line_number( void );
int cif2_flex_previous_position( void );
const char *cif2_flex_previous_line( void );

int cif2_lexer_set_report_long_items( int flag );
int cif2_lexer_report_long_items( void );
int cif2_lexer_set_line_length_limit( int max_length );
int cif2_lexer_set_tag_length_limit( int max_length );

extern int cif2error( const char *message );

#endif
