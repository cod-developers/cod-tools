/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#ifndef __CIF_GRAMMAR_Y_H
#define __CIF_GRAMMAR_Y_H

#include <cif.h>
#include <cexceptions.h>

typedef struct COMPILER_OPTIONS COMPILER_OPTIONS;

COMPILER_OPTIONS *new_compiler_options( cexception_t *ex );

CIF *new_cif_from_cif_file( char *filename, COMPILER_OPTIONS *co,
    cexception_t *ex );

void cif_printf( cexception_t *ex, char *format, ... );
char * cif_unprefix_textfield( char * tf );
char * cif_unfold_textfield( char * tf );

void print_message_generic( const char *progname, const char *filename,
    const char *datablock, const char *message, int line, int position );
void print_message( const char *message, int line, int position );
void print_current_trace( void );
void print_previous_trace( void );
void yyincrease_error_counter( void );

int is_tag_value_unknown( char * tv );

int cif_yy_error_number( void );
void cif_yy_reset_error_count( void );

void cif_yy_debug_on( void );
void cif_yy_debug_off( void );

#endif
