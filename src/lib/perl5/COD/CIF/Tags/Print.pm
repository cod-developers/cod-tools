#------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------
#*
#  CIF tag management functions that work on the internal representation
#  of a CIF file as returned by the COD::CIF::Parser module.
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
    my $is_save_block;

    $flags = {} unless $flags && ref $flags eq 'HASH';
    $fold_long_fields = $flags->{fold_long_fields}
        if defined $flags->{fold_long_fields};
    $folding_width = $flags->{folding_width}
        if defined $flags->{folding_width};
    %dictionary_tags = %{$flags->{dictionary_tags}}
        if defined $flags->{dictionary_tags};
    $is_save_block = $flags->{is_save_block}
        if defined $flags->{is_save_block};

    my $cif_version = '1.1';
    if( exists $dataset->{cifversion} ) {
        $cif_version =
            sprintf '%d.%d', $dataset->{cifversion}{major},
                             $dataset->{cifversion}{minor};
    }

    clean_cif( $dataset, $flags );

    if( !$is_save_block && int $cif_version > 1 ) {
        print '#\#CIF_', $cif_version, "\n";
    }

    if( defined $dataset->{name} ) {
        print $is_save_block ? 'save_' : 'data_', $dataset->{name}, "\n";
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
            print_tag( $tag, $datablok, $fold_long_fields,
                       $folding_width, $cif_version );
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
                print_loop( $dataset, $tag_loop_nr,
                            {
                               'fold_long_fields' => $fold_long_fields,
                               'folding_width'    => $folding_width,
                               'cif_version'      => $cif_version,
                            } );
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

    if( int $cif_version == 2 || !$is_save_block ) {
        for my $save_block (@{$dataset->{save_blocks}}) {
            print_cif( $save_block, { %$flags, is_save_block => 1 } );
        }
    }

    if( $is_save_block ) {
        print "save_\n";
    }
}

#
# Subroutines:
#

sub print_single_tag_and_value($$@)
{
    my ( $tag, $val, $fold_long_fields, $folding_width,
         $cif_version ) = @_;

    $fold_long_fields = 0
        unless defined $fold_long_fields;

    $folding_width = $default_folding_width
        unless defined $folding_width;

    my $value = sprint_value( $val, $fold_long_fields,
                              $folding_width, $cif_version );
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
    my ($key, $tags, $fold_long_fields, $folding_width, $cif_version ) = @_;

    if( exists $tags->{$key} ) {
        my $val = $tags->{$key};
        if( int(@{$val}) > 1 ) {
            print "loop_\n";
            print "$key\n";
            for my $value (@$val) {
                print_value( $value, $fold_long_fields,
                             $folding_width, $cif_version );
                print "\n";
            }
        } else {
            print_single_tag_and_value( $key, $val->[0], $fold_long_fields,
                                        $folding_width, $cif_version )
        }
    }
}

##
# Prints a CIF loop structure.
#
# @param $data_block
#       Reference to a data block as returned by the COD::CIF::Parser.
# @param $loop_nr
#       Index of the loop to be printed.
# @param $options
#       Reference to a hash containing the options that will be passed
#       to the sprint_value() subroutine.
##
sub print_loop
{
    my ( $data_block, $loop_nr, $options ) = @_;

    $options = {} unless $options;
    my $values = $data_block->{'values'};
    my @loop_tags = @{$data_block->{loops}[$loop_nr]};

    # Safeguard against a malformed looped structure
    my $max_column_index = 0;
    for ( my $i = 0; $i < @loop_tags; $i++ ) {
        if ( @{$values->{$loop_tags[$max_column_index]}} <
             @{$values->{$loop_tags[$i]}} ) {
            $max_column_index = $i;
        }
    };
    my $max_column_length = @{$values->{$loop_tags[$max_column_index]}};

    # Check if all looped data item contain the same amount of values
    for my $loop_tag (@loop_tags) {
        my $diff = $max_column_length - @{$values->{$loop_tag}};
        if ( $diff > 0 ) {
            warn "WARNING, data item '$loop_tag' contains less values than " .
                 "data item '$loop_tags[$max_column_index]' even though they " .
                 "reside in the same loop -- $diff question mark symbols " .
                 "('?') will be appended to the loop column '$loop_tag' " .
                 'instead of the missing values' . "\n";
            push @{$values->{$loop_tag}}, ( '?' ) x $diff;
        }
    }

    # Detect empty loops and attempt to fix them
    if( $max_column_length == 0 ) {
        local $" = "', '";
        warn "WARNING, loop of data items '@loop_tags' does not contain any " .
             "values -- a question mark symbol ('?') will be added as values " .
             'for each data item' . "\n";
        for my $loop_tag (@loop_tags) {
            push @{$values->{$loop_tag}}, '?';
        }
    }

    print "loop_\n";
    for (@loop_tags) {
        print $_, "\n";
    }

    my $value_array = $values->{$loop_tags[$max_column_index]};
    for my $i (0..$#{$value_array}) {
        print sprint_loop_packet($data_block, \@loop_tags, $i, $options );
    }

    return;
}

##
# Formats a single loop packet for printing.
#
# @param $data_block
#       Reference to a data block as returned by the COD::CIF::Parser.
# @param $loop_tags
#       Reference to an array of loop tags.
# @param $packet_index
#       Index of the packet to be printed.
# @param $options
#       Reference to a hash containing the options that will be passed
#       to the sprint_value() subroutine.
# @return $packet
#       Formatted string that contains the loop packet values.
##
sub sprint_loop_packet
{
    my ($data_block, $loop_tags, $packet_index, $options) = @_;

    my $line = '';
    my $packet = '';
    for my $loop_tag (@{$loop_tags}) {
        my $value = sprint_value(
                        $data_block->{'values'}{$loop_tag}[$packet_index],
                        $options->{'fold_long_fields'},
                        $options->{'folding_width'},
                        $options->{'cif_version'}
                    );
        # Process a multiline text field.
        if( $value =~ /^\n;/ ) {
            # Append and reset the current line.
            if( $line ne '' ) {
                $packet .= "\n";
                $packet .= $line;
                $line = '';
            }
            $packet .= $value;
        # Process a value that does not fit in the current line.
        } elsif( length( $line ) + length( $value ) + 1 >= $max_cif_line_len ) {
            # Append and reset the current line.
            if( $line ne '' ) {
                $packet .= "\n";
                $packet .= $line;
            }
            $line = $value;
        # Process a short value that fits in the current line.
        } else {
            # Separate values on the same line using spaces.
            if( $line ne '' ) {
                $line .= ' ';
            }
            $line .= $value;
        }
    }
    # Append the last line.
    if( $line ne '' ) {
        $packet .= "\n";
        $packet .= $line;
    }
    # Remove an extra leading newline that might have been added.
    $packet =~ s/^\n//;
    $packet .= "\n";

    return $packet;
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
    my ( $val, $fold_long_fields, $folding_width, $cif_version ) = @_;

    if( $cif_version && int $cif_version > 1 ) {
        if( ref $val eq 'ARRAY' ) {
            my @values;
            foreach (@$val) {
                push @values, sprint_value( $_, $fold_long_fields,
                                            $folding_width,
                                            $cif_version );
            }
            if( @values ) {
                return "\n[ @values ]";
            } else {
                return '[ ]';
            }
        } elsif( ref $val eq 'HASH' ) {
            my @values;
            foreach (sort keys %$val) {
                my $key = $_;
                if( ($key =~ /'''/ && $key =~ /"""/) ||
                    ($key =~ /'''/ && $key =~ /"$/) ||
                    ($key =~ /"""/ && $key =~ /'$/) ) {
                    die "ERROR, cannot store value '$key' " .
                        'in a quoted string' . "\n";
                } elsif( $key =~ /'/ && $key =~ /"/ && $key =~ /'$/ ) {
                    $key = '"""' . $key . '"""';
                } elsif( $key =~ /'/ && $key =~ /"/ && $key =~ /"$/ ) {
                    $key = "'''" . $key . "'''";
                } elsif( $key =~ /[\n\r]/ && $key =~ /'$/ ) {
                    $key = '"""' . $key . '"""';
                } elsif( $key =~ /[\n\r]/ ) {
                    $key = "'''" . $key . "'''";
                } elsif( $key =~ /'/ ) {
                    $key = '"' . $key . '"';
                } else {
                    $key = "'" . $key . "'";
                }
                push @values, "$key: " .
                              sprint_value( $val->{$_},
                                            $fold_long_fields,
                                            $folding_width,
                                            $cif_version );
            }
            if( @values ) {
                local $" = "\n";
                return "\n{\n@values\n}";
            } else {
                return '{}';
            }
        }
    }

    $fold_long_fields = 0
        unless defined $fold_long_fields;

    $folding_width = $default_folding_width
        unless defined $folding_width;

    if( $fold_long_fields && maxlen($val) > $folding_width - 2 ) {
        $val = join( "\n", map { " " . $_ }
                     fold( $folding_width - 1, " +", " ", $val ));
        $val =~ s/^\s+//g;
    }

    if( !$cif_version || int $cif_version == 1 ) {
        if( $val =~ /[\n\r]/ || $val =~ /^$/ ||
            ($val =~ /'\s/ && $val =~ /"\s/) ) {
            $val = "\n;" . $val . "\n;";
        } elsif( $val =~ /'\s/ || $val =~ /^'/ ) {
            $val = "\"" . $val . "\"";
        } elsif( $val =~ /"\s|^\#/ || $val =~ /^"/ ||
            $val =~ /^(data|loop|global|save)_/i ) {
            $val = "'" . $val . "'";
        } elsif( $val =~ /^'.*'$/ ) {
            $val = "\"" . $val . "\"";
        } elsif( $val =~ /\s|^_|^\[|^\]|^\$|^".*"$/) {
            $val = "'" . $val . "'";
        }
    } else {
        if( $val =~ /\n;/ ) {
            $val = "\n;" . prefix( $val ) . "\n;";
        } elsif( $val =~ /[\n\r]/ || $val =~ /"""/ || $val =~ /'''/ ) {
            $val = "\n;" . $val . "\n;";
        } elsif( $val =~ /'/ && $val =~ /"/ && $val =~ /[^']$/ ) {
            $val = "'''" . $val . "'''";
        } elsif( $val =~ /'/ && $val =~ /"/ && $val =~ /[^"]$/ ) {
            $val = "\"\"\"" . $val . "\"\"\"";
        } elsif( $val =~ /'/ ) {
            $val = "\"" . $val . "\"";
        } elsif( $val =~ /"/ || $val =~ /^[#\$_]/ || $val eq '' ||
            $val =~ /[\s\[\]\{\}]/ ||
            $val =~ /^(data|loop|global|save|stop)_/i ) {
            $val = "'" . $val . "'";
        }
    }
    return $val;
}

sub fold
{
    my ( $length, $separator, $ors, $string ) = @_;
    my @lines = ();
    my $line = "";

    for my $word (split( $separator, $string )) {
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

sub prefix
{
    my ( $value ) = @_;
    my $prefix = ' ' x 4;
    my @lines = map { $prefix . $_ } split( "\n", $value );
    unshift @lines, $prefix . '\\';
    return join "\n", @lines;
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
