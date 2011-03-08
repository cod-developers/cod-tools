
#ifndef _SUBSYSTEM_A_H
#define _SUBSYSTEM_A_H

#include <cexceptions.h>

enum SUBSYS_A_ERROR_CODE {
    SUBSYS_A_OK    = 0,
    SUBSYS_A_ERROR = 1
};

extern void *subsystem_a_tag;

void subsystem_a_function( cexception_t *ex );

#endif
