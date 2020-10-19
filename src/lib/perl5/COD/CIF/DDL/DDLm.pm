#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* A set of subroutines used for handling the CIF
#* Methods Dictionary Definition Language (DDLm) files.
#**

package COD::CIF::DDL::DDLm;

use strict;
use warnings;
use Scalar::Util qw( looks_like_number );

use COD::CIF::Tags::Print qw( pack_precision );
use COD::DateTime qw( canonicalise_timestamp );
use COD::Precision qw( unpack_cif_number );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    build_ddlm_dic
    canonicalise_ddlm_value
    get_all_data_names
    get_category_id
    get_data_alias
    get_data_name
    get_definition_class
    get_definition_scope
    get_dictionary_class
    get_type_contents
    get_type_container
    get_type_dimension
    get_type_purpose
    is_looped_category
    set_category_id
);

# From DDLm reference version 3.14.0
my %data_item_defaults = (
    '_definition.scope' => 'Item',
    '_definition.class' => 'Datum',
    '_dictionary.class' => 'Instance',
    '_type.container'   => 'Single',
    '_type.contents'    => 'Text',
    '_type.purpose'     => 'Describe',
);

##
# Determine the content type for the given data item as defined in a DDLm
# dictionary file. The "Implied" and "ByReference" content types are
# automatically resolved to more definitive content types.
#
# @param $data_name
#       Data name of the data item for which the content type should
#       be determined.
# @param $data_frame
#       CIF data frame (data block or save block) in which the data item
#       resides as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @return
#       Content type for the given data item as defined in
#       the provided DDLm dictionary.
##
sub get_type_contents
{
    my ($data_name, $data_frame, $dic) = @_;

    my $type_contents = $data_item_defaults{'_type.contents'};
    if ( exists $dic->{'Item'}{$data_name}{'values'}{'_type.contents'} ) {
        my $dic_item_frame = $dic->{'Item'}{$data_name};
        $type_contents = lc $dic_item_frame->{'values'}{'_type.contents'}[0];

        if ( $type_contents eq 'byreference' ) {
            $type_contents = resolve_content_type_references( $data_name, $dic );
        }

        # The 'implied' type content refers to type content
        # of the data frame in which the data item resides
        if ( $type_contents eq 'implied' ) {
            if ( exists $data_frame->{'values'}{'_type.contents'}[0] ) {
                $type_contents = $data_frame->{'values'}{'_type.contents'}[0];
            } else {
                $type_contents = $data_item_defaults{'_type.contents'};
            }
        }

        if ( $type_contents eq 'byreference' ) {
            $type_contents = resolve_content_type_references( $data_name, $dic );
        }
    }

    return $type_contents;
}

sub resolve_content_type_references
{
    my ($data_name, $dic) = @_;

    my $type_contents = $data_item_defaults{'_type.contents'};
    if ( exists $dic->{'Item'}{$data_name}{'values'}{'_type.contents'} ) {
        my $dic_item_frame = $dic->{'Item'}{$data_name};
        $type_contents = lc $dic_item_frame->{'values'}{'_type.contents'}[0];

        if ( $type_contents eq 'byreference' ) {
            if ( exists $dic_item_frame->{'values'}
                                 {'_type.contents_referenced_id'} ) {
                my $ref_data_name = lc $dic_item_frame->{'values'}
                                        {'_type.contents_referenced_id'}[0];
                if ( exists $dic->{'Item'}{$ref_data_name} ) {
                    $type_contents =
                        resolve_content_type_references( $ref_data_name, $dic );
                } else {
                    $type_contents = $data_item_defaults{'_type.contents'};
                    warn "definition of the '$data_name' data item references " .
                         "the '$ref_data_name' data item for its content type, " .
                         'but the referenced data item does not seem to be ' .
                         'defined in the dictionary -- the default content ' .
                         "type '$type_contents' will be used" . "\n";
                }
            } else {
                $type_contents = $data_item_defaults{'_type.contents'};
                warn "data item '$data_name' is declared as being of the " .
                     '\'byReference\' content type, but the ' .
                     '\'_type.contents_referenced_id\' data item is ' .
                     'not provided in the definition save frame -- ' .
                     "the default content type '$type_contents' will be used" .
                     "\n";
            }
        }
    }

    return $type_contents;
}

sub get_type_container
{
    my ( $data_frame ) = @_;

    return get_dic_item_value( $data_frame, '_type.container' );
}

sub get_type_dimension
{
    my ( $data_frame ) = @_;

    return get_dic_item_value( $data_frame, '_type.dimension' );
}

sub get_type_purpose
{
    my ( $data_frame ) = @_;

    return lc get_dic_item_value( $data_frame, '_type.purpose' );
}

sub get_definition_class
{
    my ( $data_frame ) = @_;

    return get_dic_item_value( $data_frame, '_definition.class' );
}

sub get_definition_scope
{
    my ( $data_frame ) = @_;

    return get_dic_item_value( $data_frame, '_definition.scope' );
}

sub get_dictionary_class
{
    my ( $data_frame ) = @_;

    return get_dic_item_value( $data_frame, '_dictionary.class' );
}

sub get_dic_item_value
{
    my ( $data_frame, $data_name ) = @_;

    my $value = $data_item_defaults{$data_name};
    if ( exists $data_frame->{'values'}{$data_name} ) {
        $value = $data_frame->{'values'}{$data_name}[0];
    };

    return $value;
}

##
# Builds a data structure that is more convenient to traverse in regards to
# the Dictionary, Category and Item context classification.
#
# @param $data
#       CIF data block as returned by the COD::CIF::Parser.
# @return $struct
#       Hash reference with the following keys:
#       $struct = {
#        'Dictionary' -- a hash of all data blocks that belong to the
#                        Dictionary scope.
#        'Category'   -- a hash of all save blocks that belong to the
#                        Category scope;
#        'Item'       -- a hash of all save blocks that belong to the
#                        Item scope;
#        'Datablock'  -- a reference to the input $data structure
#       };
##
sub build_ddlm_dic
{
    my ($data) = @_;

    my %categories;
    my %items;
    for my $save_block ( @{$data->{'save_blocks'}} ) {
        my $scope = get_definition_scope( $save_block );
        # assigning the default value in case it was not provided
        $save_block->{'values'}{'_definition.scope'} = [ $scope ];

        if ( $scope eq 'Dictionary' ) {
            next; # TODO: do more research on this scope
        }

        my $data_name = get_data_name( $save_block );
        if (!defined $data_name) {
            warn "WARNING, the '$save_block->{'name'}' save block does not " .
                 'contain the mandatory \'_definition.id\' data item -- ' .
                 'the save block will be ignored in further processing' . "\n";
            next;
        }
        $data_name = lc $data_name;

        if ( $scope eq 'Category' ) {
            $categories{ $data_name } = $save_block;
        } elsif ( $scope eq 'Item' ) {
            $items{ $data_name } = $save_block;
        } else {
            warn "WARNING, the '$save_block->{'name'}' save block contains " .
                 "an unrecognised '$scope' definition scope -- " .
                 'the save block will be ignored in further processing' . "\n"
        }
    };

    my $struct = {
        'Dictionary' => { $data->{'name'} => $data },
        'Category'   => \%categories,
        'Item'       => \%items,
        'Datablock'  => $data
    };

    for my $data_name ( sort keys %{$struct->{'Item'}} ) {
        my $save_block = $struct->{'Item'}{$data_name};
        $save_block->{'values'}{'_type.contents'}[0] =
            resolve_content_type_references( $data_name, $struct );
        for ( @{ get_data_alias( $save_block ) } ) {
            $struct->{'Item'}{ lc $_ } = $save_block;
        }
    }

    return $struct;
}

##
# Extracts the definition id from the data item definition frame.
# In case the definition frame does not contain a definition id
# an undef value is returned.
#
# @param $data_frame
#       Data item definition frame as returned by the COD::CIF::Parser.
# @return $data_name
#       String containing the definition id or undef value if the data frame
#       does not contain a definition id.
##
sub get_data_name
{
    my ( $data_frame ) = @_;

    my $data_name;
    if ( exists $data_frame->{'values'}{'_definition.id'} ) {
        $data_name = $data_frame->{'values'}{'_definition.id'}[0];
    }

    return $data_name;
}

##
# Extracts all provided data item names from a data item definition frame.
# The data names include the main definition id and definition id aliases.
#
# @param $data_frame
#       Data item definition frame as returned by the COD::CIF::Parser.
# @return $data_name
#       Array reference to a list of data names identifying a data item
#       or a reference to an empty array if no names were found.
##
sub get_all_data_names
{
    my ( $data_frame ) = @_;

    my @data_names;
    my $data_name = get_data_name($data_frame);
    if (defined $data_name) {
        push @data_names, $data_name;
    }
    push @data_names, @{get_data_alias($data_frame)};

    return \@data_names;
}

##
# Extracts the category id from the data item definition frame.
# In case the definition frame does not contain a category id
# an undef value is returned.
#
# @param $data_frame
#       Data item definition frame as returned by the COD::CIF::Parser.
# @return $data_name
#       String containing the category id or undef value if the data frame
#       does not contain a category id.
##
sub get_category_id
{
    my ( $data_frame ) = @_;

    my $category_id;
    if ( exists $data_frame->{'values'}{'_name.category_id'} ) {
        $category_id = $data_frame->{'values'}{'_name.category_id'}[0];
    }

    return $category_id;
}

##
# Sets the given value as the data item category.
#
# @param $data_frame
#       Data item definition frame as returned by the COD::CIF::Parser.
# @param $data_name
#       String containing the category id.
##
sub set_category_id
{
    my ( $data_frame, $category_id ) = @_;

    $data_frame->{'values'}{'_name.category_id'}[0] = $category_id;

    return
}

##
# Determines if the category is looped according to a DDLm category
# definition frame.
#
# @param $data_frame
#       Data item definition frame as returned by the COD::CIF::Parser.
# @return
#       Boolean value denoting if the category is looped.
##
sub is_looped_category
{
    my ( $data_frame ) = @_;

    return lc get_definition_class( $data_frame ) eq 'loop';
}

##
# Extracts aliases from a DDLm data item definition frame.
#
# @param $data_frame
#       Data item definition frame as returned by the COD::CIF::Parser.
# @return $aliases
#       Array reference to a list of aliases.
##
sub get_data_alias
{
    my ( $data_frame ) = @_;

    my @aliases;
    if ( exists $data_frame->{'values'}{'_alias.definition_id'} ) {
        push @aliases, @{$data_frame->{'values'}{'_alias.definition_id'}};
    }

    return \@aliases;
}

##
# Return a canonical representation of the value based on its DDLm data type.
#
# @param $value
#       Data value that should be canonicalised.
# @param $content_type
#       Content type of the value as defined in a DDLm dictionary file.
##
sub canonicalise_ddlm_value
{
    my ( $value, $content_type ) = @_;

    $content_type = lc $content_type;

    if ( $content_type eq 'text' ||
         $content_type eq 'date' ) {
        return $value;
    }

    if ( $content_type eq 'code' ||
         $content_type eq 'name' ||
         $content_type eq 'tag' ) {
        return lc $value;
    }

    # TODO: proper parsing should be carried out eventually
    if ( $content_type eq 'uri' ) {
        return $value;
    }

    if ( $content_type eq 'datetime' ) {
        my $canonical_value;
        eval {
            $canonical_value = canonicalise_timestamp($value);
        };
        if ( $@ ) {
            return $value;
        }

        return $canonical_value;
    }

    if ( $content_type eq 'symop' ) {
        return $value;
    }

    # TODO: the dimension data type is currently not yet fully established
    if ( $content_type eq 'dimension' ) {
        return $value;
    }

    if ( $content_type eq 'count'   ||
         $content_type eq 'index'   ||
         $content_type eq 'integer' ||
         $content_type eq 'real'
    ) {
        my ( $uvalue, $su ) = unpack_cif_number($value);
        if ( looks_like_number( $uvalue ) && $uvalue !~ m/^[+-]?(inf|nan)/i ) {
            return pack_precision( $uvalue + 0, $su );
        } else {
            return $value;
        }
    }

    return $value
}

1;
