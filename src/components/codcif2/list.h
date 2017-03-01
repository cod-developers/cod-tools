/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#ifndef __LIST_H
#define __LIST_H

typedef struct LIST LIST;

#include <cif_grammar_y.h>
#include <cexceptions.h>
#include <value.h>

void list_add( LIST *list, VALUE *value, cexception_t *ex );
VALUE *list_get( LIST *list, int index );

#endif
