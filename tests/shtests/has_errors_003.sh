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
#* Unit test for the COD::CIF::Data::CODFlags::has_errors subroutine.
#* Tests the way the subroutine behaves when the input data block contains
#* both the COD_ENTRY_ISSUE loop and the '_cod_error_flag' data item.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( has_errors );

my $data_block =
{
    'name'   => 'cod_warnings_both',
    'tags'   => [
                  '_cod_error_flag',
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
                  '_cod_error_flag' => [ 'errors' ],
                  '_cod_entry_issue.id' => [
                    '1', '2', '3', '4'
                  ],
                  '_cod_entry_issue.severity' => [
                    'note', 'warning', 'error', 'retraction'
                  ],
                },
    'precisions' => {},
    'types'  => {
                  '_cod_error_flag' => [ 'UQSTRING' ],
                  '_cod_entry_issue.id' => [
                    'INT', 'INT', 'INT', 'INT'
                  ],
                  '_cod_entry_issue.severity' => [
                    'UQSTRING', 'UQSTRING', 'UQSTRING', 'UQSTRING'
                  ]
                }
};

# Both approaches describe the block as having warnings
if (has_errors($data_block)) {
    print 'Data block \'' . $data_block->{'name'} . '\' contains errors.' . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' does not contain errors.' . "\n";
}

# Only the COD_ENTRY_ISSUE loop describes the block as having errors
$data_block->{'values'}{'_cod_error_flag'}[0] = 'none';
if (has_errors($data_block)) {
    print 'Data block \'' . $data_block->{'name'} . '\' contains errors.' . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' does not contain errors.' . "\n";
}

# Only the '_cod_error_flag' data item describes the block as having errors
$data_block->{'values'}{'_cod_error_flag'}[0] = 'errors';
$data_block->{'values'}{'_cod_entry_issue.severity'}[2] = 'none';
if (has_errors($data_block)) {
    print 'Data block \'' . $data_block->{'name'} . '\' contains errors.' . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' does not contain errors.' . "\n";
}

# None of the approaches describe the block as having errors
$data_block->{'values'}{'_cod_error_flag'}[0] = 'none';
if (has_errors($data_block)) {
    print 'Data block \'' . $data_block->{'name'} . '\' contains errors.' . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' does not contain errors.' . "\n";
}


END_SCRIPT
