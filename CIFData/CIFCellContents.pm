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
use Formulae::FormulaPrint;

require Exporter;
@CIFCellContents::ISA = qw(Exporter);
@CIFCellContents::EXPORT = qw(
    cif_cell_contents
    get_cell
    get_symmetry_operators
    symop_generate_atoms
    atomic_composition
    print_composition
);

$::format = "%g";
my $special_position_cutoff = 0.001;

sub get_cell($$$);
sub get_symmetry_operators($$);
sub symop_generate_atoms($$$);
sub copy_atom($);
sub copy_array($);
sub mat_vect_mul($$);
sub atomic_composition($$$);
sub print_composition($);

sub print_error($$$$$)
{
    my ( $program, $filename, $datablock, $errlevel, $message ) = @_;

    print STDERR $program, ": ", $filename,
    defined $datablock ? " data_" . $datablock : "",
    defined $errlevel ? ": " . $errlevel : "",
    ": ", $message, ".\n";
}

sub error($$$$)
{
    my ( $program, $filename, $datablock, $message ) = @_;
    print_error( $program, $filename, $datablock, "ERROR", $message );
}

sub warning($$$$)
{
    my ( $program, $filename, $datablock, $message ) = @_;
    print_error( $program, $filename, $datablock, "WARNING", $message );
}

sub cif_cell_contents($$$)
{
    my ($dataset, $filename, $user_Z) = @_;

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
    my @unit_cell = CIFCellContents::get_cell( $values, $filename,
					       $dataset->{name} );
    my $ortho_matrix = symop_ortho_from_fract( @unit_cell );

#   extracts symmetry operators
    my $sym_data = get_symmetry_operators( $dataset, $filename );

#   extract atoms
    my $atoms = get_atoms( $dataset, $filename, $loop_tag );

#   compute symmetry operator matrices
    my @sym_operators = map { symop_from_string($_) } @{$sym_data};

    ## serialiseRef( \@sym_operators );

    my $sym_atoms = symop_generate_atoms( \@sym_operators, $atoms,
					  $ortho_matrix );

    ## serialiseRef( $sym_atoms );

#   get the Z value

    my $Z;

    if( defined $user_Z ) {
        $Z = $user_Z;
        if( exists $values->{_cell_formula_units_Z} ) {
            my $file_Z = $values->{_cell_formula_units_Z}[0];
            if( $Z != $file_Z ) {
                warning( $0, $filename, $dataset->{name},
                         "overriding _cell_formula_units_Z ($file_Z) " .
                         "with command-line value $Z" );
            }
        }
    } else {
        if( exists $values->{_cell_formula_units_Z} ) {
            $Z = $values->{_cell_formula_units_Z}[0];
        } else {
            $Z = 1;
            warning( $0, $filename, $dataset->{name},
                     "_cell_formula_units_Z is missing -- assuming Z = $Z" );
        }
    }

    my %composition = atomic_composition( $sym_atoms, $Z, int(@sym_operators));

    ## print_composition( \%composition );

    wantarray ?
	%composition :
	FormulaPrint::sprint_formula( \%composition, $::format );
}

sub atomic_composition($$$)
{
    my ( $sym_atoms, $Z, $gp_multiplicity ) = @_;
    my %composition;

    for my $atom ( @$sym_atoms ) { 
	my $type = $atom->{atom_type};
	my $occupancy = defined $atom->{occupancy} ? $atom->{occupancy} : 1;
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

    FormulaPrint::print_formula( $composition, $::format );
}

#===============================================================#
# Tests if a symmetry operator is   (1, 0, 0, 0)
#                                   (0, 1, 0, 0)
#                                   (0, 0, 1, 0)
#                                   (0, 0, 0, 1)

sub symop_is_unity($)
{
    my($symop) = @_;
    my $eps = 1e-10;

    for(my $i = 0; $i < @{$symop}; $i++)
    {
        for(my $j = 0; $j < @{$symop}; $j++)
        {
            if($i == $j)
            {
                if(abs(${$symop}[$i][$j] - 1) > $eps) {
                    return 0;
                }
            }
            else
            {
                if(abs(${$symop}[$i][$j] - 0) > $eps) {
                    return 0;
                }
            }
        }
    }
    return 1;
}

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
    my $new_coord = mat_vect_mul( $symop, $atom->{coordinates_fract} );

    $new_atom->{coordinates_fract} = [ map { modulo_1($_) } @{$new_coord} ];

    if( $n != 0 ) {
        $new_atom->{atom_name} .= "_" . $n;
    }

    $new_atom->{coordinates_ortho} =
	mat_vect_mul( $f2o, $new_atom->{coordinates_fract} );

    ## serialiseRef( $new_atom );

    return $new_atom;
}

#===============================================================#

sub atoms_coincide($$$)
{
    my ( $old_atom, $new_atom, $f2o ) = @_;

    my $old_coord = [ map { modulo_1($_) } @{$old_atom->{coordinates_fract}} ];
    my $old_xyz = mat_vect_mul( $f2o, $old_coord );

    my $new_coord = [ map { modulo_1($_) } @{$new_atom->{coordinates_fract}} ];

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
	     "multiplicity of a general position $gp_multiplicity" .
             "-- this can not be." );
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
# @SymopLookup::table =
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

    foreach my $hash (@SymopLookup::table)
    {
        my $value = $hash->{$option};
        $value =~ s/ //g;
        $value =~ s/_//g;

        if($value eq $param)
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
		   "cell angle '$cif_tag' not present" );
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
                     "taking default value 90 degress." );
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

    if( exists $values->{"_symmetry_equiv_pos_as_xyz"}) {
        $sym_data = $values->{"_symmetry_equiv_pos_as_xyz"};
    }

    if( ( exists $values->{"_symmetry_space_group_name_Hall"} ||
	  exists $values->{"_symmetry_space_group_name_Hall"} )&&
	not defined $sym_data ) {
        my $hall = $values->{"_symmetry_space_group_name_Hall"}[0];
	$hall = $values->{"_symmetry_space_group_name_hall"}[0] unless $hall;
        $sym_data = lookup_symops("hall", $hall);

        if( !$sym_data ) {
            error( $0, $filename, $dataset->{name},
		   "_symmetry_space_group_name_Hall value '$hall' is " .
		   "not recognised" );
        } 
    }

    if( ( exists $values->{"_symmetry_space_group_name_H-M"} ||
	  exists $values->{"_symmetry_space_group_name_h-m"} ) &&
	not defined $sym_data ) {
        my $h_m = $values->{"_symmetry_space_group_name_H-M"}[0];
        $h_m = $values->{"_symmetry_space_group_name_h-m"}[0] unless $h_m;
        $sym_data = lookup_symops("hermann_mauguin", $h_m);

        if( !$sym_data ) {
            error( $0, $filename, $dataset->{name},
		   "_symmetry_space_group_name_H-M value '$h_m' is " .
		   "not recognised" );
            die;
        }
    }

    if( not defined $sym_data ) {
        error( $0, $filename, $dataset->{name},
	       "neither _symmetry_equiv_pos_as_xyz " .
	       "nor _symmetry_space_group_name_Hall " .                  
	       "nor _symmetry_space_group_name_H-M could be processed" );
        die;
    }

    return $sym_data;
}

#===============================================================#
# Multiplies an ortho matrix with a vector.

# my $ortho = [
#     [ o11 o12 o13 ]
#     [ 0   o22 o23 ]
#     [ 0   0   o33 ]
# ]
#

sub mat_vect_mul($$)
{
    my($matrix, $vector) = @_;

    my @new_coordinates;

    for(my $i = 0; $i < @{$vector}; $i++)
    {
        $new_coordinates[$i] = 0;
        for(my $j = 0; $j < @{$vector}; $j++)
        {
            $new_coordinates[$i] += ${$matrix}[$i][$j] * ${$vector}[$j];
        }
    }

    if( @$vector == 3 && @$matrix == 4 ) {
	$new_coordinates[0] += $matrix->[0][3];
	$new_coordinates[1] += $matrix->[1][3];
	$new_coordinates[2] += $matrix->[2][3];
    }

    return \@new_coordinates;
}

sub get_atoms
{
    my ( $dataset, $filename, $loop_tag ) = @_;

    my $values = $dataset->{values};

    my @unit_cell = get_cell( $values, $filename, $dataset->{name} );
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
	    mat_vect_mul( $ortho_matrix, $atom->{coordinates_fract} );

	if( defined $values->{_atom_site_occupancy} ) {
	    if( $values->{_atom_site_occupancy}[$i] ne '?' ) {
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
