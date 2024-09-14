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
#* subroutine. Tests the way the subroutine behaves when entries contain
#* several references to the related enantiomer entries using the
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
        '0000002',
        '0000003',
    ]
};

my $entry_2 = {
    'id' => '0000002',
    'related_enantiomer_entries' => [
        '0000001',
        '0000003',
    ]
};

my $entry_3 = {
    'id' => '0000003',
    'related_enantiomer_entries' => [
        '0000001',
        '0000002',
    ]
};

my $entry_4 = {
    'id' => '0000004',
    'related_enantiomer_entries' => [
        '0000001',
        '0000002',
    ]
};

# Main entry contains several references and the
# related entry is the first of the referenced
run_test($entry_1, $entry_2);
run_test($entry_2, $entry_1);

# Main entry contains several references and the
# related entry is not the first of the referenced
run_test($entry_1, $entry_3);
run_test($entry_2, $entry_3);

# Main entry contains several references and the
# related entry is neither of them
run_test($entry_1, $entry_4);
run_test($entry_2, $entry_4);
run_test($entry_3, $entry_4);

END_SCRIPT
