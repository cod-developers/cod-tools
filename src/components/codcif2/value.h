/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#ifndef __VALUE_H
#define __VALUE_H

typedef struct VALUE VALUE;

typedef enum {
    VALUE_UNKNOWN = 0,
    VALUE_SCALAR,
    VALUE_LIST,
    VALUE_TABLE,
} value_type_t;

#endif
