#! /bin/sh

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
#*
#* Unit test for the COD::CIF::Data::CODNumbers::have_equiv_bibliographies
#* subroutine. Tests the way the subroutine behaves when two entries with
#* identical bibliographies (including the DOIs) are compared.
#**

use strict;
use warnings;

use COD::CIF::Data::CODNumbers;

my $entry_1 = {
    'bibliography' => {
        '_journal_name_full'    => 'Journal of Applied Crystallography',
        '_journal_year'         => 2016,
        '_journal_volume'       => 49,
        '_journal_issue'        => 1,
        '_journal_page_first'   => 292,
        '_journal_page_last'    => 301,
        '_journal_paper_doi'    => '10.1107/S1600576715022396',
    }
};

my $entry_2 = {
    'bibliography' => {
        '_journal_name_full'    => 'Journal of Applied Crystallography',
        '_journal_year'         => 2016,
        '_journal_volume'       => 49,
        '_journal_issue'        => 1,
        '_journal_page_first'   => 292,
        '_journal_page_last'    => 301,
        '_journal_paper_doi'    => '10.1107/S1600576715022396',
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
