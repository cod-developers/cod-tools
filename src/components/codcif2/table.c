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
#include <table.h>
#include <value.h>

#define DELTA_CAPACITY (100)

struct TABLE {

    size_t length;
    size_t capacity;

    char **keys;
    VALUE **values;
};

TABLE *new_table( cexception_t *ex )
{
    TABLE *table = callocx( 1, sizeof(TABLE*), ex );
    return table;
}

void table_add( TABLE *table, char *key, VALUE *value, cexception_t *ex )
{
    cexception_t inner;
    ssize_t i;
    
    cexception_guard( inner ) {
        i = table->length;
        if( table->length + 1 > table->capacity ) {
            table->keys = reallocx( table->keys,
                                    sizeof( char* ) *
                                    (table->capacity + DELTA_CAPACITY),
                                    &inner );
            table->keys[i] = NULL;
            table->values = reallocx( table->values,
                                      sizeof( VALUE* ) *
                                      (table->capacity + DELTA_CAPACITY),
                                      &inner );
            table->values[i] = NULL;
            table->capacity += DELTA_CAPACITY;
        }
        table->length++;

        table->keys[i] = strdupx( key, &inner );
        table->values[i] = value;
    }
    cexception_catch {
        cexception_reraise( inner, ex );
    }    
}

VALUE *table_get( TABLE *table, char *key )
{
    size_t i;
    for( i = 0; i < table->length; i++ ) {
        if( strcmp( table->keys[i], key ) == 0 ) {
            return table->values[i];
        }
    }
    return NULL;
}
