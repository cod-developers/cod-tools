#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
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

SV * parse_cif( char * fname, char * prog, SV * opt )
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
                 "could not allocate CIF parser options in CCIFparser.pm\n" );
        co = NULL;
    }

    HV * options = (HV*) SvRV( opt );
    if( hv_exists( options, "do_not_unprefix_text", 20 ) ) {
        set_do_not_unprefix_text( co );
    }
    if( hv_exists( options, "do_not_unfold_text", 18 ) ) {
        set_do_not_unfold_text( co );
    }
    if( hv_exists( options, "fix_errors", 10 ) ) {
        set_fix_errors( co );
    }
    if( hv_exists( options, "fix_duplicate_tags_with_same_values", 35 ) ) {
        set_fix_duplicate_tags_with_same_values( co );
    }
    if( hv_exists( options, "fix_duplicate_tags_with_empty_values", 36 ) ) {
        set_fix_duplicate_tags_with_empty_values( co );
    }
    if( hv_exists( options, "fix_data_header", 15 ) ) {
        set_fix_data_header( co );
    }
    if( hv_exists( options, "fix_datablock_names", 19 ) ) {
        set_fix_datablock_names( co );
    }
    if( hv_exists( options, "fix_string_quotes", 17 ) ) {
        set_fix_string_quotes( co );
    }
    if( hv_exists( options, "fix_missing_closing_double_quote", 32 ) ) {
        set_fix_missing_closing_double_quote();
    }
    if( hv_exists( options, "fix_missing_closing_single_quote", 32 ) ) {
        set_fix_missing_closing_single_quote();
    }
    if( hv_exists( options, "fix_ctrl_z", 10 ) ) {
        set_fix_ctrl_z();
    }
    if( hv_exists( options, "fix_non_ascii_symbols", 21 ) ) {
        set_fix_non_ascii_symbols();
    }
    if( hv_exists( options, "allow_uqstring_brackets", 23 ) ) {
        set_allow_uqstring_brackets();
    }

    if( strlen( fname ) == 1 && fname[0] == '-' ) {
        fname = NULL;
    }

    progname = prog;

    int nerrors = 0;
    AV * datablocks = newAV();

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
            HV * current_datablock = newHV();
            hv_store( current_datablock, "name", 4,
                newSVpv( datablock_name( datablock ), 0 ), 0 );

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
                hv_store( valuehash, tags[i], strlen( tags[i] ),
                    newRV_noinc( (SV*) tagvalues ), 0 );
                hv_store( typehash,  tags[i], strlen( tags[i] ),
                    newRV_noinc( (SV*) typevalues ), 0 );

                if( inloop[i] != -1 ) {
                    hv_store( loopid, tags[i], strlen( tags[i] ),
                        newSViv( inloop[i] ), 0 );
                    SV **current_loop = av_fetch( loops, inloop[i], 0 );
                    av_push( (AV*) SvRV( current_loop[0] ),
                             newSVpv( tags[i], 0 ) );
                }
            }

            hv_store( current_datablock, "tags",   4, newRV_noinc( (SV*) taglist ), 0 );
            hv_store( current_datablock, "values", 6, newRV_noinc( (SV*) valuehash ), 0 );
            hv_store( current_datablock, "types",  5, newRV_noinc( (SV*) typehash ), 0 );
            hv_store( current_datablock, "inloop", 6, newRV_noinc( (SV*) loopid ), 0 );
            hv_store( current_datablock, "loops",  5, newRV_noinc( (SV*) loops ), 0 );
       
            av_push( datablocks, newRV_noinc( (SV*) current_datablock ) );
        }
        nerrors = cif_nerrors( cif );
        delete_cif( cif );
    }

    HV * ret = newHV();
    hv_store( ret, "datablocks", 10, newRV_noinc( (SV*) datablocks ), 0 );
    hv_store( ret, "nerrors",     7, newSViv( nerrors ), 0 );
    return( newRV_noinc( (SV*) ret ) );
}
