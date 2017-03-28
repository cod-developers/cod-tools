/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#ifndef __CIFTABLE_H
#define __CIFTABLE_H

#include <stdio.h>
#include <cexceptions.h>

typedef struct CIFTABLE CIFTABLE;

#include <value.h>

CIFTABLE *new_table( cexception_t *ex );
void delete_table( CIFTABLE *table );
void table_dump( CIFTABLE *table );

void table_add( CIFTABLE *table, char *key, VALUE *value,
                cexception_t *ex );
VALUE *table_get( CIFTABLE *table, char *key );

#endif
