/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#ifndef __COMMON_H
#define __COMMON_H

#include <stdlib.h>

char *strclone( const char *s );
char *strnclone( const char *s, size_t length );
char *strappend( char *s, const char *suffix );
char *process_escapes( char *str );
char translate_escape( char **s );

#endif
