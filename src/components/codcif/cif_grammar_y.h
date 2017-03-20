/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#ifndef __CIF_GRAMMAR_Y_H
#define __CIF_GRAMMAR_Y_H

#include <cif.h>
#include <cif_options.h>
#include <cexceptions.h>
#include <value.h>

CIF *new_cif_from_cif_file( char *filename, cif_option_t co,
                            cexception_t *ex );

void yyincrease_error_counter( void );

int cif_yy_error_number( void );
void cif_yy_reset_error_count( void );

void cif_yy_debug_on( void );
void cif_yy_debug_off( void );

#endif
