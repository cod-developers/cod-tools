#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Data/CODFlags.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::CODFlags::has_issue_severity_value
#* subroutine. Tests the way the subroutine behaves when the input data
#* block contains issues of the requested severity. Uses dotless data names.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags;

my $data_block =
{
    'name'   => 'cod_entry_issues',
    'tags'   => [
                  '_cod_entry_issue_id',
                  '_cod_entry_issue_severity'
                ],
    'loops'  => [
                  [ '_cod_entry_issue_id', '_cod_entry_issue_severity' ],
                ],
    'inloop' => {
                  '_cod_entry_issue_id' => 0,
                  '_cod_entry_issue_severity' => 0,
                },
    'values' => {
                  '_cod_entry_issue_id' => [
                    '1', '2', '3', '4'
                  ],
                  '_cod_entry_issue_severity' => [
                    'note', 'warning', 'error', 'retraction'
                  ],
                },
    'precisions' => {},
    'types'  => { 
                  '_cod_entry_issue_id' => [
                    'INT', 'INT', 'INT', 'INT'
                  ],
                  '_cod_entry_issue_severity' => [
                    'UQSTRING', 'UQSTRING', 'UQSTRING', 'UQSTRING'
                  ]
                }
};

if (COD::CIF::Data::CODFlags::has_issue_severity_value($data_block, 'note')) {
    print "At least one issue of the 'note' severity was located.\n";
} else {
    print "No issues of the 'note' severity were located.\n";
}

if (COD::CIF::Data::CODFlags::has_issue_severity_value($data_block, 'warning')) {
    print "At least one issue of the 'warning' severity was located.\n";
} else {
    print "No issues of the 'warning' severity were located.\n";
}

if (COD::CIF::Data::CODFlags::has_issue_severity_value($data_block, 'error')) {
    print "At least one issue of the 'error' severity was located.\n";
} else {
    print "No issues of the 'error' severity were located.\n";
}

if (COD::CIF::Data::CODFlags::has_issue_severity_value($data_block, 'retraction')) {
    print "At least one issue of the 'retraction' severity was located.\n";
} else {
    print "No issues of the 'retraction' severity were located.\n";
}

END_SCRIPT
