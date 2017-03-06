/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#include <cexceptions.h>
#include <allocx.h>
#include <value.h>
#include <list.h>
#include <table.h>

VALUE *new_value_from_scalar( char *s, cexception_t *ex ) {
    VALUE *value = callocx( 1, sizeof(VALUE), ex );
    value->v.str = s;
    value->type = CIF_UNKNOWN; // for now
    return value;
}

VALUE *new_value_from_list( LIST *list, cexception_t *ex ) {
    VALUE *value = callocx( 1, sizeof(VALUE), ex );
    value->v.l = list;
    value->type = CIF_LIST;
    return value;
}

VALUE *new_value_from_table( TABLE *table, cexception_t *ex ) {
    VALUE *value = callocx( 1, sizeof(VALUE), ex );
    value->v.t = table;
    value->type = CIF_TABLE;
    return value;
}

void delete_value( VALUE *value ) {
    if( value->type == CIF_LIST ) {
    } else if( value->type == CIF_TABLE ) {
    } else {
        freex( value->v.str );
    }
    freex( value );
}

void value_dump( VALUE *value ) {
    switch( value->type ) {
        case CIF_LIST:
            list_dump( value_get_list( value ) );
            break;
        case CIF_TABLE:
            table_dump( value_get_table( value ) );
            break;
        default:
            printf( " %s", value_get_scalar( value ) );
    }
}

cif_value_type_t value_get_type( VALUE *value ) {
    return value->type;
}

char *value_get_scalar( VALUE *value ) {
    return value->v.str;
}

LIST *value_get_list( VALUE *value ) {
    return value->v.l;
}

TABLE *value_get_table( VALUE *value ) {
    return value->v.t;
}
