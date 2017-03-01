/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#include <cexceptions.h>
#include <allocx.h>
#include <value.h>
#include <table.h>

struct VALUE {
    union {
        char *str;
        // struct LIST *l;
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

VALUE *new_value_from_table( TABLE *t, cexception_t *ex ) {
    VALUE *value = callocx( 1, sizeof(VALUE), ex );
    value->v.t = t;
    value->type = VALUE_TABLE;
    return value;
}
