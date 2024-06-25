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
#* Tests the way the subroutine behaves when CIF 2.0 loop values start
#* with a semicolon (';') and thus must be delimited. In this particular
#* case the loop consists of a three data items with identical values.
#**

use strict;
use warnings;

# use COD::CIF::Tags::Print;

my $fold_long_fields = 0;
my $folding_width = 80;
my $cif_version = 2;

my @feature_sets;
for my $i (0..15) {
    my $binary = sprintf "%04b", $i;
    push @feature_sets, [ split '', $binary ];
}

my @values;
for my $feature (@feature_sets) {
    my $value = ';start----------------';
    $value .= "-'"   if $feature->[3];
    $value .= '-"'   if $feature->[2];
    $value .= "-'''" if $feature->[1];
    $value .= '-"""' if $feature->[0];
    $value .= '-end';
    push @values, $value;
}

my @value_1 = map { $_ . '-1' }  @values;
my @value_2 = map { $_ . '-2' }  @values;
my @value_3 = map { $_ . '-3' }  @values;

my $data_block = {
  'cifversion' => {
    'major' => 1,
    'minor' => 1
  },
  'name' => 'test',
  'inloop' => {
    '_tag_1' => 0,
    '_tag_2' => 0,
    '_tag_3' => 0,
  },
  'loops' => [
    [
      '_tag_1',
      '_tag_2',
      '_tag_3',
    ]
  ],
  'precisions' => {},
  'save_blocks' => [],
  'tags' => [
    '_tag_1',
    '_tag_2',
    '_tag_3',
  ],
  'types' => {
    '_tag_1' => [ 'UQSTRING' x @values ],
    '_tag_2' => [ 'UQSTRING' x @values ],
    '_tag_3' => [ 'UQSTRING' x @values ],
  },
  'values' => {
    '_tag_1' => \@value_1,
    '_tag_2' => \@value_2,
    '_tag_3' => \@value_3,
  }
};

COD::CIF::Tags::Print::print_loop(
    $data_block,
    0,
    {
       'fold_long_fields' => $fold_long_fields,
       'folding_width'    => $folding_width,
       'cif_version'      => $cif_version,
    } );

END_SCRIPT
