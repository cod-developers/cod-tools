sub det3
{
    my ($m) = @_;
    local $[ = 1;

    $m->[1][1] * $m->[2][2] * $m->[3][3]
	+ $m->[2][1] * $m->[3][2] * $m->[1][3]
	+ $m->[1][2] * $m->[2][3] * $m->[3][1]
	- $m->[1][3] * $m->[2][2] * $m->[3][1]
	- $m->[1][2] * $m->[2][1] * $m->[3][3]
	- $m->[1][1] * $m->[3][2] * $m->[2][3]
}

sub check_symop_determinant
{
    my ($symop) = @_;

    my $matrix = symop_from_string( $symop );

    if( $matrix ) {
	my $det = det3( $matrix );
	## print "||| $symop\n";
	## print "||| $det\n";
	## print "||| @{$matrix->[0]}\n";
	## print "||| @{$matrix->[1]}\n";
	## print "||| @{$matrix->[2]}\n";
	## print "||| \n";
	if( abs( $det - 1 ) > 1e-5 ) {
	    return "determinant of the symmetry operator '$symop' matrix ".
		"is not 1";
	}
    }

    return undef;
}

sub check_symop_orthogonality
{
    my ($symop) = @_;

    my $matrix = symop_from_string( $symop );

    for( my $i = 0; $i < 3; $i ++ ) {
	for( my $j = 0; $j < 3; $j ++ ) {
	    my $s = 0;
	    for( my $k = 0; $k < 3; $k ++ ) {
		$s += $matrix->[$i][$k] * $matrix->[$j][$k];
	    }
	    my $val = ($i == $j) ? 1 : 0;
	    if( abs( $s - $val ) > 1e-5 ) {
		return "rotation matrix of the symmetry operator '$symop' " .
		    "is not orthogonal";
	    }
	}
    }

    return undef;
}
