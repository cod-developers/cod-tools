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

package CIFTagCanonicalNames;

use strict;

require Exporter;
@CIFTagCanonicalNames::ISA = qw(Exporter);
@CIFTagCanonicalNames::EXPORT = qw( canonical_tag_name canonicalize_names canonicalize_all_names );

use CIFDictTags;
use CIFCODTags;

my @dictionary_tags = ( @CIFDictTags::tag_list, @CIFCODTags::tag_list );

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

    # convert all tags to a "cannonical" form (the one used in this
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
            my $cannonical_key = $cif_tags_lc{$lc_key};
            ## print ">>> $key -> $lc_key -> $cannonical_key\n";
            if( !exists $datablok->{$cannonical_key} ) {
                $datablok->{$cannonical_key} = $datablok->{$key};
                delete $datablok->{$key};
                @{$dataset->{tags}} =
                    map { s/^\Q$key\E$/$cannonical_key/; $_ }
                @{$dataset->{tags}};
                if( exists $dataset->{types}{$key} ) {
                    $dataset->{types}{$cannonical_key} =
                        $dataset->{types}{$key};
                    delete $dataset->{types}{$key};
                }
                if( exists $dataset->{precisions}{$key} ) {
                    $dataset->{precisions}{$cannonical_key} =
                        $dataset->{precisions}{$key};
                    delete $dataset->{precisions}{$key};
                }
                if( exists $dataset->{inloop}{$key} ) {
                    my $loop_nr = $dataset->{inloop}{$key};
                    $dataset->{inloop}{$cannonical_key} =
                        $dataset->{inloop}{$key};
                    delete $dataset->{inloop}{$key};
                    @{$dataset->{loops}[$loop_nr]} =
                        map { s/^\Q$key\E$/$cannonical_key/; $_ }
                    @{$dataset->{loops}[$loop_nr]};
                }
            }
        }
    }
}

1;
