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
use List::MoreUtils qw( any uniq );
use Scalar::Util qw( looks_like_number );
use URI::Split qw( uri_split );

use COD::CIF::ChangeLog qw( summarise_messages );
use COD::CIF::DDL::Ranges qw( parse_range
                              range_to_string
                              is_in_range );
use COD::CIF::DDL::Validate qw( check_enumeration_set );
use COD::CIF::Parser qw( parse_cif );
use COD::CIF::Tags::Print qw( pack_precision );
use COD::CIF::Tags::Manage qw( get_item_loop_index
                               has_special_value
                               has_numeric_value );
use COD::DateTime qw( parse_date parse_datetime canonicalise_timestamp );
use COD::ErrorHandler qw( process_parser_messages
                          report_message );
use COD::Precision qw( unpack_cif_number );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    build_search_struct
    get_category_id
    get_data_alias
    get_data_name
    get_ddlm_import_path_from_env
    get_definition_class
    get_definition_scope
    get_imported_files
    get_type_contents
    get_type_container
    get_type_purpose
    merge_imported_files
    merge_save_blocks
    is_looped_category
    ddlm_validate_data_block
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

my $DDLM_IMPORT_PATH_ENV_VARIABLE = 'COD_TOOLS_DDLM_IMPORT_PATH';

##
# Produces a list of directory paths where the imported DDLm-compliant
# CIF dictionary files should be searched for by parsing the
# COD_TOOLS_DDLM_IMPORT_PATH environment variable.
#
# @return \@env_dic_import_path
#       Reference to an array of directory paths.
##
sub get_ddlm_import_path_from_env
{
    return [] if !exists $ENV{$DDLM_IMPORT_PATH_ENV_VARIABLE};

    my @env_dic_import_path = split ':', $ENV{$DDLM_IMPORT_PATH_ENV_VARIABLE};

    return \@env_dic_import_path;
}

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
#             # Reference to an array of directory paths where
#             # the imported files should be searched for
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
#       Reference to an array of directory paths where
#       the file should be searched for.
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
#       Data name of the data item for which the content type should
#       be determined.
# @param $data_frame
#       CIF data frame (data block or save block) in which the data item
#       resides as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of the validation dictionary (as returned by the
#       'build_search_struct' data structure).
# @return
#       Content type for the given data item as defined in the provided DDLm.
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

# BEGIN: subroutines focused on data validation

##
# Validates a data block against a DDLm-conformant dictionary.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of the validation dictionary as returned by the
#       COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @param $options
#       Reference to a hash of options. The following options are recognised:
#       {
#       # Report data items that have been replaced by other data items
#           'report_deprecated' => 0,
#       # Ignore the case while matching enumerators
#           'ignore_case'       => 0,
#       # Array reference to a list of data items that should be
#       # treated as potentially having values consisting of a
#       # combination of several enumeration values. Data items
#       # are identified by data names
#           'enum_as_set_tags'  => [ '_atom_site.refinement_flags',
#                                    '_atom_site.refinement_flags', ],
#       # Report missing mandatory s.u. values
#           'report_missing_su' => 0,
#       # Maximum number of validation issues that are reported for
#       # each unique combination of validation criteria and validated
#       # data items. Negative values remove the limit altogether
#           'max_issue_count'   => -1
#       }
# @return
#       Array reference to a list of validation issue data structures
#       of the following form:
#       {
#       # Code of the data block that caused the validation issue
#           'data_block_code' => 'issue_block_code',
#       # Code of the save frame that caused the validation issue
#       # Might be undefined
#           'save_frame_code' => 'issue_frame_code',
#       # Code of the validation test that raised the issue
#           'test_type' => 'TEST_TYPE_CODE',
#       # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#       # Human-readable description of the issue
#           'message'         => 'description of the issue'
#       }
##
sub ddlm_validate_data_block
{
    my ( $data_block, $dic, $options ) = @_;

    my $max_issue_count   = exists $options->{'max_issue_count'} ?
                                   $options->{'max_issue_count'} : -1;

    my @issues;
    # NOTE: the DDLm dictionary contains a special data structure that
    # defines which data items are mandatory, recommended and forbidden
    # in certain dictionary scopes (Dictionary, Category, Item)
    my $application_scope = extract_application_scope( $dic );
    if ( defined $application_scope ) {
        push @issues,
             @{validate_application_scope( $data_block, $application_scope )};
    }

    my $data_name = $data_block->{'name'};
    my $data_block_issues = validate_data_frame( $data_block, $dic, $options );
    for my $issue ( @{ summarise_validation_issues( $data_block_issues ) } ) {
        $issue->{'data_block_code'} = $data_name;
        push @issues, $issue;
     }

    # DDLm dictionaries contain save frames
    for my $save_frame ( @{ $data_block->{'save_blocks'} } ) {
        my $save_frame_issues = validate_data_frame( $save_frame, $dic, $options );
        for my $issue ( @{ summarise_validation_issues( $save_frame_issues ) } ) {
            $issue->{'data_block_code'} = $data_name;
            $issue->{'save_frame_code'} = $save_frame->{'name'};
            push @issues, $issue;
        }
    }

    if ($max_issue_count > -1) {
        @issues = limit_validation_issues(\@issues, $max_issue_count)
    }

    return \@issues;
}

##
# Groups validation issues with identical messages together and replaces
# each group with a single validation issue that contains a summarized
# version of the message.
#
# @param $issues
#       Array reference to a list of validation message data structures
#       of the following form:
#       {
#       # Code of the data block that caused the validation issue
#           'data_block_code' => 'issue_block_code',
#       # Code of the save frame that caused the validation issue
#       # Might be undefined
#           'save_frame_code' => 'issue_frame_code',
#       # Code of the validation test that raised the issue
#           'test_type' => 'TEST_TYPE_CODE',
#       # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#       # Human-readable description of the issue
#           'message'         => 'description of the issue'
#       }
#
# @return $summarised_issues
#       Reference to an array of unique summarised issues.
##
sub summarise_validation_issues
{
    my ($issues) = @_;

    my %message_count;
    for my $issue (@{$issues}) {
        $message_count{$issue->{'message'}}{'count'}++;
        $message_count{$issue->{'message'}}{'representative_issue'} = $issue;
    }

    my @summarised_issues;
    for my $message ( sort keys %message_count ) {
        my $count = $message_count{$message}->{'count'};
        my $issue = $message_count{$message}->{'representative_issue'};
        if( $count > 1 ) {
            $issue->{'message'} = $message . " ($count times)";
        }
        push @summarised_issues, $issue;
    }

    return \@summarised_issues;
}

sub limit_validation_issues
{
    my ($issues, $max_issue_count) = @_;

    my %grouped_issues;
    for my $issue ( @{$issues} ) {
        my $constraint = $issue->{'test_type'};
        my $data_name_key = join "\x{001E}", @{$issue->{'data_items'}};
        push @{$grouped_issues{$constraint}{$data_name_key}}, $issue;
    }

    # TODO: move hash out of the subroutine
    my %test_types = (
        'STANDARD_UNCERTAINTY.FORBIDDEN' =>
            'eligibility to have associated standard uncertainty values',
        'STANDARD_UNCERTAINTY.VALUE_MISMATCH' =>
            'compatability between standard uncertainty values expressed' .
            'as a separate data item and those expressed using the concise ' .
            'notation',
        'STANDARD_UNCERTAINTY.MANDATORY' =>
            'requirement to have associated standard uncertainty values',
        'DIFFERING_ALIAS_VALUES' =>
            'identity between the values of aliased data items',
        'PRESENCE_OF_LINKED_DATA_ITEM_VALUE' =>
            'mandatory presence of a linked data item value',
        'PRESENCE_OF_LINKED_DATA_ITEM' =>
            'mandatory presence of a linked data item',
        'CONTENT_TYPE.MANDATORY_LIST_STRUCTURE' =>
            'of data values appearing in a \'LIST\' data structure',
        'CONTENT_TYPE.LIST_SIZE_CONSTRAINT' =>
            'data values appearing in a \'LIST\' data structure ' .
            'of the correct size',
        'TYPE_CONSTRAINT.QUOTED_NUMERIC_VALUES' =>
            'proper quote usage with numeric values',
        'TYPE_CONSTRAINT.TEXT_TYPE_FORBIDDEN_CHARACTER' =>
            'data value of the \'TEXT\' type not having forbidden characters',
        'TYPE_CONSTRAINT.CODE_TYPE_FORBIDDEN_CHARACTER' =>
            'data value of the \'CODE\' type not having forbidden characters',
        'TYPE_CONSTRAINT.NAME_TYPE_FORBIDDEN_CHARACTER' =>
            'data value of the \'NAME\' type not having forbidden characters',
        'TYPE_CONSTRAINT.TAG_TYPE_START_CHARACTER' =>
            'data value of the \'TAG\' type having the correct prefix',
        'TYPE_CONSTRAINT.TAG_TYPE_START_CHARACTER' =>
            'data value of the \'TAG\' type not having forbidden characters',
        'TYPE_CONSTRAINT.URI_TYPE_START_CHARACTER' =>
            'data value of the \'URI\' type having the correct prefix',
        'TYPE_CONSTRAINT.URI_TYPE_FORBIDDEN_CHARACTER' =>
            'data value of the \'URI\' type not having forbidden characters',
        'TYPE_CONSTRAINT.URI_TYPE_SCHEME_PREFIX',
            'data value of the \'URI\' type having a scheme prefix',
        'TYPE_CONSTRAINT.DATE_TYPE_FORMAT' =>
            'data value conformance to the \'DATE\' type',
        'TYPE_CONSTRAINT.DATETIME_TYPE_FORMAT' =>
            'data value conformance to the \'DATETIME\' type',
        'TYPE_CONSTRAINT.VERSION_TYPE_FORMAT' =>
            'data value conformance to the \'VERSION\' type',
        'TYPE_CONSTRAINT.DIMENSION_TYPE_FORMAT' =>
            'data value conformance to the \'DIMENSION\' type',
        'TYPE_CONSTRAINT.RANGE_TYPE_FORMAT' =>
            'data value conformance to the \'RANGE\' type',
        'TYPE_CONSTRAINT.RANGE_TYPE_LOWER_GT_UPPER' =>
            'data value of the \'RANGE\' type having a lower bound that is ' .
            'greater than the upper bound',
        'TYPE_CONSTRAINT.COUNT_TYPE_CONSTRAINT' =>
            'data value conformance to the \'COUNT\' type',
        'TYPE_CONSTRAINT.INDEX_TYPE_CONSTRAINT' =>
            'data value conformance to the \'INDEX\' type',
        'TYPE_CONSTRAINT.INTEGER_TYPE_CONSTRAINT' =>
            'data value conformance to the \'INTEGER\' type',
        'TYPE_CONSTRAINT.REAL_TYPE_CONSTRAINT' =>
            'data value conformance to the \'REAL\' type',
        'TYPE_CONSTRAINT.IMAG_TYPE_FORMAT' =>
            'data value conformance to the \'IMAG\' type',
        'TYPE_CONSTRAINT.COMPLEX_TYPE_FORMAT' =>
            'data value conformance to the \'COMPLEX\' type',
        'TYPE_CONSTRAINT.SYMOP_TYPE_FORMAT' =>
            'data value conformance to the \'SYMOP\' type',
        'TYPE_CONTAINER.TOP_LEVEL_MATRIX' =>
            'data values having a top level \'MATRIX\' container',
        'TYPE_CONTAINER.TOP_LEVEL_LIST' =>
            'data values having a top level \'LIST\' container',
        'TYPE_CONTAINER.TOP_LEVEL_TABLE' =>
            'data values having a top level \'TABLE\' container',
        'TYPE_CONTAINER.NO_TOP_LEVEL' =>
            'data values having no top level container',
        'TYPE_CONTAINER.MATRIX_ROW_COUNT' =>
            'data value being a matrix with the correct row count',
        'TYPE_CONTAINER.MATRIX_ROW_LENGTH' =>
            'data value being a matrix with the correct row length',
        'TYPE_CONTAINER.MISMATCHING_MATRIX_ROW_LENGTHS' =>
            'data value being a matrix with rows of the same length',
        'ENUMERATION_SET' =>
            'data value belonging to the specified enumeration set',
        'LOOP_CONTEXT.MUST_NOT_APPEAR_IN_LOOP' =>
            'data items that incorrectly appear inside of a looped list',
        'CATEGORY_INTEGRITY' =>
            'category integrity',
        'KEY_ITEM_PRESENCE' =>
            'mandatory key item presence',
        'SIMPLE_KEY_UNIQUNESS'    =>
            'simple loop key uniqueness',
        'COMPOSITE_KEY_UNIQUNESS' =>
            'composite loop key uniqueness',
        'PRESENCE_OF_DEPRECATED_ITEM' =>
            'presence of a deprecated data item',
        'ENUM_RANGE.IN_RANGE' =>
            'data value belonging to the specified value range',
        'SCOPE.PROHIBITED' =>
            'data item appearing in a definition prohibited scope',
        'SCOPE.MANDATORY' =>
            'data item not appearing in a mandatory definition scope',
        'SCOPE.RECOMMENDED' =>
            'data item not appearing in a recommended definition scope',
        'ISSUE_COUNT_LIMIT_EXCEEDED' =>
            'the number of issues of the same test type exceeding ' .
            'the maximum issue count'
    );

    my @limited_issues;
    for my $constraint (sort keys %grouped_issues) {
        for my $data_name_key (sort keys %{$grouped_issues{$constraint}}) {
            my @group_issues = @{$grouped_issues{$constraint}{$data_name_key}};
            my $group_size = scalar(@group_issues);

            my $description;
            if ( defined $test_types{$constraint} ) {
                $description = $test_types{$constraint};
            }

            if ( $group_size > $max_issue_count ) {
                my $limit_exceeded_issue = {
                    'test_type'  => 'ISSUE_COUNT_LIMIT_EXCEEDED',
                    'data_items' => $group_issues[0]->{'data_items'},
                    'message'    => 
                        'a test ' .
                        (defined $description ? "of $description " : '') .
                        'involving the [' .
                        ( join ', ', map {"'$_'"} @{$group_issues[0]->{'data_items'}} ) .
                        "] data items resulted in $group_size validation messages " .
                        '-- the number of reported messages is limited to ' .
                        "$max_issue_count"
                };
                
                for my $property ('data_block_code', 'save_frame_code') {
                    next if !defined $group_issues[0]->{$property};
                    $limit_exceeded_issue->{$property} =
                                            $group_issues[0]->{$property};
                }

                push @limited_issues, $limit_exceeded_issue;
                $group_size = $max_issue_count;
            }

            push @limited_issues, @group_issues[0..($group_size - 1)];
        }
    }

    return @limited_issues;
}

##
# Validates a data block against a DDLm-conformant dictionary.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of the validation dictionary as returned by the
#       COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @param $options
#       Reference to a hash of options. The following options are recognised:
#       {
#       # Report data items that have been replaced by other data items
#           'report_deprecated' => 0,
#       # Ignore the case while matching enumerators
#           'ignore_case'       => 0,
#       # Array reference to a list of data items that should be
#       # treated as potentially having values consisting of a
#       # combination of several enumeration values. Data items
#       # are identified by data names
#           'enum_as_set_tags'  => [ '_atom_site.refinement_flags',
#                                    '_atom_site.refinement_flags', ],
#       # Report missing mandatory s.u. values
#           'report_missing_su' => 0
#       }
# @return
#       Array reference to a list of validation issue data structures
#       of the following form:
#       {
#       # Code of the data block that caused the validation issue
#           'data_block_code' => 'issue_block_code',
#       # Code of the save frame that caused the validation issue
#       # Might be undefined
#           'save_frame_code' => 'issue_frame_code',
#       # Code of the validation test that raised the issue
#           'test_type' => 'TEST_TYPE_CODE',
#       # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#       # Human-readable description of the issue
#           'message'         => 'description of the issue'
#       }
##
sub validate_data_frame
{
    my ($data_frame, $dic, $options) = @_;

    my @issues;
    push @issues, @{validate_type_contents($data_frame, $dic)};
    push @issues, @{validate_enumeration_set($data_frame, $dic, $options)};
    push @issues, @{validate_range($data_frame, $dic)};
    push @issues, @{validate_type_container($data_frame, $dic)};
    push @issues, @{validate_loops($data_frame, $dic)};
    push @issues, @{validate_aliases($data_frame, $dic)};

    if ( $options->{'report_deprecated'} ) {
        push @issues, @{report_deprecated($data_frame, $dic)};
    }

    push @issues, @{validate_linked_items($data_frame, $dic)};
    push @issues, @{validate_standard_uncertainties(
                    $data_frame, $dic,
                    {
                      'report_missing_su' => $options->{'report_missing_su'}
                    }
                )};

    return \@issues;
}

##
# Checks if the usage of standard uncertainty values is correct according
# to the given DDLm dictionary.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       The data structure of the validation dictionary as returned by the
#       COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @param $options
#       Reference to a hash of options. The following options are recognised:
#       {
#       # Report missing mandatory s.u. values
#           'report_missing_su' => 0
#       }
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
#
##
sub validate_standard_uncertainties
{
    my ($data_frame, $dic, $options) = @_;

    $options = {} if !defined $options;
    my $report_missing_su = defined $options->{'report_missing_su'} ?
                                    $options->{'report_missing_su'} : 0;

    my @issues;
    for my $tag ( @{$data_frame->{'tags'}} ) {
        next if ( !exists $dic->{'Item'}{$tag} );

        push @issues, @{check_su_eligibility($tag, $data_frame, $dic)};
        push @issues, @{check_su_pairs($tag, $data_frame, $dic)};

        if ( $report_missing_su ) {
            push @issues, @{ check_missing_su_values($tag, $data_frame, $dic) };
        }
    }

    return \@issues;
}

##
# Checks the eligibility of a data item to contain standard uncertainty values.
#
# @param $tag
#       Data name of the data item that should be checked.
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of the validation dictionary as returned by the
#       COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_su_eligibility
{
    my ($tag, $data_frame, $dic) = @_;

    my $dic_item = $dic->{'Item'}{$tag};
    # measurand data items are allowed to contain standard uncertainties
    return [] if get_type_purpose($dic_item) eq 'measurand';

    # numeric types capable of having s.u. values in parenthesis notation
    my $type_content = lc get_type_contents($tag, $data_frame, $dic);
    return [] if ! ( $type_content eq 'count'   || $type_content eq 'index' ||
                     $type_content eq 'integer' || $type_content eq 'real' );

    # Getting su values provided using the parenthesis notation
    my $su_values = get_su_from_data_values( $data_frame, $tag );

    my @issues;
    for ( my $i = 0; $i < @{$data_frame->{'values'}{$tag}}; $i++ ) {
        if ( defined $su_values->[$i] ) {
            next if $su_values->[$i] eq 'spec';
            next if $su_values->[$i] eq 'text';

            my $value = $data_frame->{'values'}{$tag}->[$i];
            my $par_su = '(-)';
            if ( $value =~ /([(][0-9]+[)])$/ ) {
                $par_su = $1;
            }
            push @issues,
                 {
                    'test_type'  => 'STANDARD_UNCERTAINTY.FORBIDDEN',
                    'data_items' => [ $tag ],
                    'message'    =>
                        "data item '$tag' value '$value' is not permitted to " .
                        "contain the appended standard uncertainty value '$par_su'"
                 }
        }
    }

    return \@issues;
}

##
# Checks if a data item does not contain ambiguos standard uncertainty values.
# A standard uncertainty value is considered ambiguos if the values provided
# using the parenthesis notation and those provided using a separate data item
# do not match.
#
# @param $tag
#       Data name of the data item that should be checked.
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of the validation dictionary as returned by
#       the COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_su_pairs
{
    my ($tag, $data_frame, $dic) = @_;

    my $dic_item = $dic->{'Item'}{$tag};
    return [] if get_type_purpose($dic_item) ne 'measurand';

    my @su_data_names = @{ get_su_data_names_in_frame($dic, $data_frame, $tag) };
    return [] if !@su_data_names;

    my @issues;
    my $su_data_name = lc $su_data_names[0];
    my $par_su_values = get_su_from_data_values( $data_frame, $tag );
    my $item_su_values = $data_frame->{'values'}{$su_data_name};
    for ( my $i = 0; $i < @{$data_frame->{'values'}{$tag}}; $i++ ) {

        next if !defined $par_su_values->[$i];
        next if $par_su_values->[$i] eq 'text';
        next if $par_su_values->[$i] eq 'special';

        next if (  has_special_value( $data_frame, $su_data_name, $i ) );
        next if ( !has_numeric_value( $data_frame, $su_data_name, $i ) );

        if ( $item_su_values->[$i] ne $par_su_values->[$i] ) {
            push @issues,
                 {
                    'test_type'  => 'STANDARD_UNCERTAINTY.VALUE_MISMATCH',
                    'data_items' => [ $tag, $su_data_name ],
                    'message'    =>
                        "data item '$tag' value '$data_frame->{'values'}{$tag}[$i]' " .
                        'has an ambiguous standard uncertainty value -- ' .
                        'values provided using the parenthesis notation ' .
                        "('$par_su_values->[$i]') and the '$su_data_name' " .
                        "data item ('$item_su_values->[$i]') do not match"
                 }
        }
    }

    return \@issues;
}

##
# Checks if a data item contains the mandatory standard uncertainty values
# using either the parenthesis notation or as a separate data item.
#
# @param $tag
#       Data name of the data item that should be checked.
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of the validation dictionary as returned by
#       the COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_missing_su_values
{
    my ($tag, $data_frame, $dic) = @_;

    my $dic_item = $dic->{'Item'}{$tag};
    return [] if get_type_purpose($dic_item) ne 'measurand';

    return [] if @{ get_su_data_names_in_frame($dic, $data_frame, $tag) };

    my @issues;
    my $par_su_values = get_su_from_data_values( $data_frame, $tag );
    for ( my $i = 0; $i < @{$par_su_values}; $i++ ) {
        if ( !defined $par_su_values->[$i] ) {
            push @issues,
                 {
                    'test_type'  => 'STANDARD_UNCERTAINTY.MANDATORY',
                    'data_items' => [ $tag ],
                    'message'    =>
                        "data item '$tag' value '$data_frame->{'values'}{$tag}[$i]' " .
                        'violates content purpose constraints -- data values ' .
                        'of the \'Measurand\' type must have their standard ' .
                        'uncertainties provided'
                 }
        }
    }

    return \@issues;
}

##
# Checks if data names that refer to the same data item (aliases) have
# identical data values.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of the validation dictionary as returned by
#       the COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub validate_aliases
{
    my ($data_frame, $dic) = @_;

    my @issues;

    my $alias_groups = cluster_aliases($data_frame, $dic);
    for my $key ( sort keys %{$alias_groups} ) {
        my $alias_group = $alias_groups->{$key};
        # TODO: currently, looped data items are silently skipped.
        # They should be properly validated or at least reported
        next if any { @{$data_frame->{'values'}{$_}} > 1 } @{$alias_group};

        my $type_contents = get_type_contents( $alias_group->[0],
                                               $data_frame,
                                               $dic );
        my $first_value = $data_frame->{'values'}{$alias_group->[0]}[0];

        if ( any { !compare_ddlm_values(
                $first_value,
                $data_frame->{'values'}{$_}[0],
                $type_contents ) } @{$alias_group} ) {
            push @issues,
                 {
                    'test_type'  => 'DIFFERING_ALIAS_VALUES',
                    'data_items' => $alias_group,
                    'message'    =>
                        'incorrect usage of data item aliases -- ' .
                        'data names [' .
                        ( join ', ', map { "'$_'" } @{$alias_group} ) .
                        '] refer to the same data item, but have differing ' .
                        'values [' .
                        ( join ', ', map { "'$data_frame->{'values'}{$_}[0]'" }
                                                @{$alias_group} ) .
                        ']'
                 }
        }
    }

    return \@issues;
}

sub cluster_aliases
{
    my ( $data_frame, $dic ) = @_;

    my %alias_groups;
    for my $tag ( @{$data_frame->{'tags'}} ) {
      if ( exists $dic->{'Item'}{$tag} ) {
        my $dic_item = $dic->{'Item'}{$tag};
        my $data_names = get_data_alias($dic_item);
        next if !@{$data_names};
        my $key = build_data_name_key($data_names);
        push @{ $alias_groups{$key} }, $tag;
      }
    };

    for my $key ( keys %alias_groups ) {
        if ( @{$alias_groups{$key}} < 2 ) {
            delete $alias_groups{$key};
        }
    }

    return \%alias_groups;
}

sub build_data_name_key
{
    my ($data_names) = @_;

    my $join_char = "\x{001E}";
    return join $join_char, sort map { lc } @{$data_names};
}

##
# Evaluates if a data item is eligible to contain the standard uncertainty
# values of the specified data item as defined in a DDLm dictionary. 
#
# @param $dic
#       Data structure of a DDLm dictionary as returned by the
#       COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @param $data_name
#       Name of the measured data item.
# @param $su_data_name
#       Name of the s.u. data item.
# @return
#       '1' if the data item is eligible, '0' otherwise.
##
sub is_su_pair
{
    my ( $dic, $data_name, $su_data_name ) = @_;

    return 0 if !exists $dic->{'Item'}{ lc $su_data_name };
    my $su_item = $dic->{'Item'}{ lc $su_data_name };

    return 0 if get_type_purpose( $su_item ) ne 'su';

    return 0 if !exists $su_item->{'values'}{'_name.linked_item_id'};
    my $linked_data_name = lc $su_item->{'values'}{'_name.linked_item_id'}[0];

    return 0 if !exists $dic->{'Item'}{$linked_data_name};

    my $linked_data_item = $dic->{'Item'}{$linked_data_name};
    my @linked_item_names = @{ get_all_data_names( $linked_data_item ) };
    if ( any { uc $data_name eq uc $_ } @linked_item_names ) {
        return 1;
    }

    return 0;
}

##
# Returns the names of data items that are intended to store the standard
# uncertainty (s.u.) values of the given data item as defined in a DDLm
# dictionary.
#
# @param $dic
#       Data structure of a DDLm dictionary as returned by the
#       COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @param $data_name
#       Name of the data item for which the s.u. values apply.
# @return
#       Reference to an array of data names.
##
sub get_su_data_names
{
    my ( $dic, $data_name ) = @_;

    return [] if !exists $dic->{'Item'}{$data_name};

    my @su_data_names = grep { is_su_pair( $dic, $data_name, $_ ) }
                                                   keys %{$dic->{'Item'}};

    return \@su_data_names;
}

##
# Returns the names of s.u. data items that are present in the given data
# frame. A DDLm dictionary is consulted to determine which data items store
# the s.u. values.
#
# @param $dic
#       Data structure of a DDLm dictionary as returned by the
#       COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @param $data_frame
#       Data frame as returned by the COD::CIF::Parser.
# @param $data_name
#       Name of the data item for which the s.u. values apply.
# @return
#       Reference to an array of data names.
##
sub get_su_data_names_in_frame
{
    my ( $dic, $data_frame, $data_name ) = @_;

    my $su_names_in_dic = get_su_data_names( $dic, $data_name );

    my @su_data_names = grep { exists $data_frame->{'values'}{$_} }
                                                        @{$su_names_in_dic};

    return \@su_data_names;
}

##
# Extracts the standard uncertainty (s.u.) values expressed using the
# concise parenthesis notation from all values of the given data item.
#
# @param $frame
#       Data frame that contains the data item as returned by the COD::CIF::Parser.
# @param $data_name
#       Name of the data item.
# @return $su_values
#       Array reference to a list of extracted s.u. values. For more
#       information about the potential return values consult the
#       extract_su_from_data_value() subroutine.
##
sub get_su_from_data_values
{
    my ( $data_frame, $data_name ) = @_;

    my @su_values;
    for (my $i = 0; $i < @{$data_frame->{'values'}{$data_name}}; $i++) {
        push @su_values,
             extract_su_from_data_value($data_frame, $data_name, $i );
    }

    return \@su_values;
}

##
# Extracts the standard uncertainty (s.u.) value expressed using the
# parenthesis notation. One of the four types of s.u. values might be
# returned based on the data value:
#   - numeric value (i.e. 0.01) for numeric data values with s.u. values
#     (i.e. 1.23(1));
#   - undef value for numeric values with no s.u. values (i.e. 1.23);
#   - 'spec' string for special CIF values (unquoted '?' or '.' symbols);
#   - 'text' string for non-numeric values (i.e. 'text').
#
# Note, that according to the working specification of CIF 1.1 quoted numeric
# values (i.e. '1.23') should be treated as non-numeric values.
#
# @param $frame
#       Data frame that contains the data item as returned by the COD::CIF::Parser.
# @param $data_name
#       Name of the data item.
# @param $index
#       The index of the data item value.
# @return $su_value
#       The extracted s.u. value in the specified notation.
##
sub extract_su_from_data_value
{
    my ( $data_frame, $data_name, $index ) = @_;

    my $su_value = generate_value_descriptor( $data_frame, $data_name, $index );
    if ( $su_value eq 'numb' ) {
        my ($number, $su) =
                unpack_cif_number( $data_frame->{'values'}{$data_name}[$index] );
        $su_value = $su;
    }

    return $su_value;
}

##
# Extracts the standard uncertainty (s.u.) values recorded in a separate
# data item. One of the three types of s.u. values might be returned based
# on the data value:
#   - numeric value (i.e. 0.01) for numeric data values;
#   - 'spec' string for special CIF values (unquoted '?' or '.' symbols);
#   - 'text' string for non-numeric values (i.e. 'text').
#
# Note, that according to the working specification of CIF 1.1 quoted numeric
# values (i.e. '1.23') should be treated as non-numeric values.
#
# concise parenthesis notation from all values of the given data item.
#
# @param $frame
#       Data frame that contains the data item as returned by the COD::CIF::Parser.
# @param $data_name
#       Name of the data item.
# @return $su_values
#       Array reference to a list of extracted s.u. values.
##
sub get_su_from_separate_item
{
    my ( $dic, $data_frame, $data_name ) = @_;

    my $su_names = get_su_data_names_in_frame( $dic, $data_frame, $data_name );
    return if !@{$su_names};

    $su_names = [ sort { $a cmp $b } @{$su_names} ] ;
    my $su_name = $su_names->[0];

    my @su_values;
    for ( my $i = 0; $i < @{$data_frame->{'values'}{$su_name}}; $i++ ) {
        my $su_value = generate_value_descriptor( $data_frame, $su_name, $i );
        if ( $su_value eq 'numb' ) {
            $su_value = $data_frame->{'values'}{$su_name}[$i];
        }
        push @su_values, $su_value;
    }

    return \@su_values;
}

##
# Returns a descriptor of a data value. One of the following strings will
# be returned:
#   - 'numb' in case the value is numeric;
#   - 'spec' in case of special CIF values (unquoted '?' or '.' symbols);
#   - 'text' in case of non-numeric values (i.e. 'text').
#
# Note, that according to the working specification of CIF 1.1 quoted numeric
# values (i.e. '1.23') should be treated as non-numeric values.
#
# @param $data_frame
#       Data frame that contains the data item as returned by the COD::CIF::Parser.
# @param $data_name
#       Name of the numeric data item.
# @param $index
#       Index of the data item value.
# @return $descriptor
#       Value descriptor string.
##
sub generate_value_descriptor
{
    my ( $data_frame, $data_name, $index ) = @_;

    my $descriptor = 'text';
    if ( has_special_value($data_frame, $data_name, $index ) ) {
        $descriptor = 'spec';
    } elsif ( has_numeric_value( $data_frame, $data_name, $index ) ) {
        $descriptor = 'numb';
    }

    return $descriptor;
}

##
# Evaluates if a standard uncertainty value is a numeric one.
# This subroutines handles standard uncertainty values returned
# by the get_su_from_data_values() and get_su_from_separate_item().
#
# @param $su_value
#       The standard uncertainty value.
# @return
#       '1' is the value is numeric, '0' otherwise.
##
sub is_numeric_su_value
{
    my ( $su_value ) = @_;

    return 0 if !defined $su_value;
    return 0 if $su_value eq 'text';
    return 0 if $su_value eq 'spec';

    return 1;
}

##
# Checks the relationship constraints between linked data items. Missing
# linked data items as well as values unique to the foreign key are
# reported.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of the validation dictionary as returned by
#       the COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub validate_linked_items
{
    my ($data_frame, $dic) = @_;

    my @issues;
    for my $tag ( @{$data_frame->{'tags'}} ) {
        next if !exists $dic->{'Item'}{$tag};

        my $dic_item = $dic->{'Item'}{$tag};
        next if !exists $dic_item->{'values'}{'_name.linked_item_id'};

        my @linked_item_names = ( lc $dic_item->{'values'}{'_name.linked_item_id'}[0] );
        # Check if the linking data item stores the su values
        my $is_su = ( get_type_purpose( $dic_item ) eq 'su' );
        # Retrieve the aliases of the linked data item
        if ( exists $dic->{'Item'}{$linked_item_names[0]} ) {
            push @linked_item_names, map { lc }
                 @{ get_data_alias( $dic->{'Item'}{$linked_item_names[0]} ) };
        } else {
            warn 'missing data item definition in the DDLm dictionary -- ' .
                 "the '$tag' data item is defined as being linked to the " .
                 "'$linked_item_names[0]' data item, however, the definition " .
                 'of the linked data item is not provided' . "\n";
        }

        # filtering out special CIF values ('?' and '.')
        my @data_item_values;
        for ( my $i = 0; $i < @{$data_frame->{'values'}{$tag}}; $i++ ) {
          if ( !has_special_value( $data_frame, $tag, $i ) ) {
              push @data_item_values,
                   $data_frame->{'values'}{$tag}[$i];
          }
        };

        my $linked_item_found = 0;
        for my $linked_item_name (@linked_item_names) {
          if ( exists $data_frame->{'values'}{$linked_item_name} ) {
            $linked_item_found = 1;
            # SU are not required to match the linked data item values
            next if $is_su;
            my %candidate_key_values = map { $_ => 1 }
                  @{$data_frame->{'values'}{$linked_item_name}};
            my @unmatched = uniq sort grep { !exists $candidate_key_values{$_} }
                  @data_item_values;
            push @issues, map {
                    {
                       'test_type'  => 'PRESENCE_OF_LINKED_DATA_ITEM_VALUE',
                       'data_items' => [ $tag ],
                       'message'    =>
                            "data item '$tag' contains value '$_' that was " .
                            'not found among the values of the linked ' .
                            "data item '$linked_item_name'"
                    }
                 } @unmatched;
            last;
          }
        }

        if (!$linked_item_found) {
          push @issues,
               {
                   'test_type'  => 'PRESENCE_OF_LINKED_DATA_ITEM',
                   'data_items' => [ $tag ],
                   'message'    =>
                        "missing linked data item -- the " .
                        "'$linked_item_names[0]' data item is required by " .
                        "the '$tag' data item"
               }
        }
    }

    return \@issues;
}

##
# Checks the content type against the DDLm dictionary file.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of the validation dictionary as returned by
#       the COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
##
sub validate_type_contents
{
    my ($data_frame, $dic) = @_;

    my @issues;
    for my $tag ( @{$data_frame->{'tags'}} ) {
        next if !exists $dic->{'Item'}{$tag};

        my $type_contents = lc get_type_contents( $tag, $data_frame, $dic );
        my $parsed_type = parse_content_type( $type_contents );
        my @single_item_issues;
        for (my $i = 0; $i < @{$data_frame->{'values'}{$tag}}; $i++) {
            my $value = $data_frame->{'values'}{$tag}[$i];
            push @single_item_issues, @{check_complex_content_type(
                                            $value,
                                            $parsed_type,
                                            $data_frame->{'types'}{$tag}[$i],
                                            ''
                                        )};
        }

        # update the issue message and register data item names
        for my $issue (@single_item_issues) {
            $issue->{'message'} = "data item '$tag' " . $issue->{'message'};
            $issue->{'data_items'} = [ $tag ];
            push @issues, $issue; 
        }
    }

    return \@issues;
}

##
# Parses the given content type string.
# @param $data_frame
#       The content type string.
# @return
#       Reference to a data structure representing the parsed string. 
##
sub parse_content_type
{
    my ( $content_type ) = @_;

    # FIXME: currently the content type string parsing is as primitive
    # as it gets and does not take into account the possibilty of
    # deeper nested structure, etc. However, it does cover most
    # (if not all) of the provided use cases
    my $type_list  = $content_type;
    my $struct_key = 'types';
    if ( $content_type =~ m/^list[(](.*)[)]$/ ) {
        $type_list  = $1;
        $struct_key = 'list';
    } elsif ( $content_type =~ m/^matrix[(](.*)[)]$/ ) {
        $type_list  = $1;
        $struct_key = 'matrix';
    }

    my %parsed_type;
    $parsed_type{$struct_key} = [ split /,/, $type_list ];

    return \%parsed_type;
}

sub stringify_nested_value
{
    my ( $value, $structure_path ) = @_;

    my $value_string = 'value';
    if ( ref $value eq  '' ) {
        $value_string .= " '$value'";
    }
    if ( $structure_path ne '' ) {
        $value_string .= ' located at the data structure position ' .
                         "'$structure_path'" ;
    }

    return $value_string;
}

##
# Checks a structured value against the DDLm data type constraints.
# This is a top-level highly recursive subroutine that is mainly responsible
# for unpacking complex data structures and passing the unpacked values to
# low-level validation subroutines.
#
# @param $value
#       Data value to be validated.
# @param $type_in_dic
#       Data type of the value as specified in the validating DDLm dictionary. 
# @param $type_in_parser
#       Data type of the value as assigned by the COD::CIF::Parser.
#       Used mainly to determine if the value in the original files
#       was surrounded by quotes.
# @param $struct_path
#       String that contains the structure path to the value in a human
#       readable form, i.e., '[7]{"key_1"}{"key_2"}[2]'.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_complex_content_type
{
    my ($value, $type_in_dic, $type_in_parser, $struct_path) = @_;

    my @validation_issues;

    if ( ref $type_in_dic eq 'HASH' ) {
        if ( exists $type_in_dic->{'types'} ) {
            push @validation_issues,
                 @{ check_complex_content_type( $value,
                                      $type_in_dic->{'types'},
                                      $type_in_parser,
                                      $struct_path ) };
        }

        if ( exists $type_in_dic->{'list'} ) {
            if ( ref $value ne 'ARRAY' ) {
                push @validation_issues,
                     {
                        'test_type' => 'CONTENT_TYPE.MANDATORY_LIST_STRUCTURE',
                        'message'   =>
                            (stringify_nested_value( $value, $struct_path )) .
                            ' violates content type constraints ' .
                            '-- the value should be placed inside a list'
                     };
                return \@validation_issues;
            }

            # process each value
            for (my $i = 0; $i < @{$value}; $i++ ) {
                push @validation_issues,
                     @{ check_complex_content_type( $value->[$i],
                                          $type_in_dic->{'list'},
                                          $type_in_parser->[$i],
                                          $struct_path . "[$i]") };
            }
        }
    } elsif ( ref $type_in_dic eq 'ARRAY' ) {
        # More than a single data type indicates
        # an implicit list, i.e. real,int,int
        my $types = $type_in_dic;
        if ( @{$types} > 1 ) {
            if ( ref $value ne 'ARRAY' ) {
                push @validation_issues,
                     {
                        'test_type' => 'CONTENT_TYPE.MANDATORY_LIST_STRUCTURE',
                        'message'   =>
                            (stringify_nested_value( $value, $struct_path )) .
                            ' violates content type constraints ' .
                            '-- the value should be placed inside a list'
                     };
                return \@validation_issues;
            }

            if ( @{$types} ne @{$value} ) {
                push @validation_issues,
                     {
                        'test_type' => 'CONTENT_TYPE.LIST_SIZE_CONSTRAINT',
                        'message'   =>
                            (stringify_nested_value( $value, $struct_path )) .
                            ' violates content type constraints -- ' .
                            'the value list contains an incorrect number ' .
                            'of elements (' . (scalar @{$value}) .
                            ' instead of ' . (scalar @{$types}) . ')'
                     };
                return \@validation_issues;
            }

            for (my $i = 0; $i < @{$types}; $i++ ) {
                push @validation_issues,
                     @{ check_complex_content_type( $value->[$i], $types->[$i],
                                          $type_in_parser->[$i],
                                          $struct_path . "[$i]" ) };
            }
        } else {
            push @validation_issues,
                 @{ check_complex_content_type( $value, $types->[0],
                                      $type_in_parser, $struct_path ) };
        }
    } else {
        push @validation_issues,
             @{ check_content_type( $value, $type_in_dic,
                                    $type_in_parser, $struct_path ) };
    }

    return \@validation_issues;
}

##
# Checks a structured value against the DDLm data type constraints.
#
# This is a helper subroutine that should not be called directly.
# The check_complex_content_type subroutine should be used instead.
#
# @param $value
#       Data value to be validated.
# @param $type_in_dic
#       Data type of the value as specified in the validating DDLm dictionary. 
# @param $type_in_parser
#       Data type of the value as assigned by the COD::CIF::Parser.
#       Used mainly to determine if the value in the original files
#       was surrounded by quotes.
# @param $struct_path
#       String that contains the structure path to the value in a human
#       readable form, i.e., '[7]{"key_1"}{"key_2"}[2]'.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_content_type
{
    my ( $value, $type_in_dic, $type_in_parser, $struct_path ) = @_;

    my @validation_issues;
    if ( ref $value eq '' ) {
        # skip special CIF values '?', '.'
        if ( ( $value eq '?' || $value eq '.' ) &&
             $type_in_parser eq 'UQSTRING' ) {
            return \@validation_issues;
        };

        push @validation_issues,
                @{ check_primitive_data_type( $value, $type_in_dic ) };

        if ( !@validation_issues &&
             ( uc $type_in_dic eq 'COUNT'   ||
               uc $type_in_dic eq 'INDEX'   ||
               uc $type_in_dic eq 'INTEGER' ||
               uc $type_in_dic eq 'REAL' ) &&
             $type_in_parser ne 'FLOAT' &&
             $type_in_parser ne 'INT' ) {
            push @validation_issues,
                 {
                    'test_type'  => 'TYPE_CONSTRAINT.QUOTED_NUMERIC_VALUES',
                    'message'    =>
                        'numeric values should be written without the use ' .
                        'of quotes or multiline value designators'
                 }
        }

        my $value_with_full_path = stringify_nested_value( $value, $struct_path );
        for my $issue (@validation_issues) {
            $issue->{'message'} =
                    $value_with_full_path . " violates content type " .
                    "constraints -- " . $issue->{'message'}
        }
    } elsif ( ref $value eq 'ARRAY' ) {
        for (my $i = 0; $i < @{$value}; $i++ ) {
            push @validation_issues,
                 @{ check_complex_content_type( $value->[$i], $type_in_dic,
                                      $type_in_parser->[$i],
                                      $struct_path ."[$i]" ) };
        }
    } elsif ( ref $value eq 'HASH' ) {
        for my $key ( keys %{$value} ) {
            push @validation_issues,
                 @{ check_complex_content_type( $value->{$key}, $type_in_dic,
                                      $type_in_parser->{$key},
                                      $struct_path . "{\"$key\"}" ) };
        }
    } else {
       warn 'Handling of the \'', ref $value, '\' Perl reference in ' .
            'data type validation is not yet implemented';
    }

    return \@validation_issues;
}

##
# Checks the value against the DDLm data type constraints.
#
# The validation rules for imaginary and complex and types were based on the
# "Draft specifications of the dictionary relational expression language dREL"
# document (https://www.iucr.org/__data/assets/pdf_file/0007/16378/dREL_spec_aug08.pdf).
#
# @param $value
#       The data value that is being validated.
# @param $type
#       The declared data type of the value.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_primitive_data_type
{
    my ($value, $type) = @_;

    # CIF2 characters according to the EBNF grammar:
    # https://www.iucr.org/__data/assets/text_file/0009/112131/CIF2-ENBF.txt
    #
    # U+0009, U+000A, U+000D, U+0020-U+007E, U+00A0-U+D7FF, U+E000-U+FDCF,
    # U+FDF0-U+FFFD, U+10000-U+1FFFD, U+20000-U+2FFFD, U+30000-U+3FFFD,
    # U+40000-U+4FFFD, U+50000-U+5FFFD, U+60000-U+6FFFD, U+70000-U+7FFFD,
    # U+80000-U+8FFFD, U+90000-U+9FFFD, U+A0000-U+AFFFD, U+B0000-U+BFFFD,
    # U+C0000-U+CFFFD, U+D0000-U+DFFFD, U+E0000-U+EFFFD, U+F0000-U+FFFFD,
    # U+100000-U+10FFFD
    my $cif2_ws_character = '\x{0009}' . '\x{000A}' . '\x{000D}' . '\x{0020}';
    my $cif2_nws_character = '\x{0021}-\x{007E}' . '\x{00A0}-\x{D7FF}' .
     '\x{E000}-\x{FDCF}' . '\x{FDF0}-\x{FFFD}' . '\x{10000}-\x{1FFFD}' .
     '\x{20000}-\x{2FFFD}' . '\x{30000}-\x{3FFFD}' . '\x{40000}-\x{4FFFD}' .
     '\x{50000}-\x{5FFFD}' . '\x{60000}-\x{6FFFD}' . '\x{70000}-\x{7FFFD}' .
     '\x{80000}-\x{8FFFD}' . '\x{90000}-\x{9FFFD}' . '\x{A0000}-\x{AFFFD}' .
     '\x{B0000}-\x{BFFFD}' . '\x{C0000}-\x{CFFFD}' . '\x{D0000}-\x{DFFFD}' .
     '\x{E0000}-\x{EFFFD}' . '\x{F0000}-\x{FFFFD}' . '\x{100000}-\x{10FFFD}';

    my $u_int   = '[0-9]+';
    my $int     = "[+-]?${u_int}";
    my $exp     = "[eE][+-]?${u_int}";
    my $u_float = "(?:${u_int}${exp})|(?:[0-9]*[.]${u_int}|${u_int}+[.])(?:$exp)?";
    my $float   = "[+-]?(?:${u_float})";

    my $cif2_character = $cif2_ws_character . $cif2_nws_character;

    my @validation_issues;

    $type = lc $type;
    if ( $type eq 'text' ) {
        # case-sensitive sequence of CIF2 characters
        if ( $value =~ m/([^$cif2_character])/ ) {
            push @validation_issues,
                 {
                    'test_type' => 'TYPE_CONSTRAINT.TEXT_TYPE_FORBIDDEN_CHARACTER',
                    'message'   =>
                        "the '$1' symbol does not belong to the permitted symbol set"
                 }
        }
    } elsif ( $type eq 'code' ) {
        # case-insensitive sequence of CIF2 characters containing
        # no ASCII whitespace
        if ( $value =~ m/([^$cif2_nws_character])/ ) {
            push @validation_issues,
                 {
                    'test_type' => 'TYPE_CONSTRAINT.CODE_TYPE_FORBIDDEN_CHARACTER',
                    'message'   =>
                        "the '$1' symbol does not belong to the permitted symbol set"
                 }
        }
    } elsif ( $type eq 'name' ) {
        # case-insensitive sequence of ASCII alpha-numeric characters
        # or underscore
        if ( $value =~ m/([^_A-Za-z0-9])/ ) {
            push @validation_issues,
                 {
                    'test_type' => 'TYPE_CONSTRAINT.NAME_TYPE_FORBIDDEN_CHARACTER',
                    'message'   =>
                        "the '$1' symbol does not belong to the permitted symbol set"
                 }
        }
    } elsif ( $type eq 'tag' ) {
        # case-insensitive CIF2 character sequence with leading
        # underscore and no ASCII whitespace
        if ( $value !~ m/^_/ ) {
            push @validation_issues,
                 {
                    'test_type' => 'TYPE_CONSTRAINT.TAG_TYPE_START_CHARACTER',
                    'message'   =>
                        'the value must start with an underscore (\'_\') symbol'
                 }
        }
        if ( $value =~ m/([^$cif2_nws_character])/ ) {
            push @validation_issues,
                 {
                    'test_type' => 'TYPE_CONSTRAINT.TAG_TYPE_FORBIDDEN_CHARACTER',
                    'message'   =>
                        "the '$1' symbol does not belong to the permitted symbol set"
                 }
        }
    } elsif ( $type eq 'uri' ) {
        # A Uniform Resource Identifier per RFC 3986
        # TODO: implement proper URI parsing as per RFC 3986
        my ($scheme, $auth, $path, $query, $frag) = uri_split($value);
        if (defined $scheme) {
            if ( $scheme =~ /^[^A-Za-z]/ ) {
                push @validation_issues,
                {
                    'test_type' => 'TYPE_CONSTRAINT.URI_TYPE_START_CHARACTER',
                    'message'   =>
                        "the URI scheme component '$scheme' " .
                        'must start with an ASCII letter ([A-Za-z])'
                }
            }
            if ( $scheme =~ /([^A-Za-z0-9.+-])/ ) {
                push @validation_issues,
                {
                    'test_type' => 'TYPE_CONSTRAINT.URI_TYPE_FORBIDDEN_CHARACTER',
                    'message'   =>
                        "the '$1' symbol is not allowed " .
                        "in the URI scheme component '$scheme'"
                }
            }
        } else {
                push @validation_issues,
                {
                    'test_type' => 'TYPE_CONSTRAINT.URI_TYPE_SCHEME_PREFIX',
                    'message'   =>
                        'an URI string must start with a scheme component'
                }
        }
    } elsif ( $type eq 'date' ) {
        # ISO standard date format <yyyy>-<mm>-<dd>.
        # Use DateTime for all new dictionaries
        eval {
            parse_date($value);
        };
        if ( $@ ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.DATE_TYPE_FORMAT',
                'message'   =>
                        'the value should conform to the ISO standard date '.
                        'format <yyyy>-<mm>-<dd>'
            }
        }
    } elsif ( $type eq 'datetime' ) {
        # A timestamp. Text formats must use date-time or
        # full-date productions of RFC3339 ABNF
        eval {
            parse_datetime($value);
        };
        if ( $@ ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.DATETIME_TYPE_FORMAT',
                'message'   =>
                        'the value should be a date-time or full-date ' .
                        'production of RFC339 ABNF'
            }
        }
    } elsif ( $type eq 'version' ) {
        # version digit string of the form <major>.<version>.<update>
        if ( $value !~ m/^[0-9]+(?:[.][0-9]+){0,2}$/ ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.VERSION_TYPE_FORMAT',
                'message'   =>
                        'the value should be a version digit string of ' .
                        'the form <major>.<version>.<update>'
            }
        }
    } elsif ( $type eq 'dimension' ) {
        # integer limits of an Array/Matrix/List in square brackets
        if ( $value !~ m/^[[](?:$u_int(?:,$u_int)*)?[]]$/ ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.DIMENSION_TYPE_FORMAT',
                'message'   =>
                        'the value should consists of zero or more natural ' .
                        'numbers separated by commas written in between ' .
                        'square brackets, i.e. \'[4,4]\''
            }
        }
    } elsif ( $type eq 'range' ) {
        # inclusive range of numerical values min:max
        my $range = parse_range($value);
        my $lower = $range->[0];
        my $upper = $range->[1];
        if ( ( !defined $lower || $lower !~ /^$int|$float$/ ) &&
             ( !defined $upper || $upper !~ /^$int|$float$/ ) ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.RANGE_TYPE_FORMAT',
                'message'   =>
                        'the value should be a range of numerical values of ' .
                        'the form \'min:max\''
            }
        } elsif ( defined $lower && defined $upper ) {
            if ( $lower > $upper ) {
                push @validation_issues,
                {
                    'test_type' => 'TYPE_CONSTRAINT.RANGE_TYPE_LOWER_GT_UPPER',
                    'message'   =>
                            "the lower range value '$lower' is greater than " .
                            "the upper range value '$upper'"
                }
            }
        }
    } elsif ( $type eq 'count' ) {
        # NOTE: this data type is considered deprecated
        #       and might be removed in the future
        # unsigned integer number
        $value =~ s/\([0-9]+\)$//;
        if ( $value !~ m/^[0-9]+$/ ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.COUNT_TYPE_CONSTRAINT',
                'message'   =>
                        'the value should be an unsigned integer'
            }
        }
    } elsif ( $type eq 'index' ) {
        # NOTE: this data type is considered deprecated
        #       and might be removed in the future
        # unsigned non-zero integer
        $value =~ s/\([0-9]+\)$//;
        if ( $value !~ m/^[0-9]+$/ || $value <= 0 ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.INDEX_TYPE_CONSTRAINT',
                'message'   =>
                        'the value should be an unsigned non-zero integer'
            }
        }
    } elsif ( $type eq 'integer' ) {
        # positive or negative integer
        $value =~ s/\([0-9]+\)$//;
        if ( $value !~ m/^[-+]?[0-9]+$/ ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.INTEGER_TYPE_CONSTRAINT',
                'message'   =>
                        'the value should be an integer'
            }
        }
    } elsif ( $type eq 'real' ) {
        # floating-point real number
        $value =~ s/\([0-9]+\)$//;
        if ( $value !~ m/^(?:${int}|${float})$/ ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.REAL_TYPE_CONSTRAINT',
                'message'   =>
                        'the value should be a floating-point real number'
            }
        }
    } elsif ( $type eq 'imag' ) {
        # floating-point imaginary number
        if ( $value !~ m/^(?:${int}|${float})[jJ]$/ ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.IMAG_TYPE_FORMAT',
                'message'   =>
                        'the value should be a floating-point imaginary ' .
                        'number expressed as a real number with the imaginary ' .
                        'unit suffix \'j\' , i.e. -42j'
            }
        }
    } elsif ( $type eq 'complex' ) {
        # complex number <R>+j<I>
        if ( $value !~ m/^(?:$int|${float})[+-](?:${u_int}|${u_float})[jJ]$/ ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.COMPLEX_TYPE_FORMAT',
                'message'   =>
                        'the value should be a complex number consisting ' .
                        'of a real part expressed as a real number and the ' .
                        'imaginary part expressed as a real number with the ' .
                        'imaginary unit suffix \'j\', i.e. -3.14+42j'
            }
        }
    } elsif ( $type eq 'symop' ) {
        if ( $value !~ /^[-+]?[0-9]*(?:[_ ][0-9]{3,})?$/) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.SYMOP_TYPE_FORMAT',
                'message'   =>
                        'the value should be a string composed of an integer ' .
                        'optionally followed by an underscore or space and ' .
                        'three or more digits'
            }
        }
    } elsif ( $type eq 'implied' ) {
        # implied by the context of the attribute
        warn 'the interpretation of the \'Implied\' data type depends on ' .
             'the context of that the data item appears in -- ' .
             'it should be resolved prior to passing it to the ' .
             '\'check_primitive_data_type\' subroutine' . "\n";
    } elsif ( $type eq 'byreference' ) {
        # The contents have the same form as those of the attribute
        # referenced by _type.contents_referenced_id
        warn 'the interpretation of the \'byReference\' data type depends on ' .
             'the dictionary definitions of the referenced data item -- ' .
             'it should be resolved prior to passing it to the ' .
             '\'check_primitive_data_type\' subroutine' . "\n";
    } else {
        warn "content type '$type' is not recognised\n";
    }

    return \@validation_issues;
}

##
# Checks the container types and dimensions against the DDLm dictionary file.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of the validation dictionary as returned by
#       the COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub validate_type_container
{
    my ($data_frame, $dic) = @_;

    my @issues;

    for my $tag ( @{$data_frame->{'tags'}} ) {
        next if ( !exists $dic->{'Item'}{$tag} );

        my $type_container = lc get_type_container( $dic->{'Item'}{$tag} );
        my $perl_ref_type;
        if ( $type_container eq 'single' ) {
            $perl_ref_type = '';
        } elsif ( $type_container eq 'list' ) {
            $perl_ref_type = 'ARRAY';
        } elsif ( $type_container eq 'table' ) {
            $perl_ref_type = 'HASH';
        } elsif ( $type_container eq 'array' ) {
            $perl_ref_type = 'ARRAY';
        } elsif ( $type_container eq 'matrix') {
            $perl_ref_type = 'ARRAY OF ARRAYS';
        } elsif ( $type_container eq 'multiple' ) {
            # TODO: implement Multiple type check
            next;
        } else {
            next;
        }

        my $type_dimension = get_type_dimension( $dic->{'Item'}{$tag} );
        my $dimensions;
        if ( defined $type_dimension ) {
            $dimensions = parse_dimension( $type_dimension );
        }

        my $report_position = ( @{$data_frame->{'values'}{$tag}} > 1 );
        for ( my $i = 0; $i < @{$data_frame->{'values'}{$tag}}; $i++ ) {
            my $value = $data_frame->{'values'}{$tag}[$i];

            my $placeholder_value = $value;
            $placeholder_value = '[ ... ]' if ref $value eq 'ARRAY';
            $placeholder_value = '{ ... }' if ref $value eq 'HASH';
            my $message = "data item '$tag' value '$placeholder_value' ";
            if ( $report_position ) {
                $message .= 'with the loop index \'' . ($i+1) . '\' ';
            }

            if ( $perl_ref_type eq 'ARRAY OF ARRAYS' ) {
                if ( !is_array_of_arrays( $value ) ) {
                    $message .=
                        'must have a top level matrix container ' .
                        '(i.e. [ [ v1_1 v1_2 ... ] [ v2_1 v2_2 ... ] ... ])';
                    push @issues,
                         {
                            'test_type'  => 'TYPE_CONTAINER.TOP_LEVEL_MATRIX',
                            'data_items' => [ $tag ],
                            'message'    => $message
                         }
                } else {
                    my $single_item_issues = check_matrix_dimensions( $value, $dimensions );
                    for my $issue ( @{$single_item_issues} ) {
                        $issue->{'message'} = $message . $issue->{'message'};
                        $issue->{'data_items'} = [ $tag ];
                        push @issues, $issue;
                    }
                }
            } elsif ( $perl_ref_type ne ref $value ) {
                if ( $perl_ref_type eq 'ARRAY' ) {
                    $message .= 'must have a top level list container ' .
                                '(i.e. [v1 v2 ...])';
                    push @issues,
                         {
                            'test_type'  => 'TYPE_CONTAINER.TOP_LEVEL_LIST',
                            'data_items' => [ $tag ],
                            'message'    => $message
                         }
                } elsif ( $perl_ref_type eq 'HASH' ) {
                    $message .= 'must have a top level table container ' .
                                '(i.e. {\'k1\':v1 \'k2\':v2 ...})';
                    push @issues,
                         {
                            'test_type'  => 'TYPE_CONTAINER.TOP_LEVEL_TABLE',
                            'data_items' => [ $tag ],
                            'message'    => $message
                         }
                } else {
                    $message .= 'must not have a top level container';
                    push @issues,
                         {
                            'test_type'  => 'TYPE_CONTAINER.NO_TOP_LEVEL',
                            'data_items' => [ $tag ],
                            'message'    => $message
                         }
                }
            }
        }
    }

    return \@issues;
}

##
# Evaluates if a given value is an array of arrays.
#
# @param $value
#       Value to be evaluated.
# @return
#       '1' if the value is array of arrays,
#       '0' otherwise. 
##
sub is_array_of_arrays
{
    my ( $value ) = @_;

    return 0 if ref $value ne 'ARRAY';
    return 0 if !@{$value};
    for my $element ( @{$value} ) {
        return 0 if ref $element ne 'ARRAY';
    }

    return 1;
}

##
# Checks if a matrix data structure is of proper dimensions.
#
# @param $matrix
#       Reference to an array of arrays.
# @param $dimensions
#       Reference to a parsed dimension string as returned
#       by the parse_dimension() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_matrix_dimensions
{
    my ( $matrix, $dimensions ) = @_;

    my $target_row_count = $dimensions->[0];
    my $target_col_count = $dimensions->[1];
    
    my @issues;
    my $row_count = scalar @{$matrix};
    if ( defined $target_row_count ) {
        if ( $target_row_count ne $row_count ) {
            push @issues,
                 {
                    'test_type' => 'TYPE_CONTAINER.MATRIX_ROW_COUNT',
                    'message'   =>
                        'does not contain the required number of ' .
                        "matrix rows ($row_count instead of $target_row_count)"
                 }
        }
    }
    return \@issues if !$row_count;

    my @column_counts = map { scalar @{$_} } @{$matrix};
    if ( defined $target_col_count ) {
        for ( my $i = 0; $i < @column_counts; $i++ ) {
            next if $column_counts[$i] eq $target_col_count;
            push @issues,
                 {
                    'test_type' => 'TYPE_CONTAINER.MATRIX_ROW_LENGTH',
                    'message'   =>
                        'does not contain the required number of elements in ' .
                        'the matrix row \'' . ( $i + 1 ) . '\' ' .
                        "($column_counts[$i] instead of $target_col_count)"
                 }
        }
    } else {
        my $first_row_col_count = $column_counts[0];
        for ( my $i = 0; $i < @column_counts; $i++ ) {
            next if $column_counts[0] == $column_counts[$i];
            push @issues,
                 {
                    'test_type' => 'TYPE_CONTAINER.MISMATCHING_MATRIX_ROW_LENGTHS',
                    'message'   =>
                        'is not a proper matrix -- the number of elements in ' .
                        'row \'1\' and row \'' . ( $i + 1 ) . '\' do not match ' .
                        "($column_counts[0] vs. $column_counts[$i])"
                 };
            last;
        }
    }

    return \@issues;
}

##
# Parses a DDLm dimension string into individual components.
#
# @param $dimension_string
#       DDLm dimension string to be parsed.
# @return
#       Reference to an array of two elements both of which might be
#       undefined.
##
sub parse_dimension
{
    my ( $dimension_string ) = @_;

    my @dimension_components;
    if ( $dimension_string =~ m/^\[((\d+)(,(\d+))?)?\]$/ ) {
        push @dimension_components, $2;
        push @dimension_components, $4;
    } else {
        warn "WARNING, dimension string '$dimension_string' could not be parsed\n";
        @dimension_components = (undef, undef);
    }

    return \@dimension_components;
}

#sub stringify_value
#{
#    my ($value) = @_;
#
#    my $max_string_length = 256;
#
#    if (ref $value eq '') {
#        return $value;
#    }
#
#    if (ref $value eq 'ARRAY') {
#        my $array_string = '[ ';
#        for my $a_value ( @{$value} ) {
#            $array_string .= stringify_value($a_value) . " ";
#        }
#        $array_string .= ']';
#        return $array_string;
#    }
#
#    if (ref $value eq 'HASH') {
#        my $hash_string = '{ ';
#        for my $key ( sort keys %{$value} ) {
#            $hash_string .= "'$key': " . stringify_value($value->{$key}) . " ";
#        }
#        $hash_string .= '}';
#        return $hash_string;
#    }
#
#    return $value;
#}

##
# Checks enumeration values against the DDLm dictionary file.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of the validation dictionary as returned by
#       the COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @param $options
#       Reference to a hash of options. The following options are recognised:
#       {
#       # A list of data items that should be treated as potentially
#       # consisting of a several enumeration values
#           'enum_as_set_tags' => [ '_atom_site_refinement_flags',
#                                   '_atom_site.refinement_flags', ]
#       }
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub validate_enumeration_set
{
    my ($data_frame, $dic, $options) = @_;

    my @issues;

    for my $tag ( @{$data_frame->{'tags'}} ) {
        next if ( !exists $dic->{'Item'}{$tag} );

        my $dic_item = $dic->{'Item'}{$tag};
        next if ( !exists $dic_item->{'values'}{'_enumeration_set.state'} );

        my $treat_as_set = any { /^$tag$/ } @{$options->{'enum_as_set_tags'}};
        my $enum_options = { 'treat_as_set' => $treat_as_set,
                             'ignore_case'  => 0 };

        my $enum_set = $dic_item->{'values'}{'_enumeration_set.state'};
        my $data_type = get_type_contents($tag, $data_frame, $dic);
        my @canon_enum_set =
            map { canonicalise_ddlm_value( $_, $data_type ) } @{$enum_set};

        my $type_container = lc get_type_container($dic_item);
        if ( $type_container eq 'single' ) {
            my @values;
            for ( my $i = 0; $i < @{$data_frame->{'values'}{$tag}}; $i++ ) {
                next if has_special_value($data_frame, $tag, $i);
                push @values, $data_frame->{'values'}{$tag}[$i];
            }
            my @canon_values =
                map { canonicalise_ddlm_value( $_, $data_type ) } @values;

            my $is_proper_enum = check_enumeration_set(
                                    \@canon_values,
                                    \@canon_enum_set,
                                    $enum_options
                                  );
            for ( my $i = 0; $i < @{ $is_proper_enum }; $i++ ) {
                if ( $is_proper_enum->[$i] ) {
                    push @issues,
                         {
                            'test_type'  => 'ENUMERATION_SET',
                            'data_items' => [ $tag ],
                            'message' =>
                                "data item '$tag' value '$values[$i]' must " .
                                'be one of the enumeration values [' .
                                ( join ', ', @{$enum_set} ) . ']'
                         }
                }
            }
        } else {
            for (my $i = 0; $i < @{$data_frame->{'values'}{$tag}}; $i++) {
                my $value = $data_frame->{'values'}{$tag}[$i];
                # !!! Mainly targeted at '_type.contents'.
                # !!! Might be deprecated soon.
                if ( $type_container eq 'multiple' ) {
                    if (! any { uc $value  eq uc $_ } @{$enum_set} ) {
                        #     print "$instance: $tag: $value is not permitted\n";
                        #  warn "data item '$tag' value \"$value\" "
                        #     . 'must be one of the enumeration values '
                        #     . '[' . ( join ', ', @enum_values ) . ']. '
                        #     . 'This message might be a false positive since '
                        #     . 'handling of enumeration values with the '
                        #     . "'Multiple' type container is not yet implemented\n";
                    }
                # TODO: consider all of these combinations?
                # even if they don't really occur?
                } elsif ( $type_container eq 'array' ) {

                } elsif ( $type_container eq 'matrix') {

                } elsif ( $type_container eq 'list' ) {

                } elsif ( $type_container eq 'table' ) {

                }
            }
        }
    }

    return \@issues;
}

##
# Checks loop properties against a DDLm dictionary.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of the validation dictionary as returned by
#       the COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub validate_loops
{
    my ($data_frame, $dic) = @_;

    my @issues;

    my %looped_categories;
    for my $tag ( @{$data_frame->{'tags'}} ) {
        next if !exists $dic->{'Item'}{$tag};

        my $category_id = get_category_id($dic->{'Item'}{$tag});
        # This should not happen in a proper dictionary
        next if ( !exists $dic->{'Category'}{lc $category_id} );

        my $category = $dic->{'Category'}{lc $category_id};
        my $tag_is_looped = exists $data_frame->{'inloop'}{$tag};

        if ( is_looped_category( $category ) ) {
            $looped_categories{$category_id}{$tag} = {
                'loop_id'   =>
                    ( exists $data_frame->{'inloop'}{$tag} ?
                      $data_frame->{'inloop'}{$tag} : -1 ),
                'loop_size' => scalar @{$data_frame->{'values'}{$tag}},
            };
        } elsif ( $tag_is_looped ) {
            push @issues,
                 {
                    'test_type'  => 'LOOP_CONTEXT.MUST_NOT_APPEAR_IN_LOOP',
                    'data_items' => [ $tag ],
                    'message'    => "data item '$tag' must not appear in a loop"
                 }
        }
    }

    push @issues,
         @{check_loop_keys( \%looped_categories, $data_frame, $dic )};

    for my $c (keys %looped_categories) {
        # check if all data items appear in the same loop
        my %loops;
        for my $d ( keys %{$looped_categories{$c}} ) {
            $loops{$looped_categories{$c}{$d}{'loop_id'}}++;
        }
        if ( keys %loops > 1 ) {
            push @issues,
                 {
                    'test_type'  => 'CATEGORY_INTEGRITY',
                    'data_items' => [ keys %{$looped_categories{$c}} ],
                    'message'    =>
                        'data items ' . '[' .
                        ( join ', ', sort map { "'$_'" } keys %{$looped_categories{$c}} ) .
                        ']' . ' must all appear in the same loop'
                 }
        }
    }

    return \@issues;
}

##
# Checks the existence and uniqueness of loop primary keys.
#
# @param $looped_categories
#       Data structure that stores information about the looped
#       categories present in the provided data frame:
#
#       $looped_categories = {
#           $category_1 => {
#               {
#                   $category_1_data_name_1 => {
#                       'loop_id'   => 1,  # in loop no 1
#                       'loop_size' => 5,
#                    },
#                   $category.data_name_2 => {
#                       'loop_id'   => 1,
#                       'loop_size' => 5,
#                   },
#                   $category.data_name_3 => {
#                       'loop_id'   => -1, # unlooped
#                       'loop_size' => 1,
#                   },
#                   $category.data_name_4 => {
#                       'loop_id'   => 2,  # in loop no 2
#                       'loop_size' => 3,
#                   },
#               },
#           $category_2 => {
#               ...
#           }
#       }
# @param $data_frame
#       Data frame in which the validate loops reside as returned
#       by the COD::CIF::Parser.
# @param $dic
#       Data structure of the validation dictionary as returned by
#       the COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_loop_keys
{
    my ( $looped_categories, $data_frame, $dic ) = @_;

    my @issues;
    foreach my $c (sort keys %{$looped_categories} ) {
        # The _category.key_id data item hold the data name of a
        # single data item that acts as a primary key
        push @issues,
             @{check_simple_category_key(
                $data_frame, $looped_categories, $c, $dic
             ) };

        # If the _category.key_id and _category_key.name data item values
        # are identical the validation of the latter should be skipped
        if ( exists $dic->{'Category'}{$c}{'values'}{'_category.key_id'} &&
             exists $dic->{'Category'}{$c}{'values'}{'_category_key.name'} &&
             @{$dic->{'Category'}{$c}{'values'}{'_category_key.name'}} == 1 &&
             $dic->{'Category'}{$c}{'values'}{'_category.key_id'}[0] eq
             $dic->{'Category'}{$c}{'values'}{'_category_key.name'}[0]
        ) {
            next;
        }

        # Alternatively, the _category_key.name data item contains
        # a list of data items that can function as a primary key
        push @issues,
             @{check_composite_category_key(
                $data_frame, $looped_categories, $c, $dic
             ) };

    }

    return \@issues;
}

##
# Checks constraints of a simple loop key that consists of a single data item.
#
# @param $data_frame
#       Data frame in which the validate loops reside as returned
#       by the COD::CIF::Parser.
# @param $looped_categories
#       Data structure that stores information about the looped
#       categories present in the provided data frame:
#
#       $looped_categories = {
#           $category_1 => {
#               {
#                   $category_1_data_name_1 => {
#                       'loop_id'   => 1,  # in loop no 1
#                       'loop_size' => 5,
#                    },
#                   $category.data_name_2 => {
#                       'loop_id'   => 1,
#                       'loop_size' => 5,
#                   },
#                   $category.data_name_3 => {
#                       'loop_id'   => -1, # unlooped
#                       'loop_size' => 1,
#                   },
#                   $category.data_name_4 => {
#                       'loop_id'   => 2,  # in loop no 2
#                       'loop_size' => 3,
#                   },
#               },
#           $category_2 => {
#               ...
#           }
#       }
# @param $category_name
#       Name of the category that should be checked.
# @param $dic
#       Data structure of the validation dictionary as returned by
#       the COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_simple_category_key
{
    my ( $data_frame, $looped_categories, $category_name, $dic ) = @_;

    return [] if !exists $dic->{'Category'}{$category_name};
    my $category_block = $dic->{'Category'}{$category_name};
    return [] if !exists $category_block->{'values'}{'_category.key_id'};
    my $cat_key_id = $category_block->{'values'}{'_category.key_id'}[0];
    my $category = $looped_categories->{$category_name};

    # TODO/FIXME: check is the error message still holds true.
    # I.e. we might not find the definition of a subcategory,
    # but still find the definition of the parent category
    my $candidate_key_ids = get_candidate_key_ids($category_name, $dic);
    if ( !defined $candidate_key_ids ) {
        warn 'WARNING, missing data item definition in the DDLm ' .
             "dictionary -- the '$cat_key_id' data item is defined as " .
             "being the primary key of the looped '$category_name' category, " .
             'however, the data item definition is not provided' . "\n";
        return [];
    }

    # The candidate loop key is chosen only if it shares a looped list
    # with at least a single data item from the category. Two unlooped
    # data items are treated as sharing the same loop
    my $key_data_name;
    for my $id ( @{$candidate_key_ids} ) {
        for my $data_name ( map { lc } @{get_all_data_names($dic->{'Item'}{$id})}) {
            next if !exists $data_frame->{'values'}{$data_name};
            next if !item_shares_loop_with_any_item_from_category( $data_name,
                                                                   $data_frame,
                                                                   $category );
            $key_data_name = $data_name;
            last;
        }
        last if defined $key_data_name;
    }

    my @issues;
    if ( defined $key_data_name ) {
        # NOTE: in order to avoid duplicate validation messages the key
        # uniqueness check is only carried out if the primary key data
        # item is the one provided directly in the category definition
        if ( any { $key_data_name eq lc $_ }
                    @{get_all_data_names($dic->{'Item'}{$cat_key_id})} ) {
            my $data_type =
                 get_type_contents($key_data_name, $data_frame, $dic);
            push @issues,
                 @{ check_key_uniqueness( $key_data_name, $data_frame, $data_type ) };
        }
    } else {
        # NOTE: dREL methods sometimes define a way to evaluate the
        # data value using other data item. Since dREL is currently
        # not handled by the validator the missing value should not
        # be reported
        # TODO: implement key evaluation using dREL methods
        my $is_evaluatable = 0;
        for my $id ( @{$candidate_key_ids} ) {
            if ( exists $dic->{'Item'}{$id}{'values'}{'_method.purpose'} ) {
                if ( any { lc $_ eq 'evaluation' }
                         @{$dic->{'Item'}{$id}{'values'}{'_method.purpose'}} ) {
                    $is_evaluatable = 1;
                    last;
                }
            }
        }

        if ( !$is_evaluatable ) {
            push @issues,
                 {
                    'test_type'  => 'KEY_ITEM_PRESENCE',
                    'data_items' => [ $candidate_key_ids->[0] ],
                    'message'    =>
                        'missing category key data item -- ' .
                        "the '$candidate_key_ids->[0]' data item must be " .
                        'provided in the loop containing the [' .
                        ( join ', ', sort map { "'$_'" }
                        keys %{$looped_categories->{$category_name}} ) .
                        '] data items'
                }
        }
    }

    return \@issues;
}

##
# Determines if an item resides in the same looped list as at least one of
# the items from the provided looped category. Data items that do not reside
# in a loop are treated as sharing the same loop.
#
# @param $key_item_name
#       Name of the data item that should be checked.
# @param $data_frame
#       Data frame in which all of the involved data items reside
#       as returned by the COD::CIF::Parser.
# @param $looped_category
#       Reference to a data structure that contains information about
#       a looped category from the provided data frame:
#
#       {
#           $category_1_data_name_1 => {
#               'loop_id'   => 1,  # in loop no 1
#               'loop_size' => 5,
#           },
#           $category.data_name_2 => {
#               'loop_id'   => 1,
#               'loop_size' => 5,
#           },
#           $category.data_name_3 => {
#               'loop_id'   => -1, # unlooped
#               'loop_size' => 1,
#           },
#           $category.data_name_4 => {
#               'loop_id'   => 2,  # in loop no 2
#               'loop_size' => 3,
#           },
#       },
# @return
#       '1' if the item resides in the same looped list as at least one of
#           the item from the category,
#       '0' otherwise. 
##
sub item_shares_loop_with_any_item_from_category
{
    my ($key_item_name, $data_frame, $looped_category) = @_;

    my $key_loop_id = get_item_loop_index($data_frame, $key_item_name);
    $key_loop_id = -1 if !defined $key_loop_id;

    for my $item (sort keys %{$looped_category}) {
        my $item_loop_id = $looped_category->{$item}{'loop_id'};
        return 1 if $item_loop_id == $key_loop_id;
    }

    return 0;
}

##
# Determines which data items can act as non-composite primary keys of a
# category according to the given DDLm dictionary. Normally, each category
# only has a single non-composite candidate key, with the notable exception
# of looped categories that contain looped subcategories. In this case, the
# child category can use the primary key of the parent category as its own.
#
# @param $category_id
#       Id of the category.
# @param $dic
#       Data structure of the validation dictionary as returned by
#       the COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @return
#       Array reference to id list of data items that can act as the primary
#       key for the given category.
##
sub get_candidate_key_ids
{
    my ( $category_id, $dic ) = @_;

    return [] if !exists $dic->{'Category'}{$category_id}{'values'}{'_category.key_id'};

    my @candidate_keys;
    my $cat_key_id = lc $dic->{'Category'}{$category_id}{'values'}{'_category.key_id'}[0];
    push @candidate_keys, $cat_key_id;

    my $parent_category_id = lc get_category_id( $dic->{'Category'}{$category_id} );
    if ( is_looped_category( $dic->{'Category'}{$parent_category_id} ) ) {
       push @candidate_keys, @{ get_candidate_key_ids( $parent_category_id, $dic ) };
    }

    return \@candidate_keys;
}

##
# Checks the uniqueness constraint of a simple loop key.
#
# @param $data_name
#       Data name of the data item which acts as the unique loop key.
# @param $data_frame
#       CIF data frame (data block or save block) in which the data item
#       resides as returned by the COD::CIF::Parser.
# @param $key_type
#       Content type of the key as defined in the DDLm dictionary.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_key_uniqueness
{
    my ($data_name, $data_frame, $key_type) = @_;

    my %unique_values;
    for ( my $i = 0; $i < @{$data_frame->{'values'}{$data_name}}; $i++ ) {
        # TODO: special values are silently skipped, but maybe they should
        # still be reported somehow since having special value in a key
        # might not be desirable...
        next if has_special_value($data_frame, $data_name, $i);
        my $value = $data_frame->{'values'}{$data_name}[$i];
        my $canon_value = canonicalise_ddlm_value( $value, $key_type );
        push @{$unique_values{$canon_value}}, $value;
    }

    my @issues;
    for my $key ( sort keys %unique_values ) {
        if ( @{$unique_values{$key}} > 1 ) {
            push @issues,
                 {
                    'test_type'  => 'SIMPLE_KEY_UNIQUNESS',
                    'data_items' => [ $data_name ],
                    'message'    =>
                        "data item '$data_name' acts as a loop key, but the " .
                        'associated data values are not unique -- value ' .
                        "'$key' appears " . ( scalar @{$unique_values{$key}} ) .
                        ' times as [' .
                        ( join ', ', map { "'$_'" } @{$unique_values{$key}} ) . ']'
                }
        }
    }

    return \@issues;
}

##
# Checks constraints of a composite loop key that consists of several data
# items.
#
# @param $data_frame
#       Data frame in which the validate loops reside as returned
#       by the COD::CIF::Parser.
# @param $looped_categories
#       Data structure that stores information about the looped
#       categories present in the provided data frame:
#
#       $looped_categories = {
#           $category_1 => {
#               {
#                   $category_1_data_name_1 => {
#                       'loop_id'   => 1,  # in loop no 1
#                       'loop_size' => 5,
#                    },
#                   $category.data_name_2 => {
#                       'loop_id'   => 1,
#                       'loop_size' => 5,
#                   },
#                   $category.data_name_3 => {
#                       'loop_id'   => -1, # unlooped
#                       'loop_size' => 1,
#                   },
#                   $category.data_name_4 => {
#                       'loop_id'   => 2,  # in loop no 2
#                       'loop_size' => 3,
#                   },
#               },
#           $category_2 => {
#               ...
#           }
#       }
# @param $category
#       Name of the category that should be checked.
# @param $dic
#       Data structure of the validation dictionary as returned by
#       the COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_composite_category_key
{
    my ( $data_frame, $looped_categories, $category, $dic ) = @_;

    return [] if !exists $dic->{'Category'}{$category}{'values'}{'_category_key.name'};

    my @issues;
    my @key_data_names;
    my $cat_key_ids = $dic->{'Category'}{$category}{'values'}{'_category_key.name'};
    for my $cat_key_id ( @{$cat_key_ids} ) {
        if ( exists $dic->{'Item'}{lc $cat_key_id} ) {
            my $cat_key_frame = $dic->{'Item'}{lc $cat_key_id};
            my $type_contents = get_type_contents(
                $cat_key_id, $data_frame, $dic
            );

            my @data_names;
            push @data_names, @{ get_all_data_names( $cat_key_frame ) };
            @data_names = map { lc } @data_names;

            my $is_key_present = 0;
            for my $data_name (@data_names) {
                if ( exists $data_frame->{'values'}{$data_name} ) {
                    $is_key_present = 1;
                    push @key_data_names, $data_name;
                    last;
                }
            }

            # NOTE: dREL methods sometimes define a way to evaluate the
            # data value using other data items. Since dREL is currently
            # not handled by the validator the missing value should not
            # be reported
            # TODO: implement key evaluation using dREL methods
            my $is_evaluatable = 0;
            if ( exists $cat_key_frame->{'values'}{'_method.purpose'} ) {
                 $is_evaluatable = any { lc $_ eq 'evaluation' }
                        @{$cat_key_frame->{'values'}{'_method.purpose'}};
            }

            my $has_default_value = 0;
            if ( exists $cat_key_frame->{'values'}{'_enumeration.default'} &&
                 !(has_special_value($cat_key_frame, '_enumeration.default', 0) ) ) {
                $has_default_value = 1;
            }

            if ( !$is_key_present &&
                 !$is_evaluatable &&
                 !$has_default_value ) {
                push @issues,
                     {
                        'test_type'  => 'KEY_ITEM_PRESENCE',
                        'data_items' => [ $data_names[0] ],
                        'message'    =>
                            'missing category key data item -- ' .
                            "the '$data_names[0]' data item must be provided " .
                            'in the loop containing the [' .
                            ( join ', ', sort map { "'$_'" }
                            keys %{$looped_categories->{$category}} ) .
                            '] data items'
                     }
            }

        } else {
            warn 'WARNING, missing data item definition in the DDLm ' .
                 "dictionary -- the '$cat_key_id' data item is defined as " .
                 'comprising the composite primary key of the looped ' .
                 "'$category' category, however, the data item definition " .
                 'is not provided' . "\n";
        }
    }
    push @issues,
         @{ check_composite_key_uniqueness( \@key_data_names, $data_frame, $dic ) };

    return \@issues;
}

##
# Checks the uniqueness constraint of a composite loop key.
#
# @param $data_names
#       Data names of data items that comprise the composite unique loop key.
# @param $data_frame
#       CIF data frame (data block or save block) in which the data item
#       resides as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of the validation dictionary as returned by
#       the COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_composite_key_uniqueness
{
    my ($data_names, $data_frame, $dic) = @_;

    return [] if !@{ $data_names };

    my $join_char = "\x{001E}";
    my %unique_values;
    for ( my $i = 0; $i < @{$data_frame->{'values'}{$data_names->[0]}}; $i++ ) {
        my $composite_key = '';
        my @composite_key_values;
        my $has_special_value = 0;
        for my $data_name ( @{$data_names } ) {
            # TODO: composite keys containing special values are silently
            # skipped, but maybe they should still be reported somehow since
            # having special value in a key might render it unusable
            if ( has_special_value($data_frame, $data_name, $i) ) {
                $has_special_value = 1;
                last;
            };

            # TODO: it is really suboptimal to ask for the content type
            # each time...
            my $key_type = get_type_contents(
                $data_name, $data_frame, $dic
            );

            my $value = $data_frame->{'values'}{$data_name}[$i];
            push @composite_key_values, $value;
            $composite_key .= canonicalise_ddlm_value( $value, $key_type ) .
                              "$join_char";
        }
        if (!$has_special_value) {
            push @{$unique_values{$composite_key}}, \@composite_key_values;
        }
    }

    my @issues;
    for my $key ( sort keys %unique_values ) {
        if ( @{$unique_values{$key}} > 1 ) {
            my @duplicates;
            for my $values ( @{$unique_values{$key}} ) {
                push @duplicates,
                     '[' . ( join ', ', map { "'$_'" } @{$values} ) . ']';
            }

            push @issues,
                 {
                    'test_type'  => 'COMPOSITE_KEY_UNIQUNESS',
                    'data_items' => \@{$data_names},
                    'message'    =>
                        'data items [' .
                        ( join ', ', map { "'$_'" } @{$data_names} ) .
                        '] act as a composite loop key, but the associated ' .
                        'data values are not collectivelly unique -- values [' .
                        ( join ', ', map { "'$_'" } split /$join_char/, $key ) .
                        '] appear ' .
                        ( scalar @{$unique_values{$key}} ) . ' times as ' .
                        ( join ', ', @duplicates )
                 }
        }
    }

    return \@issues;
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
        if ( looks_like_number( $uvalue ) ) {
            return pack_precision( $uvalue + 0, $su );
        } else {
            return $value;
        }
    }

    return $value
}

# TODO: it should be noted, that special CIF values are handled outside of
# this function
# TODO: maybe move this to a separate module, implement and test all available
# options
sub compare_ddlm_values
{
  my ( $value_1, $value_2, $content_type ) = @_;

  return ( canonicalise_ddlm_value($value_1, $content_type) eq
           canonicalise_ddlm_value($value_2, $content_type) );
}

##
# Checks if a data frame contains data items that marked as deprecated
# by a DDLm dictionary.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of the validation dictionary as returned by
#       the COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub report_deprecated
{
    my ($data_frame, $dic) = @_;

    my @issues;
    for my $tag ( @{$data_frame->{'tags'}} ) {
        next if !exists $dic->{'Item'}{$tag};
        my $data_item = $dic->{'Item'}{$tag};
        next if !exists $data_item->{'values'}{'_definition_replaced.by'};

        push @issues,
             {
              'test_type'  => 'PRESENCE_OF_DEPRECATED_ITEM',
              'data_items' => [ $tag ],
              'message'    =>
                  "the '$tag' data item has been deprecated and should " .
                  'not be used -- it was replaced by the [' .
                  (
                      join ',' , map { "'$_'" }
                        @{$data_item->{'values'}{'_definition_replaced.by'}}
                  ) .'] data items'
             }
    }

    return \@issues;
}

##
# Checks if values are within the range specified by a DDLm dictionary.
#
# In case the value has an associated standard uncertainty (s.u.) value
# the range is extended from [x; y] to [x-3s; y+3s] where s is the s.u.
# value. Standard uncertainty values are considered in range comparison
# even if the data item is not formally eligible to have an associated
# s.u. value at all.
#  
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of the validation dictionary as returned by
#       the COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub validate_range
{
    my ($data_frame, $dic) = @_;

    my @issues;

    for my $tag ( @{$data_frame->{'tags'}} ) {
        next if !exists $dic->{'Item'}{$tag};

        my $dic_item = $dic->{'Item'}{$tag};
        next if !exists $dic_item->{'values'}{'_enumeration.range'};
        my $range = parse_range( $dic_item->{'values'}{'_enumeration.range'}[0] );

        # DDLm s.u. values can be stored either in the parenthesis of the
        # data value (concise notation, i.e. 5.7(6)) or using a separate
        # data item. This subroutine prioritises the concise notation and
        # only uses the data item if none of the concise notation s.u.
        # values are applicable
        my $su_values = get_su_from_data_values( $data_frame, $tag );
        if ( !any { is_numeric_su_value( $_ ) } @{$su_values} ) {
            $su_values = get_su_from_separate_item( $dic, $data_frame, $tag );
        }

        for (my $i = 0; $i < @{$data_frame->{'values'}{$tag}}; $i++) {
            next if (  has_special_value($data_frame, $tag, $i) );
            next if ( !has_numeric_value($data_frame, $tag, $i) );

            my $value = $data_frame->{'values'}{$tag}[$i];
            my $old_value = $value;

            my $su_value;
            if ( defined $su_values &&
                 is_numeric_su_value( $su_values->[$i] ) ) {
                $su_value = $su_values->[$i];
            }

            $value =~ s/\(\d+\)$//;
            if ( !is_in_range( $value, { 'range' => $range,
                                         'type' => 'numb',
                                         'sigma' => $su_value } ) ) {
                push @issues,
                     {
                        'test_type'  => 'ENUM_RANGE.IN_RANGE',
                        'data_items' => [ $tag ],
                        'message' =>
                            "data item '$tag' value '$old_value' should be " .
                            "in range " . range_to_string($range, { 'type' => 'numb' })
                     }
            }
        }
    }

    return \@issues;
}

##
# Checks application scope restrictions for data items in a dictionary file.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $application_scope
#       Reference to a data item application scope data structure as
#       returned by the extract_application_scope() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Code of the data block in which the data item resides
#           'data_block_code' => 'block_code',
#           # Code of the save frame in which the data item resides
#           # Might be undefined
#           'save_frame_code' => 'frame_name'
#           # Names of the data items examined by the the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub validate_application_scope
{
    my ($data_frame, $application_scope) = @_;

    my @issues;
    my $data_block_code = $data_frame->{'name'};
    my $search_struct = build_search_struct($data_frame);
    for my $scope ( 'Dictionary', 'Category', 'Item' ) {
      for my $instance ( sort keys %{$search_struct->{$scope}} ) {
        my %mandatory   = map { $_ => 0 } @{$application_scope->{$scope}{'Mandatory'}};
        my %recommended = map { $_ => 0 } @{$application_scope->{$scope}{'Recommended'}};
        my %prohibited  = map { $_ => 0 } @{$application_scope->{$scope}{'Prohibited'}};

        # NOTE: by definition the 'Dictionary' scope does not have a save frame name
        my $save_frame_code;
        if ( $scope ne 'Dictionary' ) {
            $save_frame_code = $search_struct->{$scope}{$instance}{'name'};
        }

        for my $tag ( @{$search_struct->{$scope}{$instance}{'tags'}} ) {
          if ( exists $prohibited{$tag} ) {
            # NOTE: import statements are allowed in the HEAD category
              if ( $tag eq '_import.get' &&
                   ( lc get_definition_class( $search_struct->{$scope}{$instance} ) eq 'head' ) ) {
                next;
              }
              push @issues,
                   {
                      'test_type'       => 'SCOPE.PROHIBITED',
                      'data_block_code' => $data_block_code,
                      'save_frame_code' => $save_frame_code,
                      'data_items'      => [ $tag ],
                      'message'         =>
                          "data item '$tag' is prohibited in the '$scope' scope " .
                          "of the '$search_struct->{$scope}{$instance}{'name'}' " .
                          'frame'
                   }
          }
          $mandatory{$tag}   = 1 if ( exists $mandatory{$tag} );
          $recommended{$tag} = 1 if ( exists $recommended{$tag} );
        }

        for my $tag (sort keys %mandatory) {
          if ( $mandatory{$tag} == 0 ) {
            push @issues,
                 {
                    'test_type'       => 'SCOPE.MANDATORY',
                    'data_block_code' => $data_block_code,
                    'save_frame_code' => $save_frame_code,
                    'data_items'      => [ $tag ],
                    'message'         =>
                        "data item '$tag' is mandatory in the '$scope' scope of " .
                        "the '$search_struct->{$scope}{$instance}{'name'}' frame"
                 }
          }
        }

        for my $tag ( sort keys %recommended) {
          if ( $recommended{$tag} == 0 ) {
            # The _category_key.name and _category.key_id are recommended
            # for the CATEGORY scope, however, they make no sense if
            # the CATEGORY is unlooped
            # TODO: figure out what is the IUCr policy towards this
            if ( $scope eq 'Category' &&
                 !is_looped_category( $search_struct->{$scope}{$instance} ) &&
                 ( $tag eq '_category_key.name' || $tag eq '_category.key_id' )
            ) {
               next;
            }

            push @issues,
                 {
                    'test_type'       => 'SCOPE.RECOMMENDED',
                    'data_block_code' => $data_block_code,
                    'save_frame_code' => $save_frame_code,
                    'data_items'      => [ $tag ],
                    'message'         =>
                        "data item '$tag' is recommended in the '$scope' scope of " .
                        "the '$search_struct->{$scope}{$instance}{'name'}' frame"
                 }
          }
        }
      }
    }

    return \@issues;
}

##
# Extracts the application scopes of the data items described in the given
# dictionary. This subroutine is most likely applicable only to the DDLm
# dictionary itself.
#
# @param $dic
#       Data structure of the validation dictionary as returned by
#       the COD::CIF::DDL::DDLm::build_search_struct() subroutine.
#       Most likely this dictionary will be the DDLm dictionary.
# @return $application_scope
#       Reference to a data item application scope data structure of the
#       following form:
#       {
#           'Dictionary' => {
#               'Mandatory'   => [ 'data_item_1', 'data_item_2' ],
#               'Recommended' => [ 'data_item_3' ],
#               'Prohibited'  => [ 'data_item_1' ],
#           },
#           'Category' => {
#               ...
#           },
#           'Item' => {
#               ...
#           }
#       }
##
sub extract_application_scope
{
    my ($dic) = @_;

    if ( !defined $dic->{'Datablock'}
            {'values'}{'_dictionary_valid.application'} ||
         !defined $dic->{'Datablock'}
            {'values'}{'_dictionary_valid.attributes'} ) {
        return;
    }

    my $valid_application = $dic->{'Datablock'}
                              {'values'}{'_dictionary_valid.application'};
    my $valid_attributes  = $dic->{'Datablock'}
                              {'values'}{'_dictionary_valid.attributes'};

    # The DDLm dictionary stores scope restriction data in the form:
    # [SCOPE RESTRICTION], i.e. [DICTIONARY MANDATORY]
    my %application_scope;
    for (my $i = 0; $i < @{$valid_application}; $i++) {
        $application_scope
            {$valid_application->[$i][0]}
            {$valid_application->[$i][1]} = $valid_attributes->[$i]
    };
    # expand valid attribute categories into individual data item names
    for my $scope (keys %application_scope) {
        for my $permission (keys %{$application_scope{$scope}}) {
            $application_scope{$scope}{$permission} =
                expand_categories( $application_scope{$scope}{$permission}, $dic );
        }
    }

    return \%application_scope;
}

##
# Returns the ids of all data items contained in the given categories
# and their subcategories. Recursive.
#
# @param $parent_ids
#       Array reference to a list of parent category ids. Might contain
#       data item ids which are simply copied upon encounter.
# @param $dic
#       Data structure of the validation dictionary as returned by
#       the COD::CIF::DDL::DDLm::build_search_struct() subroutine.
# @return
#       Array reference to a list of data item ids.
##
sub expand_categories
{
    my ($parent_ids, $dic) = @_;

    my @expanded_categories;
    for my $parent_id ( map { lc } @{$parent_ids} ) {
        if ( exists $dic->{'Item'}{$parent_id} ) {
            push @expanded_categories, $parent_id;
        } elsif ( exists $dic->{'Category'}{$parent_id} ) {
            for my $child_id (keys %{$dic->{'Item'}}) {
                my $category_id = get_category_id( $dic->{'Item'}{$child_id} );
                if ( defined $category_id &&
                     lc $category_id eq $parent_id ) {
                    push @expanded_categories, $child_id;
                }
            }
            for my $child_id (keys %{$dic->{'Category'}}) {
                my $category_id = get_category_id( $dic->{'Category'}{$child_id} );
                if ( defined $category_id &&
                     lc $category_id eq $parent_id ) {
                    push @expanded_categories, @{expand_categories([ $child_id ], $dic)};
                }
            }
        } else {
            die 'No such data item or category was found in dictionary';
        }
    }

    return \@expanded_categories;
}

##
# Returns an array composed of the main data name and the provided data name
# aliases.
#
# @param $data_frame
#       Data item definition frame as returned by the COD::CIF::Parser.
# @return $data_names
#       Array reference to a list of data names identifying a data item.
##
sub get_all_data_names
{
    my ( $data_frame ) = @_;

    my @data_names;
    if ( defined get_data_name( $data_frame ) ) {
        push @data_names, get_data_name( $data_frame );
    }
    push @data_names, @{ get_data_alias( $data_frame ) };
    @data_names = uniq map { lc } @data_names;

    return \@data_names;
}

# END: subroutines focused on data validation

1;
