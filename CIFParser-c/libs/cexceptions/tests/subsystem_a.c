
#include <cexceptions.h>
#include <subsystem_a.h>

void *subsystem_a_tag = &subsystem_a_tag;

#define subsystem_a_exception( EX, MESSAGE ) \
    cexception_raise_in( EX, subsystem_a_tag, SUBSYS_A_ERROR, MESSAGE )

void subsystem_a_function( cexception_t *ex )
{
    subsystem_a_exception( ex, "Error in subsystem A function" );
}
