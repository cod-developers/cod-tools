/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#ifndef __LIST_H
#define __LIST_H

typedef struct LIST LIST;

#include <cexceptions.h>
#include <value.h>

LIST *new_list( cexception_t *ex );

void list_push( LIST *list, VALUE *value, cexception_t *ex );
void list_unshift( LIST *list, VALUE *value, cexception_t *ex );

size_t list_length( LIST *list );
VALUE *list_get( LIST *list, int index );
VALUE **list_get_values( LIST *list );

#endif
