/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

/* representation of the cif for the interpreter, assembler and
   code generator */

/* exports: */
#include <cif.h>

/* uses: */
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <allocx.h>
#include <assert.h>
#include <cxprintf.h>
#include <stringx.h>

void *cif_subsystem = &cif_subsystem;

int cif_debug = 0;
static int cif_stackdebug = 0;
static int cif_heapdebug = 0;

void cif_debug_on( void )
{
    cif_debug = 1;
}

int cif_debug_is_on( void )
{
    return cif_debug;
}

void cif_debug_off( void )
{
    cif_debug = 0;
}

void cif_stackdebug_on( void )
{
    cif_stackdebug = 1;
}

int cif_stackdebug_is_on( void )
{
    return cif_stackdebug;
}

void cif_stackdebug_off( void )
{
    cif_stackdebug = 0;
}

void cif_heapdebug_on( void )
{
    cif_heapdebug = 1;
}

int cif_heapdebug_is_on( void )
{
    return cif_heapdebug;
}

void cif_heapdebug_off( void )
{
    cif_heapdebug = 0;
}

struct CIF {
    size_t length;
    size_t capacity;
};

CIF *new_cif( cexception_t *ex )
{
    return callocx( 1, sizeof(CIF), ex );
}

void delete_cif( CIF *bc )
{
    if( bc ) {
	freex( bc );
    }
}

void create_cif( CIF * volatile *cif, cexception_t *ex )
{
    assert( cif );
    assert( !(*cif) );

    *cif = new_cif( ex );
}

void dispose_cif( CIF * volatile *cif )
{
    assert( cif );
    if( *cif ) {
	delete_cif( *cif );
	*cif = NULL;
    }
}

void cif_dump( CIF * volatile cif )
{
    return;
}
