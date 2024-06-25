#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Tags/Print.pm
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
#* Unit test for the COD::CIF::Tags::Print::print_loop() subroutine.
#* Tests the way the subroutine behaves when the loop consists of
#* several data items some of which have values that are longer
#* than the maximum line length.
#**

use strict;
use warnings;

# use COD::CIF::Tags::Print;

my $long_value = 'Loop-value-that-is-longer-than-the-maximum-line-length-and-is-thus-handled-differently.';
my $fold_long_fields = 0;
my $folding_width = 80;
my $cif_version = 1.1;

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
      '_tag_1',
      '_tag_2',
      '_tag_3',
      '_tag_4',
      '_tag_5',
    ]
  ],
  'precisions' => {},
  'save_blocks' => [],
  'tags' => [
    '_tag_1',
    '_tag_2',
    '_tag_3',
    '_tag_4',
    '_tag_5',
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
    ]
  },
  'values' => {
    '_tag_1' => [
      "$long_value"
    ],
    '_tag_2' => [
      'Value-2-1'
    ],
    '_tag_3' => [
      'Value-3-1'
    ],
    '_tag_4' => [
      'Value-4-1'
    ],
    '_tag_5' => [
      'Value-5-1'
    ],
  }
};

##
# Loop that contains a single loop packet with an extra
# long value at the first position.
##
print "# Single loop packet with an extra long value at the first position\n";
COD::CIF::Tags::Print::print_loop(
    $data_block,
    0,
    {
       'fold_long_fields' => $fold_long_fields,
       'folding_width'    => $folding_width,
       'cif_version'      => $cif_version,
    }
);
print "\n";

##
# Loop that contains a single loop packet with an extra
# long value at the middle position.
##
print "# Single loop packet with an extra long value at the middle position\n";
$data_block->{'values'}{'_tag_1'} = [ 'value-1-1' ];
$data_block->{'values'}{'_tag_3'} = [ "$long_value" ];

COD::CIF::Tags::Print::print_loop(
    $data_block,
    0,
    {
       'fold_long_fields' => $fold_long_fields,
       'folding_width'    => $folding_width,
       'cif_version'      => $cif_version,
    }
);
print "\n";

##
# Loop that contains a single loop packet with an extra
# long value at the last position.
##
print "# Single loop packet with an extra long value at the last position\n";
$data_block->{'values'}{'_tag_3'} = [ 'value-3-1' ];
$data_block->{'values'}{'_tag_5'} = [ "$long_value" ];

COD::CIF::Tags::Print::print_loop(
    $data_block,
    0,
    {
       'fold_long_fields' => $fold_long_fields,
       'folding_width'    => $folding_width,
       'cif_version'      => $cif_version,
    }
);
print "\n";

##
# Loop that contains the extra long values at the loop
# left-to-right diagonal positions.
##
print "# Extra long values at the left-to-right diagonal positions\n";
$data_block->{'values'}{'_tag_1'} = [ map { "Value-1-$_" } 1..5 ];
$data_block->{'values'}{'_tag_2'} = [ map { "Value-2-$_" } 1..5 ];
$data_block->{'values'}{'_tag_3'} = [ map { "Value-3-$_" } 1..5 ];
$data_block->{'values'}{'_tag_4'} = [ map { "Value-4-$_" } 1..5 ];
$data_block->{'values'}{'_tag_5'} = [ map { "Value-5-$_" } 1..5 ];

for my $i (1..5) {
$data_block->{'types'}{"_tag_$i"} =
    [
      'UQSTRING',
      'UQSTRING',
      'UQSTRING',
      'UQSTRING',
      'UQSTRING',
    ];
}
$data_block->{'values'}{'_tag_1'}[0] = $long_value;
$data_block->{'values'}{'_tag_2'}[1] = $long_value;
$data_block->{'values'}{'_tag_3'}[2] = $long_value;
$data_block->{'values'}{'_tag_4'}[3] = $long_value;
$data_block->{'values'}{'_tag_5'}[4] = $long_value;

COD::CIF::Tags::Print::print_loop(
    $data_block,
    0,
    {
       'fold_long_fields' => $fold_long_fields,
       'folding_width'    => $folding_width,
       'cif_version'      => $cif_version,
    }
);
print "\n";

##
# Loop that contains the extra long values at the loop
# right-to-left diagonal positions.
##
print "# Extra long values at the right-to-left diagonal positions\n";
$data_block->{'values'}{'_tag_1'} = [ map { "Value-1-$_" } 1..5 ];
$data_block->{'values'}{'_tag_2'} = [ map { "Value-2-$_" } 1..5 ];
$data_block->{'values'}{'_tag_3'} = [ map { "Value-3-$_" } 1..5 ];
$data_block->{'values'}{'_tag_4'} = [ map { "Value-4-$_" } 1..5 ];
$data_block->{'values'}{'_tag_5'} = [ map { "Value-5-$_" } 1..5 ];

for my $i (1..5) {
$data_block->{'types'}{"_tag_$i"} =
    [
      'UQSTRING',
      'UQSTRING',
      'UQSTRING',
      'UQSTRING',
      'UQSTRING',
    ];
}
$data_block->{'values'}{'_tag_1'}[4] = $long_value;
$data_block->{'values'}{'_tag_2'}[3] = $long_value;
$data_block->{'values'}{'_tag_3'}[2] = $long_value;
$data_block->{'values'}{'_tag_4'}[1] = $long_value;
$data_block->{'values'}{'_tag_5'}[0] = $long_value;

COD::CIF::Tags::Print::print_loop(
    $data_block,
    0,
    {
       'fold_long_fields' => $fold_long_fields,
       'folding_width'    => $folding_width,
       'cif_version'      => $cif_version,
    }
);
print "\n";

##
# Loop that contains the extra long values at the middle row.
##
print "# Extra long values at the middle row\n";
$data_block->{'values'}{'_tag_1'} = [ map { "Value-1-$_" } 1..5 ];
$data_block->{'values'}{'_tag_2'} = [ map { "Value-2-$_" } 1..5 ];
$data_block->{'values'}{'_tag_3'} = [ map { "Value-3-$_" } 1..5 ];
$data_block->{'values'}{'_tag_4'} = [ map { "Value-4-$_" } 1..5 ];
$data_block->{'values'}{'_tag_5'} = [ map { "Value-5-$_" } 1..5 ];

for my $i (1..5) {
$data_block->{'types'}{"_tag_$i"} =
    [
      'UQSTRING',
      'UQSTRING',
      'UQSTRING',
      'UQSTRING',
      'UQSTRING',
    ];
}
$data_block->{'values'}{'_tag_3'}[0] = $long_value;
$data_block->{'values'}{'_tag_3'}[1] = $long_value;
$data_block->{'values'}{'_tag_3'}[2] = $long_value;
$data_block->{'values'}{'_tag_3'}[3] = $long_value;
$data_block->{'values'}{'_tag_3'}[4] = $long_value;

COD::CIF::Tags::Print::print_loop(
    $data_block,
    0,
    {
       'fold_long_fields' => $fold_long_fields,
       'folding_width'    => $folding_width,
       'cif_version'      => $cif_version,
    }
);
print "\n";

##
# Loop that contains the extra long values at the middle column.
##
print "# Extra long values at the middle column\n";
$data_block->{'values'}{'_tag_1'} = [ map { "Value-1-$_" } 1..5 ];
$data_block->{'values'}{'_tag_2'} = [ map { "Value-2-$_" } 1..5 ];
$data_block->{'values'}{'_tag_3'} = [ map { "Value-3-$_" } 1..5 ];
$data_block->{'values'}{'_tag_4'} = [ map { "Value-4-$_" } 1..5 ];
$data_block->{'values'}{'_tag_5'} = [ map { "Value-5-$_" } 1..5 ];

for my $i (1..5) {
$data_block->{'types'}{"_tag_$i"} =
    [
      'UQSTRING',
      'UQSTRING',
      'UQSTRING',
      'UQSTRING',
      'UQSTRING',
    ];
}
$data_block->{'values'}{'_tag_1'}[2] = $long_value;
$data_block->{'values'}{'_tag_2'}[2] = $long_value;
$data_block->{'values'}{'_tag_3'}[2] = $long_value;
$data_block->{'values'}{'_tag_4'}[2] = $long_value;
$data_block->{'values'}{'_tag_5'}[2] = $long_value;

COD::CIF::Tags::Print::print_loop(
    $data_block,
    0,
    {
       'fold_long_fields' => $fold_long_fields,
       'folding_width'    => $folding_width,
       'cif_version'      => $cif_version,
    }
);
print "\n";

##
# Loop that contains multiline and extra long values.
##
print "# Mixture of multiline and extra long values\n";
$data_block->{'values'}{'_tag_1'} = [ map { "Value-1-$_" } 1..5 ];
$data_block->{'values'}{'_tag_2'} = [ map { "Value-2-$_" } 1..5 ];
$data_block->{'values'}{'_tag_3'} = [ map { "Value-3-$_" } 1..5 ];
$data_block->{'values'}{'_tag_4'} = [ map { "Value-4-$_" } 1..5 ];
$data_block->{'values'}{'_tag_5'} = [ map { "Value-5-$_" } 1..5 ];

for my $i (1..5) {
$data_block->{'types'}{"_tag_$i"} =
    [
      'UQSTRING',
      'UQSTRING',
      'UQSTRING',
      'UQSTRING',
      'UQSTRING',
    ];
}

$data_block->{'values'}{'_tag_1'}[0] = "\nValue-1-1";
$data_block->{'values'}{'_tag_3'}[0] = $long_value;
$data_block->{'values'}{'_tag_2'}[1] = "\nValue-2-2";
$data_block->{'values'}{'_tag_3'}[1] = $long_value;
$data_block->{'values'}{'_tag_3'}[2] = $long_value;
$data_block->{'values'}{'_tag_3'}[3] = $long_value;
$data_block->{'values'}{'_tag_4'}[3] = "\nValue-4-4";
$data_block->{'values'}{'_tag_3'}[4] = $long_value;
$data_block->{'values'}{'_tag_5'}[4] = "\nValue-5-5";

COD::CIF::Tags::Print::print_loop(
    $data_block,
    0,
    {
       'fold_long_fields' => $fold_long_fields,
       'folding_width'    => $folding_width,
       'cif_version'      => $cif_version,
    }
);

END_SCRIPT
