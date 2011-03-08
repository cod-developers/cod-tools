/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#include <stdio.h> /* import sprintf() */
#include <string.h>
#include <ctype.h>
#include <assert.h>
#include <cexceptions.h>
#include <cxprintf.h>
#include <allocx.h>
#include <getoptions.h>

static option_t* find_option( option_t options[], char *arg,
			      cexception_t *ex );

static void get_string_value ( int argc, char **argv, int *i, option_t* option,
			       cexception_t* ex );

static void get_int_value    ( int argc, char **argv, int *i, option_t* option,
			       cexception_t* ex );

static void get_int_array    ( int argc, char **argv, int *i, option_t* option,
			       cexception_t* ex );

static void get_float_value  ( int argc, char **argv, int *i, option_t* option,
			       cexception_t* ex );

static void get_float_array  ( int argc, char **argv, int *i, option_t* option,
			       cexception_t* ex );


char **get_optionsx( int argc, char *argv[], option_t options[],
		     cexception_t *ex )
{
    cexception_t inner;
    int i, f;
    char **files;
    option_t *option;

    files = callocx( sizeof(*files), argc + 1, ex );

    cexception_guard( inner ) {
        for( i = 1, f = 0; i < argc; i++ ) {
	    if( strcmp( argv[i], "-" ) == 0 ) {
	        files[f++] = argv[i];
		continue;
	    }
	    if( strcmp( argv[i], "--" ) == 0 ) {
	        i++; while( i < argc ) files[f++] = argv[i++];
		break;
	    }
	    option = find_option( options, argv[i], &inner );
	    if( option == NULL ) {
	        files[f++] = argv[i];
	    } else {
		assert( option->option_type == OT_FUNCTION || option->data );
		if( option->data )
		    option->data->present = 1;
	        switch( option->option_type ) {
                    case OT_BOOLEAN_TRUE:
		        option->data->value.bool = 1;
		        break;
                    case OT_BOOLEAN_FALSE:
		        option->data->value.bool = 0;
		        break;
                    case OT_STRING:
		        get_string_value( argc, argv, &i, option, &inner );
		        break;
                    case OT_INT:
                    case OT_LONG:
		        get_int_value( argc, argv, &i, option, &inner );
		        break;
		    case OT_INT_ARRAY:
		    case OT_LONG_ARRAY:
		        get_int_array( argc, argv, &i, option, &inner );
		        break;
                    case OT_FLOAT:
                    case OT_DOUBLE:
		        get_float_value( argc, argv, &i, option, &inner );
		        break;
                    case OT_FLOAT_ARRAY:
                    case OT_DOUBLE_ARRAY:
		        get_float_array( argc, argv, &i, option, &inner );
		        break;
                    case OT_FUNCTION:
		        assert( option->proc );
		        option->proc( argc, argv, &i, option, &inner );
		        break;
	            default:
			break;
		}
	    }
	}
    }
    cexception_catch {
        free( files );
	cexception_reraise( inner, ex );
    }
    return files;
}

static  option_t* find_option( option_t options[], char *arg,
			       cexception_t *ex )
{
    int i, hit_count = 0;
    int found;

    for( i = 0; options[i].option_type != OT_NULL; i++ ) {
        if( ( options[i].short_names && 
	      strcmp( options[i].short_names, arg ) == 0 ) ||
	    ( options[i].long_names &&
	      strcmp( options[i].long_names, arg ) == 0 ))
	        return &options[i];
	if( options[i].long_names && 
	    strstr( options[i].long_names, arg ) == options[i].long_names ) {
	        hit_count++;
	        found = i;
	}
    }
    if( hit_count == 1 ) {
        return &options[found];
    } else if( hit_count > 1 ) {
        static char optnames[150];
	int pos = 0;
	for( i = 0; options[i].option_type != OT_NULL; i++ ) {
	  if( options[i].long_names &&
	      strstr( options[i].long_names, arg ) == options[i].long_names ) {
	    pos += sprintf( optnames + pos, "%s%s", pos == 0 ? "" : ", ",
			    options[i].long_names );
	    assert( pos < sizeof(optnames) );
	  }
	}
        cexception_raise( ex, GETOPTIONS_PREFIX_NOT_UNIQUE,
			  cxprintf( "option prefix '%s' is not unique:\n"
				    "possible options are %s",
				    arg, optnames ));
    } else {
        if( strncmp( "-", arg, 1 ) == 0 ) {
	    cexception_raise( ex, GETOPTIONS_NO_SUCH_OPTION,
			      cxprintf( "unknown option '%s'", arg ));
	}
    }
    return NULL;
}

#define check_argc( argc, i, option, argname, ex )\
    if( *i >= argc - 1 ) {\
        cexception_raise( ex, GETOPTIONS_OPTION_NEEDS_ARGUMENT,\
                          cxprintf( "option '%s' (%s) needs %s argument",\
				    option->short_names, option->long_names,\
				    argname ));\
    }


static void get_string_value( int argc, char **argv, int *i, option_t* option,
			      cexception_t* ex )
{
    check_argc( argc, i, option, "string", ex );
    assert( option->data );
    option->data->value.s = argv[++(*i)];
    option->data->present = 1;
}

static void get_int_value( int argc, char **argv, int *i, option_t* option,
			   cexception_t* ex )
{
    int processed = 0;
    char *string;

    check_argc( argc, i, option, "integer", ex );
    assert( option->data );

    string = argv[++(*i)];
    assert( string );

    while( isspace( *string )) string++;
    processed = sscanf( string, "%ld", &option->data->value.i );
    if( processed != 1 ) {
        cexception_raise( ex, GETOPTIONS_OPTION_NEEDS_INT_ARGUMENT,
			  cxprintf( "option '%s' (%s) argument "
				    "must be integer",
				    option->short_names,
				    option->long_names ));
    }
    option->data->present = 1;
}

static void get_int_array( int argc, char **argv, int *i, option_t* option,
			   cexception_t *ex )
{
    int j;
    char *string;
    int processed = 0;

    check_argc( argc, i, option, "integer", ex );
    assert( option->data );

    string = argv[++(*i)];
    assert( string );

    while( isspace( *string )) string++;
    for( j = 0; *string != '\0'; j++ ) {
        option->data->value.ai = 
            reallocx( option->data->value.ai,
		      sizeof(option->data->value.ai[0]) * (j+1), ex );
        processed = sscanf( string, "%ld", &option->data->value.ai[j] );
        if( processed != 1 ) {
	    cexception_raise( ex, GETOPTIONS_OPTION_NEEDS_INT_ARGUMENT,
			      cxprintf( "option '%s' (%s) argument "
					"must be one or several integers",
					option->short_names,
					option->long_names ));
	}
	while( !isspace( *string ) && *string ) string++;
	while(  isspace( *string ) && *string ) string++;
    }
    option->data->count = j;
    option->data->present = 1;
}

static void get_float_value( int argc, char **argv, int *i, option_t* option,
			     cexception_t* ex )
{
    int processed = 0;
    char *string;
    float tmp_float;

    check_argc( argc, i, option, "numeric", ex );
    assert( option->data );

    string = argv[++(*i)];
    assert( string );
    
    while( isspace( *string )) string++;
    processed = sscanf( string, "%f", &tmp_float );
    if( processed != 1 ) {
        cexception_raise( ex, GETOPTIONS_OPTION_NEEDS_FLOAT_ARGUMENT,
			  cxprintf( "option '%s' (%s) argument "
				    "must be numeric",
				    option->short_names,
				    option->long_names ));
    }
    option->data->value.f = tmp_float;
    option->data->present = 1;
}

static void get_float_array( int argc, char **argv, int *i, option_t* option,
			     cexception_t *ex )
{
    int j;
    int processed = 0;
    char *string;
    float tmp;

    check_argc( argc, i, option, "numeric", ex );
    assert( option->data );

    string = argv[++(*i)];
    assert( string );

    while( isspace( *string )) string++;
    for( j = 0; *string != '\0'; j++ ) {
        option->data->value.af =
	    reallocx( option->data->value.af,
		      sizeof(option->data->value.af[0]) * (j+1), ex );
	processed = sscanf( string, "%f", &tmp );
	option->data->value.af[j] = tmp;
        if( processed != 1 ) {
	    cexception_raise( ex, GETOPTIONS_OPTION_NEEDS_FLOAT_ARGUMENT,
			      cxprintf( "option '%s' (%s) argument "
					"must be one or several numbers",
					option->short_names,
					option->long_names ));
	}
	while( !isspace( *string ) && *string ) string++;
	while(  isspace( *string ) && *string ) string++;
    }
    option->data->count = j;
    option->data->present = 1;
}
