/*-------------------------------------------------------------------------*\
* $Author$
* $Date$
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#include <string.h>
#include <assert.h>
#include <cif_grammar_y.h>
#include <allocx.h>
#include <cexceptions.h>
#include <stringx.h>
#include <ciftable.h>
#include <cifvalue.h>

#define DELTA_CAPACITY (100)

struct CIFTABLE {

    size_t length;
    size_t capacity;

    char **keys;
    CIFVALUE **values;
};

void delete_table( CIFTABLE *table )
{
    assert( table );

    size_t i;
    for( i = 0; i < table->length; i++ ) {
        freex( table->keys[i] );
        delete_value( table->values[i] );
    }
    freex( table->keys );
    freex( table->values );
    freex( table );
}

CIFTABLE *new_table( cexception_t *ex )
{
    CIFTABLE *table = callocx( 1, sizeof(CIFTABLE), ex );
    table->values = NULL;
    return table;
}

void table_dump( CIFTABLE *table )
{
    assert( table );
    printf( " {" );
    size_t i;
    for( i = 0; i < table->length; i++ ) {
        int max_sq_in_row = 0;
        int max_dq_in_row = 0;
        size_t j = 0;
        while( table->keys[i][j] != '\0' ) {
            if(        table->keys[i][j] == '\'' ) {
                if( max_sq_in_row == 0 || j == 0 ||
                    table->keys[i][j-1] == '\'' ) {
                    max_sq_in_row++;
                }
            } else if( table->keys[i][j] == '"' ) {
                if( max_dq_in_row == 0 || j == 0 ||
                    table->keys[i][j-1] == '"' ) {
                    max_dq_in_row++;
                }
            }
            j++;
        }
        if( max_sq_in_row == 0 ) {
            // string without single quotes
            printf( " '%s':", table->keys[i] );
        } else if( max_dq_in_row == 0 ) {
            // string without double quotes
            printf( " \"%s\":", table->keys[i] );
        } else if( max_sq_in_row < 3 ) {
            // string with 1 or 2 single quotes and some double quotes
            printf( " '''%s''':", table->keys[i] );
        } else {
            // string with three single quotes and 1 or 2 double quotes
            printf( " \"\"\"%s\"\"\":", table->keys[i] );
        }
        value_dump( table->values[i] );
    }
    printf( " }" );
}

size_t table_length( CIFTABLE *table )
{
    assert( table );
    return table->length;
}

char **table_keys( CIFTABLE *table )
{
    assert( table );
    return table->keys;
}

void table_add( CIFTABLE *table, char *key, CIFVALUE *value, cexception_t *ex )
{
    assert( table );

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
                                      sizeof( CIFVALUE* ) *
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

CIFVALUE *table_get( CIFTABLE *table, char *key )
{
    assert( table );
    size_t i;
    for( i = 0; i < table->length; i++ ) {
        if( strcmp( table->keys[i], key ) == 0 ) {
            return table->values[i];
        }
    }
    return NULL;
}
