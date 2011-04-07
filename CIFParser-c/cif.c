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
#include <cexceptions.h>
#include <cxprintf.h>
#include <stringx.h>

void *cif_subsystem = &cif_subsystem;

static int cif_debug = 0;

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

#define DELTA_CAPACITY (100)

struct CIF {

    /* Fields 'length' and 'capacity' describe allocated parallel
       arrays tags and values. The 'capacity' field contains a number
       of array elements allocated for use in each array. The 'length'
       field contains a number of elements actually used. All elements
       after the 'length-1'-th element MUST contain NULL values. */
    size_t length;
    size_t capacity;
    ssize_t tags_length;
    char **tags;
    char ***values;
};

CIF *new_cif( cexception_t *ex )
{
    return callocx( 1, sizeof(CIF), ex );
}

void delete_cif( CIF *cif )
{
    ssize_t i, j;

    if( cif ) {
        for( i = 0; i < cif->length; i++ ) {
            if( cif->tags ) 
                freex( cif->tags[i] );
            if( cif->values && cif->values[i] ) {
                for( j = 0; cif->values[i][j] != NULL; j++ )
                    freex( cif->values[i][j] );
                freex( cif->values[i] );
            }
        }
        freex( cif->tags );
        freex( cif->values );
	freex( cif );
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
    ssize_t i;

    for( i = 0; i < cif->length; i++ ) {
        printf( "%-32s '%s'\n", cif->tags[i], cif->values[i][0] );
    }

    return;
}

void cif_insert_value( CIF * cif, char *tag,
                       char *value, cif_value_type_t vtype,
                       cexception_t *ex )
{
    cexception_t inner;
    ssize_t i;

    cexception_guard( inner ) {
        i = cif->length;
        if( cif->length + 1 > cif->capacity ) {
            cif->tags = reallocx( cif->tags,
                                  sizeof(cif->tags[0]) * (cif->capacity + DELTA_CAPACITY),
                                  &inner );
            cif->tags[i] = NULL;
            cif->values = reallocx( cif->values,
                                    sizeof(cif->values[0]) * (cif->capacity + DELTA_CAPACITY),
                                    &inner );
            cif->values[i] = NULL;
            cif->capacity += DELTA_CAPACITY;
        }
        cif->length++;

        cif->values[i] = callocx( sizeof(cif->values[0][0]), 2, &inner );

        cif->tags[i] = strdupx( tag, &inner );
        cif->values[i][0] = value;
    }
    cexception_catch {
        cexception_reraise( inner, ex );
    }
}
