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
use COD::CIF::Parser qw( parse_cif );
use COD::ErrorHandler qw( process_parser_messages
                          report_message );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    build_search_struct
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

##
# Recursively locates and parses imported DDLm files.
#
# @param $dic_block
#       Reference to a DDLm dictionary data block as returned by
#       the COD::CIF::Parser.
# @param $options
#       Reference to an option hash. The following options are recognised:
#       {
#         'file_path' => [ './', '/dir/subdir/subsubdir/' ],
#             # Reference to an array of directory path where
#             # the imported files can potentially reside
#         'importing_file' => './file_dir/file.dic',
#             # Filename of the file that contained the dictionary
#             # data block. Used mainly for error-reporting
#         'parser_options' => {},
#             # Reference to an option hash that will be
#             # passed to the CIF parser
#         'die_on_error_level' => {
#               'ERROR'   => 1,
#               'WARNING' => 0,
#               'NOTE'    => 1,
#         }
#             # Reference to a hash that species which error
#             # level are fatal and which are not
#       }
# @param $imported_data
#       Reference to a data structure that contains parsed data of
#       the imported files:
#       {
#         $imported_file_1 => {
#           'file_data' => { }
#               # Reference to a DDLm dictionary data block
#               # as returned by the COD::CIF::Parser
#           'parser_messages' => { }
#               # Reference to error messages generated during the
#               # parsing of the file as returned by the COD::CIF::Parser
#           'provenance' => {
#               # Reference to a data structure that records provenance
#               # information mainly used in error reporting
#               'file_location'   => '/path/imported_file.dic'
#                   # Path to the file that was recognised as the imported one
#                   # If the file could not be located in the given path,
#                   # value of this field is set to undef
#               'importing_file'  => '/path/importing_file.dic'
#                   # Path to the file that contained the import statement
#               'importing_block' => 'block_name'
#                   # Name of the data block that contained the import statement
#               'importing_frame' =>
#                   # Name of the save frame that contained the import statement
#           }
#         }
#       }
##
sub get_imported_files
{
    my ( $dic_block, $options ) = @_;

    my $file_path          = $options->{'file_path'};
    my $parser_options     = $options->{'parser_options'};
    my $die_on_error_level = $options->{'die_on_error_level'};
    my $importing_file     = $options->{'importing_file'};

    my $imported_data = resolve_import_dependencies(
        {
            'container_file' => $dic_block,
            'file_path'      => $file_path,
            'imported_files' => {},
            'parser_options' => $parser_options,
            'provenance' => {
                'importing_file'  => $importing_file,
                'importing_block' => $dic_block->{'name'},
            }
        }
    );

    for my $imported_file_name ( sort keys %{$imported_data} ) {
        my $file_import = $imported_data->{$imported_file_name};
        my $import_provenance = $file_import->{'provenance'};
        my $add_pos;
        if ( defined $import_provenance->{'importing_block'} ) {
            $add_pos = 'data_' . $import_provenance->{'importing_block'};
            if ( defined $import_provenance->{'importing_frame'} ) {
                $add_pos = 'save_' . $import_provenance->{'importing_frame'};
            }
        }
        if ( !defined $file_import->{'provenance'}{'file_location'} ) {
            report_message( {
               'message'  =>
                    "the '$imported_file_name' file could not be located " .
                    'in the given path -- file will not be imported',
               'program'  => $0,
               'filename' => $file_import->{'provenance'}{'importing_file'},
               'add_pos'  => $add_pos,
            }, $die_on_error_level->{'WARNING'} );
        } else {
            process_parser_messages( $file_import->{'parser_messages'},
                                     $die_on_error_level );
        }
    }

    return $imported_data;
}

#
# TODO: consider a more conservative dictionary import system
#
# dictionary = {
#   'file_path'       => [ 'dir1', 'dir2', 'dir3' ]
#   'container_file' =>
#   'imported_files'  =>
#   'parser_options'  =>
# }
sub resolve_import_dependencies
{
    my ($params) = @_;
    my $file_path      = $params->{'file_path'};
    my $container_file = $params->{'container_file'};
    my %imported_files = %{$params->{'imported_files'}};
    my $parser_options = $params->{'parser_options'};
    my $provenance     = $params->{'provenance'};

    for my $saveblock ( @{$container_file->{'save_blocks'}} ) {
        next if !exists $saveblock->{'values'}{'_import.get'};
        next if !exists $saveblock->{'values'}{'_import.get'}[0];
        for my $import_details ( @{$saveblock->{'values'}{'_import.get'}[0]} ) {
            my $filename = $import_details->{'file'};
            next if exists $imported_files{$filename};
            my $file_location = find_file_in_path( $filename, $file_path );
            if ( defined $file_location ) {
                my ( $import_data, $err_count, $messages ) =
                            parse_cif( $file_location, $parser_options );
                $imported_files{$filename}{'file_data'} = $import_data->[0];
                $imported_files{$filename}{'parser_messages'} = $messages;
                $imported_files{$filename}{'provenance'} = {
                    'file_location'   => $file_location,
                    'importing_file'  => $provenance->{'importing_file'},
                    'importing_block' => $provenance->{'importing_block'},
                    'importing_frame' => $saveblock->{'name'},
                };

                my $single_import = resolve_import_dependencies( {
                    'file_path'         => $file_path,
                    'container_file'    => $import_data->[0],
                    'imported_files'    => \%imported_files,
                    'parser_options'    => $parser_options,
                    'provenance' => {
                        'importing_file'  => $file_location,
                        'importing_block' => $import_data->[0]{'name'},
                        'importing_frame' => $saveblock->{'name'},
                    },
                } );
                %imported_files = %{$single_import};
            } else {
                $imported_files{$filename}{'provenance'} = {
                    'file_location'   => undef,
                    'importing_file'  => $provenance->{'importing_file'},
                    'importing_block' => $provenance->{'importing_block'},
                    'importing_frame' => $saveblock->{'name'},
                };
            }
        }
    }

    return \%imported_files;
}

##
# Finds the first occurence of a file in the given path.
#
# @param $filename
#       Name of the file.
# @param $file_path
#       Reference to an array of directory path where the file
#       can potentially reside.
# @return
#       Full path to the file in case it is found, undef value otherwise.
##
sub find_file_in_path
{
    my ( $filename, $file_path ) = @_;

    my $file_location;
    for my $path ( @{$file_path} ) {
        $path =~ s/[\/]+$//;
        if ( -f "$path/$filename" ) {
            $file_location = "$path/$filename";
            last;
        }
    }

    return $file_location;
}

# TODO: check for cyclic relationships
sub merge_imported_files
{
    my ($dic, $imported_files) = @_;

    for my $saveblock ( @{$dic->{'save_blocks'}} ) {
        next if !exists $saveblock->{'values'}{'_import.get'};
        next if !exists $saveblock->{'values'}{'_import.get'}[0];

        for my $import ( @{$saveblock->{'values'}{'_import.get'}[0]} ) {
            my $filename = $import->{'file'};
            next if !exists $imported_files->{$filename};
            next if !exists $imported_files->{$filename}{'file_data'};
            my $imported_file = $imported_files->{$filename}{'file_data'};

            $imported_file = merge_imported_files($imported_file, $imported_files);
            my $target_saveblock = $import->{'save'};
            for my $imported_saveblock ( @{$imported_file->{'save_blocks'}} ) {
              if ( lc $imported_saveblock->{'name'} eq lc $target_saveblock ) {
                if ( lc get_definition_scope( $imported_saveblock ) eq 'category' ) {
                    my $imports = get_category_imports($saveblock, $imported_file, $import );
                    push @{$dic->{'save_blocks'}}, @{$imports};
                } else {
                    $saveblock = merge_save_blocks($saveblock, $imported_saveblock);
                }
              }
            }
        }
    }

    return $dic;
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

1;
