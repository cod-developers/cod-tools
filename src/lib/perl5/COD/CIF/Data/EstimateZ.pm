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
use COD::CIF::Data::CellContents qw( cif_cell_contents );
use COD::CIF::Tags::Manage qw( get_aliased_value );
use COD::Formulae::Parser::IUCr;
use COD::Precision qw( unpack_cif_number );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    cif_estimate_z
    cif_estimate_z_from_formula
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

    undef $volume if defined $volume && $volume eq '?';
    undef $density if defined $density && $density eq '?';
    undef $mol_mass if defined $mol_mass && $mol_mass eq '?';

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

##
# Tries to estimate the most likely Z value from the formula_sum
# provided in the CIF data block and from the atom contents of the
# CIF.
#
# @param $dataset
#       Reference to a data block as returned by the COD::CIF::Parser.
#
# @param $options
#       Reference to a hash of options. The following options are recognised:
#         'use_attached_hydrogens'
#                       Add hydrogen counts specified in the
#                       _atom_site_attached_hydrogens to the total hydrogen
#                       number.
#         'assume_full_occupancies'
#                       Assume that all atoms have occupancy 1.0 instead of
#                       relying on the _atom_site_occupancy value
# @return
#        The calculated Z number.
##
sub cif_estimate_z_from_formula
{
    my ($dataset, $options) = @_;

    my $use_attached_hydrogens =
        exists $options->{use_attached_hydrogens} ?
               $options->{use_attached_hydrogens} : 0;

    my $assume_full_occupancies =
        exists $options->{assume_full_occupancies} ?
               $options->{assume_full_occupancies} : 0;

    my $values = $dataset->{values};

    if (!defined $values->{_chemical_formula_sum}) {
        die "no '_chemical_formula_sum' given\n";
    }

    my $cif_formula = $values->{_chemical_formula_sum}[0];

    $cif_formula =~ s/\n/ /g;
    $cif_formula =~ s/^\s+|\s+$//g;

    my $parser = COD::Formulae::Parser::IUCr->new;
    my %cif_formula = %{$parser->ParseString( $cif_formula )};

    my %cell_formula = cif_cell_contents ( $dataset,
                                           1, # $Z_value
                                           $use_attached_hydrogens,
                                           $assume_full_occupancies );

    do {
        require Data::Dumper;
        print Data::Dumper::Dumper( \%cif_formula );
        print Data::Dumper::Dumper( \%cell_formula );
    } if 0;

    # Compute the ratio of the computed whole-cell formula (atomic
    # composition) and the declared formula. If most (i.e. consensus)
    # atom counts have the same ratio, this ratio will be declared as
    # Z; otherwise the subroutine will fail:

    my %atom_ratios;
    my %ratio_counts;

    for my $atom_name (keys %cell_formula) {
        if( exists $cif_formula{$atom_name} ) {
            my $ratio =
                $cell_formula{$atom_name} / $cif_formula{$atom_name};
            $atom_ratios{$atom_name} = $ratio;
            $ratio_counts{$ratio} ++;
        }
    }

    # Check the atom count consensus:

    my $max_ratio_count = 0;
    my $most_popular_ratio;
    for my $ratio (keys %ratio_counts) {
        if( $max_ratio_count < $ratio_counts{$ratio} ) {
            $max_ratio_count = $ratio_counts{$ratio};
            $most_popular_ratio = $ratio;
        }
    }

    do {
        require Data::Dumper;
        print Data::Dumper::Dumper( \%atom_ratios );
        print Data::Dumper::Dumper( \%ratio_counts );
    } if 0;

    my $Z;

    my $number_of_atoms = int(keys %atom_ratios);

    if( $max_ratio_count > $number_of_atoms / 2 ) {
        # Consensus is reached, the most popular ratio is present
        # for more than half atom types:
        $Z = $most_popular_ratio;
    } else {
        die "only $max_ratio_count out of $number_of_atoms atoms " .
            "have ratio $most_popular_ratio, and other ratios are " .
            "even less frequent -- cannot estimate Z from formula " .
            "'$cif_formula'\n";
    }

    return $Z;
}

1;
