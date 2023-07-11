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
use List::MoreUtils qw( any );
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
    get_type_source
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
    '_type.source'      => 'Assigned',
);

my $IMAG_UNIT = 'j';

##
# Determine the content type for the given data item as defined in a DDLm
# dictionary file. The default behaviour is to resolve the "Implied" and
# "ByReference" content types to more definitive content types.
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
# @param $options
#       Reference to a hash of options. The following options are recognised:
#       {
#         # Boolean value denoting if the 'Implied' content type
#         # should be resolved to a more definitive content type.
#         # Default: '1'.
#           'resolve_implied_type' => 1,
#         # Boolean value denoting if the 'ByReference' content type
#         # should be resolved to a more definitive content type.
#         # Default: '1'.
#           'resolve_byreference_type' => 1,
#       }
# @return
#       Content type for the given data item as defined in
#       the provided DDLm dictionary.
##
sub get_type_contents
{
    my ($data_name, $data_frame, $dic, $options) = @_;

    $options = {} if !defined $options;
    my $resolve_implied = defined $options->{'resolve_implied_type'} ?
                                  $options->{'resolve_implied_type'} : 1;
    my $resolve_byreference =
                          defined $options->{'resolve_byreference_type'} ?
                                  $options->{'resolve_byreference_type'} : 1;

    my $type_contents = $data_item_defaults{'_type.contents'};
    if ( exists $dic->{'Item'}{$data_name}{'values'}{'_type.contents'} ) {
        my $dic_item_frame = $dic->{'Item'}{$data_name};
        $type_contents = $dic_item_frame->{'values'}{'_type.contents'}[0];

        my $examined_items = [];
        if ( lc $type_contents eq 'byreference' && $resolve_byreference ) {
            my $resolution_results = resolve_content_type_references(
                                         $data_name,
                                         $dic,
                                         $examined_items
                                     );
            $type_contents  = $resolution_results->{'content_type'};
            $examined_items = $resolution_results->{'examined_items'};
        }

        # The 'Implied' content type refers to content type
        # of the data frame in which the data item resides
        if ( lc $type_contents eq 'implied' && $resolve_implied ) {
            if ( exists $data_frame->{'values'}{'_type.contents'}[0] ) {
                $type_contents = $data_frame->{'values'}{'_type.contents'}[0];
            } else {
                $type_contents = $data_item_defaults{'_type.contents'};
            }

            if ( lc $type_contents eq 'byreference' && $resolve_byreference ) {
                my $ref_data_name = get_data_name($data_frame);
                if (defined $ref_data_name) {
                    my $resolution_results = resolve_content_type_references(
                                                 get_data_name($data_frame),
                                                 $dic,
                                                 $examined_items
                                             );
                    $type_contents = $resolution_results->{'content_type'}
                } else {
                    $type_contents = $data_item_defaults{'_type.contents'};
                }
            }
        }
    }

    return $type_contents;
}

##
# Determines the content type by resolving content type references. Recursive.
#
# @param $data_name
#       Data name of the data item for which the content type should
#       be determined.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @param $examined_items
#       Reference to an array of data item names that have previously
#       occurred as references while trying to resolve the content type.
#       Data names are given in the order they have been examined.
#       Used to detect circular dependencies. Default: [].
# @return
#       Reference to a data structure of the following form:
#       {
#         # Content type value of the referenced data item.
#         # Can be 'ByReference'.
#           'content_type'  => 'Text',
#         # Names of data items that have previously occurred as
#         # references while trying to resolve the content type.
#         # Data names are given in the order they have been examined.
#           'examined_items' => [
#               '_examined_item.first',
#               '_examined_item.second,
#               # ...,
#               '_examined_item.last',
#           ]
#       }
##
sub resolve_content_type_references
{
    my ($data_name, $dic, $examined_items) = @_;

    my $REF_ATTRIBUTE = '_type.contents_referenced_id';

    $examined_items = [] if !defined $examined_items;

    my $type_contents = $data_item_defaults{'_type.contents'};

    if (any { lc $data_name eq lc $_ } @{$examined_items}) {
        warn 'content type of the \'' . $examined_items->[0] . '\' data item ' .
             'could not be resolved due to a circular reference caused by ' .
             "the '$REF_ATTRIBUTE' attribute -- the default '$type_contents' " .
             'content type will be used' . "\n";
        push @{$examined_items}, $data_name;
        return {
                  'content_type'   => $type_contents,
                  'examined_items' => $examined_items
               };
    }

    push @{$examined_items}, $data_name;
    if ( exists $dic->{'Item'}{$data_name}{'values'}{'_type.contents'} ) {
        my $dic_item_frame = $dic->{'Item'}{$data_name};
        $type_contents = $dic_item_frame->{'values'}{'_type.contents'}[0];

        if ( lc $type_contents eq 'byreference' ) {
            if ( exists $dic_item_frame->{'values'}{$REF_ATTRIBUTE} ) {
                my $ref_data_name = lc $dic_item_frame->{'values'}
                                                   {$REF_ATTRIBUTE}[0];
                if ( exists $dic->{'Item'}{$ref_data_name} ) {
                    my $result = resolve_content_type_references(
                                     $ref_data_name,
                                     $dic,
                                     $examined_items
                                 );
                    $type_contents = $result->{'content_type'};
                } else {
                    $type_contents = $data_item_defaults{'_type.contents'};
                    warn "definition of the '$data_name' data item " .
                         "references the '$ref_data_name' data item for its " .
                         'content type, but the referenced data item is not ' .
                         'defined in the dictionary -- the default ' .
                         "'$type_contents' content type will be used" . "\n";
                }
            } else {
                $type_contents = $data_item_defaults{'_type.contents'};
                warn "data item '$data_name' is declared as being of the " .
                     "'byReference' content type, but the '$REF_ATTRIBUTE' " .
                     'attribute is not provided in the definition save ' .
                     "frame -- the default '$type_contents' content type " .
                     'will be used' . "\n";
            }
        }
    }

    return  {
                'content_type'   => $type_contents,
                'examined_items' => $examined_items
            };
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

sub get_type_source
{
    my ( $data_frame ) = @_;

    return lc get_dic_item_value( $data_frame, '_type.source' );
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
# Builds a data structure that is more convenient to traverse in regard to
# the Dictionary, Category and Item context classification.
#
# @param $data
#       CIF data block as returned by the COD::CIF::Parser.
# @param $options
#       Reference to a hash of options. The following options are recognised:
#       {
#         # Boolean value denoting if the 'ByReference' content type
#         # should be resolved to a more definitive content type.
#         # Default: '1'.
#           'resolve_content_types' => 1,
#       }
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
#       }
##
sub build_ddlm_dic
{
    my ($data, $options) = @_;

    $options = {} if !defined $options;
    my $resolve_content_types = defined $options->{'resolve_content_types'} ?
                                        $options->{'resolve_content_types'} : 1;

    my %categories;
    my %items;
    for my $save_block ( @{$data->{'save_blocks'}} ) {
        my $scope = get_definition_scope( $save_block );
        # Assign the default value in case it was not provided
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
        if ($resolve_content_types) {
            my $result = resolve_content_type_references( $data_name, $struct );
            $save_block->{'values'}{'_type.contents'}[0] =
                                                    $result->{'content_type'};
        }
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
# Parses a value that has the 'Complex' DDLm content type.
#
# @param $value
#       Value that should be parsed.
# @return
#       Reference to a hash of the following form:
#       {
#         # Real part of the complex number. May include
#         # the standard uncertainty in parentheses form.
#           'real' => '3.14(1)',
#         # Imaginary part of the complex number without
#         # the imaginary unit 'j'. May include the standard
#         # uncertainty in parentheses form. It is currently
#         # assumed that the imaginary part is always positive
#         # and never contains an explicit plus sign.
#           'complex' => '6.28(2)',
#         # Sign that separates the real part from the imaginary part (+/-).
#           'sign' => '-',
#       }
#       or undef if the value could not be parsed successfully.
##
sub parse_ddlm_complex_value
{
    my ($value) = @_;

    my $u_int   = '[0-9]+';
    my $int     = "[+-]?${u_int}";
    my $exp     = "[eE][+-]?${u_int}";
    my $u_float = "(?:${u_int}${exp})|(?:[0-9]*[.]${u_int}|${u_int}+[.])(?:$exp)?";
    my $float   = "[+-]?(?:${u_float})";
    my $su      = "[(]${u_int}[)]";

    if ( $value =~ m{
                     ^(
                        (?:$int|${float})(?:${su})?
                      )
                      [ ]?
                      ([+-])
                      [ ]?
                      (
                        (?:${u_int}|${u_float})(?:${su})?
                      )
                      ${IMAG_UNIT}$
                    }x ) {
        return {
                 'real'    => $1,
                 'sign'    => $2,
                 'imag'    => $3,
               }
    }

    return
}

##
# Returns a canonical representation of the value based on its DDLm data type.
#
# @param $value
#       Data value that should be canonicalised.
# @param $content_type
#       Content type of the value as defined in a DDLm dictionary file.
# @param $return
#       Canonical representation of the value.
##
sub canonicalise_ddlm_value
{
    my ( $value, $content_type ) = @_;

    $content_type = lc $content_type;

    if ( $content_type eq 'text' ||
         $content_type eq 'word' ||
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
        return canonicalise_ddlm_number($value);
    }

    if ( $content_type eq 'imag' ) {
        return canonicalise_ddlm_imag_value($value);
    }

    if ( $content_type eq 'complex' ) {
        return canonicalise_ddlm_complex_value($value);
    }

    return $value
}

##
# Returns a canonical representation of a value based on
# the syntax of the numeric DDLm content types (e.g. 'Integer', 'Real').
#
# @param $value
#       Data value that should be canonicalised.
# @param $return
#       Canonical representation of the value.
##
sub canonicalise_ddlm_number
{
    my ($value) = @_;

    my ( $uvalue, $su ) = unpack_cif_number($value);
    if ( looks_like_number( $uvalue ) && $uvalue !~ m/^[+-]?(?:inf|nan)/i ) {
        return pack_precision( $uvalue + 0, $su );
    }

    return $value;
}

##
# Returns a canonical representation of a value based on
# the syntax of the 'Imag' DDLm content type.
#
# @param $value
#       Data value that should be canonicalised.
# @param $return
#       Canonical representation of the value.
##
sub canonicalise_ddlm_imag_value
{
    my ($value) = @_;

    my $number = $value;
    $number =~ s/${IMAG_UNIT}$//;
    if ($number ne $value) {
        return (canonicalise_ddlm_number($number) . $IMAG_UNIT);
    }

    return $value;
}

##
# Returns a canonical representation of a value based on
# the syntax of the 'Complex' DDLm content type.
#
# @param $value
#       Data value that should be canonicalised.
# @param $return
#       Canonical representation of the value.
##
sub canonicalise_ddlm_complex_value
{
    my ($value) = @_;

    my $parsed_value = parse_ddlm_complex_value($value);
    if (defined $parsed_value) {
        my $real_part = $parsed_value->{'real'};
        $real_part = canonicalise_ddlm_number($real_part);

        my $imag_part = $parsed_value->{'imag'};
        $imag_part .= $IMAG_UNIT;
        $imag_part = canonicalise_ddlm_imag_value($imag_part);

        return $real_part . $parsed_value->{'sign'} . $imag_part;
    }

    return $value;
}

1;
