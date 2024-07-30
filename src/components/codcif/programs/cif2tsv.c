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

"   -a, --all-tags\n"
"                     Extract data for all data names (default).\n"
"                     Overrides '--tags'.\n"

"   -t, --tags _cell_length_a,_cell_volume\n"
"                     Extract the specified data items.\n\n"

"   -g, --group-separator    $'\\n'\n"
"       --newline-characters $'\\n'\n"
"                     Specify a group separator that separates "
                     "TSV/CSV/ADT \"lines\" (default \"\\n\")\n\n"

"   -r, --record-separator $'\\t'\n"
"       --separator        $'\\t'\n"
"                     Use the specified string to separate values\n"
"                     of different data items (default \" \").\n\n"

"   -u, --unit-separator \"|\"\n"
"       --value-separator \"|\"\n"
"       --vseparator      \"|\"\n"
"                     Use the specified string to separate multiple\n"
"                     values of each looped data item (default \"|\").\n\n"

"   -p, --replacement  \" \"\n"
"                     A charater to which all separators are replaced\n"
"                     in the non-quoting output formats (TSV and ADT).\n\n"

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
"                     output. Default depends on how program is called:\n"
"                     'cif2csv', 'cif2tsv' or 'cif2adt'\n"

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
static option_value_t use_all_tags;
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

static void set_tag_list( int argc, char *argv[], int *i,
                          option_t *option, cexception_t * ex )
{
    use_all_tags.value.b = 0;
    (*i) ++;
    tags.value.s = argv[*i];
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
  { "-a", "--all-tags",           OT_BOOLEAN_TRUE,  &use_all_tags},
  { "-t", "--tags",               OT_FUNCTION,      NULL, &set_tag_list },
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

static int tag_is_in_tag_list (char *tag, char *tag_list[], int ntags )
{
    if( tag && tag_list ) {
        for( int i = 0; i < ntags; i++ ) {
            if( strcmp( tag, tag_list[i] ) == 0 ) {
                return 1;
            }
        }
    }
    return 0;
}

/* Adding some suntactic sugar for readablity, to shorten a very long
   function call: */

#define PRINT_QUOTED_OR_DELIMITED(VALUE)                       \
    print_quoted_or_delimited_value                             \
    ( (VALUE), group_separator.value.s, *separator.value.s,     \
      *vseparator.value.s, *replacement.value.s,                \
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
  use_all_tags.value.b = 1; /* Print out all data items by default.*/
  header.value.b = 0; /* Do NOT print the header by default.*/
  tags.value.s = "";
  group_separator.value.s = "\n"; /*ASCII: GS, group separator*/
  separator.value.s = "\t";       /*ASCII: RS, record separator*/
  vseparator.value.s = "|";       /*ASCII: US, unit separator*/
  replacement.value.s = " ";
  print_filename.value.b = 1;
  print_dataname.value.b = 1;

  char *basename = rindex( progname, '/' );

  if( basename ) {
      basename ++;
  } else {
      basename = progname;      
  }
  
  if( strcmp( basename, "cif2csv" ) == 0 ) {
      set_csv_delimiters( argc, argv, /*int *i = */NULL,
                          /* option = */ NULL,
                          /* cexception_t * ex =*/ NULL );
  } else if( strcmp( basename, "cif2tsv" ) == 0 ) {
      set_tsv_delimiters( argc, argv, /*int *i = */NULL,
                          /* option = */ NULL,
                          /* cexception_t * ex =*/ NULL );
  } else if( strcmp( basename, "cif2adt" ) == 0 ) {
      set_adt_delimiters( argc, argv, /*int *i = */NULL,
                          /* option = */ NULL,
                          /* cexception_t * ex =*/ NULL );
  } else if( strcmp( basename, "cif-to-csv" ) == 0 ) {
      set_csv_delimiters( argc, argv, /*int *i = */NULL,
                          /* option = */ NULL,
                          /* cexception_t * ex =*/ NULL );
  } else if( strcmp( basename, "cif-to-tsv" ) == 0 ) {
      set_tsv_delimiters( argc, argv, /*int *i = */NULL,
                          /* option = */ NULL,
                          /* cexception_t * ex =*/ NULL );
  } else if( strcmp( basename, "cif-to-adt" ) == 0 ) {
      set_adt_delimiters( argc, argv, /*int *i = */NULL,
                          /* option = */ NULL,
                          /* cexception_t * ex =*/ NULL );
  }
  
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
      char *column_names [] = {"tag", "index", "value", NULL};
      if( print_dataname.value.b == 1 ) {
          PRINT_QUOTED_OR_DELIMITED( "dblname" );
          separator_now = separator.value.s;
      }
      for( int i = 0; column_names[i] != NULL; i++ ) {
          printf( "%s", separator_now );
          PRINT_QUOTED_OR_DELIMITED( column_names[i] );
          separator_now = separator.value.s;
      }
      if( print_filename.value.b == 1 ) {
          printf( "%s", separator_now );
          PRINT_QUOTED_OR_DELIMITED( "filename" );
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
                  if( !cif_datablock_list( cif ) ) {
                      fprintf( stderr,
                               "%s: file '%s' seems to be empty (no named datablocks)\n",
                               argv[0], filename );
                  } else {
                      /*
                      cif_print_tag_values
                          ( cif, taglist, tagcount,
                            ( print_filename.value.b == 1 ? filename : "" ),
                            print_dataname.value.b, group_separator.value.s,
                            separator.value.s, vseparator.value.s,
                            replacement.value.s );
                      */

                      DATABLOCK *datablock;
                      DATABLOCK *dblock_list = cif_datablock_list( cif );

                      foreach_datablock( datablock, dblock_list ) {
                          char *dblock_name = datablock_name( datablock );
                          char **tags = datablock_tags( datablock );
                          ssize_t *value_lengths = datablock_value_lengths( datablock );
                          for( size_t i = 0; i < datablock_length(datablock); i++ ) {
                              char *tag_name = tags[i];

                              if( use_all_tags.value.b == 1 ||
                                  tag_is_in_tag_list( tag_name, taglist, tagcount )) {
                                  for( ssize_t j = 0; j < value_lengths[i]; j++ ) {
                                      if( print_dataname.value.b == 1 ) {
                                          PRINT_QUOTED_OR_DELIMITED( dblock_name );
                                          printf( "%s", separator.value.s );
                                      }
                                      PRINT_QUOTED_OR_DELIMITED( tag_name );
                                      printf( "%s", separator.value.s );
                                      if( always_quote.value.b &&
                                          *quote.value.s != '\0' ) {
                                          printf( "\"%zd\"%s", j, separator.value.s );
                                      } else {
                                          printf( "%zd%s", j, separator.value.s );
                                      }
                                      PRINT_QUOTED_OR_DELIMITED
                                          (value_scalar (datablock_cifvalue (datablock, i, j)));
                                      if( print_filename.value.b == 1 ) {
                                          printf( "%s", separator.value.s );
                                          PRINT_QUOTED_OR_DELIMITED( filename );
                                      }
                                      printf( "%s", group_separator.value.s );
                                  }
                              }
                          }
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
