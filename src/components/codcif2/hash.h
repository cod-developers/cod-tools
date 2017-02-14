/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#include <cif_grammar_y.h>
#include <cexceptions.h>

void hash_add( typed_value *root, char *key, typed_value *value,
               cexception_t *ex );
typed_value *hash_get( typed_value *root, char *key );
