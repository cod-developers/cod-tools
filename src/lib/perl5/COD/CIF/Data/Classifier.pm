#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Classify a CIF structure -- find out if it is organic compound,
#  inorganic, mineral, etc.
#**

package COD::CIF::Data::Classifier;

use strict;
use warnings;
use COD::CIF::Data qw( get_cell get_symmetry_operators );
use COD::CIF::Data::AtomList qw( atom_array_from_cif );
use COD::CIF::Data::SymmetryGenerator qw( symop_generate_atoms );
use COD::Fractional qw( symop_ortho_from_fract );
use COD::Spacegroups::Symop::Algebra qw( symop_vector_mul );
use COD::Spacegroups::Symop::Parse qw( symop_from_string
                                       modulo_1
                                       symop_string_canonical_form );
use COD::Algebra::Vector qw( distance
                             matrix_vector_mul
                             vdot
                             vector_sub );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    cif_class_flags
    cif_has_C_bonds
);

sub get_atoms( $$ );

sub length_of_fractional_vector( $$ );
sub distance_fractional( $$$ );

my $has_C_H_bond_flag = "has_C_H_bond";
my $has_C_C_bond_flag = "has_C_C_bond";

my $too_close_distance = 0.3; # Angstroems

sub cif_class_flags( $$$ )
{
    my ( $datablock, $atom_properties, $bond_safety_margin ) = @_;

    my @flags = ();

    @flags = cif_has_C_bonds
        ( $datablock, $atom_properties, $bond_safety_margin );

    return wantarray ? sort @flags : join( ",", sort @flags );
}

sub cif_has_C_bonds( $$$$ )
{
    my ( $datablock, $atom_properties, $bond_safety_margin ) = @_;

    my %flags; # accumulate flags that will be returned

    my $C_H_covalent_distance =
        $atom_properties->{"C"}{covalent_radius} +
        $atom_properties->{"H"}{covalent_radius} +
        $bond_safety_margin;

    my $C_C_covalent_distance =
        $atom_properties->{"C"}{covalent_radius} * 2 +
        $bond_safety_margin;

    my $symops = get_symmetry_operators( $datablock );

    my @symop_matrices = map { symop_from_string($_) } @{$symops};

    # Create a list of symmetry operators:
    my $symop_list = { symops => [ map { symop_from_string($_) } @$symops ],
                       symop_ids => {} };
    for (my $i = 0; $i < @{$symops}; $i++) {
        $symop_list->{symop_ids}
                     {symop_string_canonical_form($symops->[$i])} = $i;
    }

    my $atoms = atom_array_from_cif( $datablock,
                                     { symop_list => $symop_list } );

    ## print $datablock->{name}, " ", int(@$atoms), "\n";

    ## use COD::Serialise qw( serialiseRef );
    ## serialiseRef( $atoms );

    ## use COD::Serialise qw( serialiseRef );
    ## serialiseRef( $symops );

    my @cell = get_cell( $datablock->{values} );

    if( !@cell || !defined $cell[0] || @cell < 6 ) {
        return 0;
    }

    my $f2o = symop_ortho_from_fract(  @cell );

    my $g = metric_tensor_from_cell( @cell );

    ## use COD::Serialise qw( serialiseRef );
    ## serialiseRef( $g );

    my $sym_atoms = symop_generate_atoms( \@symop_matrices, $atoms );

    ## use COD::Serialise qw( serialiseRef );
    ## serialiseRef( $sym_atoms );

    # Search for a C-H or C-C bond:

    for my $i (0..$#$atoms) {
        my $atom1 = $atoms->[$i];
        next unless $atom1->{chemical_type} eq "C";

        # First, let's try bonds with untranslated symmetry equivalent
        # atoms, since they are the most probable -- asymmetric units
        # usually contain atoms that are close to each other in a
        # molecule:
        for my $j ($i+1..$#$sym_atoms) {
            my $atom2 = $sym_atoms->[$j];
            next unless
                $atom2->{chemical_type} eq "H" ||
                $atom2->{chemical_type} eq "C";
            next if
                $atom1->{assembly} eq $atom2->{assembly} &&
                $atom1->{group} ne $atom2->{group} &&
                $atom1->{group} ne '.' && $atom2->{group} ne '.';

            my $interatomic_distance =
                distance( $atom1->{coordinates_ortho},
                          $atom2->{coordinates_ortho} );

            next if $interatomic_distance < $too_close_distance;

            ## my $distance = distance_fractional( $atom1->{coordinates_fract},
            ##                                     $atom2->{coordinates_fract},
            ##                                     $g );
            ##
            ## print ">>> $interatomic_distance, $distance\n"
            ##     if abs($interatomic_distance - $distance) > 1E-6;

            if( $atom2->{chemical_type} eq "H" &&
                $interatomic_distance < $C_H_covalent_distance ) {
                ## print ">>> found C-H bond $interatomic_distance " .
                ##     "$atom1->{atom_name}-$atom2->{atom_name}\n";
                ## use COD::Serialise qw( serialiseRef );
                ## serialiseRef( [ $atom1, $atom2, $interatomic_distance,
                ##                 $C_H_covalent_distance  ] );
                $flags{$has_C_H_bond_flag} = 1;
                return keys %flags if int(keys %flags) >= 2;
            }
            if( $atom2->{chemical_type} eq "C" &&
                $interatomic_distance < $C_C_covalent_distance ) {
                ## print ">>> found C-C bond $interatomic_distance \n";
                ## use COD::Serialise qw( serialiseRef );
                ## serialiseRef( [ $atom1, $atom2, $interatomic_distance,
                ##                 $C_H_covalent_distance  ] );
                $flags{$has_C_C_bond_flag} = 1;
                return keys %flags if int(keys %flags) >= 2;
            }
        }
        # If we did not find bond to untranslated atoms, let's try
        # +/-1 translation:
        for my $j (0..$#$sym_atoms) {
            my $atom2 = $sym_atoms->[$j];
            next unless
                $atom2->{chemical_type} eq "H" ||
                $atom2->{chemical_type} eq "C";
            next if
                $atom1->{assembly} eq $atom2->{assembly} &&
                $atom1->{group} ne $atom2->{group} &&
                $atom1->{group} ne '.' && $atom2->{group} ne '.';

            for my $dx (-1, 0, 1) {
            for my $dy (-1, 0, 1) {
            for my $dz (-1, 0, 1) {
                my @shifted_fractionals = ( $atom2->{coordinates_fract}[0] + $dx,
                                            $atom2->{coordinates_fract}[1] + $dy,
                                            $atom2->{coordinates_fract}[2] + $dz );

                my $distance = distance_fractional( $atom1->{coordinates_fract},
                                                    \@shifted_fractionals,
                                                    $g );

                next if $distance < $too_close_distance;

                if( $atom2->{chemical_type} eq "H" &&
                    $distance < $C_H_covalent_distance ) {
                    ## use COD::Serialise qw( serialiseRef );
                    ## serialiseRef( [ $atom1, $atom2, $interatomic_distance,
                    ##                 $C_H_covalent_distance  ] );
                    $flags{$has_C_H_bond_flag} = 1;
                    return keys %flags if int(keys %flags) >= 2;
                }
                if( $atom2->{chemical_type} eq "C" &&
                    $distance < $C_C_covalent_distance ) {
                    ## use COD::Serialise qw( serialiseRef );
                    ## serialiseRef( [ $atom1, $atom2, $interatomic_distance,
                    ##                 $C_H_covalent_distance  ] );
                    $flags{$has_C_C_bond_flag} = 1;
                    return keys %flags if int(keys %flags) >= 2;
                }
            }}}
        }
    }

    return keys %flags;
}

my $Pi = 4 * atan2(1,1);

sub metric_tensor_from_cell
{
    my @cell = @_;
    my ($a, $b, $c) = @cell[0..2];
    my ($alpha, $beta, $gamma) = map {$Pi * $_ / 180} @cell[3..5];
    my ($ca, $cb, $cg) = map {cos} ($alpha, $beta, $gamma);

    my $g = [
        [ $a * $a, $a * $b * $cg, $a * $c * $cb ],
        [ 0,       $b * $b,       $b * $c * $ca ],
        [ 0,             0,       $c * $c ]
        ];

    $g->[1][0] = $g->[0][1];
    $g->[2][0] = $g->[0][2];
    $g->[2][1] = $g->[1][2];

    return $g;
}

sub length_of_fractional_vector( $$ )
{
    my ( $v, $g ) = @_;
    return vdot( $v, matrix_vector_mul( $g, $v ));
}

sub distance_fractional( $$$ )
{
    my ( $v1, $v2, $g ) = @_;
    return sqrt( length_of_fractional_vector( vector_sub($v1, $v2), $g ));
}

1;
