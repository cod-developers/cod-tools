/*---------------------------------------------------------------------------*\
** $Author$
** $Date$ 
** $Revision$
** $URL$
\*---------------------------------------------------------------------------*/

#ifndef _CEXCEPTIONS_H
#define _CEXCEPTIONS_H

#include <setjmp.h>

typedef struct cexception_s {
    int error_code;
    const void *subsystem_tag;
    const char *message;
    const char *source_file;
    int line;
    jmp_buf jmp_buffer;
} cexception_t;

#define NULL_EXCEPTION ((cexception_t*)0)

/*--------------------------------------------------------------------------*/

#define cexception_guard(EXCEPTION) \
   if( setjmp((EXCEPTION).jmp_buffer) == 0 )

#define cexception_catch  else

/*--------------------------------------------------------------------------*/

int cexception_init( cexception_t *cexception );

void cexception_raise_at( int line_nr, const char * filename,
			  cexception_t *cexception,
			  const void *sybsystem_tag,
			  int error_code,
			  const char *message );

#define cexception_raise( EXCEPTION, CODE, MESSAGE ) \
    cexception_raise_at( __LINE__, __FILE__, EXCEPTION, NULL, CODE, MESSAGE )

#define cexception_raise_in( EXCEPTION, SUBSYSTEM, CODE, MESSAGE ) \
    cexception_raise_at( __LINE__, __FILE__, EXCEPTION, \
			 SUBSYSTEM, CODE, MESSAGE )

#define cexception_finally( CLEAN, RERAISE ) \
    cexception_catch { \
        CLEAN \
        RERAISE  \
    } \
    CLEAN

#define cexception_finally3( PREPARE, CLEAN, RERAISE ) \
    cexception_catch { \
        PREPARE \
        CLEAN \
        RERAISE \
    } \
    CLEAN

void cexception_reraise( cexception_t old_cexception,
			 cexception_t *new_cexception );

/*--------------------------------------------------------------------------*/

const char *cexception_message( cexception_t *ex );
const void *cexception_subsystem_tag( cexception_t *ex );
const char *cexception_source_file( cexception_t *ex );
int cexception_error_code( cexception_t *ex );
int cexception_source_line( cexception_t *ex );

#endif
