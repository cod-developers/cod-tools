#------------------------------------------------------------------------------
#$Author: saulius $
#$Date: 2010-01-19 17:12:06 +0200 (Tue, 19 Jan 2010) $ 
#$Revision: 1071 $
#$URL: svn+ssh2224://vartai.ibt.lt/home/xray/svn-repositories/cif-tools/trunk/CIFData/CIFCellContents.pm $
#------------------------------------------------------------------------------
#*
#  Estimate Z-value using CIF-provided crystal density, cell volume
#  and molecular weight, if they are present.
#
#  The exported functions in this module accept CIF internal
#  representation data structure as produced by CIFParser module.
#**

package CIFEstimateZ;

use strict;
use warnings;

require Exporter;
@CIFCellContents::ISA = qw(Exporter);
@CIFCellContents::EXPORT = qw(
    cif_estimate_z
);

# Avogadro number in "CIF unit" scale:
my $N = 0.1 * 6.0221418;

sub cif_estimate_z($)
{
    my ($dataset) = @_;
    my $values = $dataset->{values};

    if( defined $values ) {

        my $volume = get_volume( $values );
        my $density = get_crystal_density( $values );
        my $molwt = get_molecular_weight( $values );

        if( defined $volume && defined $density && defined $molwt ) {
            return int( 0.5 + $N * $density * $volume / $molwt ), "\n";
        } else {
            my $error = "";
            if( !defined $volume ) {
                $error .= "cell volume undefined in '$dataset->{name}'\n";
            }
            if( !defined $density ) {
                 $error .= "crystal density undefined in '$dataset->{name}'\n";
            }
            if( !defined $molwt ) {
                $error .= "molecular weight undefined in '$dataset->{name}'\n";
            }
            die "not enough data in '$dataset->{name}' to estimate Z:\n" . $error;
        }
    }
}

sub get_crystal_density
{
    my $values = shift;

    for my $tag (qw(
                _exptl_crystal_density_diffrn
                _exptl_crystal.density_diffrn
                _exptl_crystal.density_Matthews
                _exptl_crystal_density_meas
             )) {
        if( exists $values->{$tag} ) {
            my $density = $values->{$tag}[0];
            $density =~ s/\(\d*\)$//;
            return $density;
        }
    }
    return undef;
}

sub get_molecular_weight
{
    my $values = shift;

    for my $tag (qw(
                _chemical_formula_weight
                _chemical_formula.weight
                _chemical_formula_weight_meas
                _chemical_formula.weight_meas
             )) {
        if( exists $values->{$tag} ) {
            my $wt = $values->{$tag}[0];
            $wt =~ s/\(\d*\)$//;
            return $wt;
        }
    }
    return undef;
}

sub get_volume
{
    my $values = shift;

    if( defined $values->{_cell_volume} ) {
        my $volume = $values->{_cell_volume}[0];
        $volume =~ s/\(\d*\)$//;
        return $volume;
    } else {
        if( defined $values->{_cell_length_a} &&
            defined $values->{_cell_length_b} &&
            defined $values->{_cell_length_c} ) {
            my @cell = get_unit_cell( $values );
            return calculate_cell_volume( @cell );
        } else {
            return undef
        }
    }
    return undef
}

sub get_unit_cell
{
    my $values = $_[0];

    return (
	$values->{_cell_length_a}[0],
	$values->{_cell_length_b}[0],
	$values->{_cell_length_c}[0],
	defined $values->{_cell_angle_alpha} ?
            $values->{_cell_angle_alpha}[0] : 90,
	defined $values->{_cell_angle_beta} ?
            $values->{_cell_angle_beta}[0] : 90,
	defined $values->{_cell_angle_gamma} ?
            $values->{_cell_angle_gamma}[0] : 90
    );
}

sub calculate_cell_volume
{
    my @cell = map { s/\(.*\)//g; $_ } @_;

    my $Pi = 4 * atan2(1,1);

    my ($a, $b, $c) = @cell[0..2];
    my ($alpha, $beta, $gamma) = map {$Pi * $_ / 180} @cell[3..5];
    my ($ca, $cb, $cg) = map {cos} ($alpha, $beta, $gamma);
    my $sg = sin($gamma);
    
    my $V = $a * $b * $c * sqrt( $sg**2 - $ca**2 - $cb**2 + 2*$ca*$cb*$cg );

    return $V;
}

1;
