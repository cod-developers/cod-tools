#--*-perl-*-------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#-----------------------------------------------------------------------
#*
# Performs Gauss-Jordan elimination on a matrix.
#**

package COD::Algebra::GaussJordan;
use strict;
use warnings;
require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    backward_elimination
    forward_elimination
    gj_elimination_non_zero_elements
);

# Run the G-J elimination process, return a reduced echelon form
# matrix.
sub gj_elimination($$)
{
    my ( $m, $epsilon ) = @_;

    my $row_echelon_matrix = forward_elimination( $m, $epsilon );
    my $reduced_row_echelon_matrix =
        back_substitution( $row_echelon_matrix, $epsilon );

    return $reduced_row_echelon_matrix;
}


# Return only non-zero elements of the row echelon form
sub gj_elimination_non_zero_elements($$)
{
    my ( $m, $epsilon ) = @_;


    my $reduced_row_echelon_m = gj_elimination( $m, $epsilon );

    my @non_null_rows = map { $_->[0] != 0 ||
                              $_->[1] != 0 ||
                              $_->[2] != 0 ? $_ : () } @$reduced_row_echelon_m;

    return \@non_null_rows;
}

# Find machine epsilon – a floating point number that added to 1.0
# yields the same 1.0
sub machine_epsilon
{
    my $eps = 1.0;

    while( $eps/2 + 1 > 1 ) {
        $eps /= 2;
    }

    return $eps;
}

my $machine_eps = machine_epsilon();

# Find the pivot row (the row with the largest coefficient)
sub pivot
{
    my ( $m, $k, $r ) = @_;
    my $maxi = $k;
    for( my $j = $k + 1; $j <=  $#{$m}; $j++ ) {
        if( abs($m->[$maxi][$r]) < abs($m->[$j][$r]) ) {
            $maxi = $j;
        }
    }

    return $maxi;
}

# Perform the first step in Gauss-Jordan method: Gaussian elimination (forward
# elimination).
# @param  matrix, machine epsilon
# @retval matrix in row echelon form
sub forward_elimination
{
    my( $a, $epsilon ) = @_;
    return [] if @$a == 0;

    my @m = map { [@{$_}] } @{$a};

    my $eps = defined $epsilon ? $epsilon : 2*$machine_eps;

    my $N = @m; # Matrix row count
    my $k = 0;  # pivot row
    my $r = 0;  # pivot column
    while( $k < $N && $r < @{$m[$k]} ) {
        my $j = pivot( \@m, $k, $r );
        # print STDERR ">>> pivot = ", $m[$j][$k], $m[$j];
        if( abs($m[$j][$r]) <= $eps ) {
            $m[$j][$r] = 0;
            $r ++; # No pivot in this column, try the next one
        } else {
            if( $k != $j ) {
                ($m[$k], $m[$j]) = ($m[$j], $m[$k]);
            }
            for( my $l = $k + 1; $l < $N; $l++ ) {
                my $f = $m[$l][$r] / $m[$k][$r];
                $m[$l][$r] = 0;
                for( my $h = $r + 1; $h < @{$m[$l]}; $h ++ ) {
                    $m[$l][$h] -= $m[$k][$h] * $f;
                    if( abs($m[$l][$h]) <= $eps ) {
                        $m[$l][$h] = 0;
                    }
                }
            }
            $k ++; # Process the next pivot row
            $r ++; # Process the next pivot column
        }
    }

    do {
        for (@m) {
            print STDERR ">>>> ", join(" ", @$_), "\n";
        }
    } if 0;

    return \@m;
}

# The 'backward_elimination' name is deprecated and retained only for
# compatibility
sub backward_elimination
{
    return &back_substitution
}

# Subtract one row (a vector) multiplied by a coefficient from another
# row:
sub v_k_sub
{
    my ( $v1, $v2, $k ) = @_;

    for( my $i = 0; $i < @{$v1}; $i++ ) {
        $v1->[$i] -= $k * $v2->[$i];
    }

    return;
}

# Find the index of the first non-zero element in the row:
sub i_non_zero
{
    my ( $v, $eps ) = @_;

    my $i;
    for( $i = 0; $i < @{$v}; $i++ ) {
        if( abs($v->[$i]) > $eps  ) {
            return $i;
        }
    }

    return $i;
}

# Conclude Gauss-Jordan elimination: perform backward elimination.
# @param:  matrix in row echelon form, machine epsilon
# @retval: copy of a matrix in reduced row echelon form
sub back_substitution
{
    my( $a, $epsilon ) = @_;
    return [] if @$a == 0;

    # make a copy of the original row echelon matrix
    my @m = map { [@{$_}] } @{$a};

    my $eps = defined $epsilon ? $epsilon : 2*$machine_eps;

    my $N = @m;
    for( my $k = $N - 1; $k >= 0; $k-- ) {
        my $s = i_non_zero( $m[$k], $eps );
        if( $s < @{$m[$k]} ) {
            my $f = $m[$k][$s];
            for( my $h = $s; $h < @{$m[$k]}; $h ++ ) {
                if( abs($m[$k][$h]) > $eps ) {
                    $m[$k][$h] /= $f;
                } else {
                    $m[$k][$h] = 0;
                }
            }
            for( my $l = $k - 1; $l >= 0; $l-- ) {
                v_k_sub( $m[$l], $m[$k], $m[$l][$s] );
            }
        }
    }

    return \@m;
}

1;
