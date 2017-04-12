/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#include <cexceptions.h>
#include <assert.h>
#include <allocx.h>
#include <cifvalue.h>
#include <ciflist.h>
#include <ciftable.h>

struct CIFVALUE {
    union {
        char *str;
        struct CIFLIST *l;
        struct CIFTABLE *t;
    } v;
    cif_value_type_t type;
};

void delete_value( CIFVALUE *value ) {
    assert( value );

    if( value->type == CIF_LIST ) {
        delete_list( value_list( value ) );
    } else if( value->type == CIF_TABLE ) {
        delete_table( value_table( value ) );
    } else {
        freex( value->v.str );
    }
    freex( value );
}

CIFVALUE *new_value_from_scalar( char *s, cif_value_type_t type,
                              cexception_t *ex )
{
    CIFVALUE *value = callocx( 1, sizeof(CIFVALUE), ex );
    value->v.str = s;
    value->type = type;
    return value;
}

CIFVALUE *new_value_from_list( CIFLIST *list, cexception_t *ex )
{
    CIFVALUE *value = callocx( 1, sizeof(CIFVALUE), ex );
    value->v.l = list;
    value->type = CIF_LIST;
    return value;
}

CIFVALUE *new_value_from_table( CIFTABLE *table, cexception_t *ex )
{
    CIFVALUE *value = callocx( 1, sizeof(CIFVALUE), ex );
    value->v.t = table;
    value->type = CIF_TABLE;
    return value;
}

void value_dump( CIFVALUE *value ) {
    assert( value );
    switch( value->type ) {
        case CIF_LIST:
            list_dump( value_list( value ) );
            break;
        case CIF_TABLE:
            table_dump( value_table( value ) );
            break;
        case CIF_SQSTRING:
            printf( " '%s'", value_scalar( value ) );
            break;
        case CIF_DQSTRING:
            printf( " \"%s\"", value_scalar( value ) );
            break;
        case CIF_SQ3STRING:
            printf( " '''%s'''", value_scalar( value ) );
            break;
        case CIF_DQ3STRING:
            printf( " \"\"\"%s\"\"\"", value_scalar( value ) );
            break;
        case CIF_TEXT:
            printf( "\n;%s\n;\n", value_scalar( value ) );
            break;
        default:
            printf( " %s", value_scalar( value ) );
    }
}

cif_value_type_t value_type( CIFVALUE *value ) {
    return value->type;
}

char *value_scalar( CIFVALUE *value ) {
    return value->v.str;
}

CIFLIST *value_list( CIFVALUE *value ) {
    return value->v.l;
}

CIFTABLE *value_table( CIFVALUE *value ) {
    return value->v.t;
}
