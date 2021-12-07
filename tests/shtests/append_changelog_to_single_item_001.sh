#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/ChangeLog.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::ChangeLog::append_changelog_to_single_item()
#* subroutine. Tests the way the subroutine behaves when the input changelog
#* data item does not exist in the processed data block. The subroutine should
#* not only add the changelog value, but also the changelog data item name
#* to the tag array.
#**

use strict;
use warnings;

use COD::CIF::ChangeLog qw( append_changelog_to_single_item );

my $changelog_item = '_cod_depositor_comments';

my $data_block =
{
    'name'   => 'no_changelog',
    'tags'   => [
                ],
    'loops'  => [
                ],
    'inloop' => {
                },
    'values' => {
                },
    'precisions' => {},
    'types'  => {
                }
};

append_changelog_to_single_item(
    $data_block,
    [ 'New log message' ],
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
