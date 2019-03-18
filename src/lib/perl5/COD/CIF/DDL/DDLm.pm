#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* A set of subroutines used for handling the CIF
#* Dictionary Definition Language (DDL) files.
#**

package COD::CIF::DDL::DDLm;

use strict;
use warnings;
use Clone qw( clone );
use COD::CIF::Parser qw( parse_cif );
use COD::CIF::Tags::Manage qw(
    new_datablock
    exclude_tag
    rename_tag
    set_loop_tag
    set_tag
);
use COD::CIF::Unicode2CIF qw( cif2unicode );
use COD::ErrorHandler qw( process_parser_messages );
use POSIX qw( strftime );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    build_search_struct
    cif2ddlm
    ddl2ddlm
    get_category_id
    get_data_alias
    get_data_name
    get_definition_class
    get_definition_scope
    get_imported_files
    get_type_contents
    get_type_container
    get_type_purpose
    merge_imported_files
    merge_save_blocks
    is_looped_category
);

# From DDLm dictionary version 3.13.1
my %import_defaults = (
    'mode' => 'Contents'
);

my %data_item_defaults = (
    # DDLm version 3.11.10
    '_definition.scope' => 'Item',
    '_definition.class' => 'Datum',
    '_type.container'   => 'Single',
    '_type.contents'    => 'Text',
    '_type.purpose'     => 'Describe'
);

#
# dictionary = {
#   'file_path'       => [ 'dir1', 'dir2', 'dir3' ]
#   'container_file' =>
#   'imported_files'  =>
#   'parser_options'  =>
# }
#
# TODO: consider a more conservative dictionary import system
#
sub get_imported_files
{
    my ($params) = @_;
    my $file_path = $params->{'file_path'};
    my $container_file = $params->{'container_file'};
    my %imported_files = %{$params->{'imported_files'}};
    my $parser_options = $params->{'parser_options'};
    my $die_on_error_level =
        defined $params->{'die_on_error_level'} ?
                $params->{'die_on_error_level'} : 1;

    for my $saveblock ( @{$container_file->{'save_blocks'}} ) {
      if ( exists $saveblock->{'values'}{'_import.get'} &&
           exists $saveblock->{'values'}{'_import.get'}[0] ) {
        foreach my $import ( @{$saveblock->{'values'}{'_import.get'}[0]} ) {
          my $filename = $import->{'file'};
          if ( !exists $imported_files{$filename} ) {
            foreach my $path ( @{$file_path} ) {
              # FIXME: the path ends up with a double slash
              if ( -f "$path/$filename" ) {
                my ( $import_data, $err_count, $messages ) =
                  parse_cif( "$path/$filename", $parser_options );
                # TODO: check how the error messages interact with the
                # subroutine context
                process_parser_messages( $messages, $die_on_error_level );
                $imported_files{$filename} = $import_data->[0];
                my $single_import = get_imported_files( {
                    'file_path'      => $file_path,
                    'container_file' => $import_data->[0],
                    'imported_files' => \%imported_files,
                    'parser_options' => $parser_options
                } );
                %imported_files = %{$single_import};
                last;
              }
            }
          }
        }
      }
    }

    return \%imported_files;
}

# TODO: check for cyclic relationships
sub merge_imported_files
{
    my ($dict, $imported_files) = @_;

    for my $saveblock ( @{$dict->{'save_blocks'}} ) {
      if ( exists $saveblock->{'values'}{'_import.get'} &&
           exists $saveblock->{'values'}{'_import.get'}[0] ) {
        foreach my $import ( @{$saveblock->{'values'}{'_import.get'}[0]} ) {
          my $filename = $import->{'file'};
          if ( exists $imported_files->{$filename} ) {
            my $imported_file = $imported_files->{$filename};
            $imported_file = merge_imported_files($imported_file, $imported_files);
            my $target_saveblock = $import->{'save'};
            foreach my $imported_saveblock ( @{$imported_file->{'save_blocks'}} ) {
              if ( lc $imported_saveblock->{'name'} eq lc $target_saveblock ) {
                if ( lc get_definition_scope( $imported_saveblock ) eq 'category' ) {
                    my $imports = get_category_imports($saveblock, $imported_file, $import );
                    push @{$dict->{'save_blocks'}}, @{$imports};
                } else {
                    $saveblock = merge_save_blocks($saveblock, $imported_saveblock);
                }
              }
            }
          }
        }
      }
    }

    return $dict;
}

##
# Extracts the data blocks from a CIF data structure that should be imported
# to the importing category.
#
# Category import is implemented as described in the _import_details.mode
# save frame of the DDL dictionary version 13.3.1:
#
#  "Full" imports the entire definition together with any child definitions
#  (in the case of categories) found in the target dictionary. The importing
#  definition becomes the parent of the imported definition. As a special
#  case, a 'Head' category importing a'Head' category is equivalent to
#  importing all children of the imported 'Head' category as children of
#  the importing 'Head' category.
#
# @param $save_block
#       Category save frame that contains the import statement as returned
#       by the COD::CIF::Parser.
# @param $import_data
#       CIF data block of the imported CIF dictionary file as returned
#       by the COD::CIF::Parser.
# @param $import_options
#       Reference to an import option hash. The list of supported options
#       matches the one described in the _import_details.single_index frame
#       of the DDL dictionary version 13.3.1:
#           'file'         URI of source dictionary
#           'version'      version of source dictionary
#           'save'         save frame code of source definition
#           'mode'         mode for including save frames
#           'dupl'         option for duplicate entries
#           'miss'         option for missing duplicate entries
# @return
#       Reference to an array of data frames that should be added to
#       the importing dictionary.
##
sub get_category_imports
{
    my ($save_block, $import_data, $import_options) = @_;

    my $parent_block_scope = get_definition_scope( $save_block );

    if ( lc $parent_block_scope ne 'category' ) {
        die "ERROR, a category import '$import_options->{'save'}' from file " .
            "'$import_options->{'file'}' defined in a non-category save block " .
            "'$save_block->{'name'}'\n";
    }

    my $import_block;
    my $import_block_id = uc $import_options->{'save'};
    for my $block ( @{$import_data->{'save_blocks'}} ) {
        if ( uc $block->{'values'}{'_definition.id'}[0] eq $import_block_id ) {
            $import_block = $block;
            last;
        }
    }

    my $import_type = defined $import_options->{'mode'} ?
                              $import_options->{'mode'} :
                              $import_defaults{'mode'};

    # Head category importing a head category is a special case
    my $head_in_head = lc get_definition_class( $save_block )   eq 'head' &&
                       lc get_definition_class( $import_block ) eq 'head';

    # TODO: warn about an import type mismatch
    if ( $head_in_head ) {
        $import_type = 'full';
    }

    my $imported_save_blocks = get_child_blocks(
        $import_block_id,
        $import_data,
        {
         'recursive' => ( lc $import_type eq 'full' )
        }
    );

    my $parent_block_id = $save_block->{'values'}{'_definition.id'}[0];
    if ( $head_in_head ) {
        for my $block (@{$imported_save_blocks}) {
            if ( uc $block->{'values'}{'_name.category_id'}[0] eq $import_block_id ) {
                $block->{'values'}{'_name.category_id'}[0] = $parent_block_id;
            }
        }
    } else {
        $import_block->{'values'}{'_name.category_id'}[0] =
            $save_block->{'values'}{'_definition.id'}[0];
        push @{$imported_save_blocks}, $import_block;
    }

    return $imported_save_blocks;
}

##
# Selects blocks that belong to the given category.
#
# @param $id
#       Identifier name of the category. The identifier is usually stored as
#       the value of the '_definition.id' data item.
# @param $data
#       Reference to a data frame as returned by the COD::CIF::Parser.
# @param $options
#       Reference to a hash of options. The following options are recognised:
#       {
#       # Recursively select child blocks.
#           'recursive' => 0
#       }
# @return
#       Reference to an array of child blocks.
##
sub get_child_blocks
{
    my ($id, $data, $options) = @_;

    my $recursive = defined $options->{'recursive'} ?
                            $options->{'recursive'} : 0;

    my @blocks;
    $id = uc $id;
    for my $block ( @{$data->{'save_blocks'}} ) {
        my $block_id       = uc $block->{'values'}{'_definition.id'}[0];
        my $block_category = uc $block->{'values'}{'_name.category_id'}[0];
        my $block_scope    = get_definition_scope( $block );

        if ( $block_category eq $id ) {
            push @blocks, $block;
            if ( lc $block_scope eq 'category' && $recursive ) {
                push @blocks,
                     @{ get_child_blocks($block_id, $data, $options ) };
            }
        }
    }

    return \@blocks;
}

# TODO: rewrite as non-destructive?
sub merge_save_blocks
{
    my ($main_save_block, $auxilary_save_block) = @_;

    foreach my $key ( keys %{$auxilary_save_block->{'types'}} ) {
        $main_save_block->{'types'}{$key} = $auxilary_save_block->{'types'}{$key};
    }

    foreach my $key ( keys %{$auxilary_save_block->{'values'}} ) {
        $main_save_block->{'values'}{$key} = $auxilary_save_block->{'values'}{$key};
    }

    foreach my $key ( keys %{$auxilary_save_block->{'inloop'}} ) {
        $main_save_block->{'inloop'}{$key} =
            $auxilary_save_block->{'inloop'}{$key} +
            scalar @{$main_save_block->{'loops'}};
    }

    push @{$main_save_block->{'loops'}}, @{$auxilary_save_block->{'loops'}};
    push @{$main_save_block->{'tags'}}, @{$auxilary_save_block->{'tags'}};

    return $main_save_block;
}

##
# Determine the content type for the given data item as defined in a DDLm
# dictionary file. The "Implied" and "ByReference" content types are
# automatically resolved to more definitive content types.
#
# @param $data_name
#       The data name of the data item for which the content type should
#       be determined.
# @param $data_frame
#       CIF data frame (data block or save block) in which the data item
#       resides as returned by the COD::CIF::Parser.
# @param $dict
#       The data structure of the validation dictionary (as returned by the
#       'build_search_struct' data structure).
# @return
#       Content type for the given data item as defined in the provided DDLm.
##
sub get_type_contents
{
    my ($data_name, $data_frame, $dict) = @_;

    my $type_contents = $data_item_defaults{'_type.contents'};
    if ( exists $dict->{'Item'}{$data_name}{'values'}{'_type.contents'} ) {
        my $dict_item_frame = $dict->{'Item'}{$data_name};
        $type_contents = lc $dict_item_frame->{'values'}{'_type.contents'}[0];

        if ( $type_contents eq 'byreference' ) {
            $type_contents = resolve_content_type_references( $data_name, $dict );
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
            $type_contents = resolve_content_type_references( $data_name, $dict );
        }
    }

    return $type_contents;
}

sub resolve_content_type_references
{
    my ($data_name, $dict) = @_;

    my $type_contents = $data_item_defaults{'_type.contents'};
    if ( exists $dict->{'Item'}{$data_name}{'values'}{'_type.contents'} ) {
        my $dict_item_frame = $dict->{'Item'}{$data_name};
        $type_contents = lc $dict_item_frame->{'values'}{'_type.contents'}[0];

        if ( $type_contents eq 'byreference' ) {
            if ( exists $dict_item_frame->{'values'}
                                 {'_type.contents_referenced_id'} ) {
                my $ref_data_name = lc $dict_item_frame->{'values'}
                                        {'_type.contents_referenced_id'}[0];
                if ( exists $dict->{'Item'}{$ref_data_name} ) {
                    $type_contents =
                        resolve_content_type_references( $ref_data_name, $dict );
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

    return get_dict_item_value( $data_frame, '_type.container' );
}

sub get_type_purpose
{
    my ( $data_frame ) = @_;

    return lc get_dict_item_value( $data_frame, '_type.purpose' );
}

sub get_definition_class
{
    my ( $data_frame ) = @_;

    return get_dict_item_value( $data_frame, '_definition.class' );
}

sub get_definition_scope
{
    my ( $data_frame ) = @_;

    return get_dict_item_value( $data_frame, '_definition.scope' );
}

sub get_dict_item_value
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
sub build_search_struct
{
    my ($data) = @_;

    my %categories;
    my %items;
    my %tags;
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
        'Tags'       => \%tags,
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
# Converts (in a rather crude way) CIF data blocks of DDL dictionaries
# to DDLm in order to represent them using the same code. This method
# should not be used to translate DDL to DDLm for other purposes as it
# is largely based on guesswork and works satisfactory only for the
# purpose of this script.
##
sub ddl2ddlm
{
    my( $ddl_datablocks, $options ) = @_;

    $options = {} unless $options;
    my( $keep_original_date, $new_version ) = (
        $options->{keep_original_date},
        $options->{new_version},
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
        $date = $ddl_datablocks->[0]{values}{_dictionary_update}[0];
    } else {
        $date = strftime( '%F', gmtime() );
    }

    my $ddlm_datablock = new_datablock( $ddl_datablocks->[0]{values}
                                                         {_dictionary_name}[0],
                                        '2.0' );

    my $head = new_datablock( $category_overview, '2.0' );
    set_tag( $head, '_definition.id', uc $category_overview );
    set_tag( $head, '_definition.class', 'Head' );
    set_tag( $head, '_definition.scope', 'Category' );
    push @{$ddlm_datablock->{save_blocks}}, $head;

    for my $datablock (@$ddl_datablocks) {
        next if $datablock->{name} eq 'on_this_dictionary';

        for my $name (@{$datablock->{values}{_name}}) {
            my $ddl_datablock = clone( $datablock );
            $ddl_datablock->{name} = $name;
            $ddl_datablock->{name} =~ s/^_//;
            $ddl_datablock->{name} =~ s/_\[\]$//;

            set_tag( $ddl_datablock, '_definition.update', $date );

            if( exists $ddl_datablock->{values}{_category} &&
                $ddl_datablock->{values}{_category}[0] eq $category_overview ) {
                $name =~ s/^_//;
                $name =~ s/_\[\]$//;

                my @tags = grep { exists $_->{values}{_category} &&
                                  $_->{values}{_category}[0] eq $name }
                                @$ddl_datablocks;
                my @loop_tags = grep { exists $_->{values}{_list} &&
                                       $_->{values}{_list}[0] eq 'yes' }
                                     @tags;

                # Uppercasing category names to make them stand out:
                $name = uc $name;
                set_tag( $ddl_datablock,
                         '_definition.class',
                         @tags && @tags == @loop_tags ? 'Loop' : 'Set' );
                set_tag( $ddl_datablock, '_definition.scope', 'Category' );
            } else {
                set_tag( $ddl_datablock, '_definition.class', 'Datum' );
                set_tag( $ddl_datablock, '_type.container', 'Single' );

                my $type_purpose;

                if( $ddl_datablock->{values}{_type} ) {
                    set_tag( $ddl_datablock,
                             '_type.contents',
                             $typemap{$ddl_datablock->{values}{_type}[0]} );
                    if( $ddl_datablock->{values}{_type}[0] eq 'numb' &&
                        exists $ddl_datablock->{values}{_type_conditions} &&
                        $ddl_datablock->{values}{_type_conditions}[0] =~ /^esd|su$/ ) {
                        $type_purpose = 'Measurand';
                    }
                }

                if( exists $ddl_datablock->{values}{_enumeration} ) {
                    $type_purpose = 'State';
                }

                if( $type_purpose ) {
                    set_tag( $ddl_datablock,
                             '_type.purpose',
                             $type_purpose );
                }
            }

            if(  exists $ddl_datablock->{values}{_units} &&
                !exists $ddl_datablock->{values}{_units_detail} ) {
                warn "'_units_detail' is not defined for '$ddl_datablock->{name}'";
            }

            for my $tag (sort keys %tags_to_rename) {
                next if !exists $ddl_datablock->{values}{$tag};

                $ddl_datablock->{values}{$tag} =
                    [ map { cif2unicode( $_ ) }
                          @{$ddl_datablock->{values}{$tag}} ];

                rename_tag( $ddl_datablock,
                            $tag,
                            $tags_to_rename{$tag} );
            }

            for my $tag (@tags_to_exclude) {
                next if !exists $ddl_datablock->{values}{$tag};
                exclude_tag( $ddl_datablock, $tag );
            }

            if( exists $ddl_datablock->{values}{'_units.code'} ) {
                $ddl_datablock->{values}{'_units.code'}[0] =~ s/ /_/g;
                $ddl_datablock->{values}{'_units.code'}[0] =
                    lc $ddl_datablock->{values}{'_units.code'}[0];
                $ddl_datablock->{values}{'_units.code'}[0] =~
                    s/angstroem/angstrom/g;
                $ddl_datablock->{values}{'_units.code'}[0] =~
                    s/electron-volt/electron_volt/g;
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

    set_tag( $ddlm_datablock,
             '_dictionary.title',
             $ddl_datablocks->[0]{values}{_dictionary_name}[0] );
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

    while( my( $i, $loop ) = each @{$dataset->{loops}}) {
        my $description = new_datablock( "loop_$i", '2.0' );

        set_tag( $description, '_definition.id', "loop_$i" );
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
                    ? 'loop_' . $dataset->{inloop}{$tag}
                    : 'PRELIMINARY_GROUP' );

        push @{$ddlm->{save_blocks}}, $description;
    }

    return $ddlm;
}

1;
