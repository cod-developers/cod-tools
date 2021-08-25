/*---------------------------------------------------------------------------*\
** $Author$
** $Date$
** $Revision$
** $URL$
\*---------------------------------------------------------------------------*/

#include <stdio.h>
#include <stringx.h>
#include <allocx.h>
#include <cexceptions.h>

int main()
{
    int *data = NULL;
    int i;
    const int len = 20;

    for( i = 0; i < len; i++ ) {
        data = creallocx( data, i, i + 1, sizeof(data[0]), NULL );
        data[i] += i;
    }

    for( i = 0; i < len; i++ ) {
        printf( "%d ", data[i] );
    }
    printf( "\n" );

    freex( data );

    return 0;
}
