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

package COD::CIFTags::CIFTagPrint;

use strict;

require Exporter;
@COD::CIFTags::CIFTagPrint::ISA = qw(Exporter);
@COD::CIFTags::CIFTagPrint::EXPORT =
    qw( print_cif print_single_tag_and_value print_tag print_value
        get_tag_print_order pack_precision fold );

$COD::CIFTags::CIFTagPrint::max_cif_line_len = 80;
$COD::CIFTags::CIFTagPrint::default_folding_width =
    $COD::CIFTags::CIFTagPrint::max_cif_line_len - 1;
$COD::CIFTags::CIFTagPrint::max_cif_tag_len = 32;

sub print_cif
{
    my ( $dataset, $flags ) = @_;
    my $datablok = $dataset->{values};

    my @dictionary_tags;
    my %dictionary_tags;

    my ( $exclude_misspelled_tags, $preserve_loop_order ) = ( 0 ) x 2;
    my $fold_long_fields = 0;
    my $keep_tag_order = 0;
    my $folding_width;

    if( $flags && ref $flags eq "HASH" ) {
        $exclude_misspelled_tags = $flags->{exclude_misspelled_tags};
        $preserve_loop_order = $flags->{preserve_loop_order};
        $fold_long_fields = $flags->{fold_long_fields}
            if defined $flags->{fold_long_fields};
        $folding_width = $flags->{folding_width}
            if defined $flags->{folding_width};
        %dictionary_tags = %{$flags->{dictionary_tags}}
            if defined $flags->{dictionary_tags};
        @dictionary_tags = @{$flags->{dictionary_tag_list}}
            if defined $flags->{dictionary_tag_list};
        $keep_tag_order = $flags->{keep_tag_order}
            if defined $flags->{keep_tag_order};
    }

    my $print_order = get_tag_print_order( $dataset,
                                           \%dictionary_tags,
                                           \@dictionary_tags,
                                           $keep_tag_order,
                                           $preserve_loop_order );

    if( defined $dataset->{name} ) {
        print "data_", $dataset->{name}, "\n";
    }

    for my $value_type ('tags', 'loops') {
        for my $status ('dictionary', 'non_dictionary') {
            next if $status eq 'non_dictionary' && $exclude_misspelled_tags;
            my @tag_list = @{$print_order->{$value_type}{$status}};
            if( $status eq 'non_dictionary' && @tag_list ) {
                print "#BEGIN " . ucfirst( $value_type ) . " that were " .
                      "not found in dictionaries:\n";
            }
            for my $tag (@tag_list) {
                if( exists $dataset->{inloop}{$tag} ) {
                    my $tag_loop_nr = $dataset->{inloop}{$tag};
                    print_loop( $tag, $tag_loop_nr, $dataset,
                                $fold_long_fields, $folding_width );
                } else {
                    print_tag( $tag, $datablok,
                               $fold_long_fields, $folding_width );
                }
            }
            if( $status eq 'non_dictionary' && @tag_list ) {
                print "#END " . ucfirst( $value_type ) . " that were " .
                      "not found in dictionaries\n";
            }
        }
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

    $folding_width = $COD::CIFTags::CIFTagPrint::default_folding_width
        unless defined $folding_width;

    my $value = sprint_value( $val, $fold_long_fields, $folding_width );
    my $key_len = length($tag) > $COD::CIFTags::CIFTagPrint::max_cif_tag_len ?
        length($tag) : $COD::CIFTags::CIFTagPrint::max_cif_tag_len;
    my $val_len = length($value);

    if( $value =~ /\s/ ) {
        $val_len += 2;
    }
    if( $key_len + $val_len + 1 >
        $COD::CIFTags::CIFTagPrint::max_cif_line_len &&
        $value !~ /\n/ ) {
        printf "%s\n", $tag;
    } else {
        if( $value !~ /\n/ ) {
            printf "%-" . $COD::CIFTags::CIFTagPrint::max_cif_tag_len . "s ", $tag;
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
            } elsif( length( $line ) + length( $val ) + 1 
                     < $COD::CIFTags::CIFTagPrint::max_cif_line_len ) {
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

sub get_tag_print_order
{
    my( $dataset, $dictionary_tags, $dictionary_tag_list, $keep_tag_order,
        $preserve_loop_order ) = @_;

    my $datablok = $dataset->{values};

    my @dictionary_tags;
    my %dictionary_tags = ();

    @dictionary_tags = @$dictionary_tag_list if $dictionary_tag_list;
    %dictionary_tags = %$dictionary_tags if $dictionary_tags;

    if( !@dictionary_tags ) {
        @dictionary_tags = sort {$a cmp $b} keys %dictionary_tags;
    }

    my @tags_to_print = ();

    if( $keep_tag_order ) {
        @tags_to_print = @{$dataset->{tags}};
        if( !%dictionary_tags ) {
            %dictionary_tags = map {($_,$_)} @tags_to_print;
        }
    } else {
        @tags_to_print = @dictionary_tags;
    }

    my %printed_loops = ();

    # Extract tags, that are found in dictionaries:

    my @dictionary_tag_order;
    for my $tag (@tags_to_print) {
        if( defined $datablok->{$tag} ) {
            if( exists $dictionary_tags{$tag} &&
                !exists $dataset->{inloop}{$tag} ) {
                push( @dictionary_tag_order, $tag );
            } elsif( $tag eq "_publ_author_name" ) {
                my $tag_loop_nr = $dataset->{inloop}{$tag};
                unless( exists $printed_loops{$tag_loop_nr} ) {
                    push( @dictionary_tag_order, $tag );
                    $printed_loops{$tag_loop_nr} = 1;
                }
            }
        }
    }

    # Extract tags that are not in the dictionary (most probably
    # some misspelled tags):

    my @non_dictionary_tag_order;
    if( %dictionary_tags ) {
        for my $tag (@{$dataset->{tags}}) {
            if( !exists $dictionary_tags{$tag} &&
                !exists $dataset->{inloop}{$tag} ) {
                push( @non_dictionary_tag_order, $tag );
            }
        }
    }

    my @tags_for_output;

    if( $preserve_loop_order ) {
        @tags_for_output = @{$dataset->{tags}}
    } else {
        @tags_for_output = @dictionary_tags;
    }

    # Extract loops, that contain at least one dictionary tag:

    my @dictionary_loop_order;
    for my $tag (@tags_for_output) {
        if( defined $datablok->{$tag} ) {
            if( exists $dataset->{inloop}{$tag} ) {
                my $tag_loop_nr = $dataset->{inloop}{$tag};
                unless( exists $printed_loops{$tag_loop_nr} ) {
                    push( @dictionary_loop_order, $tag );
                    $printed_loops{$tag_loop_nr} = 1;
                }
            }
        }
    }

    # Extract loops, that contain only non-dictionary tags:

    my @non_dictionary_loop_order;
    if( %dictionary_tags ) {
        for my $tag (@{$dataset->{tags}}) {
            if( exists $dataset->{inloop}{$tag} && 
                ! exists $dictionary_tags{$tag} ) {
                my $tag_loop_nr = $dataset->{inloop}{$tag};
                unless( exists $printed_loops{$tag_loop_nr} ) {
                    push( @non_dictionary_loop_order, $tag );
                    $printed_loops{$tag_loop_nr} = 1;
                }
            }
        }
    }

    return {
        tags => {
            dictionary     => \@dictionary_tag_order,
            non_dictionary => \@non_dictionary_tag_order,
        },
        loops => {
            dictionary     => \@dictionary_loop_order,
            non_dictionary => \@non_dictionary_loop_order,
        },
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

    $folding_width = $COD::CIFTags::CIFTagPrint::default_folding_width
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
    my $length = shift;
    my $separator = shift;
    my $ors = shift;
    my $string = shift;
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
