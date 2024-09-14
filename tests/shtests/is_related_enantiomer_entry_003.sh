#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/CODNumbers.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE}" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::CODNumbers::is_related_enantiomer_entry()
#* subroutine. Tests the way the subroutine behaves when only one of the entries
#* refers to the other entry as a related enantiomer entry using the
#* 'related_enantiomer_entries' field.
#**

use strict;
use warnings;

# use COD::CIF::Data::CODNumbers;

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
    'related_enantiomer_entries' => [
        '0000002'
    ]
};

my $entry_2 = {
    'id' => '0000002',
};

run_test($entry_1, $entry_2);
run_test($entry_2, $entry_1);

END_SCRIPT
