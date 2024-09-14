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
#include <assert.h>

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

    char *line; /* A copy of the file line where the error occurred. */

    CIFMESSAGE *next;

};

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
        freex( cm->line );

        next = cm->next;
        freex( cm );
        cm = next;
    }
}

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

CIFMESSAGE *cifmessage_next( CIFMESSAGE *cm )
{
    assert( cm );
    return cm->next;
}

char* cifmessage_addpos( CIFMESSAGE *cm )
{
    assert( cm );
    return cm->addPos;
}

char* cifmessage_program( CIFMESSAGE *cm )
{
    assert( cm );
    return cm->program;
}

char* cifmessage_filename( CIFMESSAGE *cm )
{
    assert( cm );
    return cm->filename;
}

int cifmessage_lineno( CIFMESSAGE *cm )
{
    assert( cm );
    return cm->lineNo;
}

int cifmessage_pos( CIFMESSAGE *cm )
{
    assert( cm );
    return cm->columnNo;
}

int cifmessage_columnno( CIFMESSAGE *cm )
{
    assert( cm );
    return cm->columnNo;
}

char* cifmessage_message( CIFMESSAGE *cm )
{
    assert( cm );
    return cm->message;
}

char* cifmessage_explanation( CIFMESSAGE *cm )
{
    assert( cm );
    return cm->explanation;
}

char* cifmessage_msgseparator( CIFMESSAGE *cm )
{
    assert( cm );
    return cm->msgSeparator;
}

char* cifmessage_status( CIFMESSAGE *cm )
{
    assert( cm );
    return cm->status;
}

char* cifmessage_line( CIFMESSAGE *cm )
{
    assert( cm );
    return cm->line;
}

void cifmessage_set_line( CIFMESSAGE *cm, char *line, cexception_t *ex )
{
    assert( cm );
    if( cm->line ) {
        freex( cm->line );
        cm->line = NULL;
    }
    if( line ) {
        cm->line = strdupx( line, ex );
    }
}

CIFMESSAGE *cifmessage_revert_list( CIFMESSAGE *msglist  )
{
    CIFMESSAGE *newlist = NULL;

    while( msglist ) {
        CIFMESSAGE *next = msglist->next;
        msglist->next = newlist;
        newlist = msglist;
        msglist = next;
    }

    return newlist;
}
