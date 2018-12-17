#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Tags/Manage.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
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
