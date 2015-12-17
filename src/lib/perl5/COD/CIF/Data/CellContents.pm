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

package COD::CIF::Data::CellContents;

use strict;
use warnings;
use COD::AtomProperties;
use COD::Fractional qw( symop_ortho_from_fract ) ;
use COD::Spacegroups::Symop::Parse qw( symop_from_string );
use COD::Formulae::Print qw( sprint_formula );
use COD::CIF::Data qw( get_cell get_symmetry_operators );
use COD::CIF::Data::AtomList qw( atom_array_from_cif );
use COD::CIF::Data::EstimateZ qw( cif_estimate_z );
use COD::CIF::Data::SymmetryGenerator qw( symop_generate_atoms );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    cif_cell_contents
    atomic_composition
    print_composition
);

$::format = "%g";

sub atomic_composition( $$$@ );
sub print_composition( $ );

sub cif_cell_contents( $$@ )
{
    my ($dataset, $user_Z, $use_attached_hydrogens,
        $assume_full_occupancies) = @_;

    my $values = $dataset->{values};

#   extracts atom site label or atom site type symbol.
#   The check is left only for error message/output compatibility,
#   since the actual extraction of site label tag is shifted to
#   CIFAtomList::atom_array_from_cif().
    if( !exists $values->{"_atom_site_label"} &&
        !exists $values->{"_atom_site_type_symbol"} ) {
        die 'ERROR, neither _atom_site_label nor _atom_site_type_symbol '
          . 'was found in the input file' . "\n";
    }

#   extracts cell constants
    my @unit_cell = get_cell( $values );

    my $ortho_matrix = symop_ortho_from_fract( @unit_cell );

#   extracts symmetry operators
    my $sym_data = get_symmetry_operators( $dataset );

#   extract atoms
    my $atoms = atom_array_from_cif( $dataset,
                                     { allow_unknown_chemical_types => 1,
                                       atom_properties =>
                                            \%COD::AtomProperties::atoms } );

#   compute symmetry operator matrices
    my @sym_operators = map { symop_from_string($_) } @{$sym_data};

    ## serialiseRef( \@sym_operators );

    my $sym_atoms =
        symop_generate_atoms( \@sym_operators, $atoms, $ortho_matrix );

    ## serialiseRef( $sym_atoms );

#   get the Z value

    my $Z;

    if( defined $user_Z ) {
        $Z = $user_Z;
        if( exists $values->{_cell_formula_units_z} ) {
            my $file_Z = $values->{_cell_formula_units_z}[0];
            if( $Z != $file_Z ) {
                warn "WARNING, overriding _cell_formula_units_Z ($file_Z) " .
                     "with command-line value $Z" . "\n";
            }
        }
    } else {
        if( exists $values->{_cell_formula_units_z} ) {
            $Z = $values->{_cell_formula_units_z}[0];
        } else {
            eval {
                $Z = cif_estimate_z( $dataset );
            };
            if( $@ ) {
                my $msg = $@;
                $msg =~ s/^ERROR, //;
                $msg =~ s/\n$//;
                $msg =~ s/;\n/; /g;
                $msg =~ s/\n/; /g;
                $Z = 1;
                warn "WARNING, $msg -- assuming Z = $Z" . "\n";
            } else {
                warn 'WARNING, _cell_formula_units_Z is missing -- '
                   . "assuming Z = $Z" . "\n";
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
        sprint_formula( \%composition, $::format );
}

sub atomic_composition($$$@)
{
    my ( $sym_atoms, $Z, $gp_multiplicity, $use_attached_hydrogens,
         $assume_full_occupancies ) = @_;
    $use_attached_hydrogens = 0 unless defined $use_attached_hydrogens;
    $assume_full_occupancies = 0 unless defined $assume_full_occupancies;
    my %composition;

    for my $atom ( @$sym_atoms ) { 
        my $occupancy = 
            defined $atom->{atom_site_occupancy} &&
            !$assume_full_occupancies &&
            $atom->{atom_site_occupancy} ne '.' &&
            $atom->{atom_site_occupancy} ne '?'
                ? $atom->{atom_site_occupancy} : 1;
        $occupancy =~ s/\(\d+\)\s*$//;

        my $attached_hydrogens = 0;
        if( exists $atom->{attached_hydrogens} &&
            $atom->{attached_hydrogens} ne '.' &&
            $atom->{attached_hydrogens} ne '?' ) {
            $attached_hydrogens = $atom->{attached_hydrogens};
        }
        my $hydrogen_amount =
            $occupancy * $atom->{multiplicity} * $attached_hydrogens;
        if( $hydrogen_amount > 0 && $use_attached_hydrogens ) {
            $composition{H} = 0 if !exists $composition{H};
            $composition{H} += $hydrogen_amount;
        }

        my $type = $atom->{chemical_type};

        next if $atom->{chemical_type} eq ".";

        my $amount = $occupancy  * $atom->{multiplicity};
        $composition{$type} += $amount;
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

    print_formula( $composition, $::format );
}

1;
