%module CCIFParserSWIG
%{
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

    struct CIF {
        int nerrors;
        DATABLOCK *datablock_list;
        DATABLOCK *last_datablock; /* points to the end of the
                                      datablock_list; SHOULD not be freed
                                      when the CIF structure is deleted.*/
    };

    CIF * parse_cif( char * fname );
    void set_progname( char * name );
%}
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

struct CIF {
    int nerrors;
    DATABLOCK *datablock_list;
    DATABLOCK *last_datablock; /* points to the end of the
                                  datablock_list; SHOULD not be freed
                                  when the CIF structure is deleted.*/
};

CIF * parse_cif( char * fname );
void set_progname( char * name );
