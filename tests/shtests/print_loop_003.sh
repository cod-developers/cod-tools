#! /bin/sh

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
#* Unit test for the COD::CIF::Tags::Print::print_loop() subroutine.
#* Tests the way the subroutine behaves when CIF 1.1 loop values start
#* with a semicolon (';') and thus must be delimited. In this particular
#* case the loop consists of a single data item.
#**

use strict;
use warnings;

use COD::CIF::Tags::Print;

my $data_name = '_test_data_name';
my $value = ';value-that-starts-with-a-semicolon-and-has-no-spaces-(i.e.-an-InChi-string);';
my $fold_long_fields = 0;
my $folding_width = 80;
my $cif_version = 1;

my @feature_sets;
for my $i (0..15) {
    my $binary = sprintf "%04b", $i;
    push @feature_sets, [ split '', $binary ];
}

my @values;
for my $feature (@feature_sets) {
    my $value = ';start';
    $value .= "-'"   if $feature->[3];
    $value .= '-"'   if $feature->[2];
    $value .= "-'''" if $feature->[1];
    $value .= '-"""' if $feature->[0];
    $value .= '-end';
    push @values, $value;
}

my $data_block = {
  'cifversion' => {
    'major' => 1,
    'minor' => 1
  },
  'name' => 'test',
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
    '_tag' => [ 'UQSTRING' x @values ]
  },
  'values' => {
    '_tag' => \@values
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
