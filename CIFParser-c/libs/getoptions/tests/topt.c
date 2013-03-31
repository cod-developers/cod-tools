/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <cexceptions.h>
#include <getoptions.h>

static option_function report_option;
static void usage(void);

static
struct options {
    option_value_t output_name;
    option_value_t flag;
    option_value_t int_value;
    option_value_t long_value;
    option_value_t float_value;
    option_value_t double_value;
    option_value_t int_array;
    option_value_t long_array;
    option_value_t float_array;
    option_value_t double_array;
} program_options;

static 
struct option_t options[] = {
  { "-b",  "--flag",      OT_BOOLEAN_TRUE,  &program_options.flag            },
  { "-b-", "--no-flag",   OT_BOOLEAN_FALSE, &program_options.flag            },
  { "-o",  "--output",    OT_STRING,        &program_options.output_name     },
  { "-i",  "--integer",   OT_INT,           &program_options.int_value       },
  { "-l",  "--long",      OT_LONG,          &program_options.long_value      },
  { "-f",  "--float",     OT_FLOAT,         &program_options.float_value     },
  { "-d",  "--double",    OT_DOUBLE,        &program_options.double_value    },
  { "-x",  "--function",  OT_FUNCTION,      NULL, report_option              },
  { "-I",  "--array-int", OT_INT_ARRAY,     &program_options.int_array       },
  { "-L",  "--array-lng", OT_LONG_ARRAY,    &program_options.long_array      },
  { "-F",  "--array-flt", OT_FLOAT_ARRAY,   &program_options.float_array     },
  { "-D",  "--array-dbl", OT_DOUBLE_ARRAY,  &program_options.double_array    },
  { NULL,  "--help",      OT_FUNCTION,      NULL, (option_function*)usage    },
  { NULL,  "--usage",     OT_FUNCTION,      NULL, (option_function*)usage    },
  { NULL, NULL, OT_NULL }
  /* option of the type OT_NULL marks the end of the options[] array */
};

static void show_options( struct options *options );
static void show_files( char *files[] );

int main( int argc, char *argv[] )
{
    cexception_t ex;
    char **files = NULL;

    cexception_guard( ex ) {
        files = get_optionsx( argc, argv, options, &ex );
    }
    cexception_catch {
        fprintf( stderr, "%s: %s\n", argv[0], cexception_message( &ex ));
	return cexception_error_code( &ex );
    }

    show_options( &program_options );
    show_files( files );

    return 0;
}

/*---------------------------------------------------------------------------*/

static void show_options( struct options *options )
{
    int i;

    puts( "" );
    printf( "--output  = '%s'\n",
	    options->output_name.value.s ?
	        options->output_name.value.s : "<null>" );

    printf( "--flag    = %s\n",  options->flag.value.b ? "TRUE" : "FALSE" );
    printf( "--integer = %d\n",  (int)options->int_value.value.i );
    printf( "--long    = %ld\n", options->long_value.value.i );
    printf( "--float   = %f\n",  (double)options->float_value.value.f );
    printf( "--double  = %g\n",  options->double_value.value.f );
    puts( "" );

    printf( "--array-int = " );
    for( i = 0; i < options->int_array.count; i++ )
        printf( " %d", (int)options->int_array.value.ai[i] );
    puts( "" );

    printf( "--array-lng = " );
    for( i = 0; i < options->long_array.count; i++ )
        printf( " %ld", options->long_array.value.ai[i] );
    puts( "" );

    printf( "--array-flt = " );
    for( i = 0; i < options->float_array.count; i++ )
        printf( " %5.2f ", options->float_array.value.af[i] );
    puts( "" );

    printf( "--array-lng = " );
    for( i = 0; i < options->double_array.count; i++ )
        printf( " %6.3f", options->double_array.value.af[i] );
    puts( "" );

    puts( "" );
}

static void show_files( char *files[] )
{
    printf( "Files: " );
    while( *files != NULL ) {
        printf( "%s ", *files++ );
    }
    puts( "" );
}

static void report_option( int argc, char **argv, int *i,
			   option_t *option, cexception_t *ex )
{
    if( strncmp( argv[*i], "--", 2 ) == 0 ) {
        printf( "option '%s' encountered\n", option->long_names );
    } else {
        printf( "option '%s' (%s) encountered\n",
		option->short_names,
		option->long_names );
    }
    /* (*i)++; */
}

static void usage(void)
{
    puts(
         "\n"
	 "test for get_optionsx function\n\n"
	 "usage:\n"
	 "    topt [option]\n\n"
	 "options:\n"
	 " --help, --usage    print short usage message and exit\n"
    );
    exit(0);
}
