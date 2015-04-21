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
use COD::Spacegroups::SymopLookup;
use COD::Spacegroups::SpacegroupNames;
use COD::Spacegroups::VectorAlgebra;
use COD::UserMessage;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    get_cell
    get_symmetry_operators
    symop_generate_atoms
    mat_vect_mul
    distance
);
our @EXPORT_OK = qw( copy_atom );

my %sg_name_abbrev =
    map { my $key = $_->[1]; $key =~ s/\s+//g; ( $key, $_->[2] ) }
    @COD::Spacegroups::SpacegroupNames::names,
    map { [ $_->{number}, $_->{hermann_mauguin}, $_->{universal_h_m} ] }
    @COD::Spacegroups::SymopLookup::table,
    @COD::Spacegroups::SymopLookup::extra_settings;


my $special_position_cutoff = 0.01; # Angstroems
# Atoms related by symmetry operators that are more distant than the
# $special_position_cutoff are considered different and not belonging
# to the same special position. All symmetry equivalent atoms that
# (after appropriate translations) are closer to the original atom
# than $special_position_cutoff are considered to be the same atom on
# a special position.

sub get_cell($$$);
sub get_symmetry_operators($$);
sub symop_generate_atoms($$$);
sub copy_atom($);
sub copy_array($);
sub mat_vect_mul($$);

#===============================================================#
# Calculates distance between two given vectors.

# Accepts two arrays of vectors coordinates_fract.

# Returns a distance.

sub distance($$)
{
    my($vector1, $vector2) = @_;
    my $dist = 0;

    for(my $k = 0; $k < @{$vector1}; $k++)
    {
        $dist += (${$vector1}[$k] - ${$vector2}[$k])**2;
    }
    return sqrt($dist);
}

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
        my $new_coord = mat_vect_mul( $symop, $atom->{coordinates_fract} );
        $new_atom->{coordinates_fract} =
            [ map { modulo_1($_) } @{$new_coord} ];
        $new_atom->{coordinates_ortho} =
            mat_vect_mul( $f2o, $new_atom->{coordinates_fract} );
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

    my $old_xyz = mat_vect_mul( $f2o, $old_coord );

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
        my $new_xyz = mat_vect_mul( $f2o, $shifted_coord );
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
# @COD::Spacegroups::SymopLookup::table =
# (
# {
#     number          => 1,
#     hall            => ' P 1',
#     schoenflies     => 'C1^1',
#     hermann_mauguin => 'P 1',
#     universal_h_m   => 'P 1',
#     symops => [
#         'x,y,z',
#     ],
#     ncsym => [
#         'x,y,z',
#     ]
# },
# );

sub lookup_symops
{
    my ($option, $param) = @_;

    $param =~ s/ //g;
    $param =~ s/_//g;

    my $sg_full = $sg_name_abbrev{$param};

    $sg_full = "" unless defined $sg_full;
    $sg_full =~ s/\s+//g;

    foreach my $hash (@COD::Spacegroups::SymopLookup::table,
                      @COD::Spacegroups::SymopLookup::extra_settings)
    {
        my $value = $hash->{$option};
        $value =~ s/ //g;
        $value =~ s/_//g;

        if( $value eq $param || $value eq $sg_full )
        {
            return $hash->{symops};
        }
    }
    return undef;
}

#===============================================================#
# Extract unit cell angles and lengths.

# Accepts
#     values - a hash where a data from the CIF file is stored
# Returns
#     cell_lengths_and_angles - an array  with stored information.

sub get_cell($$$)
{
    my( $values, $filename, $dataname ) = @_;

    my @cell_lengths_and_angles;

    for my $cif_tag (qw(_cell_length_a
                        _cell_length_b
                        _cell_length_c
                        ))
    {
        if( exists $values->{$cif_tag} ) {
            push(@cell_lengths_and_angles, $values->{$cif_tag}[0]);
            $cell_lengths_and_angles[-1] =~ s/\(\d+\)$//;
        } else {
            error( $0, $filename, $dataname,
                   "cell length '$cif_tag' not present" );
        }
    }

    for my $cif_tag (qw(_cell_angle_alpha
                        _cell_angle_beta
                        _cell_angle_gamma
                        ))
    {
        if( exists $values->{$cif_tag} ) {
            push( @cell_lengths_and_angles, $values->{$cif_tag}[0] );
            $cell_lengths_and_angles[-1] =~ s/\(\d+\)$//;
        } else {
            warning( $0, $filename, $dataname,
                     "cell angle '$cif_tag' not present -- " .
                     "taking default value 90 degrees" );
            push( @cell_lengths_and_angles, 90 );
        }
    }

    return @cell_lengths_and_angles;
}

sub get_symmetry_operators($$)
{
    my ( $dataset, $filename ) = @_;

    my $values = $dataset->{values};

    my $sym_data;

    if( exists $values->{"_space_group_symop_operation_xyz"} ) {
        $sym_data = $values->{"_space_group_symop_operation_xyz"};
    } elsif( exists $values->{"_symmetry_equiv_pos_as_xyz"} ) {
        $sym_data = $values->{"_symmetry_equiv_pos_as_xyz"};
    }

    if( !defined $sym_data ) {
        for my $tag (qw( _space_group_name_Hall
                         _space_group_name_hall
                         _symmetry_space_group_name_Hall 
                         _symmetry_space_group_name_hall 
                     )) {
            if( exists $values->{$tag} ) {
                my $hall = $values->{$tag}[0];
                next if $hall eq '?';
                $sym_data = lookup_symops("hall", $hall);

                if( !$sym_data ) {
                    error( $0, $filename, $dataset->{name},
                           "$tag value '$hall' is not recognised" );
                } else {
                    last
                }
            }
        }
    }

    if( !defined $sym_data ) {
        for my $tag (qw( _space_group_name_H-M_alt
                         _space_group_name_h-m_alt
                         _space_group.name_H-M_full
                         _space_group.name_h-m_full
                         _symmetry_space_group_name_H-M
                         _symmetry_space_group_name_h-m
                    )) {
            if( exists $values->{$tag} ) {
                my $h_m = $values->{$tag}[0];
                next if $h_m eq '?';
                $sym_data = lookup_symops("hermann_mauguin", $h_m);

                if( !$sym_data ) {
                    error( $0, $filename, $dataset->{name},
                           "$tag value '$h_m' is not recognised" );
                } else {
                    last
                }
            }
        }
    }

    if( not defined $sym_data ) {
        for my $tag (qw( _space_group_ssg_name
                         _space_group_ssg_name_IT
                         _space_group_ssg_name_WJJ
                    )) {
            if( exists $values->{$tag} ) {
                my $ssg_name = $values->{$tag}[0];
                next if $ssg_name eq '?';

                my $h_m = $ssg_name;
                $h_m =~ s/\(.*//g;
                $h_m =~ s/[\s_]+//g;

                $sym_data = lookup_symops("hermann_mauguin", $h_m);

                if( !$sym_data ) {
                    error( $0, $filename, $dataset->{name},
                           "$tag value '$ssg_name' yielded H-M " .
                           "symbol '$h_m' which is not in our tables" );
                } else {
                    last
                }
            }
        }
    }

    if( not defined $sym_data ) {
        error( $0, $filename, $dataset->{name},
               "neither symmetry operators, " .
               "nor Hall spacegroup symbol, " .
               "nor Hermann-Mauguin spacegroup symbol could be processed" );
        die;
    }

    return $sym_data;
}

#======================================================================#
# Multiplies an ortho matrix with a vector. If the matrix is 3x4 (rows
# x columns), it assumes that the 4-th column is a translation vector
# and adds it to the result vector, thus implementing 3D symmetry
# operators.
#
# Examples of matrices:
#
# my $ortho = [
#     [ o11 o12 o13 ]
#     [ 0   o22 o23 ]
#     [ 0   0   o33 ]
# ]
#
# my $symop = [
#     [ o11 o12 o13 t1 ]
#     [ 0   o22 o23 t2 ]
#     [ 0   0   o33 t3 ]
# ]
#

sub mat_vect_mul($$)
{
    return &symop_vector_mul;
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
