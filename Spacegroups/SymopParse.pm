#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------
#* 
#**

package SymopParse;

use strict;

require Exporter;
@SymopParse::ISA = qw(Exporter);
@SymopParse::EXPORT = qw( symop_from_string string_from_symop 
    symop_string_canonical_form check_symmetry_operator modulo_1
);

#
# Symop array contains the following values:
# my $symop = [
#     [ r11 r12 r13 t1 ]
#     [ r21 r22 r23 t1 ]
#     [ r31 r32 r33 t1 ]
#     [   0   0   0  1 ]
# ]
#

sub symop_from_string
{
    my ($str) = @_;

    my @symop = ( [0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,1] );
    my $n = 0;

    $str =~ s/\s+//g;

    while( $n < 3 && $str ne "" && $str =~ s/(^.*?,|^.*?$)// ) {
	my $symop = $1;
	$symop =~ s/,//g;
	$symop = lc($symop);
	while( $symop ne "" && $symop =~ s/([-+]?)([xyz0-9.\/]+)// ) {
	    my $sign = defined $1 ? ($1 eq "-" ? -1 : +1 ) : +1;
	    my $value = $2;

	    if( $value =~ /^x$/ ) {
		$symop[$n][0] = $sign;
	    }
	    elsif( $value =~ /^y$/ ) {
		$symop[$n][1] = $sign;
	    }
	    elsif( $value =~ /^z$/ ) {
		$symop[$n][2] = $sign;
	    }
	    else {
		if( $value =~ m/(\d+)\/(\d+)/ ) {
		    $value = $1 / $2;
		}
		$symop[$n][3] = $sign * $value;
	    }
	    #print "sign = $sign; value = $value\n";
	}
	#print "====\n";
	$n ++;
    }

    return \@symop;
}

sub round
{
    use POSIX;
    my $x = $_[0];
    return POSIX::floor( $x + 0.5 );
}

sub string_from_symop
{
    my ($symop) = @_;

    my @symops = ( "", "", "" );

    for( my $i = 0; $i < $#{$symop}; $i ++ ) {
	if( $symop->[$i][0] > 0 ) {
	    $symops[$i] = "x";
	} elsif( $symop->[$i][0] < 0 ) {
	    $symops[$i] = "-x";
	}
	if( $symop->[$i][1] > 0 ) {
	    if( $symops[$i] eq "" ) {
		$symops[$i] = "y";
	    } else {
		$symops[$i] .= "+y";
	    }
	} elsif( $symop->[$i][1] < 0 ) {
	    $symops[$i] .= "-y";
	}
	if( $symop->[$i][2] > 0 ) {
	    if( $symops[$i] eq "" ) {
		$symops[$i] = "z";
	    } else {
		$symops[$i] .= "+z";
	    }
	} elsif( $symop->[$i][2] < 0 ) {
	    $symops[$i] .= "-z";
	}
	if( $symop->[$i][3] != 0 ) {
	    my $val = $symop->[$i][3];
	    my $abs = abs( $val );
	    my $sig = $val > 0 ? "+" : "-";
	    my $maxdiff = 1e-3;
	    if( abs( $abs - 1.0 ) < $maxdiff ) {
		$val = ""
	    }
	    elsif( abs( $abs - 0.5 ) < $maxdiff ) {
		$val = $sig . "1/2";
	    }
	    elsif( abs( $abs * 3 - round($abs * 3)) < $maxdiff ) {
		my $numerator = round( $abs * 3 );
		$val = $sig . "$numerator/3";
	    }
	    elsif( abs( $abs * 4 - round($abs * 4)) < $maxdiff ) {
		my $numerator = round( $abs * 4 );
		$val = $sig . "$numerator/4";
	    }
	    elsif( abs( $abs * 6 - round($abs * 6)) < $maxdiff ) {
		my $numerator = round( $abs * 6 );
		$val = $sig . "$numerator/6";
	    } else {
		$val = sprintf( "%+f", $val );
	    }
	    $symops[$i] .= $val;
	}
    }

    return join( ",", @symops );
}

sub symop_print
{
    my ($symop) = @_;

    for( my $i = 0; $i <= $#{$symop}; $i ++ ) {
	for( my $j = 0; $j <= $#{$symop->[$i]}; $j ++ ) {
	    print $symop->[$i][$j];
	    print ", " if( $j < $#{$symop->[$i]} );
	}
	print "\n";
    }
}

sub modulo_1
{
    my $x = $_[0];
    use POSIX;
    return $x - POSIX::floor($x);
}

sub symop_translation_modulo_1
{
    my ($symop) = @_;

    for( my $i = 0; $i < $#{$symop}; $i ++ ) {
	$symop->[$i][3] = modulo_1( $symop->[$i][3] + 10 );
    }

    return $symop;
}

sub symop_string_canonical_form
{
    my ($symop) = @_;

    return string_from_symop(
	symop_translation_modulo_1(
	    symop_from_string( $symop )
	)
    );
}

sub check_symmetry_operator
{
    my ($symop) = @_;

    my $symop_term = '(?:x|y|z|\d|\d*\.\d+|\d+\.\d*|\d/\d)';
    my $symop_component =
	"(?:(?:-|\\+)?$symop_term|" .
	"(?:-|\\+)?$symop_term(?:-|\\+)$symop_term|" .
	"(?:-|\\+)?$symop_term(?:-|\\+)$symop_term(?:-|\\+)$symop_term)";

    if( !defined $symop ) {
	return "no symmetry operators";
    } else {
	my $no_spaces = $symop;
	$no_spaces =~ s/\s//g;
	if( $no_spaces !~ 
	    /^($symop_component,){2}($symop_component)$/i ) {
	    return "symmetry operator '$symop' could not be parsed";
	}
    }
    return undef;
}

1;
