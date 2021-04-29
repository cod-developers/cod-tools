#------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------
#*
# Parse symmetry operators describing superspace groups (N+1
# dimensional space groups) used for the description of the
# incommensurately modulated structures.
#**

package COD::Spacegroups::Symop::SSGParse;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    symop_from_string
    string_from_symop
    string_from_symop_reduced
    symop_string_canonical_form
    check_symmetry_operator
    modulo_1
    symop_translation_modulo_1
    symop_print
    symop_from_ssg_operator
);

#
# Symop array contains the following values:
# my $symop = [
#     [ r11 r12 r13 r14 ... r1N  t1 ]
#     [ r21 r22 r23 r24 ... r2N  t2 ]
#     [ r31 r32 r33 r34 ... r3N  t3 ]
#     [ r41 r42 r42 r44 ... r4N  t4 ]
#     [ ... ... ... ... ... ... ... ]
#     [ rN1 rN2 rN3 rN4 ... rNN  tN ]
#     [   0   0   0   0 ...   0   1 ]
# ]
#

sub symop_from_string
{
    my ($str) = @_;

    $str =~ s/\s+//g;
    my @lines = split ',', $str;
    my $N = scalar @lines;

    my @symop;
    foreach (@lines) {
        push @symop, [ ( 0 ) x ( $N+1 ) ];
    }
    push @symop, [ ( 0 ) x $N, 1 ];

    for my $i (0..$#lines) {
        my $symop = lc($lines[$i]);
        $symop = lc($symop);
        while( $symop ne "" && $symop =~ s/([-+]?)([x0-9.\/]+)// ) {
            my $sign = defined $1 ? ($1 eq "-" ? -1 : +1 ) : +1;
            my $value = $2;

            if( $value =~ /^x([0-9]+)/ ) {
                $symop[$i][$1-1] = $sign;
            } else {
                if( $value =~ /([0-9]+)\/([0-9]+)/ ) {
                    $value = $1 / $2;
                }
                $symop[$i][$N] = $sign * $value;
            }
        }
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

    my $n = scalar(@$symop);
    my @symops = ( "" ) x ($n-1);

    for( my $i = 0; $i < $#{$symop}; $i ++ ) {
        my @symop_parts;
        for( my $j = 0; $j < @symops; $j ++ ) {
            next if $symop->[$i][$j] == 0;
            push @symop_parts,
                 ( $symop->[$i][$j] < 0 ? "-" : "" ) . "x" . ($j+1);
        }
        $symops[$i] = join "+", @symop_parts;
        $symops[$i] =~ s/\+-/-/g;
        if( $symop->[$i][$n-1] != 0 ) {
            my $sig = $symop->[$i][$n-1] > 0 ? "+" : "-";
            my $val = abs( $symop->[$i][$n-1] );
            $symops[$i] .= $sig . $val;
        }
    }
    return join( ",", @symops );
}

sub string_from_symop_reduced
{
    my ($symop) = @_;

    my $n = scalar(@$symop);
    my @symops = ( "" ) x ($n-1);

    for( my $i = 0; $i < $#{$symop}; $i ++ ) {
        my @symop_parts;
        for( my $j = 0; $j < @symops; $j ++ ) {
            next if $symop->[$i][$j] == 0;
            push @symop_parts,
                 ( $symop->[$i][$j] < 0 ? "-" : "" ) . "x" . ($j+1);
        }
        $symops[$i] = join "+", @symop_parts;
        $symops[$i] =~ s/\+-/-/g; # <- finish RE for Emacs...
        if( $symop->[$i][$n-1] != 0 ) {
            my $val = $symop->[$i][$n-1];
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

    my $n = scalar(@$symop);
    for( my $i = 0; $i < $#{$symop}; $i ++ ) {
        $symop->[$i][$n-1] = modulo_1( $symop->[$i][$n-1] + 10 );
    }

    return $symop;
}

sub symop_string_canonical_form
{
    my ($symop) = @_;

    return string_from_symop_reduced(
        symop_translation_modulo_1(
            symop_from_string( $symop )
        )
    );
}

sub check_symmetry_operator
{
    my ($symop) = @_;

    my $symop_term = '(?:x[0-9]+|[0-9]|[0-9]*\.[0-9]+|[0-9]+\.[0-9]*|[0-9]/[0-9])';
    my $symop_component =
        "(?:[-+]?$symop_term(?:[-+]$symop_term){0,})";

    if( !defined $symop ) {
        return "no symmetry operators";
    } else {
        my $no_spaces = $symop;
        $no_spaces =~ s/\s//g;
        if( $no_spaces !~
            /^($symop_component,){3,}($symop_component)$/i ) {
            return "symmetry operator '$symop' could not be parsed";
        }
    }
    return undef;
}

sub symop_from_ssg_operator
{
    my ( $m ) = @_;

    my $n = $#{$m};

    return [
        [ $m->[0][0], $m->[0][1], $m->[0][2], $m->[0][$n] ],
        [ $m->[1][0], $m->[1][1], $m->[1][2], $m->[1][$n] ],
        [ $m->[2][0], $m->[2][1], $m->[2][2], $m->[2][$n] ],

        [ $m->[$n][0], $m->[$n][1], $m->[$n][2], $m->[$n][$n] ]
    ];
}

1;
