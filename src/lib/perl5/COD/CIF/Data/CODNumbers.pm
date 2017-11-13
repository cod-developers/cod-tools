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
    have_equiv_lattices
    have_equiv_bibliographies
);

my %default_options = (
    'use_su'                => 1,
    'max_cell_length_diff'  => 0.5,
    'max_cell_angle_diff'   => 1.2,
    'check_bibliography'    => 1,
    'check_sample_history'  => 0,
    'check_compound_source' => 0,
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
            for my $cod_entry (@{$COD{$formula}}) {
                if( entries_are_the_same( $structures{$id},
                                          $cod_entry,
                                          \%options )) {
                    my $cod_key = $cod_entry->{filename};
                    $structures_found{$cod_key} = $cod_entry;
                }
            }
        }
        if( defined $calc_formula && defined $COD{$calc_formula} &&
            ( !defined $formula || $formula ne $calc_formula )) {
            ## print ">>> formula: '$formula', contents: '$calc_formula'\n";
            for my $cod_entry (@{$COD{$calc_formula}}) {
                if( entries_are_the_same( $structures{$id},
                                          $cod_entry,
                                          \%options )) {
                    my $cod_key = $cod_entry->{filename};
                    if( !exists $structures_found{$cod_key} ) {
                        $structures_found{$cod_key} = $cod_entry;
                    }
                }
            }
        }
        if( defined $cell_formula && defined $COD{$cell_formula} &&
            ( !defined $calc_formula || $calc_formula ne $cell_formula ) ) {
            for my $cod_entry (@{$COD{$cell_formula}}) {
                if( entries_are_the_same( $structures{$id},
                                          $cod_entry,
                                          \%options )) {
                    my $cod_key = $cod_entry->{filename};
                    if( !exists $structures_found{$cod_key} ) {
                        $structures_found{$cod_key} = $cod_entry;
                    }
                }
            }
        }

        push @duplicates,
               { formula    => $final_formula,
                 datablock  => $structures{$id},
                 duplicates => \%structures_found };
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

    return if !defined $id;
    $structure{id} = $id;
    $structure{filename} = basename( $file );
    $structure{index} = $index;

    if( defined $values->{_chemical_formula_sum} ) {
        my $formula = $values->{_chemical_formula_sum}[0];

        if( $formula ne '?' ) {

            $formula =~ s/^\s*'\s*|\s*'\s*$//g;
            $formula =~ s/^\s*|\s*$//g;
            $formula =~ s/\s+/ /g;

            my $formula_parser = COD::Formulae::Parser::AdHoc->new();

            eval {
                $formula_parser->ParseString( $formula );
                if( defined $formula_parser->YYData->{ERRCOUNT} &&
                    $formula_parser->YYData->{ERRCOUNT} > 0 ) {
                    die "ERROR, $formula_parser->YYData->{ERRCOUNT} "
                      . 'error(s) encountered while parsing chemical '
                      . "formula sum\n";
                    ;
                } else {
                    $formula = $formula_parser->SprintFormula;
                }
            };
            if( $@ ) {
                warn "WARNING, could not parse formula '$formula' "
                   . "resorting to simple split routine\n";
                $formula = join ' ', sort {$a cmp $b} split( ' ', $formula );
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
        chomp $error;
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
        chomp $error;
        warn "WARNING, unit cell summary formula could not be calculated -- $error\n";
    };
    $structure{cell_formula} = $cell_formula
        if defined $cell_formula;

    for my $key ( qw( _cell_length_a
                      _cell_length_b
                      _cell_length_c
                      _cell_angle_alpha
                      _cell_angle_beta
                      _cell_angle_gamma ) ) {
        my $val = $values->{$key}[0];
        if ( defined $val ) {
            $val =~ s/^\s*'\s*|\s*'\s*$//g;
            $val =~ s/\(.*$//;
            $val =~ s/[()_a-zA-Z]//g;
            $structure{'cell'}{$key} = sprintf '%f', $val;
        }
        if( exists $sigmas->{$key} ) {
            $structure{'sigcell'}{$key} = $sigmas->{$key}[0];
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
                      _pd_prep_pressure ) ) {
       if( exists $values->{$key} ) {
           my $val = $values->{$key}[0];
           if( defined $val ) {
               my $parameter;
               if( $key =~ /history/ ) {
                   $parameter = 'history';
               } elsif( $key =~ /pressure/ ) {
                   $parameter = 'pressure';
               } else {
                   $parameter = 'temperature';
               }
               $structure{$parameter}{$key} = $val;
               $structure{$parameter}{$key}
                   =~ s/^\s*'\s*|\s*'\s*$//g;
            }
        }
    }

    for my $key ( qw( _cod_enantiomer_of
                      _cod_related_optimal_struct ) ) {
        if( exists $values->{$key} ) {
            $structure{enantiomer} = $values->{$key}[0];
        }
    }

    for my $key ( qw( _cod_related_optimal_struct
                      _[local]_cod_related_optimal_struct ) ) {
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
                      _[local]_cod_suboptimal_structure ) ) {
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

##
# Evaluates if the crystal lattice parameters provided in both entries could
# be considered equivalent. Undefined values are treated as being equal to any
# other value.
#
# @param $entry1
#       Data structure of the first entry as returned by the 'cif_fill_data()'
#       or the 'query_COD_database()' subroutines.
# @param $entry2
#       Data structure of the second entry as returned by the 'cif_fill_data()'
#       or the 'query_COD_database()' subroutines.
# @param $options
#       Reference to a hash containing the options that modify the behaviour
#       of the subroutine. The following options are recognised by this
#       subroutine:
#
#       {
#       # Logical value denoting whether the s.u. values should be
#       # considered while comparing the measured values
#           'use_su'               => 1,
#       # The maximum difference between two cell length values in
#       # ångströms for them to be still considered equivalent
#           'max_cell_length_diff' => 0.5,
#       # The maximum difference between two cell angle values in
#       # ångströms for them to be still considered equivalent
#           'max_cell_angle_diff'  => 1.2,
#       }
#
#       In case the option value is undefined the default value is used.
#
# @return
#       '1' if the crystal lattice parameters are considered equivalent,
#       '0' otherwise.
##
sub have_equiv_lattices
{
    my ($entry1, $entry2, $options) = @_;

    my $use_su          = defined $options->{'use_su'} ?
                                  $options->{'use_su'} : 1;
    my $max_length_diff = defined $options->{'max_cell_length_diff'} ?
                                  $options->{'max_cell_length_diff'} : 0.5;
    my $max_angle_diff  = defined $options->{'max_cell_angle_diff'} ?
                                  $options->{'max_cell_angle_diff'} : 1.2;

    my @cell1  = get_cell( $entry1->{'cell'} );
    my @cell2  = get_cell( $entry2->{'cell'} );
    my @sigma1 = get_cell( $entry1->{'sigcell'} );
    my @sigma2 = get_cell( $entry2->{'sigcell'} );

    for my $i (0..2) {
        my $length_1 = $cell1[$i];
        my $length_2 = $cell2[$i];
        my $su_1     = $sigma1[$i];
        my $su_2     = $sigma2[$i];
        next if ( !( defined $length_1 && defined $length_2 ) );

        return 0 if !are_equiv_meas(
            $length_1,
            $length_2,
            {
                'su_1'     => $su_1,
                'su_2'     => $su_2,
                'use_su'   => $use_su,
                'max_diff' => $max_length_diff,
            }
        );
    }

    for my $i (3..5) {
        my $angle_1 = $cell1[$i];
        my $angle_2 = $cell2[$i];
        my $su_1    = $sigma1[$i];
        my $su_2    = $sigma2[$i];
        next if ( !( defined $angle_1 && defined $angle_2 ) );

        return 0 if !are_equiv_meas(
            $angle_1,
            $angle_2,
            {
                'su_1'     => $su_1,
                'su_2'     => $su_2,
                'use_su'   => $use_su,
                'max_diff' => $max_angle_diff,
            }
        );
    }

    return 1;
}

##
# Compares two numeric measured values while making use of the standard
# uncertainties (s.u.) associated with the measurement. In case the use of
# the s.u. values is not desired a similarity threshold can be can be provided
# instead.
#
# @param $value_1
#       The first numeric value to be compared.
# @param $value_2
#       The second numeric value to be compared.
# @param $options
#       Reference to a hash containing the options that modify the behaviour
#       of the subroutine. The following options are recognised by this
#       subroutine:
#
#       {
#       # Logical value denoting whether the s.u. values should be
#       # considered while comparing the measured values. In case
#       # this option is enabled, but no s.u. values are provided
#       # the values are compared using the threshold value. In
#       # case only one s.u. value is provided, the other value
#       # is assumed to be zero.
#       # TODO: is defaulting to zero really the correct behaviour?
#           'use_su'   => 1,
#       # Standard uncertainty value associated with $value_1
#           'su_1'     => undef,
#       # Standard uncertainty value associated with $value_2
#           'su_2'     => undef,
#       # The maximum difference between numeric values for them to
#       # be still considered equivalent
#           'max_diff' => 0,
#       }
#
#       In case the option value is undefined the default value is used.
#
# @return
#       '1' if the numeric values are considered equivalent,
#       '0' otherwise.
##
sub are_equiv_meas
{
    my ( $value_1, $value_2, $options ) = @_;

    my $su_1     = $options->{'su_1'};
    my $su_2     = $options->{'su_2'};
    my $use_su   = defined $options->{'use_su'} ?
                           $options->{'use_su'} : 1;
    my $max_diff = defined $options->{'max_diff'} ?
                           $options->{'max_diff'} : 0;

    if( !(defined $su_1 || defined $su_2) ) {
        $use_su = 0;
    } else {
        $su_1 = 0 unless defined $su_1;
        $su_2 = 0 unless defined $su_2;
    }

    my $are_equal;
    if( $use_su ) {
        $are_equal = eqsig( $value_1, $su_1, $value_2, $su_2 );
    } else {
        $are_equal = abs( $value_1 - $value_2 ) < $max_diff;
    }

    return $are_equal;
}

##
# Evaluates if all of the values in a certain category provided in both entries
# could be considered equivalent. Undefined values are treated as being equal
# to any other value.
#
# @param $entry1
#       Data structure of the first entry as returned by the 'cif_fill_data()'
#       or the 'query_COD_database()' subroutines.
# @param $entry2
#       Data structure of the second entry as returned by the 'cif_fill_data()'
#       or the 'query_COD_database()' subroutines.
# @param $category
#       The name of the category that the compared values belong to, i.e.
#       'bibliography'.
# @return
#       '1' if the sample histories are considered equivalent,
#       '0' otherwise.
##
sub have_equiv_category_values
{
    my ($entry_1, $entry_2, $category) = @_;

    my $number = '[-+]?([0-9]+(\.[0-9]*)?|\.[0-9]+)([Ee][-+]?[0-9]+)?';

    my %tags = map {($_,$_)} ( keys %{$entry_1->{$category}},
                               keys %{$entry_2->{$category}} );

    for my $tag (keys %tags) {
        next if ( !( exists $entry_1->{$category}{$tag} &&
                     exists $entry_2->{$category}{$tag} ) );
        my $val_1 = $entry_1->{$category}{$tag};
        my $val_2 = $entry_2->{$category}{$tag};
        if ( $val_1 =~ /^${number}$/o || $val_2 =~ /^${number}$/o ) {
            $val_1 =~ s/\(\d+\)$//;
            $val_2 =~ s/\(\d+\)$//;
            return 0 if ( $val_1 != $val_2 )
        } else {
            $val_1 =~ s/^\s+|\s+$//g;
            $val_2 =~ s/^\s+|\s+$//g;
            $val_1 =~ s/\n/ /g;
            $val_2 =~ s/\n/ /g;
            $val_1 =~ s/\s+/ /g;
            $val_2 =~ s/\s+/ /g;
            return 0 if ( $val_1 ne $val_2 );
        }
    }

    return 1;
}

##
# Evaluates if the sample histories provided in both entries could
# be considered equivalent. Undefined values are treated as being equal
# to any other value.
#
# @param $entry1
#       Data structure of the first entry as returned by the 'cif_fill_data()'
#       or the 'query_COD_database()' subroutines.
# @param $entry2
#       Data structure of the second entry as returned by the 'cif_fill_data()'
#       or the 'query_COD_database()' subroutines.
# @return
#       '1' if the sample histories are considered equivalent,
#       '0' otherwise.
##
sub have_equiv_sample_histories
{
    my ($entry1, $entry2) = @_;

    return have_equiv_category_values($entry1, $entry2, 'history');
}

##
# Evaluates if the compound sources provided in both entries could
# be considered equivalent. Undefined values are treated as being equal
# to any other value.
#
# @param $entry1
#       Data structure of the first entry as returned by the 'cif_fill_data()'
#       or the 'query_COD_database()' subroutines.
# @param $entry2
#       Data structure of the second entry as returned by the 'cif_fill_data()'
#       or the 'query_COD_database()' subroutines.
# @return
#       '1' if the compound sources are considered equivalent,
#       '0' otherwise.
##
sub have_equiv_compound_sources
{
    my ($entry1, $entry2) = @_;

    return have_equiv_category_values($entry1, $entry2, 'source');
}

##
# Evaluates if the experimental conditions provided in both entries could
# be considered equivalent. Undefined values are treated as being equal
# to any other value.
#
# @param $entry1
#       Data structure of the first entry as returned by the 'cif_fill_data()'
#       or the 'query_COD_database()' subroutines.
# @param $entry2
#       Data structure of the second entry as returned by the 'cif_fill_data()'
#       or the 'query_COD_database()' subroutines.
# @return
#       '1' if the experimental conditions are considered equivalent,
#       '0' otherwise.
##
sub have_equiv_conditions
{
    my ( $entry1, $entry2 ) = @_;

    return have_equiv_category_values($entry1, $entry2, 'temperature') &&
           have_equiv_category_values($entry1, $entry2, 'pressure');
}

##
# Evaluates if the bibliographical information provided in both entries could
# be considered equivalent. Undefined values are treated as being equal to any
# other value.
#
# @param $entry_1
#       Data structure of the first entry as returned by the 'cif_fill_data()'
#       or the 'query_COD_database()' subroutines.
# @param $entry_2
#       Data structure of the second entry as returned by the 'cif_fill_data()'
#       or the 'query_COD_database()' subroutines.
# @return
#       '1' if the bibliographical information is considered equivalent,
#       '0' otherwise.
##
sub have_equiv_bibliographies
{
    my ($entry_1, $entry_2) = @_;

    my $biblio_1 = $entry_1->{'bibliography'};
    my $biblio_2 = $entry_2->{'bibliography'};
    my %tags = map {($_,$_)} ( keys %{$biblio_1}, keys %{$biblio_2} );

    # If DOIs exists, their comparison gives a definitive answer to
    # whether we are analysing the same paper (data source) or not:
    if( defined $biblio_1->{'_journal_paper_doi'} &&
        defined $biblio_2->{'_journal_paper_doi'} ) {
        return
            lc $biblio_1->{'_journal_paper_doi'} eq
            lc $biblio_2->{'_journal_paper_doi'};
    }

    my %has_numeric_value = (
        '_journal_year'   => 1,
        '_journal_volume' => 1,
        '_journal_issue'  => 1,
    );

    my %skip_tag = (
        '_journal_name_full' => 1,
    );

    for my $tag ( keys %tags ) {
        next if ( $skip_tag{$tag} );
        my $value_1 = $biblio_1->{$tag};
        my $value_2 = $biblio_2->{$tag};
        next if ( !( defined $value_1 && defined $value_2 ) );
        if( $has_numeric_value{$tag} ) {
            if ( $value_1 != $value_2 ) {
                return 0;
            }
        } else {
            if ( lc $value_1 ne lc $value_2 ) {
                return 0;
            }
        }
    }

    return 1;
}

sub entries_are_the_same
{
    my ($entry1, $entry2, $user_options) = @_;

    $user_options = {} unless defined $user_options;
    my %options;
    foreach my $key (keys %default_options) {
        $options{$key} = defined $user_options->{$key} ?
                                 $user_options->{$key} :
                                 $default_options{$key};
    };

    my $are_the_same =
        have_equiv_lattices( $entry1, $entry2, \%options ) &&
        have_equiv_conditions( $entry1, $entry2 ) &&
        (!defined $entry1->{suboptimal} || $entry1->{suboptimal} ne 'yes') &&
        (!defined $entry2->{suboptimal} || $entry2->{suboptimal} ne 'yes');

    if ( $options{'check_sample_history'} &&
         !have_equiv_sample_histories( $entry1, $entry2 ) ) {
        return 0;
    }

    if ( $options{'check_compound_source'} &&
         !have_equiv_compound_sources( $entry1, $entry2 ) ) {
        return 0;
    }

    if ( $options{'check_bibliography'} &&
         !have_equiv_bibliographies( $entry1, $entry2 ) ) {
        return 0;
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
            $entry1->{suboptimal} eq 'yes' ) {
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

    return;
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

    my $column_list = join ',', @columns;

    if( $options{check_sample_history} ) {
        $column_list .= ',' . join ',', @history_columns;
    }

    if( $options{check_compound_source} ) {
        $column_list .= ',compoundsource';
    }

    my $sth = $dbh->prepare(
        "SELECT $column_list FROM `$database->{table}` ".
        'WHERE (formula = ? OR calcformula = ? OR cellformula = ?)' .
        ($cod_series_prefix ? "AND `file` LIKE '$cod_series_prefix%'" : '')
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
                my $query_formula = '- ' . $formula . ' -';
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

                        push @{$COD->{$formula}}, $structure;
                    }
                } else {
                    die "ERROR, error fetching formula '${formula}'" .
                         ( defined $DBI::errstr ? ' -- ' .
                                   lcfirst( $DBI::errstr) : '' );
                }
            }
        }
    }

    return;
}

1;
