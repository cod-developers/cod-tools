/*---------------------------------------------------------------------------*\
** $Author$
** $Date$ 
** $Revision$
** $URL$
\*---------------------------------------------------------------------------*/

#ifndef __ALLOCX_H
#define __ALLOCX_H

/* memory allocation functions that use cexception handling */

#include <stdlib.h>
#include <cexceptions.h>

typedef enum {
    ALLOCX_OK = 0,
    ALLOCX_NO_MEMORY = 99,
    ALLOCX_last
} ALLOCX_ERROR;

extern void *allocx_subsystem;

void *mallocx( size_t size, cexception_t *ex );
void *callocx( size_t size, size_t nr, cexception_t *ex );
void *reallocx( void *buffer, size_t new_size, cexception_t *ex );
void freex( void* );

#endif
