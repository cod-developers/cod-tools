#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <setjmp.h>
#include <string.h>
#include <cif_grammar_y.h>
#include <cif_grammar_flex.h>
#include <allocx.h>
#include <cxprintf.h>
#include <getoptions.h>
#include <cexceptions.h>
#include <stdiox.h>
#include <stringx.h>
#include <stdarg.h>
#include <yy.h>
#include <assert.h>
#include <cif.h>
#include <datablock.h>

char *progname = "cifparser";

CIF * parse_cif( char * fname ) 
{
    cexception_t inner;
    cif_yy_debug_off();
    cif_flex_debug_off();
    cif_debug_off();
    CIF * volatile cif = NULL;
    COMPILER_OPTIONS * volatile co = NULL;

    if( strlen( fname ) == 1 && fname[0] == '-' ) {
        fname = NULL;
    }

    int nerrors = 0;
    cexception_guard( inner ) {
        co = new_compiler_options( &inner );
    }
    cexception_catch {
        fprintf( stderr,
                 "could not allocate CIF parser options in CCIFparser.pm\n" );
        co = NULL;
    }

    cexception_guard( inner ) {
        cif = new_cif_from_cif_file( fname, co, &inner );
    }
    cexception_catch {
        if( cif != NULL ) {
            nerrors = cif_nerrors( cif );
            dispose_cif( &cif );
        } else {
            nerrors++;
        }
    }
    return( cif );
}

void set_progname( char * name ) {
    progname = name;
}
