#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------
#* 
#  CIF comparison functions that work on the internal
#  representation of a CIF file returned by the CIFParser module.
#**

package CIFDiff;

use strict;
use CIFTagPrint;

require Exporter;
@CIFDiff::ISA = qw(Exporter);
@CIFDiff::EXPORT = qw( diff );

sub diff
{
    my( $cif1, $cif2, $options ) = @_;
    if( $options->{compare_datablock_names}
        && $cif1->{name} ne $cif2->{name} ) {
        print "<data_" . $cif1->{name} . "\n";
        print ">data_" . $cif2->{name} . "\n";
    }
    my @tags1 = sort @{$cif1->{tags}};
    my @tags2 = sort @{$cif2->{tags}};
    while( @tags1 > 0 || @tags2 > 0 ) {
        if( scalar @tags1 == 0 ) {
            print ">";
            CIFTagPrint::print_tag( $tags2[0], $cif2->{values},
                $options->{fold}, $options->{folding_width} );
            shift @tags2;
            next;
        }
        if( scalar @tags2 == 0 ) {
            print "<";
            CIFTagPrint::print_tag( $tags1[0], $cif1->{values},
                $options->{fold}, $options->{folding_width} );
            shift @tags1;
            next;
        }
        if( $tags1[0] ne $tags2[0] ) {
            if( $tags1[0] lt $tags2[0] ) {
                print "<";
                CIFTagPrint::print_tag( $tags1[0], $cif1->{values},
                    $options->{fold}, $options->{folding_width} );
                shift @tags1;
            } else {
                print ">";
                CIFTagPrint::print_tag( $tags2[0], $cif2->{values},
                    $options->{fold}, $options->{folding_width} );
                shift @tags2;
            }
            next;
        }
        if( scalar @{$cif1->{values}{$tags1[0]}} !=
            scalar @{$cif2->{values}{$tags2[0]}} ) {
            print "number of values for "
                . "tag " . $tags1[0]
                . " is different\n";
            shift @tags1;
            shift @tags2;
            next;
        }
        my $is_different = 0;
        for( my $i = 0; $i < @{$cif1->{values}{$tags1[0]}}; $i++ ) {
            if( $cif1->{values}{$tags1[0]}[$i] ne
                $cif2->{values}{$tags2[0]}[$i] ) {
                $is_different = 1;
                last;
            }
        }
        if( $is_different ) {
            print "<";
            CIFTagPrint::print_tag( $tags1[0], $cif1->{values},
                $options->{fold}, $options->{folding_width} );
            print ">";
            CIFTagPrint::print_tag( $tags2[0], $cif2->{values},
                $options->{fold}, $options->{folding_width} );
        }
        shift @tags1;
        shift @tags2;        
    }
}

1;
