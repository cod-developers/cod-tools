/*---------------------------------------------------------------------------*\
**$Author$
**$Date$
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#ifndef __DATABLOCK_H
#define __DATABLOCK_H

#include <unistd.h>
#include <stdarg.h>
#include <cexceptions.h>
#include <cifvalue.h>
#include <ciflist.h>

typedef struct DATABLOCK DATABLOCK;

typedef enum {
  DBLK_OK = 0,
  DBLK_UNRECOVERABLE_ERROR,
  DBLK_COMPILATION_ERROR,

  last_DBLK_ERROR
} datablock_error_t;

extern void *datablock_subsystem;

void datablock_debug_on( void );
void datablock_debug_off( void );
int datablock_debug_is_on( void );

DATABLOCK *new_datablock( const char *name, DATABLOCK *next,
                          cexception_t *ex );

void delete_datablock( DATABLOCK *bc );
void delete_datablock_list( DATABLOCK *datablock_list );

void create_datablock( DATABLOCK * volatile *datablock, const char *name,
                       DATABLOCK *next, cexception_t *ex );

DATABLOCK *datablock_start_save_frame( DATABLOCK *datablock, const char *name,
                                       cexception_t *ex );

void dispose_datablock( DATABLOCK * volatile *datablock );

DATABLOCK *datablock_next( DATABLOCK *datablock );
void datablock_set_next( DATABLOCK *datablock, DATABLOCK *next );

size_t datablock_length( DATABLOCK *datablock );
char **datablock_tags( DATABLOCK *datablock );
ssize_t *datablock_value_lengths( DATABLOCK *datablock );
CIFVALUE *datablock_cifvalue( DATABLOCK *datablock, int tag_nr, int val_nr );
ssize_t datablock_tag_index( DATABLOCK *datablock, char *tag );
void datablock_overwrite_cifvalue( DATABLOCK * datablock, ssize_t tag_nr,
    ssize_t val_nr, CIFVALUE *value, cexception_t *ex );
int *datablock_in_loop( DATABLOCK *datablock );
cif_value_type_t datablock_value_type( DATABLOCK *datablock,
                                       int tag_nr, int val_nr );
int datablock_loop_count( DATABLOCK *datablock );
DATABLOCK * datablock_save_frame_list( DATABLOCK *datablock );

void datablock_dump( DATABLOCK * volatile datablock );
void datablock_print( DATABLOCK * volatile datablock );
void datablock_list_tags( DATABLOCK * volatile datablock );
void datablock_print_tag_values( DATABLOCK * volatile datablock,
    char ** tagnames, int tagcount, char * volatile prefix, char * separator,
    char * vseparator );

void datablock_insert_cifvalue( DATABLOCK * datablock, char *tag,
                                CIFVALUE *value, cexception_t *ex );

void datablock_start_loop( DATABLOCK *datablock );
void datablock_finish_loop( DATABLOCK *datablock, cexception_t *ex );

void datablock_push_loop_cifvalue( DATABLOCK * datablock, CIFVALUE *value,
                                   cexception_t *ex );
char * datablock_name( DATABLOCK * datablock );

#define foreach_datablock( NODE, LIST ) \
    for( NODE = LIST; NODE != NULL; NODE = datablock_next( NODE ))

#endif
