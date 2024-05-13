#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Data/CIF2COD.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::CIF2COD::get_coeditor_code() subroutine.
#* Tests the way the subroutine handles non-IUCr journals.
#*
#* No ad-hoc approaches are currently used with non-IUCr journals.
#**

use strict;
use warnings;

use COD::CIF::Data::CIF2COD;

my $data_block = {
    '_cod_data_source_file' => [
      'ac1543.cif'
    ],
    '_journal_coeditor_code' => [
      'AC1541'
    ],
    '_journal_name_full' => [
      'Different journal'
    ]
};
my $options = { 'journal' => 'Different journal' } ;

# Proper code in the _journal_coeditor_code data item.
my $value = COD::CIF::Data::CIF2COD::get_coeditor_code($data_block, $options);
print 'case_001: ' . ( defined $value ? "'$value'" : 'undefined' ) . "\n";

# Code with the "sup..." postfix in the _journal_coeditor_code data item.
$data_block->{'_journal_coeditor_code'}[0] = 'AC1542SUP1';
$value = COD::CIF::Data::CIF2COD::get_coeditor_code($data_block, $options);
print 'case_002: ' . ( defined $value ? "'$value'" : 'undefined' ) . "\n";

# Delete the explicit coeditor code.
delete $data_block->{'_journal_coeditor_code'};

# No code in the _journal_coeditor_code data item, file name matches the IUCr
# coeditor code syntax.
$value = COD::CIF::Data::CIF2COD::get_coeditor_code($data_block, $options);
print 'case_003: ' . ( defined $value ? "'$value'" : 'undefined' ) . "\n";

# No code in the _journal_coeditor_code data item, original filename matches
# the IUCr code syntax with the "sup" postfix.
$data_block->{'_cod_data_source_file'}[0] = 'AC1544SUP1';
$value = COD::CIF::Data::CIF2COD::get_coeditor_code($data_block, $options);
print 'case_004: ' . ( defined $value ? "'$value'" : 'undefined' ) . "\n";

# No code in the _journal_coeditor_code data item, original filename does not
# match the IUCr coeditor code syntax.
$data_block->{'_cod_data_source_file'}[0] = '123456';
$value = COD::CIF::Data::CIF2COD::get_coeditor_code($data_block, $options);
print 'case_005: ' . ( defined $value ? "'$value'" : 'undefined' ) . "\n";

# Delete the recorded file name.
delete $data_block->{'_cod_data_source_file'};

# No code in the _journal_coeditor_code data item, no original filename.
$value = COD::CIF::Data::CIF2COD::get_coeditor_code($data_block, $options);
print 'Case_006: ' . ( defined $value ? "'$value'" : 'undefined' ) . "\n";

END_SCRIPT
