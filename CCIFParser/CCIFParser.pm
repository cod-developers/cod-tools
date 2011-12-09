#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------
#* 
#  Wrapper for CIF parser, written in C language. Converts parsed CIF
#  data structure to one, which can be used by Perl programs.
#**

package CCIFParser;

use strict;
use SOptions;
use Precision;
use Cwd;

require Exporter;
@CCIFParser::ISA = qw(Exporter);
@CCIFParser::EXPORT = qw( parse );

use Inline C => Config => LIBS => "-L" . getcwd . "/CIFParser-c -L"
    . getcwd . "/CIFParser-c/libs/cexceptions -L"
    . getcwd . "/CIFParser-c/libs/getoptions -lCIFParser-c -lcexceptions -lgetoptions",
    INC => "-I" . getcwd . "/CIFParser-c -I"
    . getcwd . "/CIFParser-c/libs/cexceptions -I"
    . getcwd . "/CIFParser-c/libs/getoptions";
use Inline C => <<'END_OF_C_CODE';

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <setjmp.h>
#include <string.h>
#include <cif_grammar_y.h>
#include <cif_grammar_flex.h>
#include <cif_grammar.tab.h>
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

void parse_cif( SV * filename, HV * options ) {
    cif_yy_debug_off();    
    cif_flex_debug_off();    
    cif_debug_off();
    CIF * volatile cif = NULL;
    int nerrors = 0;
    AV * datablocks = newAV();

    COMPILER_OPTIONS * co = new_compiler_options();
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

    cexception_t inner;
    cexception_guard( inner ) {
        cif = new_cif_from_cif_file( SvPV_nolen( filename ), co, &inner );
    }
    cexception_catch {
        if( cif != NULL ) {
            nerrors = cif_nerrors( cif );
            dispose_cif( cif );
        } else {
            nerrors++;
        }
    }
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
                av_push( loops, newRV_inc( loop ) );
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
                    newRV_inc( tagvalues ), 0 );
                hv_store( typehash,  tags[i], strlen( tags[i] ),
                    newRV_inc( typevalues ), 0 );

                if( inloop[i] != -1 ) {
                    hv_store( loopid, tags[i], strlen( tags[i] ),
                        newSViv( inloop[i] ), 0 );
                    SV **current_loop = av_fetch( loops, inloop[i], 0 );
                    av_push( SvRV( current_loop[0] ), newSVpv( tags[i], 0 ) );
                }
            }

            hv_store( current_datablock, "tags",   4, newRV_inc( taglist ),   0 );
            hv_store( current_datablock, "values", 6, newRV_inc( valuehash ), 0 );
            hv_store( current_datablock, "types",  5, newRV_inc( typehash ), 0 );
            hv_store( current_datablock, "inloop", 6, newRV_inc( loopid ), 0 );
            hv_store( current_datablock, "loops",  5, newRV_inc( loops ), 0 );
       
            av_push( datablocks, newRV_inc( current_datablock ) );
        }
        nerrors = cif_nerrors( cif );
        delete_cif( cif );
    }
    Inline_Stack_Vars;
    Inline_Stack_Reset;
    Inline_Stack_Push(sv_2mortal(newRV_inc(datablocks)));
    Inline_Stack_Push(sv_2mortal(newSViv(nerrors)));
    Inline_Stack_Done;
}

void set_progname( SV * name ) {
    progname = SvPV_nolen( name );
}

END_OF_C_CODE

sub parse
{
    my( $filename, $options ) = @_;
    $options = {} unless defined $options;
    set_progname( $0 ne '-e' ? $0 : "" );
    my( $data, $nerrors ) = parse_cif( $filename, $options );
    foreach my $datablock ( @$data ) {
        $datablock->{precisions} = {};
        foreach my $tag   ( keys %{$datablock->{types}} ) {
            my @prec;
            my $has_numeric_values = 0;
            for( my $i = 0; $i < @{$datablock->{types}{$tag}}; $i++ ) {
                next unless $datablock->{types}{$tag}[$i] eq "INT" ||
                            $datablock->{types}{$tag}[$i] eq "FLOAT";
                $has_numeric_values = 1;
                if(         $datablock->{types}{$tag}[$i] eq "FLOAT" &&
                            $datablock->{values}{$tag}[$i] =~
                            m/^(.*)( \( ([0-9]+) \) )$/six ) {
                            $prec[$i] = unpack_precision( $1, $3 );
                } elsif(    $datablock->{types}{$tag}[$i] eq "INT" &&
                            $datablock->{values}{$tag}[$i] =~
                            m/^(.*)( \( ([0-9]+) \) )$/sx ) {
                            $prec[$i] = $3;
                }
            }
            if( @prec > 0 || ( exists $datablock->{inloop}{$tag} &&
                $has_numeric_values ) ) {
                if( @prec < @{$datablock->{types}{$tag}} ) {
                    $prec[ @{$datablock->{types}{$tag}} - 1 ] = undef;
                }
                $datablock->{precisions}{$tag} = \@prec;
            }
        }
    }
    if( wantarray ) {
        return( $data, $nerrors );
    } else {
        return $data;
    }
}

1;
