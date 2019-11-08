#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------
#* 
#  CIF comparison functions that work on the internal representation of
#  a CIF file returned by the COD::CIF::Parser module.
#**

package COD::CIF::Data::Diff;

use strict;
use warnings;
use COD::CIF::Tags::Manage qw( tag_is_empty );
use COD::CIF::Tags::Print qw( print_tag );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    diff
    comm
);

sub diff
{
    my( $cif1, $cif2, $options ) = @_;
    $options = {} unless defined $options;
    $options->{compare_datablock_names} = 1
        unless exists $options->{compare_datablock_names};
    $options->{fold} = 1 unless exists $options->{fold};
    $options->{fold_width} = 72 unless exists $options->{fold_width};

    if( $options->{compare_datablock_names}
        && $cif1->{name} ne $cif2->{name} ) {
        print "<data_" . $cif1->{name} . "\n";
        print ">data_" . $cif2->{name} . "\n";
    }

    my $comm = comm( $cif1, $cif2, $options );
    foreach my $line ( @$comm ) {
        if( defined $line->[0] && defined $line->[2] &&
            $line->[0] eq $line->[2] &&
            @{$cif1->{values}{$line->[0]}} !=
            @{$cif2->{values}{$line->[0]}} ) {
            print "the number of '$line->[0]' data item values differs "
                 . "between datablocks\n";
            next;
        }
        if( defined $line->[0] ) {
            print "<";
            print_tag( $line->[0], $cif1->{values},
                $options->{fold}, $options->{folding_width} );
        }
        if( defined $line->[2] ) {
            print ">";
            print_tag( $line->[2], $cif2->{values},
                $options->{fold}, $options->{folding_width} );
        }
    }
}

sub comm
{
    my( $cif1, $cif2, $options ) = @_;
    $options = {} unless defined $options;
    my $comm = [];
    my $comparators = {};
    if( defined $options->{comparators} ) {
        $comparators = $options->{comparators};
    }

    my( $no_right, $no_left, $no_common );
    $no_right = (exists $options->{suppress_right})
        ? $options->{suppress_right} : 0;
    $no_left = (exists $options->{suppress_left})
        ? $options->{suppress_left} : 0;
    $no_common = (exists $options->{suppress_common})
        ? $options->{suppress_common} : 0;

    my @tags1 = keys %{$cif1->{values}};
    my @tags2 = keys %{$cif2->{values}};
    if( defined $options->{compare_only} ) {
        my %compare_only = map { $_ => 1 } @{$options->{compare_only}};
        @tags1 = grep { exists $compare_only{$_} } @tags1;
        @tags2 = grep { exists $compare_only{$_} } @tags2;
    }
    if( defined $options->{compare_not} ) {
        my %compare_not = map { $_ => 1 } @{$options->{compare_not}};
        @tags1 = grep { !exists $compare_not{$_} } @tags1;
        @tags2 = grep { !exists $compare_not{$_} } @tags2;
    }
    @tags1 = sort @tags1;
    @tags2 = sort @tags2;
    PAIR_OF_TAGS:
    while( @tags1 > 0 || @tags2 > 0 ) {
        if( !@tags1 ) {
            my $tag = shift @tags2;
            if( $options->{ignore_empty_values} &&
                tag_is_empty( $cif2, $tag ) ) {
                next;
            }
            push @$comm, [ undef, undef, $tag ] unless $no_left;
            next;
        }
        if( !@tags2 ) {
            my $tag = shift @tags1;
            if( $options->{ignore_empty_values} &&
                tag_is_empty( $cif1, $tag ) ) {
                next;
            }
            push @$comm, [ $tag, undef, undef ] unless $no_right;
            next;
        }
        if( $tags1[0] ne $tags2[0] ) {
            if( $tags1[0] lt $tags2[0] ) {
                my $tag = shift @tags1;
                if( $options->{ignore_empty_values} &&
                    tag_is_empty( $cif1, $tag ) ) {
                    next;
                }
                push @$comm, [ $tag, undef, undef ] unless $no_left;
            } else {
                my $tag = shift @tags2;
                if( $options->{ignore_empty_values} &&
                    tag_is_empty( $cif2, $tag ) ) {
                    next;
                }
                push @$comm, [ undef, undef, $tag ] unless $no_right;
            }
            next;
        }

        my $values1 = $cif1->{values};
        my $values2 = $cif2->{values};
        if( scalar @{$values1->{$tags1[0]}} !=
            scalar @{$values2->{$tags2[0]}} ) {
            push @$comm, [ shift @tags1, undef, shift @tags2 ];
            next;
        }

        my $comparator = \&cmp_text;
        if( exists $comparators->{$tags1[0]} ) {
            $comparator = $comparators->{$tags1[0]};
        }
        for( my $i = 0; $i < @{$values1->{$tags1[0]}}; $i++ ) {
            if( &$comparator( $values1->{$tags1[0]}[$i],
                              $values2->{$tags2[0]}[$i] ) != 0 ) {
                push @$comm, [ shift @tags1, undef, shift @tags2 ];
                next PAIR_OF_TAGS;
            }
        }
        push @$comm, [ undef, $tags1[0], undef ] unless $no_common;
        shift @tags1;
        shift @tags2;
    }
    return $comm;
}

sub cmp_text
{
    return $_[0] cmp $_[1];
}

1;
