#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  A Perl object to build all spacegroup operators and spacegroup
#  description from symmetry operators supplied one by one or as a
#  list.
#**

package SGBuilder;
use strict;
use warnings;

use VectorAlgebra;
use SymopAlgebra qw( symop_translation );
use SymopParse;

use fields qw( symops has_inversion inversion_translation centering_translations );

sub new { 
    my ($self) = @_;

    $self = fields::new($self) unless (ref $self);
    $self->{symops} = [];
    $self->{has_inversion} = 0;
    $self->{inversion_translation} = undef;
    $self->{centering_translations} = [];
    return $self;
}

sub print
{
    my ($self) = @_;

    print "inversion: ", $self->{has_inversion}, "\n";
    print "centering: ";
    for (@{$self->{centering_translations}}) {
        local $, = ",";
        print @$_;
        print " ";
    }
    print "\n";
}

sub insert_translation
{
    my ($self, $translation) = @_;

    $translation = vector_modulo_1( $translation );

    if( vector_is_zero( $translation )) {
        return
    }
    for my $t (@{$self->{centering_translations}}) {
        if( vectors_are_equal( $t, $translation )) {
            return
        }
    }
    push( @{$self->{centering_translations}}, $translation );
}

sub insert_symop
{
    my ($self, $symop) = @_;

    if( SymopAlgebra::symop_is_inversion( $symop )) {
        if( $self->{has_inversion} ) {
            my $translation = SymopAlgebra::symop_translation( $symop );
            my $new_centering = vector_sub( $self->{inversion_translation},
                                            $translation );
            $self->insert_translation( $new_centering );
        } else {
            $self->{has_inversion} = 1;
            $self->{inversion_translation} = symop_translation( $symop );
        }
    }
}

sub insert_symop_string
{
    my ($self, $symop_string) = @_;

    my $symop = SymopParse::symop_from_string( $symop_string );
    $self->insert_symop( $symop );
}

1;
