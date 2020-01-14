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
use DBI;
use File::Basename qw( basename );
use List::MoreUtils qw( any uniq );
use COD::Formulae::Parser::AdHoc;
use COD::DateTime qw( parse_datetime );
use COD::CIF::Data::CellContents qw( cif_cell_contents );
use COD::CIF::Tags::Manage qw( get_aliased_value );
use COD::Precision qw( eqsig );
use COD::DateTime qw( is_date_only_timestamp );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    fetch_duplicates
    fetch_duplicates_from_database
    get_database_entries
    build_entry_from_db_row
    cif_fill_data
    entries_are_the_same
    have_equiv_lattices
    have_equiv_bibliographies
    have_equiv_category_values
    have_equiv_timestamps
);

my %default_options = (
    'check_bibliography'    => 1,
    'check_sample_history'  => 0,
    'check_compound_source' => 0,
);

my $db_fields2tags = {
    'cell' => {
        'a'     => '_cell_length_a',
        'b'     => '_cell_length_b',
        'c'     => '_cell_length_c',
        'alpha' => '_cell_angle_alpha',
        'beta'  => '_cell_angle_beta',
        'gamma' => '_cell_angle_gamma',
    },
    'sigcell' => {
        'siga'     => '_cell_length_a',
        'sigb'     => '_cell_length_b',
        'sigc'     => '_cell_length_c',
        'sigalpha' => '_cell_angle_alpha',
        'sigbeta'  => '_cell_angle_beta',
        'siggamma' => '_cell_angle_gamma',
    },
    'bibliography' => {
        'journal'   => '_journal_name_full',
        'year'      => '_journal_year',
        'volume'    => '_journal_volume',
        'issue'     => '_journal_issue',
        'firstpage' => '_journal_page_first',
        'lastpage'  => '_journal_page_last',
        'doi'       => '_journal_paper_doi',
    },
    'temperature'  => {
        'diffrtemp' => '_diffrn_ambient_temperature',
        'celltemp'  => '_cell_measurement_temperature',
    },
    'pressure'     => {
        'diffrpressure' => '_diffrn_ambient_pressure',
        'cellpressure'  => '_cell_measurement_pressure',
    },
    'history'      => {
        'thermalhist'  => '_exptl_crystal_thermal_history',
        'pressurehist' => '_exptl_crystal_pressure_history',
    },
    'source'       => {
        'compoundsource' => '_chemical_compound_source'
    }
};

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
#       the 'get_database_entries()' and 'entries_are_the_same()' subroutines.
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
#         # 'get_database_entries()' subroutine:
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

    $user_options = {} if !defined $user_options;
    my %options = %{$user_options};
    foreach my $key (keys %default_options) {
        if ( !defined $options{$key} ) {
            $options{$key} = $default_options{$key};
        }
    };

    my %structures = %{$structures};
    my $sth = prepare_database_query( $dbh, $database, \%options );
    my $db_entries = get_database_entries( $sth, \%structures, $db_fields2tags );

    my @duplicates;
    for my $id (sort { $structures{$a}->{index} <=>
                       $structures{$b}->{index} } keys %structures) {

        my @formulas;
        for my $field ( qw( chemical_formula_sum
                            calc_formula
                            cell_formula ) ) {
            if ( defined $structures{$id}{$field} ) {
                push @formulas, $structures{$id}{$field};
            }
        };
        @formulas = uniq @formulas;

        my $final_formula = @formulas ? $formulas[0] : '?';
        $final_formula =~ s/\s/_/g;

        my %structures_found = ();
        for my $formula (@formulas) {
            next if !defined $db_entries->{$formula};
            for my $cod_entry (@{$db_entries->{$formula}}) {
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

            my @formula_parser_warnings;
            eval {
                local $SIG{__WARN__} = sub {
                    push @formula_parser_warnings, @_;
                };
                $formula_parser->ParseString( $formula );
            };
            if ( !@formula_parser_warnings ) {
                $formula = $formula_parser->SprintFormula;
            } else {
                for( @formula_parser_warnings ) {
                    print STDERR $_;
                }
                warn "WARNING, could not parse formula '$formula' -- "
                   . 'resorting to simple split routine' . "\n";
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
        if( defined $sigmas->{$key} ) {
            $structure{'sigcell'}{$key} = $sigmas->{$key}[0];
        }
    }

    my $categories = {
        'bibliography' => [
            qw(
                _journal_name_full
                _journal_year
                _journal_volume
                _journal_issue
                _journal_page_first
                _journal_page_last
                _journal_paper_doi
            )
        ],
        'history' => [
            qw(
                 _exptl_crystal_pressure_history
                 _exptl_crystal_thermal_history
            )
        ],
        'pressure' => [
            qw(
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
                _pd_prep_pressure
            )
        ],
        'temperature' => [
            qw(
                _cell_measurement_temperature
                _cell_measurement_temperature_C
                _diffrn_ambient_temperature
                _diffrn_ambient_temperature_C
                _diffrn_ambient_temperature_gt
                _diffrn_ambient_temperature_lt
                _pd_prep_temperature
            )
        ],
        # FIXME: the 'enantiomer' field should be removed prior to a major
        # release since it was replaced with the 'related_enantiomer_entries'
        # field. The new field takes into consideration that there might be
        # more than one related enantiomer entry.
        'enantiomer' => [
            qw(
                _cod_related_enantiomer_entry.code
                _cod_related_enantiomer_entry_code
                _cod_enantiomer_of
            )
        ],
        'source' => [
            qw(
                _chemical_compound_source
            )
        ]
    };

    for my $category ( keys %{$categories} ) {
        for my $data_name ( @{$categories->{$category}} ) {
            my $val = $values->{$data_name}[0];
            if( defined $val ) {
               $structure{$category}{$data_name} = $val;
               $structure{$category}{$data_name}
                   =~ s/^\s*['"]\s*|\s*['"]\s*$//g;
            }
        }
    }

    my $enantiomer_entry_codes = get_related_enantiomer_entry_codes( $dataset );
    if (@{$enantiomer_entry_codes}) {
        $structure{'related_enantiomer_entries'} = $enantiomer_entry_codes;
    }

    my $value = get_aliased_value($values,
                    [ qw( _cod_related_optimal_entry.code
                          _cod_related_optimal_entry_code
                          _cod_related_optimal_struct
                          _[local]_cod_related_optimal_struct ) ]);
    if (defined $value) {
        $structure{'related_optimal'} = $value;
    }

    # FIXME: whether a structure is suboptimal can be judged not only from
    # the value of the _cod_suboptimal_structure data item, but also from
    # the presence of related optimal entry data items (the preferred way).
    # This type of functionality is supplied by the
    # COD::CIF::Data::CODFlags::is_suboptimal() subroutine
    $value = get_aliased_value($values,
                [ qw( _cod_suboptimal_structure
                      _[local]_cod_suboptimal_structure ) ] );
    if (defined $value) {
        $structure{'suboptimal'} = $value;
    }

    return \%structure;
}

##
# Returns the COD IDs of entries that are explicitly referenced as
# enantiomers in the provided data block.
#
# @param $data_block
#       Reference to data block as returned by the COD::CIF::Parser.
# @return \@related_enantiomer_entry_codes
#       Reference to an array of COD IDs.
##
sub get_related_enantiomer_entry_codes
{
    my ($data_block) = @_;

    my @related_enantiomer_tags = qw(
        _cod_related_enantiomer_entry.code
        _cod_related_enantiomer_entry_code
        _cod_enantiomer_of
    );

    my @related_enantiomer_entry_codes;
    for my $tag (@related_enantiomer_tags) {
        next if !defined $data_block->{'values'}{$tag};
        push @related_enantiomer_entry_codes, @{$data_block->{'values'}{$tag}};
    }
    @related_enantiomer_entry_codes = uniq @related_enantiomer_entry_codes;

    return \@related_enantiomer_entry_codes;
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
#       or the 'get_database_entries()' subroutines.
# @param $entry2
#       Data structure of the second entry as returned by the 'cif_fill_data()'
#       or the 'get_database_entries()' subroutines.
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
        $su_1 = 0 if !defined $su_1;
        $su_2 = 0 if !defined $su_2;
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
#       or the 'get_database_entries()' subroutines.
# @param $entry2
#       Data structure of the second entry as returned by the 'cif_fill_data()'
#       or the 'get_database_entries()' subroutines.
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
        next if ( !( defined $entry_1->{$category}{$tag} &&
                     defined $entry_2->{$category}{$tag} ) );
        my $val_1 = $entry_1->{$category}{$tag};
        my $val_2 = $entry_2->{$category}{$tag};
        if ( $val_1 =~ /^${number}$/o || $val_2 =~ /^${number}$/o ) {
            $val_1 =~ s/\([0-9]+\)$//;
            $val_2 =~ s/\([0-9]+\)$//;
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
#       or the 'get_database_entries()' subroutines.
# @param $entry2
#       Data structure of the second entry as returned by the 'cif_fill_data()'
#       or the 'get_database_entries()' subroutines.
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
#       or the 'get_database_entries()' subroutines.
# @param $entry2
#       Data structure of the second entry as returned by the 'cif_fill_data()'
#       or the 'get_database_entries()' subroutines.
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
#       or the 'get_database_entries()' subroutines.
# @param $entry2
#       Data structure of the second entry as returned by the 'cif_fill_data()'
#       or the 'get_database_entries()' subroutines.
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
#       or the 'get_database_entries()' subroutines.
# @param $entry_2
#       Data structure of the second entry as returned by the 'cif_fill_data()'
#       or the 'get_database_entries()' subroutines.
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

sub have_equiv_timestamps
{
    my ($entry_1, $entry_2, $data_name) = @_;

    my $timestamp_1 = $entry_1->{'timestamp'}{$data_name};
    my $timestamp_2 = $entry_2->{'timestamp'}{$data_name};

    if ( !( defined $timestamp_1 && defined $timestamp_2 ) ) {
        return 1;
    }

    my $dt_1;
    my $dt_2;
    eval {
        $dt_1 = parse_datetime($timestamp_1);
        $dt_1->set_time_zone('UTC');
    };
    if ($@) {
        chomp $@;
        warn $@ . "\n";
    }

    eval {
        $dt_2 = parse_datetime($timestamp_2);
        $dt_2->set_time_zone('UTC');
    };
    if ($@) {
        chomp $@;
        warn $@ . "\n";
    }

    if ( !( defined $dt_1 && defined $dt_2 ) ) {
        return 1;
    }

    # Time products are treated as being equal if at least
    # one of them is not defined
    if ( is_date_only_timestamp($timestamp_1) ||
         is_date_only_timestamp($timestamp_2) ) {
        return $dt_1->date() eq $dt_2->date();
    }

    return DateTime->compare($dt_1, $dt_2) == 0 ? 1 : 0;
}

sub entries_are_the_same
{
    my ($entry1, $entry2, $user_options) = @_;

    $user_options = {} if !defined $user_options;
    my %options = %{$user_options};
    foreach my $key (keys %default_options) {
        if ( !defined $options{$key} ) {
            $options{$key} = $default_options{$key};
        }
    };

    return 0 if entries_are_enantiomers( $entry1, $entry2 );

    # FIXME: the logic involving optimal/suboptimal structures seems
    # to be broken. For example, structures that contain the
    # _cod_suboptimal_structure data are not even recognised as themselves
    # by the cif_cod_numbers script
    return 0 if defined $entry1->{'suboptimal'} && $entry1->{'suboptimal'} eq 'yes';
    return 0 if defined $entry2->{'suboptimal'} && $entry2->{'suboptimal'} eq 'yes';

    return 0 if !have_equiv_lattices( $entry1, $entry2, \%options );
    return 0 if !have_equiv_conditions( $entry1, $entry2 );

    # FIXME: the related optimal check is parameter position dependent:
    # ( entries_are_the_same($s1, $s2) != entries_are_the_same($s1, $s2) )
    if ( defined $entry1->{'related_optimal'} &&
         $entry1->{'related_optimal'} eq $entry2->{'id'} &&
         defined $entry1->{'suboptimal'} &&
         $entry1->{'suboptimal'} eq 'yes' ) {
        return 0;
    }

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

    return 1;
}

##
# Evaluates if at least one of the entries is explicitly marked by the COD
# maintainers as an enantiomer of the other. 
#
# @param $entry_1
#       Data structure of the first entry as returned by the 'cif_fill_data()'
#       or the 'get_database_entries()' subroutines.
# @param $entry_2
#       Data structure of the second entry as returned by the 'cif_fill_data()'
#       or the 'get_database_entries()' subroutines.
# @return
#       '1' if at least one of the entries is marked as an enantiomer of the other,
#       '0' otherwise.
##
sub entries_are_enantiomers
{
    my ($entry_1, $entry_2) = @_;

    return 1 if is_related_enantiomer_entry($entry_1, $entry_2);
    return 1 if is_related_enantiomer_entry($entry_2, $entry_1);

    return 0;
}

##
# Evaluates if the main entry references the related entry as an enantiomer.
#
# @param $main_entry
#       Data structure of the main entry as returned by the 'cif_fill_data()'
#       or the 'get_database_entries()' subroutines.
# @param $related_entry
#       Data structure of the relared entry as returned by the 'cif_fill_data()'
#       or the 'get_database_entries()' subroutines.
# @return
#       '1' if the main entry references the related entry as an enantiomer,
#       '0' otherwise.
##
sub is_related_enantiomer_entry
{
    my ($main_entry, $related_entry) = @_;

    my @enantiomer_entries;

    # FIXME: the following code block should be removed once
    # the 'enantiomer' entry field is properly deprecated and removed 
    # BEGIN
    if (defined $main_entry->{'enantiomer'}) {
        my @enantiomer_tags = qw(
            _cod_related_enantiomer_entry.code
            _cod_related_enantiomer_entry_code
            _cod_enantiomer_of
        );
        for my $tag (@enantiomer_tags) {
            next if !defined $main_entry->{'enantiomer'}{$tag};
            push @enantiomer_entries, $main_entry->{'enantiomer'}{$tag};
        }
    }
    # END

    if (exists $main_entry->{'related_enantiomer_entries'}) {
        push @enantiomer_entries, @{$main_entry->{'related_enantiomer_entries'}};
    }

    my $is_enantiomer = any { $_ eq $related_entry->{'id'} } @enantiomer_entries;

    return $is_enantiomer ? 1 : 0;
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

sub prepare_database_query
{
    my ( $dbh, $database, $user_options ) = @_;

    $user_options = {} if !defined $user_options;
    my %options = %{$user_options};
    foreach my $key (keys %default_options) {
        if ( !defined $options{$key} ) {
            $options{$key} = $default_options{$key};
        }
    };
    my $cod_series_prefix = defined $options{'cod_series_prefix'} ?
                                    $options{'cod_series_prefix'} : '';

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

    return $sth;
}

sub get_database_entries
{
    my ( $sth, $data, $db_fields2tags ) = @_;

    my $COD = ();
    for my $id (keys %{$data}) {
        for my $formula (( $data->{$id}{chemical_formula_sum},
                           $data->{$id}{calc_formula},
                           $data->{$id}{cell_formula} )) {
            next if !defined $formula;
            my $query_formula = '- ' . $formula . ' -';
            my $rv = $sth->execute( $query_formula,
                                    $query_formula,
                                    $query_formula );
            if( defined $rv ) {
                $COD->{$formula} = [];
                while ( my $row = $sth->fetchrow_hashref() ) {
                    my $entry = build_entry_from_db_row( $row, $db_fields2tags );
                    push @{$COD->{$formula}}, $entry;
                }
            } else {
                die "ERROR, error fetching formula '${formula}'" .
                     ( defined $DBI::errstr ? ' -- ' .
                               lcfirst( $DBI::errstr) : '' );
            }
        }
    }

    return $COD;
}

sub build_entry_from_db_row
{
    my ($db_row, $db_fields2tags) = @_;

    my $entry = {
        'filename' => $db_row->{'file'},
        'id'       => $db_row->{'file'},
    };

    for my $category (keys %{$db_fields2tags}) {
        my $fields = $db_fields2tags->{$category};
        for my $field ( keys %{$fields} ) {
            $entry->{$category}{$fields->{$field}} = $db_row->{$field};
        }
    }

    return $entry;
}

1;
