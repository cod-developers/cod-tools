#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
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
#include <yy.h>
#include <cif.h>
#include <datablock.h>
#include <cifmessage.h>
#include <cifvalue.h>
#include <ciflist.h>
#include <ciftable.h>

char *progname = "cifparser";

bool is_option_set( HV * options, char * optname ) {
    int value = 0;
    if (options) {
        SV ** value_ref = hv_fetch(options, optname, strlen(optname), 0);
        if (value_ref && *value_ref) {
            value = ( SvIV(*value_ref) > 0 ) ? 1 : 0;
        }
    }

    return value;
}

SV *SV_utf8( SV * scalar ) {
    SvUTF8_on( scalar );
    return scalar;
}

void hv_put( HV * hash, char * key, SV * scalar ) {
    hv_store_ent( hash, SV_utf8( newSVpv( key, 0 ) ), scalar, 0 );
}

SV *extract_value( CIFVALUE * cifvalue ) {
    size_t i;
    SV *extracted;
    switch( value_type( cifvalue ) ) {
        case CIF_LIST: {
            CIFLIST *ciflist = value_list( cifvalue );
            AV *values = newAV();
            for( i = 0; i < list_length( ciflist ); i++ ) {
                av_push( values, extract_value( list_get( ciflist, i ) ) );
            }
            extracted = newRV_noinc( (SV*) values );
            break;
        }
        case CIF_TABLE: {
            CIFTABLE *ciftable = value_table( cifvalue );
            char **keys = table_keys( ciftable );
            HV *values = newHV();
            for( i = 0; i < table_length( ciftable ); i++ ) {
                hv_put( values, keys[i],
                        extract_value( table_get( ciftable, keys[i] ) ) );
            }
            extracted = newRV_noinc( (SV*) values );
            break;
        }
        default:
            extracted = SV_utf8( newSVpv( value_scalar( cifvalue ), 0 ) );
    }
    return extracted;
}

SV *extract_type( CIFVALUE * cifvalue ) {
    size_t i;
    SV *extracted;
    switch( value_type( cifvalue ) ) {
        case CIF_LIST: {
            CIFLIST *ciflist = value_list( cifvalue );
            AV * type_list = newAV();
            for( i = 0; i < list_length( ciflist ); i++ ) {
                av_push( type_list, extract_type( list_get( ciflist, i ) ) );
            }
            extracted = newRV_noinc( (SV*) type_list );
            break;
        }
        case CIF_TABLE: {
            CIFTABLE *ciftable = value_table( cifvalue );
            char **keys = table_keys( ciftable );
            HV *type_hash = newHV();
            for( i = 0; i < table_length( ciftable ); i++ ) {
                hv_put( type_hash, keys[i],
                        extract_type( table_get( ciftable, keys[i] ) ) );
            }
            extracted = newRV_noinc( (SV*) type_hash );
            break;
        }
        case CIF_INT :
            extracted = newSVpv( "INT", 3 ); break;
        case CIF_FLOAT :
            extracted = newSVpv( "FLOAT", 5 ); break;
        case CIF_SQSTRING :
            extracted = newSVpv( "SQSTRING", 8 ); break;
        case CIF_DQSTRING :
            extracted = newSVpv( "DQSTRING", 8 ); break;
        case CIF_UQSTRING :
            extracted = newSVpv( "UQSTRING", 8 ); break;
        case CIF_TEXT :
            extracted = newSVpv( "TEXTFIELD", 9 ); break;
        case CIF_SQ3STRING :
            extracted = newSVpv( "SQ3STRING", 9 ); break;
        case CIF_DQ3STRING :
            extracted = newSVpv( "DQ3STRING", 9 ); break;
        default :
            extracted = newSVpv( "UNKNOWN", 7 );
    }
    return extracted;
}

SV * convert_datablock( DATABLOCK * datablock )
{
    HV * current_datablock = newHV();
    hv_put( current_datablock, "name",
        SV_utf8( newSVpv( datablock_name( datablock ), 0 ) ) );

    size_t length = datablock_length( datablock );
    char **tags   = datablock_tags( datablock );
    ssize_t * value_lengths = datablock_value_lengths( datablock );
    int *inloop   = datablock_in_loop( datablock );
    int  loop_count = datablock_loop_count( datablock );

    AV * taglist    = newAV();
    HV * valuehash  = newHV();
    HV * loopid     = newHV();
    AV * loops      = newAV();
    HV * typehash   = newHV();
    AV * saveframes = newAV();

    size_t i;
    ssize_t j;
    for( i = 0; i < loop_count; i++ ) {
        AV * loop = newAV();
        av_push( loops, newRV_noinc( (SV*) loop ) );
    }

    for( i = 0; i < length; i++ ) {
        av_push( taglist, SV_utf8( newSVpv( tags[i], 0 ) ) );

        AV * tagvalues  = newAV();
        AV * typevalues = newAV();
        for( j = 0; j < value_lengths[i]; j++ ) {
            av_push( tagvalues,
                extract_value( datablock_cifvalue( datablock, i, j ) ) );
            av_push( typevalues,
                extract_type( datablock_cifvalue( datablock, i, j ) ) );
        }
        hv_put( valuehash, tags[i], newRV_noinc( (SV*) tagvalues ) );
        hv_put( typehash,  tags[i], newRV_noinc( (SV*) typevalues ) );

        if( inloop[i] != -1 ) {
            hv_put( loopid, tags[i], newSViv( inloop[i] ) );
            SV **current_loop = av_fetch( loops, inloop[i], 0 );
            av_push( (AV*) SvRV( current_loop[0] ),
                     SV_utf8( newSVpv( tags[i], 0 ) ) );
        }
    }

    DATABLOCK * saveframe;
    foreach_datablock( saveframe,
                       datablock_save_frame_list( datablock ) ) {
        av_push( saveframes,
                 newRV_noinc( convert_datablock( saveframe ) ) );
    }

    hv_put( current_datablock, "tags", newRV_noinc( (SV*) taglist ) );
    hv_put( current_datablock, "values", newRV_noinc( (SV*) valuehash ) );
    hv_put( current_datablock, "types", newRV_noinc( (SV*) typehash ) );
    hv_put( current_datablock, "inloop", newRV_noinc( (SV*) loopid ) );
    hv_put( current_datablock, "loops", newRV_noinc( (SV*) loops ) );
    hv_put( current_datablock, "save_blocks",
            newRV_noinc( (SV*) saveframes ) );

    return (SV*) current_datablock;
}

cif_option_t cif_options_from_hash( SV * opt )
{
    cif_option_t co = cif_option_default();

    HV * options = (HV*) SvRV( opt );
    reset_lexer_flags();
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
    return( cif_option_suppress_messages( co ) );
}

SV * parse_cif( char * fname, char * prog, SV * opt )
{
    cexception_t inner;
    cif_yy_debug_off();
    cif2_yy_debug_off();
    cif_flex_debug_off();
    cif_debug_off();
    CIF * volatile cif = NULL;
    cif_option_t co = cif_options_from_hash( opt );

    if( !fname ||
        ( strlen( fname ) == 1 && fname[0] == '-' ) ) {
        fname = NULL;
    }

    progname = prog;

    int nerrors = 0;
    AV * datablocks = newAV();
    AV * error_messages = newAV();

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
            SV * converted_datablock = convert_datablock( datablock );
            HV * versionhash  = newHV();
            hv_put( versionhash, "major", newSViv( major_version ) );
            hv_put( versionhash, "minor", newSViv( minor_version ) );
            hv_put( (HV*) converted_datablock, "cifversion",
                    newRV_noinc( (SV*) versionhash ) );
            av_push( datablocks, newRV_noinc( converted_datablock ) );
        }

        CIFMESSAGE *cifmessage;
        foreach_cifmessage( cifmessage, cif_messages( cif ) ) {
            HV * current_cifmessage = newHV();

            int lineno = cifmessage_lineno( cifmessage );
            int columnno = cifmessage_columnno( cifmessage );

            if( lineno != -1 ) {
                hv_put( current_cifmessage, "lineno", newSViv( lineno ) );
            }
            if( columnno != -1 ) {
                hv_put( current_cifmessage, "columnno",
                        newSViv( columnno ) );
            }

            hv_put( current_cifmessage, "addpos",
                      newSVpv( cifmessage_addpos( cifmessage ), 0 ) );
            hv_put( current_cifmessage, "program",
                      newSVpv( progname, 0 ) );
            hv_put( current_cifmessage, "filename",
                      newSVpv( cifmessage_filename( cifmessage ), 0 ) );
            hv_put( current_cifmessage, "status",
                      newSVpv( cifmessage_status( cifmessage ), 0 ) );
            hv_put( current_cifmessage, "message",
                      newSVpv( cifmessage_message( cifmessage ), 0 ) );
            hv_put( current_cifmessage, "explanation",
                      newSVpv( cifmessage_explanation( cifmessage ), 0 ) );
            hv_put( current_cifmessage, "msgseparator",
                      newSVpv( cifmessage_msgseparator( cifmessage ), 0 ) );
            hv_put( current_cifmessage, "line",
                      newSVpv( cifmessage_line( cifmessage ), 0 ) );

            av_push( error_messages, newRV_noinc( (SV*) current_cifmessage ) );
        }

        nerrors = cif_nerrors( cif );
        delete_cif( cif );
    }

    HV * ret = newHV();
    hv_put( ret, "datablocks", newRV_noinc( (SV*) datablocks ) );
    hv_put( ret, "messages", newRV_noinc( (SV*) error_messages ) );
    hv_put( ret, "nerrors", newSViv( nerrors ) );
    return( sv_2mortal( newRV_noinc( (SV*) ret ) ) );
}

SV * parse_cif_string( char * buffer, char * prog, SV * opt )
{
    cexception_t inner;
    cif_yy_debug_off();
    cif2_yy_debug_off();
    cif_flex_debug_off();
    cif_debug_off();
    CIF * volatile cif = NULL;
    cif_option_t co = cif_options_from_hash( opt );

    progname = prog;

    int nerrors = 0;
    AV * datablocks = newAV();
    AV * error_messages = newAV();

    cexception_guard( inner ) {
        cif = new_cif_from_cif_string( buffer, co, &inner );
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
            SV * converted_datablock = convert_datablock( datablock );
            HV * versionhash  = newHV();
            hv_put( versionhash, "major", newSViv( major_version ) );
            hv_put( versionhash, "minor", newSViv( minor_version ) );
            hv_put( (HV*) converted_datablock, "cifversion",
                    newRV_noinc( (SV*) versionhash ) );
            av_push( datablocks, newRV_noinc( converted_datablock ) );
        }

        CIFMESSAGE *cifmessage;
        foreach_cifmessage( cifmessage, cif_messages( cif ) ) {
            HV * current_cifmessage = newHV();

            int lineno = cifmessage_lineno( cifmessage );
            int columnno = cifmessage_columnno( cifmessage );

            if( lineno != -1 ) {
                hv_put( current_cifmessage, "lineno", newSViv( lineno ) );
            }
            if( columnno != -1 ) {
                hv_put( current_cifmessage, "columnno",
                        newSViv( columnno ) );
            }

            hv_put( current_cifmessage, "addpos",
                      newSVpv( cifmessage_addpos( cifmessage ), 0 ) );
            hv_put( current_cifmessage, "program",
                      newSVpv( progname, 0 ) );
            hv_put( current_cifmessage, "filename",
                      newSVpv( cifmessage_filename( cifmessage ), 0 ) );
            hv_put( current_cifmessage, "status",
                      newSVpv( cifmessage_status( cifmessage ), 0 ) );
            hv_put( current_cifmessage, "message",
                      newSVpv( cifmessage_message( cifmessage ), 0 ) );
            hv_put( current_cifmessage, "explanation",
                      newSVpv( cifmessage_explanation( cifmessage ), 0 ) );
            hv_put( current_cifmessage, "msgseparator",
                      newSVpv( cifmessage_msgseparator( cifmessage ), 0 ) );
            hv_put( current_cifmessage, "line",
                      newSVpv( cifmessage_line( cifmessage ), 0 ) );

            av_push( error_messages, newRV_noinc( (SV*) current_cifmessage ) );
        }

        nerrors = cif_nerrors( cif );
        delete_cif( cif );
    }

    HV * ret = newHV();
    hv_put( ret, "datablocks", newRV_noinc( (SV*) datablocks ) );
    hv_put( ret, "messages", newRV_noinc( (SV*) error_messages ) );
    hv_put( ret, "nerrors", newSViv( nerrors ) );
    return( sv_2mortal( newRV_noinc( (SV*) ret ) ) );
}
