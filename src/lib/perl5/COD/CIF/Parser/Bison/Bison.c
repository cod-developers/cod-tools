#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <cif_grammar_y.h>
#include <cif_grammar_flex.h>
#include <cif_options.h>
#include <allocx.h>
#include <cxprintf.h>
#include <getoptions.h>
#include <cexceptions.h>
#include <stdiox.h>
#include <stringx.h>
#include <yy.h>
#include <cif.h>
#include <datablock.h>
#include <cifmessage.h>

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

void hv_put( HV * hash, char * key, SV * scalar ) {
    hv_store( hash, key, strlen(key), scalar, 0 );
}

SV * convert_datablock( DATABLOCK * datablock )
{
    HV * current_datablock = newHV();
    hv_put( current_datablock, "name",
        newSVpv( datablock_name( datablock ), 0 ) );

    size_t length = datablock_length( datablock );
    char **tags   = datablock_tags( datablock );
    ssize_t * value_lengths = datablock_value_lengths( datablock );
    char ***values = datablock_values( datablock );
    int *inloop   = datablock_in_loop( datablock );
    int  loop_count = datablock_loop_count( datablock );
    datablock_value_type_t **types = datablock_types( datablock );

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
        av_push( taglist, newSVpv( tags[i], 0 ) );

        AV * tagvalues  = newAV();
        AV * typevalues = newAV();
        SV * type;
        for( j = 0; j < value_lengths[i]; j++ ) {
            av_push( tagvalues, newSVpv( values[i][j], 0 ) );
            switch ( types[i][j] ) {
                case DBLK_INT :
                    type = newSVpv( "INT", 3 ); break;
                case DBLK_FLOAT :
                    type = newSVpv( "FLOAT", 5 ); break;
                case DBLK_SQSTRING :
                    type = newSVpv( "SQSTRING", 8 ); break;
                case DBLK_DQSTRING :
                    type = newSVpv( "DQSTRING", 8 ); break;
                case DBLK_UQSTRING :
                    type = newSVpv( "UQSTRING", 8 ); break;
                case DBLK_TEXT :
                    type = newSVpv( "TEXTFIELD", 9 ); break;
                default :
                    type = newSVpv( "UNKNOWN", 7 );
            }
            av_push( typevalues, type );
        }
        hv_put( valuehash, tags[i], newRV_noinc( (SV*) tagvalues ) );
        hv_put( typehash,  tags[i], newRV_noinc( (SV*) typevalues ) );

        if( inloop[i] != -1 ) {
            hv_put( loopid, tags[i], newSViv( inloop[i] ) );
            SV **current_loop = av_fetch( loops, inloop[i], 0 );
            av_push( (AV*) SvRV( current_loop[0] ),
                     newSVpv( tags[i], 0 ) );
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

SV * parse_cif( char * fname, char * prog, SV * opt )
{
    cexception_t inner;
    cif_yy_debug_off();
    cif_flex_debug_off();
    cif_debug_off();
    CIF * volatile cif = NULL;
    cif_option_t co = cif_option_default();

    HV * options = (HV*) SvRV( opt );
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
        foreach_datablock( datablock, cif_datablock_list( cif ) ) {
            av_push( datablocks, newRV_noinc( convert_datablock( datablock ) ) );
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
