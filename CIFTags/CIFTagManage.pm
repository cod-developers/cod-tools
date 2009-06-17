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
@CIFTagManage::EXPORT = qw( exclude_tag tag_is_empty exclude_empty_tags
    set_tag cif_lowercase_tags
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
	if( tag_is_empty( $cif, $tag ) &&
            !exists $cif->{inloop}{$tag} ) {
	    push( @empty_tags, $tag );
	}
    }
    for my $empty_tag (@empty_tags) {
	exclude_tag( $cif, $empty_tag );
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

sub cif_lowercase_tags
{
    my ( $cif ) = @_;

    if( ref $cif eq "ARRAY" ) {
        for my $datablock (@{$cif}) {
            cif_lowercase_tags( $datablock );
        }
    } elsif( ref $cif eq "HASH" ) {

        @{$cif->{tags}} = map { lc($_) } @{$cif->{tags}};

        for my $loop (@{$cif->{loops}}) {
            @{$loop} = map { lc($_) } @{$loop};
        }

        for my $key (qw( values precisions types inloop )) {
            while ( my ($tag, $value) = each %{$cif->{values}} ) {
                my $lc_tag = lc( $tag );
                if( $lc_tag ne $tag ) {
                    delete $cif->{values}{$tag};
                    $cif->{values}{$lc_tag} = $value;
                }
            }
        }

        if( $cif->{save_blocks} ) {
            for my $save_blk (@{$cif->{save_blocks}}) {
                cif_lowercase_tags( $save_blk );
            }
        }
    } else {
        die( "cif_lowercase_tags() expects ARRAY or HASH reference as " .
             "a parameter" );
    }

    return $cif;
}

1;
