/*-------------------------------------------------------------------------*\
* $Author$
* $Date$
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#ifndef __CIFLIST_H
#define __CIFLIST_H

#include <stdio.h>
#include <cexceptions.h>

typedef struct CIFLIST CIFLIST;

#include <cifvalue.h>

CIFLIST *new_list( cexception_t *ex );
void delete_list( CIFLIST *list );
void list_dump( CIFLIST *list );

void list_push( CIFLIST *list, CIFVALUE *value, cexception_t *ex );
void list_unshift( CIFLIST *list, CIFVALUE *value, cexception_t *ex );

size_t list_length( CIFLIST *list );
CIFVALUE *list_get( CIFLIST *list, int index );
CIFVALUE **list_get_values( CIFLIST *list );

int list_contains_list_or_table( CIFLIST *list );
char *list_concat( CIFLIST *list, char separator, cexception_t *ex );

#endif
