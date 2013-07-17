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
use SymopParse;
use SymopAlgebra qw(
    symop_mul symop_modulo_1 symop_translate symop_translation
    symop_set_translation
);

use fields qw(
    symops has_inversion inversion_translation centering_translations
);

my $unity_symop = [
    [ 1, 0, 0, 0 ],
    [ 0, 1, 0, 0 ],
    [ 0, 0, 1, 0 ],
    [ 0, 0, 0, 1 ],
];

my $inversion_symop = [
    [-1, 0, 0, 0 ],
    [ 0,-1, 0, 0 ],
    [ 0, 0,-1, 0 ],
    [ 0, 0, 0, 1 ],
];

sub new { 
    my ($self) = @_;

    $self = fields::new($self) unless (ref $self);
    $self->{symops} = [ $unity_symop ];
    $self->{has_inversion} = 0;
    $self->{inversion_translation} = undef;
    $self->{centering_translations} = [ [0,0,0] ];
    return $self;
}

sub print
{
    my ($self) = @_;

    print "nrepreset: ", int(@{$self->{symops}}), "\n";
    print "representatives:\n";
    for my $symop (@{$self->{symops}}) {
        print "    ", string_from_symop( $symop ), "\n"
    }
    print "nsymops:   ", int(@{$self->all_symops()}), "\n";
    print "symops:\n";
    for my $symop (@{$self->all_symops()}) {
        print "    ", string_from_symop( $symop ), "\n"
    }
    print "inversion: ", $self->{has_inversion}, "\n";
    print "centering: ";
    for (@{$self->{centering_translations}}) {
        local $, = ",";
        print @$_;
        print " ";
    }
    print "\n";
}

sub all_symops
{
    my ($self) = @_;

    my @inversions = ( $unity_symop );

    if( $self->{has_inversion} ) {
        push( @inversions,
              scalar( symop_translate( $inversion_symop,
                                       $self->{inversion_translation})));
    }

    my @symops;

    for my $inversion (@inversions) {
        for my $translation (@{$self->{centering_translations}}) {
            for my $symop (@{$self->{symops}}) {
                my $final_symop =
                    SymopAlgebra::flush_zeros_in_symop(
                        symop_modulo_1(
                            symop_translate( symop_mul( $symop, $inversion ),
                                             $translation )));
                push( @symops, $final_symop );
            }
        }
    }

    return wantarray ? @symops : \@symops;
}

sub insert_translation
{
    my ($self, $translation) = @_;

    $translation = vector_modulo_1( round_vector( $translation ));

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

sub insert_representative_matrix
{
    my ($self, $symop) = @_;

    push( @{$self->{symops}}, $symop );
    for my $s (@{$self->{symops}}) {
        my $product = symop_modulo_1( symop_mul( $s, $symop ));
        $self->insert_symop( $product );
    }
}

sub insert_symop
{
    my ($self, $symop) = @_;

    $symop = symop_modulo_1( $symop );

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
    } else {
        my $existing_symop;
        if( defined ($existing_symop = $self->has_matrix( $symop ))) {
            my $existing_translation = symop_translation( $existing_symop );
            my $translation = symop_translation( $symop );
            $self->insert_translation(
                vector_sub( $existing_translation, $translation ));
        } else {
            my $inverted_symop = symop_mul( $inversion_symop, $symop );
            if( defined
                ($existing_symop = $self->has_matrix( $inverted_symop ))) {
                if( !$self->{has_inversion} ) {
                    my $existing_translation = symop_translation( $existing_symop );
                    my $translation = symop_translation( $symop );
                    $self->{has_inversion} = 1;
                    $self->{inversion_translation} =
                        vector_add( $existing_translation, $translation );
                } else {
                    my $translated_inversion =
                        symop_set_translation( $inversion_symop,
                                               $self->{inversion_translation} );
                    my $translated_symop =
                        symop_mul( $existing_symop, $translated_inversion );
                    my $existing_translation = symop_translation( $translated_symop );
                    my $translation = symop_translation( $symop );
                    $self->insert_translation(
                        vector_sub( $existing_translation, $translation ));
                }
            } else {
                $self->insert_representative_matrix( $symop );
            }
        }
    }
}

sub insert_symops
{
    my ($self, $symops) = @_;

    for my $symop (@$symops) {
        $self->insert_symop( $symop );
    }
}

sub has_matrix
{
    my ($self, $symop) = @_;

    for my $s (@{$self->{symops}}) {
        if( SymopAlgebra::symop_matrices_are_equal( $s, $symop )) {
            return $s;
        }
    }
    return undef;
}

sub insert_symop_string
{
    my ($self, $symop_string) = @_;

    my $symop = SymopParse::symop_from_string( $symop_string );
    $self->insert_symop( $symop );
}

sub insert_symop_strings
{
    my ($self, $strings) = @_;

    for my $symop_string (@$strings) {
        $self->insert_symop_string( $symop_string );
    }
}

1;
