#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Perform various checks of the CIF data.
#**

package COD::CIF::Data::Check;

use strict;
use warnings;
use Digest::MD5 qw( md5_hex );
use Digest::SHA qw( sha1_hex );
use COD::AuthorNames qw( parse_author_name );
use COD::Escape qw( decode_textfield );
use COD::CIF::Data qw( get_content_encodings );
use COD::CIF::Data::CODFlags qw( has_hkl );
use COD::CIF::Data::EstimateZ qw( cif_estimate_z );
use COD::CIF::Unicode2CIF qw( cif2unicode );
use COD::CIF::Tags::Manage qw(
    tag_is_empty
    tag_is_unknown
);
use COD::DateTime qw( parse_datetime );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
check_author_names
check_bibliography
check_chemical_formula_sum
check_disorder
check_embedded_file_integrity
check_formula_sum_syntax
check_limits
check_mandatory_presence
check_pdcif_relations
check_simultaneous_presence
check_su_eligibility
check_temperature_factors
check_timestamp
check_z
);

my $CIF_NUMERIC_REGEX =
    '([+-]?' .
    '(?:\d+(?:\.\d*)?|\.\d+)' .
    '(?:[eE][+-]?\d+)?)' .
    '(\(\d+\))?';

##
# Checks if the publication authors names provided in the data block
# comply with the name syntax requirement.
#
# @param $dataset
#       Reference to a data block as returned by the COD::CIF::Parser.
# @return
#       Reference to an array of audit messages.
##
sub check_author_names
{
    my ($dataset) = @_;
    my @messages;

    my $values = $dataset->{'values'};

    if( !defined $values->{'_publ_author_name'} ) {
        return \@messages;
    }

    for my $author (@{$values->{'_publ_author_name'}}) {
        eval {
            local $SIG{__WARN__} = sub {
                my $warning = $_[0];
                $warning =~ s/\n$//;
                push @messages, $warning;
            };
            my $parsed_name = parse_author_name( cif2unicode( $author ), 1 );
        }
    }

    return \@messages;
}

##
# Checks if the given data block contains sufficient bibliographical
# information.
#
# @param $dataset
#       Reference to a data block as returned by the COD::CIF::Parser.
# @param $options
#       Reference to a hash of options. The following options are recognised:
#       {
#       # Treat the presence of doi as sufficient bibliographical information
#       # and return immediately if this piece of information is found
#           'require_only_doi' => 0
#       }
# @return
#       Reference to an array of audit messages.
##
sub check_bibliography
{
    my ($dataset, $options) = @_;

    my $require_only_doi = defined $options->{'require_only_doi'} ?
                                   $options->{'require_only_doi'} : 0;
    my @messages;

    if( $require_only_doi &&
        !tag_is_empty( $dataset, '_journal_paper_doi' ) ) {
        return \@messages;
    }

    if( tag_is_empty( $dataset, '_journal_name_full' ) ) {
        push @messages, 'WARNING, _journal_name_full is undefined';
    }
    if( tag_is_empty( $dataset, '_publ_section_title' ) ) {
        push @messages, 'WARNING, _publ_section_title is undefined';
    }
    if( tag_is_empty( $dataset, '_journal_year' ) &&
        tag_is_empty( $dataset, '_journal_volume') ) {
        push @messages,
             'WARNING, neither _journal_year nor _journal_volume is defined';
    }
    if( tag_is_empty( $dataset, '_journal_page_first' ) &&
        tag_is_empty( $dataset, '_journal_article_reference' ) ) {
        push @messages, 'WARNING, neither _journal_page_first nor '
                      . '_journal_article_reference is defined';
    }
    return \@messages;
}

##
# Checks if the summary chemical formula provided in the data block
# complies with the chemical formula syntax requirements. This subroutine
# checks against a simple syntax that does not take into account things
# such as chemical element types, chemical element order, etc. For a
# more robust formula parsing use the COD::Formulae::Parser::AdHoc::AdHoc
# or the COD::Formulae::Parser::IUCr::IUCr modules.
#
# @param $dataset
#       Reference to a data block as returned by the COD::CIF::Parser.
# @return
#       Reference to an array of audit messages.
##
sub check_chemical_formula_sum
{
    my ($dataset) = @_;
    my @messages;

    my $formula = $dataset->{'values'}{'_chemical_formula_sum'}[0];

    if ( defined $formula ) {
        push @messages, @{check_formula_sum_syntax($formula)};
    }

    return \@messages;
}

sub check_formula_sum_syntax
{
    my ($formula) = @_;
    my @messages;

    my $formula_comp = '[a-zA-Z]{1,2}[0-9.]*';

    if ( $formula !~ /^\s*(?:$formula_comp\s+)*(?:$formula_comp)\s*$/ ) {
        push @messages,
             "WARNING, chemical formula '$formula' could not be parsed -- "
           . 'a chemical formula should consist of a space-seprated '
           . 'chemical element symbols with optional numeric quantities '
           . "(e.g. 'C2 H6 O')";
    }

    return \@messages;
}

sub check_embedded_file_integrity
{
    my ($dataset) = @_;
    my @messages;
    my $values = $dataset->{values};

    my $encodings;
    eval {
        $encodings = get_content_encodings( $dataset );
    };
    if( $@ ) {
        push @messages, $@;
    }

    for my $i (0..$#{$values->{_tcod_file_contents}}) {
        my $content  = $values->{_tcod_file_contents}[$i];
        my $path     = $values->{_tcod_file_name}[$i];
        my $md5sum   = $values->{_tcod_file_md5sum}[$i];
        my $sha1sum  = $values->{_tcod_file_sha1sum}[$i];
        my $encoding;
        if( exists $values->{_tcod_file_content_encoding} ) {
            $encoding = $values->{_tcod_file_content_encoding}[$i];
            $encoding = undef if $encoding eq '.';
        }

        next if $content eq '.' || $content eq '?';
        next if ($md5sum  eq '.' || $md5sum  eq '?') &&
                ($sha1sum eq '.' || $sha1sum eq '?');

        eval {
            if( !$encoding || !$encodings ||
                !exists $encodings->{$encoding} ) {
                if( $encoding && $encodings &&
                    !exists $encodings->{$encoding} ) {
                    push @messages,
                         "WARNING, content encoding stack '$encoding' is not "
                       . 'described -- trying to guess';
                }
                # Perform a default decoding, try to guess the encoding
                # layer type from the encoding ID
                $content = decode_textfield( $content, $encoding );
            } else {
                for my $layer (reverse @{$encodings->{$encoding}}) {
                    $content = decode_textfield( $content, $layer );
                }
            }
        };
        if( $@ ) {
            push @messages,
                 "WARNING, could not decode contents for file '$path' -- "
               . "$@; will not decode contents";
            $content = $values->{_tcod_file_contents}[$i];
        }

        if( $md5sum ) {
            if( md5_hex( $content ) ne $md5sum ) {
                push @messages,
                     "WARNING, MD5 checksums of the original '$path' "
                   . 'and decoded files are different';
            }
        }
        if( $sha1sum ) {
            if( sha1_hex( $content ) ne $sha1sum ) {
                push @messages,
                     "WARNING, SHA1 checksums of the original '$path' "
                   . 'and decoded files are different';
            }
        }
    }
    return \@messages;
}

sub check_z
{
    my ($dataset) = @_;
    my @messages;

    return \@messages if !tag_is_empty( $dataset, '_cell_formula_units_Z' );

    eval {
        cif_estimate_z( $dataset );
    };
    if( $@ ) {
        $@ =~ s/^([A-Z]+),\s*//;
        $@ =~ s/\n$//;
        push @messages, "WARNING, $@";
    }

    return \@messages;
}

sub check_disorder
{
    my( $dataset ) = @_;
    my @messages;

    if ( !exists $dataset->{values}{_atom_site_disorder_group} ) {
        return \@messages;
    }

    my $assemblies = {};
    for my $i (0..$#{$dataset->{values}{_atom_site_disorder_group}}) {
        my $assembly = '.';
        if( exists $dataset->{values}{_atom_site_disorder_assembly} ) {
            $assembly = $dataset->{values}{_atom_site_disorder_assembly}[$i];
        }
        my $group = $dataset->{values}{_atom_site_disorder_group}[$i];
        $assemblies->{$assembly} = {}
            unless exists $assemblies->{$assembly};
        $assemblies->{$assembly}{$group} = 0
            unless exists $assemblies->{$assembly}{$group};
        $assemblies->{$assembly}{$group}++;
    }

    delete $assemblies->{'.'}{'.'};

    if( exists $dataset->{values}{_atom_site_disorder_assembly} ) {
        for my $assembly (sort keys %{$assemblies}) {
            my @counts = map { $assemblies->{$assembly}{$_} }
                             sort keys %{$assemblies->{$assembly}};
            my %counts = map { $_ => 1 } @counts;
            if( scalar( keys %counts ) > 1 ) {
                push @messages,
                     'NOTE, atom count in groups of disorder assembly ' .
                     "'$assembly' are different: " .
                     join( ', ', map { "$assemblies->{$assembly}{$_} ('$_')" }
                                     sort keys %{$assemblies->{$assembly}} );
            }
        }
    }

    return \@messages;
}

##
# Checks if atoms that have special occupancy values (unknown or inapplicable)
# are explicitly marked as dummy atoms.
#
# @param $dataset
#       Reference to a data block as returned by the COD::CIF::Parser.
# @return
#       Reference to an array of audit messages.
##
sub check_occupancies
{
    my( $dataset ) = @_;
    my @messages;

    my $values = $dataset->{'values'};
    if ( exists $values->{'_atom_site_occupancy'} ) {
        for (my $i = 0; $i < @{$values->{'_atom_site_label'}}; $i++) {
            if ( ( $values->{'_atom_site_occupancy'}[$i] eq '.' || 
                   $values->{'_atom_site_occupancy'}[$i] eq '?' ) &&
                 ( !exists $values->{'_atom_site_calc_flag'} ||
                   $values->{'_atom_site_calc_flag'}[$i] ne 'dum' ) ) {
                push @messages,
                     "WARNING, atom '$values->{'_atom_site_label'}[$i]' has " .
                     "a special occupancy value " .
                     "'$values->{'_atom_site_occupancy'}[$i]' " .
                     'even though the atom is not explicitly marked as a ' .
                     'dummy atom' . "\n";
            }
        }
    }

    return \@messages;
}

# Check whether specified tags are all simultaneously present. This
# check in COD is important for _atom_site_fractional_{x,y,z},
# _atom_site_Cartesian_{x,y,z} and _atom_site_aniso_U_?? data items.

sub check_simultaneous_presence
{
    my( $dataset, $tag_lists ) = @_;
    my @messages;

    for my $tag_list (@{$tag_lists}) {
        push @messages, @{check_all_tags_present( $dataset, $tag_list )};
    }

    return \@messages;
}

sub check_all_tags_present
{
    my( $dataset, $tag_list ) = @_;
    my @messages;
    my ( %tags_present, %tags_absent );

    for my $tag (@{$tag_list}) {
        if( exists $dataset->{values}{$tag} ) {
            $tags_present{$tag} ++;
        } else {
            $tags_absent{$tag} ++;
        }
    }

    if( int(keys %tags_present) > 0 &&
        int(keys %tags_absent) > 0 ) {
        my @tags_present = sort {$a cmp $b} keys %tags_present;
        my @tags_absent = sort {$a cmp $b} keys %tags_absent;
        my $tag = $tags_present[0];

        push @messages, "WARNING, data item '$tag' is present, but data item"
            . ( int(@tags_absent) > 1 ? 's' : '' ) . ' ['
            . join( ', ', map { "'$_'" } @tags_absent ) . '] '
            . ( int(@tags_absent) > 1 ? 'are' : 'is' ) . ' absent';
    }

    return \@messages;
}

sub check_pdcif_relations
{
    my ($data) = @_;
    my @messages;

    my $overall_info_datablock;
    my $overall_info_datablock_count = 0;

    my $pd_ids = {};

    my @phases;
    my @diffractograms;

    for( my $i = 0; $i < @{$data}; $i++ ) {
        my $dataset = $data->[$i];
        my $datablock = $dataset->{values};
        if( exists $datablock->{_pd_block_id} ) {
            my $datablock_pd_id = $datablock->{_pd_block_id}[0];
            if( exists $pd_ids->{$datablock_pd_id} ) {
                push @messages,
                     'ERROR, two or more data blocks with _pd_block_id ' .
                     "'$datablock_pd_id' were found -- _pd_block_id " .
                     'must be unique for each data block';
            } else {
                $pd_ids->{$datablock_pd_id} = $i;
            }
        }
        if( grep { /^_pd_/ } @{$dataset->{tags}} ) {
            if( exists $datablock->{_atom_site_label} &&
                has_hkl( $dataset ) &&
                (exists $datablock->{_pd_phase_block_id} ||
                 $datablock->{_pd_block_diffractogram_id}) ) {
                push @messages,
                     "WARNING, data block 'data_$dataset->{name}' " .
                     'describes a phase, a diffractogram and contains ' .
                     'references to other phase/diffractogram data ' .
                     'blocks';
                next;
            } elsif( exists $datablock->{_atom_site_label} &&
                     has_hkl( $dataset ) ) {
                next; # proper single data block pdCIF
            } elsif( exists $datablock->{_atom_site_label} ) {
                push @phases, $i;
            } elsif( has_hkl( $dataset ) ) {
                push @diffractograms, $i;
            }
        }
        if( exists $datablock->{_pd_phase_block_id} &&
            exists $datablock->{_pd_block_diffractogram_id} ) {
            if( !defined $overall_info_datablock ) {
                $overall_info_datablock = $i;
            }
            $overall_info_datablock_count++;
        }
    }

    return \@messages if @phases + @diffractograms == 0;

    if( $overall_info_datablock_count > 1 ) {
        push @messages,
             "NOTE, $overall_info_datablock_count data blocks having both "
           . '_pd_phase_block_id and _pd_block_diffractogram_id were found -- '
           . 'taking the first occurrence as the overall information data block';
    }

    # Checking whether all powder diffraction IDs from the overall
    # information data block (if such exists) point to existing
    # data blocks. Also, checking whether all phases and diffractograms
    # are listed in overall information data block:

    if( $overall_info_datablock_count > 0 ) {
        my $overall_block = $data->[$overall_info_datablock];
        my $overall_data = $overall_block->{values};
        my $overall_dataname = 'data_' . $overall_block->{name};

        for my $phase_id (@{$overall_data->{_pd_phase_block_id}}) {
            if( !exists $pd_ids->{$phase_id} ) {
                push @messages,
                     "ERROR, phase data block with _pd_block_id '$phase_id'"
                   . 'is listed in the _pd_phase_block_id loop of the '
                   . "overall information data block '$overall_dataname', "
                   . 'but does not exist';
            }
        }
        for my $diffractogram_id (@{$overall_data->{_pd_block_diffractogram_id}}) {
            if( !exists $pd_ids->{$diffractogram_id} ) {
                push @messages,
                     'ERROR, diffractogram data block with _pd_block_id '
                   . "'$diffractogram_id' listed in the "
                   . '_pd_block_diffractogram_id loop of the overall '
                   . "data block '$overall_dataname', but does not exist";
            }
        }
        for my $phase_nr (@phases) {
            my $phase_block = $data->[$phase_nr];
            my $phase_data = $phase_block->{values};
            if( ( grep { $_ eq $phase_data->{_pd_block_id}[0] }
                         @{$overall_data->{_pd_phase_block_id}} ) == 0 ) {
                push @messages,
                     'ERROR, phase data block \'data_' . $phase_block->{name}
                   . '\' is not listed in _pd_phase_block_id loop of the '
                   . "overall information data block '$overall_dataname'";
            }
        }
        for my $diffractogram_nr (@diffractograms) {
            my $diffractogram_block = $data->[$diffractogram_nr];
            my $diffractogram_data = $diffractogram_block->{values};
            if( ( grep { $_ eq $diffractogram_data->{_pd_block_id}[0] }
                         @{$overall_data->{_pd_block_diffractogram_id}} ) == 0 ) {
                push @messages,
                      'ERROR, diffractogram data block \'data_'
                    . $diffractogram_block->{name} . '\' is not listed in '
                    . '_pd_block_diffractogram_id loop of the overall '
                    . "information data block '$overall_dataname'";
            }
        }
    }

    # Looking for stray powder diffraction data blocks -- each data block
    # with _pd_block_id should be listed in overall information
    # data block (except publication data block and the overall information
    # data block itself):

    for my $phase_nr (@phases) {
        my $phase_block = $data->[$phase_nr];
        my $phase_data = $phase_block->{values};
        my $phase_dataname = 'data_' . $phase_block->{name};
        if( !exists $phase_data->{_pd_block_diffractogram_id} ||
            tag_is_unknown( $phase_block, '_pd_block_diffractogram_id' ) ) {
            push @messages,
                 "ERROR, phase data block '$phase_dataname' does not "
               . 'contain a diffractogram list (no _pd_block_diffractogram_id)';
            next;
        }
        for my $diffractogram_id (@{$phase_data->{_pd_block_diffractogram_id}}) {
            if( !exists $pd_ids->{$diffractogram_id} ) {
                push @messages,
                     'ERROR, diffractogram data block with _pd_block_id '
                   . "'$diffractogram_id' is listed in the phase data block "
                   . "'$phase_dataname', but does not exist";
                next;
            }
            my $diffractogram_nr = $pd_ids->{$diffractogram_id};
            my $diffractogram_block = $data->[$diffractogram_nr];
            my $diffractogram_data = $diffractogram_block->{values};
            my $diffractogram_dataname = 'data_' . $diffractogram_block->{name};
            if( !exists $diffractogram_data->{_pd_phase_block_id} ) {
                push @messages,
                     "ERROR, diffractogram data block '$diffractogram_dataname' "
                   . 'does not contain a phase list (no _pd_phase_block_id)';
                next;
            }
            my $found = 0;
            for my $phase_id (@{$diffractogram_data->{_pd_phase_block_id}}) {
                if( !exists $pd_ids->{$phase_id} ) {
                    push @messages,
                         'ERROR, phase data block with _pd_block_id '
                       . "'$phase_id' is listed in the diffractogram data block "
                       . "'$diffractogram_dataname', but does not exist";
                    next;
                }
                if( $pd_ids->{$phase_id} == $phase_nr ) {
                    $found = 1;
                    last;
                }
            }
            if( !$found ) {
                # If diffractogram data block does not contain a backlink
                # to the phase block, we assume that the backlink is:
                push @messages,
                     'WARNING, value \'' . $phase_data->{_pd_block_id}[0] . '\' '
                   . 'seems to be missing in the _pd_phase_block_id list of '
                   . "the diffractogram data block '$diffractogram_dataname'";
            }
        }
    }

    for my $diffractogram_nr (@diffractograms) {
        my $diffractogram_block = $data->[$diffractogram_nr];
        my $diffractogram_data = $diffractogram_block->{values};
        my $diffractogram_dataname = 'data_' . $diffractogram_block->{name};
        if( !exists $diffractogram_data->{_pd_phase_block_id} ||
            tag_is_unknown( $diffractogram_block, '_pd_phase_block_id' ) ) {
            if( @phases > 1 ) {
                push @messages,
                     "ERROR, diffractogram data block '$diffractogram_dataname' " .
                     'does not contain a phase list (no _pd_phase_block_id)';
            }
            next;
        }
        for my $phase_id (@{$diffractogram_data->{_pd_phase_block_id}}) {
            if( !exists $pd_ids->{$phase_id} ) {
                push @messages,
                     "ERROR, phase data block with _pd_block_id '$phase_id' "
                   . 'is listed in the diffractogram data block '
                   . "'$diffractogram_dataname', but does not exist";
                next;
            }
            my $phase_nr = $pd_ids->{$phase_id};
            my $phase_block = $data->[$phase_nr];
            my $phase_data = $phase_block->{values};
            my $phase_dataname = 'data_' . $phase_block->{name};
            if( !exists $phase_data->{_pd_block_diffractogram_id} ) {
                push @messages,
                     "ERROR, phase data block '$phase_dataname' "
                   . 'does not contain a diffractogram list '
                   . '(no _pd_block_diffractogram_id)';
                next;
            }
            my $found = 0;
            for my $diffractogram_id (@{$phase_data->{_pd_block_diffractogram_id}}) {
                if( !exists $pd_ids->{$diffractogram_id} ) {
                    push @messages,
                         'ERROR, diffractogram data block with _pd_block_id '
                       . "'$diffractogram_id' is listed in the phase data block "
                       . "'$phase_dataname', but does not exist";
                    next;
                }
                if( $pd_ids->{$diffractogram_id} == $diffractogram_nr ) {
                    $found = 1;
                    last;
                }
            }
            if( !$found ) {
                # If phase data block does not contain a backlink to the
                # diffractogram, we are not sure if it is omitted or added:
                push @messages,
                     'ERROR, value \'' . $diffractogram_data->{_pd_block_id}[0]
                   . '\' seems to be missing in _pd_block_diffractogram_id '
                   . "list of the phase data block '$phase_dataname'";
            }
        }
    }

    return \@messages;
}

sub check_temperature_factors
{
    my($dataset, $options) = @_;
    my @messages;

    my $mandatory_year_cutoff = defined $options->{'mandatory_year_cutoff'} ?
                                        $options->{'mandatory_year_cutoff'} :
                                       '1969';

    my $values = $dataset->{values};

    if( tag_is_empty( $dataset, '_journal_year' ) ) {
        return \@messages;
    }
    if( $values->{_journal_year}[0] <= $mandatory_year_cutoff ) {
        return \@messages;
    }

    if( !tag_is_empty($dataset,'_atom_site_B_iso_or_equiv') ||
        !tag_is_empty($dataset,'_atom_site_U_iso_or_equiv') ) {
        return \@messages;
    }
    foreach my $indexes ( '11', '12', '13', '22', '23', '33' ) {
        if( !tag_is_empty($dataset,
            '_atom_site_aniso_B_' . $indexes) ||
            !tag_is_empty($dataset,
            '_atom_site_aniso_U_' . $indexes) ) {
            return \@messages;
        }
    }
    push @messages, 'WARNING, structure is published after '
       . "$mandatory_year_cutoff, but does not contain "
       . 'temperature factors';

    return \@messages;
}

##
# Checks if the data item values provided in the data block lie within the
# expected limits. All checked non-numeric or *negative* values are reported
# as erroneous.
#
# @param $dataset
#       Reference to a data block as returned by the COD::CIF::Parser.
# @param $limits_table
#       Reference to a data structure containing the expected limits.
#       Example of the data structure:
#       {
#         # Range limits are specified using arrays [ $lower, $upper ]
#         '_data_name_1' => [
#           # Severity of the audit message is based on the array index
#           [ 0, 1 ], # Values outside range [0; 1] will raise an ERROR
#           [ 2, 5 ], # Values outside range [2; 5] will raise a WARNING
#           [ 6, 9 ]  # Values outside range [6; 9] will raise a NOTE
#         ],
#         # Upper limit can be omitted
#         '_data_name_2' => [
#           [ 3 ], # Values greater than 3 will raise an ERROR
#           [ 2 ], # Values greater than 2 will raise a WARNING
#           # Not all error levels need to be defined
#         ],
#         ...
#       }
#
# @return
#       Reference to an array of audit messages.
##
sub check_limits
{
    my ($dataset, $limits_table) = @_;
    my @messages;

    my @report_names = qw( ERROR WARNING NOTE );
    my $values = $dataset->{'values'};

    foreach my $tag( sort keys %{$limits_table} ) {
        next if !exists $values->{$tag};

        my $value = $values->{$tag}[0];
        # FIXME: special values are not properly checked
        next if $value =~ /^[.?]$/;
        if( $value !~ /^$CIF_NUMERIC_REGEX$/ ) {
            push @messages, "ERROR, data item '$tag' value '$value' is not numeric";
            next;
        } else {
            # TODO: this subroutine need to be thoroughly tested.
            # FIXME: Currently, mixed-limit arrays are not handled correctly,
            # i.e.:
            # {
            #  _data_name_1 => [
            #       [ 5 ], [ 4, 2 ], [ 1 ]
            #   ],
            #  _data_name_2 => [
            #       [ 1, 3 ], [ 2 ], [ 5, 8 ]
            #  ]
            # }
            my $number = $1;
            # FIXME: No way to check negative values?
            if( $number < 0 ) {
                push @messages, "WARNING, data item '$tag' value '$value' should "
                   . 'be in range [0.0, +inf)';
                next;
            }
            if( !defined $limits_table->{$tag}[0][1] ) {
                foreach my $i ( 0..$#{ $limits_table->{$tag} } ) {
                    my $limit = $limits_table->{$tag}[$i][0];
                    if( $number > $limit ) {
                        push @messages, "$report_names[$i], data item '$tag' "
                                      . "value '$value' is > $limit";
                        last;
                    }
                }
            } else {
                foreach my $i( 0..$#{ $limits_table->{$tag} } ) {
                    my $begin = $limits_table->{$tag}[$i][0];
                    my $end   = $limits_table->{$tag}[$i][1];
                    if( ($number < $begin) || ($number > $end) ) {
                        push @messages, "$report_names[$i], data item '$tag' "
                                      . "value '$value' lies outside the range "
                                      . "[$begin, $end]";
                        last;
                    }
                }
            }
        }
    }
    return (\@messages);
}

##
# Checks if the data block contains data item values that have standard
# uncertainty values as part of their numerical expression even though they
# are not eligible to do so.
#
# @param $dataset
#       Reference to a data block as returned by the COD::CIF::Parser.
# @param $data_names
#       Reference to an array of data names that should not contain standard
#       uncertainty values as part of their numerical expression.
# @return
#       Reference to an array of audit messages.
##
sub check_su_eligibility
{
    my ( $dataset, $data_names ) = @_;
    my @messages;

    for ( @{$data_names} ) {
        if ( defined $dataset->{'values'}{$_} &&
             $dataset->{'values'}{$_}[0] =~ /^$CIF_NUMERIC_REGEX$/ ) {
            if ($2) {
                push @messages,"WARNING, data item '$_' value is " .
                     "'$dataset->{'values'}{$_}[0]', but it should " .
                     'be numeric and without precision (s.u. value)';
            }
        }
    }

    return \@messages;
}

##
# Checks if the given data items exist in the data block.
#
# @param $dataset
#       Reference to a data block as returned by the COD::CIF::Parser.
# @param $data_names
#       Reference to a hash that details what data names should be
#       searched for in the data block. The data names serve a hash
#       keys and the values correspond to the severity of the audit
#       message:
#       {
#       # Data item '_tag_1' is mandatory.
#       # An error message will be generated in case it is not found.
#           '_tag_1' => 1,
#       # Data item '_tag_2' is optional, but highly recommended
#       # An warning message will be generated in case it is not found.
#           '_tag_2' => 0,
#       }
# @return
#       Reference to an array of audit messages.
##
sub check_mandatory_presence
{
    my ( $dataset, $data_names ) = @_;
    my @messages;

    for ( sort keys %{$data_names} ) {
        if ( !defined $dataset->{'values'}{$_} ) {
            if ( $data_names->{$_} ) {
                push @messages,
                    "ERROR, mandatory data item '$_' was not found"
            } else {
                push @messages,
                     "WARNING, recommended data item '$_' was not found"
            }
        }
    }

    return \@messages;
}

##
# Checks if the timestamp values provided in the data block can be parsed
# as a date value (YYYY-MM-DD) or a datetime value (as defined in RFC3339).
# Any date that specifies a moment in the future as compared to the
# current machine time is also reported.
#
# @param $dataset
#       Reference to a data block as returned by the COD::CIF::Parser.
# @param $data_names
#       Reference to an array of data names that should be checked.
# @return
#       Reference to an array of audit messages.
##
sub check_timestamp
{
    my ( $dataset, $data_names ) = @_;

    my @messages;
    for my $name ( @{$data_names} ) {
        if ( exists $dataset->{'values'}{$name} ) {
            foreach ( @{$dataset->{'values'}{$name}} ) {
                my $datetime;
                eval {
                    $datetime = parse_datetime($_);
                };
                if ($@) {
                    push @messages, "ERROR, data item '$name' value " .
                         "'$_' could not be succesfully parsed as a timestamp " .
                         'value';
                } else {
                    if ( DateTime->compare($datetime, DateTime->now() ) > 0 ) {
                        push @messages, "ERROR, data item '$name' value " .
                             "'$_' seems to specify a moment of time in " .
                             'the future';
                    }
                }
            };
        }
    }

    return \@messages;
}

1;
