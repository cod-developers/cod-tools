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

package CIFTagPrint;

use strict;

require Exporter;
@CIFTagPrint::ISA = qw(Exporter);
@CIFTagPrint::EXPORT = qw( print_cif print_single_tag_and_value );

$CIFTagPrint::max_cif_line_len = 80;
$CIFTagPrint::default_folding_width = $CIFTagPrint::max_cif_line_len - 1;
$CIFTagPrint::max_cif_tag_len = 32;

sub print_cif
{
    my ( $dataset, $flags ) = @_;
    my $datablok = $dataset->{values};

    my @dictionary_tags;
    my %dictionary_tags = ();

    my ( $exclude_misspelled_tags, $preserve_loop_order ) = ( 0 ) x 2;
    my $fold_long_fields = 1;
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

    if( !@dictionary_tags ) {
	@dictionary_tags = sort {$a cmp $b} keys %dictionary_tags;
    }

    my @tags_to_print = ();

    if( $keep_tag_order ) {
	@tags_to_print = @{$dataset->{tags}};
    } else {
	@tags_to_print = @dictionary_tags;
    }

    my %printed_loops = ();

    if( defined $dataset->{name} ) {
	print "data_", $dataset->{name}, "\n";
    }

    for my $tag (@tags_to_print) {
	if( defined $datablok->{$tag} ) {
	    if( !exists $dataset->{inloop}{$tag} ) {
		print_tag( $tag, $datablok,
			   $fold_long_fields, $folding_width );
	    } elsif( $tag eq "_publ_author_name" ) {
		my $tag_loop_nr = $dataset->{inloop}{$tag};
		unless( exists $printed_loops{$tag_loop_nr} ) {
		    print_loop( $tag, $tag_loop_nr, $dataset,
				$fold_long_fields, $folding_width );
		    $printed_loops{$tag_loop_nr} = 1;
		}
	    }
	}
    }

    # Print out any tags that are not in the dictionary (most probably
    # some misspelled tags):

    if( !$exclude_misspelled_tags ) {
	my $tags_encountered = 0;
	for my $tag (@{$dataset->{tags}}) {
	    if( !exists $dictionary_tags{$tag} &&
		!exists $dataset->{inloop}{$tag} ) {
		if( !$tags_encountered ) {
		    print "#BEGIN Tags that were not found in dictionaries:\n";
		    $tags_encountered = 1;
		}
		print_tag( $tag, $datablok, $fold_long_fields,
                           $folding_width );
	    }
	}
	if( $tags_encountered ) {
	    print "#END Tags that were not found in dictionaries\n";
	}
    }

    # Print out loops:

    my @tags_for_output;

    if( $preserve_loop_order ) {
	@tags_for_output = @{$dataset->{tags}}
    } else {
	@tags_for_output = @dictionary_tags;
    }

    for my $tag (@tags_for_output) {
	if( defined $datablok->{$tag} ) {
	    if( exists $dataset->{inloop}{$tag} ) {
		my $tag_loop_nr = $dataset->{inloop}{$tag};
		unless( exists $printed_loops{$tag_loop_nr} ) {
		    print_loop( $tag, $tag_loop_nr, $dataset,
                                $fold_long_fields, $folding_width );
		    $printed_loops{$tag_loop_nr} = 1;
		}
	    }
	}
    }

    # Print out loops that contain only non-dictionary tags:

    if( !$exclude_misspelled_tags ) {
	my $tags_encountered = 0;
	for my $tag (@{$dataset->{tags}}) {
	    if( exists $dataset->{inloop}{$tag} && 
		! exists $dictionary_tags{$tag} ) {
		my $tag_loop_nr = $dataset->{inloop}{$tag};
		unless( exists $printed_loops{$tag_loop_nr} ) {
		    if( !$tags_encountered ) {
			print "#BEGIN Loops that were not found in " .
			    "dictionaries:\n";
			$tags_encountered = 1;
		    }
		    print_loop( $tag, $tag_loop_nr, $dataset,
                                $fold_long_fields, $folding_width );
		    $printed_loops{$tag_loop_nr} = 1;
		}
	    }
	}
	if( $tags_encountered ) {
	    print "#END Loops that were not found in dictionaries\n";
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

    $folding_width = $CIFTagPrint::default_folding_width
        unless defined $folding_width;

    my $value = sprint_value( $val, $fold_long_fields, $folding_width );
    my $key_len = length($tag) > $CIFTagPrint::max_cif_tag_len ?
        length($tag) : $CIFTagPrint::max_cif_tag_len;
    my $val_len = length($value);

    if( $value =~ /\s/ ) {
        $val_len += 2;
    }
    if( $key_len + $val_len + 1 > $CIFTagPrint::max_cif_line_len &&
        $value !~ /\n/ ) {
        printf "%s\n", $tag;
    } else {
        if( $value !~ /\n/ ) {
            printf "%-" . $CIFTagPrint::max_cif_tag_len . "s ", $tag;
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
		     < $CIFTagPrint::max_cif_line_len ) {
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

    $folding_width = $CIFTagPrint::default_folding_width
        unless defined $folding_width;

    if( $fold_long_fields && maxlen($val) > $folding_width - 2 ) {
	$val = join( "\n", map { " " . $_ }
		     fold( $folding_width - 1, " +", " ", $val ));
	$val =~ s/^\s+//g;
    }

    if( $val =~ /\n/ || $val =~ /^$/ ||
        ($val =~ /'\s/ && $val =~ /"\s/) ) {
	$val = "\n;" . $val . "\n;";
    } elsif( $val =~ /'\s/ ) {
	$val = "\"" . $val . "\"";
    } elsif( $val =~ /"\s|^\#/ ) {
	$val = "'" . $val . "'";
    } elsif( $val =~ /^'.*'$/ ) {
	$val = "\"" . $val . "\"";
    } elsif( $val =~ /\s|^_|^".*"$/) {
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

1;
