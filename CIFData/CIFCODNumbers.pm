#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Find COD numbers of duplicate structures.
#**

package CIFCODNumbers;

use strict;
use File::Basename;
use Formulae::AdHocParser;
use CIFData::CIFCellContents;

require Exporter;
@CIFCODNumbers::ISA = qw(Exporter);
@CIFCODNumbers::EXPORT = qw(fetch_duplicates fetch_duplicates_from_database);

my %has_numeric_value = (
    "_journal_year"   => 1,
    "_journal_volume" => 1,
    "_journal_issue"  => 1,
);

my %skip_tag = (
    "_journal_name_full" => 0,
);

my $max_cell_length_diff = 0.5; # Angstroems
my $max_cell_angle_diff  = 1.2; # degrees

my $check_bibliography = 1;
my $check_sample_history = 0;
my $ignore_sigma = 0;

my $cod_series_prefix;

# Returns a list of duplicates for each supplied datablock
# Parameters:
#   --  array of datablocks
#   --  file name
#   --  hash of database parameters, i.e.:
#       { table => "data" }
#   --  database handle
#   --  options
# Return:
#   --  {
#         formula => 'C',
#         duplicates =>
#         {
#           "1100003" => 
#            {
#              "bibliography" => { ... },
#              "cell" => { ... },
#              "filename" => "1100003",
#              "id"  => "1100003",
#              "pressure" => { ... },
#              "sigcell" => { ... },
#              "temperature" => { ... },
#            },
#            ...
#         }
#       }

sub fetch_duplicates_from_database
{
    my( $data, $file, $database, $dbh, $options ) = @_;

    $options = {} unless defined $options;
    $max_cell_length_diff = $options->{max_cell_length_diff}
        if defined $options->{max_cell_length_diff};
    $max_cell_angle_diff  = $options->{max_cell_angle_diff}
        if defined $options->{max_cell_angle_diff};
    $check_bibliography = $options->{check_bibliography}
        if defined $options->{check_bibliography};
    $check_sample_history = $options->{check_sample_history}
        if defined $options->{check_sample_history};
    $ignore_sigma = $options->{ignore_sigma}
        if defined $options->{ignore_sigma};
    $cod_series_prefix = $options->{cod_series_prefix}
        if defined $options->{cod_series_prefix};

    my %structures = cif_fill_data( $data, $file );

    my %COD = ();

    query_COD_database( $dbh, $database, \%COD, \%structures, $options );

    my @duplicates;
    for my $id (keys %structures) {
        my $formula = $structures{$id}{chemical_formula_sum};
        my $cell_contents = $structures{$id}{cell_contents};

        my $final_formula;
        if( defined $formula ) {
            $final_formula = $formula;
        } elsif( defined $cell_contents ) {
            $final_formula = $cell_contents;            
        } else {
            $final_formula = '?';
        }

        $final_formula =~ s/\s/_/g;

        my %structures_found = ();

        if( defined $formula && defined $COD{$formula} ) {
            for my $COD_entry (@{$COD{$formula}}) {
                if( entries_are_the_same( $structures{$id}, $COD_entry )) {
                    my $COD_key = $COD_entry->{filename};
                    $structures_found{$COD_key} = $COD_entry;
                }
            }
        }
        if( defined $cell_contents && defined $COD{$cell_contents} &&
            ( !defined $formula || $formula ne $cell_contents )) {
            ## print ">>> formula: '$formula', contents: '$cell_contents'\n";
            for my $COD_entry (@{$COD{$cell_contents}}) {
                if( entries_are_the_same( $structures{$id}, $COD_entry )) {
                    my $COD_key = $COD_entry->{filename};
                    if( !exists $structures_found{$COD_key} ) {
                        $structures_found{$COD_key} = $COD_entry;
                    }
                }
            }
        }        

        push( @duplicates,
                { formula => $final_formula,
                  duplicates => \%structures_found } );
    }

    return \@duplicates;
}

# Wrapper for fetch_duplicates_from_database(), pre-creating database
# connection from database credential hash
# Parameters:
#   --  array of datablocks
#   --  file name
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
    my( $data, $file, $database, $options ) = @_;
    my $dbh = database_connect( $database );
    my $duplicates = fetch_duplicates_from_database( $data,
                                                     $file,
                                                     $database,
                                                     $dbh,
                                                     $options );
    database_disconnect( $dbh );
    return $duplicates;
}

#------------------------------------------------------------------------------

sub cif_fill_data
{
    my ( $data, $file ) = @_;

    my %structures = ();
    my $id;

    for my $dataset ( @$data ) {
        my $values = $dataset->{values};
        my $sigmas = $dataset->{precisions};
        my $id = $dataset->{name};

        if( defined $id ) {
            $structures{$id}{id} = $id;
            $structures{$id}{filename} = File::Basename::basename( $file );
        } else {
            next
        }

        if( defined $values->{_chemical_formula_sum} ) {
            my $formula = $values->{_chemical_formula_sum}[0];

            if( $formula ne '?' ) {

                $formula =~ s/^\s*'\s*|\s*'\s*$//g;
                $formula =~ s/^\s*|\s*$//g;
                $formula =~ s/\s+/ /g;

                my $formula_parser = new AdHocParser;

                eval {
                    $formula_parser->ParseString( $formula );
                    if( defined $formula_parser->YYData->{ERRCOUNT} &&
                        $formula_parser->YYData->{ERRCOUNT} > 0 ) {
                        print STDERR "$0: ", $file, " ", $dataset->{name}, ": ",
                        $formula_parser->YYData->{ERRCOUNT},
                        " error(s) encountered while parsing chemical formula ",
                        "sum\n";
                        die;
                    } else {
                        $formula = $formula_parser->SprintFormula;
                    }
                };
                if( $@ ) {
                    print STDERR "$0: ", $file, " ", $dataset->{name}, ": ",
                    "could not parse formula '$formula', resorting to ",
                    "simple split routine\n";
                    $formula = join( " ", sort {$a cmp $b} 
                                     split( " ", $formula ));
                }
            }
            $structures{$id}{chemical_formula_sum} = $formula;
        }

        my $calculated_formula;
        eval {
            $calculated_formula =
                CIFCellContents::cif_cell_contents( $dataset, $file, undef );
        };

        $structures{$id}{cell_contents} = $calculated_formula
            if defined $calculated_formula;

        for my $key ( qw( _cell_length_a _cell_length_b _cell_length_c
                     _cell_angle_alpha _cell_angle_beta _cell_angle_gamma )) {
            my $val = $values->{$key}[0];
            if( defined $val ) {
                $val =~ s/^\s*'\s*|\s*'\s*$//g;
                $val =~ s/\(.*$//;
                $val =~ s/[()_a-zA-Z]//g;
                $structures{$id}{cell}{$key} = sprintf "%f", $val;
            }
        }
        for my $key ( qw( _cell_length_a _cell_length_b _cell_length_c
                     _cell_angle_alpha _cell_angle_beta _cell_angle_gamma )) {
            if( exists $sigmas->{$key} ) {
                my $val = $sigmas->{$key}[0];
                $structures{$id}{sigcell}{$key} = $val;
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
                    $structures{$id}{$parameter}{$key} = $val;
                    $structures{$id}{$parameter}{$key}
                        =~ s/^\s*'\s*|\s*'\s*$//g;
                }
            }
        }

        for my $key ( qw( _cod_enantiomer_of
                          _cod_related_optimal_struct )) {
            if( exists $values->{$key} ) {
                $structures{$id}{enantiomer} = $values->{$key}[0];
            }
        }

        for my $key ( qw( _cod_related_optimal_struct
                          _[local]_cod_related_optimal_struct )) {
            if( exists $values->{$key} ) {
                $structures{$id}{related_optimal} = $values->{$key}[0];
            }
        }

        my @journal_keys =
            grep ! /^_journal_name/,
            grep /^_journal_[^\s]*$/,
            keys %{$values};

        for my $key (@journal_keys) {
            my $val = $values->{$key}[0];
            if( defined $val ) {
                $val =~ s/^['"]|["']$//g;
                $structures{$id}{bibliography}{$key} = $val;
            }
        }
        if( defined $values->{'_[local]_cod_suboptimal_structure'} ||
            defined $values->{_cod_suboptimal_structure} ) {
            my $val = defined $values->{_cod_suboptimal_structure} ?
                $values->{_cod_suboptimal_structure}[0] :
                $values->{'_[local]_cod_suboptimal_structure'}[0];
            ## print ">>>>>> $val\n";
            $structures{$id}{suboptimal} = $val;
        }
    }

    return %structures;
}

#------------------------------------------------------------------------------

sub get_cell($)
{
    my $datablok = $_[0];

    return (
        $datablok->{_cell_length_a},
        $datablok->{_cell_length_b},
        $datablok->{_cell_length_c},
        $datablok->{_cell_angle_alpha},
        $datablok->{_cell_angle_beta},
        $datablok->{_cell_angle_gamma}
    );
}

sub eqsig
{
    my ( $x, $sigx, $y, $sigy ) = @_;

    $sigx = 0.0 unless defined $sigx;
    $sigy = 0.0 unless defined $sigy;

    return ($x - $y)**2 <= 9 * $sigx**2 + $sigy**2;
}

sub cells_are_the_same($$$$)
{
    my ($cell1, $cell2, $sigma1, $sigma2) = @_;

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
            if( defined $sigma1 && ! $ignore_sigma) {
                if( !eqsig( $length1, $sigma1, $length2, $sigma2 )) {
                    return 0;
                }
            } else {
                my $diff = abs( $length1 - $length2 );
                if( $diff > $max_cell_length_diff ) {
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
            if( defined $sigma1 && ! $ignore_sigma ) {
                if( !eqsig( $angle1, $sigma1, $angle2, $sigma2 )) {
                    return 0;
                }
            } else {
                my $diff = abs( $angle1 - $angle2 );
                if( $diff > $max_cell_angle_diff ) {
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
    my ($entry1, $entry2) = @_;

    my $number = '[-+]?([0-9]+(\.[0-9]*)?|\.[0-9]+)([Ee][-+]?[0-9]+)?';

    my @parameters = qw( temperature pressure );
    if( $check_sample_history ) {
        push( @parameters, "history" );
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
    my ($entry1, $entry2) = @_;
    
    ## print ">>> $entry1->{id}, $entry2->{id}, ",
    ## defined $entry1->{suboptimal} ? $entry1->{suboptimal} : "" , " ", 
    ## defined $entry2->{suboptimal} ? $entry2->{suboptimal} : "", "\n";

    my $are_the_same;

    if( $check_bibliography ) {
        $are_the_same =
            cells_are_the_same( $entry1->{cell}, $entry2->{cell},
                                $entry1->{sigcell}, $entry2->{sigcell} ) &&
            conditions_are_the_same( $entry1, $entry2 ) &&
            (!defined $entry1->{suboptimal} || $entry1->{suboptimal} ne "yes") &&
            (!defined $entry2->{suboptimal} || $entry2->{suboptimal} ne "yes") &&
            bibliographies_are_the_same( $entry1->{bibliography},
                                         $entry2->{bibliography} );
    } else {
        $are_the_same =
            cells_are_the_same( $entry1->{cell}, $entry2->{cell},
                                $entry1->{sigcell}, $entry2->{sigcell} ) &&
            conditions_are_the_same( $entry1, $entry2 ) &&
            (!defined $entry1->{suboptimal} || $entry1->{suboptimal} ne "yes") &&
            (!defined $entry2->{suboptimal} || $entry2->{suboptimal} ne "yes");
    }

    if( $are_the_same ) {
        ## use Serialise;
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

sub database_connect
{
    my ( $database ) = @_;
    
    my $dbh = DBI->connect( "dbi:$database->{platform}:" .
                            "hostname=$database->{host};".
                            "db=$database->{name};".
                            "user=$database->{user};".
                            "password=$database->{password}" )
        || die "cannot connect do the database -- $DBI::errstr";

    return $dbh;
}

sub database_disconnect
{
    my ( $dbh ) = @_;

    $dbh->disconnect || die "cannot disconnect -- $DBI::errstr";
}

sub query_COD_database
{
    my ( $dbh, $database, $COD, $data, $options ) = @_;

    use DBI;

    my @columns = qw( file a b c alpha beta gamma
                      siga sigb sigc sigalpha sigbeta siggamma
                      celltemp diffrtemp cellpressure diffrpressure
                      journal year volume issue firstpage lastpage
                      duplicateof optimal status flags );

    my @history_columns = qw( thermalhist pressurehist );

    my $column_list = join( ",", @columns );

    if( $options && $options->{check_sample_history} ) {
        $column_list .= "," . join( ",", @history_columns );
    }

    my $sth = $dbh->prepare(
        "SELECT $column_list FROM `$database->{table}` ".
        "WHERE (formula = ? OR calcformula = ?)" .
        ($cod_series_prefix ? "AND `file` LIKE '$cod_series_prefix%'" : "")
        );

    for my $id (keys %{$data}) {
        ## print ">>> id = $id\n";
        ## use Serialise;
        ## serialiseRef( $data->{$id} );
        for my $formula (( $data->{$id}{chemical_formula_sum},
                           $data->{$id}{cell_contents} )) {
            if( defined $formula ) {
                ## print ">>> formula = $formula\n";
                my $query_formula = "- " . $formula . " -";
                my $rv = $sth->execute( $query_formula, $query_formula );
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

                        push( @{$COD->{$formula}}, $structure );
                    }
                } else {
                    print STDERR "$0: error fetching formula '${formula}' -- " .
                        "$DBI::errstr";
                }
            }
        }
    }
}

1;

## sub cell_volume
## {
##     my @cell = @_;
## 
##     if( !defined $cell[0] || !defined $cell[1] || !defined $cell[2] ||
##         !defined $cell[3] || !defined $cell[4] || !defined $cell[5] ) {
##         return -1;
##     }
## 
##     my $Pi = 3.14159265358979;
## 
##     @cell = map { s/\(.*\)//g; $_ } @_;
## 
##     my ($a, $b, $c) = @cell[0..2];
##     my ($alpha, $beta, $gamma) = map {$Pi * $_ / 180} @cell[3..5];
##     my ($ca, $cb, $cg) = map {cos} ($alpha, $beta, $gamma);
##     my $sg = sin($gamma);
##     
##     my $V = $a * $b * $c * sqrt( $sg**2 - $ca**2 - $cb**2 + 2*$ca*$cb*$cg );
## 
##     return $V;
## }
## 
## sub compute_datablock_cell_volume
## {
##     my $values = $_[0];
##     my @cell = get_cell( $values );
##     return cell_volume( @cell );
## }
