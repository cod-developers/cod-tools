#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------
#* 
#  CIF comparison functions that work on the internal
#  representation of a CIF file returned by the CIFParser module.
#**

package COD::CIFData::CIFDiff;

use strict;
use COD::CIFTags::CIFTagPrint;

require Exporter;
@COD::CIFData::CIFDiff::ISA = qw(Exporter);
@COD::CIFData::CIFDiff::EXPORT = qw( diff comm );

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
            print "number of values for "
                . "tag " . $line->[0]
                . " is different\n";
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

    my( @tags1, @tags2 );
    if( defined $options->{compare_only} ) {
        my %compare_only = map{ $_ => 1 } @{$options->{compare_only}};
        foreach( keys %{$cif1->{values}} ) {
            if( exists $compare_only{$_} ) {
                push( @tags1, $_ );
            }
        }
        foreach( keys %{$cif2->{values}} ) {
            if( exists $compare_only{$_} ) {
                push( @tags2, $_ );
            }
        }
    } else {
        @tags1 = keys %{$cif1->{values}};
        @tags2 = keys %{$cif2->{values}};
    }
    @tags1 = sort @tags1;
    @tags2 = sort @tags2;
    PAIR_OF_TAGS:
    while( @tags1 > 0 || @tags2 > 0 ) {
        if( scalar @tags1 == 0 ) {
            push( @$comm, [ undef, undef, $tags2[0] ] ) unless $no_left;
            shift @tags2;
            next;
        }
        if( scalar @tags2 == 0 ) {
            push( @$comm, [ $tags1[0], undef, undef ] ) unless $no_right;
            shift @tags1;
            next;
        }
        if( $tags1[0] ne $tags2[0] ) {
            if( $tags1[0] lt $tags2[0] ) {
                push( @$comm, [ $tags1[0], undef, undef ] ) unless $no_left;
                shift @tags1;
            } else {
                push( @$comm, [ undef, undef, $tags2[0] ] ) unless $no_right;
                shift @tags2;
            }
            next;
        }
        if( scalar @{$cif1->{values}{$tags1[0]}} !=
            scalar @{$cif2->{values}{$tags2[0]}} ) {
            push( @$comm, [ $tags1[0], undef, $tags2[0] ] );
            shift @tags1;
            shift @tags2;
            next;
        }
        my $is_different;
        for( my $i = 0; $i < @{$cif1->{values}{$tags1[0]}}; $i++ ) {
            if( exists $comparators->{$tags1[0]} ) {
                if( &{ $comparators->{$tags1[0]} }(
                    $cif1->{values}{$tags1[0]}[$i],
                    $cif2->{values}{$tags2[0]}[$i] ) != 0 ) {
                    push( @$comm, [ $tags1[0], undef, $tags2[0] ] );
                    shift @tags1;
                    shift @tags2;
                    next PAIR_OF_TAGS;
                }
            } else {
                if( $cif1->{values}{$tags1[0]}[$i] ne
                    $cif2->{values}{$tags2[0]}[$i] ) {
                    push( @$comm, [ $tags1[0], undef, $tags2[0] ] );
                    shift @tags1;
                    shift @tags2;
                    next PAIR_OF_TAGS;
                }
            }
        }
        push( @$comm, [ undef, $tags1[0], undef ] ) unless $no_common;
        shift @tags1;
        shift @tags2;
    }
    return $comm;
}

1;
