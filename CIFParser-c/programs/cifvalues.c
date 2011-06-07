
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <getoptions.h>
#include <cif_grammar_y.h>
#include <cif_grammar_flex.h>
#include <allocx.h>
#include <cxprintf.h>

static option_value_t tags;
static option_value_t separator;
static option_value_t vseparator;
static option_value_t print_filename;
static option_value_t print_dataname;
static option_value_t verbose;
static option_value_t debug;
static option_value_t only_compile;

static option_t options[] = {
  { "-t", "--tag",          OT_STRING,        &tags },
  { "-s", "--separator",    OT_STRING,        &separator },
  { NULL, "--vseparator",   OT_STRING,        &vseparator },
  { NULL, "--filename",     OT_BOOLEAN_TRUE,  &print_filename },
  { NULL, "--no-filename",  OT_BOOLEAN_FALSE, &print_filename },
  { NULL, "--dataname",     OT_BOOLEAN_TRUE,  &print_dataname },
  { NULL, "--no-dataname",  OT_BOOLEAN_FALSE, &print_dataname },
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
  CIF * volatile cif = NULL;
  int retval = 0;
  int i;

  progname = argv[0];

  tags.value.s = "";
  separator.value.s = " ";
  vseparator.value.s = ",";
  print_filename.value.bool = 0;
  print_dataname.value.bool = 1;

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
          cif = new_cif_from_cif_file( files[i], &inner );

          if( cif && cif_nerrors( cif ) == 0 ) {
              if( debug.present && strstr(debug.value.s, "dump") != NULL ) {
                  cif_print( cif );
              } else {
                  cif_print_tag_values( cif, tags.value.s,
                      ( print_filename.value.bool == 1 ? filename : "" ), 
                      print_dataname.value.bool,
                      separator.value.s, vseparator.value.s );
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

  return retval;
}
