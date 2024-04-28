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
#include <cifmessage.h>
#include <cif_compiler.h>
#include <cif_grammar_y.h>
#include <cif_grammar_flex.h>
#include <cif_lex_buffer.h>
#include <cif_lexer.h>
#include <allocx.h>
#include <cxprintf.h>
#include <ctype.h>
#include <version.h>

static char *source_URL = "$URL$";

static char *usage_text[2] = {

" Parse CIF file(s), check syntax, and optionally output pretty-printed data.\n",

" OPTIONS:\n"

"   -c, --compile-only\n"
"                     Only compile the CIF (check syntax). Prints out\n"
"                     the filename and 'OK' or 'FAILED' to STDOUT, along\n"
"                     with error messages to STDERR.\n\n"

"   -f, --fix-syntax\n"
"                     Attempt to fix some errors in inputs CIF files, such as\n"
"                     missing data_ headers or unterminated quoted strings.\n\n"
"   -f-, --dont-fix-syntax\n"
"                     Do not attempt to fix syntax errors in input CIF files.\n\n"

"   -p, --print\n"
"                     Print out data in CIF format (a kind of CIF pretty-printer).\n\n"

"   -d, --debug lex,yacc\n"
"                     Specify one or several (comma-separated) debugging options.\n\n"
"                     Currently supported debugging options are:\n"
"                       dump\n"
"                               Dump internal data structures for inspection.\n"
"                       lex\n"
"                               Switch on (F)LEX token printout.\n"
"                       yacc\n"
"                               Ask YACC/BISON to report which rules they reduce.\n"
"                       yylval\n"
"                               Print out YACC/BISON's yylval.\n"
"                       text\n"
"                               Dump the perceived input file text.\n"
"                       code\n"
"                               Dump intermediate CIF code representation.\n"
"\n"

"   -l, --line-length-limit 80\n"
"                     Set the maximum line length for --report-long checks.\n\n"

"   -w, --dataname-length-limit 74\n"
"                     Set the maximum tag length for --report-long checks.\n\n"

"   -q, --quiet\n"
"                     Be quiet, only output error messages and data.\n"

"   -q-, --no-quiet, --verbose\n"
"                     Produce verbose output of the parsing process.\n\n"

"   -r, --report-long-items\n"
"                     Report CIF items (lines, data names) that are longer\n"
"                     longer than mandated by the standard.\n"

"   -r-, --do-not-report-long-items\n"
"                     Ignore long items in CIF, process all data.\n\n"

"   -s, --suppress-errors\n"
"                     Suppress error messages from the parser.\n"

"   -s-, --do-not-suppress-errors\n"
"                     Print parser messages to STDERR (default).\n\n"

"   -M, --dump-messages\n"
"                     Do not use accumulated CIF messages (default).\n"

"   -M-, --do-not-dump-messages\n"
"                     Dump accumulated message texts from the CIF object.\n\n"

"   -u, --unfold-lines\n"
"                     Unfold long lines (default).\n"
"   -u-, --do-not-unfold-lines\n"
"                     Leave folded lines as they are.\n\n"

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

static option_value_t fix_errors;
static option_value_t be_quiet;
static option_value_t debug;
static option_value_t print_cif;
static option_value_t suppress_error_messages;
static option_value_t dump_messages;
static option_value_t report_long_items;
static option_value_t line_length_limit;
static option_value_t dataname_length_limit;
static option_value_t do_not_unfold_long_lines;

static option_t options[] = {
  { "-d", "--debug",           OT_STRING,         &debug },
  { "-f", "--fix-syntax",      OT_BOOLEAN_TRUE,   &fix_errors },
  { "-f-","--dont-fix-syntax", OT_BOOLEAN_FALSE,  &fix_errors },
  { "-c", "--compile-only",    OT_BOOLEAN_FALSE,  &print_cif },
  { "-l", "--line-length-limit",
                               OT_INT,            &line_length_limit},
  { "-p", "--print",           OT_BOOLEAN_TRUE,   &print_cif },
  { "-q", "--quiet",           OT_BOOLEAN_TRUE,   &be_quiet },
  { "-q-","--no-quiet",        OT_BOOLEAN_FALSE,  &be_quiet },
  { NULL, "--verbose",         OT_BOOLEAN_FALSE,  &be_quiet },
  { NULL, "--help",            OT_FUNCTION, NULL, &usage },
  { NULL, "--version",         OT_FUNCTION, NULL, &version },
  { "-s", "--suppress-errors", OT_BOOLEAN_TRUE,   &suppress_error_messages },
  { "-s-","--dont-suppress-errors",
                               OT_BOOLEAN_FALSE,  &suppress_error_messages },
  { "-u", "--unfold-lines",    OT_BOOLEAN_FALSE,  &do_not_unfold_long_lines },
  { "-u-","--do-not-unfold-lines",
                               OT_BOOLEAN_TRUE,   &do_not_unfold_long_lines },
  { NULL, "--dont-unfold-lines",
                               OT_BOOLEAN_TRUE,   &do_not_unfold_long_lines },
  { NULL, "--no-unfold-lines",
                               OT_BOOLEAN_TRUE,   &do_not_unfold_long_lines },
  { NULL, "--do-not-suppress-errors",
                               OT_BOOLEAN_FALSE,  &suppress_error_messages },
  { NULL, "--no-suppress-errors",
                               OT_BOOLEAN_FALSE,  &suppress_error_messages },

  { "-r", "--report-long-items",
                               OT_BOOLEAN_TRUE,   &report_long_items },
  { "-r-","--do-not-report-long-items",
                               OT_BOOLEAN_FALSE,  &report_long_items },
  { NULL, "--dont-report-long-items",
                               OT_BOOLEAN_FALSE,  &report_long_items },
  { NULL, "--no-report-long-items",
                               OT_BOOLEAN_FALSE,  &report_long_items },

  { "-w", "--dataname-length-limit",
                               OT_INT,            &dataname_length_limit},

  { "-M", "--dump-messages",   OT_BOOLEAN_TRUE,   &dump_messages },
  { "-M-","--dont-dump-messages",
                               OT_BOOLEAN_FALSE,  &dump_messages },
  { NULL, "--do-not-dump-messages",
                               OT_BOOLEAN_FALSE,  &dump_messages },
  { NULL, "--no-dump-messages",
                               OT_BOOLEAN_FALSE,  &dump_messages },
  { NULL }
};

static char *strnonl( char *str )
{
    char *start = str;
    if( str ) {
        while( *str ) {
            if( *str == '\n' ) {
                *str = '\0';
            }
            str ++;
        }
    }

    return start;
}

char *progname;

int main( int argc, char *argv[], char *env[] )
{
  cexception_t inner;
  char ** volatile files = NULL;
  CIF * volatile cif = NULL;
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

  if( report_long_items.value.b == 1 ) {
      cif_lexer_set_report_long_lines( 1 );
      cif_lexer_set_report_long_tags( 1 );
  }

  if( line_length_limit.present ) {
      cif_lexer_set_line_length_limit( line_length_limit.value.i );
  }

  if( dataname_length_limit.present ) {
      cif_lexer_set_tag_length_limit( dataname_length_limit.value.i );
  }

  for( i = 0; i == 0 || files[i] != NULL; i++ ) {
      char * volatile filename = NULL;
      cexception_guard( inner ) {
          cif_option_t compiler_options = cif_option_default();
          filename = files[i] ? files[i] : "-";

          if( suppress_error_messages.value.b == 1 ) {
              compiler_options =
                  cif_option_set( compiler_options, CO_SUPPRESS_MESSAGES );
          }

          if( fix_errors.value.b == 1 ) {
              compiler_options =
                  cif_option_set_fix_errors( compiler_options );
          }

          if( do_not_unfold_long_lines.value.b == 1 ) {
              compiler_options =
                  cif_option_set( compiler_options, DO_NOT_UNFOLD_TEXT );
          }

          cif = new_cif_from_cif_file( files[i], compiler_options, &inner );

          if( cif ) {
              if( dump_messages.value.b == 1 ) {
                  CIFMESSAGE *messages = cif_messages( cif );
                  CIFMESSAGE *msg;

                  foreach_cifmessage( msg, messages ) {
                      fprintf( stderr, "%s\t%s\t%d\t%d\t%s",
                               progname, cifmessage_filename( msg ),
                               cifmessage_lineno( msg ), cifmessage_pos( msg ),
                               strnonl( cifmessage_message( msg )));
                      fprintf( stderr, "\n" );
                  }
              }
              if( cif_yyretval( cif ) != 0 ) {
                  cexception_raise( &inner, CIF_UNRECOVERABLE_ERROR,
                                    cxprintf( "compiler could not recover "
                                              "from errors, quitting now\n"
                                              "%d error(s) detected\n",
                                              cif_nerrors( cif )));
#if 0
                                    "compiler could not recover "
                                    "from errors, quitting now" );
#endif
              }
          }

          if( cif && cif_nerrors( cif ) == 0 ) {
              if( debug.present && strstr(debug.value.s, "dump") != NULL ) {
                  cif_dump( cif );
              } else {
                  if( print_cif.value.b == 1 ) {
                      cif_print( cif );
                  } else {
                      if( !be_quiet.value.b ) {
                          printf( "%s: file '%s' OK\n", progname,
                                  filename );
                      }
                  }
              }
          } else {
              retval = 1;
              if( print_cif.value.b == 0 && !be_quiet.value.b ) {
                  printf( "%s: file '%s' FAILED\n", progname, filename );
              }
          }

          if( cif ) {
              delete_cif( cif );
              cif = NULL;
              filename = NULL;
          }
      }
      cexception_catch {
          if( filename ) {
              if( print_cif.value.b == 0 && !be_quiet.value.b ) {
                  printf( "%s: file '%s' FAILED\n", progname, filename );
              }
              if( suppress_error_messages.value.b == 0 ) {
                  const char *syserror = cexception_syserror( &inner );
                  if( syserror ) {
                      fprintf( stderr, "%s: %s: %s - %c%s\n", argv[0], filename,
                               cexception_message( &inner ),
                               tolower(*syserror), syserror+1 );
                  } else {
                      fprintf( stderr, "%s: %s: %s\n", argv[0], filename,
                               cexception_message( &inner ));
                  }
              }
          } else {
              if( suppress_error_messages.value.b == 0 ) {
                  const char *syserror = cexception_syserror( &inner );
                  if( syserror ) {
                      fprintf( stderr, "%s: %s - %c%s\n", argv[0],
                               cexception_message( &inner ),
                               tolower(*syserror), syserror+1 );
                  } else {
                      fprintf( stderr, "%s: %s\n", argv[0],
                               cexception_message( &inner ));
                  }
              }
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
