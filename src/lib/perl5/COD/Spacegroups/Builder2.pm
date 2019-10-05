#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*

# A Perl object to build all spacegroup operators and spacegroup
# description from symmetry operators supplied one by one or as a
# list.

# This module, the Builder, implements the optimised spacegroup
# building algorthmas described in [1], according to my (S.G.)
# understanding. The algebra should follow pretty closely the text of
# the paper; all bugs, if present, are mine (S.G. ;).

# [1]. Grosse-Kunstleve, R. W. Algorithms for deriving
# crystallographic space-group information. Acta
# crystallographica. Section A, Foundations of crystallography, 1999,
# 55, 383-395. URL: https://doi.org/10.1107/S0108767398010186

#**

package COD::Spacegroups::Builder2;

use strict;
use warnings;
use COD::Algebra::Vector qw( vector_sub vector_add vector_modulo_1
                             vector_is_zero vectors_are_equal
                           );
use COD::Spacegroups::Symop::Parse qw( symop_from_string string_from_symop );
use COD::Spacegroups::Symop::Algebra qw(
    symop_mul symop_modulo_1 symop_translate symop_translation
    symop_set_translation symop_is_inversion symop_matrices_are_equal
    symop_is_translation
    symop_vector_mul
);

use fields qw(
    symops has_inversion inversion_translation centering_translations
    inversion_symop
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

sub snap_number_to_crystallographic
{
    my ($value, $eps) = @_;

    $eps = 1E-6 unless defined $eps;

    if( abs($value) < $eps ) {
        return 0.0;
    }
    if( abs($value - 1) < $eps ) {
        return 1.0;
    }
    if( abs($value - 1/2) < $eps ) {
        return 1/2;
    }
    if( abs($value - 1/3) < $eps ) {
        return 1/3;
    }
    if( abs($value - 2/3) < $eps ) {
        return 2/3;
    }
    if( abs($value - 1/4) < $eps ) {
        return 1/4;
    }
    if( abs($value - 3/4) < $eps ) {
        return 3/4;
    }
    if( abs($value - 1/6) < $eps ) {
        return 1/6;
    }
    if( abs($value - 5/6) < $eps ) {
        return 5/6;
    }
    if( abs($value - 1) < $eps ) {
        return 1;
    }

    return $value;
}

sub snap_to_crystallographic
{
    my ($vector) = @_;

    for(@$vector) {
        if( ref $_ ) {
            snap_to_crystallographic( $_ );
        } else {
            $_ = snap_number_to_crystallographic( $_ );
        }
    }
    return $vector;
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
                    symop_modulo_1(
                        snap_to_crystallographic(
                            symop_translate( symop_mul( $symop, $inversion ),
                                             $translation )
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
    # Δw = W_L * w_I + 2 * w_L - w_I." [1].

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
                print STDERR ">>>> symop     translation @{$symop_translation}\n";
                print STDERR ">>>> inversion translation @{$self->{inversion_translation}}\n";
                print STDERR ">>>> inserting new translation @{$new_translation}\n";
            } if $debug;
            $self->insert_translation( $new_translation );
        }
    }
}

sub insert_translation
{
    my ($self, $translation) = @_;

    $translation =
        snap_to_crystallographic(
            vector_modulo_1( 
                $translation
            )
        );

    # Check whether the centering vector is present and if not, add
    # it:
    if( $self->has_translation( $translation ) ) {
        return;
    }

    my @new_translations = ( $translation );
    my @added_translations = @new_translations;
    push( @{$self->{centering_translations}}, $translation );
    $translation = undef;

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
    
    # "Each centering vector has to be multiplied with all rotation
    # matrices in the list of representative symmetry matrices to
    # possibly generate additional centering vectors":

    # Assume the all previous translations have been checked against
    # all current representative matrices; wee only need to check the
    # new rotations and try to add them (S.G.):
    foreach my $t (@added_translations) {
        foreach my $s (@{$self->{symops}}) {
            my $translation_operator =
                symop_set_translation( $unity_symop, $t );
            my $product =
                snap_to_crystallographic(
                    symop_modulo_1(
                        symop_mul( $s, $translation_operator )
                    )
                );
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
    }
}

sub insert_representative_matrix
{
    my ($self, $symop) = @_;

    $symop = symop_modulo_1(snap_to_crystallographic( $symop ));

    if( $self->has_matrix( $symop ) ) {
        return;
    }

    ##print STDERR ">> adding symop ", string_from_symop( $symop ), " to the representative list\n";

    my @new_symops = ( $symop );
    my @added_symops = @new_symops;
    push( @{$self->{symops}}, $symop );
    ##$symop = undef;
    
    #while( @new_symops ) {
        ##my $test_symop = shift( @new_symops );
        ##my @new_products = ();
        for my $group_symop (@{$self->{symops}}) {
            my $product = 
                snap_to_crystallographic(
                    symop_modulo_1(
                        ##symop_mul( $group_symop, $test_symop )
                        symop_mul( $group_symop, $symop )
                    )
                );
            if( !$self->has_matrix( $product ) ) {
                ##print STDERR ">> pushing symop ", string_from_symop( $product ), " to the new product list\n";
                ##push( @new_products, $product );
                push( @added_symops, $product );
                $self->insert_symop( $product );
            }
            ## if( !$self->has_matrix( $product ) ) {
            ##     print STDERR ">> pushing symop ", string_from_symop( $product ), " to the representative list\n";
            ##     push( @new_products, $product );
            ## }
            ## else {
            ##     # The following call should insert the new centering
            ##     # operator if necessary (S.G.):
            ##     $self->insert_symop( $product );
            ## }
        }
        ## if( @new_products ) {
        ##     #push( @{$self->{symops}}, @new_products );
        ##     #for my $s (@new_products) {
        ##     #    $self->insert_symop( $s );
        ##     #}
        ##     push( @new_symops, @new_products );
        ##     push( @added_symops, @new_products );
        ## }
        ## if( $debug ) {
        ##     print( STDERR ">>> insert_representative_matrix - " .
        ##            "symops available: ",
        ##            int(@{$self->{symops}}), "\n" );
        ##     for (@{$self->{symops}}) {
        ##         print STDERR string_from_symop( $_ ), "\n";
        ##     }
        ##     print STDERR ">>>  insert_representative_matrix - " .
        ##         "symops to go: ", int(@new_symops), "\n";
        ##     for (@new_symops) {
        ##         print STDERR string_from_symop( $_ ), "\n";
        ##     }
        ##     print STDERR "\n";
        ## }
    #} # while()

    # "Each centering vector has to be multiplied with all rotation
    # matrices in the list of representative symmetry matrices to
    # possibly generate additional centering vectors":

    # Assume the all previous representatibe matrices have been
    # checked against all current centering vectors; wee only need to
    # check the new rotations and try to add them (S.G.):
    foreach my $s (@added_symops) {
        foreach my $t (@{$self->{centering_translations}}) {
            my $translation_symop = symop_set_translation( $unity_symop, $t );
            my $st = 
                snap_to_crystallographic(
                    symop_modulo_1(
                        symop_mul( $s, $translation_symop )
                    )
                );
            my $new_translation = 
                snap_to_crystallographic(
                    vector_modulo_1(
                        vector_sub( 
                            symop_translation( $st ),
                            $t
                        )
                    )
                );
            do {
                local $" = ", ";
                print STDERR ">>>>> s : ", string_from_symop($s), "\n";
                print STDERR ">>>>> ts: ", string_from_symop($translation_symop), "\n";
                print STDERR ">>>>> st: ", string_from_symop($st), "\n";
                print STDERR ">>>>> inserting translation @{$new_translation}\n";
            } if $debug;
            $self->insert_translation( $new_translation );
        }
    }
}

sub insert_symop
{
    my ($self, $symop) = @_;

    $symop = snap_to_crystallographic( symop_modulo_1( $symop ) );

    ##print STDERR ">> inserting symop ", string_from_symop( $symop ), "\n";
    
    if( symop_is_translation($symop) ) {
        # This branch is strictly speaking not necessary, since pure
        # translation will be recognised as having the same matrix as
        # the unity operator...
        my $translation = symop_translation( $symop );
        $self->insert_translation( $translation );
    }
    elsif( symop_is_inversion($symop) ) {
        ##print STDERR ">> symop ", string_from_symop( $symop ), " is inversion\n";
        if( $self->{has_inversion} ) {
            my $translation = symop_translation( $symop );
            my $new_centering = vector_sub( $self->{inversion_translation},
                                            $translation );
            $self->insert_translation( $new_centering );
        } else {
            $self->{has_inversion} = 1;
            $self->{inversion_translation} = symop_translation( $symop );
            $self->check_inversion_translation();
        }
    }
    else {
        my $existing_symop = $self->has_matrix( $symop );

        ##print( STDERR ">> symop ", string_from_symop( $symop ), " is NOT an inversion\n" );

        if( defined $existing_symop ) {
            ##print( STDERR ">> symop ", string_from_symop( $symop ), " exists as ",
            ##       string_from_symop( $existing_symop ), "\n" );

            my $delta_translation =
                vector_sub(
                    symop_translation( $symop ),
                    symop_translation( $existing_symop )
                );
            $self->insert_translation( $delta_translation );
        } else {
            my $inverted_symop =
                snap_to_crystallographic(
                    symop_mul( $inversion_symop, $symop )
                );
            my $existing_inverted = $self->has_matrix( $inverted_symop );
            if( defined $existing_inverted ) {
                ##print( STDERR ">> symop ", string_from_symop( $symop ), " exists as INVERTED ",
                ##       string_from_symop( $existing_inverted ), "\n" );

                my $existing_translation = symop_translation( $existing_inverted );
                my $delta_translation =
                    snap_to_crystallographic(
                        vector_modulo_1(
                            vector_add( 
                                symop_translation( $symop ),
                                symop_translation( $inverted_symop )
                            )
                        )
                    );
                # FIXME: check what to do if inversion with different
                # translation is already present (S.G.).
                if( !$self->{has_inversion} ) {
                    $self->{has_inversion} = 1;
                    $self->{inversion_translation} = $delta_translation;
                } else {
                    $self->insert_translation( 
                        vector_sub( 
                            $delta_translation,
                            $self->{inversion_translation}
                        ));
                }
                $self->check_inversion_translation();
            } else {
                ##print( STDERR ">> passing symop ", string_from_symop( $symop ), " to 'insert_representative_matrix'\n" );
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
