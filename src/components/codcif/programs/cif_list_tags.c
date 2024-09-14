/*---------------------------------------------------------------------------*\
**$Author$
**$Date$
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

/* uses: */

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <getoptions.h>
#include <cif_compiler.h>
#include <cif_grammar_y.h>
#include <cif_grammar_flex.h>
#include <allocx.h>
#include <version.h>

static char *source_URL = "$URL$";

static char *usage_text[2] = {

" Parse CIF file(s) and output a list of CIF data items.\n",

" OPTIONS:\n"

"   --datablock-name, --dataname\n"
"                     Print data block names in the output (default).\n"
"   --no-datablock-name, --no-dataname\n"
"                     Do not print data block names in the output.\n\n"

"   -c, --compile-only\n"
"                     Only compile the CIF (check syntax). Prints out\n"
"                     the filename and 'OK' or 'FAILED' to STDOUT, along\n"
"                     with error messages to STDERR.\n\n"

"   -q, --quiet\n"
"                     Be quiet, only output error messages and data.\n"
"   -q-, --no-quiet, --verbose\n"
"                     Produce verbose output of the parsing process.\n\n"

"   -r, --record-separator $'\\n'\n"
"       --separator        $'\\n'\n"
"                     Use the specified string to separate values\n"
"                     of different data items (default \" \").\n\n"

"   -d, --debug\n"
"                     Print internal program data structures for debugging.\n\n"

"   --version\n"
"                     Print program version (SVN Id) and exit.\n"
"   --help\n"
"                     Print short usage message (this message) and exit.\n"
};

static void usage( int argc, char *argv[], int *i, option_t *option,
                   cexception_t * ex )
{
    puts( usage_text[0] );
    puts( " USAGE:" );
    printf( "   %s --options < input.cif\n", argv[0] );
    printf( "   %s --options input.cif\n", argv[0] );
    printf( "   %s --options input1.cif input2.cif inputs*.cif\n\n", argv[0] );
    puts( usage_text[1] );
    exit( 0 );
};

static void version( int argc, char *argv[], int *i, option_t *option,
                     cexception_t * ex )
{
    printf( "%s version %s svn revision %s\n", argv[0], VERSION, SVN_VERSION );
    printf( "%s\n", source_URL );
    exit( 0 );
}

static option_value_t separator;
static option_value_t verbose;
static option_value_t debug;
static option_value_t only_compile;
static option_value_t print_dataname;

static option_t options[] = {
  { NULL, "--dataname",          OT_BOOLEAN_TRUE,   &print_dataname },
  { NULL, "--no-dataname",       OT_BOOLEAN_FALSE,  &print_dataname },
  { NULL, "--datablock-name",    OT_BOOLEAN_TRUE,   &print_dataname },
  { NULL, "--no-datablock-name", OT_BOOLEAN_FALSE,  &print_dataname },
  { "-d", "--debug",             OT_STRING,         &debug },
  { "-c", "--compile-only",      OT_BOOLEAN_TRUE,   &only_compile },
  { "-q", "--quiet",             OT_BOOLEAN_FALSE,  &verbose },
  { "-q-","--no-quiet",          OT_BOOLEAN_TRUE,   &verbose },
  { "-r", "--record-separator",  OT_STRING,         &separator },
  { NULL, "--separator",         OT_STRING,         &separator },
  { NULL, "--verbose",           OT_BOOLEAN_TRUE,   &verbose },
  { NULL, "--help",              OT_FUNCTION, NULL, &usage },
  { NULL, "--version",           OT_FUNCTION, NULL, &version },
  { NULL }
};

char *progname;

int main( int argc, char *argv[], char *env[] )
{
  cexception_t inner;
  char ** volatile files = NULL;
  CIF * volatile cif = NULL;
  int retval = 0;
  int i;

  separator.value.s = "\n";
  print_dataname.value.b = 1;
  
  progname = argv[0];

  cexception_guard( inner ) {
      files = get_optionsx( argc, argv, options, &inner );
  }
  cexception_catch {
      fprintf( stderr, "%s: %s\n", argv[0], cexception_message( &inner ));
      exit(1);
  }

  if( files[0] == NULL && isatty(0) && isatty(1) ) {
      fprintf( stderr, "%s: USAGE: %s data.cif\n", argv[0], argv[0] );
      exit(2);
  }

  cif_yy_debug_off();
  cif_flex_debug_off();
  cif_debug_off();
  if( debug.present ) {
      if( strstr(debug.value.s, "lex") != NULL ) cif_flex_debug_yyflex();
      if( strstr(debug.value.s, "yacc") != NULL ) cif_yy_debug_on();
      if( strstr(debug.value.s, "yylval") != NULL ) cif_flex_debug_yylval();
      if( strstr(debug.value.s, "text") != NULL ) cif_flex_debug_yytext();
      if( strstr(debug.value.s, "code") != NULL ) {
          cif_flex_debug_lines();
          cif_debug_on();
      }
  }

  for( i = 0; i == 0 || files[i] != NULL; i++ ) {
      char * volatile filename = NULL;
      cexception_guard( inner ) {
          filename = files[i] ? files[i] : "-";
          cif = new_cif_from_cif_file( files[i], cif_option_default(),
                                       &inner );

          if( cif && cif_nerrors( cif ) == 0 ) {
              if( debug.present && strstr(debug.value.s, "dump") != NULL ) {
                  cif_print( cif );
              } else {
                  cif_list_tags( cif, separator.value.s,
                                 print_dataname.value.b );
              }
              delete_cif( cif );
              cif = NULL;
              filename = NULL;
          }
      }
      cexception_catch {
          if( filename ) {
              fprintf( stderr, "%s: %s: %s\n", argv[0], filename, cexception_message( &inner ));
          } else {
              fprintf( stderr, "%s: %s\n", argv[0], cexception_message( &inner ));
          }
          delete_cif( cif );
          retval = 3;
          cif = NULL;
      }
  }

  delete_cif( cif );
  freex( files );

  return retval;
}
