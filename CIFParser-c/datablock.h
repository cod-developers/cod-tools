/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#ifndef __DATABLOCK_H
#define __DATABLOCK_H

#include <stdlib.h>
#include <stdarg.h>
#include <cexceptions.h>

typedef struct DATABLOCK DATABLOCK;

typedef enum {
    DBLK_UNKNOWN = 0,
    DBLK_NUMBER,
    DBLK_UQSTRING,
    DBLK_SQSTRING,
    DBLK_DQSTRING,
    DBLK_TEXT,
    last_DBLK_VALUE
} datablock_value_type_t;

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

void dispose_datablock( DATABLOCK * volatile *datablock );

DATABLOCK *datablock_next( DATABLOCK *datablock );
void datablock_set_next( DATABLOCK *datablock, DATABLOCK *next );

size_t datablock_length( DATABLOCK *datablock );
char **datablock_tags( DATABLOCK *datablock );
ssize_t *datablock_value_lengths( DATABLOCK *datablock );
char ***datablock_values( DATABLOCK *datablock );
int *datablock_in_loop( DATABLOCK *datablock );
datablock_value_type_t **datablock_types( DATABLOCK *datablock );
int datablock_loop_count( DATABLOCK *datablock );

void datablock_dump( DATABLOCK * volatile datablock );
void datablock_print( DATABLOCK * volatile datablock );

void datablock_insert_value( DATABLOCK * datablock, char *tag,
                       char *value, datablock_value_type_t vtype,
                       cexception_t *ex );

void datablock_start_loop( DATABLOCK *datablock );
void datablock_finish_loop( DATABLOCK *datablock, cexception_t *ex );

void datablock_push_loop_value( DATABLOCK * datablock, char *value,
                                datablock_value_type_t vtype,
                                cexception_t *ex );

#define foreach_datablock( NODE, LIST ) \
    for( NODE = LIST; NODE != NULL; NODE = datablock_next( NODE ))

#endif
