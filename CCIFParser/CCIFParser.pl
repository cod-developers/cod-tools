#!/usr/bin/perl

use strict;
use warnings;
#use Inline C => Config => AUTO_INCLUDE => '#include "cif_grammar_y"';
use Inline C => Config => MYEXTLIB => '/home/andrius/cif-tools/trunk/CCIFParser/cif_grammar.so /home/andrius/cif-tools/trunk/CCIFParser/cif.so /home/andrius/cif-tools/trunk/CCIFParser/cexceptions.so /home/andrius/cif-tools/trunk/CCIFParser/getoptions.so';

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

            AV * taglist    = newAV();
            HV * valuehash  = newHV();
            HV * loopid     = newHV();
            AV * loops      = newAV();
            int i, j;
            for( i = 0; i < loop_count; i++ ) {
                AV * loop = newAV();
                av_push( loops, newRV_inc( loop ) );
            }

            for( i = 0; i < length; i++ ) {
                av_push( taglist, newSVpv( tags[i], 0 ) );
                AV * tagvalues = newAV();
                for( j = 0; j < value_lengths[i]; j++ ) {
                    av_push( tagvalues, newSVpv( values[i][j], 0 ) );
                }
                hv_store( valuehash, tags[i], strlen( tags[i] ),
                    newRV_inc( tagvalues ), 0 );
                if( inloop[i] != -1 ) {
                    hv_store( loopid, tags[i], strlen( tags[i] ),
                        newSViv( inloop[i] ), 0 );
                    SV **current_loop = av_fetch( loops, inloop[i], 0 );
                    av_push( SvRV( current_loop[0] ), newSVpv( tags[i], 0 ) );
                }
            }

            hv_store( current_datablock, "tags",   4, newRV_inc( taglist ),   0 );
            hv_store( current_datablock, "values", 6, newRV_inc( valuehash ), 0 );
            hv_store( current_datablock, "inloop", 6, newRV_inc( loopid ), 0 );
            hv_store( current_datablock, "loops",  5, newRV_inc( loops ), 0 );
       
            av_push( datablocks, newRV_inc( current_datablock ) );
        }
    }
    dispose_cif( cif );
    return datablocks;
}

END_OF_C_CODE

my $a = parse_cif( $ARGV[0] );
foreach my $datablock ( @$a ) {
    print  $datablock->{name} . "\n";
    foreach my $tag ( @{$datablock->{tags}} ) {
        print "    [$tag]: ";
        print join( " ", @{$datablock->{values}{$tag}} ) . "\n";
    }
    print "Values:\n";
    foreach my $tag ( keys %{$datablock->{values}} ) {
        print "    [$tag]\n";
    }
    print "Inloops:\n";
    foreach my $tag ( keys %{$datablock->{inloop}} ) {
        print "    " . $tag . " " . $datablock->{inloop}{$tag} . "\n";
    }
    print "Loops:\n";
    foreach my $loop ( @{$datablock->{loops}} ) {
        print join( " ", @$loop ) . "\n";
    }
}
