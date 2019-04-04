#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Calculate unit cell contents from the atomic coordinates and
#  symmetry information in the CIF data structure returned by the
#  COD::CIF::Parser.
#**

package COD::CIF::Data::CellContents;

use strict;
use warnings;
use COD::AtomProperties;
use COD::Fractional qw( symop_ortho_from_fract ) ;
use COD::Spacegroups::Symop::Parse qw( symop_from_string
                                       symop_string_canonical_form );
use COD::Formulae::Print qw( sprint_formula );
use COD::CIF::Data qw( get_cell
                       get_formula_units_z
                       get_symmetry_operators );
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

#   extracts cell constants
    my @unit_cell = get_cell( $values );

    my $ortho_matrix = symop_ortho_from_fract( @unit_cell );

#   extracts symmetry operators
    my $sym_data = get_symmetry_operators( $dataset );

    # Create a list of symmetry operators:
    my $symop_list = { symops => [ map { symop_from_string($_) } @$sym_data ],
                       symop_ids => {} };
    for (my $i = 0; $i < @{$sym_data}; $i++) {
        $symop_list->{symop_ids}
                     {symop_string_canonical_form($sym_data->[$i])} = $i;
    }

#   extract atoms
    my $atoms = atom_array_from_cif( $dataset,
                                     { allow_unknown_chemical_types => 1,
                                       atom_properties =>
                                            \%COD::AtomProperties::atoms,
                                       symop_list => $symop_list } );

#   compute symmetry operator matrices
    my @sym_operators = map { symop_from_string($_) } @{$sym_data};

    ## serialiseRef( \@sym_operators );

    my $sym_atoms =
        symop_generate_atoms( \@sym_operators, $atoms,
                              { disregard_symmetry_independent_sites => 1 } );

    ## serialiseRef( $sym_atoms );

#   get the Z value

    my $Z;

    if( defined $user_Z ) {
        $Z = $user_Z;
    } else {
        my $warning;
        {
            local $SIG{__WARN__} = sub {
                $warning = $_[0];
                chomp $warning;
            };
            $Z = get_formula_units_z( $dataset );
        };

        if ( defined $warning ) {
            warn "WARNING, $warning -- the Z value will be estimated" . "\n";
        }

        if ( !defined $Z ) {
            eval {
                $Z = cif_estimate_z( $dataset );
            };
            if( $@ ) {
                my $msg = $@;
                $msg =~ s/^ERROR, //;
                $msg =~ s/\n$//;
                $Z = 1;
                warn "WARNING, $msg -- assuming Z = $Z" . "\n";
            } else {
                warn "WARNING, taking the estimated Z value Z = $Z" . "\n";
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
        $occupancy =~ s/\([0-9]+\)\s*$//;

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
