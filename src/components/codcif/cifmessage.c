/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

/* exports: */
#include <cifmessage.h>

/* uses: */
#include <cexceptions.h>
#include <allocx.h>
#include <stringx.h>

struct CIFMESSAGE {
    int lineNo;
    int columnNo;
    char*  addPos; /* additional position -- e.g. a data block name */

    char* program;
    char* filename;
    char* status;
    char* message;
    char* explanation;
    char* msgSeparator; /* separator that was used between
                                   'message' and 'explanation'. */

    CIFMESSAGE *next;

};

CIFMESSAGE *new_cifmessage( CIFMESSAGE *next, cexception_t *ex )
{
    CIFMESSAGE *cm = callocx( sizeof(cm[0]), 1, ex );
    cm->next = next;
    return cm;
}

static char *strnulldupx( char *str, cexception_t *ex )
{
    if( str ) {
        return strdupx( str, ex );
    } else {
        return NULL;
    }
}

CIFMESSAGE *new_cifmessage_from_data( CIFMESSAGE *next,
                                      char *progname,
                                      char *filename,
                                      int line,
                                      int col,
                                      char *addPos,
                                      char *status,
                                      char *message,
                                      char *explanation,
                                      char *separator,
                                      cexception_t *ex )
{
    cexception_t inner;
    CIFMESSAGE * volatile cm = new_cifmessage( NULL, ex );

    cexception_guard( inner ) {
        cm->addPos = strnulldupx( addPos, &inner );
        cm->program = strnulldupx( progname, &inner );
        cm->filename = strnulldupx( filename, &inner );
        cm->status = strnulldupx( status, &inner );
        cm->message = strnulldupx( message, &inner );
        cm->explanation = strnulldupx( explanation, &inner );
        cm->msgSeparator = strnulldupx( separator, &inner );

        cm->lineNo = line;
        cm->columnNo = col;
    }
    cexception_catch {
        delete_cifmessage( cm );
        cexception_reraise( inner, ex );
    }
    cm->next = next;
    return cm;
}


void delete_cifmessage( CIFMESSAGE *cm )
{
    CIFMESSAGE *next;

    while( cm ) {
        freex( cm->addPos );
        freex( cm->program );
        freex( cm->filename );
        freex( cm->status );
        freex( cm->message );
        freex( cm->explanation );
        freex( cm->msgSeparator );

        next = cm->next;
        freex( cm );
        cm = next;
    }
}
