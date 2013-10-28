#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Filter and check pairs of CIF and Fobs files for suitability for
#  deposition to COD database.
#**

package CODPredepositionCheck;

use strict;
use warnings;
use IPC::Open3 qw / open3 /;
use IO::Handle;
use Symbol;
use Unicode::Normalize;
use Unicode2CIF;
use Encode;
use Capture::Tiny ':all';
use UserMessage;
use CIF2COD;
use CIFTagPrint;

@CODPredepositionCheck::identity_tags = qw(
    _cell_length_a
    _cell_length_b
    _cell_length_c
    _cell_angle_alpha
    _cell_angle_beta
    _cell_angle_gamma
    _publ_author_name
    _symmetry_space_group_name_Hall
    _symmetry_space_group_name_H-M
    _[local]_cod_data_source_file
    _[local]_cod_data_source_block
);

$CODPredepositionCheck::max_hold_period = 12;
$CODPredepositionCheck::default_hold_period = 6;

sub filter_and_check
{
    my( $cif, $cif_filename, $hkl, $hkl_filename,
        $db_conf, $deposition_type, $tmp_file, $options ) = @_;

    # Possible options:
    # -- bypass_checks
    # -- replace
    # -- release
    # -- hold_period
    # -- journal
    # -- use_c_parser (not implemented)
    # -- use_perl_parser (default)
    # -- author_name
    # -- split pdCIF

    $options->{hold_period} = check_hold_period( $deposition_type,
                                                 $cif_filename,
                                                 $options->{hold_period},
                                                 $options->{replace} );

    my @filter_opt = qw(
        --fix-syntax-errors
        --fold-title
        --leave-title
        --global-priority
        --reformat-spacegroup
        --estimate-spacegroup
        --keep-unrecognised-spacegroups
        --parse-formula-sum
        --calculate-cell-volume
        --exclude-empty-tags
        --preserve-loop-order
    );

    if( $deposition_type eq 'prepublication' ) {
        push( @filter_opt, '--dont-exclude-publication-details' );
    }

    my( $filter_stdout, $filter_stderr );
    if( ref( $cif ) eq 'ARRAY' ) {
        ( $filter_stdout, $filter_stderr ) =
            run_command( [ 'cif_filter', @filter_opt ], $cif );
    } else {
        ( $filter_stdout, $filter_stderr ) =
            run_command( [ 'cif_filter', @filter_opt, $cif ] );
    }

    foreach( @$filter_stderr ) {
        my $parsed = parse_message( $_ );
        if( defined $parsed ) {
            for( $parsed->{message} ) {
                s/:$//;
                if( /tag .+ is not recognised/ ) {
                    $parsed->{errlevel} = 'NOTE';
                    last;
                }
                if( /the dataname apparently had spaces in it - replaced/ ||
                    /non-ascii symbols encountered in the text/ ||
                    /DOS EOF symbol .* was encountered and ignored/ ||
                    /string with spaces without quotes/ ||
                    /(single|double)-quoted string is missing a closing quote -- fixed/ ||
                    /no data block heading .* found/ ) {
                    $parsed->{errlevel} = 'NOTE';
                    $parsed->{line} = undef;
                    $parsed->{column} = undef;
                    last;
                }
                if( /stray CIF values at the beginning of the input file/ ) {
                    $parsed->{errlevel} = 'WARNING';
                    last;
                }
                if( /end of file encountered while in text field starting in line/ ) {
                    $parsed->{errlevel} = 'ERROR';
                    $parsed->{line} = undef;
                    $parsed->{column} = undef;
                    last;
                }
                if( /STOP_ symbol detected in line/ ||
                    /GLOBAL_ symbol detected/ ||
                    /syntax error/ ||
                    /wrong number of elements in the loop block/ ||
                    /tag .* appears more than once$/ ) {
                    $parsed->{errlevel} = 'ERROR';
                    last;
                }
                if( !defined $parsed->{errlevel} ) {
                    $parsed->{errlevel} = 'NOTE';
                }
            }
            print_message( $0,
                           $cif_filename,
                           $parsed->{datablock},
                           $parsed->{errlevel},
                           $parsed->{message},
                           $parsed->{line},
                           $parsed->{column} );
        } elsif( /^[^:]+cif_filter: (.*)/ ) { # Ad-hoc parse for some messages
            print STDERR "$0: $1\n";
        }
    }

    if( @$filter_stdout == 0 ) {
        die "file '$cif_filename' became empty after filtering " .
            "with cif_filter";
    }

    my( $fix_values_stdout, $fix_values_stderr ) =
        run_command( [ 'cif_fix_values' ], $filter_stdout );

    foreach( @$fix_values_stderr ) {
        my $parsed = parse_message( $_ );
        if( defined $parsed ) {
            if( $parsed->{message} !~ /value '[^']*' should be one of these:/ ) {
                print_message( $0,
                               $cif_filename,
                               $parsed->{datablock},
                               'NOTE',
                               $parsed->{message},
                               $parsed->{line},
                               $parsed->{column} );
            }
        }
    }

    my( $correct_stdout, $correct_stderr ) =
        run_command( [ 'cif_correct_tags' ], $fix_values_stdout );

    foreach( @$correct_stderr ) {
        my $parsed = parse_message( $_ );
        if( defined $parsed ) {
            print_message( $0,
                           $cif_filename,
                           $parsed->{datablock},
                           'NOTE',
                           $parsed->{message},
                           $parsed->{line},
                           $parsed->{column} );
        }
    }
    die 'cif_correct_tags encountered ' . @$correct_stderr . ' ' .
        'warning(s)' if @$correct_stderr > 0;

    if( !$options->{bypass_checks} ) {
        my $ccc_opt;
        if(      $deposition_type eq 'published' ) {
            $ccc_opt = [ '--do-not-check-authors',
                         '--do-not-check-limits' ];
        } else {
            $ccc_opt = [ '--do-not-check-temperature-factors' ];
        }

        my( $ccc_stdout, $ccc_stderr ) =
            run_command( [ 'cif_cod_check', @$ccc_opt ],
                         $correct_stdout );

        if( $ccc_stdout->[0] !~ /OK$/) {
            my $warnings = 0;
            CCCMESSAGE:
            foreach( @$ccc_stdout ) {
                my $parsed = parse_message( $_ );
                if( defined $parsed ) {
                    for( $parsed->{message} ) {
                        if( $deposition_type ne 'published' &&
                            ( /(_journal_name_full|_publ_author_name) is undefined/ ||
                              /neither _journal_year nor _journal_volume is defined/ ||
                              /neither _journal_page_first nor _journal_article_reference is defined/ ) ) {
                            next CCCMESSAGE;
                        }
                        if( !defined $parsed->{errlevel} ) {
                            $parsed->{errlevel} = 'WARNING';
                        }
                        $warnings++ if $parsed->{errlevel} ne 'NOTE';
                    }
                    print_message( $0,
                                   $cif_filename,
                                   $parsed->{datablock},
                                   $parsed->{errlevel},
                                   $parsed->{message},
                                   $parsed->{line},
                                   $parsed->{column} );
                }
            }
            die "cif_cod_check encountered $warnings warning(s)"
                if $warnings;
        }
    }

    open( my $out, ">", $tmp_file );
    print $out join( "\n", @$correct_stdout );
    close( $out );    

    use CIFParser;
    my $parser = new CIFParser;
    my $data = $parser->Run( $tmp_file );

    # Splitting powder diffraction CIF datablocks into CIF and HKL:

    my @cif_datablocks;
    my @hkl_datablocks;

    for my $dataset (@$data) {
        if( exists $dataset->{values}{_refln_index_h} &&
            exists $dataset->{values}{_pd_phase_block_id} ) {
            push( @hkl_datablocks, $dataset );
        } else {
            push( @cif_datablocks, $dataset );
        }
    }

    my $is_pdcif = 0;
    $data = \@cif_datablocks;
    if( @hkl_datablocks > 0 ) {
        $is_pdcif = 1;
        $hkl_filename = $cif_filename;
        open( $out, ">", $tmp_file );
        select( $out );
        for my $dataset (@hkl_datablocks) {
            CIFTagPrint::print_cif( $dataset,
                {
                    keep_tag_order => 1,
                    preserve_loop_order => 1
                } );
        }
        select( STDOUT );
        close( $out );
        open( my $inp, $tmp_file );
        $hkl = [ map{ s/\n$//; $_ } <$inp> ];
        close( $inp );
    }

    # Checking whether names in pre-deposition CIFs and in personal
    # communication CIFs match the depositor name:

    my $deposition_authors;
    my $first_data_name;

    if( $deposition_type eq 'prepublication' ||
        $deposition_type eq 'personal' ) {
          DATASET:
        for my $dataset (@$data) {
            my $values = $dataset->{values};
            if( !defined $values ) {
                critical( $cif_filename, $dataset->{name}, "ERROR",
                          "no data in datablock '$dataset->{name}'" );
            }
            if( exists $values->{_publ_author_name} ) {
                my $web_author = lc($options->{author_name});
                $web_author =~ s/\s//g;
                if( !defined $deposition_authors ) {
                    $deposition_authors = join( "; ",
                        @{$values->{_publ_author_name}} );
                    $first_data_name = $dataset->{name};
                } else {
                    my $deposition_authors_now = join( "; ",
                        @{$values->{_publ_author_name}} );
                    my $data_name_now = $dataset->{name};
                    if( $deposition_authors ne $deposition_authors_now ) {
                        critical( $cif_filename, $data_name_now, "WARNING",
                                  "author list in the datablock " .
                                  "data_$first_data_name " .
                                  "($deposition_authors) is not the " .
                                  "same as in the datablock " .
                                  "data_$data_name_now " .
                                  "($deposition_authors_now) -- please " .
                                  "make sure that all data are authored " .
                                  "by the same people when depositing " .
                                  "multiple data blocks" );
                    }
                }
                for my $author (@{$values->{_publ_author_name}}) {
                    my $cif_author = lc($author);
                    $cif_author =~ s/\s//g;
                    $cif_author = Unicode2CIF::cif2unicode( $cif_author );
                    next DATASET if $cif_author eq $web_author;
                    # Stripping UTF8 combining characters:
                    $cif_author = NFD( $cif_author );
                    $cif_author =~ s/\pM//g;
                    next DATASET if $cif_author eq $web_author;
                }
                critical( $cif_filename, $dataset->{name}, "WARNING",
                          "submitting author '$options->{author_name}' " .
                          "does not match any author in the " .
                          "data_$dataset->{name} author list (" .
                          join( ', ', map { "'$_'" }
                          @{$values->{_publ_author_name}}) . ") -- " .
                          "will not deposit the structure, " .
                          "the prepublication structures and personal " .
                          "communications must be deposited by one of " .
                          "the authors" );
            }
        }
    }

    $deposition_authors = $options->{author_name} unless
        defined $deposition_authors;

    # Checking whether the pre-deposition/pres. comm. cifs have no
    # complete bibliography; if the do they should be deposited as
    # "published structures":

    if( $deposition_type eq 'personal' ) {
        for my $dataset (@$data) {
            my $values = $dataset->{values};
            if( !defined $values ) {
                critical( $cif_filename, $dataset->{name}, "WARNING",
                          "no data in datablock '$dataset->{name}'" );
            }
            if( (exists $values->{_journal_volume} ||
                 exists $values->{_journal_issue}) &&
                 exists $values->{_journal_year} &&
                 exists $values->{_journal_page_first} ) {
                critical( $cif_filename, $dataset->{name}, "WARNING",
                          "the data_$dataset->{name} datablock " .
                          "seems to have a complete bibliography " .
                          "(journal year, volume/issue and page) - " .
                          "it should then rather be deposited as " .
                          "a published structure, not as a personal " .
                          "communication" );
            }
        }
    }

    # Checking that all structures in the uploaded CIF are published
    # in the same journal, so that they can be assigned to the same
    # COD number range:

    if( $deposition_type eq 'published' ) {
        my ($range, $journal, $data_name);
        for my $dataset (@$data) {
            my $values = $dataset->{values};
            if( !defined $values ) {
                critical( $cif_filename, $dataset->{name}, "WARNING",
                          "no data in datablock '$dataset->{name}'" );
            }
            if( exists $values->{_journal_name_full} ) {
                if( !defined $range ) {
                    $journal = $values->{_journal_name_full}[0];
                    $range = select_COD_number_range( $journal,
                                                      $deposition_type );
                    $data_name = $dataset->{name};
                } else {
                    my $journal_now = $values->{_journal_name_full}[0];
                    my $range_now =
                        select_COD_number_range( $journal_now,
                                                 $deposition_type );
                    my $data_name_now = $dataset->{name};
                    if( $range_now ne $range ) {
                        critical( $cif_filename, undef, "WARNING",
                                  "journals '$journal' of " .
                                  "data_$data_name and '$journal_now' " .
                                  "of data_$data_name_now " .
                                  "indicate that the datablocks belong " .
                                  "to different COD number ranges, " .
                                  "please submit them as separate CIFs" );
                    }
                }
            }
        }
    }

    # Checking local COD tags: removing tags '_cod_database_code' and
    # '_cod_hold_until_date' in case they are not adequate, warning about
    # presence of '_cod_database_fobs_code' when Fobs file is not supplied:

    for my $dataset (@$data) {
        my $values = $dataset->{values};
        if( !$options->{replace} &&
            exists $values->{_cod_database_code} &&
            defined $values->{_cod_database_code}[0] ) {
            print_message( $0, $cif_filename, $dataset->{name}, "NOTE",
                           "tag '_cod_database_code' value '" .
                           $values->{_cod_database_code}[0] . "' " .
                           "will be overwritten upon deposition" );
        }
        if( $deposition_type ne 'prepublication' &&
            exists $values->{_cod_hold_until_date} &&
            defined $values->{_cod_hold_until_date}[0] ) {
            print_message( $0, $cif_filename, $dataset->{name}, "NOTE",
                           "tag '_cod_hold_until_date' value '" .
                           $values->{_cod_hold_until_date}[0] .
                           "' will be removed from '$cif_filename' " .
                           "upon deposition -- only prepublication " .
                           "CIF files can contain this tag" );
        }
        if( exists $values->{_cod_database_fobs_code} ) {
            if( !defined $hkl ) {
                critical( $cif_filename, $dataset->{name}, "WARNING",
                          "CIF file contains tag " .
                          "'_cod_database_fobs_code', but Fobs file " .
                          "is not supplied -- can not continue" );
            }
            if( !$options->{replace} &&
                defined $values->{_cod_database_fobs_code}[0] ) {
                    print_message( $0,
                                   $cif_filename,
                                   $dataset->{name},
                                   "NOTE",
                                   "tag '_cod_database_fobs_code' " .
                                   "value '" .
                                   $values->{_cod_database_fobs_code}[0] .
                                   "' will be overwritten upon " .
                                   "deposition" );
            }
        }
    }

    # Handle the uploaded HKL file

    my $hkl_now;
    if( defined $hkl ) {
        if( ref( $hkl ) eq 'ARRAY' ) {
            $hkl_now = join( "\n", @$hkl );
        } else {
            open( my $hkl_file_handle, $hkl );
            $hkl_now = join( "\n",
                             map {s/(\n|\r|\r\n)$//;$_} <$hkl_file_handle> );
            close( $hkl_file_handle );
        }
    }

    my $number_to_replace;
    if( $options->{replace} ) {

        # determining which cif file to replace, if any:
        if( @$data != 1 ) {
            critical( $cif_filename, undef, "WARNING",
                      "file supplied for replacement " .
                      "should have only one datablock" );
        }
        if( !exists $data->[0]{values}{'_cod_database_code'}[0]) {
            critical( $cif_filename, $data->[0]{name}, "WARNING",
                      "CIF file supplied for replacement " .
                      "should have \'_cod_database_code\' value " .
                      "determining which CIF file to replace" );
        }
        $number_to_replace = $data->[0]{values}{'_cod_database_code'}[0];
    } elsif ( !$options->{bypass_checks} ) {

        # check the COD for duplicates
        my $cif_cod_numbers_opt = { check_sample_history => 0 };
        $cif_cod_numbers_opt->{check_bibliography} = 0
            if $deposition_type eq 'personal';

        use CIFData::CIFCODNumbers;
        my $duplicates = CIFCODNumbers::fetch_duplicates( $data,
                                                          $cif_filename,
                                                          $db_conf,
                                                          $cif_cod_numbers_opt );
        my %duplicate_cod_entries;
        foreach my $dataset (@$duplicates) {
            next if scalar( keys %{$dataset->{duplicates}} ) == 0;
            foreach( keys %{$dataset->{duplicates}} ) {
                print_message( $0, $cif_filename, undef, "DUPLICATE",
                               "$dataset->{formula} is found in COD entry $_" );
                $duplicate_cod_entries{$_} = 1;
            }
        }
        if( keys %duplicate_cod_entries > 0 ) {
            critical( $cif_filename, undef, "DUPLICATE",
                      "file has (at least some) structures " .
                      "that have been deposited to COD previously in " .
                      "entries " .
                      join( ", ", sort keys %duplicate_cod_entries ) );
        }
    }

    my @journal_regexp = (
        [ 'Acta.*Cryst.*C', 'Acta Cryst. Section C' ],
        [ 'Acta.*Cryst.*B', 'Acta Cryst. Section B' ],
        [ 'Acta.*Cryst.*E', 'Acta Cryst. Section E' ],
        [ 'J.*Appl.*Cryst', 'J. Appl. Cryst.' ],
        [ 'Acta.*Cryst', 'Acta Crystallographica' ],
        [ 'Chem.*Mat', 'Chemmistry of Materials' ],
        [ 'J.*Org.*Chem', 'Journal of Organic Chemistry' ],
        [ 'Organometallics', 'Organometallics' ],
        [ 'Inorg.*Chem.*', 'Inorganic Chemistry' ],
        [ 'J.*Am.*Chem.*Soc|JACS', 'JACS' ],
        [ 'ACS.*', 'other ACS journals' ],
        [ 'Dalt.*Trans', 'Dalton Trans.' ],
        [ 'New.*J.*Chem', 'New Journal of Chemistry' ],
        [ 'Chem.*Comm', 'Chem. Comm.' ],
        [ 'Org.*Biomol.*Chem', 'Organic & Biomolecular Chemistry' ],
        [ 'RSC.*', 'other RSC journals' ],
        [ 'Chem.*Lett', 'Chemistry Letters' ],
        [ 'Zeitschr.*Krist', 'Zeitschrift fur Kristallographie' ],
    );

    my $journal;
    if( !$options->{replace} ) {
        if( $deposition_type eq 'personal' ) {
            $journal = 'Personal communications to COD';
        } elsif( $deposition_type eq 'prepublication' &&
                 $options->{journal} ) {
            my $new_journal = grep_journal_name( \@journal_regexp, 
                                                 $options->{journal} );
            if( $new_journal ) {
                $journal = $new_journal;
                print_message( $0, $cif_filename, undef, "NOTE",
                               "journal name was recognised as '$journal'" );
            } else {
                $journal = $options->{journal};
                print_message( $0, $cif_filename, undef, "NOTE",
                               "journal name '$journal' was not " .
                               "recognised, leaving as is" );
            }
        } elsif( $deposition_type eq 'published' ) {
            if( exists $data->[0]{values}{_journal_name_full} ) {
                $journal = $data->[0]{values}{_journal_name_full}[0];
            } else {
                print_message( $0, $cif_filename, undef, "NOTE",
                               "journal name is not defined in the " .
                               "first datablock of the published CIF " .
                               "'$cif_filename'" );
            }
        }
    } elsif( $deposition_type eq 'prepublication' &&
             exists $data->[0]{values}{_journal_name_full} &&
             $data->[0]{values}{_journal_name_full}[0] =~
                /^To be published in ([a-zA-Z0-9 _\-\.]+)$/ ) {
        $journal = $1;
    }

    use DBI;
    my $dbh = db_connect( $db_conf->{platform},
                          $db_conf->{host},
                          $db_conf->{name},
                          $db_conf->{port},
                          $db_conf->{user},
                          $db_conf->{password} );
    die "connection to database failed" if !$dbh;

    my $database_hold_until;
    if( $options->{replace} ) {

        # Asking the database whether old file exists

        my $sth = $dbh->prepare( "SELECT COUNT(*) " .
                                 "FROM data WHERE file = ?" );
        $sth->execute( $number_to_replace );

        if( $sth->fetchrow_arrayref()->[0] == 0 ) {
            critical( $cif_filename, undef, "ERROR",
                      "entry for structure $number_to_replace " .
                      "does not exist in the COD data table -- " .
                      "can not replace abscent structures" );
        }

        $sth = $dbh->prepare( "SELECT onhold FROM data WHERE file = ?" );
        $sth->execute( $number_to_replace );
        $database_hold_until = $sth->fetchrow_arrayref()->[0];

        if( $options->{release} ) {
            if( !defined $database_hold_until ) {
                critical( $cif_filename, undef, "ERROR",
                          "can not release structure that has been " .
                          "deposited not as prepublication material" );
            }
        }
    }

    my $year = `date +%Y`;
    $year =~ /(\d+)/;
    $year = $1;

    @filter_opt = ();
    if( $deposition_type eq 'prepublication' ) {
        @filter_opt = ( '--journal', (defined $journal)
                                        ? "To be published in $journal"
                                        : "To be published",
                        '--leave-title',
                        '--authors', $deposition_authors );
    }
    if( $deposition_type eq 'personal' ) {
        @filter_opt = ( '--journal', "Personal communication to COD",
                        '--year', $year,
                        '--authors', $deposition_authors,
                        '--leave-title',
                        '--dont-exclude-publication-details' );
    }

    my $datablock_nr = 0;
    my $data_source_nr = 0;

    for my $datablock (@$data) {
        my $values = $datablock->{values};
        next unless defined $values;
        $datablock_nr++;
        if( exists $values->{_cod_data_source_file} ||
            exists $values->{'_[local]_cod_data_source_file'} ) {
            $data_source_nr++;
        }
    }
    
    if( $data_source_nr > 0 && $data_source_nr != $datablock_nr ) {
        critical( $cif_filename, undef, "ERROR",
                  "only some data blocks in '$cif_filename' " .
                  "have _cod_data_source_file tags -- we can not " .
                  "determine the exact source of data; such CIFs " . 
                  "are not suitable for COD" );
    }

    if( $data_source_nr == 0 ) {
        push( @filter_opt, ( '--original-filename', $cif_filename ) );
    }

    ( $filter_stdout, $filter_stderr ) =
        run_command( [ 'cif_filter',
                           '--fold-title',
                           '--parse-formula-sum',
                       @filter_opt ], $correct_stdout );

    foreach( @$filter_stderr ) {
        my $parsed = parse_message( $_ );
        if( defined $parsed ) {
            next if $parsed->{message} =~ /tag .+ is not recognised/;
            $parsed->{errlevel} = 'NOTE' if !defined $parsed->{errlevel};
            print_message( $0,
                           $cif_filename,
                           $parsed->{datablock},
                           $parsed->{errlevel},
                           $parsed->{message},
                           $parsed->{line},
                           $parsed->{column} );
        }
    }
    if( @$filter_stdout == 0 ) {
        die "file '$cif_filename' became empty after filtering " .
            "with cif_filter";
    }

    if( $hkl && !$is_pdcif ) {
        my $hkl_parameters = extract_cif_values( $hkl_now,
                                                 $hkl_filename,
                                                 $tmp_file,
                                                 [ @CODPredepositionCheck::identity_tags,
                                                   '_pd_block_id' ] );

        # Determining whether this HKL describes data from single-crystal
        # or powder diffraction experiment. In the first case, HKL should
        # contain only one datablock and no tags named _pd_block_id.
        # Powder diffraction HKL file can contain more than one datablock
        # and one or more of them should have _pd_block_id tag.

        my %hkl_parameters;
        if( @$hkl_parameters == 1 &&
            !exists $hkl_parameters->[0]{_pd_block_id} ) {
            # We have single-crystal experiment HKL data
            %hkl_parameters = %{$hkl_parameters->[0]};
        } else {
            critical( $hkl_filename, undef, "ERROR",
                      "supplied HKL file has more than one " .
                      "datablock and does not describe data from " .
                      "powder diffraction experiment -- only " .
                      "powder diffraction HKL files can have more " .
                      "than one datablock" );
        }

        my $cif_parameters = extract_cif_values( $filter_stdout,
                                                 $cif_filename,
                                                 $tmp_file,
                                                 \@CODPredepositionCheck::identity_tags );

        my $cif_for_hkl =
            find_cif_datablock_for_hkl( $cif_parameters,
                                        \%hkl_parameters,
                                        \@CODPredepositionCheck::identity_tags,
                                        $cif_filename,
                                        $hkl_filename );

        # Record original file and block names

        if( !exists $hkl_parameters{'_[local]_cod_data_source_file'} &&
            !exists $hkl_parameters{'_[local]_cod_data_source_block'} ){
            $hkl_now =~ s/\n+$//s;
            $hkl_now .= "\n" .
                        "_[local]_cod_data_source_file '" .
                        $hkl_filename . "'\n" .
                        "_[local]_cod_data_source_block '" .
                        $hkl_parameters{name} . "'\n";
        }
    }

    # Test run for CIF2COD

    my( $cif2cod_stdout, $cif2cod_stderr ) = capture {
        CIF2COD::cif2cod( $data,
                          $cif_filename,
                          { continue_on_errors => 1 } );
    };

    C2CMESSAGE:
    foreach( split( "\n", $cif2cod_stderr ) ) {
        if( /[^: ]+: [^: ]+: tag '([^']+)' is absent/ ) {
            my $tag = $1;
            if( $deposition_type eq 'published' ) {
                next C2CMESSAGE if $tag eq '_journal_volume';
            } else {
                if( $tag eq '_publ_section_title' ||
                    $tag eq '_journal_name_full' ||
                    $tag eq '_journal_year' ||
                    $tag eq '_journal_volume' ||
                    $tag eq '_journal_page_first' ) {
                    next C2CMESSAGE;
                }
            }
        }
        print STDERR "$_\n";
    }

    my $cif_now = join( "\n", @$filter_stdout );
    if( $is_pdcif && !$options->{split_pdcif} ) {
        $cif_now = $cif_now . "\n" . $hkl_now;
        $hkl_now = undef;
    }

    return( $cif_now, $hkl_now );
}

# Run a command (using open3) with given command line parameters and
# data that come from a scalar variable or and array reference.
#
# Parameters:
#     - [ 'cmd', '--options', '-or', 'filenames', 'word', 'per', 'item' ... ]
#     - a scalar or an array reference with input data, to be piped
#       into the command's STDIN
# Returns:
#     - an array reference with the STDOUT contents,
#     - an array reference with the STDERR contents,
#     - a scalar with the command exit status.
sub run_command($@)
{
    my ($command, $input) = @_;

    use IO::Select;

    if( !ref $command ) {
        $command = [ $command ];
    }

    my ($stdin, $stdout, $stderr);
    $stderr = gensym();

    my $command_pid = open3( $stdin, $stdout, $stderr, @$command );

    # Make STDIN of the child process non-blocking so that we do not
    # block on long inputs:
    $stdin->blocking( 0 );
    $stdout->blocking( 0 );
    $stderr->blocking( 0 );

    if( defined $input ) {
        if( ref $input eq "" ) {
            $input = [ $input ];
        } elsif( ref $input ne "ARRAY" ) {
            die( "run_command() input is not a " .
                 "scalar or an array reference" );
        }
    } else {
        $input = [];
    }

    my ( $read_selector, $write_selector );
    $read_selector  = IO::Select->new();
    $read_selector->add( $stdout, $stderr );
    $write_selector = IO::Select->new();
    $write_selector->add( $stdin );

    my ( $output, $errors );

    my $input_text = join( "\n", @$input );
    if( $input_text ne "" ) {
        $input_text .= "\n";
    }
    my $input_length = length( $input_text );
    my $input_rest = $input_length;
    my $stdin_pos = 0;

    while( 1 ) {
        if( $read_selector->handles() == 0 &&
            $write_selector->handles() == 0 ) {
            last
        }
        my @list = IO::Select->select( $read_selector, $write_selector,
                                       undef, 1000 );

        if( ! @list ) {
            die( "execution of external script \'"
               . $$command[0] . "\' was timed out" );
        }

        if( @{ $list[1] } > 0 ) {
            my $written =
                syswrite( $stdin, $input_text, $input_rest, $stdin_pos );
            if( !defined $written ) {
                die( "syswrite() failed for external script " .
                     "'$$command[0]': $!" );
            }
            $stdin_pos += $written;
            $input_rest -= $written;
            use Carp::Assert;
            assert( $stdin_pos <= $input_length );
            if( $stdin_pos == $input_length ) {
                $write_selector->remove( $stdin );
                close( $stdin );
            }
        }
        foreach my $fh ( @{ $list[0] } ) {
            if( fileno( $fh ) == fileno( $stderr )) {
                my $numb_bytes_read =
                    sysread( $fh, $errors, 4028,
                             defined $errors ? length($errors) : 0 );
                if( !$numb_bytes_read ) { # $numb_bytes_read 0 or undef
                    $read_selector->remove( $fh );
                }
            } else {
                my $numb_bytes_read =
                    sysread( $fh, $output, 4028,
                             defined $output ? length($output) : 0 );
                if( !$numb_bytes_read ) { # $numb_bytes_read 0 or undef
                    $read_selector->remove( $fh );
                }
            }
         }
    }

    close $stdin;
    close $stdout;
    close $stderr;

    waitpid( $command_pid, 0 );

    my @output = defined $output ? split( "\n", $output ) : ();
    my @errors = defined $errors ? split( "\n", $errors ) : ();

    return( \@output, \@errors, $? );
}

# Function used to connect to database
sub db_connect
{
    my ($db_platform, $db_host, $db_name, $db_port, $db_user, $db_pass) = @_;
    my $dsn = "dbi:$db_platform:" .
              "hostname=$db_host;".
              "dbname=$db_name".
              ($db_port ? ";$db_port" : "");
    my $dbh = DBI->connect( $dsn, $db_user, $db_pass );
    if( !$dbh ) {
        die( "could not connect to the database - " . lcfirst( $DBI::errstr ));
    }
    if( $db_platform ne 'SQLite' ) {
        $dbh->do( "SET CHARACTER SET utf8" );
        $dbh->do( 'set @@character_set_client = utf8' );
        $dbh->do( 'set @@character_set_connection = utf8' );
        $dbh->do( 'set @@character_set_server = utf8' );
        $dbh->do( 'set @@character_set_database = utf8' );
    }
    return $dbh;
}

# Function to select COD number range from journal name
sub select_COD_number_range($$)
{
    my ($journal, $deposition_type ) = @_;
    my $range;

    if( $deposition_type eq "prepublication" ) {
        $range = "30";
    } elsif( $deposition_type eq "personal" ) {
        $range = "35";
    } else {
        for ( $journal ) {
            if( /Acta.*Cryst.*C/ ) {
                $range = "20";
                last;
            }
            if( /Acta.*Cryst.*B/ ) {
                $range = "21";
                last;
            }
            if( /Acta.*Cryst.*E/ ) {
                $range = "22";
                last;
            }
            if( /J.*Appl.*Cryst/i ) {
                $range = "230";
                last;
            }
            if( /Acta.*Cryst/i ) {
                $range = "231";
                last;
            }
            if( /Chem.*Mat/i ) {
                $range = "400";
                last;
            }
            if( /J.*Org.*Chem/i ) {
                $range = "402";
                last;
            }
            if( /Organometallics/i ) {
                $range = "406";
                last;
            }
            if( /Inorg.*Chem.*/i ) {
                $range = "430";
                last;
            }
            if( /J.*Am.*Chem.*Soc|JACS/i ) {
                $range = "41";
                last;
            }
            if( /ACS.*/i ) {
                $range = "45";
                last;
            }
            if( /Cryst.*Growth.*Des.*/i ) {
                $range = "45";
                last;
            }
            if( /Dalt.*Trans/i ) {
                $range = "700";
                last;
            }
            if( /New.*J.*Chem/i ) {
                $range = "705";
                last;
            }
            if( /Chem.*Comm/i ) {
                $range = "710";
                last;
            }
            if( /Org.*Biomol.*Chem/i ) {
                $range = "715";
                last;
            }
            if( /RSC|Cryst.*Eng.*Comm|Green.*Chem|J.*Mater.*Chem|Perkin.*Trans|Phys.*Chem.*Chem.* Phys.*/ix ) {
                $range = "72";
                last;
            }
            if( /Chem.*Lett/i ) {
                $range = "80";
                last;
            }
            if( /Zeitschr.*Krist/i ) {
                $range = "81";
                last;
            }
            if( $deposition_type eq "published" ) {
                $range = "1";
                # print_warning( "WARNING, journal name '$journal' " .
                #                "was not recognised, " .
                #                "defaulting to range '$range' " .
                #                "(other journals)" );
            } else {
                die( "could not assign COD number range " .
                     "for journal '$journal' and deposition type " .
                     "'$deposition_type'" );
            }
        }
    }
    return $range;
}

# Function to grep correct journal name using the array or regular expressions,
# performing the matching in descending array order
# Parameters:
#       -[ [ $regexp, $journal ], [ $regexp, $journal ], ... ]
#       -$value_of_journal_field
# Return:
#       -$correct_journal_name
sub grep_journal_name
{
    my ($journal_regexp, $journal) = @_;
    foreach (@$journal_regexp) {
        if ($journal =~ /${ $_ }[0]/i) {
            return ${ $_ }[1];
        }
    }
    return undef;
}

# Unpacks CIF number to the value that can be processed with Perl
# Parameters:
#       -- $cif_number
# Return:
#       -- $unpacked_number
#       -- $precision
sub unpack_cif_number
{
    my ($value) = @_;
    my $number_pos =
        '(?:\+?' .
        '(?:\d+(?:\.\d*)?|\.\d+))'; 
    my $number_neg =
        '(?:\-' .
        '(?:\d+(?:\.\d*)?|\.\d+))'; 
    my $exponent =
        '(?:[eE][-+]?\d+)';
    my $sigma =
        '(?:\(\d+\))';
    $value =~ /($number_pos|$number_neg)($exponent?)($sigma?)/;
    my ($number_part, $exponent_part, $sigma_part ) = ($1, $2, $3);
    $sigma_part =~ s/\((\d+)\)/$1/;
    $exponent_part =~ s/[eE]([-+]?\d+)/$1/;
    $exponent_part = 0 if $exponent_part eq "";
    $sigma_part = 0 if $sigma_part eq "";
    my $converted = 10 ** $exponent_part * $number_part;
    my $digits_after_period = 0;
    if( $number_part =~ /\.(\d+)$/ ) {
        $digits_after_period = length($1);
    }
    my $precision = $sigma_part / 10 ** $digits_after_period;
    return ($converted, $precision);
}

# Checks if two CIF format numbers are (possibly) equal.
# Parameters:
#       -- $first_cif_number
#       -- $second_cif_number
# Return:
#       -- 1 if numbers are equal, 0 otherwise
sub can_be_equal
{
    my ($x, $y) = @_;
    my @x = unpack_cif_number($x);
    my @y = unpack_cif_number($y);
    if( $x[1] == 0 && $y[1] == 0 ) {
        return $x[0] == $y[0];
    } elsif( $x[1] == 0 ) {
        return $x[0] > $y[0] - $y[1] && $x[0] < $y[0] + $y[1];
    } elsif( $y[1] == 0 ) {
        return $y[0] > $x[0] - $x[1] && $y[0] < $x[0] + $x[1];
    } elsif( $x[0] + $x[1] == $y[0] - $y[1] ||
             $y[0] + $y[1] == $x[0] - $x[1] ) {
        return 0; # Intervals are open (?)
    } else {
        my @edges = (   [ $x[0] - $x[1],  1 ],
                        [ $x[0] + $x[1], -1 ],
                        [ $y[0] - $y[1],  1 ],
                        [ $y[0] + $y[1], -1 ]  );
        my $open_intervals = 0;
        foreach( sort { $a->[0] <=> $b->[0] } @edges) {
            $open_intervals += $_->[1];
            if( $open_intervals > 1 ) { return 1; }
        }
    }
}

sub critical
{
    my( $file, $datablock, $level, $message ) = @_;
    print_message( $0, $file, $datablock, $level, $message );
    die $message;
}

sub extract_cif_values
{
    my( $file, $filename, $tmp_file, $tags ) = @_;
    
    my $separator  = '|';
    my $vseparator = '@';

    my $file_now;
    if( ref( $file ) eq 'ARRAY' ) {
        $file_now = $file;
    } else {
        $file_now = [ split( '\n', $file ) ];
    }

    # Using temporary file as input for 'cifvalues': printing input lines
    # to STDIN of 'cifvalues' causes broken pipe exception when input
    # size exceeds 65536 bytes. The reason is not investigated yet

    open( my $inp, ">", $tmp_file );
    print $inp join( "\n", @$file_now ) . "\n";
    close( $inp );

    my( $values_stdout, $values_stderr ) =
        run_command( [ 'cifvalues',
                           '--tag', join( ',', @$tags ),
                           '--separator', $separator,
                           '--vseparator', $vseparator,
                           $tmp_file ] );
    foreach( @$values_stderr ) {
        my $parsed = parse_message( $_ );
        if( defined $parsed ) {
            next if $parsed->{message} =~ /compiler could not recover from errors/;
            $parsed->{message} =~ s/:$//;
            print_message( $0,
               $filename,
               $parsed->{datablock},
               ($parsed->{errlevel} ? $parsed->{errlevel} : 'WARNING'),
               $parsed->{message},
               $parsed->{line},
               $parsed->{column} );
        } else {
            print STDERR "$_\n";
        }
    }
    die 'cifvalues encountered ' . @$values_stderr . ' ' .
        'warning(s)' if @$values_stderr > 0;

    my $data = [];
    my %seen_datanames;
    foreach( @$values_stdout ) {
        my @line = split( quotemeta( $separator ), $_ );
        my $dataname = shift @line;
        if( exists $seen_datanames{$dataname} ) {
            critical( $filename, undef, "ERROR",
                      "file contains more than one datablock " .
                      "named '$dataname' -- please use unique " .
                      "datablock names" );
        }
        my $values = { name => $dataname };
        for( my $i = 0; $i < @line; $i++ ) {
            next unless $line[$i] ne '?';
            $values->{$tags->[$i]} =
                [ split( quotemeta( $vseparator ), $line[$i] ) ];
        }
        push( @$data, $values );
    }

    return $data;
}

sub find_cif_datablock_for_hkl
{
    my( $cif_parameters, $hkl_parameters, $identity_tags,
        $cif_filename, $hkl_filename ) = @_;

    my %hkl_parameters = %$hkl_parameters;

    # Determining CIF datablock related to supplied HKL file

    my $hkl_dataname = $hkl_parameters{name};
    if( exists $hkl_parameters{'_[local]_cod_data_source_block'} ) {
        $hkl_dataname = $hkl_parameters{'_[local]_cod_data_source_block'}[0];
    }

    my $cif_for_hkl;
    for my $i (0..@$cif_parameters-1 ) {
        if( (exists $cif_parameters->[$i]{'_[local]_cod_data_source_block'} &&
             $cif_parameters->[$i]{'_[local]_cod_data_source_block'}[0] eq $hkl_dataname) ||
            (!exists $cif_parameters->[$i]{'_[local]_cod_data_source_block'} &&
             $cif_parameters->[$i]{name} eq $hkl_dataname ) ) {
            if( !defined $cif_for_hkl ) {
                $cif_for_hkl = $i;
                last;
            } else {
                critical( $cif_filename, undef, "ERROR",
                          "CIF file contains more than one datablock " .
                          "named $hkl_dataname?" );
            }
        }
    }
    if( !defined $cif_for_hkl ) {
        critical( $cif_filename, undef, "ERROR",
                  "could not relate supplied HKL file to any " .
                  "datablock from CIF file -- CIF datablock " .
                  "with name '$hkl_dataname' is not found" );
    }
    my %cif_parameters = %{ $cif_parameters->[$cif_for_hkl] };

    foreach my $tag ( @$identity_tags ) {
        next if $tag =~ /^_\[local\]_cod_data_source_(file|block)$/;
        if( exists $cif_parameters{$tag} && exists $hkl_parameters{$tag} ) {
            if( $tag =~ /_cell_/ ) {
                if( !can_be_equal(
                    $cif_parameters{$tag}->[0],
                    $hkl_parameters{$tag}->[0] ) ) {
                    critical( $cif_filename, undef, "ERROR",
                              "can not confirm relation " .
                              "between datablocks named '" . 
                              $hkl_dataname .
                              "' from supplied CIF and Fobs " .
                              "files -- values of tag '$tag' " .
                              "differ: '" .
                              $cif_parameters{$tag}->[0] .
                              "' (CIF) and '" .
                              $hkl_parameters{$tag}->[0] .
                              "' (Fobs)" );
                }
            } elsif( $tag eq '_publ_author_name' ) {
                my $cif_authors = lc( join( ';',
                    @{$cif_parameters{$tag}}));
                $cif_authors =~ s/\s//g;
                my $hkl_authors = lc( join( ';',
                    @{$hkl_parameters{$tag}} ) );
                $hkl_authors =~ s/\s//g;
                if( $cif_authors ne $hkl_authors ) {
                    critical( $cif_filename, undef, "ERROR",
                              "can not confirm relation " .
                              "between datablocks named '" . 
                              $hkl_dataname .
                              "' from supplied CIF and Fobs " .
                              "files -- publication author " .
                              "lists differ: '" .
                              join( ', ', map { "'$_'" }
                              @{$cif_parameters{$tag}} ) .
                              "' (CIF) and '" . join( ', ', map { "'$_'" }
                                @{$hkl_parameters{$tag}} ) .
                              "' (Fobs)" );
                }
            } else {
                if( $cif_parameters{$tag}->[0] ne
                    $hkl_parameters{$tag}->[0] ) {
                    critical( $cif_filename, undef, "ERROR",
                              "can not confirm relation " .
                              "between datablocks named '" .
                              $hkl_dataname .
                              "' from supplied CIF and Fobs " .
                              "files -- values of tag '$tag' " .
                              "differ: '" .
                              $cif_parameters{$tag}->[0] .
                              "' (CIF) and '" .
                              $hkl_parameters{$tag}->[0] .
                              "' (Fobs)" );
                }
            }
        }
    }
    return $cif_for_hkl;
}

sub can_bypass_checks
{
    my( $client_password, $host_pass_string ) = @_;
    my $host_password = $host_pass_string;
    if( $host_pass_string =~ /^(MD5|SHA1)\((.+)\)$/ ) {
        my $algorithm = $1;
        $host_password = $2;
        if( $algorithm eq 'MD5' ) {
            use Digest::MD5 qw/ md5_hex /;
            $client_password = Digest::MD5::md5_hex( $client_password );
        } elsif( $algorithm eq 'SHA1' ) {
            use Digest::SHA qw/ sha1_hex /;
            $client_password = Digest::SHA::sha1_hex( $client_password );
        } else {
            die "unknown hashing algorithm: $algorithm";
        }
    }
    if( defined $client_password && $client_password eq $host_password ) {
        return 1;
    } else {
        return 0;
    }
}

sub check_hold_period
{
    my( $deposition_type, $filename, $hold_period, $replace ) = @_;
    my $hold_period_now;
    if( $deposition_type eq 'prepublication' ) {
        # If it is an update and hold_period is not specified,
        # it should be left unchanged
        if( defined $hold_period ) {
            $hold_period_now = $hold_period;
            if( $hold_period > $CODPredepositionCheck::max_hold_period ) {
                critical( $filename, undef, "WARNING",
                         "hold period $hold_period_now months is too " .
                         "large -- only holds up to " .
                         $CODPredepositionCheck::max_hold_period .
                         " months are accepted" );
            }
        } else {
            if( !$replace ) {
                $hold_period_now =
                    $CODPredepositionCheck::default_hold_period;
                print_message( $0, $filename, undef, "NOTE",
                               "hold period not specified, " .
                               "(or specified incorrectly), " .
                               "defaulting to $hold_period_now " .
                               "months" );
            }
        }
    }
    return $hold_period_now;
}

sub comm_array
{
    my( $arr1, $arr2 ) = @_;
    my @arr1 = @$arr1;
    my @arr2 = @$arr2;
    my @comm;
    while( scalar( @arr1 ) + scalar( @arr2 ) > 0 ) {
        if( @arr1 == 0 ) {
            push( @comm, [ undef, undef, shift @arr2 ] );
            next;
        }
        if( @arr2 == 0 ) {
            push( @comm, [ shift @arr1, undef, undef ] );
            next;
        }
        if( $arr1[0] ne $arr2[0] ) {
            if( $arr1[0] lt $arr2[0] ) {
                push( @comm, [ shift @arr1, undef, undef ] );
            } else {
                push( @comm, [ undef, undef, shift @arr2 ] );
            }
        } else {
            push( @comm, [ undef, $arr1[0], undef ] );
            shift @arr1;
            shift @arr2;
        }
        next;
    }
    return \@comm;
}

1;
