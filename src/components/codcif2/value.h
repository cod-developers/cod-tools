/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#ifndef __VALUE_H
#define __VALUE_H

typedef struct VALUE VALUE;

#include <cexceptions.h>
#include <list.h>
#include <table.h>

typedef enum {
    VALUE_UNKNOWN = 0,
    VALUE_SCALAR,
    VALUE_LIST,
    VALUE_TABLE,
} value_type_t;

VALUE *new_value_from_scalar( char *s, cexception_t *ex );
VALUE *new_value_from_list( LIST *list, cexception_t *ex );
VALUE *new_value_from_table( TABLE *table, cexception_t *ex );

value_type_t value_get_type( VALUE *value );
LIST *value_get_list( VALUE *value );
TABLE *value_get_table( VALUE *value );

#endif
