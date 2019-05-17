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
use COD::ErrorHandler qw( process_parser_messages
                          report_message );
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
        my $add_pos = sprint_add_pos_from_provenance( $import_provenance );
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

sub sprint_add_pos_from_provenance
{
    my ( $import_provenance ) = @_;

    my $add_pos;
    if ( defined $import_provenance->{'importing_block'} ) {
        $add_pos = 'data_' . $import_provenance->{'importing_block'};
        if ( defined $import_provenance->{'importing_frame'} ) {
            $add_pos = 'save_' . $import_provenance->{'importing_frame'};
        }
    }

    return $add_pos;
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
        my $import_statements = get_import_details( $saveblock );
        for my $import_details ( @{$import_statements} ) {
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
# Finds the first occurrence of a file in the given path.
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
    my ( $parent_dic, $imported_files, $die_on_error_level ) = @_;

    for my $parent_frame ( @{$parent_dic->{'save_blocks'}} ) {
        my $import_statements = get_import_details( $parent_frame );
        next if !$import_statements;

        for my $import_details ( @{$import_statements} ) {
            my $filename = $import_details->{'file'};
            next if !exists $imported_files->{$filename};
            next if !exists $imported_files->{$filename}{'file_data'};
            my $imported_file = $imported_files->{$filename}{'file_data'};
            $imported_file = merge_imported_files(
                                $imported_file,
                                $imported_files,
                                $die_on_error_level
                            );

            my $import_frame = get_imported_frame(
                                    $imported_files->{$filename},
                                    $import_details,
                                    $die_on_error_level
                               );
            next if !defined $import_frame;

            my $import_warnings = check_import_eligibility(
                                        $parent_frame,
                                        $import_frame,
                                        $import_details
                                   );
            my $file_provenance = $imported_files->{$filename}{'provenance'};
            for my $warning ( @{$import_warnings} ) {
                report_message( {
                   'message'  => $warning,
                   'program'  => $0,
                   'filename' => $file_provenance->{'importing_file'},
                   'add_pos'  => sprint_add_pos_from_provenance( $file_provenance ),
                }, $die_on_error_level->{'WARNING'} );
            };
            next if @{$import_warnings};

            my $import_mode = get_import_mode( $import_details );
            if ( $import_mode eq 'Contents' ) {
                merge_save_blocks( $parent_frame, $import_frame );
            } elsif ( $import_mode eq 'Full' ) {
                if ( lc get_definition_scope( $import_frame ) eq 'category' ) {
                    $parent_dic = import_full_category(
                                    $parent_dic,
                                    $parent_frame,
                                    $imported_file,
                                    $import_details
                                );
                } else {
                    $parent_dic = import_full_item(
                                    $parent_dic,
                                    $parent_frame,
                                    $import_frame,
                                    $import_details
                                );
                }
            } else {
                warn "the '$import_mode' import mode is currently not " .
                     'supported' . "\n";
            }
        }
    }

    return $parent_dic;
}

sub get_import_details
{
    my ( $save_frame ) = @_;

    return if !defined $save_frame->{'values'}{'_import.get'};

    return $save_frame->{'values'}{'_import.get'}[0];
}

sub check_import_eligibility
{
    my ( $parent_frame, $import_frame, $import_details ) = @_;

    my $parent_scope = get_definition_scope( $parent_frame );
    my $parent_class = get_definition_class( $parent_frame );
    my $import_scope = get_definition_scope( $import_frame );
    my $import_class = get_definition_class( $import_frame );
    my $import_mode  = get_import_mode( $import_details );

    my @messages;
    if ( $parent_scope ne 'Category' &&
         $import_scope eq 'Category' ) {
        push @messages,
            "WARNING, a non-category frame '$parent_frame->{'name'}' is not " .
            "permitted to import the '$import_details->{'save'}' category " .
            'frame' . "\n";
    }
    
    if ( $parent_scope eq 'Item' &&
         $import_mode eq 'Full' ) {
        push @messages,
            "WARNING, a non-category definition frame " .
            "'$parent_frame->{'name'}' is not permitted to import data " .
            "definitions in 'Full' mode";
    };

    if ( $import_class eq 'Head' &&
         $import_mode  eq 'Full' &&
         $parent_class ne 'Head' ) {
        push @messages,
            "WARNING, a non-HEAD category '$parent_frame->{'name'}' " .
            "is not permitted to import the '$import_frame->{'name'}' " .
            "HEAD category in 'Full' mode";
    }

    return \@messages;
}

sub get_save_frame_by_name
{
    my ( $data_block, $frame_name ) = @_;

    my @save_frames;
    for my $save_frame ( @{$data_block->{'save_blocks'}} ) {
        if ( lc $save_frame->{'name'} eq lc $frame_name ) {
            push @save_frames, $save_frame;
        }
    }

    return \@save_frames;
}

sub get_imported_frame
{
    my  ( $imported_file, $import_details, $die_on_error_level ) = @_;

    my @imported_frames;
    my $imported_frame_name = $import_details->{'save'};
    my $import_data = $imported_file->{'file_data'}; 
    my $provenance =  $imported_file->{'provenance'}; 

    my $imported_frames = get_save_frame_by_name(
                                        $import_data,
                                        $imported_frame_name
                        );

    my $import_frame;
    if ( !@{$imported_frames} ) {
        report_message( {
           'message'  => 
                "the '$imported_frame_name' save frame from the " .
                "'$import_details->{'file'}' file is referenced in a " .
                'dictionary import statement, but could not be ' .
                "located in the '$provenance->{'file_location'}' file",
           'program'  => $0,
           'filename' => $provenance->{'importing_file'},
           'add_pos'  => sprint_add_pos_from_provenance( $provenance ),
        }, $die_on_error_level->{'WARNING'} );
    } else {
        $import_frame = $imported_frames->[0];
        if ( @{$imported_frames} > 2 ) {
            report_message( {
               'message'  => 
                    "more than one '$import_details->{'save'}' save frame " .
                    "was located in the '$provenance->{'file_location'}' " .
                    "file -- only the first save frame will be imported",
               'program'  => $0,
               'filename' => $provenance->{'importing_file'},
               'add_pos'  => sprint_add_pos_from_provenance( $provenance ),
            }, $die_on_error_level->{'WARNING'} );
        }
    }

    return $import_frame;
}

sub import_full_category
{
    my ( $parent_dic, $parent_frame, $import_file, $import_details ) = @_;

    my $parent_scope = get_definition_scope( $parent_frame );

    my $imports = get_category_imports( $parent_frame, $import_file, $import_details );
    push @{$parent_dic->{'save_blocks'}}, @{$imports};

    return $parent_dic;
}

sub import_full_item
{
    my ( $parent_dic, $parent_frame, $import_frame, $import_details ) = @_;

    set_category_id( $import_frame, get_data_name( $parent_frame ) );
    push @{$parent_dic->{'save_blocks'}}, $import_frame;

    return $parent_dic;
}

sub get_import_mode
{
    my ( $import_details ) = @_;

    if ( !defined $import_details->{'mode'} ) {
        return $import_defaults{'mode'};
    }

    return $import_details->{'mode'};
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
#  case, a 'Head' category importing a 'Head' category is equivalent to
#  importing all children of the imported 'Head' category as children of
#  the importing 'Head' category.
#
# @param $parent_frame
#       Category save frame that contains the import statement as returned
#       by the COD::CIF::Parser.
# @param $import_data
#       CIF data block of the imported CIF dictionary file as returned
#       by the COD::CIF::Parser.
# @param $import_details
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
    my ( $parent_frame, $import_data, $import_details ) = @_;

    my $import_block;
    my $import_frame_name = uc $import_details->{'save'};
    for my $frame ( @{$import_data->{'save_blocks'}} ) {
        if ( uc $frame->{'name'} eq $import_frame_name ) {
            $import_block = $frame;
            last;
        }
    }

    my $import_block_id = get_data_name( $import_block );
    my $imported_frames = get_child_blocks(
        $import_block_id,
        $import_data,
        { 'recursive' => '1' }
    );

    # Head category importing a head category is a special case
    my $head_in_head = get_definition_class( $parent_frame ) eq 'Head' &&
                       get_definition_class( $import_block ) eq 'Head';
    my $parent_block_id = get_data_name( $parent_frame );
    if ( $head_in_head ) {
        for my $frame ( @{$imported_frames} ) {
            if ( uc get_category_id( $frame ) eq $import_block_id ) {
                set_category_id( $frame, $parent_block_id );
            }
        }
    } else {
        set_category_id( $import_block, $parent_block_id );
        push @{$imported_frames}, $import_block;
    }

    return $imported_frames;
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
        my $block_id       = uc get_data_name( $block );
        my $block_category = uc get_category_id( $block );
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
    my ($main_save_block, $sub_save_block) = @_;

    for my $key ( keys %{$sub_save_block->{'types'}} ) {
        $main_save_block->{'types'}{$key} = $sub_save_block->{'types'}{$key};
    }

    for my $key ( keys %{$sub_save_block->{'values'}} ) {
        $main_save_block->{'values'}{$key} = $sub_save_block->{'values'}{$key};
    }

    for my $key ( keys %{$sub_save_block->{'inloop'}} ) {
        $main_save_block->{'inloop'}{$key} =
            $sub_save_block->{'inloop'}{$key} +
            scalar @{$main_save_block->{'loops'}};
    }

    push @{$main_save_block->{'loops'}}, @{$sub_save_block->{'loops'}};
    push @{$main_save_block->{'tags'}},  @{$sub_save_block->{'tags'}};

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
# should not be used to translate DDL1 to DDLm for other purposes as it
# is largely based on guesswork and works satisfactory only for the
# purpose of this script.
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
        $date = $ddl_datablocks->[0]{values}{_dictionary_update}[0];
    } else {
        $date = strftime( '%F', gmtime() );
    }

    my $dictionary_name =
        dic_filename_to_title( $ddl_datablocks->[0]{values}{_dictionary_name}[0] );

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
                warn "'_units_detail' is not defined for '$ddl_datablock->{name}'\n";
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

1;
