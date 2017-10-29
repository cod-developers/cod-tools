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
use COD::ErrorHandler qw( process_parser_messages );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    get_imported_files
    merge_imported_files
    merge_save_blocks
);

# From DDL dictionary version 3.13.1
my %import_defaults = (
    'mode' => 'Contents'
);

my %data_item_defaults = (
    '_definition.scope' => 'Item',
    '_definition.class' => 'Datum'
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
              # TODO: the path ends up with a double slash
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
              # TODO: check for case-sensitivity
              if ( $imported_saveblock->{'name'} eq $target_saveblock ) {
                if (defined $imported_saveblock->{'values'}{'_definition.scope'} &&
                    lc $imported_saveblock->{'values'}{'_definition.scope'}[0] eq 'category' ) {
                    my $imports = get_category_imports($saveblock, $imported_file, $import );
                    foreach( @{$imports} ) {
                     #   print $_->{'name'};
                     #   print "\n";
                    }
                  #  exit;
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

sub get_category_imports
{
    my ($save_block, $import_data, $import_options) = @_;

    my $parent_block_scope =
        defined $save_block->{'values'}{'_definition.scope'} ?
                $save_block->{'values'}{'_definition.scope'}[0] :
                $data_item_defaults{'_definition.scope'};

    if ( lc $parent_block_scope ne 'category' ) {
        die "ERROR, a category import '$import_options->{'save'}' from file " .
            "'$import_options->{'file'}' defined in a non-category save block " .
            "'$save_block->{'name'}'\n";
    }

    my $import_block_id = uc $import_options->{'save'};
    my $import_block;
    for my $block ( @{$import_data->{'save_blocks'}} ) {
        if ( uc $block->{'values'}{'_definition.id'}[0] eq $import_block_id ) {
            $import_block = $block;
            last;
        }
    }

    # Head category importing a head category is a special case
    my $parent_block_class =
        defined $save_block->{'values'}{'_definition.class'} ?
                $save_block->{'values'}{'_definition.class'}[0] :
                $data_item_defaults{'_definition.class'};
    my $import_block_class =
        defined $import_block->{'values'}{'_definition.class'} ?
                $import_block->{'values'}{'_definition.class'}[0] :
                $data_item_defaults{'_definition.class'};
    my $head_in_head = lc $parent_block_class eq 'head' &&
                       lc $import_block_class eq 'head';

    my $import_type = defined $import_options->{'mode'} ?
                              $import_options->{'mode'} :
                              $import_defaults{'mode'};

    # TODO: warn about a import type mismatch
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
        push @{$imported_save_blocks}, $parent_block_id;
    }

    return $imported_save_blocks;
}

##
# Selects blocks that balong to 
#
# @param $id
#       Indentifier name of the category. The identifier is usually stored as
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
        my $block_scope    =
            defined $block->{'values'}{'_definition.scope'} ?
                (uc $block->{'values'}{'_definition.scope'}[0] ) :
                $data_item_defaults{'_definition.scope'};

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
