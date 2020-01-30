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
#* both the COD_ENTRY_ISSUE loop and the '_cod_error_flag' data item.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( is_retracted );

my $data_block =
{
    'name'   => 'cod_retracted_both',
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
                  '_cod_error_flag' => [ 'retracted' ],
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

# Both approaches describe the block as being retracted
if (is_retracted($data_block)) {
    print 'Data block \'' . $data_block->{'name'} . '\' is marked as retracted.' . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' is not marked as retracted.' . "\n";
}

# Only the COD_ENTRY_ISSUE loop describes the block as being retracted
$data_block->{'values'}{'_cod_error_flag'}[0] = 'none';
if (is_retracted($data_block)) {
    print 'Data block \'' . $data_block->{'name'} . '\' is marked as retracted.' . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' is not marked as retracted.' . "\n";
}

# Only the '_cod_error_flag' data item describes the block as being retracted
$data_block->{'values'}{'_cod_error_flag'}[0] = 'retracted';
$data_block->{'values'}{'_cod_entry_issue.severity'}[3] = 'none';
if (is_retracted($data_block)) {
    print 'Data block \'' . $data_block->{'name'} . '\' is marked as retracted.' . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' is not marked as retracted.' . "\n";
}

# None of the approaches describe the block as being retracted
$data_block->{'values'}{'_cod_error_flag'}[0] = 'none';
if (is_retracted($data_block)) {
    print 'Data block \'' . $data_block->{'name'} . '\' is marked as retracted.' . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' is not marked as retracted.' . "\n";
}


END_SCRIPT
