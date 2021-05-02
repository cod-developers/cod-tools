#------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------
#*
#  Functions for printing chemical formulas in a formated way.
#**

package COD::Formulae::Print;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    sprint_formula
    print_formula
);

sub print_formula($@)
{
    my ( $formula_hash, $format ) = @_;

    my $formula_string = sprint_formula( $formula_hash, $format );

    print $formula_string, "\n";
}

sub sprint_number($$)
{
    my ( $number, $format ) = @_;

    $number = sprintf $format, $number if defined $format;

    if( $number eq '1' ) {
        return '';
    } else {
        return $number;
    }
}

sub sprint_formula($@)
{
    my ( $formula_hash, $format ) = @_;

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
    my $formula = '';
    my $separator = '';

    if( exists $formula{C} ) {
        $formula .= 'C' . sprint_number( $formula{C}, $format );
        delete $formula{C};
        $separator = ' ';
        if( exists $formula{H} ) {
            $formula .= $separator . 'H' .
                        sprint_number( $formula{H}, $format );
            delete $formula{H};
        }
    }
    for my $key (sort {$a cmp $b} keys %formula) {
        $formula .= $separator . $key .
                    sprint_number( $formula{$key}, $format );
        $separator = ' ';
    }

    return $formula;
}

1;
