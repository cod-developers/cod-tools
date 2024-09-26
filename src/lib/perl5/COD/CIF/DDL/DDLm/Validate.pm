#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* A set of subroutines used to validate CIF files against ontologies
#* expressed using the Methods Dictionary Definition Language (DDLm).
#**

package COD::CIF::DDL::DDLm::Validate;

use strict;
use warnings;
use List::MoreUtils qw( any first_index uniq );
use URI::Split qw( uri_split );

use COD::CIF::DDL qw( get_category_name_from_local_data_name );
use COD::CIF::DDL::DDLm qw( build_ddlm_dic
                            canonicalise_ddlm_value
                            get_all_data_names
                            get_category_id
                            get_data_alias
                            get_definition_class
                            get_type_contents
                            get_type_container
                            get_type_dimension
                            get_type_purpose
                            is_looped_category );
use COD::CIF::DDL::Ranges qw( parse_range
                              range_to_string
                              is_in_range );
use COD::CIF::DDL::Validate qw( canonicalise_tag
                                check_enumeration_set );
use COD::CIF::Tags::Manage qw( get_item_loop_index
                               has_special_value
                               has_numeric_value );
use COD::DateTime qw( parse_date parse_datetime );
use COD::Precision qw( unpack_cif_number );
use COD::SemVer qw( parse_version_string );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    ddlm_validate_data_block
);

##
# Validates a data block against a DDLm-conformant dictionary.
#
# @source [1]
#       https://github.com/COMCIFS/comcifs.github.io/blob/706b1a3168c6607fdb1a44dc1d863a57e90dadf5/accepted/ddlm_dictionary_style_guide.md?plain=1#L268
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @param $options
#       Reference to a hash of options. The following options are recognised:
#       {
#         # Report data items that have been replaced by other data items.
#         # Default: 0.
#           'report_deprecated' => 0,
#         # Ignore the case while matching enumerators.
#         # Default: 0.
#           'ignore_case'       => 0,
#         # Array reference to a list of data items that should be
#         # treated as potentially having values consisting of a
#         # combination of several enumeration values. Data items
#         # are identified by data names.
#         # Default: [].
#           'enum_as_set_tags'  => [ '_atom_site.refinement_flags',
#                                    '_atom_site.refinement_flags', ],
#         # Report missing mandatory s.u. values.
#         # Default: 0.
#           'report_missing_su' => 0,
#         # Maximum number of validation issues that are reported for
#         # each unique combination of validation criteria and validated
#         # data items. Negative values remove the limit altogether.
#         # Default: -1.
#           'max_issue_count'   => -1,
#         # Do not report missing recommended attributes if they fit
#         # the criteria defined in the IUCr DDLm dictionary style guide
#         # version 1.1.0, rule 3.1.6 [1]. Default: 0.
#           'follow_iucr_style_guide' => 0
#       }
# @return
#       Array reference to a list of validation issue data structures
#       of the following form:
#       {
#         # Code of the data block that caused the validation issue
#           'data_block_code' => 'issue_block_code',
#         # Code of the save frame that caused the validation issue
#         # Might be undefined
#           'save_frame_code' => 'issue_frame_code',
#         # Code of the validation test that raised the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Human-readable description of the issue
#           'message'         => 'description of the issue'
#       }
##
sub ddlm_validate_data_block
{
    my ( $data_block, $dic, $options ) = @_;

    my $max_issue_count   = exists $options->{'max_issue_count'} ?
                                   $options->{'max_issue_count'} : -1;
    my $follow_iucr_style_guide =
                            exists $options->{'follow_iucr_style_guide'} ?
                                   $options->{'follow_iucr_style_guide'} : 0;
    my @issues;
    # NOTE: the DDLm dictionary contains a special data structure that
    # defines which data items are mandatory, recommended and forbidden
    # in certain dictionary scopes (Dictionary, Category, Item)
    my $application_scope = extract_application_scope( $dic );
    if ( defined $application_scope ) {
        if ($follow_iucr_style_guide) {
            $application_scope = apply_iucr_style_guide_exceptions(
                                     $application_scope,
                                 );
        }
        push @issues,
             @{validate_application_scope( $data_block, $application_scope )};
    }

    my $data_name = $data_block->{'name'};
    my $data_block_issues = validate_data_frame( $data_block, $dic, $options );
    for my $issue ( @{ summarise_validation_issues( $data_block_issues ) } ) {
        $issue->{'data_block_code'} = $data_name;
        push @issues, $issue;
     }

    # DDLm dictionaries contain save frames
    for my $save_frame ( @{ $data_block->{'save_blocks'} } ) {
        my $save_frame_issues = validate_data_frame( $save_frame, $dic, $options );
        for my $issue ( @{ summarise_validation_issues( $save_frame_issues ) } ) {
            $issue->{'data_block_code'} = $data_name;
            $issue->{'save_frame_code'} = $save_frame->{'name'};
            push @issues, $issue;
        }
    }

    if ($max_issue_count > -1) {
        @issues = limit_validation_issues(\@issues, $max_issue_count)
    }

    return \@issues;
}

##
# Groups validation issues with identical messages together and replaces
# each group with a single validation issue that contains a summarised
# version of the message.
#
# @param $issues
#       Array reference to a list of validation message data structures
#       of the following form:
#       {
#         # Code of the data block that caused the validation issue
#           'data_block_code' => 'issue_block_code',
#         # Code of the save frame that caused the validation issue
#         # Might be undefined
#           'save_frame_code' => 'issue_frame_code',
#         # Code of the validation test that raised the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Human-readable description of the issue
#           'message'         => 'description of the issue'
#       }
#
# @return $summarised_issues
#       Reference to an array of unique summarised issues.
##
sub summarise_validation_issues
{
    my ($issues) = @_;

    my %message_count;
    for my $issue (@{$issues}) {
        $message_count{$issue->{'message'}}{'count'}++;
        $message_count{$issue->{'message'}}{'representative_issue'} = $issue;
    }

    my @summarised_issues;
    for my $message ( sort keys %message_count ) {
        my $count = $message_count{$message}->{'count'};
        my $issue = $message_count{$message}->{'representative_issue'};
        if( $count > 1 ) {
            $issue->{'message'} = $message . " ($count times)";
        }
        push @summarised_issues, $issue;
    }

    return \@summarised_issues;
}

sub limit_validation_issues
{
    my ($issues, $max_issue_count) = @_;

    my %grouped_issues;
    for my $issue ( @{$issues} ) {
        my $constraint = $issue->{'test_type'};
        my $data_name_key = join "\x{001E}", @{$issue->{'data_items'}};
        push @{$grouped_issues{$constraint}{$data_name_key}}, $issue;
    }

    # TODO: move hash out of the subroutine
    my %test_types = (
        'STANDARD_UNCERTAINTY.FORBIDDEN' =>
            'eligibility to have associated standard uncertainty values',
        'STANDARD_UNCERTAINTY.VALUE_MISMATCH' =>
            'compatibility between standard uncertainty values expressed' .
            'as a separate data item and those expressed using the concise ' .
            'notation',
        'STANDARD_UNCERTAINTY.MANDATORY' =>
            'requirement to have associated standard uncertainty values',
        'DIFFERING_ALIAS_VALUES' =>
            'identity between the values of aliased data items',
        'PRESENCE_OF_LINKED_DATA_ITEM_VALUE' =>
            'mandatory presence of a linked data item value',
        'PRESENCE_OF_LINKED_DATA_ITEM' =>
            'mandatory presence of a linked data item',
        'CONTENT_TYPE.MANDATORY_LIST_STRUCTURE' =>
            'data values appearing in a \'LIST\' data structure',
        'CONTENT_TYPE.LIST_SIZE_CONSTRAINT' =>
            'data values appearing in a \'LIST\' data structure ' .
            'of the correct size',
        'TYPE_CONSTRAINT.QUOTED_NUMERIC_VALUES' =>
            'proper quote usage with numeric values',
        'TYPE_CONSTRAINT.TEXT_TYPE_FORBIDDEN_CHARACTER' =>
            'data value of the \'TEXT\' type not having forbidden characters',
        'TYPE_CONSTRAINT.CODE_TYPE_FORBIDDEN_CHARACTER' =>
            'data value of the \'CODE\' type not having forbidden characters',
        'TYPE_CONSTRAINT.NAME_TYPE_FORBIDDEN_CHARACTER' =>
            'data value of the \'NAME\' type not having forbidden characters',
        'TYPE_CONSTRAINT.TAG_TYPE_START_CHARACTER' =>
            'data value of the \'TAG\' type having the correct prefix',
        'TYPE_CONSTRAINT.TAG_TYPE_START_CHARACTER' =>
            'data value of the \'TAG\' type not having forbidden characters',
        'TYPE_CONSTRAINT.URI_TYPE_START_CHARACTER' =>
            'data value of the \'URI\' type having the correct prefix',
        'TYPE_CONSTRAINT.URI_TYPE_FORBIDDEN_CHARACTER' =>
            'data value of the \'URI\' type not having forbidden characters',
        'TYPE_CONSTRAINT.URI_TYPE_SCHEME_PREFIX',
            'data value of the \'URI\' type having a scheme prefix',
        'TYPE_CONSTRAINT.DATE_TYPE_FORMAT' =>
            'data value conformance to the \'DATE\' type',
        'TYPE_CONSTRAINT.DATETIME_TYPE_FORMAT' =>
            'data value conformance to the \'DATETIME\' type',
        'TYPE_CONSTRAINT.VERSION_TYPE_FORMAT' =>
            'data value conformance to the \'VERSION\' type',
        'TYPE_CONSTRAINT.DIMENSION_TYPE_FORMAT' =>
            'data value conformance to the \'DIMENSION\' type',
        'TYPE_CONSTRAINT.RANGE_TYPE_FORMAT' =>
            'data value conformance to the \'RANGE\' type',
        'TYPE_CONSTRAINT.RANGE_TYPE_LOWER_GT_UPPER' =>
            'data value of the \'RANGE\' type having a lower bound that is ' .
            'greater than the upper bound',
        'TYPE_CONSTRAINT.COUNT_TYPE_CONSTRAINT' =>
            'data value conformance to the \'COUNT\' type',
        'TYPE_CONSTRAINT.INDEX_TYPE_CONSTRAINT' =>
            'data value conformance to the \'INDEX\' type',
        'TYPE_CONSTRAINT.INTEGER_TYPE_CONSTRAINT' =>
            'data value conformance to the \'INTEGER\' type',
        'TYPE_CONSTRAINT.REAL_TYPE_CONSTRAINT' =>
            'data value conformance to the \'REAL\' type',
        'TYPE_CONSTRAINT.IMAG_TYPE_FORMAT' =>
            'data value conformance to the \'IMAG\' type',
        'TYPE_CONSTRAINT.COMPLEX_TYPE_FORMAT' =>
            'data value conformance to the \'COMPLEX\' type',
        'TYPE_CONSTRAINT.SYMOP_TYPE_FORMAT' =>
            'data value conformance to the \'SYMOP\' type',
        'TYPE_CONTAINER.TOP_LEVEL_MATRIX' =>
            'data values having a top level \'MATRIX\' container',
        'TYPE_CONTAINER.TOP_LEVEL_LIST' =>
            'data values having a top level \'LIST\' container',
        'TYPE_CONTAINER.TOP_LEVEL_LIST_SIZE' =>
            'data values having a top level \'LIST\' container of ' .
            'the correct size',
        'TYPE_CONTAINER.TOP_LEVEL_TABLE' =>
            'data values having a top level \'TABLE\' container',
        'TYPE_CONTAINER.NO_TOP_LEVEL' =>
            'data values having no top level container',
        'TYPE_CONTAINER.MATRIX_ROW_COUNT' =>
            'data value being a matrix with the correct row count',
        'TYPE_CONTAINER.MATRIX_ROW_LENGTH' =>
            'data value being a matrix with the correct row length',
        'TYPE_CONTAINER.MISMATCHING_MATRIX_ROW_LENGTHS' =>
            'data value being a matrix with rows of the same length',
        'ENUMERATION_SET' =>
            'data value belonging to the specified enumeration set',
        'LOOP_CONTEXT.MUST_NOT_APPEAR_IN_LOOP' =>
            'data items that incorrectly appear inside of a looped list',
        'CATEGORY_INTEGRITY' =>
            'category integrity',
        'LOOP.CATEGORY_HOMOGENEITY' =>
            'items in a looped list all belonging to the same category',
        'KEY_ITEM_PRESENCE' =>
            'mandatory key item presence',
        'SIMPLE_KEY_UNIQUENESS'    =>
            'simple loop key uniqueness',
        'COMPOSITE_KEY_UNIQUENESS' =>
            'composite loop key uniqueness',
        'PRESENCE_OF_DEPRECATED_ITEM' =>
            'presence of a deprecated data item',
        'ENUM_RANGE.IN_RANGE' =>
            'data value belonging to the specified value range',
        'SCOPE.PROHIBITED' =>
            'data item appearing in a definition prohibited scope',
        'SCOPE.MANDATORY' =>
            'data item not appearing in a mandatory definition scope',
        'SCOPE.RECOMMENDED' =>
            'data item not appearing in a recommended definition scope',
        'ISSUE_COUNT_LIMIT_EXCEEDED' =>
            'the number of issues of the same test type exceeding ' .
            'the maximum issue count',
    );

    my @limited_issues;
    for my $constraint (sort keys %grouped_issues) {
        for my $data_name_key (sort keys %{$grouped_issues{$constraint}}) {
            my @group_issues = @{$grouped_issues{$constraint}{$data_name_key}};
            my $group_size = scalar @group_issues;

            my $description;
            if ( defined $test_types{$constraint} ) {
                $description = $test_types{$constraint};
            }

            if ( $group_size > $max_issue_count ) {
                my $limit_exceeded_issue = {
                    'test_type'  => 'ISSUE_COUNT_LIMIT_EXCEEDED',
                    'data_items' => $group_issues[0]->{'data_items'},
                    'message'    =>
                        'a test ' .
                        (defined $description ? "of $description " : '') .
                        'involving the [' .
                            ( join ', ',
                                map { q{'} . ( canonicalise_tag($_) ) . q{'} }
                                    @{$group_issues[0]->{'data_items'}} ) .
                        "] data items resulted in $group_size validation messages " .
                        '-- the number of reported messages is limited to ' .
                        "$max_issue_count"
                };

                for my $property ('data_block_code', 'save_frame_code') {
                    next if !defined $group_issues[0]->{$property};
                    $limit_exceeded_issue->{$property} =
                                            $group_issues[0]->{$property};
                }

                push @limited_issues, $limit_exceeded_issue;
                $group_size = $max_issue_count;
            }

            push @limited_issues, @group_issues[0..($group_size - 1)];
        }
    }

    return @limited_issues;
}

##
# Validates a data block against a DDLm-conformant dictionary.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @param $options
#       Reference to a hash of options. The following options are recognised:
#       {
#         # Report data items that have been replaced by other data items
#           'report_deprecated' => 0,
#         # Ignore the case while matching enumerators
#           'ignore_case'       => 0,
#         # Array reference to a list of data items that should be
#         # treated as potentially having values consisting of a
#         # combination of several enumeration values. Data items
#         # are identified by data names
#           'enum_as_set_tags'  => [ '_atom_site.refinement_flags',
#                                    '_atom_site.refinement_flags', ],
#         # Report missing mandatory s.u. values
#           'report_missing_su' => 0,
#         # Multiplier that should be applied to the standard
#         # uncertainty (s.u.) when determining if a numeric
#         # value resides in the specified range. For example,
#         # a multiplier of 3.5 means that the value is treated
#         # as valid if it falls in the interval of
#         # [lower bound - 3.5 * s.u.; upper bound + 3.5 * s.u.]
#         # Default: 3
#           'range_su_multiplier' => 3,
#       }
# @return
#       Array reference to a list of validation issue data structures
#       of the following form:
#       {
#         # Code of the data block that caused the validation issue
#           'data_block_code' => 'issue_block_code',
#         # Code of the save frame that caused the validation issue
#         # Might be undefined
#           'save_frame_code' => 'issue_frame_code',
#         # Code of the validation test that raised the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Human-readable description of the issue
#           'message'         => 'description of the issue'
#       }
##
sub validate_data_frame
{
    my ($data_frame, $dic, $options) = @_;

    my @issues;
    push @issues, @{validate_type_contents($data_frame, $dic)};
    push @issues, @{validate_enumeration_set($data_frame, $dic, $options)};
    push @issues, @{validate_range($data_frame, $dic, $options)};
    push @issues, @{validate_type_container($data_frame, $dic)};
    push @issues, @{validate_loops($data_frame, $dic)};
    push @issues, @{validate_aliases($data_frame, $dic)};

    if ( $options->{'report_deprecated'} ) {
        push @issues, @{report_deprecated($data_frame, $dic)};
    }

    push @issues, @{validate_linked_items($data_frame, $dic)};
    push @issues, @{validate_standard_uncertainties(
                    $data_frame, $dic,
                    {
                      'report_missing_su' => $options->{'report_missing_su'}
                    }
                )};

    return \@issues;
}

##
# Checks if the usage of standard uncertainty values is correct according
# to the given DDLm dictionary.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @param $options
#       Reference to a hash of options. The following options are recognised:
#       {
#       # Report missing mandatory s.u. values
#           'report_missing_su' => 0
#       }
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
#
##
sub validate_standard_uncertainties
{
    my ($data_frame, $dic, $options) = @_;

    $options = {} if !defined $options;
    my $report_missing_su = defined $options->{'report_missing_su'} ?
                                    $options->{'report_missing_su'} : 0;

    my @issues;
    for my $tag ( @{$data_frame->{'tags'}} ) {
        next if ( !exists $dic->{'Item'}{$tag} );

        push @issues, @{check_su_eligibility($tag, $data_frame, $dic)};
        push @issues, @{check_su_pairs($tag, $data_frame, $dic)};

        if ( $report_missing_su ) {
            push @issues, @{ check_missing_su_values($tag, $data_frame, $dic) };
        }
    }

    return \@issues;
}

##
# Checks the eligibility of a data item to contain standard uncertainty values.
#
# @param $tag
#       Data name of the data item that should be checked.
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_su_eligibility
{
    my ($tag, $data_frame, $dic) = @_;

    my @issues;
    return \@issues if has_su_eligibility($tag, $data_frame, $dic);

    # Numeric types capable of having s.u. values in parenthetic notation
    my $type_content = lc get_type_contents($tag, $data_frame, $dic);
    if ( ! ( $type_content eq 'count'   || $type_content eq 'index' ||
           $type_content eq 'integer' || $type_content eq 'real' ) ) {
        return \@issues;
    };

    # Get SU values provided using the parenthetic notation
    my $su_values = get_su_from_data_values( $data_frame, $tag );
    for ( my $i = 0; $i < @{$data_frame->{'values'}{$tag}}; $i++ ) {
        if ( defined $su_values->[$i] ) {
            next if $su_values->[$i] eq 'spec';
            next if $su_values->[$i] eq 'text';

            my $value = $data_frame->{'values'}{$tag}->[$i];
            my $par_su = '(-)';
            if ( $value =~ /([(][0-9]+[)])$/ ) {
                $par_su = $1;
            }
            push @issues,
                 {
                    'test_type'  => 'STANDARD_UNCERTAINTY.FORBIDDEN',
                    'data_items' => [ $tag ],
                    'message'    =>
                        'data item \'' . ( canonicalise_tag($tag) ) .
                        "' value '$value' is not permitted to contain " .
                        "the appended standard uncertainty value '$par_su'"
                 }
        }
    }

    return \@issues;
}

##
# Evaluates if the given item can have associated standard uncertainty
# values. Data items that are eligible to have associated SU values include:
#   - All measurand data items [1,2].
#   - The '_description_example.case' data item when it appears in
#     the definition of a measurand item [3,4].
#
# @source [1]
#       ddl.dic DDLm reference dictionary version 4.1.0,
#       definition of the '_type.purpose' attribute.
# @source [2]
#       https://github.com/COMCIFS/cif_core/blob/491bf77f39ef2f989b9230ea90e6345f8282a4b7/ddl.dic#L1936
# @source [3]
#       ddl.dic DDLm reference dictionary version 4.1.0,
#       definition of the '_description_example.case' attribute.
# @source [4]
#       https://github.com/COMCIFS/cif_core/blob/491bf77f39ef2f989b9230ea90e6345f8282a4b7/ddl.dic#L428
#
# @param $tag
#       Data name of the data item that should be checked.
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @return
#       '1' if the item can have associated standard uncertainty values,
#       '0' otherwise.
##
sub has_su_eligibility
{
    my ($tag, $data_frame, $dic) = @_;

    my $type_purpose;
    if ($tag eq '_description_example.case') {
        $type_purpose = get_type_purpose($data_frame);
    } else {
        my $dic_item = $dic->{'Item'}{$tag};
        $type_purpose = get_type_purpose($dic_item);
    }

    return 1 if ( lc $type_purpose eq 'measurand' );

    return 0;
}

##
# Checks if a data item does not contain ambiguous standard uncertainty values.
# A standard uncertainty value is considered ambiguous if the values provided
# using the parenthetic notation and those provided using a separate data item
# do not match.
#
# @param $tag
#       Data name of the data item that should be checked.
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_su_pairs
{
    my ($tag, $data_frame, $dic) = @_;

    my $dic_item = $dic->{'Item'}{$tag};
    return [] if get_type_purpose($dic_item) ne 'measurand';

    my @su_data_names = @{ get_su_data_names_in_frame($dic, $data_frame, $tag) };
    return [] if !@su_data_names;

    my @issues;
    my $su_data_name = lc $su_data_names[0];
    my $par_su_values = get_su_from_data_values( $data_frame, $tag );
    my $item_su_values = $data_frame->{'values'}{$su_data_name};
    for ( my $i = 0; $i < @{$data_frame->{'values'}{$tag}}; $i++ ) {

        next if !defined $par_su_values->[$i];
        next if $par_su_values->[$i] eq 'text';
        next if $par_su_values->[$i] eq 'special';

        next if (  has_special_value( $data_frame, $su_data_name, $i ) );
        next if ( !has_numeric_value( $data_frame, $su_data_name, $i ) );

        if ( $item_su_values->[$i] ne $par_su_values->[$i] ) {
            push @issues,
                 {
                    'test_type'  => 'STANDARD_UNCERTAINTY.VALUE_MISMATCH',
                    'data_items' => [ $tag, $su_data_name ],
                    'message'    =>
                        'data item \'' . ( canonicalise_tag($tag) ) .
                        "' value '$data_frame->{'values'}{$tag}[$i]' " .
                        'has an ambiguous standard uncertainty value -- ' .
                        'values provided using the parenthetic notation ' .
                        "('$par_su_values->[$i]') and the '" .
                        ( canonicalise_tag($su_data_name) ) .
                        "' data item ('$item_su_values->[$i]') do not match"
                 }
        }
    }

    return \@issues;
}

##
# Checks if a data item contains the mandatory standard uncertainty values
# using either the parenthetic notation or as a separate data item.
#
# @param $tag
#       Data name of the data item that should be checked.
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_missing_su_values
{
    my ($tag, $data_frame, $dic) = @_;

    my $dic_item = $dic->{'Item'}{$tag};
    return [] if get_type_purpose($dic_item) ne 'measurand';

    return [] if @{ get_su_data_names_in_frame($dic, $data_frame, $tag) };

    my @issues;
    my $par_su_values = get_su_from_data_values( $data_frame, $tag );
    for ( my $i = 0; $i < @{$par_su_values}; $i++ ) {
        if ( !defined $par_su_values->[$i] ) {
            push @issues,
                 {
                    'test_type'  => 'STANDARD_UNCERTAINTY.MANDATORY',
                    'data_items' => [ $tag ],
                    'message'    =>
                        'data item \'' . ( canonicalise_tag($tag) ) .
                        "' value '$data_frame->{'values'}{$tag}[$i]' " .
                        'violates content purpose constraints -- data values ' .
                        'of the \'Measurand\' type must have their standard ' .
                        'uncertainties provided'
                 }
        }
    }

    return \@issues;
}

##
# Checks if data names that refer to the same data item (aliases) have
# identical data values.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub validate_aliases
{
    my ($data_frame, $dic) = @_;

    my @issues;

    my $alias_groups = cluster_aliases($data_frame, $dic);
    for my $key ( sort keys %{$alias_groups} ) {
        my $alias_group = $alias_groups->{$key};
        # TODO: currently, looped data items are silently skipped.
        # They should be properly validated or at least reported
        next if any { @{$data_frame->{'values'}{$_}} > 1 } @{$alias_group};

        my $type_contents = get_type_contents( $alias_group->[0],
                                               $data_frame,
                                               $dic );
        my $first_value = $data_frame->{'values'}{$alias_group->[0]}[0];

        if ( any { !compare_ddlm_values(
                $first_value,
                $data_frame->{'values'}{$_}[0],
                $type_contents ) } @{$alias_group} ) {
            push @issues,
                 {
                    'test_type'  => 'DIFFERING_ALIAS_VALUES',
                    'data_items' => $alias_group,
                    'message'    =>
                        'incorrect usage of data item aliases -- ' .
                        'data names [' .
                        ( join ', ',
                            map { q{'} . ( canonicalise_tag($_) ) . q{'} }
                                @{$alias_group} ) .
                        '] refer to the same data item, but have differing ' .
                        'values [' .
                        ( join ', ', map { "'$data_frame->{'values'}{$_}[0]'" }
                                                @{$alias_group} ) .
                        ']'
                 }
        }
    }

    return \@issues;
}

sub cluster_aliases
{
    my ( $data_frame, $dic ) = @_;

    my %alias_groups;
    for my $tag ( @{$data_frame->{'tags'}} ) {
      if ( exists $dic->{'Item'}{$tag} ) {
        my $dic_item = $dic->{'Item'}{$tag};
        my $data_names = get_data_alias($dic_item);
        next if !@{$data_names};
        my $key = build_data_name_key($data_names);
        push @{ $alias_groups{$key} }, $tag;
      }
    };

    for my $key ( keys %alias_groups ) {
        if ( @{$alias_groups{$key}} < 2 ) {
            delete $alias_groups{$key};
        }
    }

    return \%alias_groups;
}

sub build_data_name_key
{
    my ($data_names) = @_;

    my $join_char = "\x{001E}";
    return join $join_char, sort map { lc } @{$data_names};
}

##
# Evaluates if a data item is eligible to contain the standard uncertainty
# values of the specified data item as defined in a DDLm dictionary.
#
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @param $data_name
#       Name of the measured data item.
# @param $su_data_name
#       Name of the s.u. data item.
# @return
#       '1' if the data item is eligible, '0' otherwise.
##
sub is_su_pair
{
    my ( $dic, $data_name, $su_data_name ) = @_;

    return 0 if !exists $dic->{'Item'}{ lc $su_data_name };
    my $su_item = $dic->{'Item'}{ lc $su_data_name };

    return 0 if get_type_purpose( $su_item ) ne 'su';

    return 0 if !exists $su_item->{'values'}{'_name.linked_item_id'};
    my $linked_data_name = lc $su_item->{'values'}{'_name.linked_item_id'}[0];

    return 0 if !exists $dic->{'Item'}{$linked_data_name};

    my $linked_data_item = $dic->{'Item'}{$linked_data_name};
    my @linked_item_names = @{ get_all_unique_data_names( $linked_data_item ) };
    if ( any { uc $data_name eq uc $_ } @linked_item_names ) {
        return 1;
    }

    return 0;
}

##
# Returns the names of data items that are intended to store the standard
# uncertainty (s.u.) values of the given data item as defined in a DDLm
# dictionary.
#
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @param $data_name
#       Name of the data item for which the s.u. values apply.
# @return
#       Reference to an array of data names.
##
sub get_su_data_names
{
    my ( $dic, $data_name ) = @_;

    return [] if !exists $dic->{'Item'}{$data_name};

    my @su_data_names = grep { is_su_pair( $dic, $data_name, $_ ) }
                                                   keys %{$dic->{'Item'}};

    return \@su_data_names;
}

##
# Returns the names of s.u. data items that are present in the given data
# frame. A DDLm dictionary is consulted to determine which data items store
# the s.u. values.
#
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @param $data_frame
#       Data frame as returned by the COD::CIF::Parser.
# @param $data_name
#       Name of the data item for which the s.u. values apply.
# @return
#       Reference to an array of data names.
##
sub get_su_data_names_in_frame
{
    my ( $dic, $data_frame, $data_name ) = @_;

    my $su_names_in_dic = get_su_data_names( $dic, $data_name );

    my @su_data_names = grep { exists $data_frame->{'values'}{$_} }
                                                        @{$su_names_in_dic};

    return \@su_data_names;
}

##
# Extracts the standard uncertainty (s.u.) values expressed using the
# concise parenthetic notation from all values of the given data item.
#
# @param $frame
#       Data frame that contains the data item as returned by the COD::CIF::Parser.
# @param $data_name
#       Name of the data item.
# @return $su_values
#       Array reference to a list of extracted s.u. values. For more
#       information about the potential return values consult the
#       extract_su_from_data_value() subroutine.
##
sub get_su_from_data_values
{
    my ( $data_frame, $data_name ) = @_;

    my @su_values;
    for (my $i = 0; $i < @{$data_frame->{'values'}{$data_name}}; $i++) {
        push @su_values,
             extract_su_from_data_value($data_frame, $data_name, $i );
    }

    return \@su_values;
}

##
# Extracts the standard uncertainty (s.u.) value expressed using the
# parenthetic notation. One of the four types of s.u. values might be
# returned based on the data value:
#   - numeric value (e.g. 0.01) for numeric data values with s.u. values
#     (e.g. 1.23(1));
#   - undef value for numeric values with no s.u. values (e.g. 1.23);
#   - 'spec' string for special CIF values (unquoted '?' or '.' symbols);
#   - 'text' string for non-numeric values (e.g. 'text').
#
# Note, that according to the working specification of CIF 1.1 quoted numeric
# values (e.g. '1.23') should be treated as non-numeric values.
#
# @param $frame
#       Data frame that contains the data item as returned by the COD::CIF::Parser.
# @param $data_name
#       Name of the data item.
# @param $index
#       The index of the data item value.
# @return $su_value
#       The extracted s.u. value in the specified notation.
##
sub extract_su_from_data_value
{
    my ( $data_frame, $data_name, $index ) = @_;

    my $su_value = generate_value_descriptor( $data_frame, $data_name, $index );
    if ( $su_value eq 'numb' ) {
        my ($number, $su) =
                unpack_cif_number( $data_frame->{'values'}{$data_name}[$index] );
        $su_value = $su;
    }

    return $su_value;
}

##
# Extracts the standard uncertainty (s.u.) values recorded in a separate
# data item. One of the three types of s.u. values might be returned based
# on the data value:
#   - numeric value (e.g. 0.01) for numeric data values;
#   - 'spec' string for special CIF values (unquoted '?' or '.' symbols);
#   - 'text' string for non-numeric values (e.g. 'text').
#
# Note, that according to the working specification of CIF 1.1 quoted numeric
# values (e.g. '1.23') should be treated as non-numeric values.
#
# concise parenthetic notation from all values of the given data item.
#
# @param $frame
#       Data frame that contains the data item as returned by the COD::CIF::Parser.
# @param $data_name
#       Name of the data item.
# @return $su_values
#       Array reference to a list of extracted s.u. values.
##
sub get_su_from_separate_item
{
    my ( $dic, $data_frame, $data_name ) = @_;

    my $su_names = get_su_data_names_in_frame( $dic, $data_frame, $data_name );
    return if !@{$su_names};

    $su_names = [ sort { $a cmp $b } @{$su_names} ] ;
    my $su_name = $su_names->[0];

    my @su_values;
    for ( my $i = 0; $i < @{$data_frame->{'values'}{$su_name}}; $i++ ) {
        my $su_value = generate_value_descriptor( $data_frame, $su_name, $i );
        if ( $su_value eq 'numb' ) {
            $su_value = $data_frame->{'values'}{$su_name}[$i];
        }
        push @su_values, $su_value;
    }

    return \@su_values;
}

##
# Returns a descriptor of a data value. One of the following strings will
# be returned:
#   - 'numb' in case the value is numeric;
#   - 'spec' in case of special CIF values (unquoted '?' or '.' symbols);
#   - 'text' in case of non-numeric values (e.g. 'text').
#
# Note, that according to the working specification of CIF 1.1 quoted numeric
# values (e.g. '1.23') should be treated as non-numeric values.
#
# @param $data_frame
#       Data frame that contains the data item as returned by the COD::CIF::Parser.
# @param $data_name
#       Name of the numeric data item.
# @param $index
#       Index of the data item value.
# @return $descriptor
#       Value descriptor string.
##
sub generate_value_descriptor
{
    my ( $data_frame, $data_name, $index ) = @_;

    my $descriptor = 'text';
    if ( has_special_value( $data_frame, $data_name, $index ) ) {
        $descriptor = 'spec';
    } elsif ( has_numeric_value( $data_frame, $data_name, $index ) ) {
        $descriptor = 'numb';
    }

    return $descriptor;
}

##
# Evaluates if a standard uncertainty value is a numeric one.
# This subroutine handles standard uncertainty values returned
# by the get_su_from_data_values() and get_su_from_separate_item().
#
# @param $su_value
#       The standard uncertainty value.
# @return
#       '1' is the value is numeric, '0' otherwise.
##
sub is_numeric_su_value
{
    my ( $su_value ) = @_;

    return 0 if !defined $su_value;
    return 0 if $su_value eq 'text';
    return 0 if $su_value eq 'spec';

    return 1;
}

##
# Checks the relationship constraints between linked data items. Missing
# linked data items as well as values unique to the foreign key are
# reported.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub validate_linked_items
{
    my ($data_frame, $dic) = @_;

    my @issues;
    for my $tag ( @{$data_frame->{'tags'}} ) {
        next if !exists $dic->{'Item'}{$tag};

        my $dic_item = $dic->{'Item'}{$tag};
        next if !exists $dic_item->{'values'}{'_name.linked_item_id'};

        my @linked_item_names = ( lc $dic_item->{'values'}{'_name.linked_item_id'}[0] );
        # Check if the linking data item stores the su values
        my $is_su = ( get_type_purpose( $dic_item ) eq 'su' );
        # Retrieve the aliases of the linked data item
        if ( exists $dic->{'Item'}{$linked_item_names[0]} ) {
            push @linked_item_names, map { lc }
                 @{ get_data_alias( $dic->{'Item'}{$linked_item_names[0]} ) };
        } else {
            warn 'missing data item definition in the DDLm dictionary -- ' .
                 "the '$tag' data item is defined as being linked to the " .
                 "'$linked_item_names[0]' data item, however, the definition " .
                 'of the linked data item is not provided' . "\n";
        }

        # filtering out special CIF values ('?' and '.')
        my @data_item_values;
        for ( my $i = 0; $i < @{$data_frame->{'values'}{$tag}}; $i++ ) {
          if ( !has_special_value( $data_frame, $tag, $i ) ) {
              push @data_item_values,
                   $data_frame->{'values'}{$tag}[$i];
          }
        };

        my $linked_item_found = 0;
        for my $linked_item_name (@linked_item_names) {
          if ( exists $data_frame->{'values'}{$linked_item_name} ) {
            $linked_item_found = 1;
            # SU are not required to match the linked data item values
            next if $is_su;
            my %candidate_key_values = map { $_ => 1 }
                  @{$data_frame->{'values'}{$linked_item_name}};
            my @unmatched = uniq sort grep { !exists $candidate_key_values{$_} }
                  @data_item_values;
            push @issues, map {
                    {
                       'test_type'  => 'PRESENCE_OF_LINKED_DATA_ITEM_VALUE',
                       'data_items' => [ $tag ],
                       'message'    =>
                            'data item \'' . ( canonicalise_tag($tag) ) .
                            "\' contains value '$_' that was not found " .
                            'among the values of the linked data item ' .
                            q{'} . ( canonicalise_tag($linked_item_name) ) . q{'}
                    }
                 } @unmatched;
            last;
          }
        }

        if (!$linked_item_found) {
          push @issues,
               {
                   'test_type'  => 'PRESENCE_OF_LINKED_DATA_ITEM',
                   'data_items' => [ $tag ],
                   'message'    =>
                        'missing linked data item -- the \'' .
                        ( canonicalise_tag($linked_item_names[0]) ) .
                        '\' data item is required by the \'' .
                        ( canonicalise_tag($tag) ) . '\' data item'
               }
        }
    }

    return \@issues;
}

##
# Checks the content type against the DDLm dictionary file.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub validate_type_contents
{
    my ($data_frame, $dic) = @_;

    my @issues;
    for my $tag ( @{$data_frame->{'tags'}} ) {
        next if !exists $dic->{'Item'}{$tag};

        my $type_contents = lc get_type_contents( $tag, $data_frame, $dic );
        my $parsed_type = parse_content_type( $type_contents );
        my @single_item_issues;
        for (my $i = 0; $i < @{$data_frame->{'values'}{$tag}}; $i++) {
            my $value = $data_frame->{'values'}{$tag}[$i];
            push @single_item_issues, @{check_complex_content_type(
                                            $value,
                                            $parsed_type,
                                            $data_frame->{'types'}{$tag}[$i],
                                            ''
                                        )};
        }

        # update the issue message and register data item names
        for my $issue (@single_item_issues) {
            $issue->{'message'} = 'data item \'' . ( canonicalise_tag($tag) ) .
                                  '\' ' . $issue->{'message'};
            $issue->{'data_items'} = [ $tag ];
            push @issues, $issue;
        }
    }

    return \@issues;
}

##
# Parses the given content type string.
# @param $data_frame
#       The content type string.
# @return
#       Reference to a data structure representing the parsed string.
##
sub parse_content_type
{
    my ( $content_type ) = @_;

    # FIXME: currently the content type string parsing is as primitive
    # as it gets and does not take into account the possibility of
    # deeper nested structure, etc. However, it does cover most
    # (if not all) of the provided use cases
    my $type_list  = $content_type;
    my $struct_key = 'types';
    if ( $content_type =~ m/^list[(](.*)[)]$/ ) {
        $type_list  = $1;
        $struct_key = 'list';
    } elsif ( $content_type =~ m/^matrix[(](.*)[)]$/ ) {
        $type_list  = $1;
        $struct_key = 'matrix';
    }

    my %parsed_type;
    $parsed_type{$struct_key} = [ split /,/, $type_list ];

    return \%parsed_type;
}

sub stringify_nested_value
{
    my ( $value, $structure_path ) = @_;

    my $value_string = 'value';
    if ( ref $value eq  '' ) {
        $value_string .= " '$value'";
    }
    if ( $structure_path ne '' ) {
        $value_string .= ' located at the data structure position ' .
                         "'$structure_path'" ;
    }

    return $value_string;
}

##
# Checks a structured value against the DDLm data type constraints.
# This is a top-level highly recursive subroutine that is mainly responsible
# for unpacking complex data structures and passing the unpacked values to
# low-level validation subroutines.
#
# @param $value
#       Data value to be validated.
# @param $type_in_dic
#       Data type of the value as specified in the validating DDLm dictionary.
# @param $type_in_parser
#       Data type of the value as assigned by the COD::CIF::Parser.
#       Used mainly to determine if the value in the original files
#       was surrounded by quotes.
# @param $struct_path
#       String that contains the structure path to the value in a human-readable
#       form, e.g. '[7]{"key_1"}{"key_2"}[2]'.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_complex_content_type
{
    my ($value, $type_in_dic, $type_in_parser, $struct_path) = @_;

    return [] if is_cif_special_value( $value, $type_in_parser );

    my @validation_issues;
    if ( ref $type_in_dic eq 'HASH' ) {
        if ( exists $type_in_dic->{'types'} ) {
            push @validation_issues,
                 @{ check_complex_content_type( $value,
                                      $type_in_dic->{'types'},
                                      $type_in_parser,
                                      $struct_path ) };
        }

        if ( exists $type_in_dic->{'list'} ) {
            if ( ref $value ne 'ARRAY' ) {
                push @validation_issues,
                     {
                        'test_type' => 'CONTENT_TYPE.MANDATORY_LIST_STRUCTURE',
                        'message'   =>
                            (stringify_nested_value( $value, $struct_path )) .
                            ' violates content type constraints ' .
                            '-- the value should be placed inside a list'
                     };
                return \@validation_issues;
            }

            # process each value
            for (my $i = 0; $i < @{$value}; $i++ ) {
                push @validation_issues,
                     @{ check_complex_content_type( $value->[$i],
                                          $type_in_dic->{'list'},
                                          $type_in_parser->[$i],
                                          $struct_path . "[$i]") };
            }
        }
    } elsif ( ref $type_in_dic eq 'ARRAY' ) {
        # More than a single data type indicates
        # an implicit list, e.g. real,int,int
        my $types = $type_in_dic;
        if ( @{$types} > 1 ) {
            if ( ref $value ne 'ARRAY' ) {
                push @validation_issues,
                     {
                        'test_type' => 'CONTENT_TYPE.MANDATORY_LIST_STRUCTURE',
                        'message'   =>
                            (stringify_nested_value( $value, $struct_path )) .
                            ' violates content type constraints ' .
                            '-- the value should be placed inside a list'
                     };
                return \@validation_issues;
            }

            if ( @{$types} ne @{$value} ) {
                push @validation_issues,
                     {
                        'test_type' => 'CONTENT_TYPE.LIST_SIZE_CONSTRAINT',
                        'message'   =>
                            (stringify_nested_value( $value, $struct_path )) .
                            ' violates content type constraints -- ' .
                            'the value list contains an incorrect number ' .
                            'of elements (' . (scalar @{$value}) .
                            ' instead of ' . (scalar @{$types}) . ')'
                     };
                return \@validation_issues;
            }

            for (my $i = 0; $i < @{$types}; $i++ ) {
                push @validation_issues,
                     @{ check_complex_content_type( $value->[$i], $types->[$i],
                                          $type_in_parser->[$i],
                                          $struct_path . "[$i]" ) };
            }
        } else {
            push @validation_issues,
                 @{ check_complex_content_type( $value, $types->[0],
                                      $type_in_parser, $struct_path ) };
        }
    } else {
        push @validation_issues,
             @{ check_content_type( $value, $type_in_dic,
                                    $type_in_parser, $struct_path ) };
    }

    return \@validation_issues;
}

##
# Checks a structured value against the DDLm data type constraints.
#
# This is a helper subroutine that should not be called directly.
# The check_complex_content_type subroutine should be used instead.
#
# @param $value
#       Data value to be validated.
# @param $type_in_dic
#       Data type of the value as specified in the validating DDLm dictionary.
# @param $type_in_parser
#       Data type of the value as assigned by the COD::CIF::Parser.
#       Used mainly to determine if the value in the original files
#       was surrounded by quotes.
# @param $struct_path
#       String that contains the structure path to the value in a human-readable
#       form, e.g. '[7]{"key_1"}{"key_2"}[2]'.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_content_type
{
    my ( $value, $type_in_dic, $type_in_parser, $struct_path ) = @_;

    my @validation_issues;
    if ( ref $value eq '' ) {
        # skip special CIF values '?', '.'
        if ( ( $value eq '?' || $value eq '.' ) &&
             $type_in_parser eq 'UQSTRING' ) {
            return \@validation_issues;
        };

        push @validation_issues,
                @{ check_primitive_data_type( $value, $type_in_dic ) };

        if ( !@validation_issues &&
             ( uc $type_in_dic eq 'COUNT'   ||
               uc $type_in_dic eq 'INDEX'   ||
               uc $type_in_dic eq 'INTEGER' ||
               uc $type_in_dic eq 'REAL' ) &&
             $type_in_parser ne 'FLOAT' &&
             $type_in_parser ne 'INT' ) {
            push @validation_issues,
                 {
                    'test_type'  => 'TYPE_CONSTRAINT.QUOTED_NUMERIC_VALUES',
                    'message'    =>
                        'numeric values should be written without the use ' .
                        'of quotes or multiline value designators'
                 }
        }

        my $value_with_full_path = stringify_nested_value( $value, $struct_path );
        for my $issue (@validation_issues) {
            $issue->{'message'} =
                    $value_with_full_path . ' violates content type ' .
                    'constraints -- ' . $issue->{'message'}
        }
    } elsif ( ref $value eq 'ARRAY' ) {
        for (my $i = 0; $i < @{$value}; $i++ ) {
            push @validation_issues,
                 @{ check_complex_content_type( $value->[$i], $type_in_dic,
                                      $type_in_parser->[$i],
                                      $struct_path ."[$i]" ) };
        }
    } elsif ( ref $value eq 'HASH' ) {
        for my $key ( keys %{$value} ) {
            push @validation_issues,
                 @{ check_complex_content_type( $value->{$key}, $type_in_dic,
                                      $type_in_parser->{$key},
                                      $struct_path . "{\"$key\"}" ) };
        }
    } else {
       warn 'Handling of the \'', ref $value, '\' Perl reference in ' .
            'data type validation is not yet implemented';
    }

    return \@validation_issues;
}

##
# Checks the value against the DDLm data type constraints.
#
# The validation rules for imaginary and complex and types were based on
# [1,2].
#
# @source [1]
#       "Draft specifications of the dictionary relational expression
#        language dREL",
#        https://www.iucr.org/__data/assets/pdf_file/0007/16378/dREL_spec_aug08.pdf
# @source [2]
#        Draft version of the "Construction and interpretation of
#        CIF dictionaries" chapter, Table 3 from the upcoming release
#        of the International Tables for Crystallography, Volume G.
#
# TODO: update reference [2] once it is properly released.
#
# @param $value
#       The data value that is being validated.
# @param $type
#       The declared data type of the value.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_primitive_data_type
{
    my ($value, $type) = @_;

    # CIF2 characters according to the EBNF grammar:
    # https://www.iucr.org/__data/assets/text_file/0009/112131/CIF2-ENBF.txt
    #
    # U+0009, U+000A, U+000D, U+0020-U+007E, U+00A0-U+D7FF, U+E000-U+FDCF,
    # U+FDF0-U+FFFD, U+10000-U+1FFFD, U+20000-U+2FFFD, U+30000-U+3FFFD,
    # U+40000-U+4FFFD, U+50000-U+5FFFD, U+60000-U+6FFFD, U+70000-U+7FFFD,
    # U+80000-U+8FFFD, U+90000-U+9FFFD, U+A0000-U+AFFFD, U+B0000-U+BFFFD,
    # U+C0000-U+CFFFD, U+D0000-U+DFFFD, U+E0000-U+EFFFD, U+F0000-U+FFFFD,
    # U+100000-U+10FFFD
    my $cif2_ws_character = '\x{0009}' . '\x{000A}' . '\x{000D}' . '\x{0020}';
    my $cif2_nws_character = '\x{0021}-\x{007E}' . '\x{00A0}-\x{D7FF}' .
     '\x{E000}-\x{FDCF}' . '\x{FDF0}-\x{FFFD}' . '\x{10000}-\x{1FFFD}' .
     '\x{20000}-\x{2FFFD}' . '\x{30000}-\x{3FFFD}' . '\x{40000}-\x{4FFFD}' .
     '\x{50000}-\x{5FFFD}' . '\x{60000}-\x{6FFFD}' . '\x{70000}-\x{7FFFD}' .
     '\x{80000}-\x{8FFFD}' . '\x{90000}-\x{9FFFD}' . '\x{A0000}-\x{AFFFD}' .
     '\x{B0000}-\x{BFFFD}' . '\x{C0000}-\x{CFFFD}' . '\x{D0000}-\x{DFFFD}' .
     '\x{E0000}-\x{EFFFD}' . '\x{F0000}-\x{FFFFD}' . '\x{100000}-\x{10FFFD}';

    my $u_int   = '[0-9]+';
    my $int     = "[+-]?${u_int}";
    my $exp     = "[eE][+-]?${u_int}";
    my $u_float = "(?:${u_int}${exp})|(?:[0-9]*[.]${u_int}|${u_int}+[.])(?:$exp)?";
    my $float   = "[+-]?(?:${u_float})";
    my $su      = "[(]${u_int}[)]";

    my $cif2_character = $cif2_ws_character . $cif2_nws_character;

    my @validation_issues;

    $type = lc $type;
    if ( $type eq 'text' ) {
        # case-sensitive sequence of CIF2 characters
        if ( $value =~ m/([^$cif2_character])/ ) {
            push @validation_issues,
                 {
                    'test_type' => 'TYPE_CONSTRAINT.TEXT_TYPE_FORBIDDEN_CHARACTER',
                    'message'   =>
                        "the '$1' symbol does not belong to the permitted symbol set"
                 }
        }
    } elsif ( $type eq 'code' ) {
        # case-insensitive sequence of CIF2 characters containing
        # no ASCII whitespace
        if ( $value =~ m/([^$cif2_nws_character])/ ) {
            push @validation_issues,
                 {
                    'test_type' => 'TYPE_CONSTRAINT.CODE_TYPE_FORBIDDEN_CHARACTER',
                    'message'   =>
                        "the '$1' symbol does not belong to the permitted symbol set"
                 }
        }
    } elsif ( $type eq 'word' ) {
        # case-sensitive sequence of CIF2 characters containing
        # no ASCII whitespace
        if ( $value =~ m/([^$cif2_nws_character])/ ) {
            push @validation_issues,
                 {
                    'test_type' => 'TYPE_CONSTRAINT.WORD_TYPE_FORBIDDEN_CHARACTER',
                    'message'   =>
                        "the '$1' symbol does not belong to the permitted symbol set"
                 }
        }
    } elsif ( $type eq 'name' ) {
        # case-insensitive sequence of ASCII alpha-numeric characters
        # or underscore
        if ( $value =~ m/([^_A-Za-z0-9])/ ) {
            push @validation_issues,
                 {
                    'test_type' => 'TYPE_CONSTRAINT.NAME_TYPE_FORBIDDEN_CHARACTER',
                    'message'   =>
                        "the '$1' symbol does not belong to the permitted symbol set"
                 }
        }
    } elsif ( $type eq 'tag' ) {
        # case-insensitive CIF2 character sequence with leading
        # underscore and no ASCII whitespace
        if ( $value !~ m/^_/ ) {
            push @validation_issues,
                 {
                    'test_type' => 'TYPE_CONSTRAINT.TAG_TYPE_START_CHARACTER',
                    'message'   =>
                        'the value must start with an underscore (\'_\') symbol'
                 }
        }
        if ( $value =~ m/([^$cif2_nws_character])/ ) {
            push @validation_issues,
                 {
                    'test_type' => 'TYPE_CONSTRAINT.TAG_TYPE_FORBIDDEN_CHARACTER',
                    'message'   =>
                        "the '$1' symbol does not belong to the permitted symbol set"
                 }
        }
    } elsif ( $type eq 'uri' ) {
        # A Uniform Resource Identifier per RFC 3986
        # TODO: implement proper URI parsing as per RFC 3986
        my ($scheme, $auth, $path, $query, $frag) = uri_split($value);
        if (defined $scheme) {
            if ( $scheme =~ /^[^A-Za-z]/ ) {
                push @validation_issues,
                {
                    'test_type' => 'TYPE_CONSTRAINT.URI_TYPE_START_CHARACTER',
                    'message'   =>
                        "the URI scheme component '$scheme' " .
                        'must start with an ASCII letter ([A-Za-z])'
                }
            }
            if ( $scheme =~ /([^A-Za-z0-9.+-])/ ) {
                push @validation_issues,
                {
                    'test_type' => 'TYPE_CONSTRAINT.URI_TYPE_FORBIDDEN_CHARACTER',
                    'message'   =>
                        "the '$1' symbol is not allowed " .
                        "in the URI scheme component '$scheme'"
                }
            }
        } else {
                push @validation_issues,
                {
                    'test_type' => 'TYPE_CONSTRAINT.URI_TYPE_SCHEME_PREFIX',
                    'message'   =>
                        'an URI string must start with a scheme component'
                }
        }
    } elsif ( $type eq 'date' ) {
        # ISO standard date format <yyyy>-<mm>-<dd>.
        # Use DateTime for all new dictionaries
        eval {
            parse_date($value);
        };
        if ( $@ ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.DATE_TYPE_FORMAT',
                'message'   =>
                        'the value should conform to the ISO standard date '.
                        'format <yyyy>-<mm>-<dd>'
            }
        }
    } elsif ( $type eq 'datetime' ) {
        # A timestamp. Text formats must use date-time or
        # full-date productions of RFC3339 ABNF
        eval {
            parse_datetime($value);
        };
        if ( $@ ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.DATETIME_TYPE_FORMAT',
                'message'   =>
                        'the value should be a date-time or full-date ' .
                        'production of RFC3339 ABNF'
            }
        }
    } elsif ( $type eq 'version' ) {
        # Version number string that adheres to the formal grammar provided in
        # the Semantic Versioning specification version 2.0.0. Version strings
        # must take the general form of <major>.<minor>.<patch> and may also
        # contain an optional postfix with additional information such as the
        # pre-release identifier.
        #
        # Reference: https://semver.org/spec/v2.0.0.html
        if ( !defined parse_version_string($value) ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.VERSION_TYPE_FORMAT',
                'message'   =>
                        'the value should be a SemVer 2.0.0 string of ' .
                        'the form <major>.<version>.<update> followed by ' .
                        'optional pre-release or build metadata labels, e.g. ' .
                        '\'1.234.56\', \'4.7.8-dev.3.d\', \'0.0.1+build.7\'',
            }
        }
    } elsif ( $type eq 'dimension' ) {
        # integer limits of an Array/Matrix/List in square brackets
        if ( $value !~ m/^[[](?:$u_int(?:,$u_int)*)?[]]$/ ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.DIMENSION_TYPE_FORMAT',
                'message'   =>
                        'the value should consists of zero or more natural ' .
                        'numbers separated by commas written in between ' .
                        'square brackets, e.g. \'[4,4]\''
            }
        }
    } elsif ( $type eq 'range' ) {
        # inclusive range of numerical values min:max
        my $range = parse_range($value);
        my $lower = $range->[0];
        my $upper = $range->[1];
        if ( ( !defined $lower || $lower !~ /^$int|$float$/ ) &&
             ( !defined $upper || $upper !~ /^$int|$float$/ ) ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.RANGE_TYPE_FORMAT',
                'message'   =>
                        'the value should be a range of numerical values of ' .
                        'the form \'min:max\''
            }
        } elsif ( defined $lower && defined $upper ) {
            if ( $lower > $upper ) {
                push @validation_issues,
                {
                    'test_type' => 'TYPE_CONSTRAINT.RANGE_TYPE_LOWER_GT_UPPER',
                    'message'   =>
                            "the lower range value '$lower' is greater than " .
                            "the upper range value '$upper'"
                }
            }
        }
    } elsif ( $type eq 'count' ) {
        # NOTE: this data type is considered deprecated
        #       and might be removed in the future
        # unsigned integer number
        $value =~ s/${su}$//;
        if ( $value !~ m/^[0-9]+$/ ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.COUNT_TYPE_CONSTRAINT',
                'message'   =>
                        'the value should be an unsigned integer'
            }
        }
    } elsif ( $type eq 'index' ) {
        # NOTE: this data type is considered deprecated
        #       and might be removed in the future
        # unsigned non-zero integer
        $value =~ s/${su}$//;
        if ( $value !~ m/^[0-9]+$/ || $value <= 0 ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.INDEX_TYPE_CONSTRAINT',
                'message'   =>
                        'the value should be an unsigned non-zero integer'
            }
        }
    } elsif ( $type eq 'integer' ) {
        # positive or negative integer
        $value =~ s/${su}$//;
        if ( $value !~ m/^[-+]?[0-9]+$/ ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.INTEGER_TYPE_CONSTRAINT',
                'message'   =>
                        'the value should be an integer'
            }
        }
    } elsif ( $type eq 'real' ) {
        # floating-point real number
        $value =~ s/${su}$//;
        if ( $value !~ m/^(?:${int}|${float})$/ ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.REAL_TYPE_CONSTRAINT',
                'message'   =>
                        'the value should be a floating-point real number'
            }
        }
    } elsif ( $type eq 'imag' ) {
        # floating-point imaginary number
        if ( $value !~ m/^(?:${int}|${float})(?:${su})?[jJ]$/ ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.IMAG_TYPE_FORMAT',
                'message'   =>
                        'the value should be a floating-point imaginary ' .
                        'number expressed as a real number with the imaginary ' .
                        'unit suffix \'j\', e.g. \'-42j\', \'12.3j\', ' .
                        '\'6.14(2)j\''
            }
        }
    } elsif ( $type eq 'complex' ) {
        # complex number <R>+<I>j
        if ( $value !~ m/^(?:$int|${float})(?:${su})?[ ]?[+-][ ]?(?:${u_int}|${u_float})(?:${su})?[jJ]$/ ) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.COMPLEX_TYPE_FORMAT',
                'message'   =>
                        'the value should be a complex number consisting ' .
                        'of a real part expressed as a real number and the ' .
                        'imaginary part expressed as a real number with the ' .
                        'imaginary unit suffix \'j\', e.g. \'-3.14+42j\', ' .
                        '\'42 + 3.14(8)j\', \'4.2(1)-62.8(1)j\''
            }
        }
    } elsif ( $type eq 'symop' ) {
        if ( $value !~ /^[1-9][0-9]*(?:[_ ][0-9]{3,})?$/) {
            push @validation_issues,
            {
                'test_type' => 'TYPE_CONSTRAINT.SYMOP_TYPE_FORMAT',
                'message'   =>
                        'the value should be a string composed of a positive ' .
                        'integer optionally followed by an underscore or ' .
                        'space and three or more digits'
            }
        }
    } elsif ( $type eq 'implied' ) {
        # implied by the context of the attribute
        warn 'the interpretation of the \'Implied\' data type depends on ' .
             'the context of that the data item appears in -- ' .
             'it should be resolved prior to passing it to the ' .
             '\'check_primitive_data_type\' subroutine' . "\n";
    } elsif ( $type eq 'byreference' ) {
        # The contents have the same form as those of the attribute
        # referenced by _type.contents_referenced_id
        warn 'the interpretation of the \'byReference\' data type depends on ' .
             'the dictionary definitions of the referenced data item -- ' .
             'it should be resolved prior to passing it to the ' .
             '\'check_primitive_data_type\' subroutine' . "\n";
    } else {
        warn "content type '$type' is not recognised\n";
    }

    return \@validation_issues;
}

##
# Checks the container types and dimensions against the DDLm dictionary file.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub validate_type_container
{
    my ($data_frame, $dic) = @_;

    my @issues;

    for my $tag ( @{$data_frame->{'tags'}} ) {
        next if ( !exists $dic->{'Item'}{$tag} );

        my $type_container = lc get_type_container( $dic->{'Item'}{$tag} );
        my $perl_ref_type;
        if ( $type_container eq 'single' ) {
            $perl_ref_type = '';
        } elsif ( $type_container eq 'list' ) {
            $perl_ref_type = 'ARRAY';
        } elsif ( $type_container eq 'table' ) {
            $perl_ref_type = 'HASH';
        } elsif ( $type_container eq 'array' ) {
            $perl_ref_type = 'ARRAY';
        } elsif ( $type_container eq 'matrix') {
            $perl_ref_type = 'ARRAY OF ARRAYS';
        } elsif ( $type_container eq 'multiple' ) {
            # TODO: implement Multiple type check
            next;
        } else {
            next;
        }

        my $type_dimension = get_type_dimension( $dic->{'Item'}{$tag} );
        my $dimensions;
        # Matrices with a single dimension are interpreted as vectors
        # as specified in the definition of the _type.dimension data item
        # in the DDLm reference dictionary
        if ( defined $type_dimension ) {
            $dimensions = parse_dimension( $type_dimension );
            if ( $type_container eq 'matrix' &&
                  defined $dimensions->[0] &&
                 !defined $dimensions->[1] ) {
                $perl_ref_type = 'ARRAY';
            }
        }

        my $report_position = ( @{$data_frame->{'values'}{$tag}} > 1 );
        for ( my $i = 0; $i < @{$data_frame->{'values'}{$tag}}; $i++ ) {
            my $value = $data_frame->{'values'}{$tag}[$i];
            my $type = $data_frame->{'types'}{$tag}[$i];

            next if has_special_value( $data_frame, $tag, $i );

            my $placeholder_value = $value;
            $placeholder_value = '[ ... ]' if ref $value eq 'ARRAY';
            $placeholder_value = '{ ... }' if ref $value eq 'HASH';
            my $message = 'data item \'' . ( canonicalise_tag($tag) ) .
                          "' value '$placeholder_value' ";
            if ( $report_position ) {
                $message .= 'with the loop index \'' . ($i+1) . '\' ';
            }

            if ( $perl_ref_type eq 'ARRAY OF ARRAYS' ) {
                if ( !is_valid_ddlm_matrix( $value, $type ) ) {
                    $message .=
                        'must have a top level matrix container ' .
                        '(i.e. [ [ v1_1 v1_2 ... ] [ v2_1 v2_2 ... ] ... ])';
                    push @issues,
                         {
                            'test_type'  => 'TYPE_CONTAINER.TOP_LEVEL_LIST_SIZE',
                            'data_items' => [ $tag ],
                            'message'    => $message
                         }
                } else {
                    my $single_item_issues =
                        check_matrix_dimensions( $value, $type, $dimensions );
                    for my $issue ( @{$single_item_issues} ) {
                        $issue->{'message'} = $message . $issue->{'message'};
                        $issue->{'data_items'} = [ $tag ];
                        push @issues, $issue;
                    }
                }
                next;
            }

            if ( $perl_ref_type eq 'ARRAY' ) {
                if ( $perl_ref_type ne ref $value ) {
                    $message .= 'must have a top level list container ' .
                                '(i.e. [v1 v2 ...])';
                    push @issues,
                         {
                            'test_type'  => 'TYPE_CONTAINER.TOP_LEVEL_LIST',
                            'data_items' => [ $tag ],
                            'message'    => $message
                         }
                } else {
                    # Check list dimensions
                    next if !defined $dimensions;
                    next if !defined $dimensions->[0];
                    if ( scalar @{$value} ne $dimensions->[0] ) {
                        $message .=
                            'does not contain the required number of ' .
                            'list elements (' . ( scalar @{$value} ) .
                            " instead of $dimensions->[0])";
                        push @issues,
                             {
                                'test_type' => 'TYPE_CONTAINER.MATRIX_ROW_COUNT',
                                'message'   => $message
                             }
                    }
                }
                next;
            }

            if ( $perl_ref_type ne ref $value ) {
                if ( $perl_ref_type eq 'HASH' ) {
                    $message .= 'must have a top level table container ' .
                                '(i.e. {\'k1\':v1 \'k2\':v2 ...})';
                    push @issues,
                         {
                            'test_type'  => 'TYPE_CONTAINER.TOP_LEVEL_TABLE',
                            'data_items' => [ $tag ],
                            'message'    => $message
                         }
                } else {
                    $message .= 'must not have a top level container';
                    push @issues,
                         {
                            'test_type'  => 'TYPE_CONTAINER.NO_TOP_LEVEL',
                            'data_items' => [ $tag ],
                            'message'    => $message
                         }
                }
            }
        }
    }

    return \@issues;
}

##
# Evaluates if a given data structure is a valid DDLm matrix.
# The subroutine takes into account the fact that some of the matrix
# rows may be replaced with CIF special values ('.', '?').
#
# @param $matrix_values
#       Reference to a data structure that contains the parsed values
#       as returned by the COD::CIF::Parser.
# @param $matrix_types
#       Reference to a data structure that contains the types of
#       the parsed values as returned by the COD::CIF::Parser.
# @return
#       '1' if the data structure is a valid DDLm matrix,
#       '0' otherwise.
##
sub is_valid_ddlm_matrix
{
    my ( $matrix_values, $matrix_types ) = @_;

    # Check if the entire data structure is a CIF special value
    if (ref $matrix_types eq '') {
        return is_cif_special_value( $matrix_values, $matrix_types );
    }

    return 0 if ref $matrix_values ne 'ARRAY';
    return 0 if !@{$matrix_values};

    for ( my $i = 0; $i < @{$matrix_types}; $i++ ) {
        if ( ref $matrix_types->[$i] eq '' ) {
            return 0 if !is_cif_special_value( $matrix_values->[$i],
                                               $matrix_types->[$i] );
        } else {
            return 0 if ( ref $matrix_types->[$i] ne 'ARRAY' );
        }
    }

    return 1;
}

# TODO: see if it would be worthwhile moving the 'is_cif_special_value'
# subroutine into a different module.
##
# Evaluates if a given a value is a CIF special value (unknown or inapplicable).
#
# @param $value
#       Value to be evaluated.
# @param $type
#       Data type of the value as returned by the COD::CIF::Parser.
# @return
#       '1' if the value is a CIF special value,
#       '0' otherwise.
##
sub is_cif_special_value
{
    my ( $value, $type ) = @_;

    return 0 if $type ne 'UQSTRING';
    return 0 if $value ne '?' && $value ne '.';

    return 1;
}

##
# Checks if a matrix data structure is of proper dimensions.
#
# @param $matrix_values
#       Reference to a data structure that contains the matrix values
#       as returned by the COD::CIF::Parser.
# @param $matrix_types
#       Reference to a data structure that contains the types of
#       the matrix values as returned by the COD::CIF::Parser.
# @param $dimensions
#       Reference to a parsed dimension string as returned
#       by the parse_dimension() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#           # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#           # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_matrix_dimensions
{
    my ( $matrix_values, $matrix_types, $dimensions ) = @_;

    my $target_row_count = $dimensions->[0];
    my $target_col_count = $dimensions->[1];

    my @issues;
    my $row_count = scalar @{$matrix_values};
    if ( defined $target_row_count ) {
        if ( $target_row_count ne $row_count ) {
            push @issues,
                 {
                    'test_type' => 'TYPE_CONTAINER.MATRIX_ROW_COUNT',
                    'message'   =>
                        'does not contain the required number of ' .
                        "matrix rows ($row_count instead of $target_row_count)"
                 }
        }
    }
    return \@issues if !$row_count;

    my @column_counts;
    for my $row (@{$matrix_values}) {
        if (ref $row ne 'ARRAY') {
            push @column_counts, undef;
        } else {
            push @column_counts, scalar @{$row};
        }
    }

    if ( defined $target_col_count ) {
        for ( my $i = 0; $i < @column_counts; $i++ ) {
            next if !defined $column_counts[$i];
            next if $column_counts[$i] eq $target_col_count;
            push @issues,
                 {
                    'test_type' => 'TYPE_CONTAINER.MATRIX_ROW_LENGTH',
                    'message'   =>
                        'does not contain the required number of elements in ' .
                        'the matrix row \'' . ( $i + 1 ) . '\' ' .
                        "($column_counts[$i] instead of $target_col_count)"
                 }
        }
    } else {
        my $index_of_first_defined = first_index{ defined $_ } @column_counts;
        if ( defined $index_of_first_defined ) {
            my $pivot_row_col_count = $column_counts[$index_of_first_defined];
            for ( my $i = 0; $i < @column_counts; $i++ ) {
                next if !defined $column_counts[$i];
                next if $pivot_row_col_count == $column_counts[$i];
                push @issues,
                     {
                        'test_type' =>
                            'TYPE_CONTAINER.MISMATCHING_MATRIX_ROW_LENGTHS',
                        'message'   =>
                            'is not a proper matrix -- the number of ' .
                            'elements in row \''. ( $index_of_first_defined + 1 ) .
                            ' and row \'' . ( $i + 1 ) . '\' do not match ' .
                            "($pivot_row_col_count vs. $column_counts[$i])"
                     };
                last;
            }
        }
    }

    return \@issues;
}

##
# Parses a DDLm dimension string into individual components.
#
# @param $dimension_string
#       DDLm dimension string to be parsed.
# @return
#       Reference to an array of two elements both of which might be
#       undefined.
##
sub parse_dimension
{
    my ( $dimension_string ) = @_;

    my @dimension_components;
    if ( $dimension_string =~ m/^\[(([0-9]+)(,([0-9]+))?)?\]$/ ) {
        push @dimension_components, $2;
        push @dimension_components, $4;
    } else {
        warn "WARNING, dimension string '$dimension_string' could not be parsed\n";
        @dimension_components = (undef, undef);
    }

    return \@dimension_components;
}

#sub stringify_value
#{
#    my ($value) = @_;
#
#    my $max_string_length = 256;
#
#    if (ref $value eq '') {
#        return $value;
#    }
#
#    if (ref $value eq 'ARRAY') {
#        my $array_string = '[ ';
#        for my $a_value ( @{$value} ) {
#            $array_string .= stringify_value($a_value) . " ";
#        }
#        $array_string .= ']';
#        return $array_string;
#    }
#
#    if (ref $value eq 'HASH') {
#        my $hash_string = '{ ';
#        for my $key ( sort keys %{$value} ) {
#            $hash_string .= "'$key': " . stringify_value($value->{$key}) . " ";
#        }
#        $hash_string .= '}';
#        return $hash_string;
#    }
#
#    return $value;
#}

##
# Checks enumeration values against the DDLm dictionary file.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @param $options
#       Reference to a hash of options. The following options are recognised:
#       {
#       # A list of data items that should be treated as potentially
#       # consisting of a several enumeration values
#           'enum_as_set_tags' => [ '_atom_site_refinement_flags',
#                                   '_atom_site.refinement_flags', ]
#       }
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub validate_enumeration_set
{
    my ($data_frame, $dic, $options) = @_;

    my @issues;

    for my $tag ( @{$data_frame->{'tags'}} ) {
        next if ( !exists $dic->{'Item'}{$tag} );

        my $dic_item = $dic->{'Item'}{$tag};
        next if ( !exists $dic_item->{'values'}{'_enumeration_set.state'} );

        my $treat_as_set = any { /^$tag$/ } @{$options->{'enum_as_set_tags'}};
        my $enum_options = { 'treat_as_set' => $treat_as_set,
                             'ignore_case'  => 0 };

        my $enum_set = $dic_item->{'values'}{'_enumeration_set.state'};
        my $data_type = get_type_contents($tag, $data_frame, $dic);
        my @canon_enum_set =
            map { canonicalise_ddlm_value( $_, $data_type ) } @{$enum_set};

        my $type_container = lc get_type_container($dic_item);
        if ( $type_container eq 'single' ) {
            my @values;
            for ( my $i = 0; $i < @{$data_frame->{'values'}{$tag}}; $i++ ) {
                next if has_special_value($data_frame, $tag, $i);
                push @values, $data_frame->{'values'}{$tag}[$i];
            }
            my @canon_values =
                map { canonicalise_ddlm_value( $_, $data_type ) } @values;

            my $is_proper_enum = check_enumeration_set(
                                    \@canon_values,
                                    \@canon_enum_set,
                                    $enum_options
                                  );
            for ( my $i = 0; $i < @{ $is_proper_enum }; $i++ ) {
                if ( $is_proper_enum->[$i] ) {
                    push @issues,
                         {
                            'test_type'  => 'ENUMERATION_SET',
                            'data_items' => [ $tag ],
                            'message' =>
                                'data item \'' . ( canonicalise_tag($tag) ) .
                                "' value '$values[$i]' must " .
                                'be one of the enumeration values [' .
                                ( join ', ', map { "'$_'" } @{$enum_set} ) . ']'
                         }
                }
            }
        } else {
            for (my $i = 0; $i < @{$data_frame->{'values'}{$tag}}; $i++) {
                my $value = $data_frame->{'values'}{$tag}[$i];
                # !!! Mainly targeted at '_type.contents'.
                # !!! Might be deprecated soon.
                if ( $type_container eq 'multiple' ) {
                    if (! any { uc $value  eq uc $_ } @{$enum_set} ) {
                        #     print "$instance: $tag: $value is not permitted\n";
                        #  warn "data item '$tag' value \"$value\" "
                        #     . 'must be one of the enumeration values '
                        #     . '[' . ( join ', ', @enum_values ) . ']. '
                        #     . 'This message might be a false positive since '
                        #     . 'handling of enumeration values with the '
                        #     . "'Multiple' type container is not yet implemented\n";
                    }
                # TODO: consider all of these combinations?
                # even if they don't really occur?
                } elsif ( $type_container eq 'array' ) {

                } elsif ( $type_container eq 'matrix') {

                } elsif ( $type_container eq 'list' ) {

                } elsif ( $type_container eq 'table' ) {

                }
            }
        }
    }

    return \@issues;
}

##
# Checks loop properties against a DDLm dictionary.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub validate_loops
{
    my ($data_frame, $dic) = @_;

    my @issues;

    for my $loop_tags ( @{$data_frame->{'loops'}} ) {
        my %category_to_loop_tags;
        for my $loop_tag ( @{$loop_tags} ) {
            my $category_id = exists $dic->{'Item'}{$loop_tag} ?
                    get_category_id($dic->{'Item'}{$loop_tag}) :
                    get_category_name_from_local_data_name($loop_tag);
            next if !defined $category_id;
            push @{$category_to_loop_tags{lc $category_id}}, $loop_tag;
        }

        %category_to_loop_tags = %{
                        merge_child_categories_to_parent_categories(
                            \%category_to_loop_tags,
                            $dic
                        )};

        my @categories = keys %category_to_loop_tags;
        if (@categories > 1) {
            push @issues,
            {
                'test_type'  => 'LOOP.CATEGORY_HOMOGENEITY',
                'data_items' => [ @{$loop_tags} ],
                'message'    =>
                    'data items in a looped list must all belong ' .
                    'to the same category -- ' .
                    ( join ', ',
                        map { 'data items [' .
                            ( join ', ',
                                map { q{'} . ( canonicalise_tag($_) ) . q{'} }
                                    @{$category_to_loop_tags{$_}} ) .
                            "] belong to the '$_' category"
                        } sort @categories
                    ),
            }
        }
    }

    my %looped_categories;
    for my $tag ( @{$data_frame->{'tags'}} ) {
        next if !exists $dic->{'Item'}{$tag};

        my $category_id = lc get_category_id($dic->{'Item'}{$tag});
        # This should not happen in a proper dictionary
        next if !exists $dic->{'Category'}{$category_id};

        my $category = $dic->{'Category'}{$category_id};
        my $tag_is_looped = exists $data_frame->{'inloop'}{$tag};

        if ( is_looped_category( $category ) ) {
            $looped_categories{$category_id}{$tag} = {
                'loop_id'   =>
                    ( exists $data_frame->{'inloop'}{$tag} ?
                      $data_frame->{'inloop'}{$tag} : -1 ),
                'loop_size' => scalar @{$data_frame->{'values'}{$tag}},
            };
        } elsif ( $tag_is_looped ) {
            push @issues,
                 {
                    'test_type'  => 'LOOP_CONTEXT.MUST_NOT_APPEAR_IN_LOOP',
                    'data_items' => [ $tag ],
                    'message'    => 'data item \'' . ( canonicalise_tag($tag) ) .
                                    '\' must not appear in a loop'
                 }
        }
    }

    push @issues,
         @{check_loop_keys( \%looped_categories, $data_frame, $dic )};

    for my $name (keys %looped_categories) {
        push @issues,
             @{check_category_integrity(
                        $looped_categories{$name},
                        $data_frame,
                        $dic
             )};
    }

    return \@issues;
}

##
# Merges looped categories into their closest available looped category
# ancestor.
#
# @param $category_to_loop_tags
#       Reference of a data structure that maps each category to data items
#       that belong to that category. Data structure takes the following form:
#
#       {
#           'category_a' => [ 'category_a.item_1',  ..., 'category_a.item_n' ],
#           ...,
#           'category_z' => [ 'category_z.item_1', ..., 'category_z.item_m' ],
#       }
#
#       Both the category names and the data item names are lowercased.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @return
#       Reference to a data structure of the same form as the input
#       structure $category_to_loop_tags with the looped child
#       categories merged into their closest available looped category
#       ancestor, for example:
#       {
#           'category_a' => [
#               'category_a.item_1',
#               ...,
#               'sub_category_a.item_n',
#               ...,
#               'sub_sub_category_a.item_m',
#               ...
#           ],
#           ...
#       }
##
sub merge_child_categories_to_parent_categories
{
    my ($category_to_loop_tags, $dic) = @_;

    my @categories = keys %{$category_to_loop_tags};
    for my $child_category_id (@categories) {
        next if !is_looped_category( $dic->{'Category'}{$child_category_id} );
        my $closest_ancestor_id = find_closest_looped_ancestor_category(
                                    $child_category_id,
                                    [keys %{$category_to_loop_tags}],
                                    $dic
                                  );
        next if !defined $closest_ancestor_id;
        push @{$category_to_loop_tags->{$closest_ancestor_id}},
             @{$category_to_loop_tags->{$child_category_id}};
        delete $category_to_loop_tags->{$child_category_id};
    }

    return $category_to_loop_tags;
}

##
# Selects the closest looped category ancestor of a given category
# out of the provided categories as described in a DDLm dictionary.
#
# @param $child_category_id
#       Lowercased id of the category for which the closest ancestor should
#       be selected.
# @param $categories
#       Reference to an array of lowercased category ids from which
#       the closest looped category ancestor should be selected.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @return
#       Lowercased id of closest looped category ancestor or
#       undef if no such ancestor could be located.
##
sub find_closest_looped_ancestor_category
{
    my ($child_category_id, $categories, $dic) = @_;

    my $parent_category_id = lc get_category_id(
                                    $dic->{'Category'}{$child_category_id}
                                );
    return if !is_looped_category( $dic->{'Category'}{$parent_category_id} );

    if (any { $_ eq $parent_category_id } @{$categories}) {
        return $parent_category_id;
    }

    return find_closest_looped_ancestor_category(
                                                  $parent_category_id,
                                                  $categories,
                                                  $dic
                                                );
}

##
# Checks the existence and uniqueness of loop primary keys.
#
# @param $looped_categories
#       Data structure that stores information about the looped
#       categories present in the provided data frame:
#
#       # Lowercased category names serve as the top-level keys.
#       $looped_categories = {
#           $category_1 => {
#               # All data item names are also lowercased.
#               $category_1_data_name_1 => {
#                   'loop_id'   => 1,  # in loop no 1
#                   'loop_size' => 5,
#               },
#               $category.data_name_2 => {
#                   'loop_id'   => 1,
#                   'loop_size' => 5,
#               },
#               $category.data_name_3 => {
#                   'loop_id'   => -1, # unlooped
#                   'loop_size' => 1,
#               },
#               $category.data_name_4 => {
#                   'loop_id'   => 2,  # in loop no 2
#                   'loop_size' => 3,
#               },
#           },
#           $category_2 => {
#               # ...
#           },
#       }
# @param $data_frame
#       Data frame in which the validated loops reside as returned
#       by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_loop_keys
{
    my ( $looped_categories, $data_frame, $dic ) = @_;

    my @issues;
    for my $name (sort keys %{$looped_categories} ) {
        # The _category.key_id data item holds the data name of a single
        # data item that acts as the primary key of a category.

        push @issues,
             @{check_simple_category_key(
                $name, $looped_categories, $data_frame, $dic, '_category.key_id'
             ) };

        # If the _category.key_id and _category_key.name data item values
        # are identical the validation of the latter should be skipped.
        if ( exists $dic->{'Category'}{$name}{'values'}{'_category.key_id'} &&
             exists $dic->{'Category'}{$name}{'values'}{'_category_key.name'} &&
             @{$dic->{'Category'}{$name}{'values'}{'_category_key.name'}} == 1 &&
             $dic->{'Category'}{$name}{'values'}{'_category.key_id'}[0] eq
             $dic->{'Category'}{$name}{'values'}{'_category_key.name'}[0]
        ) {
            next;
        }

        # Alternatively, the _category_key.name data item contains
        # a list of data items that can function as a primary key
        push @issues,
             @{check_composite_category_key(
                $name, $looped_categories, $data_frame, $dic
             ) };

    }

    return \@issues;
}

##
# Checks if all data items from the same category appear in the same loop [1].
#
# @source [1]
#       2. Category definition,
#       "DDLm: A New Dictionary Definition Language",
#       2012, 52(8), 1910, doi: 10.1021/ci300075z
#
# @param $item_loop_details
#       Data structure that maps data items from the checked category
#       to the loops in which they appear in the validated data frame:
#       {
#           $category_data_name_1 => {
#               'loop_id'   => 1,  # in loop no 1
#               'loop_size' => 5,
#           },
#           $category.data_name_2 => {
#               'loop_id'   => 1,
#               'loop_size' => 5,
#           },
#           $category.data_name_3 => {
#               'loop_id'   => -1, # unlooped
#               'loop_size' => 1,
#           },
#           $category.data_name_4 => {
#               'loop_id'   => 2,  # in loop no 2
#               'loop_size' => 3,
#           },
#           ...
#       }
# @param $data_frame
#       Data frame in which the validated loops reside as returned
#       by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_category_integrity
{
    my ($item_loop_details, $data_frame, $dic) = @_;

    my %loop_item_count;
    for my $tag ( keys %{$item_loop_details} ) {
        $loop_item_count{$item_loop_details->{$tag}{'loop_id'}}++;
    }
    # All category items reside in the same loop
    return [] if (keys %loop_item_count <= 1);

    my @issues;
    push @issues,
         {
            'test_type'  => 'CATEGORY_INTEGRITY',
            'data_items' => [ keys %{$item_loop_details} ],
            'message'    =>
                'data items ' . '[' .
                ( join ', ',
                    sort map { q{'} . ( canonicalise_tag($_) ) . q{'} }
                        keys %{$item_loop_details} ) .
                ']' . ' must all appear in the same loop'
         };

    return \@issues;
}

##
# Checks constraints of a simple loop key that consists of a single data item.
#
# @param $category_name
#       Lowercased name of the category that should be checked.
# @param $looped_categories
#       Data structure that stores information about the looped
#       categories present in the provided data frame:
#
#       # Lowercased category names serve as the top-level keys.
#       $looped_categories = {
#           $category_1 => {
#               # All data item names are also lowercased.
#               $category_1_data_name_1 => {
#                   'loop_id'   => 1,  # in loop no 1
#                   'loop_size' => 5,
#               },
#               $category.data_name_2 => {
#                   'loop_id'   => 1,
#                   'loop_size' => 5,
#               },
#               $category.data_name_3 => {
#                   'loop_id'   => -1, # unlooped
#                   'loop_size' => 1,
#               },
#               $category.data_name_4 => {
#                   'loop_id'   => 2,  # in loop no 2
#                   'loop_size' => 3,
#               },
#           },
#           $category_2 => {
#               # ...
#           },
#       }
# @param $data_frame
#       Data frame in which the validated loops reside as returned
#       by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @param $ddlm_key_attribute
#       Name of the DDLm attribute that should be used to determine
#       the category key item. Usual values include '_category_key.name'
#       and '_category.key_id'. Default: '_category_key.name'.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_simple_category_key
{
    my ( $category_name, $looped_categories, $data_frame, $dic, $ddlm_key_attribute ) = @_;

    $ddlm_key_attribute = '_category_key.name' if !defined $ddlm_key_attribute;

    my $candidate_key_ids = get_simple_candidate_key_ids(
                                $category_name,
                                $dic,
                                $ddlm_key_attribute
                            );

    return [] if !@{$candidate_key_ids};
    # The candidate loop key is chosen only if it shares a looped list
    # with at least a single data item from the category. Two unlooped
    # data items are treated as sharing the same loop.
    my $key_data_name;
    for my $id ( @{$candidate_key_ids} ) {
        for my $data_name (@{get_all_unique_data_names($dic->{'Item'}{$id})}) {
            next if !exists $data_frame->{'values'}{$data_name};
            next if !item_shares_loop_with_any_item_from_category( $data_name,
                                                                   $data_frame,
                                                                   $looped_categories->{$category_name} );
            $key_data_name = $data_name;
            last;
        }
        last if defined $key_data_name;
    }

    my @issues;
    if ( defined $key_data_name ) {
        # NOTE: in order to avoid duplicate validation messages the key
        # uniqueness check is only carried out if the primary key data
        # item is the one provided directly in the category definition.
        if ( any { $key_data_name eq $_ }
                    @{get_all_unique_data_names($dic->{'Item'}{$candidate_key_ids->[0]})} ) {
            my $data_type =
                 get_type_contents($key_data_name, $data_frame, $dic);
            push @issues,
                 @{ check_simple_key_uniqueness( $key_data_name, $data_frame, $data_type ) };
        }
    } else {
        # NOTE: dREL methods sometimes define a way to evaluate the
        # data value using other data item. Since dREL is currently
        # not handled by the validator the missing value should not
        # be reported
        # TODO: implement key evaluation using dREL methods
        my $is_evaluatable = 0;
        for my $id ( @{$candidate_key_ids} ) {
            my $key_attributes =  $dic->{'Item'}{$id}{'values'};
            next if !exists $key_attributes->{'_method.purpose'};
            for my $i (0..$#{$key_attributes->{'_method.purpose'}}) {
                my $purpose = lc $key_attributes->{'_method.purpose'}[$i];
                if ($purpose eq 'evaluation') {
                    $is_evaluatable = 1;
                    last;
                } elsif ($purpose eq 'definition') {
                    my $expression =
                                lc $key_attributes->{'_method.expression'}[$i];
                    if ($expression =~ m/_enumeration[.]default\s*=/ms) {
                        $is_evaluatable = 1;
                        last;
                    }
                }
            }
            last if $is_evaluatable;
        }

        if ( !$is_evaluatable ) {
            push @issues,
                 {
                    'test_type'  => 'KEY_ITEM_PRESENCE',
                    'data_items' => [ $candidate_key_ids->[0] ],
                    'message'    =>
                        'missing category key data item -- the \'' .
                        ( canonicalise_tag($candidate_key_ids->[0]) ) .
                        '\' data item must be provided in the loop ' .
                        'containing the [' .
                        ( join ', ',
                              sort map { q{'} . ( canonicalise_tag($_) ) . q{'} }
                                  keys %{$looped_categories->{$category_name}} ) .
                        '] data items'
                }
        }
    }

    return \@issues;
}

##
# Determines if an item resides in the same looped list as at least one of
# the items from the provided looped category. Data items that do not reside
# in a loop are treated as sharing the same loop.
#
# @param $key_item_name
#       Name of the data item that should be checked.
# @param $data_frame
#       Data frame in which all of the involved data items reside
#       as returned by the COD::CIF::Parser.
# @param $looped_category
#       Reference to a data structure that contains information about
#       a looped category from the provided data frame:
#
#       {
#           $category_1_data_name_1 => {
#               'loop_id'   => 1,  # in loop no 1
#               'loop_size' => 5,
#           },
#           $category.data_name_2 => {
#               'loop_id'   => 1,
#               'loop_size' => 5,
#           },
#           $category.data_name_3 => {
#               'loop_id'   => -1, # unlooped
#               'loop_size' => 1,
#           },
#           $category.data_name_4 => {
#               'loop_id'   => 2,  # in loop no 2
#               'loop_size' => 3,
#           },
#       },
# @return
#       '1' if the item resides in the same looped list as at least one of
#           the item from the category,
#       '0' otherwise.
##
sub item_shares_loop_with_any_item_from_category
{
    my ($key_item_name, $data_frame, $looped_category) = @_;

    my $key_loop_id = get_item_loop_index($data_frame, $key_item_name);
    $key_loop_id = -1 if !defined $key_loop_id;

    for my $item (sort keys %{$looped_category}) {
        my $item_loop_id = $looped_category->{$item}{'loop_id'};
        return 1 if $item_loop_id == $key_loop_id;
    }

    return 0;
}

##
# Determines which data items can act as non-composite primary keys of a
# category according to the given DDLm dictionary. Normally, each category
# only has a single non-composite candidate key, with the notable exception
# of looped categories that contain looped subcategories. In this case, the
# child category can use the primary key of the parent category as its own.
#
# @param $category_id
#       Id of the category.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @param $ddlm_key_attribute
#       Name of the DDLm attribute that should be used to determine
#       the category key item. Usual values include '_category.key_id'
#       and '_category_key.name'. Default: '_category_key.name'.
# @return
#       Array reference to a list of data items that can act as the primary
#       key for the given category.
##
sub get_simple_candidate_key_ids
{
    my ( $category_id, $dic, $ddlm_key_attribute ) = @_;

    $ddlm_key_attribute = '_category_key.name' if !defined $ddlm_key_attribute;

    my @candidate_keys;
    my $category_block = $dic->{'Category'}{$category_id};
    while (defined $category_block) {
        last if !exists $category_block->{'values'}{$ddlm_key_attribute};
        last if @{$category_block->{'values'}{$ddlm_key_attribute}} > 1;
        push @candidate_keys, $category_block->{'values'}{$ddlm_key_attribute}[0];
        my $parent_category_id = lc get_category_id( $category_block );
        $category_block = $dic->{'Category'}{$parent_category_id};
        if ( !is_looped_category( $category_block ) ) {
            undef $category_block;
        }
    }
    @candidate_keys = map { lc } @candidate_keys;

    return \@candidate_keys;
}

##
# Checks the uniqueness constraint of a simple loop key.
#
# @param $data_name
#       Data name of the data item which acts as the unique loop key.
# @param $data_frame
#       CIF data frame (data block or save block) in which the data item
#       resides as returned by the COD::CIF::Parser.
# @param $key_type
#       Content type of the key as defined in the DDLm dictionary.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_simple_key_uniqueness
{
    my ($data_name, $data_frame, $key_type) = @_;

    my %unique_values;
    for ( my $i = 0; $i < @{$data_frame->{'values'}{$data_name}}; $i++ ) {
        # TODO: special values are silently skipped, but maybe they should
        # still be reported somehow since having special value in a key
        # might not be desirable...
        next if has_special_value($data_frame, $data_name, $i);
        my $value = $data_frame->{'values'}{$data_name}[$i];
        my $canon_value = canonicalise_ddlm_value( $value, $key_type );
        push @{$unique_values{$canon_value}}, $value;
    }

    my @issues;
    for my $key ( sort keys %unique_values ) {
        if ( @{$unique_values{$key}} > 1 ) {
            push @issues,
                 {
                    'test_type'  => 'SIMPLE_KEY_UNIQUENESS',
                    'data_items' => [ $data_name ],
                    'message'    =>
                        'data item \'' .
                        ( canonicalise_tag($data_name) ) .
                        '\' acts as a loop key, but the associated data ' .
                        'values are not unique -- value ' .
                        "'$key' appears " .
                            ( scalar @{$unique_values{$key}} ) .
                        ' times as [' .
                            ( join ', ', uniq map { "'$_'" }
                                @{$unique_values{$key}} ) .
                        ']'
                }
        }
    }

    return \@issues;
}

##
# Checks constraints of a composite loop key that consists of several data
# items.
#
# @param $category
#       Name of the category that should be checked.
# @param $looped_categories
#       Data structure that stores information about the looped
#       categories present in the provided data frame:
#
#       # Lowercased category names serve as the top-level keys.
#       $looped_categories = {
#           $category_1 => {
#               # All data item names are also lowercased.
#               $category_1_data_name_1 => {
#                   'loop_id'   => 1,  # in loop no 1
#                   'loop_size' => 5,
#               },
#               $category.data_name_2 => {
#                   'loop_id'   => 1,
#                   'loop_size' => 5,
#               },
#               $category.data_name_3 => {
#                   'loop_id'   => -1, # unlooped
#                   'loop_size' => 1,
#               },
#               $category.data_name_4 => {
#                   'loop_id'   => 2,  # in loop no 2
#                   'loop_size' => 3,
#               },
#           },
#           $category_2 => {
#               # ...
#           },
#       }
# @param $data_frame
#       Data frame in which the validated loops reside as returned
#       by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_composite_category_key
{
    my ( $category, $looped_categories, $data_frame, $dic ) = @_;

    $category = lc $category;

    return [] if !exists $dic->{'Category'}{$category}{'values'}{'_category_key.name'};

    my @issues;

    if (@{$dic->{'Category'}{$category}{'values'}{'_category_key.name'}} == 1) {
        push @issues, @{check_simple_category_key(
                            $category,
                            $looped_categories,
                            $data_frame,
                            $dic,
                            '_category_key.name'
                      )};
        return \@issues;
    }

    my @key_data_names;
    my $cat_key_ids = $dic->{'Category'}{$category}{'values'}{'_category_key.name'};
    for my $cat_key_id ( @{$cat_key_ids} ) {
        if ( exists $dic->{'Item'}{lc $cat_key_id} ) {
            my $cat_key_frame = $dic->{'Item'}{lc $cat_key_id};
            my $type_contents = get_type_contents(
                $cat_key_id, $data_frame, $dic
            );

            my @data_names;
            push @data_names, @{ get_all_unique_data_names( $cat_key_frame ) };

            my $is_key_present = 0;
            for my $data_name (@data_names) {
                if ( exists $data_frame->{'values'}{$data_name} ) {
                    $is_key_present = 1;
                    push @key_data_names, $data_name;
                    last;
                }
            }

            # NOTE: dREL methods sometimes define a way to evaluate the
            # data value using other data items. Since dREL is currently
            # not handled by the validator the missing value should not
            # be reported
            # TODO: implement key evaluation using dREL methods
            my $is_evaluatable = 0;
            if ( exists $cat_key_frame->{'values'}{'_method.purpose'} ) {
                my $values = $cat_key_frame->{'values'};
                for my $i (0..$#{$values->{'_method.purpose'}}) {
                    my $purpose = lc $values->{'_method.purpose'}[$i];
                    if ($purpose eq 'evaluation') {
                        $is_evaluatable = 1;
                        last;
                    } elsif ($purpose eq 'definition') {
                        my $expression = lc $values->{'_method.expression'}[$i];
                        if ($expression =~ m/_enumeration[.]default\s*=/ms) {
                            $is_evaluatable = 1;
                            last;
                        }
                    }
                }
            }

            my $has_default_value = 0;
            if ( exists $cat_key_frame->{'values'}{'_enumeration.default'} &&
                 !(has_special_value($cat_key_frame, '_enumeration.default', 0) ) ) {
                $has_default_value = 1;
            }

            if ( !$is_key_present &&
                 !$is_evaluatable &&
                 !$has_default_value ) {
                push @issues,
                     {
                        'test_type'  => 'KEY_ITEM_PRESENCE',
                        'data_items' => [ $data_names[0] ],
                        'message'    =>
                            'missing category key data item -- the \'' .
                            ( canonicalise_tag($data_names[0]) ) .
                            '\' data item must be provided in the loop ' .
                            'containing the [' .
                            ( join ', ',
                                sort map { q{'} . ( canonicalise_tag($_) ) . q{'} }
                                  keys %{$looped_categories->{$category}} ) .
                            '] data items'
                     }
            }
        } else {
            warn 'WARNING, missing data item definition in the DDLm ' .
                 "dictionary -- the '$cat_key_id' data item is defined as " .
                 'comprising the composite primary key of the looped ' .
                 "'$category' category, however, the data item definition " .
                 'is not provided' . "\n";
        }
    }
    push @issues,
         @{ check_composite_key_uniqueness( \@key_data_names, $data_frame, $dic ) };

    return \@issues;
}

##
# Checks the uniqueness constraint of a composite loop key.
#
# @param $data_names
#       Data names of data items that comprise the composite unique loop key.
# @param $data_frame
#       CIF data frame (data block or save block) in which the data item
#       resides as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub check_composite_key_uniqueness
{
    my ($data_names, $data_frame, $dic) = @_;

    return [] if !@{ $data_names };

    my $join_char = "\x{001E}";
    my %unique_values;
    for ( my $i = 0; $i < @{$data_frame->{'values'}{$data_names->[0]}}; $i++ ) {
        my $composite_key = '';
        my @composite_key_values;
        my $has_special_value = 0;
        for my $data_name ( @{$data_names } ) {
            # TODO: composite keys containing special values are silently
            # skipped, but maybe they should still be reported somehow since
            # having special value in a key might render it unusable
            if ( has_special_value($data_frame, $data_name, $i) ) {
                $has_special_value = 1;
                last;
            };

            # TODO: it is really suboptimal to ask for the content type
            # each time...
            my $key_type = get_type_contents(
                $data_name, $data_frame, $dic
            );

            my $value = $data_frame->{'values'}{$data_name}[$i];
            push @composite_key_values, $value;
            $composite_key .= canonicalise_ddlm_value( $value, $key_type ) .
                              "$join_char";
        }
        if (!$has_special_value) {
            push @{$unique_values{$composite_key}}, \@composite_key_values;
        }
    }

    my @issues;
    for my $key ( sort keys %unique_values ) {
        if ( @{$unique_values{$key}} > 1 ) {
            my @duplicates;
            for my $values ( @{$unique_values{$key}} ) {
                push @duplicates,
                     '[' . ( join ', ', map { "'$_'" } @{$values} ) . ']';
            }

            push @issues,
                 {
                    'test_type'  => 'COMPOSITE_KEY_UNIQUENESS',
                    'data_items' => \@{$data_names},
                    'message'    =>
                        'data items [' .
                        ( join ', ',
                            map { q{'} . ( canonicalise_tag($_) ) . q{'} }
                              @{$data_names} ) .
                        '] act as a composite loop key, but the associated ' .
                        'data values are not collectively unique -- values [' .
                        ( join ', ', map { "'$_'" } split /$join_char/, $key ) .
                        '] appear ' .
                            ( scalar @{$unique_values{$key}} ) .
                        ' times as [' .
                            ( join ', ',  uniq @duplicates ) .
                        ']'
                 }
        }
    }

    return \@issues;
}

##
# Checks if a data frame contains data items that marked as deprecated
# by a DDLm dictionary.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub report_deprecated
{
    my ($data_frame, $dic) = @_;

    my @issues;
    for my $tag ( @{$data_frame->{'tags'}} ) {
        next if !exists $dic->{'Item'}{$tag};
        my $data_item = $dic->{'Item'}{$tag};
        next if !exists $data_item->{'values'}{'_definition_replaced.by'};

        push @issues,
             {
              'test_type'  => 'PRESENCE_OF_DEPRECATED_ITEM',
              'data_items' => [ $tag ],
              'message'    =>
                  'the \'' . ( canonicalise_tag($tag) ) . '\' data item has ' .
                  'been deprecated and should not be used -- it was replaced ' .
                  'by the [' .
                  (
                    join ', ' ,
                        map { q{'} . ( canonicalise_tag($_) ) . q{'} }
                            @{$data_item->{'values'}{'_definition_replaced.by'}}
                  ) . '] data items'
             }
    }

    return \@issues;
}

##
# Checks if values are within the range specified by a DDLm dictionary.
#
# In case the value has an associated standard uncertainty (s.u.) value
# the range is extended from [x; y] to [x-3s; y+3s] where s is the s.u.
# value. Standard uncertainty values are considered in range comparison
# even if the data item is not formally eligible to have an associated
# s.u. value at all.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @param $options
#       Reference to a hash of options. The following options are recognised:
#       {
#         # Multiplier that should be applied to the standard
#         # uncertainty (s.u.) when determining if a numeric
#         # value resides in the specified range. For example,
#         # a multiplier of 3.5 means that the value is treated
#         # as valid if it falls in the interval of
#         # [lower bound - 3.5 * s.u.; upper bound + 3.5 * s.u.]
#           'range_su_multiplier' => 3,
#       }
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub validate_range
{
    my ($data_frame, $dic, $options) = @_;

    my $su_multiplier = $options->{'range_su_multiplier'};

    my @issues;

    for my $tag ( @{$data_frame->{'tags'}} ) {
        next if !exists $dic->{'Item'}{$tag};

        my $dic_item = $dic->{'Item'}{$tag};
        next if !exists $dic_item->{'values'}{'_enumeration.range'};
        my $range = parse_range( $dic_item->{'values'}{'_enumeration.range'}[0] );

        # DDLm s.u. values can be stored either in the parenthetic of the
        # data value (concise notation, e.g. 5.7(6)) or using a separate
        # data item. This subroutine prioritises the concise notation and
        # only uses the data item if none of the concise notation s.u.
        # values are applicable
        my $su_values = get_su_from_data_values( $data_frame, $tag );
        if ( !any { is_numeric_su_value( $_ ) } @{$su_values} ) {
            $su_values = get_su_from_separate_item( $dic, $data_frame, $tag );
        }

        for (my $i = 0; $i < @{$data_frame->{'values'}{$tag}}; $i++) {
            next if (  has_special_value($data_frame, $tag, $i) );
            next if ( !has_numeric_value($data_frame, $tag, $i) );

            my $value = $data_frame->{'values'}{$tag}[$i];
            my $old_value = $value;

            my $su_value;
            if ( defined $su_values &&
                 is_numeric_su_value( $su_values->[$i] ) ) {
                $su_value = $su_values->[$i];
            }

            $value =~ s/\([0-9]+\)$//;
            if ( !is_in_range( $value, { 'range' => $range,
                                         'type' => 'numb',
                                         'sigma' => $su_value,
                                         'multiplier' => $su_multiplier } ) ) {
                push @issues,
                     {
                        'test_type'  => 'ENUM_RANGE.IN_RANGE',
                        'data_items' => [ $tag ],
                        'message' =>
                            'data item \'' . ( canonicalise_tag($tag) ) .
                            "' value '$old_value' should be " .
                            'in range ' . range_to_string($range, { 'type' => 'numb' })
                     }
            }
        }
    }

    return \@issues;
}

##
# Checks application scope restrictions for data items in a dictionary file.
#
# @param $data_frame
#       Data frame that should be validated as returned by the COD::CIF::Parser.
# @param $application_scope
#       Reference to a data item application scope data structure as
#       returned by the extract_application_scope() subroutine.
# @return
#       Reference to an array of validation issue data structures of
#       the following form:
#       {
#         # Code of the validation test that generated the issue
#           'test_type' => 'TEST_TYPE_CODE',
#         # Code of the data block in which the data item resides
#           'data_block_code' => 'block_code',
#         # Code of the save frame in which the data item resides
#         # Might be undefined
#           'save_frame_code' => 'frame_name'
#         # Names of the data items examined by the validation test
#           'data_items' => [ 'data_name_1', 'data_name_2', ... ],
#         # Validation message that should be displayed to the user
#           'message'    => 'a detailed validation message'
#       }
##
sub validate_application_scope
{
    my ($data_frame, $application_scope) = @_;

    my @issues;
    my $data_block_code = $data_frame->{'name'};
    my $search_struct = build_ddlm_dic($data_frame);
    for my $scope ( 'Dictionary', 'Category', 'Item' ) {
      my %seen_definition;
      for my $instance ( sort keys %{$search_struct->{$scope}} ) {
        my %mandatory   = map { $_ => 0 } @{$application_scope->{$scope}{'Mandatory'}};
        my %recommended = map { $_ => 0 } @{$application_scope->{$scope}{'Recommended'}};
        my %prohibited  = map { $_ => 0 } @{$application_scope->{$scope}{'Prohibited'}};
        # NOTE: by definition the 'Dictionary' scope does not have a save frame name
        my $save_frame_code;
        if ( $scope ne 'Dictionary' ) {
            $save_frame_code = $search_struct->{$scope}{$instance}{'name'};
            # Data items that have aliases are represented by several different
            # data blocks in the DDLm dictionary search data structure. This
            # check is needed to avoid reporting the same issue multiple times. 
            next if $seen_definition{$save_frame_code};
            $seen_definition{$save_frame_code} = 1;
        }

        for my $tag ( @{$search_struct->{$scope}{$instance}{'tags'}} ) {
          if ( exists $prohibited{$tag} ) {
            # NOTE: import statements are allowed in the HEAD category
              if ( $tag eq '_import.get' &&
                   ( lc get_definition_class( $search_struct->{$scope}{$instance} ) eq 'head' ) ) {
                next;
              }
              push @issues,
                   {
                      'test_type'       => 'SCOPE.PROHIBITED',
                      'data_block_code' => $data_block_code,
                      'save_frame_code' => $save_frame_code,
                      'data_items'      => [ $tag ],
                      'message'         =>
                          'data item \'' . ( canonicalise_tag($tag) ) .
                          "\' is prohibited in the '$scope' scope of the " .
                          "'$search_struct->{$scope}{$instance}{'name'}' " .
                          'frame'
                   }
          }
          $mandatory{$tag}   = 1 if ( exists $mandatory{$tag} );
          $recommended{$tag} = 1 if ( exists $recommended{$tag} );
        }

        for my $tag (sort keys %mandatory) {
          if ( $mandatory{$tag} == 0 ) {
            push @issues,
                 {
                    'test_type'       => 'SCOPE.MANDATORY',
                    'data_block_code' => $data_block_code,
                    'save_frame_code' => $save_frame_code,
                    'data_items'      => [ $tag ],
                    'message'         =>
                        'data item \'' . ( canonicalise_tag($tag) ) .
                        "\' is mandatory in the '$scope' scope of the " .
                        "'$search_struct->{$scope}{$instance}{'name'}' frame"
                 }
          }
        }

        for my $tag (sort keys %recommended) {
          if ( $recommended{$tag} == 0 ) {
            # The _category_key.name and _category.key_id are recommended
            # for the CATEGORY scope, however, they make no sense if
            # the CATEGORY is unlooped
            # TODO: figure out what is the IUCr policy towards this
            if ( $scope eq 'Category' &&
                 !is_looped_category( $search_struct->{$scope}{$instance} ) &&
                 ( $tag eq '_category_key.name' || $tag eq '_category.key_id' )
            ) {
               next;
            }

            push @issues,
                 {
                    'test_type'       => 'SCOPE.RECOMMENDED',
                    'data_block_code' => $data_block_code,
                    'save_frame_code' => $save_frame_code,
                    'data_items'      => [ $tag ],
                    'message'         =>
                        'data item \'' . ( canonicalise_tag($tag) ) .
                        "' is recommended in the '$scope' scope of the " .
                        "'$search_struct->{$scope}{$instance}{'name'}' frame"
                 }
          }
        }
      }
    }

    return \@issues;
}

##
# Extracts the application scopes of the data items described in the given
# dictionary. This subroutine is most likely applicable only to the DDLm
# reference dictionary.
#
# @param $dic
#       Data structure of the validation dictionary as returned by
#       the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
#       Most likely this dictionary will be the DDLm reference dictionary.
# @return $application_scope
#       Reference to a data item application scope data structure of the
#       following form:
#       {
#           'Dictionary' => {
#               'Mandatory'   => [ 'data_item_1', 'data_item_2' ],
#               'Recommended' => [ 'data_item_3' ],
#               'Prohibited'  => [ 'data_item_1' ],
#           },
#           'Category' => {
#               ...
#           },
#           'Item' => {
#               ...
#           }
#       }
##
sub extract_application_scope
{
    my ($dic) = @_;

    my $data_block = $dic->{'Datablock'};
    if ( !defined $data_block->{'values'}{'_dictionary_valid.application'} &&
         ( !defined $data_block->{'values'}{'_dictionary_valid.scope'} ||
           !defined $data_block->{'values'}{'_dictionary_valid.option'} ) ) {
        return;
    }

    if ( !defined $data_block->{'values'}{'_dictionary_valid.attributes'} ) {
        return;
    }

    my $valid_scope  = $data_block->{'values'}{'_dictionary_valid.scope'};
    my $valid_option = $data_block->{'values'}{'_dictionary_valid.option'};
    my $valid_application = $data_block->
                              {'values'}{'_dictionary_valid.application'};
    my $valid_attributes  = $data_block->
                              {'values'}{'_dictionary_valid.attributes'};

    # The DDLm dictionary stores scope restriction data in the form:
    # [SCOPE RESTRICTION], e.g. [DICTIONARY MANDATORY]
    my %application_scope;
    for (my $i = 0; $i < @{$valid_attributes}; $i++) {
        my $scope;
        my $option;
        if (defined $valid_scope & defined $valid_option) {
            $scope  = $valid_scope->[$i];
            $option = $valid_option->[$i];
        } else {
            $scope  = $valid_application->[$i][0];
            $option = $valid_application->[$i][1];
        }
        $application_scope{$scope}{$option} = $valid_attributes->[$i]
    }
    # Expand valid attribute categories into individual data item names
    for my $scope (sort keys %application_scope) {
        for my $permission (sort keys %{$application_scope{$scope}}) {
            $application_scope{$scope}{$permission} =
                expand_categories( $application_scope{$scope}{$permission}, $dic );
        }
    }

    return \%application_scope;
}

##
# Modifies the application scope validation criteria to be compatible
# with the IUCr DDLm dictionary style guide [1]. The dictionary style
# guide recommends omitting some of the attributes with default values
# from the definition save frames even though they are marked as recommended
# in the DDLm reference dictionary.
#
# @source [1]
#       https://github.com/COMCIFS/comcifs.github.io/blob/706b1a3168c6607fdb1a44dc1d863a57e90dadf5/accepted/ddlm_dictionary_style_guide.md?plain=1#L268
#
# @param $application_scope
#       Reference to a data item application scope data structure as
#       returned by the extract_application_scope() subroutine.
# @return
#       Reference to the input data item application scope data structure
#       that has been modified to be compatible with the IUCr DDLm dictionary
#       style guide.
##
sub apply_iucr_style_guide_exceptions
{
    my ($application_scope) = @_;

    # Exclude some attributes from recommended
    # based on rules 3.1.6.1, 3.1.6.2, 3.1.6.3

    my @excludable_attributes = qw(
        _definition.scope
        _definition.class
    );

    my @filtered_attributes;
    for my $attribute (@{$application_scope->{'Item'}{'Recommended'}}) {
        next if any { $_ eq lc $attribute } @excludable_attributes;
        push @filtered_attributes, $attribute;
    }
    $application_scope->{'Item'}{'Recommended'} = \@filtered_attributes;

    return $application_scope;
}

##
# Returns the ids of all data items contained in the given categories
# and their subcategories. Recursive.
#
# @param $parent_ids
#       Array reference to a list of parent category ids. Might contain
#       data item ids which are simply copied upon encounter.
# @param $dic
#       Data structure of a DDLm validation dictionary as returned
#       by the COD::CIF::DDL::DDLm::build_ddlm_dic() subroutine.
# @return
#       Array reference to a list of data item ids.
##
sub expand_categories
{
    my ($parent_ids, $dic) = @_;

    my @expanded_categories;
    for my $parent_id ( @{$parent_ids} ) {
        my $parent_id_in_original_case = $parent_id;
        $parent_id = lc $parent_id;
        if ( exists $dic->{'Item'}{$parent_id} ) {
            push @expanded_categories, $parent_id;
        } elsif ( exists $dic->{'Category'}{$parent_id} ) {
            for my $child_id (keys %{$dic->{'Item'}}) {
                my $category_id = get_category_id( $dic->{'Item'}{$child_id} );
                if ( defined $category_id &&
                     lc $category_id eq $parent_id ) {
                    push @expanded_categories, $child_id;
                }
            }
            for my $child_id (keys %{$dic->{'Category'}}) {
                my $category_id = get_category_id( $dic->{'Category'}{$child_id} );
                if ( defined $category_id &&
                     lc $category_id eq $parent_id ) {
                    push @expanded_categories, @{expand_categories([ $child_id ], $dic)};
                }
            }
        } else {
            # NOTE: this warning signifies an internal inconsistency
            #       in the validating reference dictionary
            warn 'could not locate a save frame with id ' .
                 "'$parent_id_in_original_case' in the provided DDLm " .
                 'reference dictionary -- application scope validation ' .
                 'may return incorrect results' . "\n";
        }
    }

    return \@expanded_categories;
}

##
# Extracts all unique data item names from a data item definition frame.
# The data names include the main definition id and definition id aliases.
#
# @param $data_frame
#       Data item definition frame as returned by the COD::CIF::Parser.
# @return $data_names
#       Array reference to a list of unique lowercased data names identifying
#       a data item or a reference to an empty array if no names were found.
##
sub get_all_unique_data_names
{
    my ( $data_frame ) = @_;

    my @data_names = uniq map { lc } @{get_all_data_names($data_frame)};

    return \@data_names;
}

# TODO: it should be noted, that special CIF values are handled outside of
# this function
# TODO: maybe move this to a separate module, implement and test all available
# options
sub compare_ddlm_values
{
  my ( $value_1, $value_2, $content_type ) = @_;

  return ( canonicalise_ddlm_value($value_1, $content_type) eq
           canonicalise_ddlm_value($value_2, $content_type) );
}

1;
