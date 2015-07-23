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
#  Check whether COD::Spacegroups::Builder.pm correctly builds all spacegroups.
#**

use strict;
use warnings;

use COD::Spacegroups::Builder;
use COD::Spacegroups::Lookup::COD;
use COD::Spacegroups::Symop::Parse;

# Identify the spacegroup from the symmetry operators:

sub mk_symop_key
{
    my ( $symops ) = @_;

    my @canonical = sort 
        map {symop_string_canonical_form($_)} @$symops;
    my $key = join( ";", @canonical );
    return $key;
}

sub mkhash
{
    if( 1 ) {
        map { (mk_symop_key($_->{symops}), $_) }
        @COD::Spacegroups::Lookup::COD::table,
        @COD::Spacegroups::Lookup::COD::extra_settings;
    #} else {
    #        map { (mk_symop_key($_->{symops}), $_) } @CCP4SymopLookup::table;
    }
}

my %symop_lookup_table = mkhash();

for my $sg_data (@COD::Spacegroups::Lookup::COD::table) {

    my $spacegroup = new COD::Spacegroups::Builder;

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
