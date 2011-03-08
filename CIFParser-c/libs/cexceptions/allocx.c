/*---------------------------------------------------------------------------*\
** $Author$
** $Date$ 
** $Revision$
** $URL$
\*---------------------------------------------------------------------------*/

/* memory allocation functions that use cexception handling */

#include <stdlib.h>
#include <allocx.h>

void *allocx_subsystem = &allocx_subsystem;

#define merror( EX ) cexception_raise_in( EX, allocx_subsystem, \
					  ALLOCX_NO_MEMORY,     \
					  "Not enough memory" )

void *mallocx( size_t size, cexception_t *ex )
{
    void *p;
    if( size != 0 ) {
        p = malloc( size );
	if( !p ) merror( ex );
    } else {
        p = NULL;
    }
    return p;
}

void *callocx( size_t size, size_t nr, cexception_t *ex )
{
    void *p;
    if( size != 0 && nr != 0 ) {
        p = calloc( size, nr );
	if( !p ) merror( ex );
    } else {
        p = NULL;
    }
    return p;
}

void *reallocx( void *buffer, size_t new_size, cexception_t *ex )
{
    void *p;
    if( new_size != 0 ) {
        p = realloc( buffer, new_size );
	if( !p ) merror( ex );
    } else {
        p = buffer;
    }
    return p;
}

void freex( void *p )
{
    if( p )
        free( p );
}
