/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

/* representation of the CIF data for the CIF parser. */

/* exports: */
#include <datablock.h>

/* uses: */
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <allocx.h>
#include <assert.h>
#include <cexceptions.h>
#include <cxprintf.h>
#include <stringx.h>

void *datablock_subsystem = &datablock_subsystem;

static int datablock_debug = 0;

void datablock_debug_on( void )
{
    datablock_debug = 1;
}

int datablock_debug_is_on( void )
{
    return datablock_debug;
}

void datablock_debug_off( void )
{
    datablock_debug = 0;
}

#define DELTA_CAPACITY (100)

struct DATABLOCK {

    char *name; /* Data block name, as given in the data_... header. */
    /* Fields 'length' and 'capacity' describe allocated parallel
       arrays tags and values. The 'capacity' field contains a number
       of array elements allocated for use in each array. The 'length'
       field contains a number of elements actually used. All elements
       after the 'length-1'-th element MAY contain NULL values. */
    size_t length;
    size_t capacity;
    char **tags;
    char ***values;
    int *in_loop;              /* in_loop[i] is number of a loop to
				  which the i-th tag belongs; -1 if
				  not in a loop */
    ssize_t *value_lengths;    /* Lengths of the values[i] arrays. */
    ssize_t *value_capacities; /* Capacities of the values[i] arrays. */
    datablock_value_type_t **types;  /* Type for each value in 'values'. */

    ssize_t loop_value_count; /* Number of values in the currently constructed loop. */
    ssize_t loop_start; /* Index of the entry into the 'tags',
                           'values' and 'types' arrays that indicates
                           the beginning of the currently compiled
                           loop. */
    ssize_t loop_current; /* Index of the 'values' and 'types' arrays
                             where a new loop value will be pushed. */

    int loop_count;  /* Number of loops in the array 'loop_first' and 'loop_last'. */
    int *loop_first; /* loop_first[i] is the first tag index in the
			array 'tags' of the i-th loop. */
    int *loop_last;  /* loop_last[i] is the last tag index of the i-th loop. */

    struct DATABLOCK *next; /* Data blocks can be linked in a linked-list. */
};

DATABLOCK *new_datablock( const char *name, DATABLOCK *next, cexception_t *ex )
{
    cexception_t inner;
    DATABLOCK * volatile datablock = callocx( 1, sizeof(DATABLOCK), ex );

    cexception_guard( inner ) {
        datablock->loop_start = -1;
        if( name ) {
            datablock->name = strdupx( name, &inner );
        }
        datablock->next = next;
    }
    cexception_catch {
        delete_datablock( datablock );
        cexception_reraise( inner, ex );
    }
    return datablock;
}

void delete_datablock( DATABLOCK *datablock )
{
    ssize_t i, j;

    assert( !datablock || !datablock->next );

    if( datablock ) {
        for( i = 0; i < datablock->length; i++ ) {
            if( datablock->tags ) 
                freex( datablock->tags[i] );
            if( datablock->values && datablock->values[i] ) {
                for( j = 0; j < datablock->value_lengths[i]; j++ )
                    freex( datablock->values[i][j] );
                freex( datablock->values[i] );
            }
        }
        freex( datablock->name );
        freex( datablock->tags );
        freex( datablock->in_loop );
        freex( datablock->values );
        freex( datablock->value_lengths );
        freex( datablock->value_capacities );
        freex( datablock->types );
        freex( datablock->loop_first );
        freex( datablock->loop_last );
	freex( datablock );
    }
}

void delete_datablock_list( DATABLOCK *datablock_list )
{
    DATABLOCK *current;

    current = datablock_list;
    while( current ) {
        datablock_list = current->next;
        current->next = NULL;
        delete_datablock( current );
        current = datablock_list;
    }
}

void create_datablock( DATABLOCK * volatile *datablock, const char *name,
                       DATABLOCK *next, cexception_t *ex )
{
    assert( datablock );
    assert( !(*datablock) );

    *datablock = new_datablock( name, next, ex );
}

void dispose_datablock( DATABLOCK * volatile *datablock )
{
    assert( datablock );
    if( *datablock ) {
	delete_datablock( *datablock );
	*datablock = NULL;
    }
}

DATABLOCK *datablock_next( DATABLOCK *datablock )
{
    if( datablock ) {
        return datablock->next;
    } else {
        return NULL;
    }
}

void datablock_set_next( DATABLOCK *datablock, DATABLOCK *next )
{
    if( datablock ) {
        assert( !datablock->next );
        datablock->next = next;
    }
}

void datablock_print_tag( DATABLOCK * volatile datablock, int tag_nr )
{
    assert( datablock );
    printf( "%-32s", datablock->tags[tag_nr] );
}

void datablock_print_value( DATABLOCK * volatile datablock, int tag_nr, int value_idx )
{
    ssize_t i, j;

    assert( datablock );
    i = tag_nr;
    j = value_idx;

    switch( datablock->types[i][j] ) {
    case DBLK_NUMBER:
    case DBLK_UQSTRING:
	printf( " %s", datablock->values[i][j] );
	break;
    case DBLK_SQSTRING:
	printf( " '%s'", datablock->values[i][j] );
	break;
    case DBLK_DQSTRING:
	printf( " \"%s\"", datablock->values[i][j] );
	break;
    case DBLK_TEXT:
	printf( "\n;%s\n;\n", datablock->values[i][j] );
	break;
    default:
	fprintf( stderr, "unknown DATABLOCK value type %d from DATABLOCK parser!\n",
		 datablock->types[i][j] );
	printf( " '%s'\n", datablock->values[i][j] );
	break;
    }
}

void datablock_print_tag_values( DATABLOCK * volatile datablock,
    char ** tagnames, int tagcount, char * volatile prefix, char * separator,
    char * vseparator )
{

    printf( "%s", prefix );
    ssize_t i, j, k;
    for( k = 0; k < tagcount; k++ ) {
        int isfound = 0;
        for( i = 0; i < datablock->length; i++ ) {
            if( strcmp( datablock->tags[i], tagnames[k] ) == 0 ) {
                isfound = 1;
                int first = 1;
                for( j = 0; j < datablock->value_lengths[i]; j++ ) {
                    if( first == 1 ) {
                        printf( "%s", datablock->values[i][j] );
                        first = 0;
                    } else {
                        printf( "%s%s", vseparator, datablock->values[i][j] );
                    }
                }
                break;
            }
        }
        if( isfound == 0 ) {
            printf( "?" );
        }
        if( k != tagcount - 1 ) {
            printf( "%s", separator );
        }
    }
    printf( "\n" );
}

void datablock_dump( DATABLOCK * volatile datablock )
{
    ssize_t i;

    for( i = 0; i < datablock->length; i++ ) {
	datablock_print_tag( datablock, i );
	datablock_print_value( datablock, i, 0 );
	printf( "\n" );
    }
}

static int print_loop( DATABLOCK *datablock, ssize_t i )
{
    ssize_t j, k, loop, max;

    loop = datablock->in_loop[i];
    printf( "loop_\n" );
    for( j = datablock->loop_first[loop]; j <= datablock->loop_last[loop]; j++ ) {
	printf( "    %s\n", datablock->tags[j] );
    }

    for( max = 0, j = datablock->loop_first[loop]; j <= datablock->loop_last[loop]; j++ ) {
	if( max < datablock->value_lengths[j] )
	    max = datablock->value_lengths[j];
    }

    for( k = 0; k < max; k++ ) {
	for( j = datablock->loop_first[loop]; j <= datablock->loop_last[loop]; j++ ) {
	    if( k < datablock->value_lengths[j] ) {
		datablock_print_value( datablock, j, k );
	    } else {
		printf( ". " );
	    }
	}
	printf( "\n" );
    }
    return datablock->loop_last[loop];
}

void datablock_print( DATABLOCK * volatile datablock )
{
    ssize_t i;

    assert( datablock );

    printf( "data_%s\n",  datablock->name );

    for( i = 0; i < datablock->length; i++ ) {
	if( datablock->in_loop[i] < 0 ) { /* tag is not in a loop */
	    datablock_print_tag( datablock, i );
	    datablock_print_value( datablock, i, 0 );
	    printf( "\n" );
	} else {
	    i = print_loop( datablock, i );
	}
    }
}

void datablock_list_tags( DATABLOCK * volatile datablock )
{
    ssize_t i;

    assert( datablock );

    for( i = 0; i < datablock->length; i++ ) {
        printf( "%s\t%s\n", datablock->name, datablock->tags[i] );
    }
}

void datablock_insert_value( DATABLOCK * datablock, char *tag,
                       char *value, datablock_value_type_t vtype,
                       cexception_t *ex )
{
    cexception_t inner;
    ssize_t i;

    cexception_guard( inner ) {
        i = datablock->length;
        if( datablock->length + 1 > datablock->capacity ) {
            datablock->tags = reallocx( datablock->tags,
                                  sizeof(datablock->tags[0]) *
                                  (datablock->capacity + DELTA_CAPACITY),
                                  &inner );
            datablock->tags[i] = NULL;
            datablock->in_loop = reallocx( datablock->in_loop,
				     sizeof(datablock->in_loop[0]) *
				     (datablock->capacity + DELTA_CAPACITY),
				     &inner );
            datablock->values = reallocx( datablock->values,
                                    sizeof(datablock->values[0]) *
                                    (datablock->capacity + DELTA_CAPACITY),
                                    &inner );
            datablock->values[i] = NULL;
            datablock->types = reallocx( datablock->types,
                                   sizeof(datablock->types[0]) *
                                   (datablock->capacity + DELTA_CAPACITY),
                                   &inner );
            datablock->values[i] = NULL;
            datablock->value_lengths = reallocx( datablock->value_lengths,
                                           sizeof(datablock->value_lengths[0]) *
                                           (datablock->capacity + DELTA_CAPACITY),
                                           &inner );
	    datablock->value_lengths[i] = 0;
            datablock->value_capacities = reallocx( datablock->value_capacities,
                                              sizeof(datablock->value_capacities[0]) *
                                              (datablock->capacity + DELTA_CAPACITY),
                                              &inner );
	    datablock->value_capacities[i] = 0;

            datablock->capacity += DELTA_CAPACITY;
        }
        datablock->length++;

        datablock->values[i] = callocx( sizeof(datablock->values[0][0]), 1, &inner );
        datablock->types[i] = callocx( sizeof(datablock->types[0][0]), 1, &inner );
        datablock->value_capacities[i] = 1;
        datablock->tags[i] = tag;
	datablock->in_loop[i] = -1;

        if( value ) {
            datablock->value_lengths[i] = 1;
            datablock->values[i][0] = value;
            datablock->types[i][0] = vtype;
        } else {
            datablock->value_lengths[i] = 0;
	}
    }
    cexception_catch {
        cexception_reraise( inner, ex );
    }
}

void datablock_start_loop( DATABLOCK *datablock )
{
    assert( datablock );
    datablock->loop_value_count = 0;
    datablock->loop_current = datablock->loop_start = datablock->length;
}

void datablock_finish_loop( DATABLOCK *datablock, cexception_t *ex )
{
    ssize_t i, j;
    assert( datablock );

    i = datablock->loop_count;
    datablock->loop_count ++;
    datablock->loop_first = reallocx( datablock->loop_first,
				sizeof(datablock->loop_first[0]) *
				datablock->loop_count, ex );
    datablock->loop_last = reallocx( datablock->loop_last,
			       sizeof(datablock->loop_last[0]) *
			       datablock->loop_count, ex );

    datablock->loop_first[i] = datablock->loop_start;
    datablock->loop_last[i] = datablock->length - 1;

    for( j = datablock->loop_start; j < datablock->length; j++ ) {
	datablock->in_loop[j] = i;
    }

    datablock->loop_current = datablock->loop_start = -1;
}

void datablock_push_loop_value( DATABLOCK * datablock, char *value, datablock_value_type_t vtype,
                          cexception_t *ex )
{
    cexception_t inner;
    ssize_t i, j, capacity;

    assert( datablock->loop_start < datablock->length );
    assert( datablock->loop_current < datablock->length );

    cexception_guard( inner ) {
        i = datablock->loop_current;
        j = datablock->value_lengths[i];
        capacity = datablock->value_capacities[i];
        if( j >= capacity ) {
            capacity += DELTA_CAPACITY;
            datablock->values[i] = reallocx( datablock->values[i],
                                       sizeof(datablock->values[0][0]) * capacity,
                                       &inner );
            datablock->types[i] = reallocx( datablock->types[i],
                                      sizeof(datablock->types[0][0]) * capacity,
                                      &inner );
            datablock->value_capacities[i] = capacity;
        }
        datablock->value_lengths[i] = j + 1;
        datablock->values[i][j] = value;
        datablock->types[i][j] = vtype;
        datablock->loop_current++;
        if( datablock->loop_current >= datablock->length ) {
            datablock->loop_current = datablock->loop_start;
        }
    }
    cexception_catch {
        cexception_reraise( inner, ex );
    }
}

char * datablock_name( DATABLOCK * datablock ) {
    return datablock->name;
}
