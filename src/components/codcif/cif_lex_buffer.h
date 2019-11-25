/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#ifndef __CIF_LEX_BUFFER_H
#define __CIF_LEX_BUFFER_H

#include <stdio.h>
#include <unistd.h> /* for ssize_t */
#include <cif_compiler.h>
#include <cexceptions.h>

void cif_lexer_cleanup( void );
void cif_flex_reset_counters( void );

int cif_lexer_set_report_long_lines( int flag );
int cif_lexer_report_long_lines( void );
int cif_lexer_set_line_length_limit( int max_length );

void advance_mark( void );
void backstep_mark( void );

void pushchar( size_t pos, int ch );
void ungetlinec( int ch, FILE *in );
int getlinec( FILE *in, CIF_COMPILER *cif_cc, cexception_t *ex );

int cif_flex_current_line_number( void );
void cif_flex_set_current_line_number( ssize_t line );
int cif_flex_current_position( void );
void cif_flex_set_current_position( ssize_t pos );
const char *cif_flex_current_line( void );
int cif_flex_current_mark_position( void );

int cif_flex_previous_line_number( void );
int cif_flex_previous_position( void );
const char *cif_flex_previous_line( void );

char *cif_flex_token( void );

#endif
