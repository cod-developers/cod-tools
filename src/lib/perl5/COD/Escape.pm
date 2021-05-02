#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Subroutines to perform escaping and unescaping of strings
#**

package COD::Escape;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    escape
    unescape
    decode_textfield
);

use HTML::Entities qw( encode_entities decode_entities );
use IO::Uncompress::Gunzip qw( gunzip $GunzipError );
use MIME::Base64 qw( decode_base64 );
use MIME::QuotedPrint qw( decode_qp );

sub unescape_special
{
    my( $specials, $symbol ) = @_;
    if( exists $specials->{$symbol} ) {
        return $specials->{$symbol};
    } else {
        return $symbol;
    }
}

sub escape
{
    my( $text, $options ) = @_;
    $options = {} unless defined $options;
    my $plain_seq = (exists $options->{sequence})
        ? $options->{sequence} : '\\';
    my $seq = quotemeta( $plain_seq );
    $options->{escaped_symbols} = {}
        unless exists $options->{escaped_symbols};
    $text =~ s,($seq+),$plain_seq x (2 * length($1)),ge;
    foreach( keys %{ $options->{escaped_symbols} } ) {
        my $sym = quotemeta( $_ );
        $text =~ s,$sym,$plain_seq$options->{escaped_symbols}{$_},g;
    }
    return $text;
}

sub unescape
{
    my( $text, $options ) = @_;
    $options = {} unless defined $options;
    my $plain_seq = (exists $options->{sequence})
        ? $options->{sequence} : '\\';
    my $seq = quotemeta( $plain_seq );
    my $escaped_symbols = (exists $options->{escaped_symbols})
        ? $options->{escaped_symbols} : {};
    $text =~ s|((?:$seq$seq)*)(?:$seq([^$seq]))|
                $plain_seq x (length($1)/2) .
                unescape_special($escaped_symbols, $2)|ge;
    return $text;
}

sub decode_textfield
{
    my( $content, $encoding ) = @_;
    return $content if !$encoding;

    if(      $encoding eq 'base64' ) {
        return decode_base64($content);
    } elsif( $encoding eq 'quoted-printable' ) {
        return decode_qp($content);
    } elsif( $encoding eq 'ncr' ) {
        # Decoding all XML entities and encoding non-ASCII symbols
        # back in order to make the CIF file valid.
        return encode_entities( decode_entities( $content ),
                                '^\n\x09\x0a\x0d\x20-\x7e' );
    } elsif( $encoding eq 'gzip' ) {
        my $decoded;
        gunzip( \$content, \$decoded ) or die $GunzipError;
        return $decoded;
    } else {
        die "ERROR, unknown contents encoding '$encoding'" . "\n";
    }
}

1;
