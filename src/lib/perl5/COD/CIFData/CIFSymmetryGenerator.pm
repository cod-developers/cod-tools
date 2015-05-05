#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision: 1551 $
#$URL$
#------------------------------------------------------------------------------
#*
#  Calculate unit cell contents from the atomic coordinates and
#  symmetry information in the CIF data structure returned by the
#  CIFParser.
#**

package COD::CIFData::CIFSymmetryGenerator;

use strict;
use warnings;
use COD::Spacegroups::SymopAlgebra qw(symop_is_unity symop_vector_mul);
use COD::Spacegroups::SymopParse;
use COD::Spacegroups::SpacegroupNames;
use COD::Spacegroups::VectorAlgebra qw(distance);
use COD::UserMessage;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    atoms_coincide
    copy_atom
    symop_generate_atoms
    test_bond
    test_bump
);

my $special_position_cutoff = 0.01; # Angstroems
# Atoms related by symmetry operators that are more distant than the
# $special_position_cutoff are considered different and not belonging
# to the same special position. All symmetry equivalent atoms that
# (after appropriate translations) are closer to the original atom
# than $special_position_cutoff are considered to be the same atom on
# a special position.

sub atoms_coincide($$$);
sub symop_generate_atoms($$$);
sub test_bond($$$$$);
sub test_bump($$$$$$$);
sub copy_atom($);
sub copy_array($);

#===============================================================#

sub symop_apply_to_atom_mod1($$$$)
{
    my ( $symop, $atom, $n, $f2o ) = @_;

    my $new_atom = copy_atom( $atom );

    if( $n != 0 ) {
        $new_atom->{atom_name} .= "_" . $n;
    }

    if( $atom->{coordinates_fract}[0] ne "." and
        $atom->{coordinates_fract}[1] ne "." and
        $atom->{coordinates_fract}[2] ne "." ) {
        my $new_coord = symop_vector_mul( $symop,
                                          $atom->{coordinates_fract} );
        $new_atom->{coordinates_fract} =
            [ map { modulo_1($_) } @{$new_coord} ];
        $new_atom->{coordinates_ortho} =
            symop_vector_mul( $f2o, $new_atom->{coordinates_fract} );
    }

    ## serialiseRef( $new_atom );

    return $new_atom;
}

#===============================================================#

sub atoms_coincide($$$)
{
    my ( $old_atom, $new_atom, $f2o ) = @_;

    if( $old_atom->{coordinates_fract}[0] eq "." or
        $old_atom->{coordinates_fract}[1] eq "." or
        $old_atom->{coordinates_fract}[2] eq "." ) {
        return 0;
    }

    my $old_coord = [ map { modulo_1($_) }
                      @{$old_atom->{coordinates_fract}} ];

    my $old_xyz = symop_vector_mul( $f2o, $old_coord );

    my $new_coord = [ map { modulo_1($_) }
                      @{$new_atom->{coordinates_fract}} ];

    for my $dx (-1, 0, 1) {
    for my $dy (-1, 0, 1) {
    for my $dz (-1, 0, 1) {
        my $shifted_coord = [
            $new_coord->[0] + $dx,
            $new_coord->[1] + $dy,
            $new_coord->[2] + $dz,
        ];
        my $new_xyz = symop_vector_mul( $f2o, $shifted_coord );
        if( distance( $new_xyz, $old_xyz ) < $special_position_cutoff ) {
            ## local $, = ", ";
            ## print ">>> mapped to self: @{$new_xyz} / @{$old_xyz}\n";
            return 1;
        }
    }}}

    return 0;
}

#===============================================================#

sub symgen_atom($$$)
{
    my ( $sym_operators, $atom, $f2o ) = @_;

    my @sym_atoms;

    my $gp_multiplicity = int(@$sym_operators);
    my $multiplicity_ratio = 1;

    my $n = 1;

    for my $symop ( @{$sym_operators} ) {
        my $new_atom = symop_apply_to_atom_mod1( $symop, $atom, 0, $f2o );
        if( !symop_is_unity( $symop ) &&
            atoms_coincide( $atom, $new_atom, $f2o )) {
            $multiplicity_ratio ++;
        }
        push( @sym_atoms, $new_atom );
    }

    ## print ">>> $gp_multiplicity / $multiplicity_ratio\n";

    if( $gp_multiplicity % $multiplicity_ratio ) {
        die( "Multiplicity ratio $multiplicity_ratio does not divide " .
             "multiplicity of a general position $gp_multiplicity " .
             "- this should not happen" );
    }

    my $multiplicity = $gp_multiplicity / $multiplicity_ratio;

    for my $atom (@sym_atoms) {
        $atom->{multiplicity} = $multiplicity;
        $atom->{multiplicity_ratio} = $multiplicity_ratio;
    }

    return @sym_atoms;
}

#===============================================================#

sub symop_generate_atoms($$$)
{
    my ( $sym_operators, $atoms, $f2o ) = @_;

    my @sym_atoms;

    for my $atom ( @{$atoms} ) {
        push( @sym_atoms, symgen_atom( $sym_operators, $atom, $f2o ));
    }

    return \@sym_atoms;
}

#===============================================================#
# Made a decision if a chemical bond exists.
#
# Accepts a pair of chemical types, distance between atoms and a reference
# to a hash of atom properties
# %atoms = (
#           H => { #(chemical_type)
#                     name => Hydrogen,
#                     period => 1,
#                     group => 1,
#                     block => s,
#                     atomic_number => "1",
#                     atomic_weight => 1.008,
#                     covalent_radius => 0.23,
#                     vdw_radius => 1.09,
#                     valency => [1],
#                     },
#          );

sub test_bond($$$$$)
{
    my ($atom_properties, $chemical_type1, $chemical_type2, $distance,
        $covalent_sensitivity) = @_;

    my $cov_radius1 = $atom_properties->{$chemical_type1}->{covalent_radius};
    my $cov_radius2 = $atom_properties->{$chemical_type2}->{covalent_radius};

    if($distance < $cov_radius1 + $cov_radius2 + $covalent_sensitivity)
    {
        return 1;
    }

    return 0;
}

#===============================================================#
# Makes a decision if atoms are too close to each other, i.e if they
# make a "bump":
#
# Accepts a pair of atom labels, their chemical types and distance between
# them as well as a reference to a hash of atom properties
# %atoms = (
#           H => { #(chemical_type)
#                     name => Hydrogen,
#                     period => 1,
#                     group => 1,
#                     block => s,
#                     atomic_number => "1",
#                     atomic_weight => 1.008,
#                     covalent_radius => 0.23,
#                     vdw_radius => 1.09,
#                     valency => [1],
#                     },
#          );

sub test_bump($$$$$$$)
{
    my ( $atom_properties, $chemical_type1, $chemical_type2,
         $atom1_label, $atom2_label,
         $dist, $bump_factor ) = @_;

    my $cov_radius1 = $atom_properties->{$chemical_type1}->{covalent_radius};
    my $cov_radius2 = $atom_properties->{$chemical_type2}->{covalent_radius};

    if( $dist < $bump_factor * ($cov_radius1 + $cov_radius2) &&
        ($dist > $special_position_cutoff ||
         $atom1_label ne $atom2_label)) {
        return 1;
    }

    return 0;
}

#===============================================================#
# Copies atom and returns the same instance of it (different object, same props)

# Accepts a hash $atom_info = {
#                       label=>"C1_2",
#                       label_basename=>"C1",
#                       chemical_type=>"C",
#                       coordinates_fract=>[1.0, 1.0, 1.0],
#                       coordinates_ortho=>[5.0, -1.3, 1.7],
#                       unity_matrix_applied=>1,
#                       symop_id=>1
#                       assembly=>"A", # "."
#                       group=>"1", # "."
#                       }

# Returns a hash $new_atom_info = {
#                       label=>"C1_2",
#                       label_basename=>"C1",
#                       chemical_type=>"C",
#                       coordinates_fract=>[1.0, 1.0, 1.0],
#                       coordinates_ortho=>[5.0, -1.3, 1.7],
#                       unity_matrix_applied=>1,
#                       symop_id=>1,
#                       assembly=>"A", # "."
#                       group=>"1", # "."
#                       }

sub copy_atom($)
{
    my($old_atom) = @_;

    my %new_atom;

    for my $key (keys %$old_atom ) {
        if( !ref $old_atom->{$key} ) {
            $new_atom{$key} = $old_atom->{$key};
        } elsif( ref $old_atom->{$key} eq "ARRAY" ) {
            $new_atom{$key} = copy_array($old_atom->{$key});
        } else {
            die( "assertion failed: 'copy_atom' does not know how to " .
                 "copy the supplied object" );
        }
    }

    return \%new_atom;
}

sub copy_array($)
{
    my ($arr) = @_;

    my @copy_arr;
    foreach my $value (@$arr)
    {
        push(@copy_arr, $value);
    }

    return \@copy_arr;
}

1;
