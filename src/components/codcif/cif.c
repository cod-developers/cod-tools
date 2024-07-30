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
#include <unistd.h>
#include <stdarg.h>
#include <string.h>
#include <datablock.h>
#include <cifmessage.h>
#include <allocx.h>
#include <assert.h>
#include <cexceptions.h>
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
    int major_version;
    int minor_version;
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

    /* By default, CIF is set to be conforming to CIF v1.1 syntax */
    cif->major_version = 1;
    cif->minor_version = 1;

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
    cif_append_datablock( cif, new_block );
}

void cif_append_datablock( CIF * volatile cif, DATABLOCK *datablock )
{
    assert( cif );

    if( cif->last_datablock ) {
        datablock_set_next( cif->last_datablock, datablock );
        cif->last_datablock = datablock;
    } else {
        cif->datablock_list = cif->last_datablock = datablock;
    }
    cif->current_datablock = datablock;
}

void cif_start_save_frame( CIF * volatile cif, const char *name,
                           cexception_t *ex )
{
    DATABLOCK *save_frame = NULL;

    assert( cif );
    assert( cif->current_datablock );

    if( cif->current_datablock != cif->last_datablock ) {
        cexception_raise( ex, CIF_NESTED_FRAMES_ERROR,
                          "save frames may not be nested" );
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
        if( cif->major_version > 1 ) {
            printf( "#\\#CIF_%d.%d\n",
                    cif->major_version, cif->minor_version );
        }
        foreach_datablock( datablock, cif->datablock_list ) {
            datablock_dump( datablock );
        }
    }
}

void cif_print( CIF * volatile cif )
{
    DATABLOCK *datablock;

    if( cif ) {
        if( cif->major_version > 1 ) {
            printf( "#\\#CIF_%d.%d\n",
                    cif->major_version, cif->minor_version );
        }
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

void cif_insert_cifvalue( CIF * cif, char *tag, CIFVALUE *value,
                          cexception_t *ex )
{
    assert( cif );

    if( cif->datablock_list ) {
        datablock_insert_cifvalue( cif->current_datablock, tag, value, ex );
    } else {
        cexception_raise( ex, CIF_NO_DATABLOCK_ERROR,
                          "attempt to insert a CIF value before a "
                          "datablock is started" );
    }
}

void cif_overwrite_cifvalue( CIF * cif, ssize_t tag_nr, ssize_t val_nr,
                             CIFVALUE *value, cexception_t *ex )
{
    assert( cif );
    datablock_overwrite_cifvalue( cif->current_datablock, tag_nr, val_nr,
        value, ex );
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

void cif_push_loop_cifvalue( CIF * cif, CIFVALUE *value, cexception_t *ex )
{
    if( cif->datablock_list ) {
        datablock_push_loop_cifvalue( cif->current_datablock, value, ex );
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
                           char * volatile prefix, int append_blkname,
                           char * group_separator, char * separator,
                           char * vseparator, char * replacement )
{
    cif_print_quoted_tag_values( cif, tagnames, tagcount,
                                 prefix, append_blkname,
                                 group_separator, separator,
                                 vseparator, replacement,
                                 /* quote_char = */ "",
                                 /* must_always_quote = */ 0 );
}

void cif_print_quoted_tag_values( CIF *cif, char ** tagnames, int tagcount,
                                  char * volatile prefix, int append_blkname,
                                  char * group_separator, char * separator,
                                  char * vseparator, char * replacement,
                                  char * quote_char, int must_always_quote )
{
    DATABLOCK *datablock;

    if( cif ) {
        foreach_datablock( datablock, cif->datablock_list ) {
            char *dblock_name = datablock_name( datablock );
            if( !dblock_name ) {
                dblock_name = "";
            }
            if( prefix ) {
                print_quoted_or_delimited_value( prefix, group_separator,
                                                 separator, vseparator,
                                                 replacement, *quote_char,
                                                 must_always_quote );
                if( append_blkname || tagcount > 0 ) {
                    printf( "%s", separator );
                }
            }
            if( quote_char && *quote_char != '\0' ) {
                datablock_print_quoted_tag_values( datablock, tagnames, tagcount,
                                                   /*prefix =*/ (
                                                                 append_blkname ?
                                                                 dblock_name :
                                                                 NULL
                                                                 ),
                                                   group_separator, separator,
                                                   vseparator, replacement,
                                                   quote_char,
                                                   must_always_quote );
            } else {
                datablock_print_tag_values( datablock, tagnames, tagcount,
                                            /*prefix =*/ (
                                                          append_blkname ?
                                                          dblock_name : NULL
                                                          ),
                                            group_separator, separator,
                                            vseparator, replacement );
            }
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

void cif_set_version( CIF *cif, int major, int minor )
{
    assert( cif );
    cif->major_version = major;
    cif->minor_version = minor;
}

int cif_major_version( CIF *cif )
{
    assert( cif );
    return cif->major_version;
}

int cif_minor_version( CIF *cif )
{
    assert( cif );
    return cif->minor_version;
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
