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

package COD::CIF::Data::SymmetryGenerator;

use strict;
use warnings;
use COD::Algebra::Vector qw( distance );
use COD::CIF::Data::AtomList qw( copy_atom );
use COD::Formulae::Print qw( sprint_formula );
use COD::Spacegroups::Symop::Algebra qw( flush_zeros_in_symop
                                         symop_is_unity
                                         symop_modulo_1
                                         symop_mul
                                         symop_vector_mul );
use COD::Spacegroups::Symop::Parse qw( modulo_1
                                       string_from_symop
                                       symop_string_canonical_form );
use COD::Spacegroups::Names;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    apply_shifts
    atoms_coincide
    chemical_formula_sum
    symop_apply_modulo1
    symop_apply_NO_modulo_1
    symop_generate_atoms
    symop_register_applied_symop
    test_bond
    test_bump
    translate_atom
    translation
    trim_polymer
);

my $special_position_cutoff = 0.01; # Angstroems
# Atoms related by symmetry operators that are more distant than the
# $special_position_cutoff are considered different and not belonging
# to the same special position. All symmetry equivalent atoms that
# (after appropriate translations) are closer to the original atom
# than $special_position_cutoff are considered to be the same atom on
# a special position.

sub apply_shifts($);
sub atoms_coincide($$$);
sub chemical_formula_sum($@);
sub symop_apply_modulo1($$@);
sub symop_apply_NO_modulo_1($$@);
sub symop_generate_atoms($$$);
sub symop_register_applied_symop($$@);
sub test_bond($$$$$);
sub test_bump($$$$$$$);
sub translate_atom($$);
sub translation($$);
sub trim_polymer($$);

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
        die "ERROR, multiplicity ratio '$multiplicity_ratio' does not divide "
          . "multiplicity of a general position '$gp_multiplicity' -- "
          . "this should not happen\n";
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
# Applies symmetry operator to a given atom.

# The symop_apply_modulo1 subroutine accepts a reference to a hash
# $atom_info = {name=>"C1_2",
#               site_label=>"C1"
#               chemical_type=>"C",
#               coordinates_fract=>[1.0, 1.0, 1.0],
#               unity_matrix_applied=>1} and
# a reference to an array - symmetry operator
# my $symop = [
#     [ r11 r12 r13 t1 ]
#     [ r21 r22 r23 t1 ]
#     [ r31 r32 r33 t1 ]
#     [   0   0   0  1 ]
# ],
# Returns an above-mentioned hash.
#
sub symop_apply_modulo1($$@)
{
    my( $atom_info, $symop, $symop_id, $expand_to_p1 ) = @_;

    my $new_atom_info = copy_atom( $atom_info );

    my $atom_xyz = $atom_info->{coordinates_fract};

    my @new_atom_xyz =
        map { modulo_1($_) }
            @{ symop_vector_mul( $symop, $atom_xyz ) };

    $new_atom_info->{coordinates_fract} = \@new_atom_xyz;

    return symop_register_applied_symop( $new_atom_info, $symop,
                                         $symop_id, $expand_to_p1 );
}

#===============================================================#
# Applies symmetry operator to a given atom, without applying a
# modulo_1 shift.
#

# The symop_apply_NO_modulo_1 subroutine accepts a reference to a hash:

# $atom_info = {site_label=>"C1",
#               name=>"C1_2",
#               chemical_type=>"C",
#               coordinates_fract=>[1.0, 1.0, 1.0],
#               unity_matrix_applied=>1} 

# and a reference to an array - symmetry operator

# my $symop = [
#     [ r11 r12 r13 t1 ]
#     [ r21 r22 r23 t1 ]
#     [ r31 r32 r33 t1 ]
#     [   0   0   0  1 ]
# ],

# Returns an above-mentioned hash.

# The difference from the symop_apply_modulo1() subroutine is that it does not
# apply the mod1 shift.

sub symop_apply_NO_modulo_1($$@)
{
    my( $atom_info, $symop, $symop_id, $expand_to_p1 ) = @_;

    my $new_atom_info = copy_atom( $atom_info );

    my $atom_xyz = $atom_info->{coordinates_fract};

    my $new_atom_xyz = symop_vector_mul( $symop, $atom_xyz );

    $new_atom_info->{coordinates_fract} = $new_atom_xyz;

    return symop_register_applied_symop( $new_atom_info, $symop,
                                         $symop_id, $expand_to_p1 );
}

#===============================================================#

sub symop_register_applied_symop($$@)
{
    my( $new_atom_info, $symop, $symop_id, $expand_to_p1 ) = @_;

    if( defined $symop_id ) {
        $new_atom_info->{symop} = $symop;
        $new_atom_info->{symop_id} = $symop_id;
        $new_atom_info->{unity_matrix_applied} =
            symop_is_unity($symop);
    } else {
        my $symop_now = symop_mul( $new_atom_info->{symop}, $symop );
        my $symop_string =
            symop_string_canonical_form(
                string_from_symop(
                    flush_zeros_in_symop(
                        symop_modulo_1( $symop_now ) ) ) );

        $new_atom_info->{symop} = $symop_now;
        $new_atom_info->{symop_id} =
            $new_atom_info->{symop_list}
                            {symop_ids}
                            {$symop_string} + 1;
        $new_atom_info->{unity_matrix_applied} =
            symop_is_unity( $symop_now );
    }

    my $atom_xyz = $new_atom_info->{coordinates_fract};

    $new_atom_info->{coordinates_ortho} =
        symop_vector_mul( $new_atom_info->{f2o}, $atom_xyz );

    my @translation = (
        int($atom_xyz->[0] - modulo_1($atom_xyz->[0])),
        int($atom_xyz->[1] - modulo_1($atom_xyz->[1])),
        int($atom_xyz->[2] - modulo_1($atom_xyz->[2])),
    );
    $new_atom_info->{translation} =
        \@translation;
    $new_atom_info->{translation_id} =
        (5+$translation[0]) . (5+$translation[1]) . (5+$translation[2]);

    if( $new_atom_info->{unity_matrix_applied} &&
        $new_atom_info->{translation_id} eq "555" ) {
        $new_atom_info->{name} = $new_atom_info->{site_label};
    } else {
        $new_atom_info->{name} =
            $new_atom_info->{site_label} . "_" .
            $new_atom_info->{symop_id} . "_" .
            $new_atom_info->{translation_id};
    }

    $new_atom_info->{cell_label} = $new_atom_info->{site_label};
    if( $expand_to_p1 && !$new_atom_info->{unity_matrix_applied} ) {
        $new_atom_info->{cell_label} .= '_' . $new_atom_info->{symop_id};
    }

    do {
        use COD::Serialise qw( serialiseRef );
        serialiseRef( { atom => $new_atom_info, symop => $symop } );
    } if 0;

    return $new_atom_info;
}

#===============================================================#
# Shifts a given atom according shifting params. If shifting params are
# (-1, 0, 1) then 27 shifts are made.
#
# Accepts:
#    $atom      A reference to an atom information hash. An example of
#               the atom information hash:
#               {
#                    site_label => 'C1',
#                    name       => 'C1_2',
#                    chemical_type  => 'C',
#                    coordinates_fract => [1.0, 1.0, 1.0],
#                    unity_matrix_applied => 1
#               }
#
# Returns:
#   @atoms      An array of references of the atom information hashes that
#               were constructed from the original atom information hash.
sub shift_atom($)
{
    my ( $atom ) = @_;

    my @shifted_atoms;
    my @shift = ( 0, -1, 1 );

    foreach my $x ( @shift ) {
    foreach my $y ( @shift ) {
    foreach my $z ( @shift ) {
        my $new_atom = copy_atom($atom);
        $new_atom->{'translation'} = [ $x, $y, $z ];
        my @new_atom_xyz;
        if( $x != 0 || $y != 0 || $z != 0 ||
            $atom->{'unity_matrix_applied'} != 1) {

            $new_atom_xyz[0] = $atom->{'coordinates_fract'}[0] + $x;
            $new_atom_xyz[1] = $atom->{'coordinates_fract'}[1] + $y;
            $new_atom_xyz[2] = $atom->{'coordinates_fract'}[2] + $z;

            my $shift_label = ( $x + 5 ) . ( $y + 5 ) . ( $z + 5 );

            $new_atom->{'coordinates_fract'} = \@new_atom_xyz;
            $new_atom->{'coordinates_ortho'} =
                        symop_vector_mul( $atom->{'f2o'}, \@new_atom_xyz );
            $new_atom->{'name'} =
                        $atom->{'site_label'} . "_" .
                        $atom->{'symop_id'} . "_" .
                        $shift_label;
            $new_atom->{'translation_id'} = $shift_label;
        }
        push @shifted_atoms, $new_atom;
    } } }

    return @shifted_atoms;
}

#===============================================================#
# Generates atoms of surrounding cells by shifting atoms in 27 possible
# ways in 3D space. Atom name is updated to include the shift.
#
# @param $atoms
#       Reference to an array of atoms data structures as described in
#       'shift_atom'.
#
# @returns $shifted
#       Reference to an array of shifted atoms.
##

sub apply_shifts($)
{
    my ($atoms) = @_;

    my @shifted = ();

    for my $atom (@{$atoms}) {
        push( @shifted, shift_atom( $atom ));
    }

    return \@shifted;
}

#==============================================================#
# Translates an atom according a given translation.
#
# Accepts an atom description and a translation.
#
# Returns a translated atom.

sub translate_atom($$)
{
    my($atom, $translation) = @_;

    my $new_atom = copy_atom( $atom );
    my @new_atom_xyz;

    push( @new_atom_xyz, $atom->{'coordinates_fract'}[0] +
          ${$translation}[0] );
    push( @new_atom_xyz, $atom->{'coordinates_fract'}[1] +
          ${$translation}[1] );
    push( @new_atom_xyz, $atom->{'coordinates_fract'}[2] +
          ${$translation}[2] );

    $new_atom->{'coordinates_fract'} = \@new_atom_xyz;
    $new_atom->{coordinates_ortho} =
        symop_vector_mul( $atom->{f2o}, \@new_atom_xyz );

    $new_atom->{translation} = [
        $new_atom_xyz[0] - modulo_1($new_atom_xyz[0]),
        $new_atom_xyz[1] - modulo_1($new_atom_xyz[1]),
        $new_atom_xyz[2] - modulo_1($new_atom_xyz[2]),
    ];

    $new_atom->{translation_id} =
        ($new_atom->{translation}[0]+5).
        ($new_atom->{translation}[1]+5).
        ($new_atom->{translation}[2]+5);

    if( defined $new_atom->{unity_matrix_applied} &&
                $new_atom->{unity_matrix_applied} &&
                $new_atom->{translation}[0] == 0 &&
                $new_atom->{translation}[1] == 0 &&
                $new_atom->{translation}[2] == 0 ) {
        $new_atom->{name} = $new_atom->{site_label};
    } else {
        $new_atom->{name} =
            $new_atom->{site_label} . "_" .
            $new_atom->{symop_id} . "_" .
            $new_atom->{translation_id};
    }

    return $new_atom;
}

#==============================================================#
# Finds translation center of mass and center of mass modulo 1 information.

# Accepts two arrays of coordinates_fract.

# Returns an array of differences between coordinates_fract.

sub translation($$)
{
    my ($coords, $coords_modulo_1) = @_;

    my @translation;
    for( my $i = 0; $i < @{$coords}; $i++ ) {
        push @translation, ${$coords}[$i] - ${$coords_modulo_1}[$i];
    }

    return \@translation;
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
# Finds a molecule chemical formula sum.

# Accepts an array of atoms:
# $atom =      {name=>"C1_2",
#               chemical_type=>"C",
#               coordinates_fract=>[1.0, 1.0, 1.0],
#               unity_matrix_applied=>1}

# Returns a string with chemical formula sum.

sub chemical_formula_sum($@)
{
    my ($atoms, $Z) = @_;

    $Z = 1 unless defined $Z;

    my %chemical_types;

    foreach my $atom (@{$atoms}) {
        my $chemical_type = $atom->{chemical_type};
        next if $chemical_type eq '.';
        $chemical_types{$chemical_type} = 0
            if !defined $chemical_types{$chemical_type};
        $chemical_types{$chemical_type}++
    }

    for my $chemical_type (keys %chemical_types) {
        $chemical_types{$chemical_type} /= $Z;
    }

    my $formula_sum = sprint_formula( \%chemical_types );
    $formula_sum =~ s/\s$//;

    return $formula_sum;
}

#===============================================================#
# Trim a polymer -- remove atoms outside of the specified polymer
# span:

sub trim_polymer($$)
{
    my ($atoms, $max_polymer_span) = @_;

    my @trimmed_atoms;

    for my $atom (@$atoms) {
        if( abs($atom->{translation}[0]) <= $max_polymer_span &&
            abs($atom->{translation}[1]) <= $max_polymer_span &&
            abs($atom->{translation}[2]) <= $max_polymer_span ) {
            push( @trimmed_atoms, $atom );
        }
    }

    return \@trimmed_atoms;
}

1;
