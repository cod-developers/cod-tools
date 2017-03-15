/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#ifndef __VALUE_H
#define __VALUE_H

#include <cexceptions.h>

typedef struct VALUE VALUE;

typedef enum {
    CIF_UNKNOWN = 0,
    CIF_INT,
    CIF_FLOAT,
    CIF_UQSTRING,
    CIF_SQSTRING,
    CIF_DQSTRING,
    CIF_SQ3STRING,
    CIF_DQ3STRING,
    CIF_TEXT,
    CIF_LIST,
    CIF_TABLE,
    last_CIF_VALUE
} cif_value_type_t;

#include <list.h>
#include <table.h>

VALUE *new_value_from_scalar( char *s, cif_value_type_t type, cexception_t *ex );
VALUE *new_value_from_list( LIST *list, cexception_t *ex );
VALUE *new_value_from_table( TABLE *table, cexception_t *ex );

void delete_value( VALUE *value );
void value_dump( VALUE *value );

cif_value_type_t value_get_type( VALUE *value );
char *value_get_scalar( VALUE *value );
LIST *value_get_list( VALUE *value );
TABLE *value_get_table( VALUE *value );

#endif
