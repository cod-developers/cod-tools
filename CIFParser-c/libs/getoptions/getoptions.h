/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#ifndef __GETOPTIONS_H
#define __GETOPTIONS_H

/* process options and arguments on the command line */

#include <cexceptions.h>

typedef enum {
    OT_NULL,
    OT_BOOLEAN_TRUE,
    OT_BOOLEAN_FALSE,
    OT_STRING,
    OT_INT,
    OT_LONG,
    OT_FLOAT,
    OT_DOUBLE,
    OT_INT_ARRAY,
    OT_LONG_ARRAY,
    OT_FLOAT_ARRAY,
    OT_DOUBLE_ARRAY,
    OT_FUNCTION,
    OT_last
} option_type_t;

typedef struct option_value_t {
    int present;
    int count;
    union {
        char b; /* Byte or boolean */
        long i;
        double f;    
        char *s;
        long *ai;
        double *af;
    } value;
} option_value_t;

typedef struct option_t option_t;

typedef void (option_function) (int argc, char *argv[], int *i,
				option_t*, cexception_t* );

struct option_t {
    char *short_names;
    char *long_names;
    option_type_t option_type;
    option_value_t *data;
    option_function *proc;
};

char ** get_options( int argc, char *argv[], option_t options[] );
char ** get_optionsx( int argc, char *argv[], option_t options[],
		      cexception_t *ex );

void delete_getoptions_file_list( char** files );

typedef enum {
    GETOPTIONS_OK,
    GETOPTIONS_NO_SUCH_OPTION,
    GETOPTIONS_PREFIX_NOT_UNIQUE,
    GETOPTIONS_OPTION_NEEDS_ARGUMENT,
    GETOPTIONS_OPTION_NEEDS_INT_ARGUMENT,
    GETOPTIONS_OPTION_NEEDS_FLOAT_ARGUMENT,

    GETOPTIONS_NOT_ENOUGH_MEMORY = 99,

    GETOPTIONS_USER_ERROR,
    GETOPTIONS_last
} GETOPTIONS_ERRORS;

#endif
