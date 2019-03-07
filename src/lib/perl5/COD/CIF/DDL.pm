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

    my $dictionary_tags = {
        1.1 => { name    => '_audit_conform_dict_name',
                 version => '_audit_conform_dict_version',
                 uri     => '_audit_conform_dict_location' },
        2.0 => { name    => '_dictionary.title',
                 version => '_dictionary.version',
                 uri     => '_dictionary.uri' }
    };

    my $cifversion = cifversion( $datablock );
    $cifversion = 1.1 unless $cifversion;

    my @tags_in_cif = grep { exists $datablock->{values}{$_} }
                           sort values %{$dictionary_tags->{$cifversion}};

    return if !@tags_in_cif;

    my @dictionaries;
    for my $i (0..$#{$datablock->{values}{$tags_in_cif[0]}}) {
        push @dictionaries,
             { map { $_ => $datablock->{values}{$dictionary_tags->{$cifversion}{$_}}[$i] }
                   keys %{$dictionary_tags->{$cifversion}} };
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
