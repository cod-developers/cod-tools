#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SG_BUILDER_MODULE=src/lib/perl5/COD/Spacegroups/Builder.pm
INPUT_SG_LOOKUP_MODULE=src/lib/perl5/COD/Spacegroups/Lookup.pm
INPUT_SG_LOOKUP_COD_MODULE=src/lib/perl5/COD/Spacegroups/Lookup/COD.pm
INPUT_SYMOP_PARSE_MODULE=src/lib/perl5/COD/Spacegroups/Symop/Parse.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_SG_BUILDER_MODULE=$(\
    echo ${INPUT_SG_BUILDER_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

IMPORT_SG_LOOKUP_MODULE=$(\
    echo ${INPUT_SG_LOOKUP_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

IMPORT_SG_LOOKUP_COD_MODULE=$(\
    echo ${INPUT_SG_LOOKUP_COD_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

IMPORT_SYMOP_PARSE_MODULE=$(\
    echo ${INPUT_SYMOP_PARSE_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_SG_BUILDER_MODULE}" \
     -M"${IMPORT_SG_LOOKUP_MODULE} qw( make_symop_hash make_symop_key )" \
     -M"${IMPORT_SG_LOOKUP_COD_MODULE}" \
     -M"${IMPORT_SYMOP_PARSE_MODULE} qw( string_from_symop )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Check whether COD::Spacegroups::Builder.pm correctly builds all space groups.
#**

use strict;
use warnings;

# use COD::Spacegroups::Builder;
# use COD::Spacegroups::Lookup qw( make_symop_hash make_symop_key );
# use COD::Spacegroups::Lookup::COD;
# use COD::Spacegroups::Symop::Parse qw( string_from_symop );

# Identify the space group from the symmetry operators:
my %symop_lookup_table = make_symop_hash( [
                            \@COD::Spacegroups::Lookup::COD::table,
                            \@COD::Spacegroups::Lookup::COD::extra_settings
                         ] );

for my $sg_data (@COD::Spacegroups::Lookup::COD::extra_settings) {

    my $spacegroup = new COD::Spacegroups::Builder;

    $spacegroup->insert_symop_strings( $sg_data->{symops} );

    my @symops = $spacegroup->all_symops();

    my $key = make_symop_key( [ map { string_from_symop($_) } @symops ] );

    if( exists $symop_lookup_table{$key} ) {
        my $estimated_sg = $symop_lookup_table{$key};
        print $estimated_sg->{universal_h_m}, "\n";
    } else {
        print "$0: space group '$sg_data->{universal_h_m}' could not be identified\n"
    }

}
END_SCRIPT
