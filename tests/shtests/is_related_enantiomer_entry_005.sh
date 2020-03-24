#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Data/CODNumbers.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#* NOTE: this test cover a part of the code that is deprecated and will be
#* removed in the future.
#*
#* Unit test for the COD::CIF::Data::CODNumbers::is_related_enantiomer_entry()
#* subroutine. Tests the way the subroutine behaves when one of the entries
#* refer to the other entry as a related enantiomer entry using the
#* 'enantiomer' field.
#**

use strict;
use warnings;

use COD::CIF::Data::CODNumbers;

sub run_test
{
    my ($main_entry, $related_entry) = @_;

    my $is_enantiomer = COD::CIF::Data::CODNumbers::is_related_enantiomer_entry(
        $main_entry,
        $related_entry
    );
    if ( $is_enantiomer ) {
        print "Entry '$main_entry->{'id'}' references entry " .
              "'$related_entry->{'id'}' as a related enantiomer entry." . "\n";
    } else {
        print "Entry '$main_entry->{'id'}' does not reference entry " .
              "'$related_entry->{'id'}' as a related enantiomer entry." . "\n";
    }
}

my $entry_1 = {
    'id' => '0000001',
    'enantiomer' => {
        '_cod_related_enantiomer_entry.code' => '0000003',
        '_cod_related_enantiomer_entry_code' => '0000003',
        '_cod_enantiomer_of' => '0000002',
    }
};

my $entry_2 = {
    'id' => '0000002',
    'enantiomer' => {
        '_cod_related_enantiomer_entry.code' => '0000004',
        '_cod_related_enantiomer_entry_code' => '0000003',
    }
};

run_test($entry_1, $entry_2);
run_test($entry_2, $entry_1);

END_SCRIPT
