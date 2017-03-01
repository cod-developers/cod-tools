/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#ifndef __TABLE_H
#define __TABLE_H

typedef struct TABLE TABLE;

#include <cif_grammar_y.h>
#include <cexceptions.h>
#include <value.h>

void table_add( typed_value *root, char *key, typed_value *value,
               cexception_t *ex );
typed_value *table_get( typed_value *root, char *key );
VALUE *table_get_t( TABLE *table, char *key );

#endif
