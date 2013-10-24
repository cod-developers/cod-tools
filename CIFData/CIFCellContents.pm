#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Calculate unit cell contents from the atomic coordinates and
#  symmetry information in the CIF data structure returned by the
#  CIFParser.
#**

package CIFCellContents;

use strict;
use warnings;
use Fractional;
use SymopParse;
use SymopLookup;
use Spacegroups::SpacegroupNames;
use Formulae::FormulaPrint;
use CIFData::CIFEstimateZ;
use CIFData::CIFSymmetryGenerator;
use UserMessage;

require Exporter;
@CIFCellContents::ISA = qw(Exporter);
@CIFCellContents::EXPORT = qw(
    cif_cell_contents
    get_symmetry_operators
    symop_generate_atoms
    atomic_composition
    print_composition
);

$::format = "%g";

sub atomic_composition( $$$@ );
sub print_composition( $ );
sub get_atoms( $$$ );

sub cif_cell_contents( $$$@ )
{
    my ($dataset, $filename, $user_Z, $use_attached_hydrogens,
        $assume_full_occupancies) = @_;

    my $values = $dataset->{values};

#   extracts atom site label or atom site type symbol
    my $loop_tag;

    if( exists $values->{"_atom_site_label"} ) {
        $loop_tag = "_atom_site_label";
    } elsif( exists $values->{"_atom_site_type_symbol"} ) {
        $loop_tag = "_atom_site_type_symbol";
    } else {
        error( $0, $filename, $dataset->{name},
               "neither _atom_site_label " .
               "nor _atom_site_type_symbol was found in the input file" );
        return undef;
    }

#   extracts cell constants
    my @unit_cell =
        CIFSymmetryGenerator::get_cell( $values, $filename, $dataset->{name} );

    my $ortho_matrix = symop_ortho_from_fract( @unit_cell );

#   extracts symmetry operators
    my $sym_data =
        CIFSymmetryGenerator::get_symmetry_operators( $dataset, $filename );

#   extract atoms
    my $atoms = get_atoms( $dataset, $filename, $loop_tag );

#   compute symmetry operator matrices
    my @sym_operators = map { symop_from_string($_) } @{$sym_data};

    ## serialiseRef( \@sym_operators );

    my $sym_atoms =
        CIFSymmetryGenerator::symop_generate_atoms( \@sym_operators, $atoms,
                                                    $ortho_matrix );

    ## serialiseRef( $sym_atoms );

#   get the Z value

    my $Z;

    if( defined $user_Z ) {
        $Z = $user_Z;
        if( exists $values->{_cell_formula_units_z} ) {
            my $file_Z = $values->{_cell_formula_units_z}[0];
            if( $Z != $file_Z ) {
                warning( $0, $filename, $dataset->{name},
                         "overriding _cell_formula_units_Z ($file_Z) " .
                         "with command-line value $Z" );
            }
        }
    } else {
        if( exists $values->{_cell_formula_units_z} ) {
            $Z = $values->{_cell_formula_units_z}[0];
        } else {
            eval {
                $Z = CIFEstimateZ::cif_estimate_z( $dataset );
            };
            if( $@ ) {
                my $msg = $@;
                $msg =~ s/\n$//;
                $msg =~ s/:\n/: /g;
                $msg =~ s/\n/; /g;
                $Z = 1;
                warning( $0, $filename, $dataset->{name},
                         "$msg -- " .
                         "assuming Z = $Z" );
            } else {
                warning( $0, $filename, $dataset->{name},
                         "_cell_formula_units_Z is missing -- " .
                         "assuming Z = $Z" );
            }
        }
    }

    my %composition = atomic_composition( $sym_atoms,
                                          $Z,
                                          int(@sym_operators),
                                          $use_attached_hydrogens,
                                          $assume_full_occupancies );

    ## print_composition( \%composition );

    wantarray ?
        %composition :
        FormulaPrint::sprint_formula( \%composition, $::format );
}

sub atomic_composition($$$@)
{
    my ( $sym_atoms, $Z, $gp_multiplicity, $use_attached_hydrogens,
         $assume_full_occupancies ) = @_;
    $use_attached_hydrogens = 0 unless defined $use_attached_hydrogens;
    $assume_full_occupancies = 0 unless defined $assume_full_occupancies;
    my %composition;

    for my $atom ( @$sym_atoms ) { 
        my $type = $atom->{atom_type};
        my $occupancy = 
            defined $atom->{occupancy} && !$assume_full_occupancies
                ? $atom->{occupancy} : 1;
        my $amount = $occupancy  * $atom->{multiplicity};
        $composition{$type} += $amount;
        my $hydrogen_amount =
            $occupancy * $atom->{multiplicity} * $atom->{attached_hydrogens};
        if( $hydrogen_amount > 0 && $use_attached_hydrogens ) {
            $composition{H} = 0 if !exists $composition{H};
            $composition{H} += $hydrogen_amount;
        }
    }

    my $abundance_ration = $Z * $gp_multiplicity;

    for my $type ( keys %composition ) {
        $composition{$type} /= $abundance_ration;
    }

    return wantarray ? %composition : \%composition;
}

sub print_composition($)
{
    my ( $composition ) = @_;

    ## for my $key ( sort { $a cmp $b } keys %$composition ) {
    ##     print "$key: ", $composition->{$key}, "\n";
    ## }

    FormulaPrint::print_formula( $composition, $::format );
}

# ============================================================================ #
# Gets atom descriptions, as used in this module, from a CIF datablock.
#
# Returns an array of
#
#   $atom_info = {
#                   atom_name => "C1_2",
#                   atom_type => "C",
#                   occupancy => 1.0,
#                   cif_multiplicity  => 96,
#                   coordinates_fract => [1.0, 1.0, 1.0],
#                   coordinates_ortho => [1.0, 1.0, 1.0],
#              }
#

sub get_atoms( $$$ )
{
    my ( $dataset, $filename, $loop_tag ) = @_;

    my $values = $dataset->{values};

    my @unit_cell =
        CIFSymmetryGenerator::get_cell( $values, $filename, $dataset->{name} );
    my $ortho_matrix = symop_ortho_from_fract( @unit_cell );

    my @atoms;

    for my $i ( 0 .. $#{$values->{$loop_tag}} ) {
        my $atom = {
            atom_name => $values->{$loop_tag}[$i],
            atom_type => exists $values->{_atom_site_type_symbol} ?
                $values->{_atom_site_type_symbol}[$i] : undef,
            coordinates_fract => [
                $values->{_atom_site_fract_x}[$i],
                $values->{_atom_site_fract_y}[$i],
                $values->{_atom_site_fract_z}[$i]
            ],
            attached_hydrogens =>
                exists $values->{_atom_site_attached_hydrogens} &&
                $values->{_atom_site_attached_hydrogens}[$i] ne '.' &&
                $values->{_atom_site_attached_hydrogens}[$i] ne '?'
                    ? $values->{_atom_site_attached_hydrogens}[$i] : 0,
        };

        if( !defined $atom->{atom_type} ) {
            $atom->{atom_type} = $atom->{atom_name};
        }

        if( $atom->{atom_type} =~ m/^([A-Za-z]{1,2})/ ) {
            $atom->{atom_type} = ucfirst( lc( $1 ));
        }

        @{$atom->{coordinates_fract}} = map { s/\(\d+\)\s*$//; $_ }
            @{$atom->{coordinates_fract}};

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

        push( @atoms, $atom );
    }

    return \@atoms;
}

1;
