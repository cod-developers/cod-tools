#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------
#* 
#  CIF tag merging functions that work on the internal representation
#  of a CIF file returned by the COD::CIF::Parser module.
#**

package COD::CIF::Tags::Merge;

use strict;
use warnings;
use COD::CIF::Tags::Manage qw( set_loop_tag set_tag );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    merge_datablocks
);

sub merge_datablocks
{
    my( $source, $target, $options ) = @_;

    $options = {} unless $options;
    my %merge_tags;
    if( exists $options->{merge_tags} ) {
        %merge_tags = %{$options->{merge_tags}};
    }
    my %override_tags;
    if( exists $options->{override_tags} ) {
        %override_tags = %{$options->{override_tags}};
    }
    my @tags = @{$source->{tags}};
    if( exists $options->{tags} ) {
        @tags = @{$options->{tags}};
    }

    for my $tag (@tags) {
        next if !exists $source->{values}{$tag};
        if( !exists $target->{values}{$tag} ) {
            ## print ">>> old data block does not have tag $tag\n";
            if( exists $source->{inloop}{$tag} ) {
                ## print ">>> tag '$tag' is in a loop...\n";
                ## warn "Merging loops (tag $tag) is not supported " .
                ##     "in this version";
                my $new_loop_id = $source->{inloop}{$tag};
                ## print ">>> ... it is loop $new_loop_id.\n";
                my $old_loop_id;
                for my $loop_tag (
                    @{$source->{loops}[$new_loop_id]} ) {
                    ## print ">>> checking '$loop_tag'...\n";
                    if( exists $target->{values}{$loop_tag} &&
                        exists $target->{inloop}{$loop_tag} ) {
                        $old_loop_id = $target->{inloop}{$loop_tag};
                        die unless defined $old_loop_id; # assert...
                        ## print ">>> found it in $old_loop_id\n";
                        if( int( @{$target->{values}{$loop_tag}} ) !=
                            int( @{$source->{values}{$tag}} )) {
                            die "ERROR, looped data item '$loop_tag' has "
                              . "a different number of values than the "
                              . "'$tag' data item in file "
                              . "'$options->{source_filename}' "
                              . "even though the data items must end up "
                              , "in the same loop\n";
                        }
                        last;
                    }
                }
                if( defined $old_loop_id ) {
                    push @{$target->{loops}[$old_loop_id]}, $tag;
                    $target->{inloop}{$tag} = $old_loop_id;
                    ## print ">>> pushing '$tag' to old loop $old_loop_id\n";
                    ## print ">>> it already has tags @{$target->{loops}[$old_loop_id]}\n";
                } else {
                    push @{$target->{loops}}, [ $tag ];
                    $target->{inloop}{$tag} = $#{$target->{loops}};
                    ## print ">>> starting new loop $#{$target->{loops}} for tag '$tag'\n";
                }
            }
            ## print "\n";

            push( @{$target->{tags}}, $tag );

            $target->{values}{$tag} =
                $source->{values}{$tag};

            $target->{precisions}{$tag} =
                $source->{precisions}{$tag};

            $target->{types}{$tag} =
                $source->{types}{$tag};
        } else {
            if( $merge_tags{lc($tag)} ) {
                for( my $i = 0;
                     $i <= $#{$target->{values}{$tag}};
                     $i ++ ) {
                    $target->{values}{$tag}[$i] .= "\n" .
                        $source->{values}{$tag}[$i];
                }
            } elsif( defined $override_tags{lc($tag)} ||
                     $options->{override_all} ) {
                if( defined $target->{inloop}{$tag} ) {
                    set_loop_tag( $target, $tag, undef,
                                  $source->{values}{$tag} );
                } else {
                    set_tag( $target, $tag,
                             $source->{values}{$tag}[0] )
                }
            } elsif( !values_are_equal( $target->{values}{$tag},
                                        $source->{values}{$tag} )) {
                if ( scalar @{$source->{values}{$tag}} == 1 ) {
                    warn "WARNING, data item '$tag' value " .
                         "'$source->{values}{$tag}[0]' differs " .
                         "from the value '$target->{values}{$tag}[0]' " .
                         "encountered in previously processed files\n";
                } else {
                    warn 'WARNING, values of the looped data item ' .
                         "'$tag' differ from the values encountered " .
                         "in previously processed files\n";
                }
            }
        }
    }
}

sub values_are_equal
{
    my ($old_values, $new_values) = @_;

    if( int(@$old_values) != int(@$new_values) ) {
        return 0;
    }

    for( my $i = 0; $i <= $#{$new_values}; $i ++ ) {
        if( $new_values->[$i] ne $old_values->[$i] ) {
            return 0;
        }
    }

    return 1;
}

1;
