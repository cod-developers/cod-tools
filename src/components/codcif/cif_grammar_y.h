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

CIF *new_cif_from_cif1_file( FILE *in, char *filename, cif_option_t co,
                             cexception_t *ex );

void cif_yy_debug_on( void );
void cif_yy_debug_off( void );

#endif
