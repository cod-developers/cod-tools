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
#* Tests the way a specific combination of 'Implied' and 'ByReference' types
#* is handled ('ByReference' -> 'Implied' -> 'Real').
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
                    [ '_test_type.by_reference_implied' ]
            }
        },
        '_test_type.by_reference_implied' => {
            'values' => {
                '_type.contents' => [ 'Implied' ],
            }
        },
    }
};

# Resolution of the 'ByReference' type disabled
# Resolution of the 'Implied' type disabled
my $options = {
    'resolve_byreference_type' => 0,
    'resolve_implied_type'     => 0,
};
print 'Resolution of the \'ByReference\' type disabled, ' .
      'resolution of the \'Implied\' type disabled:';
print "\n    '";
print get_type_contents(
            $data_name,
            $data_frame,
            $dictionary,
            $options,
      );
print "'\n\n";

# Resolution of the 'ByReference' type enabled
# Resolution of the 'Implied' type enabled
$options = {
    'resolve_byreference_type' => 1,
    'resolve_implied_type'     => 1,
};
print 'Resolution of the \'ByReference\' type enabled, ' .
      'resolution of the \'Implied\' type enabled:';
print "\n    '";
print get_type_contents(
            $data_name,
            $data_frame,
            $dictionary,
            $options,
      );
print "'\n\n";

# Resolution of the 'ByReference' type enabled
# Resolution of the 'Implied' type disabled
$options = {
    'resolve_byreference_type' => 1,
    'resolve_implied_type'     => 0,
};
print 'Resolution of the \'ByReference\' type enabled, ' .
      'resolution of the \'Implied\' type enabled:';
print "\n    '";
print get_type_contents(
            $data_name,
            $data_frame,
            $dictionary,
            $options,
      );
print "'\n\n";

# Resolution of the 'ByReference' type disabled
# Resolution of the 'Implied' type enabled
$options = {
    'resolve_byreference_type' => 0,
    'resolve_implied_type'     => 1,
};
print 'Resolution of the \'ByReference\' type disabled, ' .
      'resolution of the \'Implied\' type enabled:';
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

perl -e "${TEST_SCRIPT}"
