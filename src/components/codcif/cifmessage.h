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
    for( (CM) = (LIST); (CM) != NULL; (CM) = cifmessage_next(LIST) )

#endif
