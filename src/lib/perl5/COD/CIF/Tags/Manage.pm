#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------
#* 
#  CIF tag management functions that work on the internal
#  representation of a CIF file returned by the COD::CIF::Parser module.
#**

package COD::CIF::Tags::Manage;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    cifversion
    clean_cif
    exclude_tag
    tag_is_empty
    tag_is_unknown
    has_unknown_value
    has_inapplicable_value
    has_special_value
    has_numeric_value
    exclude_empty_tags
    exclude_empty_non_loop_tags
    exclude_misspelled_tags
    exclude_unknown_tags
    exclude_unknown_non_loop_tags
    new_datablock
    order_tags
    rename_tag
    rename_tags
    set_tag
    set_loop_tag
    get_data_value
    get_aliased_value
);

sub rename_tags($$$);

sub exclude_tag
{
    my ($cif, $tag) = @_;

    delete $cif->{values}{$tag};
    delete $cif->{precisions}{$tag};
    delete $cif->{types}{$tag};
    @{$cif->{tags}} =
        grep { $_ ne $tag } @{$cif->{tags}};

    if( defined $cif->{inloop}{$tag} ) {
        my $loop_nr = $cif->{inloop}{$tag};
        delete $cif->{inloop}{$tag};
        @{$cif->{loops}[$loop_nr]} =
            grep { $_ ne $tag } @{$cif->{loops}[$loop_nr]};
    }

    return;
}

sub tag_is_empty
{
    my ($cif, $tag) = @_;
    my $is_empty =1;

    if( exists $cif->{values}{$tag} ) {
        for my $val (@{$cif->{values}{$tag}}) {
            if( defined $val && $val ne '?' && $val ne '.' ) {
                $is_empty = 0;
                last;
            }
        }
    }
    return $is_empty;
}

sub exclude_empty_tags
{
    my ($cif) = @_;
    my @empty_tags = ();

    for my $tag (@{$cif->{tags}}) {
        if( tag_is_empty( $cif, $tag )) {
            push @empty_tags, $tag;
        }
    }
    for my $empty_tag (@empty_tags) {
        exclude_tag( $cif, $empty_tag );
    }

    return;
}

sub exclude_empty_non_loop_tags
{
    my ($cif) = @_;
    my @empty_tags = ();

    for my $tag (@{$cif->{tags}}) {
        if( tag_is_empty( $cif, $tag ) &&
            !exists $cif->{inloop}{$tag} ) {
            push @empty_tags, $tag;
        }
    }
    for my $empty_tag (@empty_tags) {
        exclude_tag( $cif, $empty_tag );
    }

    return;
}

sub tag_is_unknown
{
    my ($cif, $tag) = @_;
    my $is_empty =1;

    if( exists $cif->{values}{$tag} ) {
        for my $val (@{$cif->{values}{$tag}}) {
            if( defined $val && $val ne '?' ) {
                $is_empty = 0;
                last;
            }
        }
    }
    return $is_empty;
}

sub exclude_unknown_tags
{
    my ($cif) = @_;
    my @empty_tags = ();

    for my $tag (@{$cif->{tags}}) {
        if( tag_is_unknown( $cif, $tag )) {
            push @empty_tags, $tag;
        }
    }
    for my $empty_tag (@empty_tags) {
        exclude_tag( $cif, $empty_tag );
    }

    return;
}

sub exclude_unknown_non_loop_tags
{
    my ($cif) = @_;
    my @empty_tags = ();

    for my $tag (@{$cif->{tags}}) {
        if( tag_is_unknown( $cif, $tag ) &&
            !exists $cif->{inloop}{$tag} ) {
            push @empty_tags, $tag;
        }
    }
    for my $empty_tag (@empty_tags) {
        exclude_tag( $cif, $empty_tag );
    }

    return;
}

sub exclude_misspelled_tags
{
    my( $cif, $dictionary_tags ) = @_;

    my @misspelled_tags;
    for my $tag (@{$cif->{tags}}) {
        if( !exists $dictionary_tags->{$tag} ) {
            push @misspelled_tags, $tag;
        }
    }
    my %misspelled_tags = map { $_ => 1 } @misspelled_tags;
    for my $misspelled_tag (@misspelled_tags) {
        next if !exists $cif->{values}{$misspelled_tag};
        if( !exists $cif->{inloop}{$misspelled_tag} ) {
            exclude_tag( $cif, $misspelled_tag );
        } else {
            my $tag_loop_nr = $cif->{inloop}{$misspelled_tag};
            my $all_tags_excluded = 1;
            for my $loop_tag (@{$cif->{loops}[$tag_loop_nr]}) {
                if( !exists $misspelled_tags{$loop_tag} ) {
                    $all_tags_excluded = 0;
                    last;
                }
            }
            next if !$all_tags_excluded;
            for my $loop_tag (@{$cif->{loops}[$tag_loop_nr]}) {
                exclude_tag( $cif, $loop_tag );
            }
        }
    }

    return;
}

sub new_datablock
{
    my( $dataname, $cifversion ) = @_;

    die 'data block name cannot be empty' if !$dataname;

    my $dataname_now = $dataname;
    $dataname_now =~ s/[ \t\r\n]/_/g;
    if( $dataname ne $dataname_now ) {
        warn "data block name '$dataname' was renamed to " .
             "'$dataname_now' as data block names cannot contain spaces";
    }

    my( $major, $minor ) = ( 1, 1 );
    if( $cifversion ) {
        ( $major, $minor, my @rest ) = split /\./, $cifversion;
        warn 'patch version for CIF format is ignored' if @rest;
        $major = int( $major );
        $minor = int( $minor );
        if( "$major.$minor" ne '1.1' && "$major.$minor" ne '2.0' ) {
            die "unknown CIF format version '$cifversion'";
        }
    }

    return {
        name   => $dataname_now,
        tags   => [],
        values => {},
        types  => {},
        precisions => {},
        loops  => [],
        inloop => {},
        cifversion => { major => $major, minor => $minor }
    };
}

sub order_tags
{
    my( $cif, $tags_to_print, $loop_tags_to_print,
        $dictionary_tags ) = @_;
    my @new_tag_list;

    # Correct non-loop tags + _publ_author_name

    for my $tag (@{$tags_to_print}) {
        if(  exists $cif->{values}{$tag} &&
             exists $dictionary_tags->{$tag} &&
           (!exists $cif->{inloop}{$tag} ||
            $tag eq '_publ_author_name') ) {
            push @new_tag_list, $tag;
        }
    }

    # Misspelled non-loop tags

    for my $tag (@{$cif->{tags}}) {
        if( !exists $dictionary_tags->{$tag} &&
            !exists $cif->{inloop}{$tag} ) {
            push @new_tag_list, $tag;
        }
    }

    # Correct loop tags

    for my $tag (@{$loop_tags_to_print}) {
        if( exists $cif->{values}{$tag} &&
            exists $cif->{inloop}{$tag} &&
            $tag ne '_publ_author_name' ) {
            push @new_tag_list, $tag;
        }
    }

    # Misspelled loop tags

    for my $tag (@{$cif->{tags}}) {
        if( !exists $dictionary_tags->{$tag} &&
             exists $cif->{inloop}{$tag} ) {
            push @new_tag_list, $tag;
        }
    }

    $cif->{tags} = \@new_tag_list;

    return;
}

sub clean_cif
{
    my( $cif, $flags ) = @_;

    my @dictionary_tags;
    my %dictionary_tags = ();

    my ( $exclude_misspelled_tags, $preserve_loop_order ) = ( 0 ) x 2;
    my $keep_tag_order = 0;

    if( $flags && ref $flags eq 'HASH' ) {
        $exclude_misspelled_tags = $flags->{exclude_misspelled_tags};
        $preserve_loop_order = $flags->{preserve_loop_order};
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

    my @tags_to_print;
    if( $keep_tag_order ) {
        @tags_to_print = @{$cif->{tags}};
        if( !%dictionary_tags ) {
            %dictionary_tags = map { $_ => 1 } @tags_to_print;
        }
    } else {
        @tags_to_print = @dictionary_tags;
    }

    if( $exclude_misspelled_tags ) {
        my %tags_to_print = map { $_ => 1 } @tags_to_print;
        exclude_misspelled_tags( $cif, \%tags_to_print );
    }

    order_tags( $cif,
                \@tags_to_print,
                $preserve_loop_order
                    ? $cif->{tags} : \@dictionary_tags,
                \%dictionary_tags );

    return;
}

sub rename_tag
{
    my ($cif, $old_tag, $new_tag ) = @_;

    return if !exists $cif->{values}{$old_tag};

    $cif->{values}{$new_tag} = $cif->{values}{$old_tag};
    delete $cif->{values}{$old_tag} if $new_tag ne $old_tag;

    if( exists $cif->{inloop}{$old_tag} ) {
        $cif->{inloop}{$new_tag} = $cif->{inloop}{$old_tag};
        delete $cif->{inloop}{$old_tag} if $new_tag ne $old_tag;
    }
    if( exists $cif->{types}{$old_tag} ) {
        $cif->{types}{$new_tag} =
            $cif->{types}{$old_tag};
        delete $cif->{types}{$old_tag} if $new_tag ne $old_tag;
    }
    if( exists $cif->{precisions}{$old_tag} ) {
        $cif->{precisions}{$new_tag} =
            $cif->{precisions}{$old_tag};
        delete $cif->{precisions}{$old_tag} if $new_tag ne $old_tag;
    }

    if( $new_tag eq $old_tag ) {
        # Tags are equal, nothing to do
    } elsif( grep { $_ eq $new_tag } @{$cif->{tags}} ) {
        # A tag is overwritten, therefore, old tag needs to be removed
        $cif->{tags} = [ grep { $_ ne $old_tag } @{$cif->{tags}} ];
        for my $loop ( @{$cif->{loops}} ) {
            $loop = [ grep { $_ ne $old_tag } @$loop ];
        }
    } else {
        # The new tag takes the place of the old one
        for my $i ( 0 .. $#{$cif->{tags}} ) {
            my $tag = $cif->{tags}[$i];
            if( $tag eq $old_tag ) {
                $cif->{tags}[$i] = $new_tag;
            }
        }
        for my $loop ( @{$cif->{loops}} ) {
            for my $i ( 0 .. $#{$loop} ) {
                if( $loop->[$i] eq $old_tag ) {
                    $loop->[$i] = $new_tag;
                }
            }
        }
    }

    return;
}

#===============================================================#
# Renames CIF data tags so that they are not confused with the
# original ones.

# Accepts a dataset hash produced by COD::CIF::Parser, a list of tags to be
# renamed, and a prefix to be appended

# Returns a hash with renamed data tags

sub rename_tags($$$)
{
    my ( $dataset, $tags2rename, $prefix ) = @_;

    my $values = $dataset->{values};
    my %renamed_tags = ();

    for my $tag (@{$tags2rename}) {
        next if !exists $values->{$tag};
        next if exists $dataset->{inloop}{$tag};

        my $new_tag = $prefix . $tag;
        rename_tag( $dataset, $tag, $new_tag );
        $renamed_tags{$new_tag} = $tag;
    }

    return wantarray ? %renamed_tags : \%renamed_tags;
}

sub set_tag
{
    my ( $cif, $tag, $value ) = @_;
    if( !exists $cif->{values}{$tag} ) {
        push @{$cif->{tags}}, $tag;
    }
    $cif->{values}{$tag}[0] = $value;

    return;
}

##
# Sets a looped data value in a data block structure.
#
# @param $cif
#       The data block structure as returned by the CIF::COD::Parser.
# @param $tag
#       The name of the data item that should be placed in a loop.
# @param $in_loop
#       The name of the data item that identifies the loop the '$tag'
#       data item should be placed in. If the value matches the '$tag'
#       value and the data item currently does not reside in a loop
#       structure a new loop is created. Undefined value is treated
#       the same way.
# @param
#       Data values that should be placed in the loop.
##
sub set_loop_tag
{
    my( $cif, $tag, $in_loop, $values ) = @_;

    my $loop_no;
    if ( !defined $in_loop || $in_loop eq $tag ) {
        if ( defined $cif->{'inloop'}{$tag} ) {
            $loop_no = $cif->{'inloop'}{$tag};
        } else {
            $loop_no = defined $cif->{'loops'} ? scalar @{$cif->{'loops'}} : 0;
            push @{$cif->{'loops'}}, [];
        }
    } else {
        if ( !defined $cif->{'inloop'}{$in_loop} ) {
            warn "the '$tag' data item could not be added to a loop " .
                 "structure containing the '$in_loop' data item -- the " .
                 "'$in_loop' data item was not found in a loop structure\n";
            return;
        }
        $loop_no = $cif->{'inloop'}{$in_loop};
    }
 # This check needs further discussion
 #  foreach ( @{$cif->{'loops'}[$loop_no]} ) {
 #       next if $_ eq $tag;
 #       if ( scalar @{$values} ne scalar @{$cif->{'values'}{$_}} ) {
 #           warn "the '$tag' data item could not be added to a loop " .
 #               "structure containing the '$_' data item -- data items " .
 #                "have a differing number of values\n";
 #           return;
 #       }
 #   }
    use List::MoreUtils qw( first_index );

    my $inloop_position = @{$cif->{'loops'}[$loop_no]};
    my $tag_position    = @{$cif->{'tags'}};
    # array length decreases upon the deletion of an already existing data name
    if ( defined $cif->{'values'}{$tag} ) {
        $tag_position--;
    }
    if ( defined $cif->{'inloop'}{$tag} &&
         $cif->{'inloop'}{$tag} eq $loop_no ) {
        $inloop_position =
            List::MoreUtils::first_index{ $_ eq $tag }
                @{$cif->{'loops'}[$loop_no]};
        $tag_position = List::MoreUtils::first_index{ $_ eq $tag }
                @{$cif->{'tags'}};
    }
    exclude_tag($cif, $tag);

    # Add the data item at a new position
    splice @{$cif->{'tags'}}, $tag_position, 0, $tag;
    splice @{$cif->{'loops'}[$loop_no]}, $inloop_position, 0, $tag;
    $cif->{'inloop'}{$tag} = $loop_no;
    $cif->{'values'}{$tag} = $values;

    return;
}

sub get_data_value
{
    my ($values, $data_name, $index) = @_;

    $index = 0 unless defined $index;

    if( exists $values->{$data_name} ) {
        if( defined $values->{$data_name}[$index] ) {
            return $values->{$data_name}[$index];
        }
    }

    return;
}

sub get_aliased_value
{
    my ($values, $data_names, $index) = @_;

    my $value;
    for my $data_name ( @{$data_names} ) {
        if (!defined $value) {
            $value = get_data_value( $values, $data_name, $index );
        } else {
            last;
        }
    }

    return $value;
}

sub cifversion($)
{
    my( $datablock ) = @_;
    return if !exists $datablock->{cifversion} ||
              !exists $datablock->{cifversion}{major} ||
              !exists $datablock->{cifversion}{minor};

    return sprintf '%d.%d', $datablock->{cifversion}{major},
                            $datablock->{cifversion}{minor};
}

##
# Evaluates if the data item is marked as containing an unknown value
# according to CIF notation.
#
# @param $frame
#       Data frame that contains the data item as returned by the CIF::COD::Parser.
# @param $data_name
#       Name of the data item.
# @param $index
#       The index of the data item value to be evaluated as unknown.
# @return
#       Boolean value denoting if the data item contains an unknown value.
##
sub has_unknown_value
{
    my ( $frame, $data_name, $index ) = @_;

    my $value = $frame->{'values'}{$data_name}[$index];
    my $type = defined $frame->{'types'}{$data_name}[$index] ?
               $frame->{'types'}{$data_name}[$index] : 'UQSTRING' ;

    return $value eq '?' && $type eq 'UQSTRING';
}

##
# Evaluates if the data item is marked as containing an inapplicable value
# according to CIF notation.
#
# @param $frame
#       Data frame that contains the data item as returned by the CIF::COD::Parser.
# @param $data_name
#       Name of the data item.
# @param $index
#       The index of the data item value to be evaluated as inapplicable.
# @return
#       Boolean value denoting if the data item contains an inapplicable value.
##
sub has_inapplicable_value
{
    my ( $frame, $data_name, $index ) = @_;

    my $value = $frame->{'values'}{$data_name}[$index];
    my $type = defined $frame->{'types'}{$data_name}[$index] ?
               $frame->{'types'}{$data_name}[$index] : 'UQSTRING' ;

    return $value eq '.' && $type eq 'UQSTRING';
}

##
# Evaluates if the data item is marked as containing a special (unknown or
# inapplicable) value according to CIF notation.
#
# @param $frame
#       Data frame that contains the data item as returned by the CIF::COD::Parser.
# @param $data_name
#       Name of the data item.
# @param $index
#       The index of the data item value to be evaluated as special.
# @return
#       Boolean value denoting if the data item contains a special value.
##
sub has_special_value
{
    my ( $frame, $data_name, $index ) = @_;

    return has_unknown_value( $frame, $data_name, $index ) ||
           has_inapplicable_value( $frame, $data_name, $index );
}

##
# Evaluates if the data item contains a numeric value as specified by
# the CIF working specification.
#
# @param $frame
#       Data frame that contains the data item as returned by the CIF::COD::Parser.
# @param $data_name
#       Name of the data item.
# @param $index
#       The index of the data item value to be evaluated as unknown.
# @return
#       Boolean value denoting if the data item contains a numeric value.
##
sub has_numeric_value
{
    my ( $data_frame, $data_name, $index ) = @_;

    my $type = defined $data_frame->{'types'}{$data_name}[$index] ?
               $data_frame->{'types'}{$data_name}[$index] : 'UQSTRING' ;

    return ( $type eq 'INT' || $type eq 'FLOAT' );
}

1;
