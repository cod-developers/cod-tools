#include <Python.h>
#include <cif_grammar_y.h>
#include <cif_grammar_flex.h>
#include <allocx.h>
#include <cxprintf.h>
#include <getoptions.h>
#include <cexceptions.h>
#include <stdiox.h>
#include <stringx.h>
#include <yy.h>
#include <cif.h>
#include <datablock.h>

char *progname = "cifparser";

PyObject * parse_cif( char * fname, char * prog, PyObject * opt )
{
    cexception_t inner;
    cif_yy_debug_off();
    cif_flex_debug_off();
    cif_debug_off();
    CIF * volatile cif = NULL;
    COMPILER_OPTIONS * co = NULL;

    cexception_guard( inner ) {
        co = new_compiler_options( &inner );
    }
    cexception_catch {
        fprintf( stderr,
                 "could not allocate CIF parser options in ccifparser.py\n" );
        co = NULL;
    }

    PyObject * options = opt;
    if( PyDict_Contains( options, PyString_FromString( "do_not_unprefix_text" ) ) ) {
        set_do_not_unprefix_text( co );
    }
    if( PyDict_Contains( options, PyString_FromString( "do_not_unfold_text" ) ) ) {
        set_do_not_unfold_text( co );
    }
    if( PyDict_Contains( options, PyString_FromString( "fix_errors" ) ) ) {
        set_fix_errors( co );
    }
    if( PyDict_Contains( options, PyString_FromString( "fix_duplicate_tags_with_same_values" ) ) ) {
        set_fix_duplicate_tags_with_same_values( co );
    }
    if( PyDict_Contains( options, PyString_FromString( "fix_duplicate_tags_with_empty_values" ) ) ) {
        set_fix_duplicate_tags_with_empty_values( co );
    }
    if( PyDict_Contains( options, PyString_FromString( "fix_data_header" ) ) ) {
        set_fix_data_header( co );
    }
    if( PyDict_Contains( options, PyString_FromString( "fix_datablock_names" ) ) ) {
        set_fix_datablock_names( co );
    }
    if( PyDict_Contains( options, PyString_FromString( "fix_string_quotes" ) ) ) {
        set_fix_string_quotes( co );
    }
    if( PyDict_Contains( options, PyString_FromString( "fix_missing_closing_double_quote" ) ) ) {
        set_fix_missing_closing_double_quote();
    }
    if( PyDict_Contains( options, PyString_FromString( "fix_missing_closing_single_quote" ) ) ) {
        set_fix_missing_closing_single_quote();
    }
    if( PyDict_Contains( options, PyString_FromString( "fix_ctrl_z" ) ) ) {
        set_fix_ctrl_z();
    }
    if( PyDict_Contains( options, PyString_FromString( "fix_non_ascii_symbols" ) ) ) {
        set_fix_non_ascii_symbols();
    }
    if( PyDict_Contains( options, PyString_FromString( "allow_uqstring_brackets" ) ) ) {
        set_allow_uqstring_brackets();
    }

    if( strlen( fname ) == 1 && fname[0] == '-' ) {
        fname = NULL;
    }

    progname = prog;

    int nerrors = 0;
    PyObject * datablocks = PyList_New(0);

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
    free( co );

    if( cif ) {
        DATABLOCK *datablock;
        foreach_datablock( datablock, cif_datablock_list( cif ) ) {
            PyObject * current_datablock = PyDict_New();
            PyDict_SetItemString( current_datablock, "name",
                PyString_FromString( datablock_name( datablock ) ) );

            size_t length = datablock_length( datablock );
            char **tags   = datablock_tags( datablock );
            ssize_t * value_lengths = datablock_value_lengths( datablock );
            char ***values = datablock_values( datablock );
            int *inloop   = datablock_in_loop( datablock );
            int  loop_count = datablock_loop_count( datablock );
            datablock_value_type_t **types = datablock_types( datablock );

            PyObject * taglist    = PyList_New(0);
            PyObject * valuehash  = PyDict_New();
            PyObject * loopid     = PyDict_New();
            PyObject * loops      = PyList_New(0);
            PyObject * typehash   = PyDict_New();

            size_t i;
            ssize_t j;
            for( i = 0; i < loop_count; i++ ) {
                PyObject * loop = PyList_New(0);
                PyList_Append( loops, loop );
            }

            for( i = 0; i < length; i++ ) {
                PyList_Append( taglist, PyString_FromString( tags[i] ) );

                PyObject * tagvalues  = PyList_New(0);
                PyObject * typevalues = PyList_New(0);
                PyObject * type;
                for( j = 0; j < value_lengths[i]; j++ ) {
                    PyList_Append( tagvalues, PyString_FromString( values[i][j] ) );
                    switch ( types[i][j] ) {
                        case DBLK_INT :
                            type = PyString_FromString( "INT" ); break;
                        case DBLK_FLOAT :
                            type = PyString_FromString( "FLOAT" ); break;
                        case DBLK_SQSTRING :
                            type = PyString_FromString( "SQSTRING" ); break;
                        case DBLK_DQSTRING :
                            type = PyString_FromString( "DQSTRING" ); break;
                        case DBLK_UQSTRING :
                            type = PyString_FromString( "UQSTRING" ); break;
                        case DBLK_TEXT :
                            type = PyString_FromString( "TEXTFIELD" ); break;
                        default :
                            type = PyString_FromString( "UNKNOWN" );
                    }
                    PyList_Append( typevalues, type );
                }
                PyDict_SetItemString( valuehash, tags[i], tagvalues );
                PyDict_SetItemString( typehash, tags[i], typevalues );

                if( inloop[i] != -1 ) {
                    PyDict_SetItemString( loopid, tags[i], PyInt_FromLong( inloop[i] ) );
                    PyObject * current_loop = PyList_GetItem( loops, inloop[i] );
                    PyList_Append( current_loop, PyString_FromString( tags[i] ) );
                }
            }

            PyDict_SetItemString( current_datablock, "tags",   taglist );
            PyDict_SetItemString( current_datablock, "values", valuehash );
            PyDict_SetItemString( current_datablock, "types",  typehash );
            PyDict_SetItemString( current_datablock, "inloop", loopid );
            PyDict_SetItemString( current_datablock, "loops",  loops );

            PyList_Append( datablocks, current_datablock );
        }
        nerrors = cif_nerrors( cif );
        delete_cif( cif );
    }

    PyObject * ret = PyDict_New();
    PyDict_SetItemString( ret, "datablocks", datablocks );
    PyDict_SetItemString( ret, "nerrors", PyInt_FromLong( nerrors ) );
    return( ret );
}
