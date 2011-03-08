
#include <cexceptions.h>
#include <subsystem_b.h>

void *subsystem_b_tag = &subsystem_b_tag;

#define subsystem_b_exception( EX, MESSAGE ) \
    cexception_raise_in( EX, subsystem_b_tag, SUBSYS_B_ERROR, MESSAGE )

void subsystem_b_function( cexception_t *ex )
{
    subsystem_b_exception( ex, "Error in subsystem B function" );
}
