/*---------------------------------------------------------------------------*\
** $Author$
** $Date$
** $Revision$
** $URL$
\*---------------------------------------------------------------------------*/

#include <stdio.h>
#include <stdiox.h>
#include <cexceptions.h>

int main( int argc, char *argv[] )
{
    cexception_t inner;
    char *progname = argv[0];
    char *filename = "nonexistent.txt";
    FILE * volatile fp = NULL;

    cexception_try( inner ) {
        fp = fopenx( filename, "r", &inner );
        fclosex( fp, &inner );
    }
    cexception_catch {
        fprintf( stderr, "%s: %s: %s - %s\n",
                 progname, filename, 
                 cexception_message( &inner ),
                 cexception_explanation( &inner ));
        exit(1);
    }

    return 0;
}
