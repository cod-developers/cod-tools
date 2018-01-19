#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Estimate Z-value using CIF-provided crystal density, cell volume
#  and molecular weight, if they are present.
#
#  The exported functions in this module accept CIF internal
#  representation data structure as produced by COD::CIF::Parser module.
#**

package COD::CIF::Data::EstimateZ;

use strict;
use warnings;
use COD::Cell qw( cell_volume );
use COD::CIF::Data qw( get_cell );
use COD::Precision qw( unpack_cif_number );
use COD::CIF::Tags::Manage qw( get_aliased_value );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    cif_estimate_z
);

# Avogadro number in "CIF unit" scale:
my $N = 0.1 * 6.0221418;

sub cif_estimate_z($)
{
    my ($dataset) = @_;
    my $values = $dataset->{values};

    my $volume  = get_volume( $values );
    my $density = get_crystal_density( $values );
    my $molwt   = get_molecular_weight( $values );

    if( defined $volume && defined $density && defined $molwt ) {
        return int( 0.5 + $N * $density * $volume / $molwt );
    } else {
        my $error = '';
        my $sep = '; ';
        if( !defined $volume ) {
            $error .= $sep . 'cell volume undefined';
        }
        if( !defined $density ) {
             $error .= $sep . 'crystal density undefined';
        }
        if( !defined $molwt ) {
            $error .= $sep . 'molecular weight undefined';
        }
        die 'ERROR, not enough data to estimate Z' . "$error" . "\n";
    }
}

sub get_crystal_density
{
    my ($values) = @_;

    my $density = get_aliased_value( $values,
            [ qw(
                _exptl_crystal_density_diffrn
                _exptl_crystal.density_diffrn
                _exptl_crystal.density_Matthews
                _exptl_crystal_density_meas
            ) ]
    );

    if (defined $density) {
        $density = unpack_cif_number( $density );
    }

    return $density;
}

sub get_molecular_weight
{
    my ($values) = @_;

    my $weight = get_aliased_value( $values,
            [ qw(
                _chemical_formula_weight
                _chemical_formula.weight
                _chemical_formula_weight_meas
                _chemical_formula.weight_meas
            ) ]
    );

    if ( defined $weight ) {
        $weight =  unpack_cif_number( $weight );
    }

    return $weight;
}

sub get_volume
{
    my ($values) = @_;

    my $volume;
    if( defined $values->{_cell_volume} ) {
        $volume = unpack_cif_number( $values->{_cell_volume}[0] );
    } else {
        eval {
            my @cell = get_cell( $values );
            $volume = cell_volume( @cell );
        };
        if ($@) {
            $@ =~ s/^ERROR, //;
            warn "WARNING, not enough data to estimate cell volume -- $@";
        }
    }

    return $volume;
}

1;
