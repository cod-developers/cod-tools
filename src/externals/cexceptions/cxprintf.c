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

#ifndef CXPRINTF_BUFFER_SIZE
#define CXPRINTF_BUFFER_SIZE 1024
#endif

#ifndef HAS_VSNPRINTF
#if _XOPEN_SOURCE >= 500 || _ISOC99_SOURCE || _BSD_SOURCE
#define HAS_VSNPRINTF 1
#endif
#endif

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
    static char error_message[CXPRINTF_BUFFER_SIZE] = "";

#if HAS_VSNPRINTF
    vsnprintf( error_message, sizeof(error_message), format, args );
#else
#warning Can not safely compile 'vcxprintf' on this system without buffer overruns – no 'vsnprintf' provided by libc
    vsprintf( error_message, format, args );
#endif
    return error_message;
}
