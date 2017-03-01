/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#ifndef __LIST_H
#define __LIST_H

#include <cif_grammar_y.h>
#include <cexceptions.h>
#include <value.h>

typedef struct LIST LIST;

void list_add( LIST *list, VALUE *value, cexception_t *ex );
VALUE *list_get( LIST *list, int index );

#endif
