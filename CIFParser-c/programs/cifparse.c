
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <getoptions.h>
#include <cif_grammar_y.h>
#include <cif_grammar_flex.h>
#include <allocx.h>
#include <cxprintf.h>

static option_value_t verbose;
static option_value_t debug;
static option_value_t only_compile;

static option_t options[] = {
  { "-d", "--debug",        OT_STRING,        &debug },
  { "-c", "--compile-only", OT_BOOLEAN_TRUE,  &only_compile },
  { "-q", "--quiet",        OT_BOOLEAN_FALSE, &verbose },
  { "-q-","--no-quiet",     OT_BOOLEAN_TRUE,  &verbose },
  { NULL, "--vebose",       OT_BOOLEAN_TRUE,  &verbose },
  { NULL }
};

char *progname;

int main( int argc, char *argv[], char *env[] )
{
  cexception_t inner;
  char ** volatile files = NULL;
  CIF * volatile code = NULL;
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
      cexception_guard( inner ) {
          code = new_cif_from_cif_file( files[i], &inner );

          if( code ) {
              if( debug.present && strstr(debug.value.s, "dump") != NULL ) {
                  cif_print( code );
              } else {
                  printf( "%s: file '%s' OK\n", progname, files[i] ? files[i] : "-" );
              }
              delete_cif( code );
              code = NULL;
          }
      }
      cexception_catch {
          fprintf( stderr, "%s: %s\n", argv[0], cexception_message( &inner ));
          delete_cif( code );
          retval = 3;
          code = NULL;
      }
  }

  delete_cif( code );

  return retval;
}
