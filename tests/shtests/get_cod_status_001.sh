#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/CIF2COD.pm
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
#* Unit test for the COD::CIF::Data::CIF2COD::get_cod_status subroutine.
#* Tests the way the subroutine behaves when the input data block contains
#* the '_cod_entry_issue.severity' data item with various flag values.
#**

use strict;
use warnings;

# use COD::CIF::Data::CIF2COD;

my $data_block =
{
    'name'   => 'cod_entry_issues',
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

my $value = COD::CIF::Data::CIF2COD::get_cod_status($data_block);
if (defined $value) {
    print 'Data block \'' . $data_block->{'name'} . "' has the '$value' status." . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' has an undefined status.' . "\n";
}

$data_block->{'values'}{'_cod_entry_issue.severity'}[3] = 'note';
$value = COD::CIF::Data::CIF2COD::get_cod_status($data_block);
if (defined $value) {
    print 'Data block \'' . $data_block->{'name'} . "' has the '$value' status." . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' has an undefined status.' . "\n";
}

$data_block->{'values'}{'_cod_entry_issue.severity'}[2] = 'note';
$value = COD::CIF::Data::CIF2COD::get_cod_status($data_block);
if (defined $value) {
    print 'Data block \'' . $data_block->{'name'} . "' has the '$value' status." . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' has an undefined status.' . "\n";
}

# Data item contains a value that is allowed by the DDL1 dictionary,
# but not by the SQL schema 
$data_block->{'values'}{'_cod_entry_issue.severity'}[1] = 'note';
$value = COD::CIF::Data::CIF2COD::get_cod_status($data_block);
if (defined $value) {
    print 'Data block \'' . $data_block->{'name'} . "' has the '$value' status." . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' has an undefined status.' . "\n";
}

# Data item contains a value that is allowed neither by the DDL1 dictionary,
# nor by the SQL schema
$data_block->{'values'}{'_cod_entry_issue.severity'}[0] = 'unknown';
$data_block->{'values'}{'_cod_entry_issue.severity'}[1] = 'unknown';
$data_block->{'values'}{'_cod_entry_issue.severity'}[2] = 'unknown';
$data_block->{'values'}{'_cod_entry_issue.severity'}[3] = 'unknown';
$value = COD::CIF::Data::CIF2COD::get_cod_status($data_block);
if (defined $value) {
    print 'Data block \'' . $data_block->{'name'} . "' has the '$value' status." . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' has an undefined status.' . "\n";
}

END_SCRIPT
