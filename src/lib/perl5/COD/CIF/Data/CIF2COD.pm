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
use COD::CIF::Data qw( get_cell );
use COD::CIF::Data::CellContents qw( cif_cell_contents );
use COD::CIF::Data::CODFlags qw( is_disordered has_coordinates has_Fobs );
use COD::CIF::Unicode2CIF qw( cif2unicode );
use COD::CIF::Tags::DictTags;
use COD::Spacegroups::Names;
use Scalar::Util qw( looks_like_number );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    cif2cod
    validate_SQL_types
    @default_data_fields
    @new_data_fields
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
    nel
    sg
    sgHall
    commonname
    chemname
    formula
    calcformula
    acce_code
    authors
    title
    journal
    year
    volume
    issue
    firstpage
    lastpage
    duplicateof
    optimal
    status
    flags
    text
);

my @data_fields = @default_data_fields;

# New sql table data fields.

our @new_data_fields = qw (
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

    duplicateof
    optimal
    status
    flags
    text
    onhold
);

my %space_groups = map {
    my $key1 = $_->[1];
    my $key2 = $_->[2];
    $key1 =~ s/\s//g;
    $key2 =~ s/\s//g;
    ($key1, $_->[2], $key2, $_->[2] )
} @COD::Spacegroups::Names::names;

sub cif2cod
{
    my( $dataset, $options ) = @_;

    $options = {} unless defined $options;

    my $require_only_doi =
        exists $options->{'require_only_doi'} ?
               $options->{'require_only_doi'} : 0;
    my $use_datablocks_without_coord =
        exists $options->{'use_datablocks_without_coord'} ?
               $options->{'use_datablocks_without_coord'} : 0;
    my $use_attached_hydrogens =
        exists $options->{'use_attached_hydrogens'} ?
               $options->{'use_attached_hydrogens'} : 0;
    my $cod_number = $options->{'cod_number'};

    my %data = ();
    my $values = $dataset->{values};
    my $sigmas = $dataset->{precisions};
    my $dataname = $dataset->{name};

    if ( !exists $values->{_atom_site_fract_x} &&
         !$use_datablocks_without_coord ) {
        warn "data block does not contain fractional coordinates\n";
        return;
    };

    my @authors = ();
    if( exists $values->{_publ_author_name} ) {
        for my $i (0..$#{$values->{_publ_author_name}}) {
            push @authors, get_tag( $values, '_publ_author_name', $i );
        }
    }

    my $authors = join '; ', @authors;

    my( $title, $journal, $year, $volume, $first_page );
    my %opt_biblio_tags = ( '_publ_section_title' => \$title,
                            '_journal_name_full'  => \$journal,
                            '_journal_year'       => \$year,
                            '_journal_volume'     => \$volume,
                            '_journal_page_first' => \$first_page );
    for my $tag (sort keys %opt_biblio_tags) {
        if( ($require_only_doi &&
             exists $values->{_journal_paper_doi}) ||
            ($tag eq '_journal_page_first' &&
             exists $values->{_journal_article_reference}) ) {
            ${$opt_biblio_tags{$tag}} = get_tag_silently( $values,
                                                          $tag,
                                                          0 );
        } else {
            ${$opt_biblio_tags{$tag}} = get_tag( $values,
                                                 $tag,
                                                 0 );
        }
    }

    my $last_page = get_tag_silently( $values, '_journal_page_last', 0 );
    my $issue = get_tag_silently( $values, '_journal_issue', 0 );

    my $text = join '\n', map { clean_whitespaces( cif2unicode($_) ) }
                     ( $authors, $title, $journal, $volume .
                       ( $issue? ( $volume ? "($issue)" :
                                   "(issue $issue)") : '' ),
                       '(' . $year . ')',
                       ( $last_page ? $first_page . '-' . $last_page :
                         $first_page ) );

    my $calc_formula;
    eval {
        $calc_formula =
                cif_cell_contents( $dataset, undef, $use_attached_hydrogens );
    };
    if( $@ ) {
        # ERRORS that originated within the function are downgraded to warnings
        my $error = $@;
        $error =~ s/[A-Z]+, //;
        chomp $error;
        warn "WARNING, summary formula could not be calculated -- $error\n";
    }

    my $cell_formula;
    eval {
        $cell_formula =
                cif_cell_contents( $dataset, 1, $use_attached_hydrogens );
    };
    if( $@ ) {
        # ERRORS that originated within the function are downgraded to warnings
        my $error = $@;
        $error =~ s/[A-Z]+, //;
        chomp $error;
        warn "WARNING, unit cell summary formula could not be calculated -- $error\n";
    }

    my $formula = get_tag( $values, '_chemical_formula_sum', 0 );
    my $empty_value_regex = qr/^[\s?]*$/s;

    undef $formula if defined $formula &&
          $formula =~ $empty_value_regex;

    # Setting the default number of unique elements to 0
    my $nel = 0;
    if( defined $formula ) {
        check_chem_formula( $formula );
        $nel = count_number_of_elements( $formula );
    }

    $data{'file'} = defined $cod_number ? $cod_number : $dataname;

    $data{'a'} = get_num_or_undef( $values, '_cell_length_a', 0 );
    $data{'siga'} = get_num_or_undef( $sigmas, '_cell_length_a', 0 );
    $data{'b'} = get_num_or_undef( $values, '_cell_length_b', 0 );
    $data{'sigb'} = get_num_or_undef( $sigmas, '_cell_length_b', 0 );
    $data{'c'} = get_num_or_undef( $values, '_cell_length_c', 0 );
    $data{'sigc'} = get_num_or_undef( $sigmas, '_cell_length_c', 0 );
    $data{'alpha'} = get_num_or_undef( $values, '_cell_angle_alpha', 0 );
    $data{'sigalpha'} = get_num_or_undef( $sigmas, '_cell_angle_alpha', 0 );
    $data{'beta'} = get_num_or_undef( $values, '_cell_angle_beta', 0 );
    $data{'sigbeta'} = get_num_or_undef( $sigmas, '_cell_angle_beta', 0 );
    $data{'gamma'} = get_num_or_undef( $values, '_cell_angle_gamma', 0 );
    $data{'siggamma'} = get_num_or_undef( $sigmas, '_cell_angle_gamma', 0 );

    my $cell_volume = get_num_or_undef( $values, '_cell_volume', 0 );

    if( !defined $cell_volume ) {
        my @cell = get_cell( $values, { silent => 1 } );
        $cell_volume = scalar cell_volume( @cell );
        if ( defined $cell_volume ) {
            $cell_volume = sprintf '%7.2f', $cell_volume;
        }
    }

    $data{'vol'} = $cell_volume;
    $data{'sigvol'} = get_num_or_undef( $sigmas, '_cell_volume', 0 );

    $data{'celltemp'} =
        get_num_or_undef( $values, '_cell_measurement_temperature', 0 );
    $data{'sigcelltemp'} =
        get_num_or_undef( $sigmas, '_cell_measurement_temperature', 0 );
    $data{'diffrtemp'} =
        get_num_or_undef( $values, '_diffrn_ambient_temperature', 0 );
    $data{'sigdiffrtemp'} =
        get_num_or_undef( $sigmas, '_diffrn_ambient_temperature', 0 );
    $data{'cellpressure'} =
        get_num_or_undef( $values, '_cell_measurement_pressure', 0 );
    $data{'sigcellpressure'} =
        get_num_or_undef( $sigmas, '_cell_measurement_pressure', 0 );
    $data{'diffrpressure'} =
        get_num_or_undef( $values, '_diffrn_ambient_pressure', 0 );
    $data{'sigdiffrpressure'} =
        get_num_or_undef( $sigmas, '_diffrn_ambient_pressure', 0 );

    $data{'thermalhist'} =
        get_tag_or_undef( $values, '_exptl_crystal_thermal_history', 0 );
    $data{'pressurehist'} =
        get_tag_or_undef( $values, '_exptl_crystal_pressure_history', 0 );
    $data{'compoundsource'} =
        get_tag_or_undef( $values, '_chemical_compound_source', 0 );

    $data{nel} = $nel;
    $data{sg} = get_space_group_info( $values,
        { 'reformat_space_group' => $options->{'reformat_space_group'} } );
    $data{'sgHall'} =
        get_space_group_Hall_symbol( $values );
    $data{'commonname'} =
        get_tag_or_undef( $values, '_chemical_name_common', 0 );
    $data{'chemname'} =
        get_tag_or_undef( $values, '_chemical_name_systematic', 0 );
    $data{'mineral'} =
        get_tag_or_undef( $values, '_chemical_name_mineral', 0 );
    $data{'formula'} = $formula ? '- ' . $formula . ' -' : '?';
    $data{'calcformula'} = $calc_formula ?
          '- ' . $calc_formula . ' -' : undef;
    $data{'cellformula'} = $cell_formula ?
          '- ' . $cell_formula . ' -' : undef;
    $data{'Z'} =
        get_tag_or_undef( $values, '_cell_formula_units_Z', 0 );
    $data{'Zprime'} =
        compute_Zprime( $data{Z}, $data{sg} );

    $data{'acce_code'} =
        get_coeditor_code( $values, { 'journal' => $journal } );

    $data{'authors'} = cif2unicode( $authors );
    $data{'title'}   = cif2unicode( $title );
    $data{'journal'} = get_tag_or_undef( $values, '_journal_name_full', 0 );
    if( defined $data{'journal'} ) {
        $data{'journal'} = cif2unicode( $data{'journal'} );
    }
    $data{'year'} =
        get_tag_or_undef( $values, '_journal_year', 0 );
    $data{'volume'} =
        get_tag_or_undef( $values, '_journal_volume', 0 );
    $data{'issue'} =
        get_tag_or_undef( $values, '_journal_issue', 0 );
    $data{'firstpage'} =
        get_tag_or_undef( $values, '_journal_page_first', 0 );
    $data{'lastpage'} =
        get_tag_or_undef( $values, '_journal_page_last', 0 );
    $data{'doi'} =
        get_tag_or_undef( $values, '_journal_paper_doi', 0 );
    $data{'onhold'} =
        get_tag_or_undef( $values, '_cod_hold_until_date', 0 );

    $data{'method'} = get_experimental_method( $values );

    $data{'radiation'}  =
        get_tag_or_undef( $values, '_diffrn_radiation_probe', 0 );
    $data{'wavelength'} =
        get_num_or_undef( $values, '_diffrn_radiation_wavelength', 0 );
    $data{'radType'}    =
        get_tag_or_undef( $values, '_diffrn_radiation_type', 0 );
    $data{'radSymbol'}  =
        get_tag_or_undef( $values, '_diffrn_radiation_xray_symbol', 0 );

    for my $r_factor_tag (qw(
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
        _refine_ls_goodness_of_fit_obs )) {
        my $data_key = $r_factor_tag;
        $data_key =~ s/^_refine_ls_//;
        $data_key =~ s/_factor//;
        $data_key =~ s/goodness_of_fit/gof/;
        $data_key =~ s/_//g;
        $data_key = 'Robs' if $data_key eq 'Rgt';
        $data_key = 'wRobs' if $data_key eq 'wRgt';
        $data_key = 'gofobs' if $data_key eq 'gofref';
        if( !defined $data{$data_key} ) {
            $data{$data_key} =
                get_num_or_undef( $values, $r_factor_tag, 0 );
        }
    }

    $data{duplicateof} =
        get_tag_or_undef( $values, '_cod_duplicate_entry', 0 );

    if( !defined $data{duplicateof} ) {
        $data{duplicateof} =
            get_tag_or_undef( $values, '_[local]_cod_duplicate_entry', 0 );
    }

    $data{optimal} = get_tag_or_undef( $values,
                                '_cod_related_optimal_struct', 0 );
    if( !defined $data{optimal} ) {
        $data{optimal} =
            get_tag_or_undef( $values,
                              '_[local]_cod_related_optimal_struct', 0 );
    }

    $data{status} = get_tag_or_undef( $values, '_cod_error_flag', 0 );
    if( !defined $data{status} ) {
        $data{status} =
            get_tag_or_undef( $values, '_[local]_cod_error_flag', 0 );
    }

    # Compose COD flags:
    my @flags;

    push @flags, 'has coordinates' if has_coordinates( $dataset );
    push @flags, 'has disorder'    if is_disordered( $dataset );
    push @flags, 'has Fobs'        if has_Fobs( $dataset );

    $data{flags} = join ',', @flags;

    $data{text} = $text;

    # Set undef if the current value is an empty string
    for ( qw( celltemp      sigcelltemp
              diffrtemp     sigdiffrtemp
              cellpressure  sigcellpressure
              diffrpressure sigdiffrpressure
              chemname commonname mineral ) ) {
        if ( exists $data{$_} && defined $data{$_} ) {
            if ( $data{$_} =~ $empty_value_regex ) {
                $data{$_} = undef;
            }
        }
    };

    # Convert CIF notation to Unicode
    for ( qw( chemname commonname mineral radType radSymbol ) ) {
        if ( exists $data{$_} && defined $data{$_} ) {
            $data{$_} = cif2unicode($data{$_});
        }
    };

    # Remove all white spaces
    for ( qw( radType radSymbol ) ) {
        if ( exists $data{$_} && defined $data{$_} ) {
            $data{$_} =~ s/\s+//g;
        }
    };

    foreach my $key ( keys %data ) {
        if ( defined $data{$key} ) {
            $data{$key} = clean_whitespaces( $data{$key} )
        }
    }

    return \%data;
}

sub filter_num
{
    my @nums = map { s/[(].*[)]$//; $_ } @_;
    wantarray ? @nums : $nums[0];
}

sub check_chem_formula
{
    my ( $formula ) = @_;

    my $formula_component = '[a-zA-Z]{1,2}[0-9.]*';

    if( $formula !~ /^\s*(?:$formula_component\s+)*(?:$formula_component)\s*$/ ) {
        warn "WARNING, chemical formula '$formula' could not be parsed -- "
           . 'a chemical formula should consist of space-seprated chemical '
           . 'element names with optional numeric quantities '
           . "(e.g. 'C2 H6 O')\n";
    }

    return;
}

sub unique
{
    my $prev;
    return map {(!defined $prev || $prev ne $_) ? $prev=$_ : ()} @_;
}

sub count_number_of_elements
{
    my $formula = $_[0];
    my @elements = map {s/[^A-Za-z]//g; /^[A-Za-z]+$/ ? $_ : () }
                   split ' ', $formula;

    my @unique = unique( sort {$a cmp $b} @elements );

    return int @unique;
}

sub get_num
{
    my ($values, $tag, $index ) = @_;

    return filter_num( &get_tag );
}

sub get_num_or_undef
{
    my $value = &get_tag_or_undef;

    if( defined $value && $value ne '?' && $value ne '.') {
        return filter_num( $value );
    }

    return;
}

sub get_tag
{
    push @_, 0;
    &get_and_check_tag;
}

sub get_tag_silently
{
    push @_, 1;
    &get_and_check_tag;
}

sub get_tag_or_undef
{
    push @_, 2;
    &get_and_check_tag;
}

sub get_and_check_tag
{
    my ( $values, $tag, $index, $ignore_errors ) = @_;

    if( ref $values eq 'HASH' ) {
        if( exists $values->{$tag} && ref $values->{$tag} eq 'ARRAY' ) {
            if( defined $values->{$tag}[$index] ) {
                my $val = $values->{$tag}[$index];
           #     if( $val =~ /^\\\n/ ) {
           #         $val =~ s/\\\n//g;
           #     }
           #     $val =~ s/\n/ /g;
           #     $val =~ s/\s+/ /g;
           #     $val =~ s/^\s*|\s*$//g;
                return $val;
            } elsif( !$ignore_errors ) {
                warn "WARNING, data item '$tag' does not have value "
                    . "number $index\n";
            }
        } elsif( !$ignore_errors ) {
            warn "WARNING, data item '$tag' is absent\n";
        }
    }
    return $ignore_errors <= 1 ? '' : undef;
}

sub clean_whitespaces
{
    my ( $value ) = @_;

    if( $value =~ /^\\\n/ ) {
        $value =~ s/\\\n//g;
    }
    $value =~ s/\n/ /g;
    $value =~ s/\s+/ /g;
    $value =~ s/^\s*|\s*$//g;

    return $value;
}

sub get_space_group_info
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

    if( exists $values->{_cod_struct_determination_method} ) {
        return $values->{_cod_struct_determination_method}[0];
    }

    my @powder_tags = grep { /^_pd_/ }
                        @COD::CIF::Tags::DictTags::tag_list;

    for my $tag (@powder_tags) {
        if( exists $values->{$tag} ) {
            return 'powder diffraction';
        }
    }

    for my $tag (qw(_exptl_crystals_number _exptl.crystals_number)) {
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
            $acce_code = get_tag_or_undef( $values, $_, 0 );
            last;
        }
    }

    # Ad hoc logic for Acta Crystallograhica journals to determine
    # the coeditor code from the orignal file name
    if ( !defined $acce_code && defined $journal_name &&
         $journal_name =~ /^Acta Cryst/ ) {
        for ( qw( _cod_data_source_file
                  _[local]_cod_data_source_file ) ) {
            if( exists $values->{$_} ) {
                $acce_code = get_tag_or_undef( $values, $_, 0 );
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

sub compute_Zprime
{
    my ( $Z, $space_group_H_M ) = @_;

    return unless defined $space_group_H_M;

    use COD::Spacegroups::Lookup::COD;
    my @sg_description =
        grep { $space_group_H_M eq $_->{'universal_h_m'} }
             @COD::Spacegroups::Lookup::COD::table;

    if( int(@sg_description) == 1 && defined $Z ) {
        my $AU_count = int @{$sg_description[0]{symops}};
        return $Z / $AU_count;
    }

    return;
}

sub validate_SQL_types
{
    my( $data, $types ) = @_;

    for my $key (sort keys %$data) {
        next if !defined $data->{$key};
        next if $data->{$key} eq 'NULL';
        next if !exists $types->{$key};

        if( $types->{$key} =~ /^(float|double|(small|medium)int)/i &&
            !looks_like_number( $data->{$key} ) ) {
            warn "value of '$key' ('$data->{$key}') does not seem " .
                 'to be numeric';
            $data->{$key} = undef;
            next;
        }

        if( $types->{$key} =~ /unsigned/i &&
            $data->{$key} < 0 ) {
            warn "value of '$key' ('$data->{$key}') is negative, " .
                 'while it must be unsigned';
            $data->{$key} = undef;
            next;
        }

        if( $types->{$key} =~ /^(var)?char[(](\d+)[)]/i ) {
            my $max_length = $2;
            my $val_length = length( $data->{$key} );
            if( $val_length > $max_length ) {
                warn "value of '$key' ('$data->{$key}') is longer " .
                     "than allowed ($val_length > $max_length) " .
                     'and may be corrupted upon casting';
            }
        }
    }

    return;
}

1;
