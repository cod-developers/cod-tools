#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------
#* 
#  Prepare 3-D "bricks" (i.e. atoms indexed into integer-numbered
#  blocks of 3-D space) for fast atom neighbour search.
#**

package AtomBricks;

use strict;

require Exporter;
@AtomBricks::ISA = qw(Exporter);
@AtomBricks::EXPORT = qw();

my $debug = 0;

#==============================================================================#
# Find minimal and maximal coordinate values in an atom list

sub get_min_max_atom_coordinates($)
{
    my ($atoms) = @_;

    my ( $min_x, $max_x, $min_y, $max_y, $min_z, $max_z );    

    for my $atom (@$atoms) {
        my ( $x, $y, $z ) = @{$atom->{coordinates_ortho}};
        if( !defined $min_x || $min_x > $x ) {
            $min_x = $x;
        }
        if( !defined $max_x || $max_x < $x ) {
            $max_x = $x;
        }
        if( !defined $min_y || $min_y > $y ) {
            $min_y = $y;
        }
        if( !defined $max_y || $max_y < $y ) {
            $max_y = $y;
        }
        if( !defined $min_z || $min_z > $z ) {
            $min_z = $z;
        }
        if( !defined $max_z || $max_z < $z ) {
            $max_z = $z;
        }
    }
    return ( $min_x, $max_x, $min_y, $max_y, $min_z, $max_z );
}

#==============================================================================#
# Given a "brick" structure with a cutoff distance, minimum and
# maximum coordinates inside, and an atom orthogonal coordinates,
# calculated idices of the brick in which this atom is in.

sub get_atom_index($@)
{
    my ( $bricks, $x, $y, $z ) = @_;

    my $distance = $bricks->{distance};

    my $i = int(($x - $bricks->{min_x})/$distance);
    my $j = int(($y - $bricks->{min_y})/$distance);
    my $k = int(($z - $bricks->{min_z})/$distance);

    return ( $i, $j, $k );
}

#==============================================================================#
# Given a "brick" structure and three indices of an atom, return spans
# of indices that can contain neighbours of a given atom.

sub get_search_span($@)
{
    my ( $bricks, $i, $j, $k ) = @_;

    my $nx = $bricks->{nx};
    my $ny = $bricks->{ny};
    my $nz = $bricks->{nz};

    my ( $min_i, $max_i ) = ( $i - 1, $i + 1 );
    my ( $min_j, $max_j ) = ( $j - 1, $j + 1 );
    my ( $min_k, $max_k ) = ( $k - 1, $k + 1 );

    die( "assertion '\$i >=0 && \$i < \$nx (\$nx == $nx)' failed on \$i == $i" )
        unless $i >= 0 && $i < $nx;
    die( "assertion '\$j >=0 && \$j < \$ny (\$ny == $ny)' failed on \$j == $j" )
        unless $j >= 0 && $j < $ny;
    die( "assertion '\$k >=0 && \$k < \$nz (\$nz == $nz)' failed on \$k == $k" )
        unless $k >= 0 && $k < $nz;

    $min_i = 0 if $min_i < 0;
    $min_j = 0 if $min_j < 0;
    $min_k = 0 if $min_k < 0;

    $max_i = $nx - 1 unless $max_i < $nx;
    $max_j = $ny - 1 unless $max_j < $ny;
    $max_k = $nz - 1 unless $max_k < $nz;

    return ( $min_i, $max_i, $min_j, $max_j, $min_k, $max_k );
}

#==============================================================================#
# Create a 3D array of "bricks" that contain atoms in the specific
# region of the 3D space; the neighbour search will then only need to
# consider atoms from the neighbouring bricks.

sub build_bricks($$)
{
    my ($atoms, $distance) = @_;

    my ( $min_x, $max_x, $min_y, $max_y, $min_z, $max_z ) =
        get_min_max_atom_coordinates( $atoms );

    # numbers of bricks in directions x, y, and z, respectively:
    my $nx = int(($max_x - $min_x)/$distance) + 1;
    my $ny = int(($max_y - $min_y)/$distance) + 1;
    my $nz = int(($max_z - $min_z)/$distance) + 1;

    do {
        print ">>> $min_x, $max_x, $distance, $nx\n";
        print ">>> $min_y, $max_y, $distance, $ny\n";
        print ">>> $min_z, $max_z, $distance, $nz\n";
    } if( $debug > 5 );

    # Create a 4-D rray, indexable with i, j, k, and atom_number:

    my $brick_array = [];

    for my $i (0..$nx) {
        push( @{$brick_array}, [] );
        for my $j (0..$ny) {
            push( @{$brick_array->[$i]}, [] );
            for my $k (0..$nz) {
                push( @{$brick_array->[$i][$j]}, [] );
            }
        }
    }

    # create the "bricks" structure:

    my $bricks = {
        distance => $distance,
        nx => $nx, ny => $ny, nz => $nz,
        max_x => $max_x, min_x => $min_x,
        max_y => $max_y, min_y => $min_y,
        max_z => $max_z, min_z => $min_z,
        atoms => $brick_array,
    };

    # distribute atom references into bricks:

    for my $atom (@$atoms) {
        ## my ( $x, $y, $z ) = @{$atom->{coordinates_ortho}};
        ## my $i = int(($x - $min_x)/$distance);
        ## my $j = int(($y - $min_y)/$distance);
        ## my $k = int(($z - $min_z)/$distance);
        my ( $i, $j, $k ) =
            get_atom_index( $bricks, @{$atom->{coordinates_ortho}} );
        print ">>> $atom->{label}, $i, $j, $k\n" if $debug > 4;
        ## print ">>> ", ref $bricks->{atoms}[$i][$j][$k], "\n";
        push( @{$bricks->{atoms}[$i][$j][$k]}, $atom )
    }

    do {
        my $i = int(@{$bricks->{atoms}} / 2);
        my $j = int(@{$bricks->{atoms}[$i]} / 2);

        for my $k ( 0..$#{$bricks->{atoms}[$i][$j]} ) {
            print ">> $i, $j, $k, ",
            int( @{$bricks->{atoms}[$i][$j][$k]} ), "\n";
        }
        ## exit( -1 );
    } if( $debug > 3 );

    return $bricks;
}

1;
