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
#* Tests the way the subroutine treats situations when the sum length
#* of the packet values is slightly lesser, slightly greater or equal
#* to the maximum line length.
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
  },
  'values' => {
    '_tag_1' => [
      'Placeholder.'
    ],
    '_tag_2' => [
      'Placeholder.'
    ],
  }
};

my $string_77 = 'Value-that-is-77-characters-long-++++++++++++++++++++++++++++++++++++++++++++';
my $string_78 = 'Value-that-is-78-characters-long-+++++++++++++++++++++++++++++++++++++++++++++';
my $string_79 = 'Value-that-is-79-characters-long-++++++++++++++++++++++++++++++++++++++++++++++';
my $string_80 = 'Value-that-is-80-characters-long-+++++++++++++++++++++++++++++++++++++++++++++++';

print "# Value length sequence: 80-1\n";
print "loop_\n";
for my $tag (@{$test_tags}) {
    print "$tag\n";
}
$data_block->{'values'}{'_tag_1'}[0] = $string_80;
$data_block->{'types'}{'_tag_1'}[0] = 'UQSTRING';
$data_block->{'values'}{'_tag_2'}[0] = 'a';
$data_block->{'types'}{'_tag_2'}[0] = 'UQSTRING';

print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    $test_tags,
                    0,
                    $options,
                );

print "# Value length sequence: 1-80\n";
print "loop_\n";
for my $tag (@{$test_tags}) {
    print "$tag\n";
}
$data_block->{'values'}{'_tag_1'}[0] = 'a';
$data_block->{'types'}{'_tag_1'}[0] = 'UQSTRING';
$data_block->{'values'}{'_tag_2'}[0] = $string_80;
$data_block->{'types'}{'_tag_2'}[0] = 'UQSTRING';

print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    $test_tags,
                    0,
                    $options,
                );

print "# Value length sequence: 79-1\n";
print "loop_\n";
for my $tag (@{$test_tags}) {
    print "$tag\n";
}
$data_block->{'values'}{'_tag_1'}[0] = $string_79;
$data_block->{'types'}{'_tag_1'}[0] = 'UQSTRING';
$data_block->{'values'}{'_tag_2'}[0] = 'a';
$data_block->{'types'}{'_tag_2'}[0] = 'UQSTRING';

print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    $test_tags,
                    0,
                    $options,
                );

print "# Value length sequence: 1-79\n";
print "loop_\n";
for my $tag (@{$test_tags}) {
    print "$tag\n";
}
$data_block->{'values'}{'_tag_1'}[0] = 'a';
$data_block->{'types'}{'_tag_1'}[0] = 'UQSTRING';
$data_block->{'values'}{'_tag_2'}[0] = $string_79;
$data_block->{'types'}{'_tag_2'}[0] = 'UQSTRING';

print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    $test_tags,
                    0,
                    $options,
                );

print "# Value length sequence: 78-1\n";
print "loop_\n";
for my $tag (@{$test_tags}) {
    print "$tag\n";
}
$data_block->{'values'}{'_tag_1'}[0] = $string_78;
$data_block->{'types'}{'_tag_1'}[0] = 'UQSTRING';
$data_block->{'values'}{'_tag_2'}[0] = 'a';
$data_block->{'types'}{'_tag_2'}[0] = 'UQSTRING';

print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    $test_tags,
                    0,
                    $options,
                );

print "# Value length sequence: 1-78\n";
print "loop_\n";
for my $tag (@{$test_tags}) {
    print "$tag\n";
}
$data_block->{'values'}{'_tag_1'}[0] = 'a';
$data_block->{'types'}{'_tag_1'}[0] = 'UQSTRING';
$data_block->{'values'}{'_tag_2'}[0] = $string_78;
$data_block->{'types'}{'_tag_2'}[0] = 'UQSTRING';

print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    $test_tags,
                    0,
                    $options,
                );

print "# Value length sequence: 77-1\n";
print "loop_\n";
for my $tag (@{$test_tags}) {
    print "$tag\n";
}
$data_block->{'values'}{'_tag_1'}[0] = $string_77;
$data_block->{'types'}{'_tag_1'}[0] = 'UQSTRING';
$data_block->{'values'}{'_tag_2'}[0] = 'a';
$data_block->{'types'}{'_tag_2'}[0] = 'UQSTRING';

print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    $test_tags,
                    0,
                    $options,
                );

print "# Value length sequence: 1-77\n";
print "loop_\n";
for my $tag (@{$test_tags}) {
    print "$tag\n";
}
$data_block->{'values'}{'_tag_1'}[0] = 'a';
$data_block->{'types'}{'_tag_1'}[0] = 'UQSTRING';
$data_block->{'values'}{'_tag_2'}[0] = $string_77;
$data_block->{'types'}{'_tag_2'}[0] = 'UQSTRING';

print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    $test_tags,
                    0,
                    $options,
                );

END_SCRIPT
