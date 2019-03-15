#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Handles CIF dictionary files written in Dictionary Definition Language (DDL1).
#**

package COD::CIF::DDL::DDL1;

use strict;
use warnings;
use Scalar::Util qw( looks_like_number );
use COD::CIF::Tags::Print qw( pack_precision );
use COD::Precision qw( unpack_cif_number );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    canonicalise_value
    get_data_type
    get_enumeration_defaults
);

##
# Returns the default values that are implied in DDL1 data item definitions
# when explicit values are not provided.
#
# @return $enumeration_defaults
#       Reference to a hash of data names and associated default values.
##
sub get_enumeration_defaults
{
    # DDL1 core dictionary version 1.4.1
    my $enumeration_defaults = {
        '_list'            => 'no',
        '_list_mandatory'  => 'no',
        '_type_conditions' => 'no',
        '_type_construct'  => '.*',
        '_list_level'      => '1',
    };

    return $enumeration_defaults;
}

##
# Determines the content type for the given data item as defined in a DDL1
# dictionary file.
#
# @param $data_item
#       Data item definition block as returned by the COD::CIF::Parser.
# @return
#       String containing the data type or undef value if the data type
#       is not provided.
##
sub get_data_type
{
    my ( $dict_item ) = @_;

    return if !exists $dict_item->{'values'}{'_type'};

    return $dict_item->{'values'}{'_type'}[0];
}

##
# Return a canonical representation of the value based on its DDL1 data type.
#
# @param $value
#       Data value that should be canonicalised.
# @param $data_type
#       Data type of the value as defined in a DDL1 dictionary file.
##
sub canonicalise_value
{
    my ( $value, $data_type ) = @_;

    return $value if !defined $data_type;
    $data_type = lc $data_type;

    if ( $data_type eq 'char' )  {
        return $value
    }

    if ( $data_type eq 'numb' )  {
        my ( $uvalue, $su ) = unpack_cif_number($value);
        if ( looks_like_number( $uvalue ) ) {
            return pack_precision( $uvalue + 0, $su );
        } else {
            return $value;
        }
    }

    return $value
}

1;
