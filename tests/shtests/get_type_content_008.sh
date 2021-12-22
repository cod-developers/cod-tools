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
#* Tests the way a specific sequence of 'Implied' and 'ByReference'
#* types is handled ('ByReference' -> 'Implied' -> 'ByReference').
#* In this particular case the final 'ByReference' cannot be resolved
#* due to various reasons.
#**

use strict;
use warnings;

use COD::CIF::DDL::DDLm qw( get_type_contents );

my $data_name = '_test_type.by_reference_chain_A_1';
my $data_frame = {
    'values' => {
        '_definition.id' => [ '_test_type.by_reference_chain_b_final' ],
        '_type.contents' => [ 'ByReference' ]
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
        '_test_type.by_reference_chain_b_1' => {
            'values' => {
                '_type.contents' => [ 'ByReference' ],
                '_type.contents_referenced_id' =>
                    [ '_test_type.by_reference_chain_b_final' ]
            }
        },
        '_test_type.by_reference_chain_b_final' => {
            'values' => {
                '_type.contents' => [ 'Integer' ]
            }
        },
    }
};

# Data frame defines an item that does not belong to the dictionary
$data_frame->{'values'}{'_definition.id'} = [ '_unrecognised_item.type' ];
my $options = {
    'resolve_byreference_type' => 1,
    'resolve_implied_type'     => 1,
};
print 'Data frame defines an item that does not belong to the dictionary:';
print "\n    '";
print get_type_contents(
            $data_name,
            $data_frame,
            $dictionary,
            $options,
      );
print "'\n\n";

# Data frame does not contain a data name attribute
delete $data_frame->{'values'}{'_definition.id'};
$options = {
    'resolve_byreference_type' => 1,
    'resolve_implied_type'     => 1,
};
print 'Save frame defines an item that does not belong to the dictionary:';
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
