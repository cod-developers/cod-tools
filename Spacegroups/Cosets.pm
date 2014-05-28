#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Perl package to find cosets of a subgroup in a symmetry group.
#**

package Cosets;

use strict;
use warnings;
require Exporter;
@Cosets::ISA = qw(Exporter);
@Cosets::EXPORT_OK = qw(  );

use SymopAlgebra qw( symop_mul );
use SymopParse;

sub canonical_string_from_symop
{
    my ($symop) = @_;

    return string_from_symop_reduced(
        SymopParse::symop_translation_modulo_1( $symop )
    );
}

# The 'find_cosets' returns an array of arrays with symmetry
# operators; each entry in the topmost array represents a right coset
# of a group whose operators are listed in @group_symops with respect
# to the subgroup listed in @subgroup_symops. The 0-th array element
# lists a coset with respect to the group unity element, i.e. the
# subgroup itself.

sub find_right_cosets
{
    my ($group_symops, $subgroup_symops) = @_;

    my %group_symops = map {
        ( canonical_string_from_symop($_), $_ )
    } @$group_symops;

    my %subgroup_symops = map {
        ( canonical_string_from_symop($_), $_ )
    } @$subgroup_symops;

    ## use Serialise; serialiseRef( \%group_symops );
    ## use Serialise; serialiseRef( \%subgroup_symops );

    my @cosets = ();

    # The subgroup is the first coset:
    push( @cosets, $subgroup_symops );
    for my $symop_key (keys %subgroup_symops) {
        delete $group_symops{$symop_key};
    }

    # The rest of cosets must be extracted:
    while( %group_symops ) {
        my @coset;
        my @group_symop_keys = keys %group_symops;
        my $current_symop_key = $group_symop_keys[0];
        my $current_symop = $group_symops{$current_symop_key};
        for my $subgroup_symop (@$subgroup_symops) {
            my $coset_symop = symop_mul( $subgroup_symop, $current_symop );
            my $coset_symop_key = canonical_string_from_symop( $coset_symop );
            ## print ">>> Coset element: ", $coset_symop_key, " ";
            die unless exists $group_symops{$coset_symop_key};
            push( @coset, $group_symops{$coset_symop_key} );
            delete $group_symops{$coset_symop_key};
        }
        push( @cosets, \@coset ) if @coset;
        ## print ">>>\n";
    }

    ## use Serialise; serialiseRef( \@cosets );

    return @cosets;
}

# Same function for the left cosets:

sub find_left_cosets
{
    my ($group_symops, $subgroup_symops) = @_;

    my %group_symops = map {
        ( canonical_string_from_symop($_), $_ )
    } @$group_symops;

    my %subgroup_symops = map {
        ( canonical_string_from_symop($_), $_ )
    } @$subgroup_symops;

    ## use Serialise; serialiseRef( \%group_symops );
    ## use Serialise; serialiseRef( \%subgroup_symops );

    my @cosets = ();

    # The subgroup is the first coset:
    push( @cosets, $subgroup_symops );
    for my $symop_key (keys %subgroup_symops) {
        delete $group_symops{$symop_key};
    }

    # The rest of cosets must be extracted:
    while( %group_symops ) {
        my @coset;
        my @group_symop_keys = keys %group_symops;
        my $current_symop_key = $group_symop_keys[0];
        my $current_symop = $group_symops{$current_symop_key};
        for my $subgroup_symop (@$subgroup_symops) {
            my $coset_symop = SymopAlgebra::round_values_in_symop(
                symop_mul( $current_symop, $subgroup_symop ));
            my $coset_symop_key = canonical_string_from_symop( $coset_symop );
            ## print ">>> Coset element: ", $coset_symop_key, " ";
            die unless exists $group_symops{$coset_symop_key};
            push( @coset, $group_symops{$coset_symop_key} );
            delete $group_symops{$coset_symop_key};
        }
        push( @cosets, \@coset ) if @coset;
        ## print ">>>\n";
    }

    ## use Serialise; serialiseRef( \@cosets );

    return @cosets;
}

1;
