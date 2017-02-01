#include <Python.h>
#include <cif_grammar_y.h>
#include <cif_grammar_flex.h>
#include <cif_options.h>
#include <allocx.h>
#include <cxprintf.h>
#include <getoptions.h>
#include <cexceptions.h>
#include <stdiox.h>
#include <stringx.h>
#include <stdbool.h>
#include <yy.h>
#include <cif.h>
#include <datablock.h>
#include <cifmessage.h>

char *progname = "cifparser";

bool is_option_set( PyObject * options, char * optname ) {
    PyObject * value_ref = PyDict_GetItem( options,
                                           PyString_FromString( optname ) );
    if( value_ref == NULL ) {
        return 0;
    } else {
        return ( PyInt_AsLong( value_ref ) > 0 ) ? 1 : 0;
    }
}

void PyDict_PutString( PyObject * dict, char * key, char * value ) {
    if( value != NULL ) {
        PyDict_SetItemString( dict, key, PyString_FromString( value ) );
    } else {
        PyDict_SetItemString( dict, key, Py_None );
    }
}

PyObject * convert_datablock( DATABLOCK * datablock )
{
    PyObject * current_datablock = PyDict_New();
    PyDict_PutString( current_datablock, "name",
                      datablock_name( datablock ) );

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
    PyObject * saveframes = PyList_New(0);

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

    DATABLOCK * saveframe;
    foreach_datablock( saveframe,
                       datablock_save_frame_list( datablock ) ) {
        PyList_Append( saveframes,
                       convert_datablock( saveframe ) );
    }

    PyDict_SetItemString( current_datablock, "tags",   taglist );
    PyDict_SetItemString( current_datablock, "values", valuehash );
    PyDict_SetItemString( current_datablock, "types",  typehash );
    PyDict_SetItemString( current_datablock, "inloop", loopid );
    PyDict_SetItemString( current_datablock, "loops",  loops );
    PyDict_SetItemString( current_datablock, "save_blocks",
                          saveframes );

    return current_datablock;
}

PyObject * parse_cif( char * fname, char * prog, PyObject * opt )
{
    cexception_t inner;
    cif_yy_debug_off();
    cif_flex_debug_off();
    cif_debug_off();
    CIF * volatile cif = NULL;
    cif_option_t co = cif_option_default();

    PyObject * options = opt;
    if( is_option_set( options, "do_not_unprefix_text" ) ) {
        co = cif_option_set_do_not_unprefix_text( co );
    }
    if( is_option_set( options, "do_not_unfold_text" ) ) {
        co = cif_option_set_do_not_unfold_text( co );
    }
    if( is_option_set( options, "fix_errors" ) ) {
        co = cif_option_set_fix_errors( co );
    }
    if( is_option_set( options, "fix_duplicate_tags_with_same_values" ) ) {
        co = cif_option_set_fix_duplicate_tags_with_same_values( co );
    }
    if( is_option_set( options, "fix_duplicate_tags_with_empty_values" ) ) {
        co = cif_option_set_fix_duplicate_tags_with_empty_values( co );
    }
    if( is_option_set( options, "fix_data_header" ) ) {
        co = cif_option_set_fix_data_header( co );
    }
    if( is_option_set( options, "fix_datablock_names" ) ) {
        co = cif_option_set_fix_datablock_names( co );
        set_lexer_fix_datablock_names();
    }
    if( is_option_set( options, "fix_string_quotes" ) ) {
        co = cif_option_set_fix_string_quotes( co );
    }
    if( is_option_set( options, "fix_missing_closing_double_quote" ) ) {
        set_lexer_fix_missing_closing_double_quote();
    }
    if( is_option_set( options, "fix_missing_closing_single_quote" ) ) {
        set_lexer_fix_missing_closing_single_quote();
    }
    if( is_option_set( options, "fix_ctrl_z" ) ) {
        set_lexer_fix_ctrl_z();
    }
    if( is_option_set( options, "fix_non_ascii_symbols" ) ) {
        set_lexer_fix_non_ascii_symbols();
    }
    if( is_option_set( options, "allow_uqstring_brackets" ) ) {
        set_lexer_allow_uqstring_brackets();
    }
    co = cif_option_suppress_messages( co );

    if( !fname ||
        ( strlen( fname ) == 1 && fname[0] == '-' ) ) {
        fname = NULL;
    }

    progname = prog;

    int nerrors = 0;
    PyObject * datablocks = PyList_New(0);
    PyObject * error_messages = PyList_New(0);

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

    if( cif ) {
        DATABLOCK *datablock;
        foreach_datablock( datablock, cif_datablock_list( cif ) ) {
            PyList_Append( datablocks, convert_datablock( datablock ) );
        }

        CIFMESSAGE *cifmessage;
        foreach_cifmessage( cifmessage, cif_messages( cif ) ) {
            PyObject * current_cifmessage = PyDict_New();

            int lineno = cifmessage_lineno( cifmessage );
            int columnno = cifmessage_columnno( cifmessage );

            if( lineno != -1 ) {
                PyDict_SetItemString( current_cifmessage, "lineno",
                                      PyInt_FromLong( lineno ) );
            }
            if( columnno != -1 ) {
                PyDict_SetItemString( current_cifmessage, "columnno",
                                      PyInt_FromLong( columnno ) );
            }

            PyDict_PutString( current_cifmessage, "addpos",
                      cifmessage_addpos( cifmessage ) );
            PyDict_PutString( current_cifmessage, "program", progname );
            PyDict_PutString( current_cifmessage, "filename",
                      cifmessage_filename( cifmessage ) );
            PyDict_PutString( current_cifmessage, "status",
                      cifmessage_status( cifmessage ) );
            PyDict_PutString( current_cifmessage, "message",
                      cifmessage_message( cifmessage ) );
            PyDict_PutString( current_cifmessage, "explanation",
                      cifmessage_explanation( cifmessage ) );
            PyDict_PutString( current_cifmessage, "msgseparator",
                      cifmessage_msgseparator( cifmessage ) );
            PyDict_PutString( current_cifmessage, "line",
                      cifmessage_line( cifmessage ) );

            PyList_Append( error_messages, current_cifmessage );
        }

        nerrors = cif_nerrors( cif );
        delete_cif( cif );
    }

    PyObject * ret = PyDict_New();
    PyDict_SetItemString( ret, "datablocks", datablocks );
    PyDict_SetItemString( ret, "messages", error_messages );
    PyDict_SetItemString( ret, "nerrors", PyInt_FromLong( nerrors ) );
    return( ret );
}
