#--*-perl-*-------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#-----------------------------------------------------------------------
#*
# Performs Gauss-Jordan elimination on a matrix; uses BigRat arithmetic.
#**

package COD::Algebra::GaussJordanBigRat;
use strict;
use warnings;
use Math::BigRat try => 'GMP';

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    gj_elimination_non_zero_elements
);

# Run the G-J elimination process, return a reduced echelon form
# matrix.
sub gj_elimination
{
    my ( $m ) = @_;

    # "rationalise" the matrix:
    my @m = map {
        [ map {Math::BigRat->new($_)} @$_ ]
    } @$m;

    my $row_echelon_matrix = forward_elimination( \@m );
    my $reduced_row_echelon_matrix =
        back_substitution( $row_echelon_matrix );

    return $reduced_row_echelon_matrix;
}


# Return only non-zero elements of the row echelon form
sub gj_elimination_non_zero_elements($@)
{
    my ( $m ) = @_;

    my $reduced_row_echelon_m = gj_elimination( $m );

    my @non_null_rows =
        map { int(grep {$_ != 0} @$_) ? $_ : () } @$reduced_row_echelon_m;

    return \@non_null_rows;
}

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
# @param  matrix
# @retval matrix in row echelon form
sub forward_elimination
{
    my( $a ) = @_;
    return [] if @$a == 0;

    my @m = map { [@{$_}] } @{$a};

    do {
        local $\ = "\n";
        for (@m) {
            print STDERR ">> ", join( "\t", @$_ );
        }
        print STDERR "";
    } if 0;

    my $N = @m; # Matrix row count
    my $k = 0;  # pivot row
    my $r = 0;  # pivot column
    while( $k < $N && $r < @{$m[$k]} ) {
        my $j = pivot( \@m, $k, $r );
        # print STDERR ">>> pivot = ", $m[$j][$k], $m[$j];
        if( $m[$j][$r]->is_zero() ) {
            $r ++; # No pivot in this column, try the next one
        } else {
            if( $k != $j ) {
                ($m[$k], $m[$j]) = ($m[$j], $m[$k]);
            }
            for( my $l = $k + 1; $l < $N; $l++ ) {
                my $f = $m[$l][$r]->copy() / $m[$k][$r]->copy();
                $m[$l][$r]->bzero();
                for( my $h = $r + 1; $h < @{$m[$l]}; $h ++ ) {
                    $m[$l][$h] = $m[$l][$h]->copy() - $m[$k][$h]->copy() * $f->copy();
                }
            }
            $k ++; # Process the next pivot row
            $r ++; # Process the next pivot column
        }
        do {
            local $\ = "\n";
            for (@m) {
                print STDERR ">>>> ", join( "\t", @$_ );
            }
            print STDERR "";
        } if 0;
    }

    do {
        for (@m) {
            print STDERR ">> ", join("\t", @$_), "\n";
        }
        print STDERR "\n";
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
        $v1->[$i] -= $k->copy() * $v2->[$i]->copy();
    }

    return;
}

# Find the index of the first non-zero element in the row:
sub i_non_zero($)
{
    my ( $v ) = @_;

    my $i;
    for( $i = 0; $i < @{$v}; $i++ ) {
        if( ! $v->[$i]->is_zero() ) {
            return $i;
        }
    }

    return $i;
}

# Conclude Gauss-Jordan elimination: perform backward elimination.
# @param:  matrix in row echelon form
# @retval: copy of a matrix in reduced row echelon form
sub back_substitution
{
    my( $a ) = @_;
    return [] if @$a == 0;

    # make a copy of the original row echelon matrix
    my @m = map { [@{$_}] } @{$a};

    my $N = @m;
    for( my $k = $N - 1; $k >= 0; $k-- ) {
        my $s = i_non_zero( $m[$k] );
        if( $s < @{$m[$k]} ) {
            my $f = $m[$k][$s];
            for( my $h = $s; $h < @{$m[$k]}; $h ++ ) {
                if( ! $m[$k][$h]->is_zero() ) {
                    $m[$k][$h] = $m[$k][$h]->copy() / $f->copy();
                } else {
                    $m[$k][$h]->bzero();
                }
            }
            for( my $l = $k - 1; $l >= 0; $l-- ) {
                v_k_sub( $m[$l], $m[$k], $m[$l][$s] );
            }
        }
        do {
            local $\ = "\n";
            for (@m) {
                print STDERR ">>>> ", join( "\t", @$_ );
            }
            print STDERR "";
        } if 0;
    }

    return \@m;
}

1;
