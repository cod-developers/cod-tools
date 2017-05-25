#include <Python.h>
#include <cif_compiler.h>
#include <cif_grammar_y.h>
#include <cif2_grammar_y.h>
#include <cif_grammar_flex.h>
#include <cif_options.h>
#include <allocx.h>
#include <cxprintf.h>
#include <cexceptions.h>
#include <stdiox.h>
#include <stringx.h>
#include <stdbool.h>
#include <yy.h>
#include <cif.h>
#include <datablock.h>
#include <cifmessage.h>
#include <cifvalue.h>
#include <ciflist.h>
#include <ciftable.h>

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

PyObject *extract_value( CIFVALUE * cifvalue ) {
    size_t i;
    PyObject *extracted;
    switch( value_type( cifvalue ) ) {
        case CIF_LIST: {
            CIFLIST *ciflist = value_list( cifvalue );
            PyObject *values = PyList_New(0);
            for( i = 0; i < list_length( ciflist ); i++ ) {
                PyList_Append( values, extract_value( list_get( ciflist, i ) ) );
            }
            extracted = values;
            break;
        }
        case CIF_TABLE: {
            CIFTABLE *ciftable = value_table( cifvalue );
            char **keys = table_keys( ciftable );
            PyObject *values = PyDict_New();
            for( i = 0; i < table_length( ciftable ); i++ ) {
                PyDict_SetItemString( values, keys[i],
                        extract_value( table_get( ciftable, keys[i] ) ) );
            }
            extracted = values;
            break;
        }
        default:
            extracted = PyString_FromString( value_scalar( cifvalue ) );
    }
    return extracted;
}

PyObject *extract_type( CIFVALUE * cifvalue ) {
    size_t i;
    PyObject *extracted;
    switch( value_type( cifvalue ) ) {
        case CIF_LIST: {
            CIFLIST *ciflist = value_list( cifvalue );
            PyObject *type_list = PyList_New(0);
            for( i = 0; i < list_length( ciflist ); i++ ) {
                PyList_Append( type_list, extract_type( list_get( ciflist, i ) ) );
            }
            extracted = type_list;
            break;
        }
        case CIF_TABLE: {
            CIFTABLE *ciftable = value_table( cifvalue );
            char **keys = table_keys( ciftable );
            PyObject *type_hash = PyDict_New();
            for( i = 0; i < table_length( ciftable ); i++ ) {
                PyDict_SetItemString( type_hash, keys[i],
                        extract_type( table_get( ciftable, keys[i] ) ) );
            }
            extracted = type_hash;
            break;
        }
        case CIF_INT :
            extracted = PyString_FromString( "INT" ); break;
        case CIF_FLOAT :
            extracted = PyString_FromString( "FLOAT" ); break;
        case CIF_SQSTRING :
            extracted = PyString_FromString( "SQSTRING" ); break;
        case CIF_DQSTRING :
            extracted = PyString_FromString( "DQSTRING" ); break;
        case CIF_UQSTRING :
            extracted = PyString_FromString( "UQSTRING" ); break;
        case CIF_TEXT :
            extracted = PyString_FromString( "TEXTFIELD" ); break;
        case CIF_SQ3STRING :
            extracted = PyString_FromString( "SQ3STRING" ); break;
        case CIF_DQ3STRING :
            extracted = PyString_FromString( "DQ3STRING" ); break;
        default :
            extracted = PyString_FromString( "UNKNOWN" );
    }
    return extracted;
}

PyObject *convert_datablock( DATABLOCK * datablock )
{
    PyObject * current_datablock = PyDict_New();
    PyDict_PutString( current_datablock, "name",
                      datablock_name( datablock ) );

    size_t length = datablock_length( datablock );
    char **tags   = datablock_tags( datablock );
    ssize_t * value_lengths = datablock_value_lengths( datablock );
    int *inloop   = datablock_in_loop( datablock );
    int  loop_count = datablock_loop_count( datablock );

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
        for( j = 0; j < value_lengths[i]; j++ ) {
            PyList_Append( tagvalues,
                extract_value( datablock_cifvalue( datablock, i, j ) ) );
            PyList_Append( typevalues,
                extract_type( datablock_cifvalue( datablock, i, j ) ) );
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
        int major_version = cif_major_version( cif );
        int minor_version = cif_minor_version( cif );
        foreach_datablock( datablock, cif_datablock_list( cif ) ) {
            PyObject * converted_datablock = convert_datablock( datablock );
            PyObject * versionhash  = PyDict_New();
            PyDict_SetItemString( versionhash, "major",
                                  PyInt_FromLong( major_version ) );
            PyDict_SetItemString( versionhash, "minor",
                                  PyInt_FromLong( minor_version ) );
            PyDict_SetItemString( converted_datablock, "cifversion",
                                  versionhash );
            PyList_Append( datablocks, converted_datablock );
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
