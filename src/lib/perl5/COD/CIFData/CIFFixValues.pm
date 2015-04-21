#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Correct temperature values which have units specified or convert
#  between Celsius degrees and Kelvins. Changes 'room/ambiante
#  temperature'  to the appropriate numeric value.
#  Fixes other undefined values (no, not measured, etc.) to '?' simbol.
#  Determine a report about changes made into standart I/O streams.
#
#  Fixes enumeration values in CIF file against CIF dictionaries.
#
#**

package COD::CIFData::CIFFixValues;

use strict;
use warnings;
use COD::CIFTags::CIFTagCanonicalNames;
use COD::CIFTags::CIFDictTags;
use COD::CIFTags::CIFCODTags;
use COD::CIFTags::CIFTagManage;

my $Id = '$Id$';
my $keep_tag_order = 0;

my $fix_misspelled_values = 1;
my $replacement_file;
my $fix_temperature = 1;
my $fix_enums = 1;

my $treat_as_set = 1;

my $use_parser = "perl";

my $dictParsed = [];
my @dictionaries = ();
my %dictTags;
my %tagDicts;
 
%COD::CIFData::CIFFixValues::default_enums = (
    '_atom_site_adp_type'                    => [ "Uani", "Uiso", "Uovl",
                                                  "Umpe", "Bani", "Biso", "Bovl" ],
    '_atom_site_calc_flag'                   => [ "d", "calc", "c", "dum" ],
    '_atom_site_refinement_flags_adp'        => [ ".", "T", "U", "TU" ],
#   '_atom_site_refinement_flags_adp'        => [ ".", "T", "U" ],
    '_atom_site_refinement_flags_occupancy'  => [ ".", "P" ],
    '_atom_site_refinement_flags_posn'       => [ ".", "D", "G", "R", "S",
                                                  "DG", "DR", "DS", "GR",
                                                  "GS", "RS", "DGR", "DGS",
                                                  "DRS", "GRS", "DGRS" ],
#   '_atom_site_refinement_flags_posn'       => [ ".", "D", "G", "R", "S" ],
    '_atom_site_refinement_flags'            => [ ".", "S", "G", "R",
                                                  "D", "T", "U", "P" ],
    '_atom_sites_solution_hydrogens'         => [ "difmap", "vecmap", "heavy",
                                                  "direct", "geom", "disper",
                                                  "isomor", "notdet", "dual", "other" ],
    '_atom_sites_solution_primary'           => [ "difmap", "vecmap", "heavy",
                                                  "direct", "geom", "disper",
                                                  "isomor", "notdet", "dual", "other" ],
    '_atom_sites_solution_secondary'         => [ "difmap", "vecmap", "heavy",
                                                  "direct", "geom", "disper", 
                                                  "isomor", "notdet", "dual", "other" ],
    '_atom_site_thermal_displace_type'       => [ "Uani", "Uiso", "Uovl", "Umpe", 
                                                  "Bani", "Biso", "Bovl" ],
    '_chemical_absolute_configuration'       => [ "rm", "ad", "rmad",
                                                  "syn", "unk", "." ],
    '_chemical_conn_bond_type'               => [ "sing", "doub", "trip", "quad", 
                                                  "arom", "poly", "delo", "pi" ],
    '_chemical_enantioexcess_bulk_technique' => [ "OA", "CD", "EC", "other" ],
    '_chemical_enantioexcess_crystal_technique' => [ "CD", "EC", "other" ],
    '_citation_coordinate_linkage'           => [ "no", "n", "yes", "y" ],
    '_diffrn_radiation_probe'                => [ "x-ray", "neutron",
                                                  "electron", "gamma" ],
    '_diffrn_radiation_wavelength_determination' => [ "fundamental",
                                                      "estimated", "refined" ],
    '_diffrn_radiation_xray_symbol'          => [ "K-L~3~", "K-L~2~",
                                                  "K-M~3~", "K-L~2,3~" ],
    '_diffrn_refln_scan_mode_backgd'         => [ "st", "mo" ],
    '_diffrn_refln_scan_mode'                => [ "om", "ot", "q" ],
    '_diffrn_source_target'                  => [ "H", "He", "Li", "Be", "B",
                                                  "C", "N", "O", "F", "Ne",
                                                  "Na", "Mg", "Al", "Si", "P",
                                                  "S", "Cl", "Ar", "K", "Ca",
                                                  "Sc", "Ti", "V", "Cr", "Mn",
                                                  "Fe", "Co", "Ni", "Cu", "Zn",
                                                  "Ga", "Ge", "As", "Se", "Br",
                                                  "Kr", "Rb", "Sr", "Y", "Zr",
                                                  "Nb", "Mo", "Tc", "Ru", "Rh",
                                                  "Pd", "Ag", "Cd", "In", "Sn",
                                                  "Sb", "Te", "I", "Xe", "Cs",
                                                  "Ba", "La", "Ce", "Pr", "Nd",
                                                  "Pm", "Sm", "Eu", "Gd", "Tb",
                                                  "Dy", "Ho", "Er", "Tm", "Yb",
                                                  "Lu", "Hf", "Ta", "W", "Re",
                                                  "Os", "Ir", "Pt", "Au", "Hg",
                                                  "Tl", "Pb", "Bi", "Po", "At",
                                                  "Rn", "Fr", "Ra", "Ac", "Th",
                                                  "Pa", "U", "Np", "Pu", "Am", 
                                                  "Cm", "Bk", "Cf", "Es", "Fm",
                                                  "Md", "No", "Lr" ],
    '_exptl_absorpt_correction_type'         => [ "analytical", "cylinder",
                                                  "empirical", "gaussian",
                                                  "integration", "multi-scan",
                                                  "none", "numerical",
                                                  "psi-scan", "refdelf", "sphere" ],
    '_exptl_crystal_colour_lustre'           => [ "metallic", "dull", "clear" ],
    '_exptl_crystal_colour_modifier'         => [ "light", "dark", "whitish",
                                                  "blackish", "grayish", "brownish",
                                                  "reddish", "pinkish", "orangish",
                                                  "yellowish", "greenish", "bluish" ],
    '_exptl_crystal_colour_primary'          => [ "colourless", "white", "black", 
                                                  "gray", "brown", "red", "pink",
                                                  "orange", "yellow", "green",
                                                  "blue", "violet" ],
    '_geom_angle_publ_flag'                  => [ "no", "n", "yes", "y" ],
    '_geom_bond_publ_flag'                   => [ "no", "n", "yes", "y" ],
    '_geom_contact_publ_flag'                => [ "no", "n", "yes", "y" ],  
    '_geom_hbond_publ_flag'                  => [ "no", "n", "yes", "y" ],
    '_geom_torsion_publ_flag'                => [ "no", "n", "yes", "y" ],
    '_publ_body_element'                     => [ "section", "subsection",
                                                  "subsubsection", "appendix",
                                                  "footnote" ],
    '_publ_body_format'                      => [ "ascii", "cif", "latex", "rtf", 
                                                  "sgml", "tex", "troff" ],
    '_publ_manuscript_incl_extra_defn'       => [ "no", "n", "yes", "y" ],
    '_publ_requested_category'               => [ "FA", "FI", "FO", "FM", "CI",
                                                  "CO", "CM", "EI", "EO", "EM",
                                                  "QI", "QO", "QM", "AD", "SC" ],
    '_refine_ls_hydrogen_treatment'          => [ "refall", "refxyz", "refU", "noref",
                                                  "constr", "mixed", "undef" ],
    '_refine_ls_matrix_type'                 => [ "full", "fullcycle", "atomblock",
                                                  "userblock", "diagonal", "sparse" ],
    '_refine_ls_structure_factor_coef'       => [ "F", "Fsqd", "Inet" ],
    '_refine_ls_weighting_scheme'            => [ "sigma", "unit", "calc" ],
    '_refln_include_status'                  => [ "o", "<", "-", "x", "h", "l" ],
    '_refln_observed_status'                 => [ "o", "<", "-", "x", "h", "l" ],
    '_refln_refinement_status'               => [ "incl", "excl", "extn" ],
    '_space_group_crystal_system'            => [ "triclinic", "monoclinic",
                                                  "orthorhombic", "tetragonal",
                                                  "trigonal", "hexagonal", "cubic" ],
    '_symmetry_cell_setting'                 => [ "triclinic", "monoclinic",
                                                  "orthorhombic", "tetragonal",
                                                  "rhombohedral", "trigonal", 
                                                  "hexagonal", "cubic" ],
    );
my $default_enums = \%default_enums;

@COD::CIFData::CIFFixValues::default_set_tags = qw(
    _atom_site_refinement_flags
    _atom_site_refinement_flags_adp
    _atom_site_refinement_flags_posn
);

#
# Subroutines:
#

sub insert_report_to_comments {
    my( $dataset, $insert_reports ) = @_;
    if( @$insert_reports > 0 ) {
        my $comments_tag = '_cod_depositor_comments';
        my $values = $dataset->{values};
        my $reports_value = join( "\n\n",@$insert_reports );
        my $title =
            "The following automatic conversions were performed:\n\n" .
            join( "\n", map { "" . $_ }
                  fold( 70, " +", " ", $reports_value ));
        
        if( exists $values->{$comments_tag} ) {
            $values->{$comments_tag}[0] .= "\n\n" . $title;
        } else {
            $values->{$comments_tag}[0] = "\n" . $title;
        }
        my $signature = $Id;
        $signature =~ s/^\$|\$$//g;
        $values->{$comments_tag}[0] .=
            "\n\n" . "Automatic conversion script" .
            "\n" . $signature;
    }
}

# Counts sigma value for the &pack_presicion subroutine

sub get_sigma($$) {
    my( $value , $sig ) = @_;
    $value =~ m/([^.]*)\.?(\d*)/;
    if( $2 ) {
        return $sig*10**(length($2)*(-1) )
    } else {
        return $sig;
    }
}

sub replacement_candidates($$) {
    my( $cif_value, $dict_value_list ) = @_;
    my @candidate_list = ();
    foreach my $dict_tag_value( @{$dict_value_list} ) {
        if( $cif_value eq $dict_tag_value ) {
            return ();
        }
        my $test_dict_value = $dict_tag_value;
        $test_dict_value =~ s/[-_\s]//g;
        my $test_cif_value = $cif_value;
        $test_cif_value =~ s/[-_\s]//g;
        
        if( lc $test_cif_value eq lc $test_dict_value ) {
            push( @candidate_list, $dict_tag_value );
            next;
        }
        if( lc $cif_value eq lc $dict_tag_value ) {
            push( @candidate_list, $dict_tag_value );
            next;
        }
    }
    if( scalar( @candidate_list ) == 1 ) {
        return @candidate_list;
    } else {
        return @{$dict_value_list};
    }
}

sub make_count($$) {
    my %notes_warnings = %{ $_[0] };
    my @messages = @{ $_[1] };
    my @reports;
    foreach my $message( @messages ) {
	if(! exists $notes_warnings{$message} ) {
	    die( "$0: Error while counting " .
                 "'$message' audit message.\n"  );
    }
	if( exists $notes_warnings{$message} ) {
            my $count = $notes_warnings{$message};
            my $times =
                ( $count =~ /^(\d*[02-9])?1$/ ) ? "time" : "times";
            if( $notes_warnings{$message} == 1 ) {
                $message .= ".";
            } else {
                $message .= " ($count $times).";
            }
            push( @reports, $message );
	}
    }
    return @reports;
}

# to print out all tags and theirs enum values from the given dictionary
#foreach( keys %dictTags ) {
#    print "'$_' => [ ";
#    foreach( @{ $dictTags{$_} } ){
#        print '"' . $_ . '"' .', ';
#    }
#    print "\n";
#}
#exit 0;

sub fix_misspelled_values($$$) {
    my( $dataset, $filename, $value_spelling ) = @_;
    my %reports = ();
    my @reports = ();
    my $dataname = 'data_' . $dataset->{name};
    my $tags = $dataset->{tags};
    my $values = $dataset->{values};
    foreach my $tag( @$tags ) {
        if(! exists $value_spelling{$tag} ) {
            next;
        }
        foreach my $tag_value( @{ $values->{$tag} } ) {
            if( $tag_value =~ /^\.|\?$/ ){
                next;
            }
            my $lc_tag_value = lc $tag_value;
            if(! exists ${ $value_spelling{$tag}}{$lc_tag_value} ){
                next;
            }
            my $old_value = $tag_value;
            my $correct = ${ $value_spelling{$tag}}{$lc_tag_value};
            $tag_value = $correct;
            my $report_key =
                "'$tag' tag value '$old_value' " .
                "was replaced with '$correct' value";
            if(! exists $reports{$report_key} ) {
                $reports{$report_key} = 0;
            }
            $reports{$report_key} ++;
        }
    }
    foreach my $message( keys %reports  ) {
        my $count = $reports{$message};
        my $times =
            ( $count =~ /^(\d*[02-9])?1$/ ) ? "time" : "times";
	if( $reports{$message} == 1 ) {
            $message .= ".";
        } else {
            $message .= " $count $times.";
        }
        push (@reports, $message);
        print STDERR "$0: $filename: $dataname: NOTE, $message\n";
    }
    return @reports;
}

sub fix_temperature($$) {
    my( $dataset, $filename ) = @_;
    my $dataname = 'data_' . $dataset->{name};
    my @insert_reports = ();
    my $values = $dataset->{values};
    my @temp_tags =
        (   '_cell_measurement_temperature',
            '_chemical_temperature_decomposition',
            '_chemical_temperature_sublimation',
            '_diffrn_ambient_temperature',
            '_exptl_crystal_density_meas_temp',
            '_chemical_melting_point' );
    my $number_pos =
        '(?:\+?' .
        '(?:\d+(?:\.\d*)?|\.\d+)' .
        '(?:[eE][-+]?\d+)?)';
    my $number_neg =
        '(?:\-' .
        '(?:\d+(?:\.\d*)?|\.\d+)' .
        '(?:[eE][-+]?\d+)?)';
    my $temp_K  =
        '(?:(?i:K(?i:elvin?)?)|(?i:K))';
    my $temp_C  =
        '(?:(?i:deg\.?(?:rees?)?)?\s*(?i:C(?i:el[sc]ius)?)|' .
        '(?i:Deg\.?(?:rees?)?\s*[Cc]?)|' .
        '(?:(?:(?i:[\\\/]+o)|(?i:O)|(?:[\\\/]*\%))' .
        '(?:[-_\s]*)(?i:C\.?)?)|' .
        '(?i:(?i:degrees?)?(?:[-_\s]*)centigrades?))';
    my $temp_RT =
        '(?:(?:(?i:temp\\\\\'erature)\s*ambi[ae]nte?)|' .
        '(?:(?:(?i:room)|(?i:amb(?i:i[ae]nte?)))' .
        '\s*(?i:tem[pt](?:erature)?)?)|(?i:rt))';
    my $temp_undef =
        '(?:(?i:ye?s?)|(?i:no?(?i:ne)?)|(?i:unknown)|' .
        '(?i:not?\s*(?:(?i:meas*ure?d?)|(?i:important)|' .
        '(?i:determine?d?)|(?i:avai?lable?)|(?i:relevant)|' .
        '(?i:recorde?d?)))|(?i:N\/?(?i:[DA]))|\s*|[-])';
    my $sigma = '(?:\d+\.\d+|\d+\.|\.\d+|\d+)';
    my $temp_dec =
        '(?i: d\.?(?i:ec\.?)?' .
        '(?i:omp\.?)?(?i:os(?i:e[ds]?|ition))?\s*(?i:at)?)';

    for my $tag( @temp_tags ) {
        if( exists $values->{$tag} ) {
            for my $i( 0..$#{$values->{$tag}} ) {
                my $temperature = $values->{$tag}[$i];
                my $temperature_modif = $temperature;
		$temperature_modif =~ s/^\s+|^\n+|\n+$|\s+$//g;
		
                if( $temperature_modif =~ /^\.|\?$/ ) {
                    next;
                }
                if( $temperature_modif =~
                    /^($number_pos|$number_pos\(\d+\))$/ ) {
                    next;
                }
                if( $temperature_modif =~
                    /^ \(?($temp_dec)?\)?(?:[-_,\s]*)
                            ($number_pos)\(?($sigma)?\)?
                            (?:[-_\s]*)$temp_K?(?:[-_,\s]*)
                            \(?($temp_dec)?\)?$
                            /x )  {
                    if( $1 || $4 ) {
                        my $old_tag = $tag;
                        my $new_tag =
                            '_chemical_temperature_decomposition';
                        $values->{$tag}[$i] =
                            pack_precision( $2 , $3 );
                        my $new_val = $values->{$tag}[$i];
                        rename_tag
                            ( $dataset, $old_tag, $new_tag );
                        my $report_msg =
                            "'$old_tag' tag was changed to '$new_tag' " .
                            "since the value had been '$temperature'. " .
                            "The value '$temperature' was changed to " .
                            "'$new_val'.";
                        push( @insert_reports, $report_msg );
                        print STDERR
                            "$0: $filename: $dataname: NOTE, $report_msg\n";
                        next;
                    }
                }
                if( $temperature_modif =~
                    /^
                        (\>|\<)[_\s]*($number_pos|$number_neg)
                        \(?($sigma)?\)?
                        (?:[-_\'\s]*)(?:$temp_C)(?:[-_,\s]*)
                        \(?($temp_dec)?\)?$
                        /x ) {
                    my $sign = $1;
                    my $number = $2;
                    my $sig  = $3;
                    my $old_tag = $tag;
                    if( $4 ) {
                        $old_tag = '_chemical_temperature_decomposition';
                    }
                    if( $old_tag !~
                        /_cell_measurement_temperature/ ) {
                        if( $sig ) {
                            $sig = get_sigma( $number , $sig );
                        }
                        if( $sign =~ /\>/ ) {
                            $values->{$tag}[$i] =
                                pack_precision
                                ( $number + 273.15 , $sig );
                            my $new_val = $values->{$tag}[$i];
                            
                            my $new_tag = $old_tag . "_gt";
                            rename_tag
                                ( $dataset, $tag, $new_tag );
                            my $report_msg =
                                "'$tag' tag was changed to " .
                                "'$new_tag' since the value was " .
                                "specified 'more than' ('>') a " .
                                "certain temperature. The value " .
                                "'$temperature' was changed to " .
                                "'$new_val' - it was converted from " .
                                "degrees Celsius(C) to Kelvins(K).";
                            push( @insert_reports, $report_msg );
                            print STDERR
                                "$0: $filename: $dataname: NOTE, $report_msg\n";
                            next;
                        }
                        if( $sign =~ /\</ ) {
                            $values->{$tag}[$i] =
                                pack_precision
                                ( $number + 273.15 , $sig );
                            my $new_val = $values->{$tag}[$i];
                            my $new_tag = $old_tag . "_lt";
                            rename_tag
                                ( $dataset, $tag, $new_tag );
                            my $report_msg =
                                "'$tag' tag was changed to " .
                                "'$new_tag' since the value was " .
                                "specified 'less than' ('<') a " .
                                "certain temperature. The value " .
                                "'$temperature' was changed to " .
                                "'$new_val' - it was converted from " .
                                "degrees Celsius(C) to Kelvins(K).";
                            push ( @insert_reports, $report_msg );
                            print STDERR
                                "$0: $filename: $dataname: NOTE, $report_msg\n";
                            next;
                        }
                    }
                    next;
                }
                if( $temperature_modif =~
                    /^
                            (\>|\<)(?:[-_\s]*)($number_pos)
                            \(?($sigma)?\)?(?:[-_\s]*)
                            (?:$temp_K)?(?:[-_,\s]*)
                            \(?($temp_dec)?\)?$
                            /x ) {
                    my $sign = $1;
                    my $number = $2;
                    my $sig  = $3;
                    my $old_tag = $tag;
                    if( $4 ) {
                        $old_tag = '_chemical_temperature_decomposition';
                    }
                    if( $old_tag !~
                        /_cell_measurement_temperature/ ) {
                        if( $sign =~ /\>/ ) {
                            $values->{$tag}[$i] =
                                pack_precision
                                ( $number , $sig );
                            my $new_val = $values->{$tag}[$i];
                            my $new_tag = $old_tag . "_gt";
                            rename_tag
                                ( $dataset, $tag, $new_tag );
                            my $report_msg =
                                "'$tag' tag was changed to " .
                                "'$new_tag' since the value was " .
                                "specified 'more than' ('>') a " .
                                "certain temperature. The value " .
                                "'$temperature' was changed to " .
                                "'$new_val' - it should be numeric " .
                                "and without a unit designator.";
                            push( @insert_reports, $report_msg );
                            print STDERR
                                "$0: $filename: $dataname: NOTE, $report_msg\n";
                            next;
                        }
                        if( $sign =~ /\</ ) {
                            $values->{$tag}[$i] =
                                pack_precision
                                ( $number , $sig );
                            my $new_val = $values->{$tag}[$i];
                            my $new_tag = $old_tag . "_lt";
                            rename_tag
                                ( $dataset, $tag, $new_tag );
                            my $report_msg =
                                "'$tag' tag was changed to " .
                                "'$new_tag' since the value was " .
                                "specified 'less than' ('<') a " .
                                "certain temperature. The value " .
                                "'$temperature' was changed to " .
                                "'$new_val' - it should be numeric " .
                                "and without a unit designator.";
                            push( @insert_reports, $report_msg );
                            print STDERR
                                "$0: $filename: $dataname: NOTE, $report_msg\n";
                            next;
                        }
                    }
                    next;
                }
                if( $temperature_modif =~
                    /^
                        ($number_pos)\s*(?:\()?
                        [\s]*(?:\+|\+\/?\-)?
                        [\s]*($sigma)(?:\))?$
                        /x ) {
                    my $check_value = $temperature_modif;
                    $values->{$tag}[$i] =
                        pack_precision( $1, $2 );
                    my $new_val = $values->{$tag}[$i];
                    $check_value =~ s/\s+//g;
                    if( $check_value eq  $new_val ) {
                        my $report_msg =
                            "'$tag' value '$temperature' was changed to " .
                            "'$new_val' - the value was reformatted.";
                        push( @insert_reports, $report_msg );
                        print STDERR
                            "$0: $filename: $dataname: NOTE, $report_msg\n";
                        next;
                    } else {
                        my $report_msg =
                            "'$tag' value '$temperature' was changed to " .
                            "'$new_val' - precision was estimated.";
                        push( @insert_reports, $report_msg );
                        print STDERR
                            "$0: $filename: $dataname: NOTE, $report_msg\n";
                        next;
                    }
                }
                if( $temperature_modif =~
                    /^
                        ($number_pos)(?:\()?($sigma)?
                        (?:\))?(?:[-_\s]*)\(?$temp_K\)?$
                        /x ) {
                    $values->{$tag}[$i] =
                        pack_precision( $1, $2 );
                    my $new_val = $values->{$tag}[$i];
                    my $report_msg =
                        "'$tag' value '$temperature' was changed to " .
                        "'$new_val' - the value should be numeric " .
                        "and without a unit designator.";
                    push( @insert_reports, $report_msg );
                    print STDERR
                        "$0: $filename: $dataname: NOTE, $report_msg\n";
                    next;
                }
                if( $temperature_modif =~
                    /^
                            ($number_neg)(?:\()?($sigma)?
                            (?:\))?(?:[-_\s]*)$temp_C?$
                            /x ) {
                    my $number = $1;
                    my $sig = $2;
                    if( $sig ) {
                        $sig = get_sigma( $number , $sig );
                    } 
                    $values->{$tag}[$i] =
                        pack_precision( $1 + 273.15, $sig );
                    my $new_val = $values->{$tag}[$i];
                    my $report_msg =
                        "'$tag' value '$temperature' was changed to " .
                        "'$new_val' - it was converted from degrees " .
                        "Celsius(C) to Kelvins(K).";
                    push( @insert_reports, $report_msg );
                    print STDERR
                        "$0: $filename: $dataname: NOTE, $report_msg\n";
                    next;
                }
                if( $temperature_modif =~
                    /^
                        ($temp_RT)(?:[-_\s]*)$
                        /x ) {
                    $values->{$tag}[$i] = "295(2)";
                    my $report_msg =
                        "'$tag' value '$temperature' was changed to " .
                        "'295(2)' - the room/ambient temperature " .
                        "average [293;298] in Kelvins(K) was taken.";
                    push( @insert_reports, $report_msg );
                    print STDERR
                        "$0: $filename: $dataname: NOTE, $report_msg\n";
                    next;
                }
                if( $temperature_modif =~
                    /^
                        ($temp_undef)(?:[-_\s]*)$
                        /x ) {
                    $values->{$tag}[$i] = "?";
                    my $report_msg =
                        "'$tag' value '$temperature' ".
                        "was changed to '?' - the " .
                        "value is undefined or not given.";
                    push( @insert_reports, $report_msg );
                    print STDERR
                        "$0: $filename: $dataname: NOTE, $report_msg\n";
                    next;
                }
                if( $temperature_modif =~
                    /^
                        ($number_pos)\s*[\-\/\:]+\s*($number_pos)
                        (?:[-_\s]*)\(?(?:$temp_C)\)?$
                        /x )   {
                    my $number = ($1 + $2)/2;
                    my $sig = ($2 - $1 )/2;
                    if( $2 > $1 )   {
                        $values->{$tag}[$i] =
                            pack_precision
                            ( $number+273.15 , $sig );
                        my $new_val = $values->{$tag}[$i];
                        my $report_msg =
                            "'$tag' value '$temperature' was changed to " .
                            "'$new_val' - it was converted from degrees " .
                            "Celsius(C) to Kelvins(K), the " .
                            "average value was taken and " .
			    "precision was estimated.";
                        push( @insert_reports, $report_msg );
                        print STDERR
                            "$0: $filename: $dataname: NOTE, $report_msg\n";
                        next;
                    }
                }
                if( $temperature_modif =~
                    /^ ($number_pos)\s*[\-\/\:]+\s*($number_pos)
                        (?:[-_\s]*)\(?(?:$temp_K)?\)?
                        (?:[-_,\s]*)\(?($temp_dec)?\)?$
                        /x ) {
                    my $temp_d = $3;
                    my $number = ($1 + $2)/2;
                    my $sig = ($2 - $1)/2;
                    if( $2 > $1 ) {
                        if( $temp_d ) {
                            my $old_tag = $tag;
                            my $new_tag =
                                '_chemical_temperature_decomposition';
                            $values->{$tag}[$i] =
                                pack_precision
                                ( $number , $sig );
                            my $new_val = $values->{$tag}[$i];
                            rename_tag
                                ( $dataset, $old_tag, $new_tag );
                            my $report_msg =
                                "'$old_tag' tag was changed to '$new_tag' " .
                                "since the value had been given as " .
                                "'$temperature'. " .
                                "The value was changed to " .
                                "'$new_val' - the average value was " .
                                "taken and precision was estimated.";
                            push( @insert_reports, $report_msg );
                            print STDERR
                                "$0: $filename: $dataname: NOTE, $report_msg\n";
                            next;
                        } else {
                            $values->{$tag}[$i] =
                                pack_precision
                                ( $number , $sig );
                            my $new_val = $values->{$tag}[$i];
                            my $report_msg =
                                "'$tag' value '$temperature' was changed to " .
                                "'$new_val' - the average value was taken " .
                                "and precision was estimated.";
                            push( @insert_reports, $report_msg );
                            print STDERR
                                "$0: $filename: $dataname: NOTE, $report_msg\n";
                            next;
                        }
                    }
                }
                if( $temperature_modif =~
                    /^ ($temp_dec)?(?:[-_,\s]*)
                            \(?($number_pos)\(?($sigma)?\)?
                            (?:[-_\s]*)(?:$temp_C|(?:\+\s*273(?:[\.\,]\d+)?\)?))
                            (?:[-_,\s]*)\(?($temp_dec)?\)?$
                            /x )  {
                    my $number = $2;
                    my $sig = $3;
                    if( $sig ) {
                        $sig = get_sigma( $number , $sig );
                    }
                    if( defined $1 || defined $4 ) {
                        my $old_tag = $tag;
                        my $new_tag =
                            '_chemical_temperature_decomposition';
                        $values->{$tag}[$i] =
                            pack_precision
                            ( $number + 273.15, $sig );
                        my $new_val = $values->{$tag}[$i];
                        rename_tag
                            ( $dataset, $old_tag, $new_tag );
                        my $report_msg =
                            "'$old_tag' tag was changed to '$new_tag' " .
                            "since the value had been given as " .
			    "'$temperature'. " .
                            "The value '$temperature' was changed to " .
                            "'$new_val' - " .
                            "it was converted from degrees Celsius(C) " .
                            "to Kelvins(K).";
                        push( @insert_reports, $report_msg );
                        print STDERR
                            "$0: $filename: $dataname: NOTE, $report_msg\n";
                        next;
                    } else {
                        $values->{$tag}[$i] =
                            pack_precision
                            ( $number + 273.15, $sig );
                        my $new_val = $values->{$tag}[$i];
                        my $report_msg =
                            "'$tag' value '$temperature' was changed to " .
                            "'$new_val' - it was converted from degrees " .
                            "Celsius(C) to Kelvins(K).";
                        push( @insert_reports, $report_msg );
                        print STDERR
                            "$0: $filename: $dataname: NOTE, $report_msg\n";
                        next;
                    }
                }
                if( $temperature_modif !~
                    /^
                        ($number_pos)(\($sigma\))?$
                        /x ) {
                    if( length($temperature) > 40 ) {
                            $temperature = substr $temperature, 0, 40;
                            $temperature .= "...";
                        }
                    print STDERR
                        "$0: $filename: $dataname: WARNING, " .
                        "'$tag' value is '$temperature', " .
                        "but it should be numeric, " .
                        "i.e. 'FLOAT or 'INT', permitted " .
                        "range is [0.0;+inf], the value " .
			"should be in Kelvins(K) ".
                        "without a unit designator.\n";
                    next;
                }
            }
        }
    }
    return @insert_reports
}

sub fix_enums($$) {
    my( $dataset, $filename ) = @_;
    my $dataname = 'data_' . $dataset->{name};
    my %reports;
    my @uniq_messages;
    my @insert_reports = ();
    my $values = $dataset->{values};
    my $tags = $dataset->{tags};
    foreach my $tag( @$tags ) {
        #if( $tag =~ /_atom_site_refinement_flags/) {
        #    next;
        #}
        if( defined $values->{$tag} ) {
            foreach my $tag_value( @{$values->{$tag}} ) {
                if( $tag_value =~ /^\.|\?$/ ) {
                    next;
                }
                if( exists $dictTags{$tag} ) {
                    my $message_key;
                    my @replacement_list =
                        replacement_candidates( $tag_value,
                                                $dictTags{$tag} );
                    if(! @replacement_list ) {
                        next;
                    } elsif( scalar( @replacement_list ) == 1 ) {
                        my $new_value = shift( @replacement_list );
                        my $old_value = $tag_value;
                        $tag_value = $new_value;
                        $message_key =
                            "NOTE, '$tag' value '$old_value' " .
                            "changed to '$new_value' " .
                            "according to $tagDicts{$tag}[0] " .
                            "dictionary" .
                            (defined $tagDicts{$tag}[1] ? 
                             " named '$tagDicts{$tag}[1]'" : "") .
                             (defined $tagDicts{$tag}[2] ? 
                              " version $tagDicts{$tag}[2]" : "") .
                              (defined $tagDicts{$tag}[3] ?
                               " from $tagDicts{$tag}[3]" : "");
                    } else {
                        my $dict_values =
                            join( ", ", @replacement_list );
                        my $val = $tag_value;
                        $val =~ s/^\n|\n$//g; 
                        if( length($val) > 30 ) {
                            $val = substr $val, 0, 30;
                            $val .= "...";
                        } 
                        $message_key =
                            "WARNING, '$tag' value '$val' " .
                            "should be one of these: [" .
                            "$dict_values] " .
                            "according to $tagDicts{$tag}[0] " .
                            "dictionary" .
                            (defined $tagDicts{$tag}[1] ?
                             " named '$tagDicts{$tag}[1]'" : "") .
                             (defined $tagDicts{$tag}[2] ?
                              " version $tagDicts{$tag}[2]" : "") .
                              (defined $tagDicts{$tag}[3] ?
                               " from $tagDicts{$tag}[3]" : "");
                    }
                    if(! exists $reports{$message_key} ) {
                        $reports{$message_key} = 0;
                        push( @uniq_messages, $message_key );
                    }
                    $reports{$message_key} ++;
                }
            }
        }
    }
    my @report_messages =
        make_count( \%reports , \@uniq_messages );
    foreach my $report( @report_messages ) {
        print STDERR "$0: $filename: $dataname: $report\n";
        if( $report =~ /^(NOTE,\s+)(.+)$/ ) {
            my $comment_message = $2;
            push( @insert_reports, $comment_message );
        }
    }
    return @insert_reports;
}

#sub treat_as_set($$) {
#    my( $dataset, $filename ) = @_;
#    my $dataname = 'data_' . $dataset->{name};
#    my %reports;
#    my @uniq_messages;
#    my @insert_reports = ();
#    my $values = $dataset->{values};
#    my $tags = $dataset->{tags};
#    foreach my $tag( @$tags ) {
#        foreach my $set_tag( @default_set_tags ) {
#            if( $tag = $set_tag ) {
#                if( defined $values->{$tag} ) {
#                    foreach my $tag_value( @{$values->{$tag}} ) {
#                        if( $tag_value =~ /^\.|\?$/ ) {
#                            next;
#                        }
#                    }
#                }
#            }
#        }
#    }
#}

my @dictionary_tags = ( @COD::CIFTags::CIFDictTags::tag_list,
                        @COD::CIFTags::CIFCODTags::tag_list );
my %dictionary_tags = map { $_, $_ } @dictionary_tags;

@ARGV = ("-") unless @ARGV;

for my $filename (@ARGV) {
    my( $data, $error_count );
    if( $use_parser eq "perl" ) {
        my $parser = new COD::CIFParser::CIFParser;
        $data = $parser->Run( $filename );
        if( defined $parser->YYData->{ERRCOUNT} &&
            $parser->YYData->{ERRCOUNT} > 0 ) {
            $error_count = $parser->YYData->{ERRCOUNT};
        }
    } else {
        ( $data, $error_count ) = COD::CCIFParser::CCIFParser::parse( $filename );
    }

    if( defined $error_count && $error_count > 0 ) {
        print STDERR "$0: $filename: ",
        $error_count,
        " error(s) encountered while parsing CIF data\n";
        ## exit -1;
        next;
    }

    canonicalize_all_names( $data );

    for my $dataset( @$data ) {
        my @insert_reports = ();
        if( $fix_temperature ) {
            my @temperature_reports =
                fix_temperature( $dataset, $filename );
            push( @insert_reports, @temperature_reports );
        }
        if( $fix_misspelled_values ) {
            my @misspell_reports =
                fix_misspelled_values
                    ( $dataset, $filename, \%value_spelling );
            push( @insert_reports, @misspell_reports );
        }
        if( $fix_enums ) {
            my @enums_reports = 
                fix_enums( $dataset, $filename );
            push( @insert_reports, @enums_reports );
        }
#        if( $treat_as_set ) {
#            my @set_reports =
#                treat_as_set( $dataset, $filename );
#            push( @insert_reports, @set_reports );
#        }
        insert_report_to_comments( $dataset , \@insert_reports );
        print_cif( $dataset, {
            exclude_misspelled_tags => 0,
            preserve_loop_order => 1,
            fold_long_fields => 0,
            dictionary_tags => \%dictionary_tags,
            dictionary_tag_list => \@dictionary_tags,
            keep_tag_order => $keep_tag_order,
        });
    }
}
