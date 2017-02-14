/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#include <string.h>
#include <cif_grammar_y.h>
#include <allocx.h>
#include <cexceptions.h>
#include <stringx.h>

#define DELTA_CAPACITY (100)

void hash_add( typed_value *root, char *key, typed_value *value,
               cexception_t *ex )
{
    cexception_t inner;
    ssize_t i;
    
    cexception_guard( inner ) {
        i = root->vlength;
        if( root->vlength + 1 > root->vcapacity ) {
            root->vkeys = reallocx( root->vkeys,
                                    sizeof( char* ) *
                                    (root->vcapacity + DELTA_CAPACITY),
                                    &inner );
            root->vkeys[i] = NULL;
            root->vvalues = reallocx( root->vvalues,
                                      sizeof( typed_value* ) *
                                      (root->vcapacity + DELTA_CAPACITY),
                                      &inner );
            root->vvalues[i] = NULL;
            root->vcapacity += DELTA_CAPACITY;
        }
        root->vlength++;

        root->vkeys[i] = strdupx( key, &inner );
        root->vvalues[i] = value;
    }
    cexception_catch {
        cexception_reraise( inner, ex );
    }    
}

typed_value *hash_get( typed_value *root, char *key )
{
    ssize_t i;
    for( i = 0; i < root->vlength; i++ ) {
        if( strcmp( root->vkeys[i], key ) == 0 ) {
            return root->vvalues[i];
        }
    }
    return NULL;
}
