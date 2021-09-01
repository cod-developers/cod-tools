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
#* Tests the way the subroutine behaves when the packet consists of several
#* data items of various types.
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
  '_tag_4',
  '_tag_5',
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
    '_tag_4' => 0,
    '_tag_5' => 0,
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
    ],
    '_tag_4' => [
      'UQSTRING'
    ],
    '_tag_5' => [
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
    '_tag_3' => [
      'Placeholder.'
    ],
    '_tag_4' => [
      'Placeholder.'
    ],
    '_tag_5' => [
      'Placeholder.'
    ],
  }
};

print "# Multiple multiline field values\n";
print "loop_\n";
for my $tag (@{$test_tags}) {
    print "$tag\n";
}
my $counter = 0;
for my $tag (@{$test_tags}) {
    $counter++;
    $data_block->{'values'}{$tag}[0] = "\nMultiline\nvalue\n$counter";
    $data_block->{'types'}{$tag}[0] = 'TEXTFIELD';
}

print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    $test_tags,
                    0,
                    $options,
                );

print "# Multiple long values\n";
print "loop_\n";
for my $tag (@{$test_tags}) {
    print "$tag\n";
}
$counter = 0;
for my $tag (@{$test_tags}) {
    $counter++;
    $data_block->{'values'}{$tag}[0] = "Loop-value-that-is-longer-than-the-maximum-line-length-and-is-thus-handled-differently-$counter.";
    $data_block->{'types'}{$tag}[0] = 'UQSTRING';
}

print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    $test_tags,
                    0,
                    $options,
                );

print "# Multiple short values\n";
print "loop_\n";
for my $tag (@{$test_tags}) {
    print "$tag\n";
}
$counter = 0;
for my $tag (@{$test_tags}) {
    $counter++;
    $data_block->{'values'}{$tag}[0] = $counter;
    $data_block->{'types'}{$tag}[0] = 'UQSTRING';
}

print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    $test_tags,
                    0,
                    $options,
                );

print "# Multiple middle-length values\n";
print "loop_\n";
for my $tag (@{$test_tags}) {
    print "$tag\n";
}
$counter = 0;
for my $tag (@{$test_tags}) {
    $counter++;
    $data_block->{'values'}{$tag}[0] = "Fits-two-values-per-line-$counter.";
    $data_block->{'types'}{$tag}[0] = 'UQSTRING';
}

print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    $test_tags,
                    0,
                    $options,
                );

print "# Value sequence: short-long-multiline-long-short\n";
print "loop_\n";
for my $tag (@{$test_tags}) {
    print "$tag\n";
}
$data_block->{'values'}{'_tag_1'}[0] = 'a';
$data_block->{'types'}{'_tag_1'}[0] = 'UQSTRING';
$data_block->{'values'}{'_tag_2'}[0] = 'Loop-value-that-is-longer-than-the-maximum-line-length-and-is-thus-handled-differently';
$data_block->{'types'}{'_tag_2'}[0] = 'UQSTRING';
$data_block->{'values'}{'_tag_3'}[0] = "\nMultiline\nvalue\n3";
$data_block->{'types'}{'_tag_3'}[0] = 'TEXTFIELD';
$data_block->{'values'}{'_tag_4'}[0] = 'Loop-value-that-is-longer-than-the-maximum-line-length-and-is-thus-handled-differently';
$data_block->{'types'}{'_tag_4'}[0] = 'UQSTRING';
$data_block->{'values'}{'_tag_5'}[0] = 'e';
$data_block->{'types'}{'_tag_5'}[0] = 'UQSTRING';

print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    $test_tags,
                    0,
                    $options,
                );

print "# Value sequence: short-long-short-multiline-short\n";
print "loop_\n";
for my $tag (@{$test_tags}) {
    print "$tag\n";
}
$data_block->{'values'}{'_tag_1'}[0] = 'a';
$data_block->{'types'}{'_tag_1'}[0] = 'UQSTRING';
$data_block->{'values'}{'_tag_2'}[0] = 'Loop-value-that-is-longer-than-the-maximum-line-length-and-is-thus-handled-differently-2';
$data_block->{'types'}{'_tag_2'}[0] = 'UQSTRING';
$data_block->{'values'}{'_tag_3'}[0] = 'c';
$data_block->{'types'}{'_tag_3'}[0] = 'UQSTRING';
$data_block->{'values'}{'_tag_4'}[0] = "\nMultiline\nvalue\n3";
$data_block->{'types'}{'_tag_4'}[0] = 'TEXTFIELD';
$data_block->{'values'}{'_tag_5'}[0] = 'e';
$data_block->{'types'}{'_tag_5'}[0] = 'UQSTRING';

print COD::CIF::Tags::Print::sprint_loop_packet(
                    $data_block,
                    $test_tags,
                    0,
                    $options,
                );

END_SCRIPT
