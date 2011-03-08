/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#ifndef __CEX_REPORT_H
#define __CEX_REPORT_H

#include <stdarg.h>

const char* cxprintf( const char * format, ... );
const char* vcxprintf( const char * format, va_list args );

#endif
