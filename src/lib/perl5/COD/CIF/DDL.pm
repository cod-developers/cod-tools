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

    return { map { $_ => $dictionary->[0]{values}
                                         {$id_tags->{$dicversion}{$_}}[0] }
             grep { exists $dictionary->[0]{values}
                                           {$id_tags->{$dicversion}{$_}} }
                  keys %{$id_tags->{$dicversion}} };
}

1;
