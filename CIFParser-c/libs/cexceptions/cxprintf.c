/*---------------------------------------------------------------------------*\
** $Author$
** $Date$ 
** $Revision$
** $URL$
\*---------------------------------------------------------------------------*/

/* composing error message for the exception handling subsystem */

/* exports: */
#include <cxprintf.h>

/* uses: */
#include <stdarg.h>
#include <stdio.h>

const char* cxprintf( const char * format, ... )
{
    const char *message;
    va_list arguments;

    va_start( arguments, format );
    message = vcxprintf( format, arguments );
    va_end( arguments );
    return message;
}

const char* vcxprintf( const char * format, va_list args )
{
    static char error_message[200] = "";

    /*
    vsnprintf( error_message, sizeof(error_message), format, args );
    */
    vsprintf( error_message, format, args );
    return error_message;
}
