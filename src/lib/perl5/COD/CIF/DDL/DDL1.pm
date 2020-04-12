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
    get_category_name
    get_data_type
    get_enumeration_defaults
    get_list_constraint_type
    get_list_mandatory_flag
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
        '_type_conditions' => 'none',
        '_type_construct'  => '.*',
        '_list_level'      => '1',
    };

    return $enumeration_defaults;
}

##
# Returns the requested data value from the given DDL1 definition block.
# In case the value if not provided, the default value provided by the DDL1
# dictionary is returned.
#
# @param $data_frame
#       Data block as returned by the COD::CIF::Parser.
# @param $data_name
#       Name of the data item to be retrieved.
# @return
#       The value of the requested item or undef if neither the value
#       nor the default value could be retrieved.
##
sub get_dic_item_value
{
    my ( $data_frame, $data_name ) = @_;

    my $data_item_defaults = get_enumeration_defaults();
    my $value = $data_item_defaults->{$data_name};
    if ( exists $data_frame->{'values'}{$data_name} ) {
        $value = $data_frame->{'values'}{$data_name}[0];
    };

    return $value;
}

##
# Determines the list constraint type of the given data item.
#
# @param $dic_item
#       Data item definition block as returned by the COD::CIF::Parser.
# @return
#       String containing the list constraint type or undef value if
#       the list constraint type could not be determined.
##
sub get_list_constraint_type
{
    my ( $dic_item ) = @_;

    return get_dic_item_value( $dic_item, '_list' );
}

##
# Determines the content type for the given data item as defined in a DDL1
# dictionary file.
#
# @param $dic_item
#       Data item definition block as returned by the COD::CIF::Parser.
# @return
#       String containing the data type or undef value if the data type
#       is not provided.
##
sub get_data_type
{
    my ( $dic_item ) = @_;

    return get_dic_item_value( $dic_item, '_type' );
}

##
# Determines the name of the parent category for the given data item
# as defined in a DDL1 dictionary file.
#
# @param $dic_item
#       Data item definition frame as returned by the COD::CIF::Parser.
# @return $data_name
#       String containing the category name or undef value if
#       the data block does not contain the name of the parent category.
##
sub get_category_name
{
    my ( $dic_item ) = @_;

    return get_dic_item_value( $dic_item, '_category' );
}

##
# Determines the value of the list mandatory flag as defined in a
# DDL1 dictionary file.
#
# @param $dic_item
#       Data item definition block as returned by the COD::CIF::Parser.
# @return
#       String containing the data type or undef value if the mandatory
#       list flag could not be determined.
##
sub get_list_mandatory_flag
{
    my ( $dic_item ) = @_;

    return get_dic_item_value( $dic_item, '_list_mandatory' );
}

##
# Returns a canonical representation of the value based on its DDL1 data type.
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
