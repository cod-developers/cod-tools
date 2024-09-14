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
#* Tests the way the subroutine behaves when the loop consists of a
#* single data item that has several values that are longer than the
#* maximum line length.
#**

use strict;
use warnings;

# use COD::CIF::Tags::Print;

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
    '_tag' => 0
  },
  'loops' => [
    [
      '_tag'
    ]
  ],
  'precisions' => {},
  'save_blocks' => [],
  'tags' => [
    '_tag'
  ],
  'types' => {
    '_tag' => [
      'UQSTRING'
    ]
  },
  'values' => {
    '_tag' => [
      'Placeholder'
    ]
  }
};
my $long_value = 'Loop-value-that-is-longer-than-the-maximum-line-length-and-is-thus-handled-differently.';

##
# Loop that contains only the extra long value.
##
print "# Loop that contains only the extra long value.\n";
$data_block->{'values'}{'_tag'} =
[
  $long_value,
];
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
# Loop that contains the extra long value at the first position.
##
print "# Loop that contains the extra long value at the first position\n";
$data_block->{'values'}{'_tag'} =
[
  'Loop-value-that-is-longer-than-the-maximum-line-length-and-is-thus-handled-differently.',
  'Value-1',
  'Value-2',
];
$data_block->{'types'}{'_tag'} =
[
  'UQSTRING',
  'UQSTRING',
  'UQSTRING',
];

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
# Loop that contains the extra long value at the last position.
##
print "# Loop that contains the extra long value at the last position\n";
$data_block->{'values'}{'_tag'} =
[
  'Value-1',
  'Value-2',
  $long_value,
];
$data_block->{'types'}{'_tag'} =
[
  'UQSTRING',
  'UQSTRING',
  'UQSTRING',
];

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
# Loop that contains the extra long value in the middle.
##
print "# Loop that contains the extra long value in the middle\n";
$data_block->{'values'}{'_tag'} =
[
  'Value-1',
  'Value-2',
  $long_value,
  'Value-4',
  'Value-5',
];
$data_block->{'types'}{'_tag'} =
[
  'UQSTRING',
  'UQSTRING',
  'UQSTRING',
  'UQSTRING',
  'UQSTRING',
];

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
# Loop that contains several consecutive extra long values.
##
print "# Loop that contains several consecutive extra long values\n";
$data_block->{'values'}{'_tag'} =
[
  'Value-1',
  $long_value,
  $long_value,
  $long_value,
  'Value-5',
];

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
# Loop that contains several multiline and extra long values.
##
print "# Loop that contains several multiline and extra long values\n";
$data_block->{'values'}{'_tag'} =
[
  "\nValue-1",
  $long_value,
  "\nValue-3",
  $long_value,
  "\nValue-5",
];

$data_block->{'types'}{'_tag'} =
[
  'TEXTFIELD',
  'UQSTRING',
  'TEXTFIELD',
  'UQSTRING',
  'TEXTFIELD',
];

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
