#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Parse a CIF file, prepare a COD database table entry from it.
#**

package COD::CIF::Data::CIF2COD;

use strict;
use warnings;
use COD::Cell qw( cell_volume );
use COD::CIF::Data qw( get_cell get_formula_units_z );
use COD::CIF::Data::CellContents qw( cif_cell_contents );
use COD::CIF::Data::CODFlags qw( is_disordered has_coordinates has_Fobs );
use COD::CIF::Data::Check qw( check_formula_sum_syntax );
use COD::CIF::Data::EstimateZ qw( cif_estimate_z );
use COD::CIF::Unicode2CIF qw( cif2unicode );
use COD::CIF::Tags::Manage qw( cifversion get_data_value get_aliased_value );
use COD::CIF::Tags::DictTags;
use COD::Spacegroups::Names;
use Scalar::Util qw( looks_like_number );
use List::MoreUtils qw( uniq none any );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    cif2cod
    validate_SQL_types
    @default_data_fields
);

# The default sql table data field that was taken from the
# cod-add-data.sh script.
our @default_data_fields = qw (
    file
    a
    siga
    b
    sigb
    c
    sigc
    alpha
    sigalpha
    beta
    sigbeta
    gamma
    siggamma
    vol
    sigvol
    celltemp
    sigcelltemp
    diffrtemp
    sigdiffrtemp
    cellpressure
    sigcellpressure
    diffrpressure
    sigdiffrpressure
    thermalhist
    pressurehist
    compoundsource
    nel
    sg
    sgHall

    commonname
    chemname
    mineral
    formula
    calcformula
    cellformula

    Z
    Zprime

    acce_code
    authors
    title
    journal
    year
    volume
    issue
    firstpage
    lastpage
    doi

    method
    radiation
    wavelength
    radType
    radSymbol

    Rall
    Robs
    Rref
    wRall
    wRobs
    wRref
    RFsqd
    RI

    gofall
    gofobs
    gofgt
    gofref

    duplicateof
    optimal
    status
    flags
    text
    onhold
);

my @data_fields = @default_data_fields;

# A hash of text fields that do no require specific processing
# and can be taken directly from the associated data items
my %text_value_fields2tags = (
   'thermalhist'    => [ qw( _exptl_crystal_thermal_history ) ],
   'pressurehist'   => [ qw( _exptl_crystal_pressure_history ) ],
   'compoundsource' => [ qw( _chemical_compound_source ) ],
   'commonname'     => [ qw( _chemical_name_common ) ],
   'chemname'       => [ qw( _chemical_name_systematic ) ],
   'mineral'        => [ qw( _chemical_name_mineral ) ],
   'formula'        => [ qw( _chemical_formula_sum ) ],
   'radiation'      => [ qw( _diffrn_radiation_probe ) ],
   'radType'        => [ qw( _diffrn_radiation_type ) ],
   'radSymbol'      => [ qw( _diffrn_radiation_xray_symbol ) ],
   'duplicateof'    => [ qw( _cod_related_duplicate_entry.code
                             _cod_related_duplicate_entry_code
                             _cod_duplicate_entry
                             _[local]_cod_duplicate_entry ) ],
   'optimal'        => [ qw( _cod_related_optimal_entry.code
                             _cod_related_optimal_entry_code
                             _cod_related_optimal_struct
                             _[local]_cod_related_optimal_struct ) ],
   'onhold'         => [ qw( _cod_depositor.requested_release_date
                             _cod_depositor_requested_release_date
                             _cod_hold_until_date ) ],

   'title'          => [ qw( _publ_section_title ) ],
   'journal'        => [ qw( _journal_name_full ) ],
   'year'           => [ qw( _journal_year ) ],
   'volume'         => [ qw( _journal_volume ) ],
   'issue'          => [ qw( _journal_issue ) ],
   'firstpage'      => [ qw( _journal_page_first ) ],
   'lastpage'       => [ qw( _journal_page_last ) ],
   'doi'            => [ qw( _journal_paper_doi ) ],
);

# A hash of numeric fields that do no require specific processing
# and can be taken directly from the associated data items
my %num_value_fields2tags = (
    'a'             => [ qw( _cell_length_a ) ],
    'b'             => [ qw( _cell_length_b ) ],
    'c'             => [ qw( _cell_length_c ) ],
    'alpha'         => [ qw( _cell_angle_alpha ) ],
    'beta'          => [ qw( _cell_angle_beta ) ],
    'gamma'         => [ qw( _cell_angle_gamma ) ],
    'vol'           => [ qw( _cell_volume ) ],
    'celltemp'      => [ qw( _cell_measurement_temperature ) ],
    'diffrtemp'     => [ qw( _diffrn_ambient_temperature ) ],
    'cellpressure'  => [ qw( _cell_measurement_pressure ) ],
    'diffrpressure' => [ qw( _diffrn_ambient_pressure ) ],
    'wavelength'    => [ qw( _diffrn_radiation_wavelength ) ],
    'Rall'          => [ qw( _refine_ls_R_factor_all ) ],
    'Robs'          => [ qw( _refine_ls_R_factor_gt
                             _refine_ls_R_factor_obs ) ],
    'Rref'          => [ qw( _refine_ls_R_factor_ref ) ],
    'wRall'         => [ qw( _refine_ls_wR_factor_all ) ],
    'wRobs'         => [ qw( _refine_ls_wR_factor_gt
                             _refine_ls_wR_factor_obs ) ],
    'wRref'         => [ qw( _refine_ls_wR_factor_ref ) ],
    'RFsqd'         => [ qw( _refine_ls_R_Fsqd_factor ) ],
    'RI'            => [ qw( _refine_ls_R_I_factor ) ],
    'gofall'        => [ qw( _refine_ls_goodness_of_fit_all ) ],
    # NOTE: 'gofobs' and 'gofgt' intentionally store the same data.
    # One of these columns will be removed in the future
    'gofobs'        => [ qw( _refine_ls_goodness_of_fit_gt
                             _refine_ls_goodness_of_fit_obs ) ],
    'gofgt'         => [ qw( _refine_ls_goodness_of_fit_gt
                             _refine_ls_goodness_of_fit_obs ) ],
    'gofref'        => [ qw( _refine_ls_goodness_of_fit_ref ) ],
);

# A hash of s.u. fields that do no require specific processing
# and can be taken directly from the associated data items
my %su_fields2tags = (
    'siga'             => [ qw( _cell_length_a ) ],
    'sigb'             => [ qw( _cell_length_b ) ],
    'sigc'             => [ qw( _cell_length_c ) ],
    'sigalpha'         => [ qw( _cell_angle_alpha ) ],
    'sigbeta'          => [ qw( _cell_angle_beta ) ],
    'siggamma'         => [ qw( _cell_angle_gamma ) ],
    'sigvol'           => [ qw( _cell_volume ) ],
    'sigcelltemp'      => [ qw( _cell_measurement_temperature ) ],
    'sigdiffrtemp'     => [ qw( _diffrn_ambient_temperature ) ],
    'sigcellpressure'  => [ qw( _cell_measurement_pressure ) ],
    'sigdiffrpressure' => [ qw( _diffrn_ambient_pressure ) ],
    # TODO: sigwavelength is not defined?
);

my %space_groups = map {
    my $key1 = $_->[1];
    my $key2 = $_->[2];
    $key1 =~ s/\s//g;
    $key2 =~ s/\s//g;
    ($key1, $_->[2], $key2, $_->[2] )
} @COD::Spacegroups::Names::names;

##
# Extracts SQL database column values from a CIF data block.
#
# @param $dataset
#       Reference to data block as returned by the COD::CIF::Parser.
# @param $options
#       Reference to a hash of options. The following options are recognised:
#       {
#       # Boolean value. Default '0'.
#       # Treat DOI as sufficient bibliographic information without requiring
#       # additional bibliographic details such as authors, journal name, etc.
#           'require_only_doi' => 0,
#       # Boolean value. Default '0'.
#       # Include the implicit hydrogen atoms into the summary chemical formula.
#       # The implicit hydrogen atoms are specified using
#       # the _atom_site_attached_hydrogens data item.
#           'use_attached_hydrogens' => 1,
#       # Boolean value. Default '1'.
#       # Accept data blocks without fractional coordinates.
#           'use_datablocks_without_coord' => 0,
#       # Boolean value. Default '0'.
#       # Correct the formatting of Hermann-Mauguin symmetry space group symbol.
#           'reformat_space_group' => 0,
#       # String value. Default: undef.
#       # A seven digit string that should be used as the COD ID of this
#       # entry instead of using the data block name as the COD ID.
#           'cod_number' => '0123456'
#       }
#   @return \%data
#       Reference to a hash where database column names serve as the hash keys.
##
sub cif2cod
{
    my ( $dataset, $options ) = @_;

    $options = {} unless defined $options;

    my $require_only_doi =
            exists $options->{'require_only_doi'} ?
                   $options->{'require_only_doi'} : 0;
    my $use_datablocks_without_coord =
            exists $options->{'use_datablocks_without_coord'} ?
                   $options->{'use_datablocks_without_coord'} : 0;
    my $use_attached_hydrogens =
            exists $options->{'use_attached_hydrogens'} ?
                   $options->{'use_attached_hydrogens'} : 1;
    my $reformat_space_group =
            exists $options->{'reformat_space_group'} ?
                   $options->{'reformat_space_group'} : 0;
    my $cod_number = $options->{'cod_number'};

    my %data = ();
    my $values = $dataset->{'values'};
    my $sigmas = $dataset->{'precisions'};

    if ( !exists $values->{'_atom_site_fract_x'} &&
         !$use_datablocks_without_coord ) {
        warn "data block does not contain fractional coordinates\n";
        return;
    };

    # Produce a list of data items that should be reported as mandatory/missing
    my @mandatory_tags = qw( formula );
    # TODO: the actual value of the doi is not examined. It could potentially
    # be a CIF special value, i.e. '?' or '.'
    if ( !$require_only_doi || !exists $values->{'_journal_paper_doi'} ) {
        push @mandatory_tags, qw( title journal year volume );
        # TODO: same issue as above
        # missing journal pages should not be reported
        # if a journal article reference is provided
        if ( !exists $values->{'_journal_article_reference'} ) {
            push @mandatory_tags, qw( firstpage );
        }
    }
    # Report mandatory data items
    report_mandatory_data_items( $values, \@mandatory_tags );

    $data{'sg'} =
        get_space_group_h_m_symbol( $values,
        { 'reformat_space_group' => $reformat_space_group } );
    $data{'sgHall'} =
        get_space_group_Hall_symbol( $values );

    # Get text values directly from CIF data items
    for my $field ( sort keys %text_value_fields2tags ) {
        $data{$field} = get_aliased_value( $values, $text_value_fields2tags{$field} );
    };

    # Get numeric values directly from CIF data items
    for my $field ( sort keys %num_value_fields2tags ) {
        $data{$field} = get_aliased_value( $values, $num_value_fields2tags{$field} );
    }

    # Get su values directly from CIF data items
    for my $field ( sort keys %su_fields2tags ) {
        $data{$field} = get_aliased_value( $sigmas, $su_fields2tags{$field} );
    };

    # process numeric values
    for my $field ( keys %num_value_fields2tags, %su_fields2tags ) {
        $data{$field} = filter_num($data{$field});
    };

    # Set undef if the current value is an empty string
    my $empty_value_regex = qr/^[\s?]*$/s;
    for ( qw( celltemp      sigcelltemp
              diffrtemp     sigdiffrtemp
              cellpressure  sigcellpressure
              diffrpressure sigdiffrpressure
              formula chemname commonname mineral
              journal year volume issue firstpage lastpage ) ) {
        if ( defined $data{$_} ) {
            if ( $data{$_} =~ $empty_value_regex ) {
                $data{$_} = undef;
            }
        }
    };

    # Convert CIF notation to Unicode
    for ( qw( chemname commonname mineral
              compoundsource
              radType radSymbol
              journal title ) ) {
        if ( defined $data{$_} &&
            ( !cifversion( $dataset ) || cifversion( $dataset ) eq '1.1' ) ) {
            $data{$_} = cif2unicode($data{$_});
        }
    };

    # Remove all white spaces
    for ( qw( radType radSymbol ) ) {
        if ( defined $data{$_} ) {
            $data{$_} =~ s/\s+//g;
        }
    };

    foreach my $key ( keys %data ) {
        if ( defined $data{$key} ) {
            $data{$key} = clean_whitespaces( $data{$key} )
        }
    }

    # Fields that require a more complex logic
    $data{'file'}   = defined $cod_number ? $cod_number : $dataset->{'name'};
    $data{'flags'}  = get_cod_flags( $dataset );
    $data{'status'} = get_cod_status( $dataset );
    $data{'method'} = get_experimental_method( $values );

    if (!defined $data{'vol'}) {
        $data{'vol'} = calculate_cell_volume($values);
        # TODO: should the calculated s.u. also be recorded?
    }

    my $Z;
    my $warning;
    {
        local $SIG{__WARN__} = sub {
            $warning = $_[0];
            chomp $warning;
        };
        $Z = get_formula_units_z( $dataset );
    }
    if ( defined $warning ) {
        warn "WARNING, $warning -- the Z value will be estimated" . "\n";
    }

    if (!defined $Z) {
        eval {
            $Z = cif_estimate_z( $dataset, { 'cell_volume' => $data{'vol'} } );
        };
        if( $@ ) {
            my $msg = $@;
            $msg =~ s/^ERROR, //;
            $msg =~ s/\n$//;
            warn "WARNING, $msg -- assuming Z = 1.\n";
            $Z = undef;
        } else {
            warn "WARNING, taking the estimated Z value Z = $Z" . "\n";
        }
    }
    $data{'Z'} = $Z;

    $data{'Zprime'} = compute_z_prime( $data{'Z'}, $data{'sg'} );

    $data{'authors'} = get_authors( $dataset );
    $data{'text'}    = concat_text_field(\%data);
    $data{'acce_code'} =
        get_coeditor_code( $values, { 'journal' => $data{'journal'} } );

    if ( defined $data{'formula'} ) {
        for ( @{ check_formula_sum_syntax( $data{'formula'} ) } ) {
            warn $_ . "\n";
        };
        $data{'formula'} = '- ' . $data{'formula'} . ' -';
    } else {
        $data{'formula'} = '?';
    }

    $data{'calcformula'} =
        calculate_formula_sum($dataset, {
            'Z' => defined $data{'Z'} ? $data{'Z'} : 1,
            'use_attached_hydrogens' => $use_attached_hydrogens
        }
    );

    $data{'cellformula'} =
        calculate_formula_sum($dataset, {
            'use_attached_hydrogens' => $use_attached_hydrogens,
            'Z' => 1,
            'formula_type' => 'unit cell'
        }
    );

    # get_number_of_elements() subroutine must be called only
    # after the assignment of the 'formula' and 'calcformula' fields
    $data{'nel'} = get_number_of_elements( {
        'formula'     => $data{'formula'},
        'calcformula' => $data{'calcformula'}
    } );

    return \%data;
}

sub report_mandatory_data_items
{
    my ( $values, $mandatory_tags ) = @_;

    for my $field ( @{$mandatory_tags} ) {
        for my $tag ( @{$text_value_fields2tags{$field}} ) {
            if ( !defined $values->{$tag} ) {
                warn "WARNING, data item '$tag' is absent.\n";
            }
        }
    };

    return;
}

sub filter_num
{
    my ($value) = @_;

    if ( defined $value && $value ne '?' && $value ne '.' ) {
        $value =~ s/[(].*[)]$//;
    } else {
        $value = undef;
    }

    return $value;
}

sub calculate_formula_sum
{
    my ($dataset, $options) = @_;

    my $Z = $options->{'Z'};
    my $formula_type = $options->{'formula_type'};
    my $use_attached_hydrogens = $options->{'use_attached_hydrogens'};

    my $formula;
    eval {
        $formula = cif_cell_contents( $dataset, $Z, $use_attached_hydrogens );
    };
    if( $@ ) {
        # ERRORS that originated within the function are downgraded to warnings
        my $error = $@;
        $error =~ s/[A-Z]+, //;
        chomp $error;
        warn 'WARNING, ' . (defined $formula_type ? "$formula_type " : '' ) .
             "summary formula could not be calculated -- $error\n";
    }

    # FIXME: the local formula mitigations were a quick fix, however,
    # it would be worthwhile to investigate and correct the issue
    # in the formula generation subroutine
    if ( defined $formula ) {
        # Mitigate formula generated by unknown ('?') atomic coordinates
        if ( $formula =~ m/^[?][0-9.]*$/ ) {
            return undef;
        }
        # Mitigate formula generated by inapplicable ('.') atomic coordinates
        if ( $formula eq '' ) {
            return undef;
        }
        # Decorate the existing formula
        $formula = '- ' . $formula . ' -';
    }

    return $formula;
}

sub calculate_cell_volume
{
    my ($values) = @_;

    my @cell = get_cell( $values, { silent => 1 } );
    my $cell_volume = scalar cell_volume( @cell );
    if ( defined $cell_volume ) {
        $cell_volume = sprintf '%7.2f', $cell_volume;
        $cell_volume =~ s/\s+//g;
    }

    return $cell_volume;
}

sub get_cod_flags
{
    my ( $dataset ) = @_;

    # Compose COD flags:
    my @flags;

    push @flags, 'has coordinates' if has_coordinates( $dataset );
    push @flags, 'has disorder'    if is_disordered( $dataset );
    push @flags, 'has Fobs'        if has_Fobs( $dataset );

    return join ',', @flags;
}

##
# Determines the 'status' column value from the values of
# the '_cod_entry_issue.severity' and '_cod_error_flag' data items.
#
# @param $data_block
#       Reference to data block as returned by the COD::CIF::Parser.
# @return
#       Text string that should be inserted into the 'status' column or
#       undef if such value could not be determined.
##
sub get_cod_status
{
    my ($data_block) = @_;

    my %cod_status;

    my $issue_status = get_cod_status_from_issue_severity($data_block);
    if (defined $issue_status) {
        $cod_status{$issue_status}++
    }

    my $flag_status = get_cod_status_from_error_flag($data_block);
    if (defined $flag_status) {
        $cod_status{$flag_status}++
    }

    return 'retracted' if exists $cod_status{'retracted'};
    return 'errors'    if exists $cod_status{'errors'};
    return 'warnings'  if exists $cod_status{'warnings'};

    return;
}

##
# Determines the 'status' column value from the value of
# the '_cod_entry_issue.severity' data item.
#
# @param $data_block
#       Reference to data block as returned by the COD::CIF::Parser.
# @return
#       Text string that should be inserted into the 'status' column or
#       undef if such value could not be determined.
##
sub get_cod_status_from_issue_severity
{
    my ($data_block) = @_;

    my $values = $data_block->{'values'};

    my @issue_severity_tags = qw(
        _cod_entry_issue.severity
        _cod_entry_issue_severity
    );

    my $issue_severity_tag;
    for my $tag ( @issue_severity_tags ) {
        if ( exists $values->{$tag} ) {
            $issue_severity_tag = $tag;
            last;
        }
    }
    return if !defined $issue_severity_tag;

    my %severity_level;
    for my $severity ( @{$values->{$issue_severity_tag}} ) {
        $severity_level{$severity}++
    };

    my @known_severity_levels = qw(
        note
        warning
        error
        retraction
    );

    for my $severity (sort keys %severity_level) {
        next if any {$_ eq $severity} @known_severity_levels;
        warn "data item '$issue_severity_tag' value '$severity' does " .
             'not belong to the set of known severity levels [' .
             ( join ', ', map { "'$_'" } @known_severity_levels ) . ']' .
             ' -- value will be ignored' . "\n";
    }

    return 'retracted' if exists $severity_level{'retraction'};
    return 'errors'    if exists $severity_level{'error'};
    return 'warnings'  if exists $severity_level{'warning'};

    return;
}

##
# Determines the 'status' column value from the value of
# the '_cod_error_flag' data item.
#
# @param $data_block
#       Reference to data block as returned by the COD::CIF::Parser.
# @return
#       Text string that should be inserted into the 'status' column or
#       undef if such value could not be determined.
##
sub get_cod_status_from_error_flag
{
    my ($data_block) = @_;

    my $values = $data_block->{'values'};

    my @error_flag_tags = qw(
        _cod_error_flag
        _[local]_cod_error_flag
    );

    my $error_flag_tag;
    for my $tag ( @error_flag_tags ) {
        if ( exists $values->{$tag} ) {
            $error_flag_tag = $tag;
            last;
        }
    }
    return if !defined $error_flag_tag;

    my $status = $values->{$error_flag_tag}[0];
    my @known_error_flags = qw(
        none
        warnings
        errors
        retracted
    );

    if ( none { $_ eq $status } @known_error_flags ) {
        warn "data item '$error_flag_tag' value '$status' does " .
             'not belong to the set of known error flags [' .
             ( join ' ,', map {"'$_'"} @known_error_flags ) . '] ' .
             '-- value will be ignored' . "\n";
    }

    return 'retracted' if $status eq 'retracted';
    return 'errors'    if $status eq 'errors';
    return 'warnings'  if $status eq 'warnings';

    return;
}

##
# Determines the value of the 'nel' (number of distinct chemical elements)
# field from the explicitly provided and calculated summary formulae.
#
# @param $formulae_values
#       Reference to a hash of formulae values:
#       {
#           # Summary chemical formula as explicitly provided in the CIF file
#           'formula'    => 'H2 O'
#           # Summary chemical formula calculated from the atomic coordinates
#           'calcformula'=> 'H2 O'
#       }
# @return
#       Number of distinct chemical elements.
##
sub get_number_of_elements
{
    my ( $formulae_values ) = @_;

    my $formula;
    if ( $formulae_values->{'formula'} ne '?'  ) {
        $formula = $formulae_values->{'formula'};
    } elsif ( defined $formulae_values->{'calcformula'} ) {
        $formula = $formulae_values->{'calcformula'};
    }

    my $number_of_elements = 0;
    if ( defined $formula ) {
        $number_of_elements = count_number_of_elements( $formula )
    }

    return $number_of_elements;
}

sub get_authors
{
    my ( $dataset ) = @_;
    my $values = $dataset->{values};
    my $authors;
    if( exists $values->{'_publ_author_name'} ) {
        my @authors = @{$values->{'_publ_author_name'}};
        if( !cifversion( $dataset ) ||
             cifversion( $dataset ) eq '1.1' ) {
            @authors = map { cif2unicode($_) } @authors;
        }
        $authors = join '; ', map { clean_whitespaces($_) } @authors;
    }

    return $authors;
}

sub concat_text_field
{
    my ($biblio) = @_;

    my $authors    = defined $biblio->{'authors'}   ?
                             $biblio->{'authors'}   : '';
    my $title      = defined $biblio->{'title'}     ?
                             $biblio->{'title'}     : '';
    my $journal    = defined $biblio->{'journal'}   ?
                             $biblio->{'journal'}   : '';
    my $year       = defined $biblio->{'year'}      ?
                             $biblio->{'year'}      : '';
    my $volume     = defined $biblio->{'volume'}    ?
                             $biblio->{'volume'}    : '';
    my $issue      = defined $biblio->{'issue'}     ?
                             $biblio->{'issue'}     : '';
    my $first_page = defined $biblio->{'firstpage'} ?
                             $biblio->{'firstpage'} : '';
    my $last_page  = defined $biblio->{'lastpage'}  ?
                             $biblio->{'lastpage'}  : '';

    my $text = join '\n', map { clean_whitespaces( $_ ) }
                     ( $authors, $title, $journal, $volume .
                       ( $issue ? ( $volume ? "($issue)" :
                                   "(issue $issue)") : '' ),
                       '(' . $year . ')',
                       ( $last_page ? $first_page . '-' . $last_page :
                         $first_page ) );

    return $text;
}

sub count_number_of_elements
{
    my ( $formula ) = @_;
    my @elements;
    for my $el ( split ' ', $formula ) {
        $el =~ s/[^A-Za-z]//g;
        if ( $el =~ /^[A-Za-z]+$/ ) {
            push @elements, $el;
        }
    }
    my @unique = uniq @elements;

    return int @unique;
}

sub clean_whitespaces
{
    my ( $value ) = @_;

    $value =~ s/\n/ /g;
    $value =~ s/\s+/ /g;
    $value =~ s/^\s*|\s*$//g;

    return $value;
}

sub get_space_group_h_m_symbol
{
    my ($values, $options) = @_;

    my $reformat_sg =
        exists $options->{'reformat_space_group'} ?
               $options->{'reformat_space_group'} : 0;

    my @space_group_tags = qw (
        _space_group_name_H-M_alt
        _space_group.name_H-M_full
        _symmetry_space_group_name_H-M
        _space_group_ssg_name
        _space_group_ssg_name_IT
        _space_group_ssg_name_WJJ
    );

    my $space_group;

    for my $sg_tag (@space_group_tags) {
        if( exists $values->{$sg_tag} ) {
            $space_group = $values->{$sg_tag}[0];
            if( $sg_tag =~ /_H-M/ && $reformat_sg ) {
                my $orig_sg = $space_group;
                $orig_sg =~ s/[()~_\s]//g;
                ## print ">>> $orig_sg\n";
                if( exists $space_groups{$orig_sg} ) {
                    $space_group = $space_groups{$orig_sg};
                }
            }
            last
        }
    }
    if( !defined $space_group ) {
        warn "WARNING, no space group information found\n";
    } else {
        $space_group =~ s/^\s*|\s*$//g;
    }
    return $space_group;
}

sub get_space_group_Hall_symbol
{
    my ($values) = @_;

    my @space_group_tags = qw (
        _space_group_name_Hall
        _symmetry_space_group_name_Hall
    );

    my $space_group;

    for my $sg_tag (@space_group_tags) {
        if( exists $values->{$sg_tag} ) {
            $space_group = $values->{$sg_tag}[0];
            last
        }
    }
    if( !defined $space_group ) {
        warn "WARNING, no Hall space group symbol found\n";
    } else {
        $space_group =~ s/^\s*|\s*$//g;
    }
    return $space_group;
}

sub get_experimental_method
{
    my ($values) = @_;

    my @determination_method_tags = qw(
        _cod_structure.determination_method
        _cod_structure_determination_method
        _cod_struct_determination_method
    );
    my $method = get_aliased_value($values, \@determination_method_tags);
    return $method if defined $method;

    my @powder_tags = grep { /^_pd_/ }
                        @COD::CIF::Tags::DictTags::tag_list;

    for my $tag (@powder_tags) {
        if( exists $values->{$tag} ) {
            return 'powder diffraction';
        }
    }

    for my $tag ( qw( _exptl_crystals_number _exptl.crystals_number ) ) {
        if( exists $values->{$tag} ) {
            return 'single crystal';
        }
    }

    return;
}

sub get_coeditor_code
{
    my ($values, $options) = @_;

    my $journal_name = $options->{'journal'};

    my $acce_code;

    for ( qw( _journal_coeditor_code
              _journal.coeditor_code ) ) {
        if( exists $values->{$_} ) {
            $acce_code = get_data_value( $values, $_, 0 );
            last;
        }
    }

    # Ad hoc logic for Acta Crystallograhica journals to determine
    # the coeditor code from the orignal file name
    if ( !defined $acce_code && defined $journal_name &&
         $journal_name =~ /^Acta Cryst/ ) {
        for ( qw( _cod_data_source.file
                  _cod_data_source_file
                  _[local]_cod_data_source_file ) ) {
            if( exists $values->{$_} ) {
                $acce_code = get_data_value( $values, $_, 0 );
                last;
            }
        }

        if ( defined $acce_code ) {
            $acce_code =~ s/[.].*$//g;
            if( $acce_code !~ /^[a-zA-Z]{1,2}[0-9]{4,5}$/ ) {
                $acce_code = undef;
            }
        }
    }

    if ( defined $acce_code ) { $acce_code = uc $acce_code };

    return $acce_code;
}

sub compute_z_prime
{
    my ( $Z, $space_group_h_m ) = @_;

    return if !defined $Z;
    return if !defined $space_group_h_m;

    use COD::Spacegroups::Lookup::COD;
    my @sg_description =
        grep { $space_group_h_m eq $_->{'universal_h_m'} }
             @COD::Spacegroups::Lookup::COD::table;

    if( int(@sg_description) == 1 ) {
        my $au_count = int @{$sg_description[0]{symops}};
        return $Z / $au_count;
    }

    return;
}

sub validate_SQL_types
{
    my( $data, $types ) = @_;

    for my $key (sort keys %{$data}) {
        next if !defined $data->{$key};
        next if !exists $types->{$key};

        if( $types->{$key} =~ /^(float|double|(small|medium)int)/i &&
            !(looks_like_number( $data->{$key} ) &&
              $data->{$key} !~ /^[+-]?(inf|nan)/i) ) {
            warn "value of '$key' ('$data->{$key}') does not seem " .
                 'to be numeric -- value will be treated as undefined' . "\n";
            $data->{$key} = undef;
            next;
        }

        if( $types->{$key} =~ /unsigned/i &&
            $data->{$key} < 0 ) {
            warn "value of '$key' ('$data->{$key}') is negative, " .
                 'while it must be unsigned -- value will be treated as ' .
                 'undefined' . "\n";
            $data->{$key} = undef;
            next;
        }

        if( $types->{$key} =~ /^(var)?char[(]([0-9]+)[)]/i ) {
            my $max_length = $2;
            my $val_length = length( $data->{$key} );
            if( $val_length > $max_length ) {
                warn "value of '$key' ('$data->{$key}') is longer " .
                     "than allowed ($val_length > $max_length) " .
                     'and may be corrupted upon casting -- ' .
                     'value will be treated as undefined' . "\n";
                $data->{$key} = undef;
            }
        }
    }

    return;
}

1;
