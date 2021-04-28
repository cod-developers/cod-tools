#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*

# A Perl object to build all space group operators and space group
# description from symmetry operators supplied one by one or as a
# list.

# This module, the Builder, implements the optimised space group
# building algorthm as described in [1], according to my (S.G.)
# understanding. The algebra should follow pretty closely the text of
# the paper; all bugs, if present, are mine (S.G. ;).

# [1]. Grosse-Kunstleve, R. W. Algorithms for deriving
# crystallographic space-group information. Acta
# crystallographica. Section A, Foundations of crystallography, 1999,
# 55, 383-395. URL: https://doi.org/10.1107/S0108767398010186

#**

package COD::Spacegroups::Builder;

use strict;
use warnings;
use COD::Algebra::Vector qw( vector_sub vector_add vector_modulo_1
                             vector_is_zero vectors_are_equal round_vector );
use COD::Spacegroups::Symop::Parse qw( symop_from_string string_from_symop );
use COD::Spacegroups::Symop::Algebra qw(
    symop_mul symop_vector_mul symop_modulo_1 symop_translate symop_translation
    symop_set_translation symop_is_inversion symop_matrices_are_equal
    flush_zeros_in_symop symop_is_translation snap_to_crystallographic
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

my $debug = 0;

sub debug
{
    my ($debug_flag) = @_;
    $debug = ($debug_flag? 1:0);
}

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
    my ($self, $fd) = @_;

    $fd = \*STDOUT unless defined $fd;

    print $fd "nrepreset: ", int(@{$self->{symops}}), "\n";
    print $fd "representatives:\n";
    for my $symop (@{$self->{symops}}) {
        print $fd "    ", string_from_symop( $symop ), "\n"
    }
    print $fd "nsymops:   ", int(@{$self->all_symops()}), "\n";
    print $fd "symops:\n";
    for my $symop (@{$self->all_symops()}) {
        print $fd "    ", string_from_symop( $symop ), "\n"
    }
    print $fd "inversion: ", $self->{has_inversion}, "\n";
    if( $self->{inversion_translation} ) {
        local $" = ", ";
        print( $fd "inversion translation: @{$self->{inversion_translation}}",
               "\n" );
    }
    print $fd "centering: ";
    for (@{$self->{centering_translations}}) {
        local $, = ",";
        print $fd @$_;
        print $fd " ";
    }
    print $fd "\n";
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
                    snap_to_crystallographic(
                        flush_zeros_in_symop(
                            symop_modulo_1(
                                symop_translate(
                                    symop_mul( $symop, $inversion ),
                                    $translation
                                )
                            )
                        )
                    );
                push( @symops, $final_symop );
            }
        }
    }

    return wantarray ? @symops : \@symops;
}

sub all_symops_ref
{
    my ($self) = @_;
    my @symops = $self->all_symops();
    return \@symops;
}

sub check_inversion_translation
{
    my ($self) = @_;

    # "Furthermore, if an inversion with translation part w_I is
    # present, another centering vector Δw can arise for each element
    # (W_L,w_L) in the list of representative matrices, /.../:
    #
    # Δw = W_L * w_I + 2 * w_L - w_I."

    if( $self->{has_inversion} && defined $self->{inversion_translation} ) {
        for my $symop (@{$self->{symops}}) {
            my $symop_translation = symop_translation( $symop );
            my $rotation = symop_set_translation( $symop, [0,0,0] );
            my $product =
                symop_vector_mul( $rotation, $self->{inversion_translation} );
            my $new_translation =
                vector_sub(
                    vector_add(
                        $product,
                        [
                          2*$symop_translation->[0],
                          2*$symop_translation->[1],
                          2*$symop_translation->[2],
                        ]
                    ),
                    $self->{inversion_translation}
                );
            do {
                local $" = ", ";
                print STDERR ">>>> symop     translation " .
                    "@{$symop_translation}\n";
                print STDERR ">>>> inversion translation " .
                    "@{$self->{inversion_translation}}\n";
                print STDERR ">>>> inserting new translation " .
                    "@{$new_translation}\n";
            } if $debug;
            $self->insert_translation( $new_translation );
        }
    }
}

sub insert_translation
{
    my ($self, $translation, $symop) = @_;

    $translation =
        snap_to_crystallographic(
            vector_modulo_1(
                round_vector( $translation )
            )
        );

    # Check whether the centering vector is present and if not, add
    # it:
    if( $self->has_translation( $translation ) ) {
        return;
    }

    do {
        local $" = ", ";
        print STDERR ">>> adding translation: @{$translation}\n";
    } if $debug;

    my @new_translations = ( $translation );
    my @added_translations = @new_translations;
    push( @{$self->{centering_translations}}, $translation );
    ## $translation = undef;

    while( @new_translations ) {
        my $test_translation = shift( @new_translations );
        my @new_sums = ();
        for my $t (@{$self->{centering_translations}}) {
            my $sum =
                snap_to_crystallographic(
                    vector_modulo_1 (
                        vector_add( $test_translation, $t )
                    )
                );
            local $" = ", ";
            if( !$self->has_translation( $sum ) ) {
                push( @new_sums, $sum );
            }
        }
        if( @new_sums ) {
            push( @{$self->{centering_translations}}, @new_sums );
            push( @new_translations, @new_sums );
            push( @added_translations, @new_sums );
        }
    }

    if( defined $symop ) {
        for my $s (@{$self->{symops}}) {
            for my $t (@{$self->{centering_translations}}) {
                my $translation_operator =
                    symop_set_translation( $unity_symop, $t );
                my $product =
                    snap_to_crystallographic(
                        symop_modulo_1(
                            symop_mul( $s, $translation_operator )
                        )
                    );
                #print ">>>> ", string_from_symop( $s ), "\n";
                #print "ppp> ", string_from_symop( $product ), "\n";
                #$self->insert_symop( $product );
                my $existing_operator = $self->has_matrix( $product );
                if( defined $existing_operator ) {
                    my $additional_translation =
                        vector_modulo_1(
                            vector_sub(
                                symop_translation( $product ),
                                symop_translation( $existing_operator )
                            )
                        );
                    $self->insert_translation(
                        $additional_translation,
                        $product );
                }
            }
            #print "\n";
        }
    }
}

sub insert_representative_matrix
{
    my ($self, $symop) = @_;

    push( @{$self->{symops}}, $symop );
    for my $s (@{$self->{symops}}) {
        my $product =
            snap_to_crystallographic(
                symop_modulo_1( symop_mul( $s, $symop ))
            );
        $self->insert_symop( $product );
    }
}

sub insert_symop
{
    my ($self, $symop) = @_;

    $symop = snap_to_crystallographic(symop_modulo_1( $symop ));

    print STDERR ">>>> checking operator ", string_from_symop($symop), "\n"
        if $debug;

    if( symop_is_inversion( $symop )) {
        if( $self->{has_inversion} ) {
            my $translation = symop_translation( $symop );
            my $new_centering = vector_sub( $self->{inversion_translation},
                                            $translation );
            $self->insert_translation( $new_centering,
                                       snap_to_crystallographic(
                                           symop_mul( $inversion_symop, $symop )
                                       )
                );
        } else {
            $self->{has_inversion} = 1;
            $self->{inversion_translation} = symop_translation( $symop );
            $self->check_inversion_translation();
        }
    } else {
        my $existing_symop;
        if( defined ($existing_symop = $self->has_matrix( $symop ))) {
            my $existing_translation = symop_translation( $existing_symop );
            my $translation = symop_translation( $symop );
            $self->insert_translation(
                vector_sub( $existing_translation, $translation ), $symop );
        } else {
            my $inverted_symop =
                snap_to_crystallographic(
                    symop_mul( $inversion_symop, $symop )
                );
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
                        snap_to_crystallographic(
                            symop_mul( $existing_symop, $translated_inversion )
                        );
                    my $existing_translation = symop_translation( $translated_symop );
                    my $translation = symop_translation( $symop );
                    $self->insert_translation(
                        vector_sub( $existing_translation, $translation ), $symop );
                }
                $self->check_inversion_translation();
            } else {
                $self->insert_representative_matrix( $symop );
                $self->check_inversion_translation();
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
        if( symop_matrices_are_equal( $s, $symop )) {
            return $s;
        }
    }
    return undef;
}

sub has_translation
{
    my ($self, $translation) = @_;

    for my $t (@{$self->{centering_translations}}) {
        if( vectors_are_equal( $t, $translation )) {
            return $t;
        }
    }
    return undef;
}

sub insert_symop_string
{
    my ($self, $symop_string) = @_;

    my $symop = symop_from_string( $symop_string );
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
