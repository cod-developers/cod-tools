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
#include <cif_grammar_y.h>
#include <cif_grammar_flex.h>
#include <allocx.h>
#include <cxprintf.h>

static char *source_URL = "$URL$";

static char *usage_text[2] = {

"Parse CIF file(s), check syntax, and optionally output pretty-printed data\n",

"Options:\n"

"  -c, --compile-only\n"
"      Only compile the CIF (check syntax). Prints out file name and\n"
"      'OK' or 'FAILED' to STDOUT, along with error messages to STDERR\n\n"

"  -f, --fix-syntax\n"
"      Attempt to fix some errors in inputs CIFs, such as missing data_\n"
"      headers or unterminated quoted strings\n\n"

"  -p, --print\n"
"      Print out data in CIF format (a kind of CIF pretty-printer ;)\n\n"

"  -d, --debug lex,yacc\n"
"      Specify one or several (comma-separated) debgging options.\n\n"
"      Currently supported options are:\n"
"          dump   -- dump internal data structures for inspection\n"
"          lex    -- switch on (F)LEX token printout\n"
"          yacc   -- ask YACC/BISON to tell us which rules they reduce\n"
"          yylval -- print out YACC/BISON's yylval\n"
"          text   -- dump the percieved input file text\n"
"          code   -- dump intermediate CIF code representation\n"
"\n"

"  -q, --quiet                 Be quiet, only output error messages and data\n"

"  -q-, --no-quiet, --verbose  Produce verbose output of the parsing process\n\n"

"  --version  print program version (SVN Id) and exit\n"

"  --help     print short usage message (this message) and exit\n"
};

static void usage( int argc, char *argv[], int *i, option_t *option,
		   cexception_t * ex )
{
    puts( usage_text[0] );
    puts( "Usage:" );
    printf( "   %s --options < input.cif\n", argv[0] );
    printf( "   %s --options input.cif\n", argv[0] );
    printf( "   %s --options input1.cif input2.cif inputs*.cif\n\n", argv[0] );
    puts( usage_text[1] );
    exit( 0 );
};

static void version( int argc, char *argv[], int *i, option_t *option,
                     cexception_t * ex )
{
    printf( "%s svnversion %s\n", argv[0], SVN_VERSION );
    printf( "%s\n", source_URL );
    exit( 0 );
}

static option_value_t fix_errors;
static option_value_t verbose;
static option_value_t debug;
static option_value_t print_cif;

static option_t options[] = {
  { "-d", "--debug",           OT_STRING,         &debug },
  { "-f", "--fix-syntax",      OT_BOOLEAN_TRUE,   &fix_errors },
  { "-f-","--dont-fix-syntax", OT_BOOLEAN_FALSE,  &fix_errors },
  { "-c", "--compile-only",    OT_BOOLEAN_FALSE,  &print_cif },
  { "-p", "--print",           OT_BOOLEAN_TRUE,   &print_cif },
  { "-q", "--quiet",           OT_BOOLEAN_FALSE,  &verbose },
  { "-q-","--no-quiet",        OT_BOOLEAN_TRUE,   &verbose },
  { NULL, "--vebose",          OT_BOOLEAN_TRUE,   &verbose },
  { NULL, "--help",            OT_FUNCTION, NULL, &usage },
  { NULL, "--version",         OT_FUNCTION, NULL, &version },
  { NULL }
};

char *progname;

int main( int argc, char *argv[], char *env[] )
{
  cexception_t inner;
  char ** volatile files = NULL;
  CIF * volatile cif = NULL;
  COMPILER_OPTIONS * volatile compiler_options = NULL;
  int retval = 0;
  int i;

  progname = argv[0];

  cexception_guard( inner ) {
      files = get_optionsx( argc, argv, options, &inner );
  }
  cexception_catch {
      fprintf( stderr, "%s: %s\n", argv[0], cexception_message( &inner ));
      exit(1);
  }

  if( files[0] == NULL && isatty(0) && isatty(1) ) {
      fprintf( stderr, "%s: Usage: %s data.cif\n", argv[0], argv[0] );
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

          if( fix_errors.value.b == 1 ) {
              compiler_options = new_compiler_options( &inner );
              set_fix_errors( compiler_options );
          }

          cif = new_cif_from_cif_file( files[i], compiler_options, &inner );

          if( cif && cif_nerrors( cif ) == 0 ) {
              if( debug.present && strstr(debug.value.s, "dump") != NULL ) {
                  cif_dump( cif );
              } else {
                  if( print_cif.value.b == 1 ) {
                      cif_print( cif );
                  } else {
                      printf( "%s: file '%s' OK\n", progname, filename );
                  }
              }
              delete_cif( cif );
              cif = NULL;
              filename = NULL;
          } else {
              if( print_cif.value.b == 0 ) {
                  printf( "%s: file '%s' FAILED\n", progname, filename );
              }
          }
      }
      cexception_catch {
          if( filename ) {
              if( print_cif.value.b == 0 ) {
                  printf( "%s: file '%s' FAILED\n", progname, filename );
              }
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

  return retval;
}
