#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/DDL/DDLm.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( get_type_contents )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::DDL::DDLm::get_type_contents() subroutine.
#* Tests the way the 'resolve_implied_type' option is recognised and handled.
#**

use strict;
use warnings;

# use COD::CIF::DDL::DDLm qw( get_type_contents );

my $data_name = '_test_data_item_type.implied';
my $data_frame = {
    'values' => {
        '_type.contents' => [ 'Integer' ]
    }
};
my $dictionary = {
    'Item' => {
        $data_name => {
            'values' => {
                '_type.contents' => [ 'Implied' ]
            }
        }
    }
};

# Resolution of the 'Implied' type disabled
my $options = {
    'resolve_byreference_type' => 0,
    'resolve_implied_type'     => 0,
};
print 'Resolution of the \'Implied\' type disabled:';
print "\n    '";
print get_type_contents(
            $data_name,
            $data_frame,
            $dictionary,
            $options,
      );
print "'\n\n";

# Resolution of the 'Implied' type enabled
# Save frame contains an explicit content type
$options = {
    'resolve_byreference_type' => 0,
    'resolve_implied_type'     => 1,
};
print 'Resolution of the \'Implied\' type enabled, ' .
      'save frame contains an explicit content type:';
print "\n    '";
print get_type_contents(
            $data_name,
            $data_frame,
            $dictionary,
            $options,
      );
print "'\n\n";

# Resolution of the 'Implied' type enabled
# Save frame does not contain an explicit content type
delete $data_frame->{'values'}{'_type.contents'};
$options = {
    'resolve_byreference_type' => 0,
    'resolve_implied_type'     => 1,
};
print 'Resolution of the \'Implied\' type enabled, ' .
      'save frame does not contain an explicit content type:';
print "\n    '";
print get_type_contents(
            $data_name,
            $data_frame,
            $dictionary,
            $options,
      );
print "'\n\n";

END_SCRIPT
