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
#include <ctype.h> /* for 'tolower()' */
#include <getoptions.h>
#include <cif_compiler.h>
#include <cif_grammar_y.h>
#include <cif_grammar_flex.h>
#include <allocx.h>
#include <version.h>

static char *source_URL = "$URL$";

static char *usage_text[2] = {

" Get specified data values from a CIF file(s).\n",

" OPTIONS:\n"

"   -h, --header, -h-, --no-header\n"
"                     Print/do not print (default) the column name header\n\n"

"   -t, --tags _cell_length_a,_cell_volume\n"
"                     Extract the specified data items (no default).\n\n"

"   -g, --group-separator    $'\\n'\n"
"       --newline-characters $'\\n'\n"
"                     Specify a group separator that separates "
                     "TSV/CSV/ADT \"lines\" (default \"\\n\")\n\n"

"   -r, --record-separator $'\\t'\n"
"       --separator        $'\\t'\n"
"                     Use the specified string to separate values\n"
"                     of different data items (default \" \").\n\n"

"   -u, --unit-separator  \"|\"\n"
"       --value-separator \"|\"\n"
"       --vseparator      \"|\"\n"
"                     Use the specified string to separate multiple\n"
"                     values of each looped data item (default \"|\").\n\n"

"   -p, --replacement  \" \"\n"
"                     A character to which all separators are replaced\n"
"                     in the non-quoting output formats (TSV and ADT).\n\n"

"   -q, --quote  '\"'\n"
"                     Quote the strings containing separators using the\n"
"                     specified quoting character (default for CSV output).\n"

"   -q-,--no-quote\n"
"                     Do not quote the strings containing separators,\n"
"                     replace separators by the --replacement character.\n\n"

"   -Q, --always-quote\n"
"                     Always quote the values even if they do not contain separators\n"

"   -Q-,--not-always-quote\n"
"                     Quote the values only if they contain separators (default)\n"

"   -D, --dos-newlines\n"
"   -M, --mac-newlines\n"
"   -U, --unix-newlines\n"
"                     Set new line convention to DOS, MAC or Unix (default)\n"
"                     Same as --group-separator with an appropriate string\n\n"
"                     (e.g. --dos-newlines in bash is"
                    " --group-sep $'\\r'$'\\n')\n\n"

"   --tsv-output, --csv-output, --adt-output\n"
"                     Set separators for the TSV, CSV or\n"
"                     ADT (ASCII delimited, using ASCII GS, RS and US chars)\n"
"                     output. Default is TSV output.\n"

"   --filename\n"
"                     Print filename in the output.\n"
"   --no-filename\n"
"                     Don't print filename in the output (default).\n\n"

"   --datablock-name, --dataname\n"
"                     Print data block names in the output (default).\n"
"   --no-datablock-name, --no-dataname\n"
"                     Do not print data block names in the output.\n\n"

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

static option_value_t header;
static option_value_t tags;
static option_value_t quote;
static option_value_t always_quote;
static option_value_t group_separator;
static option_value_t separator;
static option_value_t vseparator;
static option_value_t replacement;
static option_value_t print_filename;
static option_value_t print_dataname;
static option_value_t debug;

static void set_adt_delimiters( int argc, char *argv[], int *i,
                                option_t *option, cexception_t * ex )
{
    group_separator.value.s = "\035"; // ASCII: GS, Group Separator
    separator.value.s       = "\036"; // ASCII: RS, Record Separator
    vseparator.value.s      = "\037"; // ASCII: US, Unit Separator
    quote.value.s = "";
}

static void set_tsv_delimiters( int argc, char *argv[], int *i,
                                option_t *option, cexception_t * ex )
{
    group_separator.value.s = "\n"; // ASCII: GS, Group Separator
    separator.value.s       = "\t"; // ASCII: RS, Record Separator
    vseparator.value.s      = "\037"; // ASCII: US, Unit Separator
    quote.value.s = "";
}

static void set_csv_delimiters( int argc, char *argv[], int *i,
                                option_t *option, cexception_t * ex )
{
    group_separator.value.s = "\n";
    separator.value.s       = ",";
    vseparator.value.s      = "|";
    quote.value.s           = "\"";
}

static void set_no_quote( int argc, char *argv[], int *i,
                          option_t *option, cexception_t * ex )
{
    quote.value.s = "";
}

static void set_unix_newlines( int argc, char *argv[], int *i,
                               option_t *option, cexception_t * ex )
{
    group_separator.value.s = "\n";
}

static void set_dos_newlines( int argc, char *argv[], int *i,
                              option_t *option, cexception_t * ex )
{
    group_separator.value.s = "\r\n";
}

static void set_mac_newlines( int argc, char *argv[], int *i,
                              option_t *option, cexception_t * ex )
{
    group_separator.value.s = "\r";
}

static option_t options[] = {
  { "-h", "--header",             OT_BOOLEAN_TRUE,  &header },
  { "-h-","--no-header",          OT_BOOLEAN_FALSE, &header },
  { "-t", "--tags",               OT_STRING,        &tags },
  { "-g", "--group-separator",    OT_STRING,        &group_separator },
  { NULL, "--newline-characters", OT_STRING,        &group_separator },
  { "-r", "--record-separator",   OT_STRING,        &separator },
  { NULL, "--separator",          OT_STRING,        &separator },
  { "-u", "--unit-separator",     OT_STRING,        &vseparator },
  { NULL, "--value-separator",    OT_STRING,        &vseparator },
  { NULL, "--vseparator",         OT_STRING,        &vseparator },
  { "-p", "--replacement",        OT_STRING,        &replacement },
  { "-q", "--quote",              OT_STRING,        &quote },
  { "-q-","--no-quote",           OT_FUNCTION,      NULL, &set_no_quote },
  { "-Q", "--always-quote",       OT_BOOLEAN_TRUE,  &always_quote },
  { "-Q-","--not-always-quote",   OT_BOOLEAN_FALSE, &always_quote },
  { "-U", "--unix-newlines",      OT_FUNCTION,      NULL, &set_unix_newlines },
  { "-D", "--dos-newlines",       OT_FUNCTION,      NULL, &set_dos_newlines },
  { "-M", "--mac-newlines",       OT_FUNCTION,      NULL, &set_mac_newlines },
  { NULL, "--filename",           OT_BOOLEAN_TRUE,  &print_filename },
  { NULL, "--no-filename",        OT_BOOLEAN_FALSE, &print_filename },
  { NULL, "--dataname",           OT_BOOLEAN_TRUE,  &print_dataname },
  { NULL, "--no-dataname",        OT_BOOLEAN_FALSE, &print_dataname },
  { NULL, "--datablock-name",     OT_BOOLEAN_TRUE,  &print_dataname },
  { NULL, "--no-datablock-name",  OT_BOOLEAN_FALSE, &print_dataname },
  { NULL, "--adt-output",         OT_FUNCTION,      NULL, &set_adt_delimiters },
  { NULL, "--tsv-output",         OT_FUNCTION,      NULL, &set_tsv_delimiters },
  { NULL, "--csv-output",         OT_FUNCTION,      NULL, &set_csv_delimiters },
  { "-d", "--debug",              OT_STRING,        &debug },
  { NULL, "--help",               OT_FUNCTION,      NULL, &usage },
  { NULL, "--version",            OT_FUNCTION,      NULL, &version },
  { NULL }
};

static void
check_zero_delimiters_and_exit_if_found( char *progname )
{
    int has_error = 0;
    
    if( !group_separator.value.s || *group_separator.value.s == '\0' ) {
        has_error = 1;
        fprintf( stderr, "%s: %s\n", progname,
                 "ERROR, group separator (--group-sep) "
                 "should be a non-empty string");
        
    }

    if( !separator.value.s || *separator.value.s == '\0' ) {
        has_error = 1;
        fprintf( stderr, "%s: %s\n", progname,
                 "ERROR, record separator (--separator) "
                 "should be a non-empty string");
        
    }

    if( !vseparator.value.s || *vseparator.value.s == '\0' ) {
        has_error = 1;
        fprintf( stderr, "%s: %s\n", progname,
                 "ERROR, value (unit) separator (--vseparator) "
                 "should be a non-empty string");
        
    }

    if( has_error ) {
        exit(3);
    }
}

/* Adding some syntactic sugar for readability, to shorten a very long
   function call: */

#define PRINT_QUOTED_OR_DELIMITED(VALUE)                       \
    print_quoted_or_delimited_value                            \
    ( (VALUE), group_separator.value.s, separator.value.s,     \
      vseparator.value.s, replacement.value.s,                 \
      *quote.value.s, always_quote.value.b )

char *progname;

int main( int argc, char *argv[], char *env[] )
{
  cexception_t inner;
  char ** volatile files = NULL;
  CIF * volatile cif = NULL;
  int retval = 0;
  int i;

  progname = argv[0];

  quote.value.s = "";
  always_quote.value.b = 0;
  header.value.b = 0; /* Do NOT print the header by default.*/
  tags.value.s = "";
  group_separator.value.s = "\n"; /*ASCII: GS, group separator*/
  separator.value.s = "\t";       /*ASCII: RS, record separator*/
  vseparator.value.s = "|";       /*ASCII: US, unit separator*/
  replacement.value.s = " ";
  print_filename.value.b = 0;
  print_dataname.value.b = 1;

  char ** taglist = NULL;
  int tagcount = 0;

  cexception_guard( inner ) {
      files = get_optionsx( argc, argv, options, &inner );
      char * tag_pointer = tags.value.s;
      char * end_pointer = strchr( tags.value.s, ',' );

      while( tag_pointer != NULL && *tag_pointer != '\0' ) {
        tagcount++;
        int taglen;
        if( end_pointer != NULL ) {
            taglen = end_pointer - tag_pointer;
        } else {
            taglen = strchr( tag_pointer, '\0' ) - tag_pointer;
        }
        taglist = reallocx( taglist, sizeof( char * ) * tagcount, &inner );
        taglist[tagcount - 1] = mallocx( taglen * sizeof( char ) + 1, &inner );
        strncpy( taglist[tagcount - 1], tag_pointer, taglen );
        int i;
        for( i = 0; i < taglen; i++ ) {
            taglist[tagcount - 1][i] = tolower( taglist[tagcount - 1][i] );
        }
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

  if( quote.value.s && strlen( quote.value.s ) > 1 ) {
      fprintf( stderr, "%s: ERROR, the quote character must be a single "
               "ASCII character (one byte), but '%s' is specified\n",
               argv[0], quote.value.s );
      exit(2);      
  }

  check_zero_delimiters_and_exit_if_found( progname );

  if( files[0] == NULL && isatty(0) ) {
      fprintf( stderr, "%s: WARNING, %s reads from STDIN\n", argv[0], argv[0] );
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

  /* Print out the table (CSV/TSV/etc.) header if requested: */
  if( header.value.b == 1 ) {
      char *separator_now = "";
      if( print_filename.value.b == 1 ) {
          printf( "%s", separator_now );
          PRINT_QUOTED_OR_DELIMITED( "filename" );
          separator_now = separator.value.s;
      }
      if( print_dataname.value.b == 1 ) {
          printf( "%s", separator_now );
          PRINT_QUOTED_OR_DELIMITED( "dblname" );
          separator_now = separator.value.s;
      }
      for( int i = 0; i < tagcount; i++ ) {
          printf( "%s", separator_now );
          PRINT_QUOTED_OR_DELIMITED( taglist[i] );
          separator_now = separator.value.s;
      }
      printf( "%s", group_separator.value.s );
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
                  if( !cif_datablock_list( cif ) ||
                      !datablock_name( cif_datablock_list( cif )) ) {
                      fprintf( stderr,
                               "%s: file '%s' seems to be empty (no named datablocks)\n",
                               argv[0], filename );
                  } else {
                      if( quote.value.s != NULL && *quote.value.s != '\0' ) {
                          cif_print_quoted_tag_values
                              ( cif, taglist, tagcount,
                                ( print_filename.value.b == 1 ? filename : NULL ),
                                print_dataname.value.b, group_separator.value.s,
                                separator.value.s, vseparator.value.s,
                                replacement.value.s,
                                quote.value.s, always_quote.value.b );
                      } else {
                          cif_print_tag_values
                              ( cif, taglist, tagcount,
                                ( print_filename.value.b == 1 ? filename : NULL ),
                                print_dataname.value.b, group_separator.value.s,
                                separator.value.s, vseparator.value.s,
                                replacement.value.s );
                      }
                  }
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

  for( i = 0; i < tagcount; i++ )
      freex( taglist[i] );
  freex( taglist );

  return retval;
}
