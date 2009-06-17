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
    set_tag
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

1;
