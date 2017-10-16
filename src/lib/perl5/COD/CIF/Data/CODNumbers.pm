#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Find COD numbers of duplicate structures.
#**

package COD::CIF::Data::CODNumbers;

use strict;
use warnings;
use File::Basename qw( basename );
use COD::Formulae::Parser::AdHoc;
use COD::CIF::Data::CellContents qw( cif_cell_contents );
use COD::Precision qw( eqsig );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    fetch_duplicates
    fetch_duplicates_from_database
    cif_fill_data
    entries_are_the_same
);

my %has_numeric_value = (
    "_journal_year"   => 1,
    "_journal_volume" => 1,
    "_journal_issue"  => 1,
);

my %skip_tag = (
    "_journal_name_full" => 0,
);

my %default_options = (
    'max_cell_length_diff'  => 0.5, # Angstroems
    'max_cell_angle_diff'   => 1.2, # degrees
    'check_bibliography'    => 1,
    'check_sample_history'  => 0,
    'check_compound_source' => 0,
    'ignore_sigma'          => 0,
    'cod_series_prefix'     => ''
);

##
# Queries the database and returns a list of duplicates for each of the
# provided crystal structure descriptions.
#
# @param $structures
#       Reference to a hash of crystal structure descriptions as returned by
#       the 'cif_fill_data()' subroutine.
# @param $database
#       Reference to a hash of database parameters as described in the
#       'database_connect()' subroutine description. Currently, this
#       subroutine only uses the 'table' hash entry.
# @param $dbh
#       Database handle that will be used to carry out the queries as
#       returned by 'the database_connect()' subroutine.
# @param $user_options
#       Reference to a hash containing the options that will be passed to
#       the 'query_COD_database()' and 'entries_are_the_same()' subroutines.
# @return $duplicates
#       Reference to an array containing the following hash structure
#       for each of the crystal structure descriptions:
#       {
#         # The hash key of the crystal structure description in the
#         # $structures hash
#           'datablock'  => 'water'
#         # The chemical formula that is shared by the provided crystal
#         # structure description and its duplicate entries in the database
#           'formula'    => 'H2 O',
#         # A hash of crystal structure entries located in the database.
#         # Each duplicate entry is identified by its database ID (i.e. COD ID)
#         # and described by a data structure as returned by the
#         # 'query_COD_database()' subroutine:
#           'duplicates' =>
#               {
#                 '1100003' =>
#                  {
#                    'id'           => '1100003',
#                    'filename'     => '1100003',
#                    'bibliography' => { ... },
#                    'cell'         => { ... },
#                    'sigcell'      => { ... },
#                    'pressure'     => { ... },
#                    'temperature'  => { ... },
#                    'history'      => { ... },
#                    'source'       => { ... },
#                    ...
#                  },
#                  ...
#               }
#           }
##
sub fetch_duplicates_from_database
{
    my( $structures, $database, $dbh, $user_options ) = @_;

    $user_options = {} unless defined $user_options;
    my %options;
    foreach my $key (keys %default_options) {
        $options{$key} = defined $user_options->{$key} ?
                                 $user_options->{$key} :
                                 $default_options{$key};
    };

    my %structures = %{$structures};

    my %COD = ();

    query_COD_database( $dbh, $database, \%COD, \%structures, \%options );

    my @duplicates;
    for my $id (sort { $structures{$a}->{index} <=>
                       $structures{$b}->{index} } keys %structures) {
        my $formula = $structures{$id}{chemical_formula_sum};
        my $calc_formula = $structures{$id}{calc_formula};
        my $cell_formula = $structures{$id}{cell_formula};

        my $final_formula;
        if( defined $formula ) {
            $final_formula = $formula;
        } elsif( defined $calc_formula ) {
            $final_formula = $calc_formula;
        } elsif( defined $cell_formula ) {
            $final_formula = $cell_formula;
        } else {
            $final_formula = '?';
        }

        $final_formula =~ s/\s/_/g;

        my %structures_found = ();

        if( defined $formula && defined $COD{$formula} ) {
            for my $COD_entry (@{$COD{$formula}}) {
                if( entries_are_the_same( $structures{$id},
                                          $COD_entry,
                                          \%options )) {
                    my $COD_key = $COD_entry->{filename};
                    $structures_found{$COD_key} = $COD_entry;
                }
            }
        }
        if( defined $calc_formula && defined $COD{$calc_formula} &&
            ( !defined $formula || $formula ne $calc_formula )) {
            ## print ">>> formula: '$formula', contents: '$calc_formula'\n";
            for my $COD_entry (@{$COD{$calc_formula}}) {
                if( entries_are_the_same( $structures{$id},
                                          $COD_entry,
                                          \%options )) {
                    my $COD_key = $COD_entry->{filename};
                    if( !exists $structures_found{$COD_key} ) {
                        $structures_found{$COD_key} = $COD_entry;
                    }
                }
            }
        }
        if( defined $cell_formula && defined $COD{$cell_formula} &&
            ( !defined $calc_formula || $calc_formula ne $cell_formula ) ) {
            for my $COD_entry (@{$COD{$cell_formula}}) {
                if( entries_are_the_same( $structures{$id},
                                          $COD_entry,
                                          \%options )) {
                    my $COD_key = $COD_entry->{filename};
                    if( !exists $structures_found{$COD_key} ) {
                        $structures_found{$COD_key} = $COD_entry;
                    }
                }
            }
        }

        push( @duplicates,
                { formula => $final_formula,
                  datablock => $structures{$id},
                  duplicates => \%structures_found } );
    }

    return \@duplicates;
}

# Wrapper for fetch_duplicates_from_database(), pre-creating database
# connection from database credential hash
# Parameters:
#   --  hash of data blocks
#   --  hash of database parameters, i.e.:
#       { host  => "www.crystallography.net",
#         user  => "cod_reader",
#         name  => "cod",
#         table => "data",
#         password => "" }
#   --  options
# Return: same as fetch_duplicates_from_database()

sub fetch_duplicates
{
    my( $structures, $database, $options ) = @_;
    my $dbh = database_connect( $database );
    my $duplicates = fetch_duplicates_from_database( $structures,
                                                     $database,
                                                     $dbh,
                                                     $options );
    database_disconnect( $dbh );
    return $duplicates;
}

#------------------------------------------------------------------------------

sub cif_fill_data
{
    my ( $dataset, $file, $index ) = @_;

    my %structure;

    my $values = $dataset->{values};
    my $sigmas = $dataset->{precisions};
    my $id = $dataset->{name};

    return undef if !defined $id;
    $structure{id} = $id;
    $structure{filename} = basename( $file );
    $structure{index} = $index;

    if( defined $values->{_chemical_formula_sum} ) {
        my $formula = $values->{_chemical_formula_sum}[0];

        if( $formula ne '?' ) {

            $formula =~ s/^\s*'\s*|\s*'\s*$//g;
            $formula =~ s/^\s*|\s*$//g;
            $formula =~ s/\s+/ /g;

            my $formula_parser = new COD::Formulae::Parser::AdHoc;

            eval {
                $formula_parser->ParseString( $formula );
                if( defined $formula_parser->YYData->{ERRCOUNT} &&
                    $formula_parser->YYData->{ERRCOUNT} > 0 ) {
                    die "ERROR, $formula_parser->YYData->{ERRCOUNT} "
                      . "error(s) encountered while parsing chemical "
                      . "formula sum\n";
                    ;
                } else {
                    $formula = $formula_parser->SprintFormula;
                }
            };
            if( $@ ) {
                warn "WARNING, could not parse formula '$formula' "
                   . "resorting to simple split routine\n";
                $formula = join( " ", sort {$a cmp $b} split( " ", $formula ));
            }
        }
            $structure{chemical_formula_sum} = $formula;
    }

    my $calc_formula;
    eval {
        $calc_formula = cif_cell_contents( $dataset, undef );
    };
    if ($@) {
        # ERRORs that originated within the function are downgraded to warnings
        my $error = $@;
        $error =~ s/[A-Z]+, //;
        chomp($error);
        warn "WARNING, summary formula could not be calculated -- $error\n";
    };
    $structure{calc_formula} = $calc_formula
        if defined $calc_formula;


    my $cell_formula;
    eval {
        $cell_formula = cif_cell_contents( $dataset, 1 );
    };
    if ($@) {
        # ERRORs that originated within the function are downgraded to warnings
        my $error = $@;
        $error =~ s/[A-Z]+, //;
        chomp($error);
        warn "WARNING, unit cell summary formula could not be calculated -- $error\n";
    };
    $structure{cell_formula} = $cell_formula
        if defined $cell_formula;

    for my $key ( qw( _cell_length_a _cell_length_b _cell_length_c
                      _cell_angle_alpha _cell_angle_beta _cell_angle_gamma )) {
        my $val = $values->{$key}[0];
        if( defined $val ) {
            $val =~ s/^\s*'\s*|\s*'\s*$//g;
            $val =~ s/\(.*$//;
            $val =~ s/[()_a-zA-Z]//g;
            $structure{cell}{$key} = sprintf "%f", $val;
        }
    }
    for my $key ( qw( _cell_length_a _cell_length_b _cell_length_c
                      _cell_angle_alpha _cell_angle_beta _cell_angle_gamma )) {
        if( exists $sigmas->{$key} ) {
            my $val = $sigmas->{$key}[0];
            $structure{sigcell}{$key} = $val;
        }
    }
    for my $key ( qw( _cell_measurement_temperature
                       _cell_measurement_temperature_C
                       _diffrn_ambient_temperature
                       _diffrn_ambient_temperature_C
                       _diffrn_ambient_temperature_gt
                       _diffrn_ambient_temperature_lt
                       _pd_prep_temperature
                       _cell_measurement_pressure
                       _cell_measurement_pressure_gPa
                       _cell_wave_vectors_pressure_max
                       _cell_wave_vectors_pressure_min
                       _diffrn_ambient_pressure
                       _diffrn.ambient_pressure
                       _diffrn.ambient_pressure_esd
                       _diffrn_ambient_pressure_gPa
                       _diffrn_ambient_pressure_gt
                       _diffrn.ambient_pressure_gt
                       _diffrn_ambient_pressure_lt
                       _diffrn.ambient_pressure_lt
                       _exptl_crystal_pressure_history
                       _exptl_crystal_thermal_history
                       _pd_prep_pressure )) {
       if( exists $values->{$key} ) {
           my $val = $values->{$key}[0];
           if( defined $val ) {
               my $parameter;
               if( $key =~ /history/ ) {
                   $parameter = "history";
               } elsif( $key =~ /pressure/ ) {
                   $parameter = "pressure";
               } else {
                   $parameter = "temperature";
               }
               $structure{$parameter}{$key} = $val;
               $structure{$parameter}{$key}
                   =~ s/^\s*'\s*|\s*'\s*$//g;
            }
        }
    }

    for my $key ( qw( _cod_enantiomer_of
                       _cod_related_optimal_struct )) {
        if( exists $values->{$key} ) {
            $structure{enantiomer} = $values->{$key}[0];
        }
    }

    for my $key ( qw( _cod_related_optimal_struct
                       _[local]_cod_related_optimal_struct )) {
        if( exists $values->{$key} ) {
            $structure{related_optimal} = $values->{$key}[0];
        }
    }

     my @journal_keys =
        grep { ! /^_journal_name/ }
        grep { /^_journal_[^\s]*$/ }
        keys %{$values};

    for my $key (@journal_keys) {
        my $val = $values->{$key}[0];
        if( defined $val ) {
            $val =~ s/^['"]|["']$//g;
            $structure{bibliography}{$key} = $val;
        }
    }

    for my $key ( qw( _cod_suboptimal_structure
                       _[local]_cod_suboptimal_structure )) {
        if( exists $values->{$key} ) {
            $structure{suboptimal} = $values->{$key}[0];
        }
    }

    if( exists $values->{_chemical_compound_source} ) {
        $structure{source}{_chemical_compound_source} =
            $values->{_chemical_compound_source}[0];
    }

    return \%structure;
}

#------------------------------------------------------------------------------

sub get_cell($)
{
    my ($datablok) = @_;

    return (
        $datablok->{_cell_length_a},
        $datablok->{_cell_length_b},
        $datablok->{_cell_length_c},
        $datablok->{_cell_angle_alpha},
        $datablok->{_cell_angle_beta},
        $datablok->{_cell_angle_gamma}
    );
}

sub cells_are_the_same($$$$$)
{
    my ($cell1, $cell2, $sigma1, $sigma2, $user_options) = @_;

    $user_options = {} unless defined $user_options;
    my %options;
    foreach my $key (keys %default_options) {
        $options{$key} = defined $user_options->{$key} ?
                                 $user_options->{$key} :
                                 $default_options{$key};
    };

    my @cell1 = get_cell( $cell1 );
    my @cell2 = get_cell( $cell2 );
    my @sigma1 = get_cell( $sigma1 );
    my @sigma2 = get_cell( $sigma2 );

    for my $i (0..2) {
        my $length1 = $cell1[$i];
        my $length2 = $cell2[$i];
        if( defined $length1 and defined $length2 ) {
            my $sigma1 = $sigma1[$i];
            my $sigma2 = $sigma2[$i];
            if( defined $sigma1 || defined $sigma2 ) {
                $sigma1 = 0 unless defined $sigma1;
                $sigma2 = 0 unless defined $sigma2;
            }
            if( defined $sigma1 && ! $options{ignore_sigma} ) {
                if( !eqsig( $length1, $sigma1, $length2, $sigma2 )) {
                    return 0;
                }
            } else {
                my $diff = abs( $length1 - $length2 );
                if( $diff > $options{max_cell_length_diff} ) {
                    return 0;
                }
            }
        }
    }
    for my $i (3..5) {
        my $angle1 = $cell1[$i];
        my $angle2 = $cell2[$i];
        if( defined $angle1 and defined $angle2 ) {
            my $sigma1 = $sigma1[$i];
            my $sigma2 = $sigma2[$i];
            if( defined $sigma1 || defined $sigma2 ) {
                $sigma1 = 0 unless defined $sigma1;
                $sigma2 = 0 unless defined $sigma2;
            }
            if( defined $sigma1 && ! $options{ignore_sigma} ) {
                if( !eqsig( $angle1, $sigma1, $angle2, $sigma2 )) {
                    return 0;
                }
            } else {
                my $diff = abs( $angle1 - $angle2 );
                if( $diff > $options{max_cell_angle_diff} ) {
                    return 0;
                }
            }
        }
    }

    ## print ">>> \$cell1: @cell1\n";
    ## print ">>> \$cell2: @cell2\n";

    return 1;
}

sub conditions_are_the_same
{
    my ($entry1, $entry2, $user_options) = @_;

    $user_options = {} unless defined $user_options;
    my %options;
    foreach my $key (keys %default_options) {
        $options{$key} = defined $user_options->{$key} ?
                                 $user_options->{$key} :
                                 $default_options{$key};
    };

    my $number = '[-+]?([0-9]+(\.[0-9]*)?|\.[0-9]+)([Ee][-+]?[0-9]+)?';

    my @parameters = qw( temperature pressure );
    if( $options{check_sample_history} ) {
        push( @parameters, "history" );
    }
    if( $options{check_compound_source} ) {
        push( @parameters, "source" );
    }

    for my $parameter ( @parameters ) {

        my %tags = map {($_,$_)} ( keys %{$entry1->{$parameter}},
                                   keys %{$entry2->{$parameter}} );

        ## print ">>> 1: ",keys %{$entry1->{$parameter}},"\n";
        ## print ">>> 2: ",keys %{$entry2->{$parameter}},"\n";

        for my $tag (keys %tags) {
            if( exists $entry1->{$parameter}{$tag} &&
                exists $entry2->{$parameter}{$tag} ) {
                ## print ">>> $tag\n";
                my $val1 = $entry1->{$parameter}{$tag};
                my $val2 = $entry2->{$parameter}{$tag};
                if( $val1 =~ /^${number}$/o || $val2 =~ /^${number}$/o ) {
                    $val1 =~ s/\(\d+\)$//;
                    $val2 =~ s/\(\d+\)$//;
                    ## print ">>> '$val1', '$val2'\n\n";
                    if( $val1 != $val2 ) {
                        return 0;
                    }
                } else {
                    $val1 =~ s/^\s+|\s+$//g;
                    $val2 =~ s/^\s+|\s+$//g;
                    $val1 =~ s/\n/ /g;
                    $val2 =~ s/\n/ /g;
                    $val1 =~ s/\s+/ /g;
                    $val2 =~ s/\s+/ /g;
                    ## print ">>> '$val1', '$val2'\n\n";
                    if( $val1 ne $val2 ) {
                        return 0;
                    }
                }
            }
        }
    }
    return 1;
}

sub bibliographies_are_the_same($$)
{
    my ($biblio1, $biblio2) = @_;

    my %tags = map {($_,$_)} ( keys %$biblio1, keys %$biblio2 );

    # If DOIs exists, their comparison gives a definitve answer to
    # whether we are analysing the same paper (data source) or not:

    if( exists $biblio1->{_journal_paper_doi} &&
        exists $biblio2->{_journal_paper_doi} ) {
        return
            lc($biblio1->{_journal_paper_doi}) eq
            lc($biblio2->{_journal_paper_doi});
    }

    for my $tag ( keys %tags ) {
        next if( $skip_tag{$tag} );
        if( defined $biblio1->{$tag} && defined $biblio2->{$tag} ) {
            if( $has_numeric_value{$tag} ) {
                if( $biblio1->{$tag} != $biblio2->{$tag} ) {
                    return 0;
                }
            } else {
                if( $biblio1->{$tag} ne $biblio2->{$tag} ) {
                    return 0;
                }
            }
        }
    }
    return 1;
}

sub entries_are_the_same
{
    my ($entry1, $entry2, $user_options) = @_;

    ## print ">>> $entry1->{id}, $entry2->{id}, ",
    ## defined $entry1->{suboptimal} ? $entry1->{suboptimal} : "" , " ", 
    ## defined $entry2->{suboptimal} ? $entry2->{suboptimal} : "", "\n";

    $user_options = {} unless defined $user_options;
    my %options;
    foreach my $key (keys %default_options) {
        $options{$key} = defined $user_options->{$key} ?
                                 $user_options->{$key} :
                                 $default_options{$key};
    };

    my $are_the_same =
        cells_are_the_same(
            $entry1->{cell}, $entry2->{cell},
            $entry1->{sigcell}, $entry2->{sigcell},
            \%options ) &&
        conditions_are_the_same( $entry1, $entry2, \%options ) &&
        (!defined $entry1->{suboptimal} || $entry1->{suboptimal} ne "yes") &&
        (!defined $entry2->{suboptimal} || $entry2->{suboptimal} ne "yes");

    if( $options{check_bibliography} ) {
        $are_the_same = $are_the_same && bibliographies_are_the_same(
                                            $entry1->{bibliography},
                                            $entry2->{bibliography} );
    }

    if( $are_the_same ) {
        ## use COD::Serialise qw( serialiseRef );
        ## serialiseRef( [ $entry1, $entry2 ] );
        if( defined $entry1->{enantiomer} &&
            $entry1->{enantiomer} eq $entry2->{id} ) {
            $are_the_same = 0;
        }
        if( defined $entry1->{related_optimal} &&
            $entry1->{related_optimal} eq $entry2->{id} &&
            defined $entry1->{suboptimal} &&
            $entry1->{suboptimal} eq "yes" ) {
            $are_the_same = 0;
        }
    }

    return $are_the_same;
}

##
# Connects to a database using the provided parameters. This subroutine
# acts as a wrapper for the 'DBI->connect' subroutine.
#
# @param $database
#       Reference to a hash containing the database connection parameters, i.e.:
#       {
#         # the platform of the database like 'mysql', 'SQLite', etc.
#           'platform'  => 'mysql',
#         # address of the host machine
#           'host'      => 'www.crystallography.net',
#         # name of the database
#           'name'      => 'cod',
#         # name of the database table
#           'table'     => 'data',
#         # user name that should be used in the authentication process
#           'user'      => 'cod_reader',
#         # password that should be used in the authentication process
#           'password'  => ''
#       }
# @return
#       A database connection object as returned by the 'DBI->connect()'
#       subroutine.
##
sub database_connect
{
    my ( $database ) = @_;

    my $dbh = DBI->connect( "dbi:$database->{platform}:" .
                            "hostname=$database->{host};".
                            "dbname=$database->{name};".
                            "user=$database->{user};".
                            "password=$database->{password}" )
        || die 'cannot connect to the database' .
           ( defined $DBI::errstr ? ' -- ' . lcfirst( $DBI::errstr) : '' );

    return $dbh;
}

sub database_disconnect
{
    my ( $dbh ) = @_;

    $dbh->disconnect
    || die 'cannot disconnect from the database' .
       ( defined $DBI::errstr ? ' -- ' . lcfirst( $DBI::errstr) : '' );
}

sub query_COD_database
{
    my ( $dbh, $database, $COD, $data, $user_options ) = @_;

    $user_options = {} unless defined $user_options;
    my %options;
    foreach my $key (keys %default_options) {
        $options{$key} = defined $user_options->{$key} ?
                                 $user_options->{$key} :
                                 $default_options{$key};
    };
    my $cod_series_prefix = $options{cod_series_prefix};

    use DBI;

    my @columns = qw( file a b c alpha beta gamma
                      siga sigb sigc sigalpha sigbeta siggamma
                      celltemp diffrtemp cellpressure diffrpressure
                      journal year volume issue firstpage lastpage doi
                      duplicateof optimal status flags );

    my @history_columns = qw( thermalhist pressurehist );

    my $column_list = join( ",", @columns );

    if( $options{check_sample_history} ) {
        $column_list .= "," . join( ",", @history_columns );
    }

    if( $options{check_compound_source} ) {
        $column_list .= ',compoundsource';
    }

    my $sth = $dbh->prepare(
        "SELECT $column_list FROM `$database->{table}` ".
        "WHERE (formula = ? OR calcformula = ? OR cellformula = ?)" .
        ($cod_series_prefix ? "AND `file` LIKE '$cod_series_prefix%'" : "")
        );

    for my $id (keys %{$data}) {
        ## print ">>> id = $id\n";
        ## use COD::Serialise qw( serialiseRef );
        ## serialiseRef( $data->{$id} );
        for my $formula (( $data->{$id}{chemical_formula_sum},
                           $data->{$id}{calc_formula},
                           $data->{$id}{cell_formula} )) {
            if( defined $formula ) {
                ## print ">>> formula = $formula\n";
                my $query_formula = "- " . $formula . " -";
                my $rv = $sth->execute( $query_formula,
                                        $query_formula,
                                        $query_formula );
                if( defined $rv ) {
                    ## print "\n>>> rv = $rv\n";
                    ## local $" = ", ";
                    $COD->{$formula} = [];
                    while( my $row = $sth->fetchrow_hashref() ) {
                        ## my @row = map { defined $row->{$_} ? 
                        ##           $row->{$_} : "NULL" } @columns;
                        ## print ">>> @row\n";

                        my $structure = {
                            filename => $row->{file},
                            id => $row->{file},
                            cell => {
                                _cell_length_a => $row->{a},
                                _cell_length_b => $row->{b},
                                _cell_length_c => $row->{c},
                                _cell_angle_alpha => $row->{alpha},
                                _cell_angle_beta  => $row->{beta},
                                _cell_angle_gamma => $row->{gamma},
                            },
                            sigcell => {
                                _cell_length_a => $row->{siga},
                                _cell_length_b => $row->{sigb},
                                _cell_length_c => $row->{sigc},
                                _cell_angle_alpha => $row->{sigalpha},
                                _cell_angle_beta  => $row->{sigbeta},
                                _cell_angle_gamma => $row->{siggamma},
                            }
                        };

                        $structure->{temperature}{_diffrn_ambient_temperature} =
                            $row->{diffrtemp} if defined $row->{diffrtemp};

                        $structure->{temperature}{_cell_measurement_temperature} =
                            $row->{celltemp} if defined $row->{celltemp};

                        $structure->{pressure}{_diffrn_ambient_pressure} =
                            $row->{diffrpressure} if defined $row->{diffrpressure};

                        $structure->{pressure}{_cell_measurement_pressure} =
                            $row->{cellpressure} if defined $row->{cellpressure};

                        $structure->{history}{_exptl_crystal_thermal_history} =
                            $row->{thermalhist} if defined $row->{thermalhist};

                        $structure->{history}{_exptl_crystal_pressure_history} =
                            $row->{pressurehist} if defined $row->{pressurehist};

                        $structure->{source}{_chemical_compound_source} =
                            $row->{compoundsource} if defined $row->{compoundsource};

                        $structure->{bibliography}{_journal_name_full} =
                            $row->{journal} if defined $row->{journal};

                        $structure->{bibliography}{_journal_year} =
                            $row->{year} if defined $row->{year};

                        $structure->{bibliography}{_journal_volume} =
                            $row->{volume} if defined $row->{volume};

                        $structure->{bibliography}{_journal_issue} =
                            $row->{issue} if defined $row->{issue};

                        $structure->{bibliography}{_journal_page_first} =
                            $row->{firstpage} if defined $row->{firstpage};

                        $structure->{bibliography}{_journal_page_last} =
                            $row->{lastpage} if defined $row->{lastpage};

                        $structure->{bibliography}{_journal_paper_doi} =
                            $row->{doi} if defined $row->{doi};

                        push( @{$COD->{$formula}}, $structure );
                    }
                } else {
                    die "ERROR, error fetching formula '${formula}'" .
                         ( defined $DBI::errstr ? ' -- ' .
                                   lcfirst( $DBI::errstr) : '' );
                }
            }
        }
    }
}

1;
