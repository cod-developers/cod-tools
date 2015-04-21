
#ifndef _SUBSYSTEM_B_H
#define _SUBSYSTEM_B_H

#include <cexceptions.h>

enum SUBSYS_B_ERROR_CODE {
    SUBSYS_B_OK    = 0,
    SUBSYS_B_ERROR = 1
};

extern void *subsystem_b_tag;

void subsystem_b_function( cexception_t *ex );

#endif
