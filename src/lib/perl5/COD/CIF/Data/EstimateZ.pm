#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Estimate Z-value using CIF-provided crystal density, cell volume
#  and molecular mass, if they are present.
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

##
# Calculates the Z number from the information given in a CIF data block.
#
# @param $dataset
#       Reference to a data block as returned by the COD::CIF::Parser.
# @param $options
#       Reference to a hash of options. The following options are recognised:
#         'cell_volume'
#                       Volume of the crystal unit cell in cubic angstroms.
#                       Overrides data provided in the CIF data block.
#         'crystal_density'
#                       Density of the crystal in grams per cubic centimetre.
#                       Overrides data provided in the CIF data block.
#         'molecular_mass'
#                       Mass of the crystal unit cell in daltons.
#                       Overrides data provided in the CIF data block.
# @return
#        The calculated Z number.
##
sub cif_estimate_z
{
    my ($dataset, $options) = @_;

    my $values = $dataset->{values};

    $options = {} if !defined $options;
    my $volume   = ( exists $options->{'cell_volume'} ) ?
                            $options->{'cell_volume'} :
                            get_volume( $values );
    my $density  = ( exists $options->{'crystal_density'} ) ?
                            $options->{'crystal_density'} :
                            get_crystal_density( $values );
    my $mol_mass = ( exists $options->{'molecular_mass'} ) ?
                            $options->{'molecular_mass'} :
                            get_molecular_weight( $values );

    if( defined $volume && defined $density && defined $mol_mass ) {
        return int( 0.5 + $N * $density * $volume / $mol_mass );
    } else {
        my $error = '';
        my $sep = '; ';
        if( !defined $volume ) {
            $error .= $sep . 'cell volume undefined';
        }
        if( !defined $density ) {
             $error .= $sep . 'crystal density undefined';
        }
        if( !defined $mol_mass ) {
            $error .= $sep . 'molecular weight undefined';
        }
        die 'ERROR, not enough data to estimate Z' . "$error" . "\n";
    }

    return;
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
