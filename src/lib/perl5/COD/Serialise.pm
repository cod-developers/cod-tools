#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------

package COD::Serialise;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    serialiseHash
    serialiseArray
    serialiseRef
    serialiseScalar
);

my $separator = "#-------------------------\n";

sub serialiseRef
{
    my ($ref, $indent, $fd) = @_;
    $indent = "" unless defined $indent;
    $fd = \*STDOUT unless defined $fd;

    if( ref($ref) eq "ARRAY" ) {
        &serialiseArray( $ref, $indent, $fd );
    } elsif( ref($ref) eq "HASH" ) {
        &serialiseHash( $ref, $indent, $fd );
    } elsif( ref($ref) eq "SCALAR" ) {
        &serialiseScalar( $ref, $indent, $fd );
    } else {
        print $fd $ref;
    }
}

sub serialiseHash
{
    my ($hash, $indent, $fd) = @_;
    $indent = "" unless defined $indent;
    $fd = \*STDOUT unless defined $fd;

    ## printf $fd "\n" unless $indent eq "";
    ## print $fd $indent, "{\n";
    print $fd "{\n";
    my $old_indent = $indent;
    $indent .= " " x 3;
    foreach my $key ( sort {$a cmp $b} keys %{$hash} ) {
        printf $fd "%s%-5s => ", $indent, '"' . $key . '"';
        if( ref $hash->{$key} eq "HASH" ) {
            serialiseHash( $hash->{$key}, $indent, $fd );
        } elsif( ref $hash->{$key} eq "ARRAY" ) {
            serialiseArray( $hash->{$key}, $indent, $fd );
        } elsif( ref $hash->{$key} eq "SCALAR" ) {
            serialiseScalar( $hash->{$key}, $indent, $fd );
        } else {
            if( defined $hash->{$key} ) {
                printf $fd "\"%s\",\n", $hash->{$key};
            } else {
                print $fd "undef,\n";
            }
        }
    }
    print $fd $old_indent, "},\n";
    print $fd $separator if $old_indent eq "";
}

sub serialiseArray
{
    my ($array, $indent, $fd) = @_;
    $indent = "" unless defined $indent;
    $fd = \*STDOUT unless defined $fd;

    my $isFlat = 1;
    if( int(@{$array}) > 100 ) {
        $isFlat = 0;
    } else {
        foreach my $item ( @{$array} ) {
            if( defined $item && (ref $item or length($item) > 20 )) {
                $isFlat = 0; last;
            }
        }
    }
    my $old_indent = $indent;
    if( $isFlat ) {
        local $" = ", ";
        my @val = map { defined $_ ? "\"$_\"" : "undef" } @{$array};
        print $fd "[ @val ],\n";
    } else {
        ## printf $fd "\n" unless $indent eq "";
        ## print $fd $indent, "[\n";
        print $fd "[\n";

        $indent .= " " x 3;
        my $index = 0;
        foreach my $item ( @{$array} ) {
            if( ref $item eq "HASH" ) {
                printf $fd "%s# %3d:\n%s", $indent, $index++, $indent;
                serialiseHash( $item, $indent, $fd );
            } elsif( ref $item eq "ARRAY" ) {
                printf $fd "%s# %3d:\n%s", $indent, $index++, $indent;
                serialiseArray( $item, $indent, $fd );
            } elsif( ref $item eq "SCALAR" ) {
                printf $fd "%s# %3d:\n%s", $indent, $index++, $indent;
                serialiseScalar( $item, $indent, $fd );
            } else {
                if( defined $item ) {
                    printf $fd "%s# %3s:\n%s\"%s\",\n", $indent, $index++,
                    $indent, $item;
                } else {
                    printf $fd "%s# %3s:\n%s%s,\n", $indent, $index++,
                    $indent, "undef";
                }
            }
        }
        print $fd $old_indent, "],\n";
    }
    print $fd $separator if $old_indent eq "";
}

sub serialiseScalar
{
    my ($scalar, $indent, $fd) = @_;
    $indent = "" unless defined $indent;
    $fd = \*STDOUT unless defined $fd;

    my $value = $$scalar;

    if( ref $value ) {
        serialiseRef( $value, $indent, $fd );
    } else {
        print $fd '\"', $$scalar, '",', "\n";
    }
}

1;
