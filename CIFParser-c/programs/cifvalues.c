
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <getoptions.h>
#include <cif_grammar_y.h>
#include <cif_grammar_flex.h>
#include <allocx.h>
#include <cxprintf.h>

static char *usage_text[2] = {

"Get specified data values from a CIF file(s)\n",

"Options:\n"

"  -t, --tag _cell_length_a,_cell_volume\n"
"      Extract the specified data items (no default)\n\n"

"  -s, --separator \" \"\n"
"      Use the specified string to separate values\n\n"

"  --vseparator \",\"\n"
"      Use the specified string to separate multiple values of a "
"give data item, from a loop\n\n"

"  --filename\n"
"      Print filename in the output (default)\n\n"

"  --no-filename\n"
"      Don't print file name in the output\n\n"

"  --dataname\n"
"      Print data block names in the output (default)\n\n"

"  --no-dataname\n"
"      Do not print data block names in the output\n\n"

"  -d, --debug\n"
"      Print internal program data structures for debugging\n\n"

"  -c, --compile-only\n"
"      Just check the input CIF syntax... \n\n"

"  -q, --quiet\n"
"      Be quiet, do not print reports on the processing\n\n"

"  -q-,--no-quiet, --vebose"
"      Be verbose, print report on the work progress to STDERR\n\n"

"  --help   print short usage message (this message) and exit\n"
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
  { NULL, "--help",         OT_FUNCTION,      NULL, &usage },
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
  print_filename.value.b = 0;
  print_dataname.value.b = 1;

  char ** taglist = NULL;
  int tagcount = 0;

  cexception_guard( inner ) {
      files = get_optionsx( argc, argv, options, &inner );
      char * tag_pointer = tags.value.s;
      char * end_pointer = strchr( tags.value.s, ',' );
      while( tag_pointer != NULL ) {
        tagcount++;
        int taglen;
        if( end_pointer != NULL ) {
            taglen = end_pointer - tag_pointer;
        } else {
            taglen = strchr( tag_pointer, '\0' ) - tag_pointer;
        }
        taglist = reallocx( taglist, sizeof( char * ) * tagcount, &inner );
        taglist[tagcount - 1] = mallocx( taglen * sizeof( char ), &inner );
        strncpy( taglist[tagcount - 1], tag_pointer, taglen );
        taglist[tagcount - 1][taglen] = '\0';
        if( end_pointer != NULL ) {
            tag_pointer = end_pointer + 1;
            end_pointer = strchr( tag_pointer, ',' );
        } else {
            tag_pointer = NULL;
        }
      }
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
          cif = new_cif_from_cif_file( files[i], NULL, &inner );

          if( cif && cif_nerrors( cif ) == 0 ) {
              if( debug.present && strstr(debug.value.s, "dump") != NULL ) {
                  cif_print( cif );
              } else {
                  cif_print_tag_values( cif, taglist, tagcount,
                      ( print_filename.value.b == 1 ? filename : "" ), 
                      print_dataname.value.b,
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
