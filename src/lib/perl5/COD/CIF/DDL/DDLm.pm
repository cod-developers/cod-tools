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
use Clone qw( clone );
use POSIX qw( strftime );
use Scalar::Util qw( looks_like_number );

use COD::CIF::Tags::Manage qw(
    new_datablock
    exclude_tag
    get_item_loop_index
    has_special_value
    has_numeric_value
    rename_tag
    set_loop_tag
    set_tag
);
use COD::CIF::Tags::Print qw( pack_precision );
use COD::CIF::Unicode2CIF qw( cif2unicode );
use COD::DateTime qw( canonicalise_timestamp );
use COD::Precision qw( unpack_cif_number );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    build_ddlm_dic
    canonicalise_ddlm_value
    cif2ddlm
    ddl2ddlm
    get_category_id
    get_data_alias
    get_data_name
    get_definition_class
    get_definition_scope
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
        } elsif ( $scope eq 'Category' ) {
            $categories{ lc get_data_name( $save_block ) } = $save_block;
        } elsif ( $scope eq 'Item' ) {
            $items{ lc get_data_name( $save_block ) } = $save_block;
        } else {
            warn "WARNING, the '$save_block->{'name'}' save block contains " .
                 "an unrecognised '$scope' definition scope" .
                 ' -- the save block will be ignored in further processing' . "\n"
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
# Converts (in a rather crude way) CIF data blocks of DDL1 dictionaries
# to DDLm in order to represent them using the same code. This method
# should not be used to translate DDL1 to DDLm for any other purposes
# except preview, as it is largely based on guesswork and works
# satisfactory only for testing purposes.
##
sub ddl2ddlm
{
    my( $ddl_datablocks, $options ) = @_;

    $options = {} unless $options;
    my( $keep_original_date, $new_version, $imports ) = (
        $options->{keep_original_date},
        $options->{new_version},
        $options->{imports},
    );

    my $category_overview = 'category_overview';

    my %tags_to_rename = (
        _category            => '_name.category_id',
        _definition          => '_description.text',
        _enumeration         => '_enumeration_set.state',
        _enumeration_default => '_enumeration.default',
        _enumeration_detail  => '_enumeration_set.detail',
        _enumeration_range   => '_enumeration.range',
        _example             => '_description_example.case',
        _example_detail      => '_description_example.detail',
        _units_detail        => '_units.code',
    );

    my %typemap = (
        char => 'Text',
        numb => 'Real',
    );

    my @tags_to_exclude = ( '_list', '_name', '_type', '_type_conditions', '_units' );

    my $date;
    if( $keep_original_date ) {
        $date = get_dic_item_value( $ddl_datablocks->[0], '_dictionary_update' );
    } else {
        $date = strftime( '%F', gmtime() );
    }

    my $dictionary_name =
        dic_filename_to_title( get_dic_item_value( $ddl_datablocks->[0],
                                                   '_dictionary_name' ) );

    my $ddlm_datablock = new_datablock( $dictionary_name, '2.0' );

    my $head = new_datablock( $category_overview, '2.0' );
    set_tag( $head, '_definition.id', uc $category_overview );
    set_tag( $head, '_definition.class', 'Head' );
    set_tag( $head, '_definition.scope', 'Category' );
    set_tag( $head, '_name.object_id', uc $category_overview );
    set_tag( $head, '_name.category_id', $dictionary_name );
    if( $imports && @$imports ) {
        set_tag( $head,
                 '_import.get',
                 [ map { { file => $_,
                           save => dic_filename_to_title( $_ ),
                           mode => 'Full' } } @$imports ] );
    }
    push @{$ddlm_datablock->{save_blocks}}, $head;

    for my $datablock (@$ddl_datablocks) {
        next if $datablock->{name} eq 'on_this_dictionary';

        for my $name (@{$datablock->{values}{_name}}) {
            my $ddl_datablock = clone( $datablock );
            $ddl_datablock->{name} = $name;
            $ddl_datablock->{name} =~ s/^_//;
            $ddl_datablock->{name} =~ s/_\[\]$//;

            set_tag( $ddl_datablock, '_definition.update', $date );

            if( defined get_dic_item_value( $ddl_datablock, '_category' ) &&
                get_dic_item_value( $ddl_datablock, '_category' ) eq $category_overview ) {
                $name =~ s/^_//;
                $name =~ s/_\[\]$//;

                my @tags = grep { defined get_dic_item_value( $_, '_category' ) &&
                                  get_dic_item_value( $_, '_category' ) eq $name }
                                @$ddl_datablocks;
                my @loop_tags = grep { defined get_dic_item_value( $_, '_list' ) &&
                                       get_dic_item_value( $_, '_list' ) eq 'yes' }
                                     @tags;

                if( @loop_tags && @tags != @loop_tags ) {
                    warn "some data items of category '$name' are defined " .
                         'as looped while some are not -- category has to ' .
                         'be split in order to be represented correctly ' .
                         'in DDLm' . "\n";
                }

                # Uppercasing category names to make them stand out:
                $name = uc $name;
                set_tag( $ddl_datablock,
                         '_definition.class',
                         @tags && @tags == @loop_tags ? 'Loop' : 'Set' );
                set_tag( $ddl_datablock, '_definition.scope', 'Category' );

                # Uppercasing category data block code
                # FIXME: commented it out for now since it seems to break
                # the 'dic2markdown' script
                # $ddl_datablock->{'name'} = uc $ddl_datablock->{'name'};
            } else {
                set_tag( $ddl_datablock, '_definition.class', 'Datum' );
                set_tag( $ddl_datablock, '_type.container', 'Single' );

                my $type_purpose;

                if( get_dic_item_value( $ddl_datablock, '_type' ) ) {
                    set_tag( $ddl_datablock,
                             '_type.contents',
                             $typemap{get_dic_item_value( $ddl_datablock, '_type' )} );
                    if( get_dic_item_value( $ddl_datablock, '_type' ) eq 'numb' &&
                        defined get_dic_item_value( $ddl_datablock, '_type_conditions' ) &&
                        get_dic_item_value( $ddl_datablock, '_type_conditions' ) =~ /^esd|su$/ ) {
                        $type_purpose = 'Measurand';
                    }
                }

                if( defined get_dic_item_value( $ddl_datablock, '_enumeration' ) ) {
                    $type_purpose = 'State';
                }

                if( $type_purpose ) {
                    set_tag( $ddl_datablock,
                             '_type.purpose',
                             $type_purpose );
                }
            }

            if(  defined get_dic_item_value( $ddl_datablock, '_units' ) &&
                !defined get_dic_item_value( $ddl_datablock, '_units_detail' ) ) {
                warn "'_units_detail' is not defined for '$ddl_datablock->{name}'\n";
            }

            for my $tag (sort keys %tags_to_rename) {
                next if !defined get_dic_item_value( $ddl_datablock, $tag );

                $ddl_datablock->{values}{$tag} =
                    [ map { cif2unicode( $_ ) }
                          @{$ddl_datablock->{values}{$tag}} ];

                rename_tag( $ddl_datablock,
                            $tag,
                            $tags_to_rename{$tag} );
            }

            for my $tag (@tags_to_exclude) {
                next if !defined get_dic_item_value( $ddl_datablock, $tag );
                exclude_tag( $ddl_datablock, $tag );
            }

            if( exists $ddl_datablock->{values}{'_units.code'} ) {
                $ddl_datablock->{values}{'_units.code'}[0] =~ s/ /_/g;
                $ddl_datablock->{values}{'_units.code'}[0] =
                    lc $ddl_datablock->{values}{'_units.code'}[0];
                $ddl_datablock->{values}{'_units.code'}[0] =~
                    s/angstroem/angstrom/g;
                $ddl_datablock->{values}{'_units.code'}[0] =~
                    s/electron-?volt/electron_volt/g;
            }

            if( !exists $ddl_datablock->{values}{'_name.category_id'} ) {
                set_tag( $ddl_datablock,
                         '_name.category_id',
                         $category_overview );
            }

            set_tag( $ddl_datablock, '_definition.id', $name );
            set_tag( $ddl_datablock,
                     '_name.object_id',
                     $ddl_datablock->{values}{'_definition.id'}[0] );

            push @{$ddlm_datablock->{save_blocks}}, $ddl_datablock;
        }
    }

    set_tag( $ddlm_datablock, '_dictionary.title', $dictionary_name );
    set_tag( $ddlm_datablock,
             '_dictionary.version',
             ($new_version
                ? $new_version
                : $ddl_datablocks->[0]{values}{_dictionary_version}[0]) );
    set_tag( $ddlm_datablock, '_dictionary.date', $date );
    set_tag( $ddlm_datablock, '_dictionary.class', 'Instance' );
    set_tag( $ddlm_datablock, '_dictionary.ddl_conformance', '3.13.1' );

    if( exists $ddl_datablocks->[0]{values}{_dictionary_history} ) {
        set_loop_tag( $ddlm_datablock,
                      '_dictionary_audit.version',
                      '_dictionary_audit.version',
                      [ $ddl_datablocks->[0]{values}{_dictionary_version}[0] ] );
        set_loop_tag( $ddlm_datablock,
                      '_dictionary_audit.date',
                      '_dictionary_audit.version',
                      [ $ddl_datablocks->[0]{values}{_dictionary_update}[0] ] );
        set_loop_tag( $ddlm_datablock,
                      '_dictionary_audit.revision',
                      '_dictionary_audit.version',
                      $ddl_datablocks->[0]{values}{_dictionary_history} );
        if( $new_version ) {
            unshift @{$ddlm_datablock->{values}{'_dictionary_audit.version'}},
                    $new_version;
            unshift @{$ddlm_datablock->{values}{'_dictionary_audit.date'}},
                    strftime( '%F', gmtime() );
            unshift @{$ddlm_datablock->{values}{'_dictionary_audit.revision'}},
                    'Automatically converting to DDLm';
        }
    }

    return $ddlm_datablock;
}

##
# Converts (in a rather crude way) CIF data block to a DDLm dictionary.
##
sub cif2ddlm
{
    my( $dataset ) = @_;

    my $ddlm = new_datablock( 'CIF_PRELIMINARY', '2.0' );

    set_tag( $ddlm, '_dictionary.title', 'CIF_PRELIMINARY' );
    set_tag( $ddlm, '_definition.class', 'Reference' );

    push @{$ddlm->{save_blocks}}, new_datablock( 'PRELIMINARY_GROUP', '2.0' );
    set_tag( $ddlm->{save_blocks}[0], '_definition.id', 'PRELIMINARY_GROUP' );
    set_tag( $ddlm->{save_blocks}[0], '_definition.scope', 'Category' );
    set_tag( $ddlm->{save_blocks}[0], '_definition.class', 'Head' );

    my @loop_names;

    while( my( $i, $loop ) = each @{$dataset->{loops}}) {
        my $name = make_category_name( @$loop );
        $name = 'loop' . ( $name ? $name : "_$i" );
        push @loop_names, $name;

        my $description = new_datablock( $name, '2.0' );

        set_tag( $description, '_definition.id', $name );
        set_tag( $description, '_definition.scope', 'Category' );
        set_tag( $description, '_definition.class', 'Loop' );
        set_tag( $description, '_name.category_id', 'PRELIMINARY_GROUP' );

        push @{$ddlm->{save_blocks}}, $description;
    }

    for my $tag (@{$dataset->{tags}}) {
        my $description = new_datablock( $tag, '2.0' );

        set_tag( $description, '_definition.id', $tag );
        set_tag( $description, '_definition.scope', 'Item' );
        set_tag( $description, '_definition.class', 'Attribute' );
        set_tag( $description,
                 '_name.category_id',
                 defined $dataset->{inloop}{$tag}
                    ? $loop_names[$dataset->{inloop}{$tag}]
                    : 'PRELIMINARY_GROUP' );

        push @{$ddlm->{save_blocks}}, $description;
    }

    return $ddlm;
}

sub make_category_name
{
    my @tags = @_;

    if( $tags[0] =~ /^([^\.]+)\./ ) {
        my $prefix = $1;
        return $prefix
            unless grep { my( $p ) = split /\./, $_; $p ne $prefix } @tags;
    }

    return longest_common_tag_prefix( @tags );
}

sub longest_common_tag_prefix
{
    my @strings = @_;
    my( $shortest ) = sort { length($a) <=> length($b) } @strings;

    my @parts = $shortest =~ /([_\.][^_\.]+)/g;
    my $prefix;
    for( my $i = 0; $i < @parts; $i++ ) {
        my $prefix_now = join '', @parts[0..$i];
        last if grep { substr( $_, 0, length( $prefix_now ) ) ne $prefix_now } @strings;
        $prefix = $prefix_now;
    }
    return $prefix;
}

sub dic_filename_to_title
{
    my( $filename ) = @_;
    $filename = uc $filename if $filename =~ s/\.dic$//;
    return $filename;
}

# BEGIN: subroutines focused on data validation

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
        if ( looks_like_number( $uvalue ) ) {
            return pack_precision( $uvalue + 0, $su );
        } else {
            return $value;
        }
    }

    return $value
}

1;
