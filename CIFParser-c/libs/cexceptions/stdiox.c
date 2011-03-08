/*---------------------------------------------------------------------------*\
** $Author$
** $Date$ 
** $Revision$
** $URL$
\*---------------------------------------------------------------------------*/

/* exports: */
#include <stdiox.h>

/* uses: */
#include <cexceptions.h>
#include <cxprintf.h>
#include <errno.h>
#include <string.h>

void *stdiox_subsystem = &stdiox_subsystem;

FILE *fopenx( const char *filename, const char *mode, cexception_t *ex )
{
    FILE *f = fopen( filename, mode );

    if( f == NULL ) {
        cexception_raise_in( ex, stdiox_subsystem, STDIOX_FILE_OPEN_ERROR,
			     cxprintf( "could not open file '%s': %s",
				       filename, strerror( errno )));
    }

    return f;
}

void fclosex( FILE *file, cexception_t *ex )
{
    if( fclose( file ) != 0 ) {
        cexception_raise_in( ex, stdiox_subsystem, STDIOX_FILE_CLOSE_ERROR,
			     cxprintf( "could not close file: %s",
				       strerror( errno )));
    }
}
