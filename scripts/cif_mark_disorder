#! /bin/sh
#!perl -w # --*- Perl -*--
eval 'exec perl -x $0 ${1+"$@"}'
    if 0;
#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Mark disorder in CIF files judging by distance and occupancy.
#*
#* USAGE:
#*    $0 --options input1.cif input*.cif
#**

use strict;
use warnings;
use COD::CIF::Parser qw( parse_cif );
use COD::AtomBricks qw( build_bricks get_atom_index get_search_span );
use COD::AtomProperties;
use COD::CIF::Data qw( get_cell );
use COD::CIF::Data::AtomList qw( atom_array_from_cif );
use COD::CIF::Tags::CanonicalNames qw( canonicalize_all_names );
use COD::CIF::Tags::Manage qw( set_tag set_loop_tag );
use COD::CIF::Tags::Print qw( print_cif );
use COD::Fractional qw( symop_ortho_from_fract );
use COD::Spacegroups::Symop::Algebra qw( symop_vector_mul );
use COD::Algebra::Vector qw( distance );
use COD::SOptions qw( getOptions );
use COD::SUsage qw( usage options );
use COD::ErrorHandler qw( process_warnings
                          process_errors
                          process_parser_messages );
use COD::ToolsVersion qw( get_version_string );
use List::Util qw( sum );

my $Id = '$Id$';

my $same_site_distance_sensitivity = 0.000001;
my $same_site_occupancy_sensitivity = 0.01;
my $brick_size = 1;
my $cif_header_file;
my $use_parser = "c";
my $exclude_zero_occupancies = 1;
my $report_marked_disorders = 1;
my $ignore_occupancies = 0;
my $messages_to_depositor_comments = 1;

#* OPTIONS:
#*   -d, --distance-sensitivity  0.000001
#*                     Specify maximum distance between two atoms that should
#*                     be perceived as belonging to the same atom site.
#*
#*   --occupancy-sensitivity  0.01
#*                     Set maximum deviation for the sum of occupancies of
#*                     the atoms from the same atom site from 1.
#*
#*   -h, --add-cif-header
#*                     Comments from the beginning of this file will be
#*                     prepended to the output.
#*
#*   --exclude-zero-occupancies
#*                     Do not use atoms with 0 occupancies in calculations (default).
#*   --no-exclude-zero-occupancies
#*   --dont-exclude-zero-occupancies
#*                     Use atoms with zero (0) occupancies in the calculations.
#*
#*   --ignore-occupancies
#*                     Do not require occupancies of the atoms in the same
#*                     atom site to sum up to 1.
#*   --no-ignore-occupancies
#*   --dont-ignore-occupancies
#*                     Require the occupancies of the atoms in the same atom site
#*                     to sum up to 1 to be recognised as disorder (default).
#*
#*   --report-marked-disorders
#*                     Print each of the marked disorder assemblies to
#*                     the standard error, listing atom labels (default).
#*
#*   --no-report-marked-disorders
#*   --dont-report-marked-disorders
#*                     Do not print marked disorder assemblies to the
#*                     standard error.
#*
#*   --add-depositor-comments
#*                     Append reports about newly marked disorder assemblies
#*                     together with the signature of this script to the
#*                     '_cod_depositor_comments' value (default).
#*
#*   --no-add-depositor-comments
#*   --dont-add-depositor-comments
#*                     Do not append anything to the value of
#*                     '_cod_depositor_comments'.
#*
#*   --brick-size  1
#*                     Brick size parameter for 'AtomBricks' algorithm.
#*
#*   --use-perl-parser
#*                     Use Perl parser for CIF parsing.
#*   --use-c-parser
#*                     Use Perl & C parser for CIF parsing (default).
#*
#*   --help, --usage
#*                     Output a short usage message (this message) and exit.
#*   --version
#*                     Output version information and exit.
#**
@ARGV = getOptions(
    "-d,--distance-sensitivity" => \$same_site_distance_sensitivity,
    "--occupancy-sensitivity" => \$same_site_occupancy_sensitivity,

    "-h,--add-cif-header" => \$cif_header_file,

    "--exclude-zero-occupancies"    => sub { $exclude_zero_occupancies = 1; },
    "--no-exclude-zero-occupancies" => sub { $exclude_zero_occupancies = 0; },
    "--dont-exclude-zero-occupancies" => sub { $exclude_zero_occupancies = 0; },

    "--ignore-occupancies" => sub { $ignore_occupancies = 1 },
    "--no-ignore-occupancies" => sub { $ignore_occupancies = 0 },
    "--dont-ignore-occupancies" => sub { $ignore_occupancies = 0 },

    "--report-marked-disorders" => sub { $report_marked_disorders = 1 },
    "--no-report-marked-disorders" =>
        sub { $report_marked_disorders = 0 },
    "--dont-report-marked-disorders" =>
        sub { $report_marked_disorders = 0 },

    "--add-depositor-comments" =>
        sub { $messages_to_depositor_comments = 1 },
    "--no-add-depositor-comments" =>
        sub { $messages_to_depositor_comments = 0 },
    "--dont-add-depositor-comments" =>
        sub { $messages_to_depositor_comments = 0 },

    "--brick-size" => \$brick_size,

    "--use-perl-parser" => sub { $use_parser = "perl" },
    "--use-c-parser"    => sub { $use_parser = "c" },

    '--options'      => sub { options; exit },
    '--help,--usage' => sub { usage; exit },
    '--version'      => sub { print get_version_string(), "\n"; exit }
);

my $die_on_errors    = 1;
my $die_on_warnings  = 0;
my $die_on_notes     = 0;
my $die_on_error_level = {
    ERROR   => $die_on_errors,
    WARNING => $die_on_warnings,
    NOTE    => $die_on_notes
};

my $cif_header;
eval {
    if( $cif_header_file ) {
        open( my $header, '<', "$cif_header_file" ) or die 'ERROR, '
            . 'could not open CIF header file for reading -- '
            . lcfirst($!) . "\n";

        $cif_header = "";
        while( <$header> ) {
            last unless /^#/;
            $cif_header .= $_;
        }

        close( $header ) or die 'ERROR, '
            . 'error while closing CIF header file after reading -- '
            . lcfirst($!) . "\n";

        # The header must not contain CIF 2.0 magic code. For CIF 2.0
        # files the magic code is printed explicitly before the header.
        $cif_header =~ s/^#\\#CIF_2\.0[ \t]*\n//;
    }
};
if ($@) {
    process_errors( {
      'message'  => $@,
      'program'  => $0,
      'filename' => $cif_header_file
    }, $die_on_errors );
};

@ARGV = ("-") unless @ARGV;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

for my $filename (@ARGV) {
    my $options = { 'parser' => $use_parser, 'no_print' => 1 };
    my ( $data, $err_count, $messages ) = parse_cif( $filename, $options );
    process_parser_messages( $messages, $die_on_error_level );

    next if $err_count > 0;

    canonicalize_all_names( $data );

    if( $cif_header ) {
        # Ensure that for CIF v2.0 the magic code comes
        # before the CIF comment header:
        if( grep { exists $_->{cifversion} &&
                          $_->{cifversion}{major} == 2 } @$data ) {
            print "#\\#CIF_2.0\n";
        }
        print $cif_header;
    }

    for my $dataset (@$data) {

        my $dataname = 'data_' . $dataset->{'name'};

        local $SIG{__WARN__} = sub {
            process_warnings( {
                'message'  => @_,
                'program'  => $0,
                'filename' => $filename,
                'add_pos'  => $dataname
            }, $die_on_error_level )
        };

        eval {
            mark_disorder( $dataset,
                           \%COD::AtomProperties::atoms,
                           { same_site_distance_sensitivity =>
                                $same_site_distance_sensitivity,
                             same_site_occupancy_sensitivity =>
                                $same_site_occupancy_sensitivity,
                             brick_size => $brick_size,
                             exclude_zero_occupancies =>
                                $exclude_zero_occupancies,
                             report_marked_disorders =>
                                $report_marked_disorders,
                             ignore_occupancies => $ignore_occupancies,
                             messages_to_depositor_comments =>
                                $messages_to_depositor_comments } );
            print_cif( $dataset,
                       {
                            preserve_loop_order => 1,
                            keep_tag_order => 1
                       }
                     );
        };
        if ( $@ ) {
            process_errors( {
              'message'       => $@,
              'program'       => $0,
              'filename'      => $filename,
              'add_pos'       => $dataname
            }, $die_on_errors )
        }
    }
}

#==============================================================================#
# Find alternatives among CIF atoms
# Accepts
#    atom_list - CIF atom list, as returned by initial_atoms()
#    bricks    - CIF atom bricks, as returned by build_bricks()
# Returns
#    $alternatives = {
#       $atom_number => [ $assembly, $group ]
#    }
sub get_alternatives
{
    my( $atom_list, $bricks, $f2o, $options ) = @_;

    $options = {} unless $options;
    my $default_options = {
        same_site_distance_sensitivity => 0.000001,
        same_site_occupancy_sensitivity => 0.01,
        exclude_zero_occupancies => 1,
        ignore_occupancies => 0,
    };
    for my $key (keys %$default_options) {
        next if exists $options->{$key};
        $options->{$key} = $default_options->{$key};
    }

    my @assemblies;
    my %in_assembly;

    for my $current_atom (@$atom_list) {
        # Skipping dummy atoms
        if( $current_atom->{coordinates_fract}[0] eq '.' ||
            $current_atom->{coordinates_fract}[1] eq '.' ||
            $current_atom->{coordinates_fract}[2] eq '.' ) {
            next;
        }

        my $atom_in_unit_cell_coords_ortho =
            symop_vector_mul( $f2o, $current_atom->{coordinates_fract} );

        my ($i_init, $j_init, $k_init) =
            get_atom_index( $bricks, @{$atom_in_unit_cell_coords_ortho});

        my( $min_i, $max_i, $min_j, $max_j, $min_k, $max_k ) =
                get_search_span( $bricks, $i_init, $j_init, $k_init );

        my $name1 = $current_atom->{name};
        my $index1 = $current_atom->{index};

        for my $i ($min_i .. $max_i) {
        for my $j ($min_j .. $max_j) {
        for my $k ($min_k .. $max_k) {
            for my $atom ( @{$bricks->{atoms}[$i][$j][$k]} ) {
                my $atom_coords_ortho = $atom->{coordinates_ortho};
                my $name2 = $atom->{name};
                my $index2 = $atom->{index};

                next if $index1 ge $index2;
                next if !exists $atom->{atom_site_occupancy} ||
                       ($atom->{atom_site_occupancy} eq '0.0' &&
                        $options->{exclude_zero_occupancies}) ||
                        $atom->{atom_site_occupancy} eq '?' ||
                        $atom->{atom_site_occupancy} eq '.';

                my $dist = distance( $atom_in_unit_cell_coords_ortho,
                                     $atom_coords_ortho );
                next if $dist > $options->{same_site_distance_sensitivity};

                # Skipping initially marked disordered atoms:
                if( exists $current_atom->{assembly} &&
                    exists $atom->{assembly} &&
                    $current_atom->{assembly} eq $atom->{assembly} &&
                    exists $current_atom->{group} &&
                    exists $atom->{group} &&
                    $current_atom->{group} ne $atom->{group} ) {
                    next;
                }

                if( !exists $in_assembly{$index1} &&
                    !exists $in_assembly{$index2} ) {
                    # Creating new assembly
                    $in_assembly{$index1} = scalar @assemblies;
                    $in_assembly{$index2} = scalar @assemblies;
                    push( @assemblies, [ $index1, $index2 ] );
                } elsif( exists $in_assembly{$index1} &&
                         exists $in_assembly{$index2} ) {
                    my $assembly1 = $in_assembly{$index1};
                    my $assembly2 = $in_assembly{$index2};
                    next if $assembly1 == $assembly2;

                    # Merging two assemblies
                    my @new_assembly;
                    foreach( @{$assemblies[$assembly1]} ) {
                        $in_assembly{$_} = scalar @assemblies;
                        push( @new_assembly, $_ );
                    }
                    $assemblies[$assembly1] = [];
                    foreach( @{$assemblies[$assembly2]} ) {
                        $in_assembly{$_} = scalar @assemblies;
                        push( @new_assembly, $_ );
                    }
                    $assemblies[$assembly2] = [];
                    push( @assemblies, \@new_assembly );
                } else {
                    # Joining one atom to the assembly
                    if( exists $in_assembly{$index1} ) {
                        push( @{$assemblies[$in_assembly{$index1}]},
                              $index2 );
                        $in_assembly{$index2} = $in_assembly{$index1};
                    } else {
                        push( @{$assemblies[$in_assembly{$index2}]},
                              $index1 );
                        $in_assembly{$index1} = $in_assembly{$index2};
                    }
                }
            }
        }}}
    }

    my $count = 0;
    my %assemblies_now;

    for my $assembly (@assemblies) {
        next if @$assembly == 0;
        my $occupancy_sum =
            sum( 0.0, map { /(.*?)(?:[(][0-9]+[)])?$/; $1 }
                      map { $atom_list->[$_]{atom_site_occupancy} }
                      @$assembly );
        if( abs( $occupancy_sum - 1 ) >
            $options->{same_site_occupancy_sensitivity} &&
            !$options->{ignore_occupancies} ) {
            my @names = sort map { $atom_list->[$_]{name} } @$assembly;
            warn "WARNING, atoms " . join( ", ", map { "'$_'" } @names )
               . " share the same site, but the sum of their "
               . "occupancies is $occupancy_sum\n";
            next;
        }
        my $group_nr = 1;
        foreach( sort @$assembly ) {
            $assemblies_now{$_} = [ $count, $group_nr ];
            $group_nr++;
        }
        $count++;
    }

    return \%assemblies_now;
}

#==============================================================================#
# Find and mark disorder in a given CIF data block (overwrites old values)
# Accepts
#    dataset         - CIF data block, as produced by COD::CIF::Parser
#    atom_properties - atom properties structure, as from COD::AtomProperties
#    options         - various options to control the algorithm
sub mark_disorder
{
    my( $dataset, $atom_properties, $options ) = @_;
    my $values = $dataset->{values};

    $options = {} unless $options;
    my $default_options = {
        same_site_distance_sensitivity => 0.000001,
        same_site_occupancy_sensitivity => 0.01,
        brick_size => 1,
        exclude_zero_occupancies => 1,
        report_marked_disorders => 1,
        ignore_occupancies => 0,
        messages_to_depositor_comments => 1,
    };
    for my $key (keys %$default_options) {
        next if exists $options->{$key};
        $options->{$key} = $default_options->{$key};
    }

    # Extract atoms fract coordinates
    my $atom_list =
        atom_array_from_cif( $dataset,
                             { allow_unknown_chemical_types => 1,
                               exclude_unknown_coordinates => 1,
                               exclude_dummy_coordinates => 1,
                               assume_full_occupancy => 1,
                               atom_properties => $atom_properties } );

    my %assemblies = map{ $_->{assembly} => 1 }
                     grep{ $_->{assembly} ne '.' ||
                           $_->{group} ne '.' }
                     @$atom_list;
    my @all_assemblies = sort {($a =~ /^[0-9]+$/ && $b =~ /^[0-9]+$/)
                                    ? $a <=> $b
                                    : $a cmp $b} keys %assemblies;
    my $assembly_count = scalar @all_assemblies;

    my $bricks = build_bricks( $atom_list, $options->{brick_size} );

    # Get cell angles(alpha, beta, gamma) and lengths(a, b, c)
    my @cell = get_cell( $values );

    # Make a matric to convert from fractional coordinates to
    # orthogonal:
    my $f2o = symop_ortho_from_fract(@cell);

    my $alternatives =
        get_alternatives( $atom_list,
                          $bricks,
                          $f2o,
                          { same_site_distance_sensitivity =>
                                $options->{same_site_distance_sensitivity},
                            same_site_occupancy_sensitivity =>
                                $options->{same_site_occupancy_sensitivity},
                            exclude_zero_occupancies =>
                                $options->{exclude_zero_occupancies},
                            ignore_occupancies =>
                                $options->{ignore_occupancies} } );

    my @new_assemblies;
    for my $atom_index (keys %$alternatives) {
        my $assembly_nr = $alternatives->{$atom_index}[0];
        if( !defined $new_assemblies[$assembly_nr] ) {
            $new_assemblies[$assembly_nr] = [];
        }
        push( @{$new_assemblies[$assembly_nr]}, $atom_index );
    }

    my $rename_dot_assembly_with;
    if( has_dot_assembly( $atom_list ) &&
        ($assembly_count > 1 || scalar( keys %$alternatives ) > 0) ) {
        if( $all_assemblies[-1] eq '.' ) {
            $rename_dot_assembly_with = 'A';
        } elsif( grep { !/^[A-Y]$/ } @all_assemblies == 0 ) {
            $rename_dot_assembly_with =
                chr( ord( $all_assemblies[-1] ) + 1 );
        } else {
            my @numeric = grep { /^[0-9]+$/ } @all_assemblies;
            $rename_dot_assembly_with = $all_assemblies[-1] + 1;
        }
        rename_dot_assembly( $atom_list, $rename_dot_assembly_with );
        push( @all_assemblies, $rename_dot_assembly_with );
        @all_assemblies = sort {($a =~ /^[0-9]+$/ && $b =~ /^[0-9]+$/)
                                    ? $a <=> $b
                                    : $a cmp $b}
                          @all_assemblies;
    }

    my @assembly_names;
    if( @all_assemblies == 0 &&
        ord( 'A' ) + @new_assemblies <= ord( 'Z' ) ) {
        @assembly_names = map { chr( ord( 'A' ) + $_ - 1 ) }
                              1..@new_assemblies;
    } elsif( @all_assemblies > 0 &&
             scalar( grep { !/^[A-Z\.]$/ } @all_assemblies ) == 0 &&
             ord( $all_assemblies[-1] ) + @new_assemblies <= ord( 'Z' ) ) {
        @assembly_names = map { chr( ord( $all_assemblies[-1] ) + $_ ) }
                              1..@new_assemblies;
    } else {
        my @numeric = grep { /^[0-9]+$/ } @all_assemblies;
        my $first = (@numeric > 0) ? $numeric[-1] : 0;
        @assembly_names = map { $first + $_ } 1..@new_assemblies;
    }

    # Creating arrays of assembly and groups symbols to be recorded in
    # CIF loops
    for my $atom (@$atom_list) {
        my $index = $atom->{index};
        if( exists $alternatives->{$index} ) {
            $atom->{assembly} = $assembly_names[$alternatives->{$index}[0]];
            $atom->{group} = $alternatives->{$index}[1];
        } elsif( !exists $atom->{assembly} ||
                 !exists $atom->{group} ||
                 $atom->{assembly} eq '.' ) {
            $atom->{assembly} = '.';
            $atom->{group} = '.';
        }
    }

    my @assemblies = map { $_->{assembly} } @$atom_list;
    my @groups = map { $_->{group} } @$atom_list;

    # Modifying the CIF data structure and issuing messages
    if( @new_assemblies > 0 || defined $rename_dot_assembly_with ) {

        my @messages;
        if( defined $rename_dot_assembly_with ) {
            my $msg = "disorder assembly '.' was renamed to " .
                      "'$rename_dot_assembly_with'";
            push( @messages, $msg );
            warn "NOTE, $msg\n";
        }

        for my $assembly (@new_assemblies) {
            my @names = sort map { $atom_list->[$_]{name} } @$assembly;
            my $msg = "atoms " . join( ', ', map { "'$_'" } @names ) .
                      " were marked as alternatives";
            push( @messages, $msg );
            if( $options->{report_marked_disorders} ) {
                warn "NOTE, $msg\n";
            }
        }

        if( @new_assemblies > 0 ) {
            warn "NOTE, ". scalar( @new_assemblies ) . " site(s) "
               . "were marked as disorder assemblies\n";
        }

        my $atom_site_tag;

        if( exists $values->{"_atom_site_label"} ) {
            $atom_site_tag = "_atom_site_label";
        } else {
            $atom_site_tag = "_atom_site_type_symbol";
        }

        set_loop_tag( $dataset,
                      '_atom_site_disorder_assembly',
                      $atom_site_tag,
                      \@assemblies );
        set_loop_tag( $dataset,
                      '_atom_site_disorder_group',
                      $atom_site_tag,
                      \@groups );

        if( $options->{messages_to_depositor_comments} ) {
            my $signature = $Id;
            $signature =~ s/^\$|\$$//g;
            my $comment = "  The following automatic conversions " .
                          "were performed:\n\n";
            $comment .= join( "\n", map { '  ' . ucfirst($_) . '.' }
                                            @messages ) . "\n\n";
            $comment .= "  Automatic conversion script\n  $signature";
            if( !$values->{_cod_depositor_comments} ) {
                set_tag( $dataset,
                         '_cod_depositor_comments',
                         "\n$comment" );
            } else {
                $values->{_cod_depositor_comments}[-1] .=
                    "\n\n$comment";
            }
        }
    }

    return;
}

#==============================================================================#
# Indicates whether supplied atom list contains dot assembly.
sub has_dot_assembly
{
    my( $atom_list ) = @_;
    my %assemblies = map{ $_->{assembly} => 1 }
                     grep{ $_->{assembly} ne '.' ||
                           $_->{group} ne '.' }
                     @$atom_list;
    return (exists $assemblies{'.'}) + 0;
}

#==============================================================================#
# Renames dot assembly with a given symbol.
sub rename_dot_assembly
{
    my( $atom_list, $new_assembly ) = @_;
    for my $atom (@$atom_list) {
        next if !exists $atom->{assembly};
        next if !exists $atom->{group};
        if( $atom->{assembly} eq '.' &&
            $atom->{group} ne '.' ) {
            $atom->{assembly} = $new_assembly;
        }
    }

    return;
}
