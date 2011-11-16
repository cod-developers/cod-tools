/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

/* representation of the CIF data for the CIF parser. */

/* exports: */
#include <cif.h>

/* uses: */
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <datablock.h>
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
    int nerrors;
    DATABLOCK *datablock_list;
    DATABLOCK *last_datablock; /* points to the end of the
                                  datablock_list; SHOULD not be freed
                                  when the CIF structure is deleted.*/
};

CIF *new_cif( cexception_t *ex )
{
    CIF *cif = callocx( 1, sizeof(CIF), ex );
    return cif;
}

void delete_cif( CIF *cif )
{
    if( cif ) {
        delete_datablock_list( cif->datablock_list );
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

void cif_start_datablock( CIF * volatile cif, const char *name,
                          cexception_t *ex )
{
    DATABLOCK *new_block = NULL;

    assert( cif );

    new_block = new_datablock( name, NULL, ex );

    if( cif->last_datablock ) {
        datablock_set_next( cif->last_datablock, new_block );
        cif->last_datablock = new_block;
    } else {
        cif->datablock_list = cif->last_datablock = new_block;
    }
}

void cif_dump( CIF * volatile cif )
{
    DATABLOCK *datablock;

    if( cif ) {
        foreach_datablock( datablock, cif->datablock_list ) {
            datablock_dump( datablock );
        }
    }
}

void cif_print( CIF * volatile cif )
{
    DATABLOCK *datablock;

    if( cif ) {
        foreach_datablock( datablock, cif->datablock_list ) {
            datablock_print( datablock );
        }
    }
}

void cif_list_tags( CIF * volatile cif )
{
    DATABLOCK *datablock;

    if( cif ) {
        foreach_datablock( datablock, cif->datablock_list ) {
            datablock_list_tags( datablock );
        }
    }
}

ssize_t cif_tag_index( CIF * cif, char *tag ) {
    return datablock_tag_index( cif->last_datablock, tag );
}

void cif_insert_value( CIF * cif, char *tag,
                       char *value, datablock_value_type_t vtype,
                       cexception_t *ex )
{
    assert( cif );

    if( cif->datablock_list ) {
        datablock_insert_value( cif->last_datablock, tag, value, vtype, ex );
    } else {
        cexception_raise( ex, CIF_NO_DATABLOCK_ERROR,
                          "attempt to insert a CIF value before a "
                          "datablock is started" );
    }
}

void cif_overwrite_value( CIF * cif, ssize_t tag_nr, ssize_t val_nr,
                          char *value, datablock_value_type_t vtype )
{
    assert( cif );
    datablock_overwrite_value( cif->last_datablock, tag_nr, val_nr,
        value, vtype );
}

void cif_start_loop( CIF *cif, cexception_t *ex )
{
    assert( cif );

    if( cif->datablock_list ) {
        datablock_start_loop( cif->last_datablock );
    } else {
        cexception_raise( ex, CIF_NO_DATABLOCK_ERROR,
                          "attempt to start a CIF loop before a "
                          "datablock is started" );
    }
}

void cif_finish_loop( CIF *cif, cexception_t *ex )
{
    assert( cif );

    if( cif->datablock_list ) {
        datablock_finish_loop( cif->last_datablock, ex );
    } else {
        cexception_raise( ex, CIF_NO_DATABLOCK_ERROR,
                          "attempt to finish a CIF loop before a "
                          "datablock is started" );
    }
}

void cif_push_loop_value( CIF * cif, char *value, datablock_value_type_t vtype,
                          cexception_t *ex )
{
    if( cif->datablock_list ) {
        datablock_push_loop_value( cif->last_datablock, value, vtype, ex );
    } else {
        cexception_raise( ex, CIF_NO_DATABLOCK_ERROR,
                          "attempt to push a CIF loop value before a "
                          "datablock is started" );
    }    
}

void cif_set_nerrors( CIF *cif, int nerrors )
{
    assert( cif );
    cif->nerrors = nerrors;
}

int cif_nerrors( CIF *cif )
{
    assert( cif );
    return cif->nerrors;
}

DATABLOCK * cif_datablock_list( CIF *cif )
{
    assert( cif );
    return cif->datablock_list;
}

DATABLOCK * cif_last_datablock( CIF *cif )
{
    assert( cif );
    return cif->last_datablock;
}

void cif_print_tag_values( CIF *cif, char ** tagnames, int tagcount,
    char * volatile prefix, int append_blkname, char * separator,
    char * vseparator )
{
    DATABLOCK *datablock;

    if( cif ) {
        foreach_datablock( datablock, cif->datablock_list ) {
            char nprefix[ strlen( prefix ) + 
                strlen( datablock_name( datablock ) ) + 
                2 * strlen( separator )];
            nprefix[0] = '\0';
            if( strlen( prefix ) != 0 ) {
                strcat( nprefix, prefix );
                strcat( nprefix, separator );
            }
            if( append_blkname == 1 ) {
                strcat( nprefix, datablock_name( datablock ) );
                strcat( nprefix, separator );
            }
            datablock_print_tag_values( datablock, tagnames, tagcount, nprefix,
                separator, vseparator );
        }
    }
}
