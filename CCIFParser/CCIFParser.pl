#!/usr/bin/perl

use strict;
use warnings;

use lib "./lib/perl5";
use lib "./CIFParser";
use lib "./CIFTags";
use CIFParser;
use SOptions;
use Precision;

use Inline C => Config => LIBS => '-L/home/andrius/cif-tools/trunk/CCIFParser -lCIFParser-c -lcexceptions -lgetoptions';
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

AV * parse_cif( SV * filename ) {
    cif_yy_debug_off();    
    cif_flex_debug_off();    
    cif_debug_off();
    CIF * volatile cif = NULL;
    cexception_t inner;
    cif = new_cif_from_cif_file( SvPV_nolen( filename ), &inner );
    AV * datablocks = newAV();
    if( cif && cif_nerrors( cif ) == 0 ) {
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
    }
    dispose_cif( cif );
    return datablocks;
}

END_OF_C_CODE

sub parse
{
    my( $filename ) = @_;
    my $data = parse_cif( $filename );
    foreach my $datablock ( @$data ) {
        $datablock->{precisions} = {};
        foreach my $tag   ( keys %{$datablock->{types}} ) {
            my @prec;
            for( my $i = 0; $i < @{$datablock->{types}{$tag}}; $i++ ) {
                next unless $datablock->{types}{$tag}[$i] eq "INT" ||
                            $datablock->{types}{$tag}[$i] eq "FLOAT";
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
            if( @prec > 0 ) {
                if( @prec < @{$datablock->{types}{$tag}} ) {
                    $prec[ @{$datablock->{types}{$tag}} - 1 ] = undef;
                }
                $datablock->{precisions}{$tag} = \@prec;
            }
        }
    }
    return $data;
}

my $method = 'C';
@ARGV = getOptions(
    "-m,--method" => \$method
);

my $data;
if( $method eq 'Perl' ) {
    my $parser = new CIFParser;
    $data = $parser->Run($ARGV[0]);
} elsif( $method eq 'C' ) {
    $data = parse( $ARGV[0] );
}

foreach my $datablock ( @$data ) {
    print  $datablock->{name} . "\n";
    print "Values:\n";
    foreach my $tag ( sort { lc( $a ) cmp lc( $b ) } @{$datablock->{tags}} ) {
        print "    " . lc( $tag ) . " ";
        print join( " ", @{$datablock->{values}{$tag}} ) . "\n";
    }
    if( exists $datablock->{precisions} ) {
        print "Precisions:\n";
        foreach my $tag ( sort { lc( $a ) cmp lc( $b ) }
            keys %{$datablock->{precisions}} ) {
            print "    " . lc( $tag ) . " ";
            print join( " ", map{ ( defined $_ ) ? $_ : "undef" }
                @{$datablock->{precisions}{$tag}} ) . "\n";
        }
    }
    if( exists $datablock->{types} ) {
        print "Types:\n";
        foreach my $tag ( sort { lc( $a ) cmp lc( $b ) }
            keys %{$datablock->{types}} ) {
            print "    " . lc( $tag ) . " ";
            print join( " ", @{$datablock->{types}{$tag}} ) . "\n";
        }
    }
    print "Inloops:\n";
    foreach my $tag ( sort { lc( $a ) cmp lc( $b ) }
        keys %{$datablock->{inloop}} ) {
        print "    " . lc( $tag ) . " " . $datablock->{inloop}{$tag} . "\n";
    }
    print "Loops:\n";
    foreach my $loop ( @{$datablock->{loops}} ) {
        print join( " ", map{ lc $_ } @$loop ) . "\n";
    }
}
