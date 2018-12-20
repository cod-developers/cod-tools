#------------------------------------------------------------------------------
#$Author: andrius $
#$Date: 2018-01-19 11:51:05 +0200 (Fri, 19 Jan 2018) $ 
#$Revision: 5954 $
#$URL: svn://www.crystallography.net/cod-tools/trunk/src/lib/perl5/COD/CIF/DDL/Ranges.pm $
#------------------------------------------------------------------------------
#*
#* A set of subroutines used to validate CIF files against Dictionary
#* Definition Language (DDL) files.
#**

package COD::CIF::DDL::Validate;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    validate_enumeration_set
);

use COD::CIF::Tags::Manage qw( has_special_value );

##
# Checks enumeration values against a DDL1 dictionary.
# @param $data_block
#       Data frame that should be validated as returned by the CIF::COD::Parser.
# @param $tag
#       The data name of the item that should be validated.
# @param $enum_set
#       Reference to an array of allowed data values.
# @param $options
#       Reference to a hash of options. The following options are recognised:
#       {
#       # Ignore the case while matching enumerators
#           'ignore_case'  => 0
#       # Treat data values as potentially consisting of a
#       # combination of several enumeration values
#           'treat_as_set' => 0
#       }
# @return
#       Array reference to a list of validation messages.
##
sub validate_enumeration_set
{
    my ($data_block, $tag, $enum_set, $options) = @_;

    my @validation_messages;

    my $ignore_case  = $options->{'ignore_case'};
    my $treat_as_set = $options->{'treat_as_set'};

    my $enum_regex = build_enum_regex( $enum_set, $options );

    for (my $i = 0; $i < @{$data_block->{'values'}{$tag}}; $i++) {
        next if has_special_value($data_block, $tag, $i);
        my $value = $data_block->{'values'}{$tag}[$i];

        my $is_proper_enum = 0;
        if( $value =~ m/$enum_regex/s ) {
            $is_proper_enum = 1;
        };

        if( !$is_proper_enum ) {
            push @validation_messages,
                "data item '$tag' value '$value' must be one of the "
              . 'enumeration values [' . ( join ', ', @{$enum_set} ) . ']';
        }
    }

    return \@validation_messages;
}

##
# Constructs a regular expression that matches strings consisting only
# of the given enumeration values.
# @param $enum_set
#       Reference to an array of allowed enumeration values.
# @param $options
#       Reference to a hash of options. The following options are recognised:
#       {
#       # Ignore the case while matching enumerators
#           'ignore_case'  => 0
#       # Treat data values as potentially consisting of a
#       # combination of several enumeration values
#           'treat_as_set' => 0
#       }
# @return $regex
#       String containing the regular expression.
##
sub build_enum_regex
{
    my ($enum_set, $options) = @_;

    my $ignore_case  = defined $options->{'ignore_case'} ?
                               $options->{'ignore_case'} : 0;
    my $treat_as_set = defined $options->{'treat_as_set'} ?
                               $options->{'treat_as_set'} : 0;

    my $values = join '|', map { quotemeta } grep { $_ ne '.' } @{$enum_set};

    my $case_modifier = $ignore_case  ? '(?i)' : '';
    my $set_modifier  = $treat_as_set ? '+'    : '';

    my $regex = qr/^${case_modifier}(?:${values})${set_modifier}$/;

    return $regex;
}

1;
