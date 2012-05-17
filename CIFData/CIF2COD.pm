#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Parse a CIF file, prepare a COD database table entry from it.
#**

package CIF2COD;

use strict;
use Spacegroups::SpacegroupNames;
use CIFData::CIFCellContents;
use CIFTags::CIFDictTags;
use CIFData::CIFClassifyer;
use AtomProperties;
use Unicode2CIF;

require Exporter;
@CIFDictTags::ISA = qw(Exporter);
@CIFDictTags::EXPORT_OK = qw( @default_data_fields @new_data_fields );

sub entry_has_coordinates($);
sub entry_has_disorder($);
sub entry_has_Fobs($);

my $bond_safety_margin = 0.2; # Angstroems; a bond safety marging for a CIF classifier.

my $reformat_spacegroup = 0;
my $use_datablocks_without_coord = 0;
my $print_header = 0; # Indicates whether to print out a header with
                      # column names.
my $print_keywords = 0;

my $continue_on_errors = 0;
my $cod_number;

# The default sql table data field that was taken from the 
# cod-add-data.sh script.

@CIF2COD::default_data_fields = qw (
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

my @data_fields = @CIF2COD::default_data_fields;

# New sql table data fields.

@CIF2COD::new_data_fields = qw (
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
);

my %spacegroups = map {
    my $key1 = $_->[1];
    my $key2 = $_->[2];
    $key1 =~ s/\s//g;
    $key2 =~ s/\s//g;
    ($key1, $_->[2], $key2, $_->[2] )
} @SpacegroupNames::names;

sub cif2cod
{
    my( $data, $filename, $options ) = @_;
    
    $options = {} unless defined $options;
    $cod_number = $options->{cod_number}
        if exists $options->{cod_number};
    $continue_on_errors = $options->{continue_on_errors}
        if exists $options->{continue_on_errors};
    $print_header = $options->{print_header}
        if exists $options->{print_header};
    $print_keywords = $options->{print_keywords}
        if exists $options->{print_keywords};
    $reformat_spacegroup = $options->{reformat_spacegroup}
        if exists $options->{reformat_spacegroup};
    $use_datablocks_without_coord =
        $options->{use_datablocks_without_coord}
        if exists $options->{use_datablocks_without_coord};

    my @extracted;
    for my $dataset (@$data) {
        my %data = ();
        my $nel;
        my $values = $dataset->{values};
        my $sigmas = $dataset->{precisions};

        next unless exists $values->{_atom_site_fract_x} ||
            $use_datablocks_without_coord;

        my @authors = ();
        if( exists $values->{_publ_author_name} ) {
            for my $i (0..$#{$values->{_publ_author_name}}) {
                push( @authors, get_tag( $values, "_publ_author_name", $i ));
            }
        }

        my $authors = join( "; ", @authors );

        my $title = get_tag( $values, "_publ_section_title", 0, $filename );
        my $journal = get_tag( $values, "_journal_name_full", 0, $filename );
        my $year = get_tag( $values, "_journal_year", 0, $filename );
        my $volume = get_tag( $values, "_journal_volume", 0, $filename );
        
        my $first_page;
        if( exists $values->{_journal_article_reference} ) {
            $first_page = get_tag_silently( $values, "_journal_page_first", 0 );
        } else {
            $first_page = get_tag( $values, "_journal_page_first", 0, $filename );
        }

        my $last_page = get_tag_silently( $values, "_journal_page_last", 0 );
        my $issue = get_tag_silently( $values, "_journal_issue", 0 );

        my $calculated_formula;

        eval {
            $calculated_formula =
                CIFCellContents::cif_cell_contents( $dataset, $filename, undef );
        };
        if( $@ ) {
            error( "summary formula could not be calculated",
                   $filename, $dataset );
        }

        my $text = join( '\n', map { Unicode2CIF::cif2unicode($_) }
                         ( $authors, $title, $journal, $volume .
                           ( $issue? ( $volume ? "($issue)" : 
                                       "(issue $issue)") : "" ),
                           "(" . $year . ")",
                           ( $last_page ? $first_page . "-" . $last_page :
                             $first_page )) 
                       );

        my $diffr_temperature =
            get_num_or_undef( $values, "_diffrn_ambient_temperature", 0 );

        undef $diffr_temperature if defined $diffr_temperature &&
            $diffr_temperature =~ /^\s*\?\s*$/;

        my $diffr_temperature_sigma =
            get_num_or_undef( $sigmas, "_diffrn_ambient_temperature", 0 );

        my $cell_temperature =
            get_num_or_undef( $values, "_cell_measurement_temperature", 0 );

        undef $cell_temperature if defined $cell_temperature &&
            $cell_temperature =~ /^\s*\?\s*$/;

        my $cell_temperature_sigma =
            get_num_or_undef( $sigmas, "_cell_measurement_temperature", 0 );

        my $diffr_pressure =
            get_num_or_undef( $values, "_diffrn_ambient_pressure", 0 );

        undef $diffr_pressure if defined $diffr_pressure &&
            $diffr_pressure =~ /^\s*\?\s*$/;

        my $diffr_pressure_sigma =
            get_num_or_undef( $sigmas, "_diffrn_ambient_pressure", 0 );

        my $cell_pressure =
            get_num_or_undef( $values, "_cell_measurement_pressure", 0 );

        undef $cell_pressure if defined $cell_pressure &&
            $cell_pressure =~ /^\s*\?\s*$/;

        my $cell_pressure_sigma =
            get_num_or_undef( $sigmas, "_cell_measurement_pressure", 0 );


        my $systematic_name =
            get_tag_or_undef( $values, "_chemical_name_systematic", 0 );

        undef $systematic_name
            if defined $systematic_name && $systematic_name =~ /^\s*\?\s*$/sm;

        my $common_name =
            get_tag_or_undef( $values, "_chemical_name_common", 0 );

        if( !$common_name ) {
            $common_name =
                get_tag_or_undef( $values, "_chemical_name_mineral", 0 );
        }

        undef $common_name
            if defined $common_name && $common_name =~ /^\s*\?\s*$/sm;

        my $formula = get_tag( $values, "_chemical_formula_sum", 0, $filename );

        undef $formula if $formula =~ /^\s*\?\s*$/;

        if( defined $formula  ) {
            check_chem_formula( $formula, $filename );
        }

        $nel = count_number_of_elements( $formula );

        if( defined $cod_number ) {
            $data{file} = $cod_number;
        } else {
            $data{file} = $dataset->{name};
        }
        $data{a} = get_num_or_undef( $values, "_cell_length_a", 0 );
        $data{siga} = get_num_or_undef( $sigmas, "_cell_length_a", 0 );
        $data{b} = get_num_or_undef( $values, "_cell_length_b", 0 );
        $data{sigb} = get_num_or_undef( $sigmas, "_cell_length_b", 0 );
        $data{c} = get_num_or_undef( $values, "_cell_length_c", 0 );
        $data{sigc} = get_num_or_undef( $sigmas, "_cell_length_c", 0 );
        $data{alpha} = get_num_or_undef( $values, "_cell_angle_alpha", 0 );
        $data{sigalpha} = get_num_or_undef( $sigmas, "_cell_angle_alpha", 0 );
        $data{beta} = get_num_or_undef( $values, "_cell_angle_beta", 0 );
        $data{sigbeta} = get_num_or_undef( $sigmas, "_cell_angle_beta", 0 );
        $data{gamma} = get_num_or_undef( $values, "_cell_angle_gamma", 0 );
        $data{siggamma} = get_num_or_undef( $sigmas, "_cell_angle_gamma", 0 );

        my $cell_volume = get_num_or_undef( $values, "_cell_volume", 0 );

        if( !defined $cell_volume ) {
            my @cell = get_cell( $values );
            $cell_volume = sprintf( "%7.2f", cell_volume( @cell ));
        }

        $data{vol} = $cell_volume;
        $data{sigvol} = get_num_or_undef( $sigmas, "_cell_volume", 0 );

        $data{celltemp} = $cell_temperature;
        $data{sigcelltemp} = $cell_temperature_sigma;
        $data{diffrtemp} = $diffr_temperature;
        $data{sigdiffrtemp} = $diffr_temperature_sigma;
        $data{cellpressure} = $cell_pressure;
        $data{sigcellpressure} = $cell_pressure_sigma;
        $data{diffrpressure} = $diffr_pressure;
        $data{sigdiffrpressure} = $diffr_pressure_sigma;

        $data{thermalhist} =
            get_tag_or_undef( $values, "_exptl_crystal_thermal_history", 0 );
        $data{pressurehist} =
            get_tag_or_undef( $values, "_exptl_crystal_pressure_history", 0 );

        $data{nel} = $nel;
        $data{sg} = get_spacegroup_info( $values, $filename );
        $data{sgHall} = get_spacegroup_Hall_symbol( $values, $filename );
        $data{commonname} = $common_name;
        $data{chemname} = $systematic_name;
        $data{formula} = $formula ? "- " . $formula . " -" : "?";
        $data{calcformula} = $calculated_formula ?
              "- " . $calculated_formula . " -" : undef;

        if( exists $values->{_journal_coeditor_code} ) {
            $data{acce_code} = uc( get_tag_or_undef( $values, 
                                   "_journal_coeditor_code", 0 ));
        } elsif( exists $values->{"_journal.coeditor_code"} ) {
            $data{acce_code} = uc( get_tag_or_undef( $values, 
                                   "_journal.coeditor_code", 0 ));
        } elsif( $journal =~ /^Acta Cryst/ &&
                 exists $values->{"_[local]_cod_data_source_file"} ||
                 exists $values->{"_cod_data_source_file"} ) {
            my $acce_code = exists $values->{"_cod_data_source_file"} ?
                $values->{"_cod_data_source_file"}[0] :
                $values->{"_[local]_cod_data_source_file"}[0];
            $acce_code =~ s/\..*$//g;
            if( $acce_code =~ /^[a-zA-Z]{1,2}[0-9]{4,5}$/ ) {
                $data{acce_code} = uc( $acce_code );
            } else {
                $data{acce_code} = undef;
            }
        } else {
            $data{acce_code} = undef;
        }

        $data{authors} = Unicode2CIF::cif2unicode( $authors );
        $data{title} = Unicode2CIF::cif2unicode( $title );
        $data{journal} = get_tag_or_undef( $values, "_journal_name_full", 0 );
        if( defined $data{journal} ) {
            $data{journal} = Unicode2CIF::cif2unicode( $data{journal} );
        }
        $data{year} = get_tag_or_undef( $values, "_journal_year", 0 );
        $data{volume} = get_tag_or_undef( $values, "_journal_volume", 0 );
        $data{issue} = get_tag_or_undef( $values, "_journal_issue", 0 );
        $data{firstpage} = get_tag_or_undef( $values, "_journal_page_first", 0 );
        $data{lastpage} = get_tag_or_undef( $values, "_journal_page_last", 0 );

        $data{method} = get_experimental_method( $values );

        $data{radiation} = get_tag_or_undef( $values, "_diffrn_radiation_probe", 0 );
        $data{wavelength} = get_num_or_undef( $values, "_diffrn_radiation_wavelength", 0 );
        $data{radType} = get_tag_or_undef( $values, "_diffrn_radiation_type", 0 );
        if( defined $data{radType} ) {
            $data{radType} = Unicode2CIF::cif2unicode( $data{radType} );
            $data{radType} =~ s/\s//g;
        }
        $data{radSymbol} = get_tag_or_undef( $values, "_diffrn_radiation_xray_symbol", 0 );
        if( defined $data{radSymbol} ) {
            $data{radSymbol} = Unicode2CIF::cif2unicode( $data{radSymbol} );
            $data{radSymbol} =~ s/\s//g;
        }

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
            $data_key = "Robs" if $data_key eq "Rgt";
            $data_key = "wRobs" if $data_key eq "wRgt";
            $data_key = "gofobs" if $data_key eq "gofref";
            if( !defined $data{$data_key} ) {
                $data{$data_key} =
                    get_num_or_undef( $values, lc($r_factor_tag), 0 );
            }
        }

        $data{duplicateof} =
            get_tag_or_undef( $values, "_cod_duplicate_entry", 0 );

        if( !defined $data{duplicateof} ) {
            $data{duplicateof} =
                get_tag_or_undef( $values, "_[local]_cod_duplicate_entry", 0 );
        }

        $data{optimal} = get_tag_or_undef( $values,
                                    "_cod_related_optimal_struct", 0 );
        if( !defined $data{optimal} ) {
            $data{optimal} =
                get_tag_or_undef( $values,
                                  "_[local]_cod_related_optimal_struct", 0 );
        }

        $data{status} = get_tag_or_undef( $values, "_cod_error_flag", 0 );
        if( !defined $data{status} ) {
            $data{status} =
                get_tag_or_undef( $values, "_[local]_cod_error_flag", 0 );
        }

        # Compose COD flags:
        do {
            my $separator = "";
            my $value = "";
            if( entry_has_coordinates( $values )) {
                $value = "has coordinates";
                $separator = ",";
            }
            if( entry_has_disorder( $values )) {
                $value .= $separator . "has disorder";
                $separator = ",";
            }
            if( entry_has_Fobs( $values )) {
                $value .= $separator . "has Fobs";
                $separator = ",";
            }
            my $bond_flags = CIFClassifyer::cif_class_flags
                ( $dataset, $filename, \%AtomProperties::atoms,
                  $bond_safety_margin );
            $bond_flags =~ s/has_(\w+)_(\w+)_bond/has $1-$2 bond/g;
            if( $bond_flags !~ /^\s*$/ ) {
                $value .= "," . $bond_flags;
            }
            $data{flags} = $value;
        };

        $data{text} = $text;

        push( @extracted, \%data );
    }

    return \@extracted;
}

sub error
{
    my ( $message, $filename, $dataset, $explanation ) = @_;

    print STDERR $0, ": ";
    print STDERR $filename
        if $filename;
    print STDERR " ",  $dataset->{name}
        if $dataset && exists $dataset->{name};
    print STDERR ": "
        if $filename || $dataset;
    print STDERR $message
        if defined $message;
    print STDERR "\n", $explanation
        if defined $explanation;
    print STDERR "\n";

    die unless $continue_on_errors;
}

sub filter_num
{
    my @nums = map { s/\(.*\)$//; $_ } @_;
    wantarray ? @nums : $nums[0];
}

sub check_chem_formula
{
    my ( $formula, $filename ) = @_;

    my $formula_component = "[a-zA-Z]{1,2}[0-9.]*";

    if( $formula !~ /^\s*($formula_component\s+)*($formula_component)\s*$/ ) {
        error( "chemical formula '$formula' could not be parsed",
               $filename, undef,
               # explanation:
               "A chemical formula should consist of space-seprated " .
               "chemical element names\n" .
               "with optional numeric quantities (e.g. 'C2 H6 O')." );
    }
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
                   split( " ", $formula );

    my @unique = unique( sort {$a cmp $b} @elements );

    return int(@unique);
}

sub get_num
{
    my ($values, $tag, $index, $filename) = @_;

    return filter_num( &get_tag );
}

sub get_num_or_undef
{
    my $value = &get_tag_or_undef;

    if( defined $value ) {
        if( $value ne '?' && $value ne '.' ) {
            return filter_num( $value );
        } else {
            return undef;
        }
    } else {
        return undef;
    }
}

sub get_tag
{
    push( @_, 0 );
    &get_and_check_tag;
}

sub get_tag_silently
{
    push( @_, ("",1) );
    &get_and_check_tag;
}

sub get_tag_or_undef
{
    push( @_, ("",2) );
    &get_and_check_tag;
}

sub get_and_check_tag
{
    my ($values, $tag, $index, $filename, $ignore_errors ) = @_;

    if( ref $values eq "HASH" ) {
        if( exists $values->{$tag} && ref $values->{$tag} eq "ARRAY" ) {
            if( defined $values->{$tag}[$index] ) {
                my $val = $values->{$tag}[$index];
                if( $val =~ /^\\\n/ ) {
                    $val =~ s/\\\n//g;
                }
                $val =~ s/\n/ /g;
                $val =~ s/\s+/ /g;
                $val =~ s/^\s*|\s*$//g;
                return $val;
            } else {
                unless( $ignore_errors ) {
                    error( "tag '$tag' does not have value number $index",
                           $filename );
                }
            }
        } else {
            unless( $ignore_errors ) {
                error( "tag '$tag' is absent", $filename );
            }
        }
    }
    return $ignore_errors <= 1 ? "" : undef;
}

sub get_spacegroup_info
{
    my ($values, $filename ) = @_;
    
    my @spacegroup_tags = map {lc} qw (
        _space_group_name_H-M_alt
        _space_group.name_H-M_full
        _symmetry_space_group_name_H-M
        _space_group_ssg_name
        _space_group_ssg_name_IT
        _space_group_ssg_name_WJJ
    );

    my $spacegroup;

    for my $sg_tag (@spacegroup_tags) {
        if( exists $values->{$sg_tag} ) {
            $spacegroup = $values->{$sg_tag}[0];
            if( $sg_tag =~ /_h-m/ && $reformat_spacegroup ) {
                my $orig_sg = $spacegroup;
                $orig_sg =~ s/[\(\)~_\s]//g;
                ## print ">>> $orig_sg\n";
                if( exists $spacegroups{$orig_sg} ) {
                    $spacegroup = $spacegroups{$orig_sg};
                }
            }
            last
        }
    }
    if( !defined $spacegroup ) {
        error( "no spacegroup information found", $filename );
    } else {
        $spacegroup =~ s/^\s*|\s*$//g;
    }
    return $spacegroup;
}

sub get_spacegroup_Hall_symbol
{
    my ($values, $filename ) = @_;
    
    my @spacegroup_tags = map {lc} qw (
        _space_group_name_Hall
        _symmetry_space_group_name_Hall
    );

    my $spacegroup;

    for my $sg_tag (@spacegroup_tags) {
        if( exists $values->{$sg_tag} ) {
            $spacegroup = $values->{$sg_tag}[0];
            last
        }
    }
    if( !defined $spacegroup ) {
        error( "no Hall spacegroup symbol found", $filename );
    } else {
        $spacegroup =~ s/^\s*|\s*$//g;
    }
    return $spacegroup;
}

sub get_cell
{
    my $datablok = $_[0];

    return (
        $datablok->{_cell_length_a}[0],
        $datablok->{_cell_length_b}[0],
        $datablok->{_cell_length_c}[0],
        $datablok->{_cell_angle_alpha}[0],
        $datablok->{_cell_angle_beta}[0],
        $datablok->{_cell_angle_gamma}[0]
    );
}

sub cell_volume
{
    my @cell = map { s/\(.*\)//g; $_ } @_;

    my $Pi = 4 * atan2(1,1);

    my ($a, $b, $c) = @cell[0..2];
    my ($alpha, $beta, $gamma) = map {$Pi * $_ / 180} @cell[3..5];
    my ($ca, $cb, $cg) = map {cos} ($alpha, $beta, $gamma);
    my $sg = sin($gamma);
    
    my $V = $a * $b * $c * sqrt( $sg**2 - $ca**2 - $cb**2 + 2*$ca*$cb*$cg );

    return $V;
}

sub entry_has_coordinates($)
{
    my ($values) = @_;

    my @tags = qw(
        _atom_site_fract_x
        _atom_site.fract_x
        _atom_site_fract_y
        _atom_site.fract_y
        _atom_site_fract_z
        _atom_site.fract_z
        _atom_site_Cartn_x
        _atom_site.Cartn_x
        _atom_site_Cartn_x_nm
        _atom_site_Cartn_x_pm
        _atom_site_Cartn_y
        _atom_site.Cartn_y
        _atom_site_Cartn_y_nm
        _atom_site_Cartn_y_pm
        _atom_site_Cartn_z
        _atom_site.Cartn_z
        _atom_site_Cartn_z_nm
        _atom_site_Cartn_z_pm
    );

    for my $tag ( @tags ) {
        if( exists $values->{$tag} ) {
            for my $value (@{$values->{$tag}}) {
                if( defined $value && $value ne '.' && $value ne '?' ) {
                    return 1;
                }
            }
        }
    }

    return 0;
}

sub entry_has_disorder($)
{
    my ($values) = @_;

    my @tags = qw(
        _atom_site_disorder_assembly
        _atom_site.disorder_assembly
        _atom_site_disorder_group
        _atom_site.disorder_group
    );

    for my $tag ( @tags ) {
        if( exists $values->{$tag} ) {
            for my $value (@{$values->{$tag}}) {
                if( defined $value && $value ne '.' && $value ne '?' ) {
                    return 1;
                }
            }
        }
    }

    return 0;
}

sub entry_has_Fobs($)
{
    my ($values) = @_;

    my @tags = qw(
        _cod_database_fobs_code
    );

    for my $tag ( @tags ) {
        if( exists $values->{$tag} ) {
            for my $value (@{$values->{$tag}}) {
                if( defined $value && $value ne '.' && $value ne '?' ) {
                    return 1;
                }
            }
        }
    }

    return 0;
}

sub get_experimental_method
{
    my ($values) = @_;
    my @powder_tags = grep /^_pd_/, @CIFDictTags::tag_list;

    for my $tag (@powder_tags) {
        if( exists $values->{$tag} ) {
            return "powder diffraction";
        }
    }

    for my $tag (qw(_exptl_crystals_number _exptl.crystals_number)) {
        if( exists $values->{$tag} ) {
            return "single crystal";
        }
    }

    return undef;
}

1;
