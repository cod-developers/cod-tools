#------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------
#*
#  Convert CIF data names to the canonical form. Operate on individual
#  strings as well as the internal representation of a CIF file as returned
#  by the COD::CIF::Parser module.
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

my %CIF_TAGS_LC = map { ( lc $_ ) => $_ }
                            (
                                @COD::CIF::Tags::DictTags::tag_list,
                                @COD::CIF::Tags::COD::tag_list,
                                @COD::CIF::Tags::TCOD::tag_list,
                                @COD::CIF::Tags::DFT::tag_list,
                            );

##
# Converts a single data name to the canonical form.
#
# @param $tag
#       Data name that should be converted to the canonical form.
# @return
#       Data name in the canonical form or the original data name
#       if it could not be canonicalised.
##
sub canonical_tag_name($)
{
    my ($tag) = @_;
    my $lc_tag = lc $tag;

    return (exists $CIF_TAGS_LC{$lc_tag} ? $CIF_TAGS_LC{$lc_tag} : $tag);
}

##
# Converts all data names in a CIF file to the canonical form.
#
# @param $cif
#       Reference to a data structure of a parsed CIF file as returned
#       by the COD::CIF::Parser module.
##
sub canonicalize_all_names
{
    my ($cif) = @_;

    for my $data_block (@{$cif}) {
        canonicalize_names( $data_block );
    }

    return;
}

##
# Converts all data names in a single CIF data block to the canonical form.
#
# @param $cif
#       Reference to a data structure of a CIF data frame as returned
#       by the COD::CIF::Parser module.
##
sub canonicalize_names
{
    my ($data_block) = @_;

    my $block_values = $data_block->{'values'};
    for my $key ( keys %{$block_values} ) {
        my $lc_key = lc $key;
        if( defined $CIF_TAGS_LC{$lc_key} ) {
            my $canonical_key = $CIF_TAGS_LC{$lc_key};
            if( !exists $block_values->{$canonical_key} ) {
                rename_tag( $data_block, $key, $canonical_key );
            }
        }
    }

    return;
}

1;
