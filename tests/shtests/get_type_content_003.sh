#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/DDL/DDLm.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::DDL::DDLm::get_type_contents() subroutine.
#* Tests the way the 'resolve_byreference_type' option is recognised and
#* handled. In this particular case the reference chain includes 3 data
#* items ('ByReference' -> 'ByReference' -> 'ByReference' -> 'Integer').
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
                    [ '_test_data_item_type.final' ]
            }
        },
        '_test_data_item_type.final' => {
            'values' => {
                '_type.contents' => [ 'Integer' ]
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
# Referenced save frame contains an explicit content type
$options = {
    'resolve_byreference_type' => 1,
    'resolve_implied_type'     => 0,
};
print 'Resolution of the \'ByReference\' type enabled, ' .
      'final referenced save frame contains an explicit content type:';
print "\n    '";
print get_type_contents(
            $data_name,
            $data_frame,
            $dictionary,
            $options,
      );
print "'\n\n";

# Resolution of the 'ByReference' type enabled
# Referenced save frame does not contain an explicit content type
delete $dictionary->{'Item'}{'_test_data_item_type.final'}
                        {'values'}{'_type.contents'};
$options = {
    'resolve_byreference_type' => 1,
    'resolve_implied_type'     => 0,
};
print 'Resolution of the \'ByReference\' type enabled, ' .
      'final referenced save frame does not contain an explicit content type:';
print "\n    '";
print get_type_contents(
            $data_name,
            $data_frame,
            $dictionary,
            $options,
      );
print "'\n\n";

END_SCRIPT
