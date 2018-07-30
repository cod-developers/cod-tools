# Module to perform Gauss-Jordan elimination on a matrix. Matrix dimensions:
# N rows, 3 columns.

package COD::Algebra::GaussJordan;
use strict;
use warnings;
require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( forward_elimination backward_elimination );


# Perform elementary operations on a matrix row.
# @param  matrix, current row, i, j indices 
# @retval current row, i, j indices
sub perform_row_reduction
{
    my ( $matrix, $row, $i, $j ) = @_;
    my @m = @{$matrix};
    if ( $m[$i]->[$j] != 0 ) {
        if ( defined $row ) {
            # If non-zero line is found, a quotient is calculated
            # to produce zero in the analysed column of current row.
            my $q = $m[$i]->[$j] / $m[$row]->[$j];
            for( my $k = $j; $k < @{ $m[0] }; $k++ ) {
                $m[$i]->[$k] -= $q * $m[$row]->[$k];
            }
        } else {
            # If non-zero line is not found, take this as non-zero
            # line and divide by the value of the analysed column.
            $row = $i;
            my $q = $m[$row]->[$j];
            for( my $k = $j; $k < @{ $m[0] }; $k++ ) {
                $m[$row]->[$k] = $m[$row]->[$k] / $q;
            }
        }
    }
    return $row, $i, $j;
}


# Perform the first step in Gauss-Jordan method: Gaussian elimination (forward 
# elimination).
# @param  matrix
# @retval matrix in row echelon form
sub forward_elimination
{
    my( $m ) = @_;
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
            ( $row, $i, $j ) = perform_row_reduction ( \@m, $row, $i, $j );
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


# Conclude Gauss-Jordan elimination: perform backward elimination.
# @param:  matrix in row echelon form
# @retval: copy of a matrix in reduced row echelon form
sub backward_elimination 
{
    my( $m_orig ) = @_;
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
            ( $row, $i, $j ) = perform_row_reduction ( \@m, $row, $i, $j );
            $i--;
        }
        # Peg the used line in order not to use it once again.
        $bottom = $row - 1 if defined $row;
    }

    return \@m;
}

1;
