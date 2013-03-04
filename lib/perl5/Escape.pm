#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Subroutines to perform escaping and unescaping of strings
#**

package Escape;

use strict;
use warnings;

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

1;
