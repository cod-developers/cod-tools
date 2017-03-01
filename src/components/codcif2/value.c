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

struct VALUE {
    union {
        char *str;
        struct LIST *l;
        struct TABLE *t;
    } v;
    value_type_t type;
};

VALUE *new_value_from_scalar( char *s, cexception_t *ex ) {
    VALUE *value = callocx( 1, sizeof(VALUE), ex );
    value->v.str = s;
    value->type = VALUE_SCALAR;
    return value;
}

VALUE *new_value_from_list( LIST *list, cexception_t *ex ) {
    VALUE *value = callocx( 1, sizeof(VALUE), ex );
    value->v.l = list;
    value->type = VALUE_LIST;
    return value;
}

VALUE *new_value_from_table( TABLE *table, cexception_t *ex ) {
    VALUE *value = callocx( 1, sizeof(VALUE), ex );
    value->v.t = table;
    value->type = VALUE_TABLE;
    return value;
}
