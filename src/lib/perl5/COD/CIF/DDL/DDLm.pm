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
                $saveblock = merge_save_blocks($saveblock, $imported_saveblock);
              }
            }
          }
        }
      }
    }

    return $dict;
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
