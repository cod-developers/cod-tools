/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#ifndef __LIST_H
#define __LIST_H

#include <stdio.h>
#include <cexceptions.h>

typedef struct LIST LIST;

#include <value.h>

LIST *new_list( cexception_t *ex );
void delete_list( LIST *list );
void list_dump( LIST *list );

void list_push( LIST *list, VALUE *value, cexception_t *ex );
void list_unshift( LIST *list, VALUE *value, cexception_t *ex );

size_t list_length( LIST *list );
VALUE *list_get( LIST *list, int index );
VALUE **list_get_values( LIST *list );

int list_contains_list_or_table( LIST *list );
char *list_concat( LIST *list, char separator, cexception_t *ex );

#endif
