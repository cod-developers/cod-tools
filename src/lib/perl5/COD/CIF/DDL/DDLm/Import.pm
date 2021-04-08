#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* A set of subroutines used for resolving import statements in
#* the CIF Methods Dictionary Definition Language (DDLm) files.
#**

package COD::CIF::DDL::DDLm::Import;

use strict;
use warnings;
use COD::CIF::Parser qw( parse_cif );
use COD::CIF::DDL::DDLm qw( get_category_id
                            get_data_name
                            get_definition_class
                            get_definition_scope
                            set_category_id );
use COD::ErrorHandler qw( process_parser_messages
                          report_message );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    get_ddlm_import_path_from_env
    resolve_dic_imports
);

my $DDLM_IMPORT_PATH_ENV_VARIABLE = 'COD_TOOLS_DDLM_IMPORT_PATH';

# From DDLm reference dictionary version 3.14.0
my %import_defaults = (
    'mode' => 'Contents',
    'dupl' => 'Exit',
);

##
# Resolves dictionary import statement in the provided DDLm dictionary
# data block by locating the imported files, parsing them and importing
# the requested save frames.
#
# @param $dic_block
#       Reference to a DDLm dictionary data block as returned by
#       the COD::CIF::Parser.
# @param $options
#       Reference to an option hash. The following options are recognised:
#       {
#       # Reference to an array of directory paths where
#       # the imported files should be searched for
#         'import_path' => [ './', '/dir/subdir/subsubdir/' ],
#       # Filename of the file that contained the dictionary
#       # data block. Used mainly for error-reporting
#         'importing_file' => './file_dir/file.dic',
#       # Reference to an option hash that will be
#       # passed to the CIF parser
#         'parser_options' => { ... },
#       # Reference to a hash that species which error
#       # level are fatal and which are not
#         'die_on_error_level' => {
#               'ERROR'   => 1,
#               'WARNING' => 0,
#               'NOTE'    => 1,
#         }
#       }
# @param $dic_block
#       Reference to the $dic_block DDLm dictionary data block
#       with resolved import statements.
##
sub resolve_dic_imports
{
    my ( $dic_block, $options ) = @_;

    my $import_path        = $options->{'import_path'};
    my $importing_file     = $options->{'importing_file'};
    my $parser_options     = $options->{'parser_options'};
    my $die_on_error_level = $options->{'die_on_error_level'};

    my $import_dependencies = get_imported_files(
            $dic_block,
            {
               'import_path'        => $import_path,
               'parser_options'     => $parser_options,
               'die_on_error_level' => $die_on_error_level,
               'importing_file'     => $importing_file,
            }
    );
    for my $issue ( @{$import_dependencies->{'issues'}} ) {
        $issue->{'program'} = $0;
        report_message(
            $issue,
            $die_on_error_level->{$issue->{'err_level'}}
        );
    }

    my $imported_files = $import_dependencies->{'files'};
    for my $filename ( sort keys %{$imported_files} ) {
        process_parser_messages(
            $imported_files->{$filename}{'parser_messages'},
            $die_on_error_level
        );
    }

    my $merge_results = merge_imported_files( $dic_block, $imported_files );
    for my $import_issue (@{$merge_results->{'import_issues'}}) {
        $import_issue->{'program'} = $0;
        report_message(
            $import_issue,
            $die_on_error_level->{$import_issue->{'err_level'}}
        );
    }
    $dic_block = $merge_results->{'dictionary'};

    return $dic_block;
}

##
# Transforms the given text string into a canonical form.
#
# @param $value
#       Text string that should be normalised.
# @return
#       Normalised text string.
##
sub normalise_import_value
{
    my ($value) = @_;

    return uc $value;
}

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

    my @env_dic_import_path = split /:/, $ENV{$DDLM_IMPORT_PATH_ENV_VARIABLE};

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
#       # Reference to an array of directory paths where
#       # the imported files should be searched for
#         'import_path' => [ './', '/dir/subdir/subsubdir/' ],
#       # Filename of the file that contained the dictionary
#       # data block. Used mainly for error-reporting
#         'importing_file' => './file_dir/file.dic',
#       # Reference to an option hash that will be
#       # passed to the CIF parser
#         'parser_options' => { ... },
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

    my $import_path    = $options->{'import_path'};
    my $importing_file = $options->{'importing_file'};
    my $parser_options = $options->{'parser_options'};

    my $imported_files = resolve_import_dependencies(
        {
            'container_file' => $dic_block,
            'import_path'    => $import_path,
            'imported_files' => {},
            'parser_options' => $parser_options,
            'provenance' => {
                'importing_file'  => $importing_file,
                'importing_block' => $dic_block->{'name'},
            }
        }
    );

    my @issues;
    for my $filename ( sort keys %{$imported_files} ) {
        my $imported_file = $imported_files->{$filename};
        my $import_provenance = $imported_file->{'provenance'};
        if ( !defined $imported_file->{'provenance'}{'file_location'} ) {
            push @issues,
                 {
                    'err_level' => 'WARNING',
                    'message'   =>
                        "the '$filename' file could not be located " .
                        'in the given path -- file will not be imported',
                    'filename'  =>
                        $import_provenance->{'importing_file'},
                    'add_pos'   =>
                        sprint_add_pos_from_provenance( $import_provenance ),
                 };
        }
    }

    my $import_dependencies = {
        'files'  => $imported_files,
        'issues' => \@issues,
    };

    return $import_dependencies;
}

sub sprint_add_pos_from_provenance
{
    my ( $import_provenance ) = @_;

    my $add_pos;
    if ( defined $import_provenance->{'importing_block'} ) {
        $add_pos = 'data_' . $import_provenance->{'importing_block'};
        if ( defined $import_provenance->{'importing_frame'} ) {
            $add_pos .= ' save_' . $import_provenance->{'importing_frame'};
        }
    }

    return $add_pos;
}

#
# TODO: consider a more conservative dictionary import system
#
# dictionary = {
#   'import_path'    => [ 'dir1', 'dir2', 'dir3' ]
#   'container_file' =>
#   'imported_files' =>
#   'parser_options' =>
# }
sub resolve_import_dependencies
{
    my ($params) = @_;
    my $import_path    = $params->{'import_path'};
    my $container_file = $params->{'container_file'};
    my %imported_files = %{$params->{'imported_files'}};
    my $parser_options = $params->{'parser_options'};
    my $provenance     = $params->{'provenance'};

    for my $saveblock ( @{$container_file->{'save_blocks'}} ) {
        my $import_statements = get_import_details( $saveblock );
        for my $import_details ( @{$import_statements} ) {
            my $filename = $import_details->{'file'};
            next if exists $imported_files{$filename};
            my $file_location = find_file_in_path( $filename, $import_path );
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
                    'import_path'       => $import_path,
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

# TODO: add a check for cyclic relationships
##
# Merges several DDLm dictionary files into a single file following
# the instructions provided in the dictionary import statements.
#
# @param $parent_dic
#       Reference to a parsed DDLm dictionary file that contains
#       the dictionary import statements as returned by the COD::CIF::Parser
# @param $imported_files
#       Reference to a hash of parsed DDLm dictionary files that will
#       be used to resolve dictionary import statements as returned by
#       the get_imported_files() subroutine.
# @return
#       Reference to a data structure of the following form:
#       {
#       # Reference to the $parent_dic DDLm dictionary with
#       # resolved import statements
#         'dictionary' => { ... },
#       # Reference to an array of issues that were encountered
#       # while merging the files. The issues are described
#       # using the same field names as the ones accepted
#       # by the COD::ErrorHandler::report_message() subroutine
#         'import_issues' => [
#           {
#           # Issue level (NOTE, WARNING, ERROR)
#             'err_level' => 'WARNING',
#           # Name of the importing file in which the issue was encountered
#             'filename'  => 'dictionary.dic',
#           # Additional information that identifies the data block
#           # and save frame in which the issue was encountered
#             'add_pos'   => 'data_dic save_item',
#           # Human-readable description of the issue
#             'message'   => "save frame 'save_x' could not be imported",
#           },
#           ...
#         ]
#       }
##
sub merge_imported_files
{
    my ( $parent_dic, $imported_files ) = @_;

    my @import_issues;
    for my $parent_frame ( @{$parent_dic->{'save_blocks'}} ) {
        my $import_statements = get_import_details( $parent_frame );
        next if !$import_statements;

        for my $import_details ( @{$import_statements} ) {
            my $filename = $import_details->{'file'};
            next if !exists $imported_files->{$filename};
            next if !exists $imported_files->{$filename}{'file_data'};
            my $imported_file = $imported_files->{$filename}{'file_data'};
            my $local_merge_results = merge_imported_files(
                                          $imported_file,
                                          $imported_files,
                                      );
            push @import_issues, @{$local_merge_results->{'import_issues'}};
            $imported_file = $local_merge_results->{'dictionary'};

            my $frame_retrieval_results = get_imported_frame(
                                            $imported_files->{$filename},
                                            $import_details,
                                          );
            push @import_issues, @{$frame_retrieval_results->{'import_issues'}};
            my $import_frame = $frame_retrieval_results->{'imported_frame'};
            next if !defined $import_frame;

            my $import_warnings = check_import_eligibility(
                                        $parent_frame,
                                        $import_frame,
                                        $import_details
                                   );
            my $file_provenance = $imported_files->{$filename}{'provenance'};
            for my $warning ( @{$import_warnings} ) {
                push @import_issues,
                     {
                        'err_level' => 'WARNING',
                        'filename'  =>
                            $file_provenance->{'importing_file'},
                        'add_pos'   =>
                            sprint_add_pos_from_provenance( $file_provenance ),
                        'message'   => $warning,
                     };
            };
            next if @{$import_warnings};

            my $import_mode = get_import_mode($import_details);
            my $on_duplicate_action = get_import_dupl($import_details);
            if ( $import_mode eq 'Contents' ) {
                eval {
                    $parent_frame = import_save_frame_content(
                                        $parent_frame,
                                        $import_frame,
                                        {
                                          'on_duplicate_action' =>
                                                $on_duplicate_action
                                        }
                                    );
                };
                if ($@) {
                    push @import_issues,
                         {
                            'err_level' => 'ERROR',
                            'message'   =>
                                "save frame '$import_frame->{'name'}' from the " .
                                "'$filename' file could not be imported -- $@",
                            'filename'  =>
                                $file_provenance->{'importing_file'},
                            'add_pos'   =>
                                sprint_add_pos_from_provenance( $file_provenance ),
                         };
                }
            } elsif ( $import_mode eq 'Full' ) {
                if ( lc get_definition_scope( $import_frame ) eq 'category' ) {
                    eval {
                        $parent_dic = import_full_category(
                                        $parent_dic,
                                        $parent_frame,
                                        $imported_file,
                                        $import_details
                                      );
                    };
                    if ($@) {
                        push @import_issues,
                             {
                                'err_level' => 'ERROR',
                                'message'   =>
                                    "category save frame '$import_frame->{'name'}' " .
                                    "from the '$filename' file could not be " .
                                    "imported -- $@",
                                'filename'  =>
                                    $file_provenance->{'importing_file'},
                                'add_pos'   =>
                                    sprint_add_pos_from_provenance( $file_provenance ),
                             }
                    }
                } else {
                    eval {
                        $parent_dic = import_full_item(
                                        $parent_dic,
                                        $parent_frame,
                                        $import_frame,
                                        {
                                          'on_duplicate_action' =>
                                                    $on_duplicate_action
                                        }
                                      );
                    };
                    if ($@) {
                        push @import_issues,
                             {
                                'err_level' => 'ERROR',
                                'message'   =>
                                    "save frame '$import_frame->{'name'}' " .
                                    "from the '$filename' file could not be " .
                                    "imported -- $@",
                                'filename'  =>
                                    $file_provenance->{'importing_file'},
                                'add_pos'   =>
                                    sprint_add_pos_from_provenance( $file_provenance ),
                             }
                    }
                }
            } else {
                warn "the '$import_mode' import mode is currently not " .
                     'supported' . "\n";
            }
        }
    }

    my $import_results = {
         'dictionary'    => $parent_dic,
         'import_issues' => \@import_issues,
    };

    return $import_results;
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
            "a non-category frame '$parent_frame->{'name'}' is not " .
            "permitted to import the '$import_details->{'save'}' category " .
            'frame' . "\n";
    }

    if ( $parent_scope eq 'Item' &&
         $import_mode eq 'Full' ) {
        push @messages,
            'a non-category definition frame ' .
            "'$parent_frame->{'name'}' is not permitted to import data " .
            'definitions in \'Full\' mode';
    };

    if ( $import_class eq 'Head' &&
         $import_mode  eq 'Full' &&
         $parent_class ne 'Head' ) {
        push @messages,
            "a non-HEAD category '$parent_frame->{'name'}' " .
            "is not permitted to import the '$import_frame->{'name'}' " .
            'HEAD category in \'Full\' mode';
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

##
# Retrieves the imported save frame from a given file as specified in
# the provided dictionary import statement.
#
# @param $imported_file
#       Reference to a parsed DDLm dictionary file that contains
#       the imported save frame as returned by the COD::CIF::Parser.
# @param $import_details
#       Reference to dictionary import statement data structure as
#       returned by the get_import_details() subroutine.
# @return
#       Reference to a data structure of the following form:
#       {
#       # Reference to the imported data frame located in
#       # the imported file
#         'imported_frame' => { ... },
#       # Reference to an array of issues that were encountered
#       # while merging the files. The issues are described
#       # using the same field names as the ones accepted
#       # by the COD::ErrorHandler::report_message() subroutine
#         'import_issues' => [
#           {
#           # Issue level (NOTE, WARNING, ERROR)
#             'err_level' => 'WARNING',
#           # Name of the importing file in which the issue was encountered
#             'filename'  => 'dictionary.dic',
#           # Additional information that identifies the data block
#           # and save frame in which the issue was encountered
#             'add_pos'   => 'data_dic save_item',
#           # Human-readable description of the issue
#             'message'   => "save frame 'save_x' could not be imported",
#           },
#           ...
#         ]
#       }
##
sub get_imported_frame
{
    my  ( $imported_file, $import_details ) = @_;

    my $imported_frame_name = $import_details->{'save'};
    my $import_data = $imported_file->{'file_data'};
    my $provenance =  $imported_file->{'provenance'};

    my $imported_frames = get_save_frame_by_name(
                                        $import_data,
                                        $imported_frame_name
                          );

    my $import_frame;
    my @import_issues;
    if ( !@{$imported_frames} ) {
        push @import_issues,
             {
                'err_level' => 'WARNING',
                'filename' =>
                    $provenance->{'importing_file'},
                'add_pos'  =>
                    sprint_add_pos_from_provenance( $provenance ),
                'message'  =>
                    "the '$imported_frame_name' save frame from the " .
                    "'$import_details->{'file'}' file is referenced in a " .
                    'dictionary import statement, but could not be ' .
                    "located in the '$provenance->{'file_location'}' file"
             };
    } else {
        $import_frame = $imported_frames->[0];
        if ( @{$imported_frames} > 2 ) {
            push @import_issues,
                 {
                    'err_level' => 'WARNING',
                    'filename' =>
                        $provenance->{'importing_file'},
                    'add_pos'  =>
                        sprint_add_pos_from_provenance( $provenance ),
                    'message'  =>
                        "more than one '$import_details->{'save'}' save frame " .
                        "was located in the '$provenance->{'file_location'}' " .
                        'file -- only the first save frame will be imported',
                 };
        }
    }

    my $results = {
        'imported_frame' => $import_frame,
        'import_issues'  => \@{import_issues},
    };

    return $results;
}

##
# Imports a DDLm category into a DDLm dictionary. Category import is
# implemented as described in the save_import_details.mode save frame
# of the DDLm reference dictionary version 3.14.0 [1]:
#
#  "Full" imports the entire definition together with any child definitions
#  (in the case of categories) found in the target dictionary. The importing
#  definition becomes the parent of the imported definition. As a special
#  case, a 'Head' category importing a 'Head' category is equivalent to
#  importing all children of the imported 'Head' category as children of
#  the importing 'Head' category.
#
# @source [1]
#       https://github.com/COMCIFS/cif_core/blob/24f69f03841e9504e834a041498ba1360b2d5d63/ddl.dic
#
# @param $parent_dic
#       Reference to a DDLm dictionary data structure that contains
#       the import statement as returned by the COD::CIF::Parser.
# @param $parent_frame
#       Reference to a DDLm dictionary category definition save frame
#       that contains the import statement as returned by the COD::CIF::Parser.
# @param $import_dic
#       Reference to the DDLm dictionary data structure of the imported
#       dictionary as returned by the COD::CIF::Parser.
# @param $import_details
#       Reference to an import option hash. The list of supported options
#       matches the one described in the save_import_details.single_index
#       save frame of the DDLm reference dictionary version 3.14.0:
#           'file'         URI of source dictionary
#           'version'      version of source dictionary
#           'save'         save frame code of source definition
#           'mode'         mode for including save frames
#           'dupl'         option for duplicate entries
#           'miss'         option for missing entries
# @return
#       Reference to the data structure of the importing DDLm dictionary
#       with the resolved import statement.
##
sub import_full_category
{
    my ( $parent_dic, $parent_frame, $import_file, $import_details ) = @_;

    my $parent_scope = get_definition_scope( $parent_frame );

    my $imports = get_category_imports( $parent_frame, $import_file, $import_details );

    my $on_duplicate_action = get_import_dupl($import_details);
    my @new_frames;
    for my $import_frame (@{$imports}) {
        my $duplicate_frame_id;
        for (my $i = 0; $i < @{$parent_dic->{'save_blocks'}}; $i++) {
            my $existing_frame = $parent_dic->{'save_blocks'}[$i];
            if ( normalise_import_value( $existing_frame->{'name'} ) eq
                 normalise_import_value( $import_frame->{'name'} ) ) {
                $duplicate_frame_id = $i;
                last;
            }
        }
        if (defined $duplicate_frame_id) {
            next if $on_duplicate_action eq 'Ignore';
            if ($on_duplicate_action eq 'Replace') {
                $parent_dic->{'save_blocks'}[$duplicate_frame_id] = $import_frame;
                next;
            }
            if ($on_duplicate_action eq 'Exit') {
                die "save frame 'save_$import_frame->{'name'}' exists both " .
                    'in the importing file and in the imported save frame set' .
                    "\n";
            }
            die "import property 'dupl' value '$on_duplicate_action' must be " .
                "one of the supported values ['Ignore', 'Replace', 'Exit']" .
                "\n";
        } else {
            push @new_frames, $import_frame;
        }
    }
    push @{$parent_dic->{'save_blocks'}}, @new_frames;

    return $parent_dic;
}

##
# Imports a single DDLm definition save frame into a DDLm dictionary.
#
# @param $parent_dic
#       Reference to a DDLm dictionary data structure that contains
#       the import statement as returned by the COD::CIF::Parser.
# @param $parent_frame
#       Reference to a DDLm dictionary category definition save frame
#       that contains the import statement as returned by the COD::CIF::Parser.
# @param $import_frame
#       Reference to a DDLm dictionary definition save frame that should
#       be imported as returned by the COD::CIF::Parser.
# @param $options
#       Reference to an option hash. The following options are recognised:
#       {
#         # Text string which specifies the action that should be taken
#         # if a save frame with the same frame code as the imported
#         # frame is detected in the importing file as specified
#         # by the DDLm reference dictionary version 3.14.0.
#         # Supported values: ['Ignore', 'Replace', 'Exit'].
#         # 'Exit' is the default value.
#           'on_duplicate_action' => 'Exit',
#       }
# @return
#       Reference to the data structure of the importing DDLm dictionary
#       with the resolved import statement.
##
sub import_full_item
{
    my ( $parent_dic, $parent_frame, $import_frame, $options ) = @_;

    my $on_duplicate_action = defined $options->{'on_duplicate_action'} ?
                                      $options->{'on_duplicate_action'} :
                                      'Exit';
    my $duplicate_frame_id;
    for (my $i = 0; $i < @{$parent_dic->{'save_blocks'}}; $i++) {
        my $existing_frame = $parent_dic->{'save_blocks'}[$i];
        if ( normalise_import_value( $existing_frame->{'name'} ) eq
             normalise_import_value( $import_frame->{'name'} ) ) {
            $duplicate_frame_id = $i;
            last;
        }
    }

    my $importing_category_name = lc get_data_name( $parent_frame );
    if (!defined $duplicate_frame_id) {
        set_category_id( $import_frame, $importing_category_name );
        push @{$parent_dic->{'save_blocks'}}, $import_frame;
    } else {
        return $parent_dic if $on_duplicate_action eq 'Ignore';
        if ($on_duplicate_action eq 'Replace') {
            set_category_id( $import_frame, $importing_category_name );
            $parent_dic->{'save_blocks'}[$duplicate_frame_id] = $import_frame;
        } elsif ($on_duplicate_action eq 'Exit') {
            die 'save frame with the same frame code already exists in ' .
                'the importing file' . "\n";
        } else {
            die "import property 'dupl' value '$on_duplicate_action' must be " .
                "one of the supported values ['Ignore', 'Replace', 'Exit']" .
                "\n";
        }
    }

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

sub get_import_dupl
{
    my ( $import_details ) = @_;

    if ( !defined $import_details->{'dupl'} ) {
        return $import_defaults{'dupl'};
    }

    return $import_details->{'dupl'};
}

##
# Extracts the data blocks from a CIF data structure that should be imported
# to the importing category.
#
# Category import is implemented as described in the _import_details.mode
# save frame of the DDLm reference dictionary version 3.14.0 [1]:
#
#  "Full" imports the entire definition together with any child definitions
#  (in the case of categories) found in the target dictionary. The importing
#  definition becomes the parent of the imported definition. As a special
#  case, a 'Head' category importing a 'Head' category is equivalent to
#  importing all children of the imported 'Head' category as children of
#  the importing 'Head' category.
#
# @source [1]
#       https://github.com/COMCIFS/cif_core/blob/24f69f03841e9504e834a041498ba1360b2d5d63/ddl.dic
#
# @param $parent_frame
#       Category save frame that contains the import statement as returned
#       by the COD::CIF::Parser.
# @param $imported_dic
#       Reference to the DDLm dictionary data structure of the imported
#       dictionary as returned by the COD::CIF::Parser.
# @param $import_details
#       Reference to an import option hash. The list of supported options
#       matches the one described in the save_import_details.single_index
#       save frame of the DDLm reference dictionary version 3.14.0:
#           'file'         URI of source dictionary
#           'version'      version of source dictionary
#           'save'         save frame code of source definition
#           'mode'         mode for including save frames
#           'dupl'         option for duplicate entries
#           'miss'         option for missing entries
# @return
#       Reference to an array of data frames that should be added to
#       the importing dictionary.
##
sub get_category_imports
{
    my ( $parent_frame, $imported_dic, $import_details ) = @_;

    my $import_block;
    my $import_frame_name = normalise_import_value( $import_details->{'save'} );
    for my $frame ( @{$imported_dic->{'save_blocks'}} ) {
        if ( normalise_import_value( $frame->{'name'} ) eq $import_frame_name ) {
            $import_block = $frame;
            last;
        }
    }

    my $import_block_id = normalise_import_value( get_data_name( $import_block ) );
    my $imported_frames = get_child_frames(
                                $import_block_id,
                                $imported_dic,
                                { 'recursive' => '1' }
                          );

    # Head category importing a head category is a special case
    my $head_in_head = get_definition_class( $parent_frame ) eq 'Head' &&
                       get_definition_class( $import_block ) eq 'Head';
    my $parent_block_id = get_data_name( $parent_frame );
    if ( $head_in_head ) {
        for my $frame ( @{$imported_frames} ) {
            if ( normalise_import_value( get_category_id( $frame ) ) eq
                 $import_block_id ) {
                set_category_id( $frame, $parent_block_id );
            }
        }
    } else {
        set_category_id( $import_block, $parent_block_id );
        unshift @{$imported_frames}, $import_block;
    }

    return $imported_frames;
}

##
# Selects save frames that belong to the given category.
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
sub get_child_frames
{
    my ($id, $data, $options) = @_;

    my $recursive = defined $options->{'recursive'} ?
                            $options->{'recursive'} : 0;

    my @blocks;
    $id = normalise_import_value($id);
    for my $block ( @{$data->{'save_blocks'}} ) {
        my $block_id       = normalise_import_value( get_data_name( $block ) );
        my $block_category = normalise_import_value( get_category_id( $block ) );
        my $block_scope    = get_definition_scope( $block );

        if ( $block_category eq $id ) {
            push @blocks, $block;
            if ( lc $block_scope eq 'category' && $recursive ) {
                push @blocks,
                     @{ get_child_frames($block_id, $data, $options ) };
            }
        }
    }

    return \@blocks;
}

##
# Imports data items from one save frame into another save frame.
#
# @param $old_frame
#       Reference to a DDLm dictionary definition save frame as returned
#       by the COD::CIF::Parser. This is the base save frame that imports
#       the save frame.
# @param $new_frame
#       Reference to a DDLm dictionary definition save frame as returned
#       by the COD::CIF::Parser. This is the imported save frame.
# @param $options
#       Reference to an option hash. The following options are recognised:
#       {
#         # Text string which specifies the action that should be
#         # taken if the same data name is encountered in both
#         # the imported and the importing save frames as specified
#         # in the DDLm reference dictionary version 3.14.0.
#         # Supported values: ['Ignore', 'Replace', 'Exit'].
#         # 'Exit' is the default value.
#           'on_duplicate_action' => 'Exit',
#       }
# @return
#       Reference to a DDLm dictionary save frame produced by
#       merging the provided save frames.
##
# TODO: rewrite as non-destructive?
##
sub import_save_frame_content
{
    my ($old_frame, $new_frame, $options) = @_;

    my $on_duplicate_action = exists $options->{'on_duplicate_action'} ?
                                     $options->{'on_duplicate_action'} :
                                     'Exit';

    # Remove the current import from the import queue
    # TODO: take into account the import order as provided
    # in the "_import_details.order" data item
    shift @{$old_frame->{'values'}{'_import.get'}};

    my %new_to_old_loop_id;
    my @new_tags;
    for my $tag (@{$new_frame->{'tags'}}) {
        if (!exists $old_frame->{'values'}{$tag}) {
            $old_frame->{'types'}{$tag} = $new_frame->{'types'}{$tag};
            $old_frame->{'values'}{$tag} = $new_frame->{'values'}{$tag};
            if (exists $new_frame->{'precisions'}{$tag}) {
                $old_frame->{'precisions'}{$tag} =
                                    $new_frame->{'precisions'}{$tag};
            }
            if (exists $new_frame->{'inloop'}{$tag}) {
                my $sub_loop_id = $new_frame->{'inloop'}{$tag};
                if (!exists $new_to_old_loop_id{$sub_loop_id}) {
                    push @{$old_frame->{'loops'}}, [ $tag ];
                    $new_to_old_loop_id{$sub_loop_id} = $#{$old_frame->{'loops'}};
                } else {
                    my $main_block_id = $new_to_old_loop_id{$sub_loop_id};
                    push @{$old_frame->{'loops'}[$main_block_id]}, $tag;
                }
                $old_frame->{'inloop'}{$tag} = $new_to_old_loop_id{$sub_loop_id};
            }
            push @new_tags, $tag;
        } else {
            if ($on_duplicate_action eq 'Exit') {
                die "data item '$tag' exists in both save frames.\n"
            }
            $old_frame->{'types'}{$tag} = $new_frame->{'types'}{$tag};
            $old_frame->{'values'}{$tag} = $new_frame->{'values'}{$tag};
            if (exists $new_frame->{'precisions'}{$tag}) {
                $old_frame->{'precisions'}{$tag} =
                                        $new_frame->{'precisions'}{$tag};
            }
            if ( exists $old_frame->{'inloop'}{$tag} &&
                !exists $new_frame->{'inloop'}{$tag}) {
                   my $main_loop_id = $old_frame->{'inloop'}{$tag};
                   $old_frame->{'loops'}[$main_loop_id] =
                        [ grep { $_ != $tag }
                            @{$old_frame->{'loops'}[$main_loop_id]} ];
                   delete $old_frame->{'inloop'}{$tag};
            }
        }
    }
    push @{$old_frame->{'tags'}}, @new_tags;

    return $old_frame;
}

1;
