/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#include <stdio.h>
#include <stringx.h>
#include <allocx.h>
#include <cexceptions.h>

int main()
{
    char *str;

    str = strdupx( "test string", NULL_EXCEPTION );
    printf( "Duplicated string: %s\n", str );
    freex( str );

    return 0;
}
