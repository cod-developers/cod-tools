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
    classify_dic_blocks
    convert_pseudo_data_name_to_category_name
    get_category_name
    get_data_name
    get_data_names
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
# Determines the value of the list mandatory flag as defined
# in a DDL1 dictionary file.
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
#       String containing the category name or undef value if
##
# Determines the data names of the given data item as defined
# in a DDL1 dictionary file.
#
# @param $dic_item
#       Data item definition frame as returned by the COD::CIF::Parser.
# @return
#       Reference to an array of data names or undef value if
#       the data block does not contain any data names.
##
sub get_data_names
{
    my ( $dic_item ) = @_;

    return if !exists $dic_item->{'values'}{'_name'};

    return $dic_item->{'values'}{'_name'};
}

##
# Determines the data name of the given data item as defined
# in a DDL1 dictionary file. In case the data block defines
# several data names, the first data name is returned.
#
# @param $dic_item
#       Data item definition frame as returned by the COD::CIF::Parser.
# @return $data_name
#       String containing the data name or undef value if
#       the data block does not contain any data names.
##
sub get_data_name
{
    my ( $dic_item ) = @_;

    my $data_names = get_data_names( $dic_item );
    return if !defined $data_names;

    return $data_names->[0];
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
        if ( looks_like_number( $uvalue ) && $uvalue !~ m/^[+-]?(inf|nan)/i ) {
            return pack_precision( $uvalue + 0, $su );
        } else {
            return $value;
        }
    }

    return $value
}

##
# Classifies DDL1 dictionary blocks depending on their purpose.
# Normally, a DDL1 dictionary consists of multiple data blocks
# one of which contains the dictionary metadata while the rest
# contain either data category definitions or data item definitions.
#
# @param $dic
#       Reference to a DDL1 dictionary structure as returned by
#       the COD::CIF::Parser. 
# @return
#       Reference to a hash of the following form:
#       {
#         # Reference to an array of dictionary metadata data blocks.
#         # Should normally contain only a single data block
#           'dictionary' => [ ... ],
#         # Reference to an array of category definition data blocks
#           'category' => [ ... ],
#         # Reference to an array of data item definition data blocks
#           'item' => [ ... ],
#       }
##
sub classify_dic_blocks
{
    my ( $dic ) = @_;

    my @metadata;
    my @category;
    my @item;
    for my $data_block ( @{$dic} ) {
        if ( is_metadata_block( $data_block ) ) {
            push @metadata, $data_block;
        } elsif ( is_category_block( $data_block ) ) {
            push @category, $data_block;
        } else {
            push @item, $data_block;
        }
    }

    my %dic_blocks = (
        'dictionary' => \@metadata,
        'category'   => \@category,
        'item'       => \@item,
    );

    return \%dic_blocks;
}

##
# Evaluates if a given dictionary data block is intended to store
# the dictionary metadata (name, version, etc.).
#
# A DDL1 dictionary metadata block should normally be named 'on_this_dictionary'.
#
# @source [1]
#       https://www.iucr.org/resources/cif/dictionaries/cif_core/diffs2.0-1.0
# @source [2]
#       3.1.5.1. The dictionary identification block,
#       "International Tables for Crystallography Volume G:
#        Definition and exchange of crystallographic data",
#       2005, 77, doi: 10.1107/97809553602060000107
#
# @param $data_block
#       Reference to a DDL1 dictionary data block as returned
#       by the COD::CIF::Parser.
# @return
#        1 if the data block is a metadata block,
#        0 otherwise.
##
sub is_metadata_block
{
    my ( $data_block ) = @_;

    return ( lc $data_block->{'name'} eq 'on_this_dictionary' )
}

##
# Evaluates if a given dictionary data block defines a category.
#
# A proper category definition should have 'null' as the data type,
# 'category_overview' as the parent category and fit the category
# naming convention.
#
# @source [1]
#       https://www.iucr.org/resources/cif/dictionaries/cif_core/diffs2.0-1.0
# @source [2]
#       3.1.5.3. Category descriptions,
#       "International Tables for Crystallography Volume G:
#        Definition and exchange of crystallographic data",
#       2005, 77, doi: 10.1107/97809553602060000107
#
# @param $data_block
#       Reference to a DDL1 dictionary data block as returned
#       by the COD::CIF::Parser.
# @return
#        1 if the data block defines a category,
#        0 otherwise.
##
sub is_category_block
{
    my ( $data_block ) = @_;

    # category definition should have the 'null' data type
    my $type = get_data_type( $data_block );
    if ( defined $type ) {
        return $type eq 'null' ? 1 : 0;
    }

    # category definition should have the 'category_overview' parent category
    my $category_name = get_category_name( $data_block );
    if ( defined $category_name ) {
        return $category_name eq 'category_overview' ? 1 : 0;
    }

    # category name should fit the naming convention
    my $name = get_data_name( $data_block );
    if ( defined $name ) {
        return is_proper_category_name( $name ) ? 1 : 0;
    }

    return 0;
}

##
# Evaluates if the data name adheres to the category naming convention.
#
# @source [1]
#       https://www.iucr.org/resources/cif/dictionaries/cif_core/diffs2.0-1.0
# @source [2]
#       3.1.5.3. Category descriptions,
#       "International Tables for Crystallography Volume G:
#        Definition and exchange of crystallographic data",
#       2005, 77, doi: 10.1107/97809553602060000107
#
# @param $data_name
#       Name of the category.
# @return
#       1 is the data name is a proper category name,
#       0 otherwise.
##
sub is_proper_category_name
{
    my ( $data_name ) = @_;

    return $data_name =~ m/_\[[^\]]*\]$/;
}

##
# Converts a category name from the form that is used in category definitions
# to the form that is used in data item definitions. 
#
# Category names in category definitions are recorded using the '_name'
# data item and take the form of '_category_name_[]'. These names are
# also called 'pseudo' data names.
#
# Category names in data item definitions are recorded using the '_category'
# data item and take the form of 'category_name'. 
#
# @source [1]
#       3.1.5.3. Category descriptions,
#       "International Tables for Crystallography Volume G:
#        Definition and exchange of crystallographic data",
#       2005, 77, doi: 10.1107/97809553602060000107
#
# @param pseudo_name
#       Pseudo data name of the category as recorder in the category
#       definition data block using the '_name' data item.
# @return
#       Category name in the form that is used in data item definitions.
##
sub convert_pseudo_data_name_to_category_name
{
    my ( $pseudo_name ) = @_;

    my $category_name = $pseudo_name;
    if ( $pseudo_name =~ m/^_(.+)_\[[^\]]*\]$/ ) {
        $category_name = $1;
    }

    return $category_name;
}

1;
