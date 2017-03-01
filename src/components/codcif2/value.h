/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

typedef struct VALUE VALUE;

typedef enum {
    VALUE_UNKNOWN = 0,
    VALUE_SCALAR,
    VALUE_LIST,
    VALUE_TABLE,
} value_type_t;
