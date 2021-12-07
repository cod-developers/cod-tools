#------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------
#*
#* Manipulates ChangeLog messages and records them in a CIF file.
#**

package COD::CIF::ChangeLog;

use strict;
use warnings;
use COD::CIF::Tags::Manage qw(
    contains_data_item
    set_tag
);
use COD::CIF::Tags::Print qw( fold );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    append_changelog_to_single_item
    summarise_messages
);

##
# Records the changelog by appending the log messages to the value of
# the specified single-valued data item. Creates the specified data item
# if it does not yet exist in the data block.
#
# @param $data_block
#       Reference to data block as returned by the COD::CIF::Parser.
# @param $changelog
#       Reference to an array of changelog messages.
# @param $options
#       Reference to an option hash. The following options are
#       recognised:
#       {
#         # Name of the data item that stores the changelog.
#         # Default: '_cod_depositor_comments'.
#           'data_name' => '_cod_depositor_comments'
#         # Signature string of the entity that carried out the changes.
#         # The string will be appended to the changelog.
#         # Default: ''.
#           'signature' => 'Id: <program> <revision> <date> <user>'
#       }
##
sub append_changelog_to_single_item
{
    my( $data_block, $changelog, $options ) = @_;

    return if !@{$changelog};

    my $signature     = defined $options->{'signature'} ?
                                $options->{'signature'} : '';
    my $changelog_tag = defined $options->{'data_name'} ?
                                $options->{'data_name'} :
                                '_cod_depositor_comments';

    my $prefix = "\n";
    if( contains_data_item( $data_block, $changelog_tag ) ) {
        $prefix .= "\n";
    } else {
        set_tag( $data_block, $changelog_tag, '' );
    }

    my $title = 'The following automatic conversions were performed:';
    my $folded_changelog =
        join "\n",
            map { fold( 70, ' +', ' ', $_ ) }
                split m/\n/,
                    join "\n\n", @{$changelog};

    $signature =~ s/^\$|\$$//g;

    $data_block->{'values'}{$changelog_tag}[0] .=
        $prefix . $title . "\n\n" .
        $folded_changelog . "\n\n" .
        'Automatic conversion script' . "\n" .
        $signature;

    return;
}

##
# Groups identical messages together and replaces each group with a
# summarized version of the message.
# @param $messages
#       Reference to an array of error messages.
# @return $message_summary
#       Reference to an array of unique summary messages.
##
sub summarise_messages
{
    my ($messages) = @_;

    my %message_count;
    $message_count{$_}++ for @{$messages};

    my @message_summary;
    for my $message ( sort keys %message_count ) {
        my $count = $message_count{$message};
        if( $count > 1 ) {
            $message .= " ($count times)";
        }
        push @message_summary, $message;
    }

    return \@message_summary;
}

1;
