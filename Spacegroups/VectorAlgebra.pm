#--*-perl-*-------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#-----------------------------------------------------------------------
#*
# Basic symmetry operator algebra (addition, multiplication, etc.)
#**

package VectorAlgebra;

use strict;
use warnings;
use POSIX;

require Exporter;
@VectorAlgebra::ISA = qw(Exporter);
@VectorAlgebra::EXPORT = qw( 
    vector_sub vector_add vector_modulo_1 vector_is_zero
    vectors_are_equal round_vector
);

@VectorAlgebra::EXPORT_OK = qw( modulo_1 );

sub vector_sub($$)
{
    my ($v1, $v2) = @_;

    my @result;

    for( my $i = 0; $i < @$v1; $i++ ) {
        $result[$i] = $v1->[$i] - $v2->[$i]
    }

    return \@result;
}

sub vector_add($$)
{
    my ($v1, $v2) = @_;

    my @result;

    for( my $i = 0; $i < @$v1; $i++ ) {
        $result[$i] = $v1->[$i] + $v2->[$i]
    }

    return \@result;
}

sub modulo_1
{
    my $x = $_[0];
    return $x - POSIX::floor($x);
}

sub vector_modulo_1($)
{
    my ($v) = @_;

    my @r = map { modulo_1($_) } @$v;

    return \@r;
}

sub vector_is_zero($@)
{
    my ($vector, $eps) = @_;

    $eps = 1E-6 unless defined $eps;

    for (@$vector) {
        return 0 if abs($_) >= $eps;
    }
    return 1;
}

sub round_vector($@)
{
    my ($vector, $eps) = @_;

    $eps = 1E-10 unless defined $eps;

    map { $_ = POSIX::floor($_/$eps + 0.5)*$eps } @$vector;

    return $vector;
}

sub vectors_are_equal($$@)
{
    my ($v1, $v2, $eps) = @_;

    $eps = 1E-6 unless defined $eps;

    for( my $i = 0; $i < @$v1; $i++ ) {
        #print "delta = ", abs($v1->[$i] - $v2->[$i]), "\n";
        return 0 unless abs($v1->[$i] - $v2->[$i]) < $eps;
    }

    return 1;
}

1;
