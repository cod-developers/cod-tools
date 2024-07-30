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
#include <unistd.h>
#include <stdarg.h>
#include <string.h>
#include <allocx.h>
#include <assert.h>
#include <cexceptions.h>
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
    CIFVALUE ***values;
    int *in_loop;              /* in_loop[i] is number of a loop to
                                  which the i-th tag belongs; -1 if
                                  not in a loop */
    ssize_t *value_lengths;    /* Lengths of the values[i] arrays. */
    ssize_t *value_capacities; /* Capacities of the values[i] arrays. */

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

    struct DATABLOCK *save_frames; /* All save frames in this
                                      data block; should not be
                                      nested */

    struct DATABLOCK *last_save_frame; /* Last save frame in the
                                          save_frames list; SHOULD NOT
                                          be freed when the DATABLOCK
                                          structure is deleted. */

    struct DATABLOCK *next; /* Data blocks can be linked in a linked-list. */
};

void delete_datablock( DATABLOCK *datablock )
{
    size_t i;
    ssize_t j;

    assert( !datablock || !datablock->next );

    if( datablock ) {
        for( i = 0; i < datablock->length; i++ ) {
            if( datablock->tags )
                freex( datablock->tags[i] );
            if( datablock->values ) {
                for( j = 0; j < datablock->value_lengths[i]; j++ )
                    delete_value( datablock_cifvalue( datablock, i, j ) );
                freex( datablock->values[i] );
            }
        }
        freex( datablock->name );
        freex( datablock->tags );
        freex( datablock->in_loop );
        freex( datablock->values );
        freex( datablock->value_lengths );
        freex( datablock->value_capacities );
        freex( datablock->loop_first );
        freex( datablock->loop_last );
        delete_datablock_list( datablock->save_frames );
        freex( datablock );
    }
}

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

DATABLOCK *datablock_start_save_frame( DATABLOCK *datablock, const char *name,
                                       cexception_t *ex )
{
    DATABLOCK *save_frame = NULL;
    assert( datablock );

    save_frame = new_datablock( name, NULL, ex );

    if( datablock->last_save_frame ) {
        datablock->last_save_frame->next = save_frame;
        datablock->last_save_frame = save_frame;
    } else {
        datablock->save_frames = datablock->last_save_frame = save_frame;
    }

    return save_frame;
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

size_t datablock_length( DATABLOCK *datablock )
{
    return datablock->length;
}

char **datablock_tags( DATABLOCK *datablock )
{
    return datablock->tags;
}

ssize_t *datablock_value_lengths( DATABLOCK *datablock )
{
    return datablock->value_lengths;
}

CIFVALUE *datablock_cifvalue( DATABLOCK *datablock, int tag_nr, int val_nr )
{
    if( tag_nr >= (int)datablock->length ) {
        return NULL;
    }
    if( val_nr >= datablock->value_lengths[tag_nr] ) {
        return NULL;
    }
    return datablock->values[tag_nr][val_nr];
}

ssize_t datablock_tag_index( DATABLOCK *datablock, char *tag ) {
    size_t i;
    for( i = 0; i < datablock->length; i++ ) {
        if( strcmp( datablock->tags[i], tag ) == 0 ) {
            return i;
        }
    }
    return -1;
}

int *datablock_in_loop( DATABLOCK *datablock )
{
    return datablock->in_loop;
}

cif_value_type_t datablock_value_type( DATABLOCK *datablock, int tag_nr, int val_nr )
{
    CIFVALUE *v = datablock_cifvalue( datablock, tag_nr, val_nr );
    if( v ) {
        return value_type( v );
    } else {
        return CIF_NON_EXISTANT;
    }
}

int datablock_loop_count( DATABLOCK *datablock )
{
    return datablock->loop_count;
}

DATABLOCK * datablock_save_frame_list( DATABLOCK *datablock )
{
    assert( datablock );
    return datablock->save_frames;
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
    assert( datablock );
    value_dump( datablock->values[tag_nr][value_idx] );
}

/*
  fprint_delimited_value()

  Print a CIF value that is meant to be printed in a delimted file
  (TSV or ASCII-delimited text). All "separator" (group separator) and
  "vseparator" (value separator, or record separator in ASCII
  terminology) characters are replace by a replacement character
  (usually a space). In this way we make sure that separators are nver
  enounted in values. We maight lose information if the delimiters
  were used in values to convey some information, but for TSV (Tab
  separators) TABs are usually not significant in CIFs, and ASCII
  separator characters (GS, RS, US and FS) are forbidden in CIFs and
  thus will never occur.
 */

void fprint_delimited_value( FILE *file, char *value,
                             char *group_separator, char separator,
                             char vseparator, char replacement )
{
    char *ch = value;
    
    assert( file != NULL );
    assert( value );
    assert( group_separator );

    while( *ch != '\0' ) {
        if( *ch != group_separator[0] &&
            (group_separator[0] == '\0' || *ch != group_separator[1]) &&
            *ch != separator &&
            *ch != vseparator ) {
            fputc( *ch, file );
        } else {
            fputc( replacement, file );
        }
        ch ++;
    }
}

void datablock_print_tag_values( DATABLOCK * volatile datablock,
                                 char ** tagnames, int tagcount,
                                 char * volatile prefix,
                                 char * group_separator, char * separator,
                                 char * vseparator, char * replacement )
{

    printf( "%s", prefix );
    size_t i;
    ssize_t j, k;
    for( k = 0; k < tagcount; k++ ) {
        int isfound = 0;
        for( i = 0; i < datablock->length; i++ ) {
            if( strcmp( datablock->tags[i], tagnames[k] ) == 0 ) {
                isfound = 1;
                int first = 1;
                for( j = 0; j < datablock->value_lengths[i]; j++ ) {
                    if( first == 1 ) {
                        first = 0;
                    } else {
                        printf( "%s", vseparator );
                    }
                    fprint_delimited_value
                        ( stdout, value_scalar( datablock->values[i][j] ),
                          group_separator, *separator, *vseparator,
                          *replacement );
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
    printf( "%s", group_separator );
}

/* Print values, quoting separator characters if necessary */

static int
value_contains_separators( char *value, char *group_separator, char separator,
                           char vseparator, char quote )
{
    assert( group_separator );

    if( value ) {
        while( *value ) {
            if( *value == group_separator[0] ||
                (group_separator[0] != '\0' && *value == group_separator[1]) ||
                *value == separator ||
                *value == vseparator ||
                *value == quote ||
                *value == ' ' ) {
                return 1;
            }
            value ++;
        }
    }
    return 0;
}

void fprint_quoted_value( FILE *file, char *value,
                          char *group_separator, char separator,
                          char vseparator, char replacement,
                          char quote, int must_always_quote )
{
    assert( group_separator );

    char *ch = value;
    int must_quote =
        must_always_quote ||
        value_contains_separators( value, group_separator, separator,
                                   vseparator, quote );
    
    assert( file != NULL );
    assert( value );

    if( must_quote )
        fputc(quote, file);

    while( *ch != '\0' ) {
        if( *ch != quote ) {
            fputc( *ch, file );
        } else {
            /* quote the quotation character by emitting it
               twice: */
            fputc( *ch, file );
            fputc( *ch, file );
        }
        ch ++;
    }

    if( must_quote )
        fputc(quote, file);
}

void datablock_print_quoted_tag_values( DATABLOCK * volatile datablock,
                                        char ** tagnames, int tagcount,
                                        char * volatile prefix,
                                        char * group_separator, char * separator,
                                        char * vseparator, char * replacement,
                                        char * quote, int must_always_quote )
{
    printf( "%s", prefix );
    size_t i;
    ssize_t j, k;
    for( k = 0; k < tagcount; k++ ) {
        int isfound = 0;
        for( i = 0; i < datablock->length; i++ ) {
            if( strcmp( datablock->tags[i], tagnames[k] ) == 0 ) {
                isfound = 1;
                int first = 1;
                for( j = 0; j < datablock->value_lengths[i]; j++ ) {
                    if( first == 1 ) {
                        first = 0;
                    } else {
                        printf( "%s", vseparator );
                    }
                    fprint_quoted_value
                        ( stdout, value_scalar( datablock->values[i][j] ),
                          group_separator, *separator, *vseparator,
                          *replacement, *quote, must_always_quote );
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
    printf( "%s", group_separator );
}

void datablock_dump( DATABLOCK * volatile datablock )
{
    size_t i;

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

void datablock_print_frame( DATABLOCK * volatile datablock, char *keyword )
{
    size_t i;

    assert( datablock );

    printf( "%s%s\n",  keyword, datablock->name );

    for( i = 0; i < datablock->length; i++ ) {
        if( datablock->in_loop[i] < 0 ) { /* tag is not in a loop */
            datablock_print_tag( datablock, i );
            datablock_print_value( datablock, i, 0 );
            printf( "\n" );
        } else {
            i = print_loop( datablock, i );
        }
    }

    DATABLOCK *frame;
    for( frame = datablock->save_frames; frame; frame = frame->next ) {
        datablock_print_frame( frame, "save_" );
        puts( "save_" );
    }
}

void datablock_print( DATABLOCK * volatile datablock )
{
    datablock_print_frame( datablock, "data_" );
}

void datablock_list_tags( DATABLOCK * volatile datablock )
{
    size_t i;

    assert( datablock );

    for( i = 0; i < datablock->length; i++ ) {
        printf( "%s\t%s\n", datablock->name, datablock->tags[i] );
    }
}

void datablock_insert_cifvalue( DATABLOCK * datablock, char *tag,
                                CIFVALUE *value, cexception_t *ex )
{
    cexception_t inner;
    size_t i;

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
            /* datablock->types = reallocx( datablock->types,
                                   sizeof(datablock->types[0]) *
                                   (datablock->capacity + DELTA_CAPACITY),
                                   &inner );
               datablock->types[i] = NULL; */
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
        // datablock->types[i] = callocx( sizeof(datablock->types[0][0]), 1, &inner );
        datablock->value_capacities[i] = 1;
        datablock->tags[i] = strdupx( tag, &inner );
        datablock->in_loop[i] = -1;

        if( value ) {
            datablock->value_lengths[i] = 1;
            datablock->values[i][0] = value;
        } else {
            datablock->value_lengths[i] = 0;
        }
    }
    cexception_catch {
        cexception_reraise( inner, ex );
    }
}

void datablock_overwrite_cifvalue( DATABLOCK * datablock, ssize_t tag_nr,
                                   ssize_t val_nr, CIFVALUE *value,
                                   cexception_t *ex )
{
    cexception_t inner;

    cexception_guard( inner ) {
        delete_value( datablock_cifvalue( datablock, tag_nr, val_nr ) );
        datablock->values[tag_nr][val_nr] = value;
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

    for( j = datablock->loop_start; j < (ssize_t)datablock->length; j++ ) {
        datablock->in_loop[j] = i;
    }

    datablock->loop_current = datablock->loop_start = -1;
}

void datablock_push_loop_cifvalue( DATABLOCK * datablock, CIFVALUE *value,
                                   cexception_t *ex )
{
    cexception_t inner;
    ssize_t i, j, capacity;

    assert( datablock->loop_start < (ssize_t)datablock->length );
    assert( datablock->loop_current < (ssize_t)datablock->length );

    cexception_guard( inner ) {
        i = datablock->loop_current;
        j = datablock->value_lengths[i];
        capacity = datablock->value_capacities[i];
        if( j >= capacity ) {
            //FIXME: the '... += DELTA_CAPACITY' algorithm is fine for
            // "small" CIFs, but may exhibit quadratic performance
            // when large CIFs (> 1M values in a loop) are
            // encountered. To avoid excessive run times, the doubling
            // of the allocated memory, 'capacity *= 2', as below, is
            // advised. To avoid overusing memory, however, we need
            // to reallocate back to realistic capacities at the very
            // end of the CIF data structure construction. Synthetic
            // tests for the performance of the suggested code need to
            // be built first. (S.G.).

            // capacity *= 2;
            capacity += DELTA_CAPACITY;
            datablock->values[i] = reallocx( datablock->values[i],
                                       sizeof(datablock->values[0][0]) * capacity,
                                       &inner );
            /* datablock->types[i] = reallocx( datablock->types[i],
                                      sizeof(datablock->types[0][0]) * capacity,
                                      &inner ); */
            datablock->value_capacities[i] = capacity;
        }
        datablock->value_lengths[i] = j + 1;
        datablock->values[i][j] = value;
        datablock->loop_current++;
        if( datablock->loop_current >= (ssize_t)datablock->length ) {
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
