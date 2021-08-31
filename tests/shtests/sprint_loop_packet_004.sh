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
#* Tests the way the subroutine treats values that can be interpreted as
#* 'false' by Perl under certain conditions (i.e. '0'). This test should
#* fail in case the way an empty line is checked for is changed from
#*
#* if( $line ne '' ) { ... };
#*
#* to
#*
#* if( $line ) { ... };  
#**

use strict;
use warnings;

use COD::CIF::Tags::Print;

my $options = {
    'fold_long_fields' => 0,
    'folding_width'    => 80,
    'cif_version'      => '1.1',
};
my $test_tags =
[
  '_tag_1',
  '_tag_2',
  '_tag_3',
];

my $data_block = {
  'name' => 'test',
  'cifversion' => {
    'major' => 1,
    'minor' => 1
  },
  'inloop' => {
    '_tag_1' => 0,
    '_tag_2' => 0,
    '_tag_3' => 0,
  },
  'loops' => [
    [
      @{$test_tags}
    ]
  ],
  'precisions' => {},
  'save_blocks' => [],
  'tags' => [
    @{$test_tags}
  ],
  'types' => {
    '_tag_1' => [
      'UQSTRING'
    ],
    '_tag_2' => [
      'UQSTRING'
    ],
    '_tag_3' => [
      'UQSTRING'    
    ]
  },
  'values' => {
    '_tag_1' => [
      'Placeholder.'
    ],
    '_tag_2' => [
      'Placeholder.'
    ],
    '_tag_3' => [
      'Placeholder.'
    ],
  }
};

print "# Value sequence: 0-0-0 \n";
print "loop_\n";
for my $tag (@{$test_tags}) {
    print "$tag\n";
}
$data_block->{'values'}{'_tag_1'}[0] = 0;
$data_block->{'types'}{'_tag_1'}[0] = 'UQSTRING';
$data_block->{'values'}{'_tag_2'}[0] = 0;
$data_block->{'types'}{'_tag_2'}[0] = 'UQSTRING';
$data_block->{'values'}{'_tag_3'}[0] = 0;
$data_block->{'types'}{'_tag_3'}[0] = 'UQSTRING';

print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    $test_tags,
                    0,
                    $options,
                );

print "# Value sequence: ''-''-'' \n";
print "loop_\n";
for my $tag (@{$test_tags}) {
    print "$tag\n";
}
$data_block->{'values'}{'_tag_1'}[0] = '';
$data_block->{'types'}{'_tag_1'}[0] = 'SQSTRING';
$data_block->{'values'}{'_tag_2'}[0] = '';
$data_block->{'types'}{'_tag_2'}[0] = 'SQSTRING';
$data_block->{'values'}{'_tag_3'}[0] = '';
$data_block->{'types'}{'_tag_3'}[0] = 'SQSTRING';

print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    $test_tags,
                    0,
                    $options,
                );

print "# Value sequence: 0-long-0 \n";
print "loop_\n";
for my $tag (@{$test_tags}) {
    print "$tag\n";
}
$data_block->{'values'}{'_tag_1'}[0] = 0;
$data_block->{'types'}{'_tag_1'}[0] = 'SQSTRING';
$data_block->{'values'}{'_tag_2'}[0] = 'Loop-value-that-is-longer-than-the-maximum-line-length-and-is-thus-handled-differently';
$data_block->{'types'}{'_tag_2'}[0] = 'SQSTRING';
$data_block->{'values'}{'_tag_3'}[0] = 0;
$data_block->{'types'}{'_tag_3'}[0] = 'SQSTRING';

print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    $test_tags,
                    0,
                    $options,
                );

print "# Value sequence: 0-long-0 \n";
print "loop_\n";
for my $tag (@{$test_tags}) {
    print "$tag\n";
}
$data_block->{'values'}{'_tag_1'}[0] = 0;
$data_block->{'types'}{'_tag_1'}[0] = 'SQSTRING';
$data_block->{'values'}{'_tag_2'}[0] = "\nMultiline\nvalue";
$data_block->{'types'}{'_tag_2'}[0] = 'TEXTFIELD';
$data_block->{'values'}{'_tag_3'}[0] = 0;
$data_block->{'types'}{'_tag_3'}[0] = 'SQSTRING';

print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    $test_tags,
                    0,
                    $options,
                );

END_SCRIPT
