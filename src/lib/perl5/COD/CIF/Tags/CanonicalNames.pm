#------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------
#*
#  CIF tag management functions that work on the internal representation of
#  a CIF file as returned by the COD::CIF::Parser module.
#**

package COD::CIF::Tags::CanonicalNames;

use strict;
use warnings;
use COD::CIF::Tags::DictTags;
use COD::CIF::Tags::COD;
use COD::CIF::Tags::TCOD;
use COD::CIF::Tags::DFT;
use COD::CIF::Tags::Manage qw( rename_tag );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    canonical_tag_name
    canonicalize_names
    canonicalize_all_names
);

my @dictionary_tags = ( @COD::CIF::Tags::DictTags::tag_list,
                        @COD::CIF::Tags::COD::tag_list,
                        @COD::CIF::Tags::TCOD::tag_list,
                        @COD::CIF::Tags::DFT::tag_list );

my %cif_tags_lc = map {(lc($_),$_)} @dictionary_tags;

sub canonical_tag_name($)
{
    my $tag = $_[0];
    my $lc_tag = lc( $tag );

    exists $cif_tags_lc{$lc_tag} ? $cif_tags_lc{$lc_tag} : $tag;
}

sub canonicalize_all_names
{
    my ($cif) = @_;

    # convert all tags to a "canonical" form (the one used in this
    # script ;):

    for my $dataset (@{$cif}) {
        canonicalize_names( $dataset );
    }
}

sub canonicalize_names
{
    my ($dataset) = @_;

    my $datablok = $dataset->{values};
    for my $key ( keys %{$datablok} ) {
        my $lc_key = lc( $key );
        ## print ">>> $key -> $lc_key\n";
        if( defined $cif_tags_lc{$lc_key} ) {
            my $canonical_key = $cif_tags_lc{$lc_key};
            ## print ">>> $key -> $lc_key -> $canonical_key\n";
            if( !exists $datablok->{$canonical_key} ) {
                rename_tag( $dataset, $key, $canonical_key );
            }
        }
    }
}

1;
