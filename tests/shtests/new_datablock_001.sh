#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MANAGE_MODULE=src/lib/perl5/COD/CIF/Tags/Manage.pm
INPUT_ERROR_MODULE=src/lib/perl5/COD/ErrorHandler.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MANAGE_MODULE=$(\
    echo ${INPUT_MANAGE_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

IMPORT_ERROR_MODULE=$(\
    echo ${INPUT_ERROR_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MANAGE_MODULE} qw( new_datablock )" \
     -M"${IMPORT_ERROR_MODULE} qw( process_warnings )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Tags::Manage::new_datablock() subroutine.
#* Tests the way the subroutine behaves when given empty string or string
#* with unallowed symbols.
#**

use strict;
use warnings;

use COD::CIF::Tags::Manage qw( new_datablock );
use COD::ErrorHandler qw( process_warnings );

local $SIG{__WARN__} = sub {
    process_warnings( {
        'message'       => @_,
        'program'       => $0,
    }, {
        'ERROR'   => 0,
        'WARNING' => 0,
        'NOTE'    => 0,
    } )
};

my $data1 = new_datablock( ' ' );
my $data2 = new_datablock( "multi\nline\nname" );
my $data3 = new_datablock( '' );

END_SCRIPT
