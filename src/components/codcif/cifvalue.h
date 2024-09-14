/*-------------------------------------------------------------------------*\
* $Author$
* $Date$
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#ifndef __VALUE_H
#define __VALUE_H

#include <cexceptions.h>

typedef struct CIFVALUE CIFVALUE;

typedef enum {
    CIF_UNKNOWN = 0,
    CIF_NON_EXISTANT,
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

#include <ciflist.h>
#include <ciftable.h>

CIFVALUE *new_value_from_scalar( char *s, cif_value_type_t type, cexception_t *ex );
CIFVALUE *new_value_from_list( CIFLIST *list, cexception_t *ex );
CIFVALUE *new_value_from_table( CIFTABLE *table, cexception_t *ex );

void delete_value( CIFVALUE *value );
void value_dump( CIFVALUE *value );

cif_value_type_t value_type( CIFVALUE *value );
char *value_scalar( CIFVALUE *value );
CIFLIST *value_list( CIFVALUE *value );
CIFTABLE *value_table( CIFVALUE *value );

cif_value_type_t value_type_from_string_1_1( char *str );
cif_value_type_t value_type_from_string_2_0( char *str );

#endif
