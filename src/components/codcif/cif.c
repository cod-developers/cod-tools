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
#include <cifmessage.h>
#include <allocx.h>
#include <assert.h>
#include <cexceptions.h>
#include <cxprintf.h>
#include <stringx.h>
#include <yy.h>

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
    int yyretval;
    DATABLOCK *datablock_list;
    DATABLOCK *last_datablock; /* points to the end of the
                                  datablock_list; SHOULD not be freed
                                  when the CIF structure is deleted.*/

    DATABLOCK *current_datablock; /* points to the data block (which
                                     can represent a data block or a
                                     save frame) that is currently
                                     parsed; SHOULD not be freed when
                                     the CIF structure is deleted.*/

    CIFMESSAGE *messages; /* A linked list with error and warning
                             message data. */
};

void delete_cif( CIF *cif )
{
    if( cif ) {
        delete_datablock_list( cif->datablock_list );
        delete_cifmessage( cif->messages );
        freex( cif );
    }
}

CIF *new_cif( cexception_t *ex )
{
    CIF *cif = callocx( 1, sizeof(CIF), ex );
    return cif;
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

CIFMESSAGE *cif_messages( CIF *cif )
{
    assert( cif );
    return cif->messages;
}

CIFMESSAGE *cif_insert_message( CIF *cif, CIFMESSAGE *message )
{
    CIFMESSAGE *messages;
    assert( cif );
    messages = cif->messages;
    cif->messages = message;
    return messages;
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
    cif->current_datablock = new_block;
}

void cif_start_save_frame( CIF * volatile cif, const char *name,
                          cexception_t *ex )
{
    DATABLOCK *save_frame = NULL;

    assert( cif );
    assert( cif->current_datablock );

    if( cif->current_datablock != cif->last_datablock ) {
        yyerror( "save frames may not be nested" );
    }

    save_frame = datablock_start_save_frame( cif->current_datablock, name, ex );

    cif->current_datablock = save_frame;
}

void cif_finish_save_frame( CIF * volatile cif )
{
    assert( cif );
    cif->current_datablock = cif->last_datablock;
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
    return datablock_tag_index( cif->current_datablock, tag );
}

void cif_insert_value( CIF * cif, char *tag,
                       char *value, datablock_value_type_t vtype,
                       cexception_t *ex )
{
    assert( cif );

    if( cif->datablock_list ) {
        datablock_insert_value( cif->current_datablock, tag, value, vtype, ex );
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
    datablock_overwrite_value( cif->current_datablock, tag_nr, val_nr,
        value, vtype );
}

void cif_start_loop( CIF *cif, cexception_t *ex )
{
    assert( cif );

    if( cif->datablock_list ) {
        datablock_start_loop( cif->current_datablock );
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
        datablock_finish_loop( cif->current_datablock, ex );
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
        datablock_push_loop_value( cif->current_datablock, value, vtype, ex );
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
            char *dblock_name = datablock_name( datablock );
            ssize_t length =
                /* lengths of both strings are added: */
                strlen( prefix ) +
                (dblock_name ? strlen( dblock_name ) : 0) +
                /* too separators will be used, allocate place for them: */
                2 * strlen( separator ) 
                /* one byte must be added for the terminating '\0' character: */
                + 1;
            char nprefix[ length ];
            if( ! dblock_name ) {
                continue;
            }

            nprefix[0] = '\0';
            if( strlen( prefix ) != 0 ) {
                strncat( nprefix, prefix, length - strlen(nprefix) - 1 );
                strncat( nprefix, separator, length - strlen(nprefix) - 1 );
            }
            if( append_blkname == 1 ) {
                strncat( nprefix, dblock_name, length - strlen(nprefix) - 1 );
                strncat( nprefix, separator, length - strlen(nprefix) - 1 );
            }
            datablock_print_tag_values( datablock, tagnames, tagcount, nprefix,
                separator, vseparator );
        }
    }
}

void cif_revert_message_list( CIF *cif )
{
    if( cif ) {
        cif->messages = cifmessage_revert_list( cif->messages );
    }
}

void cif_set_yyretval( CIF *cif, int yyretval )
{
    assert( cif );
    cif->yyretval = yyretval;
}

int cif_yyretval( CIF *cif )
{
    assert( cif );
    return cif->yyretval;
}

void cif_set_message( CIF *cif,
                      const char *filename,
                      const char *errlevel,
                      const char *message,
                      const char *syserror,
                      cexception_t *ex )
{
    assert( cif );

    cif_insert_message
        ( cif, new_cifmessage_from_data
          ( /* next = */ cif->messages,
            /* progname = */ NULL,
            /* filename = */ (char*)filename,
            /* line = */ -1, /* position = */ -1,
            /* addPos = */ NULL,
            /* status = */ (char*)errlevel,
            /* message = */ (char*)message,
            /* explanation = */ (char*)syserror,
            /* separator = */ NULL,
            ex )
          );
}
