#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Tags/Print.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Tags::Print::sprint_loop_packet() subroutine.
#* Tests the way the subroutine behaves when the packet consists of a single
#* data item of various types.
#**

use strict;
use warnings;

use COD::CIF::Tags::Print;

my $options = {
    'fold_long_fields' => 0,
    'folding_width'    => 80,
    'cif_version'      => '1.1',
};
my $test_tag = '_tag';

my $data_block = {
  'name' => 'test',
  'cifversion' => {
    'major' => 1,
    'minor' => 1
  },
  'inloop' => {
    "$test_tag" => 0
  },
  'loops' => [
    [
      "$test_tag"
    ]
  ],
  'precisions' => {},
  'save_blocks' => [],
  'tags' => [
    "$test_tag"
  ],
  'types' => {
    "$test_tag" => [
      'UQSTRING'
    ]
  },
  'values' => {
    "$test_tag" => [
      'Placeholder.'
    ]
  }
};

print "# Multiline text field value\n";
print "loop_\n";
print "_tag\n";
$data_block->{'values'}{$test_tag}[0] = "\nMultiline\nvalue";
$data_block->{'types'}{$test_tag}[0] = 'TEXTFIELD';
print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    [ $test_tag ],
                    0,
                    $options,
                );

print "# Long value\n";
print "loop_\n";
print "_tag\n";
$data_block->{'values'}{$test_tag}[0] = 'Loop-value-that-is-longer-than-the-maximum-line-length-and-is-thus-handled-differently.';
$data_block->{'types'}{$test_tag}[0] = 'UQSTRING';
print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    [ $test_tag ],
                    0,
                    $options,
                );

print "# Short value\n";
print "loop_\n";
print "_tag\n";
$data_block->{'values'}{$test_tag}[0] = 'Short value';
$data_block->{'types'}{$test_tag}[0] = 'SQSTRING';
print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    [ $test_tag ],
                    0,
                    $options,
                );

END_SCRIPT
