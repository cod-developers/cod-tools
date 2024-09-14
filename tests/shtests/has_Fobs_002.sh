#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/CODFlags.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( has_Fobs )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::CODFlags::has_Fobs subroutine.
#* Tests the way the subroutine behaves when the input data block contains
#* various data items that should normally state that the entry has a related
#* diffraction file. However, in this particular case these items contain
#* special values such as ('.' and '?') that are treated the same way as if
#* the data item was not present at all.
#*
#* NOTE: currently the subroutine does not differentiate between special
#* CIF values (unquoted '?', '.') and regular question mark and dot symbols
#* (quoted '?', '.'). This behaviour should be investigated further.
#**

use strict;
use warnings;

# use COD::CIF::Data::CODFlags qw( has_Fobs );

my $data_block_1 =
{
  'name'   => 'has_Fobs_item_1',
  'tags'   => [ '_cod_related_diffrn_file.code' ],
  'loops'  => [],
  'inloop' => {},
  'values' => { '_cod_related_diffrn_file.code' => [ '?' ] },
  'precisions' => {},
  'types'  => { '_cod_related_diffrn_file.code' => [ 'UQSTRING' ] },
};

my $data_block_2 =
{
  'name'   => 'has_Fobs_item_2',
  'tags'   => [ '_cod_related_diffrn_file_code' ],
  'loops'  => [],
  'inloop' => {},
  'values' => { '_cod_related_diffrn_file_code' => [ '.' ] },
  'precisions' => {},
  'types'  => { '_cod_related_diffrn_file_code' => [ 'UQSTRING' ] },
};

my $data_block_3 =
{
  'name'   => 'has_Fobs_item_3',
  'tags'   => [ '_cod_database_fobs_code' ],
  'loops'  => [],
  'inloop' => {},
  'values' => { '_cod_database_fobs_code' => [ '.' ] },
  'precisions' => {},
  'types'  => { '_cod_database_fobs_code' => [ 'SQSTRING' ] },
};

my $data_block_4 =
{
  'name'   => 'has_Fobs_item_4',
  'tags'   => [ '_cod_database_fobs_code' ],
  'loops'  => [],
  'inloop' => {},
  'values' => { '_cod_database_fobs_code' => [ '?' ] },
  'precisions' => {},
  'types'  => { '_cod_database_fobs_code' => [ 'SQSTRING' ] },
};

my @blocks = (
    $data_block_1,
    $data_block_2,
    $data_block_3,
    $data_block_4,
);

for my $data_block ( @blocks ) {
    my $has_Fobs = has_Fobs( $data_block );
    if ( $has_Fobs ) {
        print 'Data block \'' . $data_block->{'name'} . '\' is marked as having a related diffraction file.' . "\n";
    } else {
        print 'Data block \'' . $data_block->{'name'} . '\' is not marked as having a related diffraction file.' . "\n";
    }
}

END_SCRIPT
