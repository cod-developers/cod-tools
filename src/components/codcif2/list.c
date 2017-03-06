/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#include <string.h>
#include <allocx.h>
#include <cexceptions.h>
#include <stringx.h>
#include <list.h>
#include <value.h>

#define DELTA_CAPACITY (100)

struct LIST {

    size_t length;
    size_t capacity;

    VALUE **values;
};

LIST *new_list( cexception_t *ex )
{
    LIST *list = callocx( 1, sizeof(LIST), ex );
    return list;
}

void list_dump( LIST *list )
{
    printf( " [" );
    size_t i;
    for( i = 0; i < list->length; i++ ) {
        value_dump( list->values[i] );
    }
    printf( " ]" );
}

void list_push( LIST *list, VALUE *value, cexception_t *ex )
{
    cexception_t inner;
    size_t i;

    cexception_guard( inner ) {
        i = list->length;
        if( list->length + 1 > list->capacity ) {
            list->values = reallocx( list->values,
                                     sizeof(VALUE*) *
                                     (list->capacity + DELTA_CAPACITY),
                                      &inner );
            list->values[i] = NULL;
            list->capacity += DELTA_CAPACITY;
        }
        list->length++;

        list->values[i] = value;
    }
    cexception_catch {
        cexception_reraise( inner, ex );
    }    
}

void list_unshift( LIST *list, VALUE *value, cexception_t *ex )
{
    list_push( list, NULL, ex ); // for now, we simply extend the list

    size_t i;
    for( i = list->length-1; i > 0; i-- ) {
        list->values[i] = list->values[i-1];
    }
    list->values[0] = value;
}

size_t list_length( LIST *list )
{
    return list->length;
}

VALUE *list_get( LIST *list, int index )
{
    return list->values[index];
}

VALUE **list_get_values( LIST *list )
{
    return list->values;
}

char *list_concat( LIST *list, char separator, cexception_t *ex )
{
    /* the list has to be already checked for the existence of
     * lists of tables, since concatenating their values is not
     * of much sense */

    ssize_t length = 0;
    size_t i;
    for( i = 0; i < list_length( list ); i++ ) {
        length += strlen( value_get_scalar( list_get( list, i ) ) );
    }

    char *buf = mallocx( length + list_length( list ) - 1, ex );
    buf[0] = '\0';
    ssize_t pos = 0;
    for( i = 0; i < list_length( list ); i++ ) {
        buf = strcat( buf, value_get_scalar( list_get( list, i ) ) );
        pos = pos + strlen( value_get_scalar( list_get( list, i ) ) );
        if( i != list_length( list ) - 1 ) {
            buf[pos] = separator;
            buf[pos+1] = '\0';
            pos += 1;
        }
    }

    return buf;
}
