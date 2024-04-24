/*-------------------------------------------------------------------------*\
* $Author$
* $Date$
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#include <string.h>
#include <assert.h>
#include <allocx.h>
#include <cexceptions.h>
#include <stringx.h>
#include <ciflist.h>
#include <cifvalue.h>

#define DELTA_CAPACITY (100)

struct CIFLIST {

    size_t length;
    size_t capacity;

    CIFVALUE **values;
};

void delete_list( CIFLIST *list )
{
    assert( list );

    size_t i;
    for( i = 0; i < list->length; i++ ) {
        delete_value( list->values[i] );
    }
    freex( list->values );
    freex( list );
}

CIFLIST *new_list( cexception_t *ex )
{
    CIFLIST *list = callocx( 1, sizeof(CIFLIST), ex );
    return list;
}

void list_dump( CIFLIST *list )
{
    assert( list );

    printf( " [" );
    size_t i;
    for( i = 0; i < list->length; i++ ) {
        value_dump( list->values[i] );
    }
    printf( " ]" );
}

void list_push( CIFLIST *list, CIFVALUE *value, cexception_t *ex )
{
    assert( list );

    cexception_t inner;
    size_t i;

    cexception_guard( inner ) {
        i = list->length;
        if( list->length + 1 > list->capacity ) {
            list->values = reallocx( list->values,
                                     sizeof(CIFVALUE*) *
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

void list_unshift( CIFLIST *list, CIFVALUE *value, cexception_t *ex )
{
    assert( list );
    list_push( list, NULL, ex ); // for now, we simply extend the list

    size_t i;
    for( i = list->length-1; i > 0; i-- ) {
        list->values[i] = list->values[i-1];
    }
    list->values[0] = value;
}

size_t list_length( CIFLIST *list )
{
    return list->length;
}

CIFVALUE *list_get( CIFLIST *list, int index )
{
    return list->values[index];
}

CIFVALUE **list_get_values( CIFLIST *list )
{
    return list->values;
}

int list_contains_list_or_table( CIFLIST *list )
{
    assert( list );
    size_t i;
    for( i = 0; i < list_length( list ); i++ ) {
        CIFVALUE *value = list_get( list, i );
        if( value_type( value ) == CIF_LIST ||
            value_type( value ) == CIF_TABLE ) {
            return 1;
            break;
        }
    }
    return 0;
}

char *list_concat( CIFLIST *list, char separator, cexception_t *ex )
{
    assert( list );
    /* the list has to be already checked for the existence of
     * lists of tables, since concatenating their values is not
     * of much sense */

    ssize_t length = 0;
    size_t i;
    for( i = 0; i < list_length( list ); i++ ) {
        length += strlen( value_scalar( list_get( list, i ) ) );
    }

    char *buf = mallocx( length + list_length( list ), ex );
    buf[0] = '\0';
    ssize_t pos = 0;
    for( i = 0; i < list_length( list ); i++ ) {
        buf = strcat( buf, value_scalar( list_get( list, i ) ) );
        pos = pos + strlen( value_scalar( list_get( list, i ) ) );
        if( i != list_length( list ) - 1 ) {
            buf[pos] = separator;
            buf[pos+1] = '\0';
            pos += 1;
        }
    }

    return buf;
}
