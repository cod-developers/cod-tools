#--*-perl-*-------------------------------------------------------------
#$Author: saulius $
#$Date: 2013-07-11 16:02:49 +0300 (Thu, 11 Jul 2013) $
#$Revision: 2186 $
#$URL: svn://cod.ibt.lt/cod-tools/trunk/Spacegroups/SymopAlgebra.pm $
#-----------------------------------------------------------------------
#*
# Basic symmetry operator algebra (addition, multiplication, etc.)
#**

package VectorAlgebra;

use strict;
use warnings;

require Exporter;
@VectorAlgebra::ISA = qw(Exporter);
@VectorAlgebra::EXPORT = qw( 
vector_sub vector_modulo_1 vector_is_zero
vectors_are_equal
);

sub vector_sub($$)
{
    my ($v1, $v2) = @_;

    my @result;

    for( my $i = 0; $i < @$v1; $i++ ) {
        $result[$i] = $v1->[$i] - $v2->[$i]
    }

    return wantarray ? @result : \@result;
}

sub modulo_1
{
    my $x = $_[0];
    use POSIX;
    return $x - POSIX::floor($x);
}

sub vector_modulo_1($)
{
    my ($v) = @_;

    my @r = map { modulo_1($_) } @$v;

    return wantarray ? @r : \@r;
}

sub vector_is_zero($)
{
    my ($vector) = @_;

    for (@$vector) {
        return 0 if $_ != 0.0;
    }
    return 1;
}

sub vectors_are_equal($$)
{
    my ($v1, $v2) = @_;

    for( my $i = 0; $i < @$v1; $i++ ) {
        return 0 unless $v1->[$i] == $v2->[$i];
    }

    return 1;
}

1;
