#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------
#* 
#  CIF tag management functions that work on the internal
#  representation of a CIF file returned by the CIFParser module.
#**

package COD::CIF::Tags::Print;

use strict;
use warnings;

use COD::CIF::Tags::Manage qw( clean_cif );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    print_cif
    print_single_tag_and_value
    print_tag
    print_value
    pack_precision
    fold
);

our $max_cif_line_len = 80;
our $default_folding_width = $max_cif_line_len - 1;
our $max_cif_tag_len = 32;

sub print_cif
{
    my ( $dataset, $flags ) = @_;
    my $datablok = $dataset->{values};

    my %dictionary_tags = ();

    my $fold_long_fields = 0;
    my $folding_width;

    if( $flags && ref $flags eq "HASH" ) {
        $fold_long_fields = $flags->{fold_long_fields}
            if defined $flags->{fold_long_fields};
        $folding_width = $flags->{folding_width}
            if defined $flags->{folding_width};
        %dictionary_tags = %{$flags->{dictionary_tags}}
            if defined $flags->{dictionary_tags};
    }

    clean_cif( $dataset, $flags );

    if( defined $dataset->{name} ) {
        print "data_", $dataset->{name}, "\n";
    }

    my $tag_msg = "Tags that were not found in dictionaries";
    my $loop_tag_msg = "Loops that were not found in dictionaries";

    my $non_loop_tags_encountered = 0;
    my $loop_tags_encountered = 0;
    my %printed_loops;
    for my $tag (@{$dataset->{tags}}) {
        if( !exists $dataset->{inloop}{$tag} ) {
            if( !exists $dictionary_tags{$tag} ) {
                if( !$non_loop_tags_encountered &&
                    %dictionary_tags ) {
                    print "#BEGIN $tag_msg:\n";
                    $non_loop_tags_encountered = 1;
                }
            } else {
                if( $non_loop_tags_encountered ) {
                    print "#END $tag_msg\n";
                    $non_loop_tags_encountered = 0;
                }
            }
            print_tag( $tag, $datablok,
                       $fold_long_fields, $folding_width );
        } else {
            if( $non_loop_tags_encountered ) {
                print "#END $tag_msg\n";
                $non_loop_tags_encountered = 0;
            }
            my $tag_loop_nr = $dataset->{inloop}{$tag};
            if( !exists $dictionary_tags{$tag} ) {
                if( !$loop_tags_encountered &&
                    %dictionary_tags &&
                    !exists $printed_loops{$tag_loop_nr} ) {
                    print "#BEGIN $loop_tag_msg:\n";
                    $loop_tags_encountered = 1;
                }
            } else {
                if( $loop_tags_encountered ) {
                    print "#END $loop_tag_msg\n";
                    $loop_tags_encountered = 0;
                }
            }
            unless( exists $printed_loops{$tag_loop_nr} ) {
                print_loop( $tag, $tag_loop_nr, $dataset,
                            $fold_long_fields, $folding_width );
                $printed_loops{$tag_loop_nr} = 1;
            }
        }
    }

    if( $non_loop_tags_encountered ) {
        print "#END $tag_msg\n";
    }
    if( $loop_tags_encountered ) {
        print "#END $loop_tag_msg\n";
    }
}

#
# Subroutines:
#

sub print_single_tag_and_value($$@)
{
    my ( $tag, $val, $fold_long_fields, $folding_width ) = @_;

    $fold_long_fields = 0
        unless defined $fold_long_fields;

    $folding_width = $default_folding_width
        unless defined $folding_width;

    my $value = sprint_value( $val, $fold_long_fields, $folding_width );
    my $key_len = length($tag) > $max_cif_tag_len ?
                                     length($tag) : $max_cif_tag_len;
    my $val_len = length($value);

    if( $value =~ /\s/ ) {
        $val_len += 2;
    }
    if( $key_len + $val_len + 1 > $max_cif_line_len && $value !~ /\n/ ) {
        printf "%s\n", $tag;
    } else {
        if( $value !~ /\n/ ) {
            printf "%-" . $max_cif_tag_len . "s ", $tag;
        } else {
            printf "%s", $tag;
        }
    }
    print $value, "\n";
}

sub print_tag
{
    my ($key, $tags, $fold_long_fields, $folding_width ) = @_;

    if( exists $tags->{$key} ) {
        my $val = $tags->{$key};
        if( int(@{$val}) > 1 ) {
            print "loop_\n";
            print "$key\n";
            for my $value (@$val) {
                print_value( $value, $fold_long_fields, $folding_width );
                print "\n";
            }
        } else {
            print_single_tag_and_value( $key, $val->[0], $fold_long_fields,
                                        $folding_width   )
        }
    }
}

sub print_loop
{
    my ($tag, $loop_nr, $tags, $fold_long_fields, $folding_width ) = @_;

    my @loop_tags = @{$tags->{loops}[$loop_nr]};

    print "loop_\n";
    for (@loop_tags) {
        print $_, "\n";
    }

    my $val_array = $tags->{values}{$tag};
    my $last_val = $#{$val_array};

    my $line_prefix = "";
    for my $i (0..$last_val) {
        my $folding_separator = "";
        my $lines = "";
        my $line = $line_prefix;
        for my $loop_tag (@loop_tags) {
            my $val = sprint_value( $tags->{values}{$loop_tag}[$i],
                                    $fold_long_fields, $folding_width );
            if( $val =~ /^\n;/ ) {
                $lines .= $folding_separator . $line if $line ne $line_prefix;
                if( $lines eq "" ) {
                    # don't print extra newline at the beginning of the loop:
                    $val =~ s/^\n//;
                }
                $lines .= $val;
                $line = $line_prefix;
                $folding_separator = "\n";
            } elsif( length( $line ) + length( $val ) + 1 < $max_cif_line_len ) {
                if( $line eq $line_prefix ) {
                    $line .= $val;
                } else {
                    $line .= " " . $val;
                }
            } else {
                $lines .= $folding_separator . $line;
                $line = $line_prefix . $val;
                $folding_separator = "\n";
            }
        }
        if( $line ne $line_prefix ) {
            $lines .= $folding_separator . $line;
        }
        print $lines;
        print "\n";
    }
}

sub print_value
{
    print &sprint_value
}

sub maxlen
{
    my $val = $_[0];
    my $len = 0;

    for (split( "\n", $val )) {
        $len = length if length > $len;
    }
    return $len;
}

sub sprint_value
{
    my ( $val, $fold_long_fields, $folding_width ) = @_;

    $fold_long_fields = 0
        unless defined $fold_long_fields;

    $folding_width = $default_folding_width
        unless defined $folding_width;

    if( $fold_long_fields && maxlen($val) > $folding_width - 2 ) {
        $val = join( "\n", map { " " . $_ }
                     fold( $folding_width - 1, " +", " ", $val ));
        $val =~ s/^\s+//g;
    }

    if( $val =~ /\n/ || $val =~ /^$/ ||
        ($val =~ /'\s/ && $val =~ /"\s/) ) {
        $val = "\n;" . $val . "\n;";
    } elsif( $val =~ /'\s/ || $val =~ /^'/ ) {
        $val = "\"" . $val . "\"";
    } elsif( $val =~ /"\s|^\#/ || $val =~ /^"/ ||
        $val =~ /^(data|loop|global|save)_/i ) {
        $val = "'" . $val . "'";
    } elsif( $val =~ /^'.*'$/ ) {
        $val = "\"" . $val . "\"";
    } elsif( $val =~ /\s|^_|^\[|^\$|^".*"$/) {
        $val = "'" . $val . "'";
    }
    return $val;
}

sub fold
{
    my ( $length, $separator, $ors, $string ) = @_;
    my @lines = ();
    my $line = "";

    my $word;
    for $word (split( $separator, $string )) {
        $word =~ s/^\s*|\s*$//g;
        if( !$line ) {
            $line = $word;
        } else {
            my $new_line = "$line$ors$word";
            if( length($new_line) < $length ) {
                $line = $new_line;
            } else {
                push( @lines, $line );
                $line = $word;
            }
        }
    }
    push( @lines, $line );
    return @lines;
}

sub round { $_[0] > 0 ? int($_[0] + 0.5) : int($_[0] - 0.5) }

sub pack_precision
{
    my ( $val, $sig ) = @_;

    if( defined $sig ) {
        my $digits = -round(log($sig)/log(10)) + 1;
        ## print ">>> $val +/- $sig (log = " . log($sig)/log(10) . "), digits = $digits\n";
        my $prec = round( $sig * 10**$digits );
        if( $prec >= 20 ) {
            $digits --;
            $prec = round( $sig * 10**$digits );
        }
        my $format_digits = $digits > 0 ? $digits : 0;
        $val = sprintf( "%.${format_digits}f", $val );
        return "$val($prec)";
    } else {
        return $val;
    }
}

1;
