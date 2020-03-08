#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* A set of generic subroutines for DDL handling.
#**

package COD::CIF::DDL;

use strict;
use warnings;

use COD::CIF::Tags::Manage qw( cifversion );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    get_cif_dictionary_ids
    get_dictionary_id
    is_local_data_name
    is_general_local_data_name
    is_category_local_data_name
    get_category_name_from_local_data_name
);

sub get_cif_dictionary_ids
{
    my( $datablock ) = @_;

    my %dictionary_tags = (
        '_audit_conform.dict_name'     => 'name',
        '_audit_conform.dict_version'  => 'version',
        '_audit_conform.dict_location' => 'uri',
        '_audit_conform_dict_name'     => 'name',
        '_audit_conform_dict_version'  => 'version',
        '_audit_conform_dict_location' => 'uri',
    );

    my @tags_in_cif = grep { exists $datablock->{values}{$_} }
                           sort keys %dictionary_tags;

    return if !@tags_in_cif;

    my @dictionaries;
    for my $i (0..$#{$datablock->{values}{$tags_in_cif[0]}}) {
        push @dictionaries,
             { map { $dictionary_tags{$_} => $datablock->{values}{$_}[0] }
                   @tags_in_cif };
    }

    return @dictionaries;
}

sub get_dictionary_id
{
    my( $dictionary ) = @_;

    my $id_tags = {
        DDL1 => { name    => '_dictionary_name',
                  version => '_dictionary_version' },
        DDLm => { name    => '_dictionary.title',
                  version => '_dictionary.version',
                  uri     => '_dictionary.uri' }
    };

    my $dicversion = cifversion( $dictionary->[0] ) &&
                     cifversion( $dictionary->[0] ) eq '2.0'
                        ? 'DDLm' : 'DDL1';

    return { map { $_ => $dictionary->[0]{values}{$id_tags->{$dicversion}{$_}}[0] }
             grep { exists $dictionary->[0]{values}{$id_tags->{$dicversion}{$_}} }
                  keys %{$id_tags->{$dicversion}} };
}

##
# Determines if the given data name conforms to the syntax of a local
# data name. Applies to DDL2 and DDLm.
#
# @see
#       https://www.iucr.org/resources/cif/spec/ancillary/reserved-prefixes
# @param $data_name
#       Data name to be checked.
# @return
#       '1' if the name is conformant, '0' otherwise.
##
sub is_local_data_name
{
    my ($data_name) = @_;

    my $is_local_data_name =
        is_general_local_data_name($data_name) ||
        is_category_local_data_name($data_name);

    return $is_local_data_name;
}

##
# Determines if the given data name conforms to the syntax of a general
# local data name. Applies to DDL1, DDL2 and DDLm.
#
# @see
#       https://www.iucr.org/resources/cif/spec/ancillary/reserved-prefixes
# @param $data_name
#       Data name to be checked.
# @return
#       '1' if the name is conformant, '0' otherwise.
##
sub is_general_local_data_name
{
    my ($data_name) = @_;

    return 1 if ( $data_name =~ m/^_\[local\]/ );

    return 0;
}

##
# Determines if the given data name conforms to the syntax of a local
# data name assigned to an existing category. Applies to DDL2 and DDLm.
#
# @see
#       https://www.iucr.org/resources/cif/spec/ancillary/reserved-prefixes
# @see
#       "International Tables for Crystallography, Definition and Exchange
#        of Crystallographic Data", Volume G, 2005, Section 3.1.2.1.
#        ("The _[local]_ prefix").
# @param $data_name
#       Data name to be checked.
# @return
#       '1' if the name is conformant,
#       '0' otherwise.
##
sub is_category_local_data_name
{
    my ($data_name) = @_;

    return 1 if ( $data_name =~ m/^[^.]+[.]\[local\]/ );

    return 0;
}

##
# Extracts the category name from a local data name.
#
# @see
#       https://www.iucr.org/resources/cif/spec/ancillary/reserved-prefixes
# @see
#       "International Tables for Crystallography, Definition and Exchange
#        of Crystallographic Data", Volume G, 2005, Section 3.1.2.1.
#        ("The _[local]_ prefix").
# @param $data_name
#       Local data name from which the category name shoud be extracted.
# @return
#       Category name if it could be extracted,
#       undef otherwise.
##
sub get_category_name_from_local_data_name
{
    my ($data_name) = @_;

    # general local data name of the form _[local]_category_name.item_name
    if ( $data_name =~ m/^_\[local\]_([^.]+)[.].+/ ) {
        return $1;
    }

    # category local data name of the form _category_name.[local]_item_name
    if ( $data_name =~ m/^_([^.]+)[.]\[local\]_.+/ ) {
        return $1;
    }

    return;
}

1;
