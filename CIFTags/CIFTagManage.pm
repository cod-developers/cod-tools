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

package CIFTagManage;

use strict;

require Exporter;
@CIFTagManage::ISA = qw(Exporter);
@CIFTagManage::EXPORT = qw( exclude_tag tag_is_empty
    exclude_empty_tags
    exclude_empty_non_loop_tags
    set_tag
    set_loop_tag
);

sub exclude_tag
{
    my ($cif, $tag) = @_;

    delete( $cif->{values}{$tag} );
    delete( $cif->{precisions}{$tag} );
    delete( $cif->{types}{$tag} );
    @{$cif->{tags}} =
        grep ! /^\Q$tag\E$/, @{$cif->{tags}};

    if( defined $cif->{inloop}{$tag} ) {
        my $loop_nr = $cif->{inloop}{$tag};
        delete $cif->{inloop}{$tag};
        @{$cif->{loops}[$loop_nr]} =
            grep ! /^\Q$tag\E$/, @{$cif->{loops}[$loop_nr]};
    }
}

sub tag_is_empty
{
    my ($cif, $tag) = @_;
    my $is_empty =1;

    if( exists $cif->{values}{$tag} ) {
        for my $val (@{$cif->{values}{$tag}}) {
            if( defined $val && $val ne "?" && $val ne "." ) {
                $is_empty = 0;
                last;
            }
        }
    }
    return $is_empty;
}

sub exclude_empty_tags
{
    my $cif = $_[0];
    my @empty_tags = ();

    for my $tag (@{$cif->{tags}}) {
        if( tag_is_empty( $cif, $tag )) {
            push( @empty_tags, $tag );
        }
    }
    for my $empty_tag (@empty_tags) {
        exclude_tag( $cif, $empty_tag );
    }
}

sub exclude_empty_non_loop_tags
{
    my $cif = $_[0];
    my @empty_tags = ();

    for my $tag (@{$cif->{tags}}) {
        if( tag_is_empty( $cif, $tag ) &&
            !exists $cif->{inloop}{$tag} ) {
            push( @empty_tags, $tag );
        }
    }
    for my $empty_tag (@empty_tags) {
        exclude_tag( $cif, $empty_tag );
    }
}

sub rename_tag
{
    my ($cif, $old_tag, $new_tag ) = @_;

    if( exists $cif->{values}{$old_tag} ) {
        $cif->{values}{$new_tag} = $cif->{values}{$old_tag};
        delete $cif->{values}{$old_tag};
        if( exists $cif->{inloop}{$old_tag} ) {
            $cif->{inloop}{$new_tag} = $cif->{inloop}{$old_tag};
            delete $cif->{inloop}{$old_tag};
        }
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
}

sub set_tag
{
    my ( $cif, $tag, $value ) = @_;
    if( !exists $cif->{values}{$tag} ) {
        push( @{$cif->{tags}}, $tag );
    }
    $cif->{values}{$tag}[0] = $value;
}

sub set_loop_tag
{
    my( $cif, $tag, $in_loop, $values ) = @_;
    if( !exists $cif->{values}{$tag} ) {
        push( @{$cif->{tags}}, $tag );
        if( !defined $in_loop || $tag eq $in_loop ) {
            push( $cif->{loops}, [ $tag ] );
            $cif->{inloop}{$tag} = @{$cif->{loops}} - 1;
        } else {
            my $nloop = $cif->{inloop}{$in_loop};
            push( @{$cif->{loops}[$nloop]}, $tag );
            $cif->{inloop}{$tag} = $nloop;
        }
    }
    $cif->{values}{$tag} = $values;
}

1;
