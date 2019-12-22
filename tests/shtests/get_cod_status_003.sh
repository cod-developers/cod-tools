#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Data/CIF2COD.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::CIF2COD::get_cod_status subroutine.
#* Tests the way the subroutine behaves when the input data block contains
#* the '_cod_entry_issue.severity' data item with various flag values.
#**

use strict;
use warnings;

use COD::CIF::Data::CIF2COD;

my $data_block =
{
    'name'   => 'cod_status_both_approaches',
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
                  '_cod_error_flag' => [ 'note' ],
                  '_cod_entry_issue.id' => [
                    '1', '2', '3', '4'
                  ],
                  '_cod_entry_issue.severity' => [
                    'note', 'note', 'note', 'note'
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

# Structure marked as retracted using the '_cod_error_flag' data item
$data_block->{'values'}{'_cod_error_flag'}[0] = 'retracted';
my $value = COD::CIF::Data::CIF2COD::get_cod_status($data_block);
if (defined $value) {
    print 'Data block \'' . $data_block->{'name'} . "' has the '$value' status ('retracted' status expected)." . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . "' has an undefined status ('retracted' status expected)." . "\n";
}

# Structure marked as having errors using the '_cod_error_flag' data item
$data_block->{'values'}{'_cod_error_flag'}[0] = 'errors';
$value = COD::CIF::Data::CIF2COD::get_cod_status($data_block);
if (defined $value) {
    print 'Data block \'' . $data_block->{'name'} . "' has the '$value' status ('errors' status expected)." . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . "' has an undefined status ('errors' status expected)." . "\n";
}

# Structure marked as having warnings using the '_cod_error_flag' data item
$data_block->{'values'}{'_cod_error_flag'}[0] = 'warnings';
$value = COD::CIF::Data::CIF2COD::get_cod_status($data_block);
if (defined $value) {
    print 'Data block \'' . $data_block->{'name'} . "' has the '$value' status ('warnings' status expected)." . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . "' has an undefined status ('warnings' status expected)." . "\n";
}

# Structure marked as retracted using the '_cod_entry_issue.severity' data item
$data_block->{'values'}{'_cod_entry_issue.severity'}[3] = 'retraction';
$data_block->{'values'}{'_cod_error_flag'}[0] = 'note';
$value = COD::CIF::Data::CIF2COD::get_cod_status($data_block);
if (defined $value) {
    print 'Data block \'' . $data_block->{'name'} . "' has the '$value' status ('retracted' status expected)." . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . "' has an undefined status ('retracted' status expected)." . "\n";
}

# Structure marked as having errors using the '_cod_entry_issue.severity' data item
$data_block->{'values'}{'_cod_entry_issue.severity'}[3] = 'error';
$data_block->{'values'}{'_cod_error_flag'}[0] = 'note';
$value = COD::CIF::Data::CIF2COD::get_cod_status($data_block);
if (defined $value) {
    print 'Data block \'' . $data_block->{'name'} . "' has the '$value' status ('errors' status expected)." . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . "' has an undefined status ('errors' status expected)." . "\n";
}

# Structure marked as having warnings using the '_cod_entry_issue.severity' data item
$data_block->{'values'}{'_cod_entry_issue.severity'}[3] = 'warning';
$data_block->{'values'}{'_cod_error_flag'}[0] = 'note';
$value = COD::CIF::Data::CIF2COD::get_cod_status($data_block);
if (defined $value) {
    print 'Data block \'' . $data_block->{'name'} . "' has the '$value' status ('warnings' status expected)." . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . "' has an undefined status ('warnings' status expected)." . "\n";
}

# Structure marked as having warnings using the '_cod_entry_issue.severity'
# data item and as having errors using the '_cod_error_flag' data item
$data_block->{'values'}{'_cod_entry_issue.severity'}[3] = 'warning';
$data_block->{'values'}{'_cod_error_flag'}[0] = 'errors';
$value = COD::CIF::Data::CIF2COD::get_cod_status($data_block);
if (defined $value) {
    print 'Data block \'' . $data_block->{'name'} . "' has the '$value' status ('errors' status expected)." . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' has an undefined status (\'errors\' status expected).' . "\n";
}

# Structure marked as being retracted using the '_cod_entry_issue.severity'
# data item and as having errors using the '_cod_error_flag' data item
$data_block->{'values'}{'_cod_entry_issue.severity'}[3] = 'retraction';
$data_block->{'values'}{'_cod_error_flag'}[0] = 'errors';
$value = COD::CIF::Data::CIF2COD::get_cod_status($data_block);
if (defined $value) {
    print 'Data block \'' . $data_block->{'name'} . "' has the '$value' status ('retracted' status expected)." . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' has an undefined status (\'retracted\' status expected).' . "\n";
}

END_SCRIPT
