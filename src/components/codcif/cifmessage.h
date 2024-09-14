/*---------------------------------------------------------------------------*\
**$Author$
**$Date$
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#ifndef __CIFMESSAGE_H
#define __CIFMESSAGE_H

#include <cexceptions.h>

typedef struct CIFMESSAGE CIFMESSAGE;

void delete_cifmessage( CIFMESSAGE *cm );

CIFMESSAGE *new_cifmessage( CIFMESSAGE *next, cexception_t *ex );

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
                                      cexception_t *ex );

CIFMESSAGE *cifmessage_next( CIFMESSAGE *cm );

#define foreach_cifmessage( CM, LIST ) \
    for( (CM) = (LIST); (CM) != NULL; (CM) = cifmessage_next(CM) )

char* cifmessage_addpos( CIFMESSAGE *cm );
char* cifmessage_program( CIFMESSAGE *cm );
char* cifmessage_filename( CIFMESSAGE *cm );
int cifmessage_lineno( CIFMESSAGE *cm );
int cifmessage_pos( CIFMESSAGE *cm );
int cifmessage_columnno( CIFMESSAGE *cm );
char* cifmessage_message( CIFMESSAGE *cm );
char* cifmessage_explanation( CIFMESSAGE *cm );
char* cifmessage_msgseparator( CIFMESSAGE *cm );
char* cifmessage_status( CIFMESSAGE *cm );
char* cifmessage_line( CIFMESSAGE *cm );

void cifmessage_set_line( CIFMESSAGE *cm, char *line, cexception_t *ex );

CIFMESSAGE *cifmessage_revert_list( CIFMESSAGE *msglist  );

#endif
