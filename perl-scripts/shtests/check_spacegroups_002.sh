#! /bin/sh
#!perl -w # --*- Perl -*--
eval 'exec perl -x $0 ${1+"$@"}'
    if 0;
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Check whether SGBuilder.pm correctly builds all spacegroups.
#**

use strict;
use warnings;

use SGBuilder;
use SymopLookup;
use SymopParse;

# Identify the spacegroup from the symmetry operators:

sub mk_symop_key
{
    my ( $symops ) = @_;

    my @canonical = sort 
        map {SymopParse::symop_string_canonical_form($_)} @$symops;
    my $key = join( ";", @canonical );
    return $key;
}

sub mkhash
{
    if( 1 ) {
        map { (mk_symop_key($_->{symops}), $_) }
        @SymopLookup::table, @SymopLookup::extra_settings;
    }
}

my %symop_lookup_table = mkhash();

for my $sg_data (@SymopLookup::extra_settings) {

    my $spacegroup = new SGBuilder;

    $spacegroup->insert_symop_strings( $sg_data->{symops} );

    my @symops = $spacegroup->all_symops();

    my $key = mk_symop_key( [ map { string_from_symop($_) } @symops ] );

    if( exists $symop_lookup_table{$key} ) {
        my $estimated_sg = $symop_lookup_table{$key};
        print $estimated_sg->{universal_h_m}, "\n";
    } else {
        print "$0: spacegroup '$sg_data->{universal_h_m}' could not be identified\n"
    }

}
