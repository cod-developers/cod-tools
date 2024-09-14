#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/ChangeLog.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw(append_changelog_to_single_item )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::ChangeLog::append_changelog_to_single_item()
#* subroutine. Tests the way the subroutine behaves when the input changelog
#* data item already exists in the processed data block. The subroutine should
#* append to the existing changelog value.
#**

use strict;
use warnings;

# use COD::CIF::ChangeLog qw( append_changelog_to_single_item );

my $changelog_item = '_cod_depositor_comments';

my $data_block =
{
    'name'   => 'existing_changelog',
    'tags'   => [
                  $changelog_item
                ],
    'loops'  => [
                ],
    'inloop' => {
                },
    'values' => {
                  $changelog_item => [
                    (
                      "\nThis is previous changelog message.\n" .
                      "It contains important information.\n" .
                      "\n" .
                      "Name Surname"
                    )
                  ]
                },
    'precisions' => {},
    'types'  => {
                }
};

append_changelog_to_single_item(
    $data_block,
    [ 'This is a new changelog message.' ],
    {
      'data_name' => $changelog_item,
    }
);

print "# Tags:\n";
print join "\n", @{$data_block->{'tags'}};

print "\n\n";

print "# Changelog value:\n";
print join "\n", @{$data_block->{'values'}{$changelog_item}};

print "\n";

END_SCRIPT
