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
#* Unit test for the COD::CIF::Data::CODNumbers::have_equiv_bibliographies
#* subroutine. Tests the way the subroutine behaves when two entries with
#* identical bibliographies are compared. In this case, the page numbers
#* consist of more than numers and letters.
#**

use strict;
use warnings;

# use COD::CIF::Data::CODNumbers;

my $entry_1 = {
    'bibliography' => {
        '_journal_name_full'    => 'Journal of Applied Crystallography',
        '_journal_year'         => 2016,
        '_journal_volume'       => 49,
        '_journal_issue'        => 1,
        '_journal_page_first'   => 'a292',
        '_journal_page_last'    => 'a301',
    }
};

my $entry_2 = {
    'bibliography' => {
        '_journal_name_full'    => 'Journal of Applied Crystallography',
        '_journal_year'         => 2016,
        '_journal_volume'       => 49,
        '_journal_issue'        => 1,
        '_journal_page_first'   => 'a292',
        '_journal_page_last'    => 'a301',
    }
};

my $equivalent = COD::CIF::Data::CODNumbers::have_equiv_bibliographies(
    $entry_1,
    $entry_2
);

if ( $equivalent ) {
    print "Bibliographies were treated as equivalent.\n";
} else {
    print "Bibliographies were treated as not equivalent.\n";
}

END_SCRIPT
