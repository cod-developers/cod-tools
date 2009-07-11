#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------
#* 
#  CIF tag management functions that work on the internal
#  representation of a CIF file returned by the CIFParser module.
#**

package FormulaPrint;

use strict;

require Exporter;
@FormulaPrint::ISA = qw(Exporter);
@FormulaPrint::EXPORT = qw( sprint_formula print_formula );

sub print_formula($@)
{
    my ( $formula_hash, $format ) = @_;

    my $formula_string = sprint_formula( $formula_hash, $format );

    print $formula_string, "\n";
}

sub sprint_number($$)
{
    my ($number, $format) = @_;

    if( defined $format ) {
        return sprintf( $format, $number );
    } else {
        return $number;
    }
}

sub sprint_formula($@)
{
    my ($formula_hash, $format ) = @_;

    # Chemical formulas, according the IUCr recommendations, should
    # use the 'Hill' system used by Chemical Abstracts:
    #
    # the order of the elements within any group or moiety depends on
    # whether carbon is present or not. If carbon is present, the
    # order should be: C, then H, then the other elements in
    # alphabetical order of their symbol. If carbon is not present,
    # the elements are listed purely in alphabetical order of their
    # symbol.

    # References:
    # 1. http://www.iucr.org/__data/iucr/cifdic_html/1/cif_core.dic/Cchemical_formula.html
    # (2009-06-25)
    #
    # 2. Dictionary of organic compounds By J. I. G. (John Ivan
    # George) Cadogan, American Chemical Society. Chemical Abstracts
    # Service, P. H. Rhodes, Steven V Ley; page 106 (found by Google
    # book search on 2009-06-25)

    my %formula = %$formula_hash; # make a copy, not to mess up the original
    my $formula = "";
    my $separator = "";

    if( exists $formula{C} ) {
        if( $formula{C} == 1 ) {
            $formula .= "C";
        } else {
            $formula .= "C" . sprint_number( $formula{C}, $format );
        }
        delete $formula{C};
        $separator = " ";
        if( exists $formula{H} ) {
            if( $formula{H} == 1 ) {
                $formula .= $separator . "H";
            } else {
                $formula .= $separator . "H" .
                    sprint_number( $formula{H}, $format );
            }
            delete $formula{H};
        }
    }
    for my $key (sort {$a cmp $b} keys %formula) {
        $formula .= $separator . $key .
            ($formula{$key} != 1 ?
             sprint_number( $formula{$key}, $format ) : "");
        $separator = " ";
    }

    return $formula;
}

1;
