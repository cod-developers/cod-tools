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
#* Unit test for the COD::CIF::Data::CODFlags::is_retracted subroutine.
#* Tests the way the subroutine behaves when the input data block contains
#* issues of the retraction severity.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( is_retracted );

my $data_block =
{
    'name'   => 'cod_retracted_entry_issues',
    'tags'   => [
                  '_cod_entry_issue.id',
                  '_cod_entry_issue.severity'
                ],
    'loops'  => [
                  [ '_cod_entry_issue.id', '_cod_entry_issue.severity' ],
                ],
    'inloop' => {
                  '_cod_entry_issue.id' => 0,
                  '_cod_entry_issue.severity' => 0,
                },
    'values' => {
                  '_cod_entry_issue.id' => [
                    '1', '2', '3', '4'
                  ],
                  '_cod_entry_issue.severity' => [
                    'note', 'warning', 'error', 'retraction'
                  ],
                },
    'precisions' => {},
    'types'  => { 
                  '_cod_entry_issue.id' => [
                    'INT', 'INT', 'INT', 'INT'
                  ],
                  '_cod_entry_issue.severity' => [
                    'UQSTRING', 'UQSTRING', 'UQSTRING', 'UQSTRING'
                  ]
                }
};

if (is_retracted($data_block)) {
    print 'Data block \'' . $data_block->{'name'} . '\' is marked as retracted.' . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' is not marked as retracted.' . "\n";
}

END_SCRIPT
