#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Tags/Manage.pm
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
#* Unit test for the COD::CIF::Tags::Manage::has_inapplicable_value() subroutine.
#* Tests the way the subroutine behaves when the 'types' hash entry for
#* the data item is undefined.
#**
use strict;
use warnings;

# use COD::CIF::Tags::Manage;

my $data_block =
{
  'tags'   => [ '_value' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_value' => [ '.' ] },
  'precisions' => {},
  'types' => {},
};

my $data_name   = '_value';

my $inapplicable = COD::CIF::Tags::Manage::has_inapplicable_value(
                    $data_block,
                    $data_name,
                    0 );

print "Value is " .($inapplicable ? 'inapplicable' : 'applicable') . ".\n";

END_SCRIPT
