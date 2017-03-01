/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#include <value.h>

struct VALUE {
    union {
        char *str;
        struct VALUE *s;
        // struct LIST *l;
        // struct TABLE *t;
    } v;
    value_type_t type;
};
