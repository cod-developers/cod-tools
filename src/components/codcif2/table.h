/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#ifndef __TABLE_H
#define __TABLE_H

typedef struct TABLE TABLE;

#include <stdio.h>
#include <cexceptions.h>
#include <value.h>

TABLE *new_table( cexception_t *ex );
void table_dump( TABLE *table );

void table_add( TABLE *table, char *key, VALUE *value,
                cexception_t *ex );
VALUE *table_get( TABLE *table, char *key );

#endif
