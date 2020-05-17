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
    gj_elimination forward_elimination back_substitution
    backward_elimination 
);

# Run the G-J elimination process, return a reduced echelon form
# matrix.
sub gj_elimination($$)
{
    my ( $m, $MACHINE_EPS ) = @_;

    my $row_echelon_matrix = forward_elimination( $m, $MACHINE_EPS );
    my $reduced_row_echelon_matrix = 
        back_substitution( $row_echelon_matrix, $MACHINE_EPS );

    return $reduced_row_echelon_matrix;
}

# Perform elementary operations on a matrix row.
# @param  matrix, current row, i, j indices, machine epsilon 
# @retval current row, i, j indices
sub perform_row_reduction
{
    my ( $matrix, $row, $i, $j, $EPSILON ) = @_;
    my @m = @{$matrix};
    if ( $m[$i]->[$j] != 0 ) {
        if ( defined $row ) {
            # If non-zero line is found, a quotient is calculated
            # to produce zero in the analysed column of current row.
            my $q = $m[$i]->[$j] / $m[$row]->[$j];
            for( my $k = $j; $k < @{ $m[0] }; $k++ ) {
                $m[$i]->[$k] -= $q * $m[$row]->[$k];
                if ( abs($m[$i]->[$k]) < $EPSILON ) {
                    $m[$i]->[$k] = 0;
                }
            }
        } else {
            # If non-zero line is not found, take this as non-zero
            # line and divide by the value of the analysed column.
            $row = $i;
            my $q = $m[$row]->[$j];
            for( my $k = $j; $k < @{ $m[0] }; $k++ ) {
                $m[$row]->[$k] = $m[$row]->[$k] / $q;
                if ( abs($m[$row]->[$k]) < $EPSILON ) {
                    $m[$row]->[$k] = 0;
                }
            }
        }
    }
    return $row, $i, $j;
}


# Perform the first step in Gauss-Jordan method: Gaussian elimination (forward 
# elimination).
# @param  matrix, machine epsilon
# @retval matrix in row echelon form
sub forward_elimination
{
    my( $m, $EPSILON ) = @_;
    return 0 if @$m == 0;

    my @m = @{$m};

    my $topmost = 0;
    for( my $j = 0; $j < @{ $m[0] }; $j++ ) {
        # Sorting lines of the matrix favouring the lowest absolute value
        # of the analysed column, keeping the zeroes in the bottom:
        @m[$topmost..$#m] = sort { ($a->[$j] == 0) - ($b->[$j] == 0) +
                                   ($a->[$j] != 0 &&  $b->[$j] != 0 ) *
                                   (abs( $a->[$j] ) <=> abs( $b->[$j] )) }
                                 @m[$topmost..$#m];

        # Starting from the first non-pegged line, the first line with
        # non-zero value of the analysed column is taken and used to
        # produce zeroes in the analysed column of lines below.
        my $i = $topmost;
        my $row;
        while ( $i < @m ) {
            ( $row, $i, $j ) = 
                perform_row_reduction ( \@m, $row, $i, $j, $EPSILON );
            $i++;
        }
        # Peg the used line in order not to use it once again.
        $topmost = $row + 1 if defined $row;
    }

    # Removing all-zero lines
    my @non_null_rows = map { $_->[0] != 0 ||
                              $_->[1] != 0 ||
                              $_->[2] != 0 ? $_ : () } @m;

    return \@non_null_rows;
}

# The 'backward_elimination' name is deprecated and retained only for
# compatibility
sub backward_elimination 
{
    return &back_substitution
}

# Conclude Gauss-Jordan elimination: perform backward elimination.
# @param:  matrix in row echelon form, machine epsilon
# @retval: copy of a matrix in reduced row echelon form
sub back_substitution
{
    my( $m_orig, $EPSILON ) = @_;
    return $m_orig if @$m_orig == 0;

    # make a copy of the original row echelon matrix
    my @m = map { [@{$_}] } @{$m_orig};

    my $bottom = $#m;
    my $column_shift = 0;
    if ( $m[$bottom]->[$bottom] == 0 ) {
        $column_shift = 1;
    }
    for( my $j = $bottom + $column_shift; $j >= 0; $j-- ) {
        my $i = $bottom;
        my $row;
        while ( $i >= 0 ) {
            ( $row, $i, $j ) = 
                perform_row_reduction ( \@m, $row, $i, $j, $EPSILON );
            $i--;
        }
        # Peg the used line in order not to use it once again.
        $bottom = $row - 1 if defined $row;
    }

    return \@m;
}

1;
