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
use IPC::Open3 qw / open3 /;
use IO::Handle;
use Symbol;
use Unicode::Normalize;
use Unicode2CIF;
use Encode;

sub filter_and_check
{
    my( $cif, $hkl, $db_conf, $deposition_type, $options ) = @_;
    # Possible options:
    # -- bypass_checks
    # -- replace
    # -- release
    # -- hold_period
    # -- journal
    # -- use_c_parser (not implemented)
    # -- use_perl_parser (default)
    # -- author_name

    my( @errors, @warnings, @notes );

    my $original_cif_filename = $cif;
    my $original_hkl_filename = $hkl;

    use CIFParser;
    my $parser = new CIFParser;
    my $data = $parser->Run( $cif );

    # Checking whether names in pre-deposition CIFs and in personal
    # communication CIFs match the depositor name:

    my $deposition_authors;

    if( $deposition_type eq 'prepublication' ||
        $deposition_type eq 'personal' ) {
          DATASET:
        for my $dataset (@$data) {
            my $first_data_name;
            my $values = $dataset->{values};
            if( !defined $values ) {
                push( @errors,
                      "no data in datablock '$dataset->{name}'" );
                return( undef, undef, \@errors, \@warnings, \@notes );
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
                        push( @warnings,
                              "author list in the datablock " .
                              "data_$first_data_name ($deposition_authors) " .
                              "is no the same as in the datablock " .
                              "data_$data_name_now ($deposition_authors_now) - " .
                              "please make sure that all data are authored " .
                              "by the same people when depositing multiple " .
                              "data blocks" );
                        return( undef, undef, \@errors, \@warnings, \@notes );
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
                push( @warnings,
                      "submitting author '$options->{author_name}' " .
                      "does not match any author in the data_$dataset->{name} " .
                      "author list (" . join( ', ', map { "'$_'" }
                      @{$values->{_publ_author_name}}) . ") - will not " .
                      "deposit the structure, the prepublication structures " .
                      "and personal communications " .
                      "must be deposited by one of the authors" );
                return( undef, undef, \@errors, \@warnings, \@notes );
            }
        }
    }

    $deposition_authors = $options->{author_name} unless
        defined $deposition_authors;

    # Checking whether the pre-deposition/pres. comm. cifs have no
    # complete bibliography; if the do they should be deposited as
    # "published structures":

    if( $deposition_type eq 'published' ) {
        my ($range, $journal, $data_name);
        for my $dataset (@$data) {
            my $values = $dataset->{values};
            if( !defined $values ) {
                push( @errors,
                      "no data in datablock '$dataset->{name}'" );
                return( undef, undef, \@errors, \@warnings, \@notes );
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
                        push( @warnings,
                              "journals '$journal' of data_$data_name " .
                              "and '$journal_now' of data_$data_name_now " .
                              "indicate that the datablocks belong " .
                              "to different COD number ranges, please " .
                              "submit them as separate CIFs" );
                    }
                }
            }
        }
    }

    # Handle the uploaded HKL file

    my $hkl_now;
    if( defined $hkl ) {
        fopen( my $hkl_file_handle, $hkl );
        $hkl_now = join( "\n",
                         map {s/(\n|\r|\r\n)$//;$_} <$hkl_file_handle> );
        fclose( $hkl_file_handle );
    }

    my $number_to_replace;
    if( $options->{replace} ) {

        # determining which cif file to replace, if any:
        if( @$data != 1 ) {
            push( @warnings, "file supplied for replacement "
                           . "should have only one datablock" );
            return( undef, undef, \@errors, \@warnings, \@notes );
        }
        if( !exists $data->[0]{values}{'_cod_database_code'}[0]) {
            push( @warnings, "CIF file supplied for replacement "
                . "should have \'_cod_database_code\' value "
                . "determining which cif file to replace" );
            return( undef, undef, \@errors, \@warnings, \@notes );
        }
        $number_to_replace = $data->[0]{values}{'_cod_database_code'}[0];
    } elsif ( !$options->{bypass_checks} ) {

        # check the COD for duplicates
        my $cif_cod_numbers_opt = { check_sample_history => 0 };
        $cif_cod_numbers_opt->{check_bibliography} = 0
            if $deposition_type eq 'personal';

        use CIFCODNumbers;
        my $duplicates = fetch_duplicates( $data,
                                           $cif,
                                           $db_conf,
                                           $cif_cod_numbers_opt );
        foreach my $dataset (@$duplicates) {
            next if scalar( keys %{$dataset->{duplicates}} ) == 0;
            push( @warnings, map( "DUPLICATE: $dataset->{formula} " .
                                  "is found in COD entry $_",
                                  keys %{$dataset->{duplicates}} ) );
        }
        if( @warnings > 0 ) {
            return( undef, undef, \@errors, \@warnings, \@notes );
        }
    }

    my( $correct_stdout, $correct_stderr ) =
        run_command( 'cif_correct_tags', $cif );

    if( @$correct_stderr > 0 ) {
        @warnings = @$correct_stderr;
        return( undef, undef, \@errors, \@warnings, \@notes );
    }

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
            my %ccc_warnings = (
                'published'         => undef,
                'prepublication'    => ': ((?:_journal_name_full|'
                    . '_publ_author_name) is undefined|'
                    . 'neither _journal_(?:year nor _journal_volume|'
                    . 'page_first nor _journal_article_reference) is defined|'
                    . 'WARNING.*|NOTE.*)',
                'personal'          => ': ((?:_journal_name_full|'
                    . '_publ_author_name) is undefined|'
                    . 'neither _journal_(?:year nor _journal_volume|'
                    . 'page_first nor _journal_article_reference) is defined|'
                    . 'WARNING.*|NOTE.*)',
            );
            foreach( @$ccc_stdout ) {
                if( /$ccc_warnings{$deposition_type}\n?/ ) {
                    push( @warnings, $_ );
                } else {
                    push( @errors, $_ );
                }
            }
            if( @errors > 0 ) {
                return( join( "\n", @$correct_stdout ), $hkl_now,
                        \@errors, \@warnings, \@notes );
            }
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
                push( @notes,
                      "journal name was recognised as '$journal'" );
            } else {
                $journal = $options->{journal};
                push( @notes,
                      "journal name '$journal' was not recognised, " .
                      "leaving as is" );
            }
        } elsif( $deposition_type eq 'published' ) {
            if( exists $data->[0]{values}{_journal_name_full} ) {
                $journal = $data->[0]{values}{_journal_name_full}[0];
            } else {
                push( @warnings,
                      "journal name is not defined in the " .
                      "first datablock of the published CIF " .
                      "'$cif'" );
            }
        }
    }

    use DBI;
    my $dbh = db_connect( $db_conf->{platform},
                          $db_conf->{host},
                          $db_conf->{name},
                          $db_conf->{port},
                          $db_conf->{user},
                          $db_conf->{password} );
    if( !$dbh ) {
        die( "connection to database failed" );
    }

    my $database_hold_until;
    if( $options->{replace} ) {

        # Asking the database whether old file exists

        my $sth = $dbh->prepare( "SELECT COUNT(*) " .
                                 "FROM data WHERE file = ?" );
        $sth->execute( $number_to_replace );

        if( $sth->fetchrow_arrayref()->[0] == 0 ) {
            push( @warnings,
                  "entry for structure $number_to_replace " .
                  "does not exist in the COD data table -- " .
                  "can not replace abscent structures" );
            return( join( "\n", @$correct_stdout ), $hkl_now,
                    \@errors, \@warnings, \@notes );
        }

        $sth = $dbh->prepare( "SELECT onhold FROM data WHERE file = ?" );
        $sth->execute( $number_to_replace );
        $database_hold_until = $sth->fetchrow_arrayref()->[0];

        if( $options->{release} ) {
            if( !defined $database_hold_until ) {
                push( @warnings,
                      "can not release structure that has been deposited " .
                      "not as prepublication material" );
                return( join( "\n", @$correct_stdout ), $hkl_now,
                        \@errors, \@warnings, \@notes );
            }
        }
    }

    # Calculating the date for holding on the structure

    my $hold_until;
    if( $deposition_type eq 'prepublication' ) {
        if( $options->{replace} ) {
            if( !$options->{hold_period} ) {
                $hold_until = $database_hold_until;
            } else {
                my @hold_date = split( "-", $database_hold_until );
                $hold_date[1] += $options->{hold_period};
                while( $hold_date[1] > 12 ) {
                    $hold_date[1] -= 12;
                    $hold_date[0]++;
                }
                $hold_until = sprintf( "%04d-%02d-%02d",
                                       $hold_date[0],
                                       $hold_date[1],
                                       $hold_date[2] );
            }
        } else {
            my @now_date = localtime( time() );
            my( $year, $month, $day ) = ( $now_date[5] + 1900,
                                          $now_date[4],
                                          $now_date[3] );
            $month += $options->{hold_period};
            while( $month > 12 ) {
                $month -= 12;
                $year++;
            }
            $hold_until = sprintf( "%04d-%02d-%02d",
                                   $year,
                                   $month,
                                   $day );
        }
        push( @$correct_stdout, "_cod_hold_until_date $hold_until" );
    }

    my $year = `date +%Y`;
    $year =~ /(\d+)/;
    $year = $1;

    my @filter_opt;
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
        push( @warnings,
              "only some data blocks in '$cif' have " .
              "_cod_data_source_file tags - we can not determine the " .
              "exact source of data; such CIFs are not suitable for COD" );
    }

    if( $data_source_nr == 0 ) {
        push( @filter_opt,
              ( '--original-filename', $cif ) );
    }

    my( $filter_stdout, $filter_stderr ) =
        run_command( [ 'cif_filter',
                           '--fold-title',
                           '--parse-formula-sum',
                       @filter_opt ], $correct_stdout );

    foreach( @$filter_stderr ) {
        if( /: tag '.*' is not recognised$/ ) {
            push( @warnings, $_ );
        } else {
            push( @errors, $_ );
        }
    }
    if( @errors > 0 ) {
        return( join( "\n", @$filter_stdout ), $hkl_now,
                \@errors, \@warnings, \@notes );
    }

    my $is_pd_hkl;
    if( $hkl ) {

        # Enumerating tags for later matching between datablocks of uploaded
        # CIF and HKL files

        my @identity_tags = qw(
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

        my $separator  = '|';
        my $vseparator = '@';

        # Taking values from HKL file for later checks

        my @hkl_identity_tags = ( @identity_tags, '_pd_block_id' );
        my( $values_stdout, $values_stderr ) =
            run_command( [ 'cifvalues',
                               '--tag', join( ',', @hkl_identity_tags ),
                               '--separator', $separator,
                               '--vseparator', $vseparator ],
                         [ split( '\n', $hkl_now ) ] );
        push( @warnings, @$values_stderr );
        if( @warnings > 0 ) {
            return( join( "\n", @$filter_stdout ), $hkl_now,
                \@errors, \@warnings, \@notes );
        }

        # Extracting data from cifvalues output

        my %hkl_values;
        foreach( @$values_stdout ) {
            my @line = split( quotemeta( $separator ), $_ );
            my $dataname = $line[0];
            if( $line[11] ne '?' ) { $dataname = $line[11]; }
            if( exists $hkl_values{$dataname} ) {
                push( @warnings,
                      "HKL file contains more than one datablock " .
                      "named '" . $dataname . "', please use " .
                      "unique datablock names" );
                return( join( "\n", @$filter_stdout ), $hkl_now,
                    \@errors, \@warnings, \@notes );
            }
            $hkl_values{$dataname} = {};
            for( my $i = 1; $i < @line; $i++ ) {
                next unless $line[$i] ne '?';
                $hkl_values{$dataname}->{$hkl_identity_tags[$i-1]} =
                    [ split( quotemeta( $vseparator ), $line[$i] ) ];
            }
        }
        
        # Determining whether this HKL describes data from single-crystal
        # or powder diffraction experiment. In the first case, HKL should
        # contain only one datablock and no tags named _pd_block_id.
        # Powder diffraction HKL file can contain more than one datablock
        # and one or more of them should have _pd_block_id tag.

        $is_pd_hkl = 0;
        my %hkl_parameters;
        if( keys %hkl_values == 1 && 
            !exists $hkl_values{(keys %hkl_values)[0]}->{_pd_block_id} ) {
            # We have single-crystal experiment HKL data
            %hkl_parameters = %{$hkl_values{(keys %hkl_values)[0]}};
            $hkl_parameters{name} = (keys %hkl_values)[0];
        } else {
            foreach( keys  %hkl_values ) {
                if( exists $hkl_values{$_}->{_pd_block_id} ) {
                    $is_pd_hkl = 1;
                    last;
                }
            }
            if( $is_pd_hkl ) {
                # We have powder diffraction experiment HKL data
                # To be done later:
                push( @errors,
                      "powder diffraction experiment HKL files can not be " .
                      "processed now - this function is not implemented yet" );
            } else {
                push( @errors,
                      "supplied HKL file has more than one datablock and " .
                      "and does not describe data from powder diffraction " .
                      "experiment - only powder diffraction HKL files can " .
                      "have more than one datablock" );
            }
            return( join( "\n", @$filter_stdout ), $hkl_now,
                \@errors, \@warnings, \@notes );
        }

        ( $values_stdout, $values_stderr ) =
            run_command( [ 'cifvalues',
                                '--tag', join( ',', @identity_tags ),
                                '--separator', $separator,
                                '--vseparator', $vseparator ],
                            $filter_stdout );

        # Extracting data from cifvalues output

        my %cif_parameters;
        foreach( @$values_stdout ) {
            my @line = split( quotemeta( $separator ), $_ );
            my $dataname = $line[1];
            if( $line[11] ne '?' ) { $dataname = $line[11]; }
            if( exists $cif_parameters{$dataname} ) {
                push( @warnings,
                      "CIF file contains more than one datablock " .
                      "named '" . $dataname . "', please use " .
                      "unique datablock names" );
                return( join( "\n", @$filter_stdout ), $hkl_now,
                    \@errors, \@warnings, \@notes );
            }
            $cif_parameters{$dataname} = {};
            $cif_parameters{$dataname}->{name} = $line[0];
            for( my $i = 1; $i < @line; $i++ ) {
                next unless $line[$i] ne '?';
                $cif_parameters{$dataname}->{$identity_tags[$i-1]} =
                    [ split( quotemeta( $vseparator ), $line[$i] ) ];
            }
        }

        # Determining CIF datablock related to supplied HKL file

        my $cif_for_hkl;
        if( exists $cif_parameters{$hkl_parameters{name}} ) {
            $cif_parameters{$hkl_parameters{name}}->{name} =~ /(\d{7})/;
            $cif_for_hkl = $1;           
            foreach my $tag ( @identity_tags ) {
                next if $tag =~ /^_\[local\]_cod_data_source_(file|block)$/;
                if( exists $cif_parameters{$hkl_parameters{name}}->{$tag} &&
                    exists $hkl_parameters{$tag} ) {
                    if( $tag =~ /_cell_/ ) {
                        if( !can_be_equal(
                            $cif_parameters{$hkl_parameters{name}}->{$tag}[0],
                            $hkl_parameters{$tag}->[0] ) ) {
                            push( @warnings,
                                  "can not confirm relation " .
                                  "between datablocks named '" . 
                                  $hkl_parameters{name} .
                                  "' from supplied CIF and Fobs files - values " .
                                  "of tag '$tag' differ: '" .
                                  $cif_parameters{$hkl_parameters{name}}->{$tag}[0] .
                                  "' (CIF) and '" .
                                  $hkl_parameters{$tag}->[0] .
                                  "' (Fobs)" );
                            return( join( "\n", @$filter_stdout ), $hkl_now,
                                    \@errors, \@warnings, \@notes );
                        }
                    } elsif( $tag eq '_publ_author_name' ) {
                        my $cif_authors = lc( join( ';',
                            @{$cif_parameters{$hkl_parameters{name}}->{$tag}}));
                        $cif_authors =~ s/\s//g;
                        my $hkl_authors = lc( join( ';',
                            @{$hkl_parameters{$tag}} ) );
                        $hkl_authors =~ s/\s//g;
                        if( $cif_authors ne $hkl_authors ) {
                            push( @warnings,
                                  "can not confirm relation " .
                                  "between datablocks named '" . 
                                  $hkl_parameters{name} .
                                  "' from supplied CIF and Fobs files - " .
                                  "publication author lists differ: '" .
                                  join( ', ', map { "'$_'" }
                                      @{$cif_parameters{$hkl_parameters{name}}->{$tag}} ) .
                                  "' (CIF) and '" . join( ', ', map { "'$_'" }
                                      @{$hkl_parameters{$tag}} ) .
                                  "' (Fobs)" );
                            return( join( "\n", @$filter_stdout ), $hkl_now,
                                    \@errors, \@warnings, \@notes );
                        }
                    } else {
                        if( $cif_parameters{$hkl_parameters{name}}->{$tag}[0] ne
                            $hkl_parameters{$tag}->[0] ) {
                            push( @warnings,
                                  "can not confirm relation " .
                                  "between datablocks named '" .
                                  $hkl_parameters{name} .
                                  "' from supplied CIF and Fobs files - values " .
                                  "of tag '$tag' differ: '" .
                                  $cif_parameters{$hkl_parameters{name}}->{$tag}[0] .
                                  "' (CIF) and '" .
                                  $hkl_parameters{$tag}->[0] .
                                  "' (Fobs)" );
                            return( join( "\n", @$filter_stdout ), $hkl_now,
                                    \@errors, \@warnings, \@notes );
                        }
                    }
                }
            }
        } else {
            push( @warnings,
                  "could not relate supplied HKL file to any " .
                  " datablock from CIF file - CIF datablock with name '" .
                  $hkl_parameters{name} . "' is not found" );
            return( join( "\n", @$filter_stdout ), $hkl_now,
                \@errors, \@warnings, \@notes );
        }
        if( $cif_for_hkl ) {

            # Write HKL contents to file, change the datablock name and
            # record original file and block names

            if( !$is_pd_hkl &&
                !exists $hkl_parameters{'_[local]_cod_data_source_file'} &&
                !exists $hkl_parameters{'_[local]_cod_data_source_block'} ){
                $hkl_now =~ s/\n$//;
                $hkl_now .= '\n' .
                            "_[local]_cod_data_source_file '" .
                            $original_hkl_filename . "'\n" .
                            "_[local]_cod_data_source_block '" .
                            $hkl_parameters{name} . "'\n";
            }
        }
    }

    # Execution of cif2cod script

    my( $cif2cod_stdout, $cif2cod_stderr) =
        run_command( [ 'cif2cod',
                            '--print-header',
                            '--keywords',
                            '--continue-on-errors' ],
                     $filter_stdout );

    my %cif2cod_warnings = (
        'published'         => "tag '_journal_volume' is absent",
        'prepublication'    => ': tag \'_(?:publ_section_title|journal_'
            . '(?:name_full|year|volume|page_first))\''
            . ' is absent',
        'personal'          => ': tag \'_(?:publ_section_title|journal_'
            . '(?:name_full|year|volume|page_first))\''
            . ' is absent',
    );

    foreach( @$cif2cod_stderr ) {
        if( /$cif2cod_warnings{$deposition_type}/ ) {
            push( @warnings, $_ );
        } else {
            push( @errors, $_ );
        }
    }
    if( @errors > 0 ) {
        return( join( "\n", @$filter_stdout ), $hkl_now,
                \@errors, \@warnings, \@notes );
    }

    # Generating placeholder files for prepublication material

    if( $deposition_type eq 'prepublication' ) {
        my @exported_fields = qw(
            _publ_author_name
            _publ_section_title
            _journal_name_full
            _journal_volume
            _journal_page_first
            _journal_page_last
            _diffrn_ambient_temperature
            _cell_measurement_temperature
            _diffrn_ambient_pressure
            _cell_measurement_pressure
            _chemical_name_systematic
            _chemical_name_common
            _chemical_name_mineral
            _chemical_formula_sum
            
            _cell_length_a
            _cell_length_b
            _cell_length_c
            _cell_angle_alpha
            _cell_angle_beta
            _cell_angle_gamma

            _cell_volume
            _exptl_crystal_thermal_history
            _exptl_crystal_pressure_history
            
            _refine_ls_R_factor_all
            _refine_ls_R_factor_gt
            _refine_ls_R_factor_obs
            _refine_ls_R_factor_ref
            _refine_ls_R_Fsqd_factor
            _refine_ls_R_I_factor
            _refine_ls_wR_factor_all
            _refine_ls_wR_factor_gt
            _refine_ls_wR_factor_obs
            _refine_ls_wR_factor_ref
            _refine_ls_goodness_of_fit_all
            _refine_ls_goodness_of_fit_ref
            _refine_ls_goodness_of_fit_gt
            _refine_ls_goodness_of_fit_obs

            _cod_hold_until_date
        );

        my( $cifselect_stdout, $cifselect_stderr ) =
            run_command( [ 'cif_select',
                                '--tags', join( ",", @exported_fields ) ],
                         $filter_stdout );
        push( @errors, @$cifselect_stderr );
        if( @errors > 0 ) {
            return( join( "\n", @$filter_stdout ), $hkl_now,
                \@errors, \@warnings, \@notes );
        }
    }

    return( join( "\n", @$filter_stdout ), $hkl_now,
            \@errors, \@warnings, \@notes );
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
    my $dsn = "dbi:$db_platform:$db_name:$db_host:$db_port";
    my $dbh = DBI->connect( $dsn, $db_user, $db_pass );
    if( !$dbh ) {
    die( "could not connect to the database - " . lcfirst( $DBI::errstr ));
    }
    $dbh->do( "SET CHARACTER SET utf8" );
    $dbh->do( 'set @@character_set_client = utf8' );
    $dbh->do( 'set @@character_set_connection = utf8' );
    $dbh->do( 'set @@character_set_server = utf8' );
    $dbh->do( 'set @@character_set_database = utf8' );
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

1;
