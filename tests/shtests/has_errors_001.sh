#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/CODFlags.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( has_errors )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::CODFlags::has_errors subroutine.
#* Tests the way the subroutine behaves when the input data block contains
#* issues of the error severity.
#**

use strict;
use warnings;

# use COD::CIF::Data::CODFlags qw( has_errors );

my $data_block =
{
    'name'   => 'cod_errors_entry_issues',
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

if (has_errors($data_block)) {
    print 'Data block \'' . $data_block->{'name'} . '\' contains errors.' . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' does not contain errors.' . "\n";
}

END_SCRIPT
