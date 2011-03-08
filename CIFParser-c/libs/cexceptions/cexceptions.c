/*---------------------------------------------------------------------------*\
** $Author$
** $Date$ 
** $Revision$
** $URL$
\*---------------------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <cexceptions.h>

int cexception_init( cexception_t *ex )
{
    assert( ex );
    memset( ex, 0, sizeof(*ex));
    return 1;
}

void cexception_raise_at( int line_nr, const char * filename,
			  cexception_t *cexception,
			  const void *subsystem_tag,
			  int error_code,
			  const char *message )
{
    if( cexception ) {
        cexception->message = message;
	cexception->subsystem_tag = subsystem_tag;
	cexception->error_code = error_code;
	cexception->source_file = filename;
	cexception->line = line_nr;
	longjmp( cexception->jmp_buffer, error_code );
    } else {
        fputs( message, stderr );
        fputc( '\n', stderr );
	exit( error_code );
    }
}

void cexception_reraise( cexception_t old_cexception,
			 cexception_t *new_cexception )
{
    if( new_cexception ) {
        new_cexception->message = old_cexception.message;
	new_cexception->subsystem_tag = old_cexception.subsystem_tag;
	new_cexception->error_code = old_cexception.error_code;
	new_cexception->source_file = old_cexception.source_file;
	new_cexception->line = old_cexception.line;
	longjmp( new_cexception->jmp_buffer, new_cexception->error_code );
    } else {
        fputs( old_cexception.message, stderr );
        fputc( '\n', stderr );
	exit( old_cexception.error_code );
    }
}

const char *cexception_message( cexception_t *ex )
{
    assert( ex );
    return ex->message;
}

int cexception_error_code( cexception_t *ex )
{
    assert( ex );
    return ex->error_code;
}

const void* cexception_subsystem_tag( cexception_t *ex )
{
    assert( ex );
    return ex->subsystem_tag;
}

const char *cexception_source_file( cexception_t *ex )
{
    assert( ex );
    return ex->source_file;
}

int cexception_source_line( cexception_t *ex )
{
    assert( ex );
    return ex->line;
}
