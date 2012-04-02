#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision: 1434 $
#$URL$
#------------------------------------------------------------------------------
#*
#  Classify a CIF structure -- find out if it is organic compound,
#  inorganic, mineral, etc.
#**

package CIFClassifyer;

use strict;
use warnings;

use SymopParse;
use Fractional;
use CIFData::CIFSymmetryGenerator;
use UserMessage;

require Exporter;
@CIFCellContents::ISA = qw(Exporter);
@CIFCellContents::EXPORT = qw(
    cif_has_C_H_bond
);

sub get_atoms($$$);

sub cif_has_C_H_bond($$$$)
{
    my ( $datablock, $filename, $atom_properties, $bond_safety_margin ) = @_;

    my $C_H_covalent_distance =
        $atom_properties->{"C"}{covalent_radius} +
        $atom_properties->{"H"}{covalent_radius} +
        $bond_safety_margin;

    my $atoms = get_atoms( $datablock, $filename, "_atom_site_label" );

    ## print $datablock->{name}, " ", int(@$atoms), "\n";

    ## use Serialise;
    ## serialiseRef( $atoms );


    my $symops =
        CIFSymmetryGenerator::get_symmetry_operators( $datablock, $filename );

    my @symop_matrices = map { symop_from_string($_) } @{$symops};

    my @cell =
        CIFSymmetryGenerator::get_cell( $datablock->{values}, $filename,
                                        $datablock->{name} );

    if( !@cell || !defined $cell[0] || @cell < 6 ) {
        return 0;
    }

    my $f2o = symop_ortho_from_fract(  @cell );

    ## use Serialise;
    ## serialiseRef( $symops );

    my $sym_atoms =
        CIFSymmetryGenerator::symop_generate_atoms( \@symop_matrices, 
                                                    $atoms, $f2o );

    ## use Serialise;
    ## serialiseRef( $sym_atoms );

    # Search for a C-H bond:

    for my $i (0..$#$atoms) {
        my $atom1 = $atoms->[$i];
        next unless $atom1->{atom_type} eq "C";
        for my $j ($i+1..$#$sym_atoms) {
            my $atom2 = $sym_atoms->[$j];
            next unless $atom2->{atom_type} eq "H";
            next if
                $atom1->{assembly} eq $atom2->{assembly} &&
                $atom1->{group} ne $atom2->{group};

            my $interatomic_distance =
                CIFSymmetryGenerator::distance( $atom1->{coordinates_ortho},
                                                $atom2->{coordinates_ortho} );

            if( $interatomic_distance < $C_H_covalent_distance ) {
                ## use Serialise;
                ## serialiseRef( [ $atom1, $atom2, $interatomic_distance,
                ##                 $C_H_covalent_distance  ] );
                return 1;
            }
        }
    }

    return 0;
}

# ============================================================================ #
# Gets atom descriptions, as used in this module, from a CIF datablock.
#
# Returns an array of
#
#   $atom_info = {
#                   atom_name => "C1_2",
#                   atom_type => "C",
#                   assembly  => "A", # "."
#                   group     => "1", # "."
#                   occupancy => 1.0,
#                   cif_multiplicity  => 96,
#                   coordinates_fract => [1.0, 1.0, 1.0],
#                   coordinates_ortho => [1.0, 1.0, 1.0],
#              }
#

sub get_atoms($$$)
{
    my ( $dataset, $filename, $loop_tag ) = @_;

    my $values = $dataset->{values};

    my @unit_cell =
        CIFSymmetryGenerator::get_cell( $values, $filename, $dataset->{name} );

    if( !@unit_cell || !defined $unit_cell[0] || @unit_cell < 6 ) {
        return;
    }

    my $ortho_matrix = symop_ortho_from_fract( @unit_cell );

    my @atoms;

    for my $i ( 0 .. $#{$values->{$loop_tag}} ) {

        my @fractional_coordinates_modulo_1 = 
            map { s/\(\d+\)\s*$//; modulo_1($_) }
            ( $values->{_atom_site_fract_x}[$i],
              $values->{_atom_site_fract_y}[$i],
              $values->{_atom_site_fract_z}[$i] );

        my $atom = {
            atom_name => $values->{$loop_tag}[$i],
            atom_type => exists $values->{_atom_site_type_symbol} ?
                $values->{_atom_site_type_symbol}[$i] : undef,
            coordinates_fract => \@fractional_coordinates_modulo_1,
        };

        if( !defined $atom->{atom_type} ) {
            $atom->{atom_type} = $atom->{atom_name};
        }

        if( $atom->{atom_type} =~ m/^([A-Za-z]{1,2})/ ) {
            $atom->{atom_type} = ucfirst( lc( $1 ));
        }

        $atom->{coordinates_ortho} =
            CIFSymmetryGenerator::mat_vect_mul( $ortho_matrix,
                                                $atom->{coordinates_fract} );

        if( defined $values->{_atom_site_occupancy} ) {
            if( $values->{_atom_site_occupancy}[$i] ne '?' &&
                $values->{_atom_site_occupancy}[$i] ne '.' ) {
                $atom->{occupancy} = $values->{_atom_site_occupancy}[$i];
                $atom->{occupancy} =~ s/\(\d+\)\s*$//;
            } else {
                $atom->{occupancy} = 1;
            }
        }

        if( defined $values->{_atom_site_symmetry_multiplicity} &&
            $values->{_atom_site_symmetry_multiplicity}[$i] ne '?' ) {
            $atom->{cif_multiplicity} =
                $values->{_atom_site_symmetry_multiplicity}[$i];
        }

        if( exists $values->{"_atom_site_disorder_assembly"}[$i]) {
            $atom->{"assembly"} =
                $values->{"_atom_site_disorder_assembly"}[$i];
        } else {
            $atom->{"assembly"} = ".";
        }

        if( exists $values->{"_atom_site_disorder_group"}[$i] ) {
            $atom->{"group"} = $values->{"_atom_site_disorder_group"}[$i];
        } else {
            $atom->{"group"} = ".";
        }

        push( @atoms, $atom );
    }

    return \@atoms;
}

1;
