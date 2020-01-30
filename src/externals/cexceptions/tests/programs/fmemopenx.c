/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#include <stdio.h>
#include <stdiox.h>
#include <cexceptions.h>

int main( int argc, char *argv[] )
{
    cexception_t inner;
    char *progname = argv[0];
    char *buffer = "text";
    FILE * volatile fp_ok = NULL;
    FILE * volatile fp_fail = NULL;

    cexception_try( inner ) {
        fp_ok = fmemopenx( buffer, 4, "r", &inner );
        fp_fail = fmemopenx( buffer, -2, "r", &inner );
        fclosex( fp_ok, &inner );
        fclosex( fp_fail, &inner );
    }
    cexception_catch {
        fprintf( stderr, "%s: %s: %s - %s\n",
                 progname, "-", 
                 cexception_message( &inner ),
                 cexception_explanation( &inner ));
        exit(1);
    }

    return 0;
}
