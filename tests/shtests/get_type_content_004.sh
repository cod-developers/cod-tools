#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/DDL/DDLm.pm'
#END DEPEND--------------------------------------------------------------------

TEST_SCRIPT=$(cat <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::DDL::DDLm::get_type_contents() subroutine.
#* Tests the way the 'resolve_byreference_type' option is recognised and
#* handled. In this particular case the reference chain includes cycles
#* ('ByReference-1' -> 'ByReference-2' -> 'ByReference-3' -> 'ByReference-2').
#**

use strict;
use warnings;

use COD::CIF::DDL::DDLm qw( get_type_contents );

my $data_name = '_test_type.by_reference_1';
my $data_frame = {
    'values' => {
        '_type.contents' => [ 'Real' ]
    }
};
my $dictionary = {
    'Item' => {
        $data_name => {
            'values' => {
                '_type.contents' => [ 'ByReference' ],
                '_type.contents_referenced_id' =>
                    [ '_test_type.by_reference_2' ]
            }
        },
        '_test_type.by_reference_2' => {
            'values' => {
                '_type.contents' => [ 'ByReference' ],
                '_type.contents_referenced_id' =>
                    [ '_test_type.by_reference_3' ]
            }
        },
        '_test_type.by_reference_3' => {
            'values' => {
                '_type.contents' => [ 'ByReference' ],
                '_type.contents_referenced_id' =>
                    [ '_test_type.by_reference_2' ]
            }
        },
    }
};

# Resolution of the 'ByReference' type disabled
my $options = {
    'resolve_byreference_type' => 0,
    'resolve_implied_type'     => 0,
};
print 'Resolution of the \'ByReference\' type disabled:';
print "\n    '";
print get_type_contents(
            $data_name,
            $data_frame,
            $dictionary,
            $options,
      );
print "'\n\n";

# Resolution of the 'ByReference' type enabled
# Reference chain incorrectly contains a circular reference
$options = {
    'resolve_byreference_type' => 1,
    'resolve_implied_type'     => 0,
};
print 'Resolution of the \'ByReference\' type enabled, ' .
      'reference chain incorrectly contains a circular reference:';
print "\n    '";
print get_type_contents(
            $data_name,
            $data_frame,
            $dictionary,
            $options,
      );
print "'\n\n";

END_SCRIPT
)

perl -e "${TEST_SCRIPT}" | perl -0777 -lne 'print $_;'
