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
use Clone qw( clone );
use POSIX qw( strftime );

use COD::CIF::Tags::Manage qw(
    cifversion
    exclude_tag
    new_datablock
    rename_tag
    set_loop_tag
    set_tag
);
use COD::CIF::Unicode2CIF qw( cif2unicode );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    cif_to_ddlm
    ddl1_to_ddlm
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

##
# Converts (in a rather crude way) CIF data blocks of DDL1 dictionaries
# to DDLm in order to represent them using the same code. This method
# should not be used to translate DDL1 to DDLm for any other purposes
# except preview, as it is largely based on guesswork and works
# satisfactory only for testing purposes.
##
sub ddl1_to_ddlm
{
    my( $ddl_datablocks, $options ) = @_;

    $options = {} unless $options;
    my( $keep_original_date, $new_version, $imports ) = (
        $options->{keep_original_date},
        $options->{new_version},
        $options->{imports},
    );

    my $category_overview = 'category_overview';

    my %tags_to_rename = (
        _category            => '_name.category_id',
        _definition          => '_description.text',
        _enumeration         => '_enumeration_set.state',
        _enumeration_default => '_enumeration.default',
        _enumeration_detail  => '_enumeration_set.detail',
        _enumeration_range   => '_enumeration.range',
        _example             => '_description_example.case',
        _example_detail      => '_description_example.detail',
        _list_reference      => '_category_key.name',
        _units_detail        => '_units.code',
    );

    my %typemap = (
        char => 'Text',
        numb => 'Real',
    );

    my @tags_to_exclude = ( '_list', '_name', '_type', '_type_conditions', '_units' );

    my $date;
    if( $keep_original_date ) {
        $date = get_dic_item_value( $ddl_datablocks->[0], '_dictionary_update' );
    } else {
        $date = strftime( '%F', gmtime() );
    }

    my $dictionary_name =
        dic_filename_to_title( get_dic_item_value( $ddl_datablocks->[0],
                                                   '_dictionary_name' ) );

    my $ddlm_datablock = new_datablock( $dictionary_name, '2.0' );

    my $head = new_datablock( $category_overview, '2.0' );
    set_tag( $head, '_definition.id', uc $category_overview );
    set_tag( $head, '_definition.class', 'Head' );
    set_tag( $head, '_definition.scope', 'Category' );
    set_tag( $head, '_name.object_id', uc $category_overview );
    set_tag( $head, '_name.category_id', $dictionary_name );
    if( $imports && @$imports ) {
        set_tag( $head,
                 '_import.get',
                 [ map { { file => $_,
                           save => dic_filename_to_title( $_ ),
                           mode => 'Full' } } @$imports ] );
    }
    push @{$ddlm_datablock->{save_blocks}}, $head;

    for my $datablock (@$ddl_datablocks) {
        next if $datablock->{name} eq 'on_this_dictionary';

        for my $name (@{$datablock->{values}{_name}}) {
            my $ddl_datablock = clone( $datablock );
            $ddl_datablock->{name} = $name;
            $ddl_datablock->{name} =~ s/^_//;
            $ddl_datablock->{name} =~ s/_\[\]$//;

            set_tag( $ddl_datablock, '_definition.update', $date );

            if( defined get_dic_item_value( $ddl_datablock, '_category' ) &&
                get_dic_item_value( $ddl_datablock, '_category' ) eq $category_overview ) {
                $name =~ s/^_//;
                $name =~ s/_\[\]$//;

                my @tags = grep { defined get_dic_item_value( $_, '_category' ) &&
                                  get_dic_item_value( $_, '_category' ) eq $name }
                                @$ddl_datablocks;
                my @loop_tags = grep { defined get_dic_item_value( $_, '_list' ) &&
                                       get_dic_item_value( $_, '_list' ) eq 'yes' }
                                     @tags;

                if( @loop_tags && @tags != @loop_tags ) {
                    warn "some data items of category '$name' are defined " .
                         'as looped while some are not -- category has to ' .
                         'be split in order to be represented correctly ' .
                         'in DDLm' . "\n";
                }

                # Uppercase category names to make them stand out.
                $name = uc $name;
                set_tag( $ddl_datablock,
                         '_definition.class',
                         @tags && @tags == @loop_tags ? 'Loop' : 'Set' );
                set_tag( $ddl_datablock, '_definition.scope', 'Category' );

                # Uppercasing category data block code
                # FIXME: commented it out for now since it seems to break
                # the 'dic2markdown' script
                # $ddl_datablock->{'name'} = uc $ddl_datablock->{'name'};
            } else {
                set_tag( $ddl_datablock, '_definition.class', 'Datum' );
                set_tag( $ddl_datablock, '_type.container', 'Single' );

                my $type_purpose;

                if( get_dic_item_value( $ddl_datablock, '_type' ) ) {
                    set_tag( $ddl_datablock,
                             '_type.contents',
                             $typemap{get_dic_item_value( $ddl_datablock, '_type' )} );
                    if( get_dic_item_value( $ddl_datablock, '_type' ) eq 'numb' ) {
                        if( defined get_dic_item_value( $ddl_datablock, '_type_conditions' ) &&
                            get_dic_item_value( $ddl_datablock, '_type_conditions' ) =~ /^esd|su$/ ) {
                            $type_purpose = 'Measurand';
                        }
                        if( !defined get_dic_item_value( $ddl_datablock, '_units_detail' ) ) {
                            set_tag( $ddl_datablock, '_units.code', 'none' );
                        }
                    }
                }

                if( defined get_dic_item_value( $ddl_datablock, '_enumeration' ) ) {
                    $type_purpose = 'State';
                }

                if( $type_purpose ) {
                    set_tag( $ddl_datablock, '_type.purpose', $type_purpose );
                }
            }

            if(  defined get_dic_item_value( $ddl_datablock, '_units' ) &&
                !defined get_dic_item_value( $ddl_datablock, '_units_detail' ) ) {
                warn "'_units_detail' is not defined for '$ddl_datablock->{name}'\n";
            }

            # Convert DDL1 parent item to DDLm linked item.
            if ( defined $ddl_datablock->{'values'}{'_list_link_parent'} ) {
                rename_tag( $ddl_datablock,
                            '_list_link_parent',
                            '_name.linked_item_id' );
                set_tag( $ddl_datablock, '_type.purpose', 'Link' );
            }

            for my $tag (sort keys %tags_to_rename) {
                next if !defined get_dic_item_value( $ddl_datablock, $tag );

                $ddl_datablock->{values}{$tag} =
                    [ map { cif2unicode( $_ ) }
                          @{$ddl_datablock->{values}{$tag}} ];

                rename_tag( $ddl_datablock,
                            $tag,
                            $tags_to_rename{$tag} );
            }

            for my $tag (@tags_to_exclude) {
                next if !defined get_dic_item_value( $ddl_datablock, $tag );
                exclude_tag( $ddl_datablock, $tag );
            }

            if( exists $ddl_datablock->{values}{'_units.code'} ) {
                $ddl_datablock->{values}{'_units.code'}[0] =~ s/ /_/g;
                $ddl_datablock->{values}{'_units.code'}[0] =
                    lc $ddl_datablock->{values}{'_units.code'}[0];
                $ddl_datablock->{values}{'_units.code'}[0] =~
                    s/angstroem/angstrom/g;
                $ddl_datablock->{values}{'_units.code'}[0] =~
                    s/electron-?volt/electron_volt/g;
            }

            if( !exists $ddl_datablock->{values}{'_name.category_id'} ) {
                set_tag( $ddl_datablock,
                         '_name.category_id',
                         $category_overview );
            }

            # Uppercase parent categories of other categories to stand out.
            # Assume that _definition.scope is always set to 'Category'.
            if (defined $ddl_datablock->{'values'}{'_definition.scope'}) {
                set_tag( $ddl_datablock,
                         '_name.category_id',
                       uc $ddl_datablock->{'values'}{'_name.category_id'}[0] );
            }

            set_tag( $ddl_datablock, '_definition.id', $name );
            set_tag( $ddl_datablock,
                     '_name.object_id',
                     $ddl_datablock->{values}{'_definition.id'}[0] );

            push @{$ddlm_datablock->{save_blocks}}, $ddl_datablock;
        }
    }

    my %data_name_to_frame =
                        map { uc $_->{'values'}{'_definition.id'}[0] => $_ }
                            @{$ddlm_datablock->{'save_blocks'}};

    move_ddlm_keys_to_category_definitions($ddlm_datablock, \%data_name_to_frame);

    for my $save_frame (@{$ddlm_datablock->{'save_blocks'}}) {
        my $data_name = $save_frame->{'values'}{'_definition.id'}[0];
        if (defined get_dic_item_value( $save_frame, '_list_mandatory' )) {
            # TODO: consider is the value is set to 'yes' or 'no'.
            # Normally, the value is only set to 'yes' as 'no' is the default.
            warn "conversion of data item '$data_name' is lossy -- " .
                 'constraints imposed by the \'_list_mandatory\' DDL1 ' .
                 'attribute cannot be expressed in DDLm.' . "\n";
            exclude_tag( $save_frame, '_list_mandatory' );
        }

        if ( defined get_dic_item_value( $save_frame, '_related_item' ) ||
             defined get_dic_item_value( $save_frame, '_related_function' ) ) {
            warn "conversion of data item '$data_name' is lossy -- " .
                 'the \'_related_item\' and \'_related_function\' DDL1 ' .
                 'attributes will not be automatically translated to DDLm.' .
                 "\n";
            for my $tag ( qw( _related_item _related_function ) ) {
                next if !defined get_dic_item_value( $save_frame, $tag );
                exclude_tag( $save_frame, $tag );
            }
        }

        # This subroutine must be called after converting all of the
        # '_list_link_parent' DDL1 attributes.
        convert_ddl1_child_item_links( $save_frame, \%data_name_to_frame );
    }

    my $dic_version;
    if (defined $new_version) {
        $dic_version = $new_version
    } else {
        $dic_version = '0.0.1' . '+DDL1-version.' .
                       $ddl_datablocks->[0]{'values'}{'_dictionary_version'}[0];
    }

    set_tag( $ddlm_datablock, '_dictionary.title', $dictionary_name );
    set_tag( $ddlm_datablock, '_dictionary.version', $dic_version );
    set_tag( $ddlm_datablock, '_dictionary.date', $date );
    set_tag( $ddlm_datablock, '_dictionary.class', 'Instance' );
    set_tag( $ddlm_datablock, '_dictionary.ddl_conformance', '4.1.0' );

    if( exists $ddl_datablocks->[0]{'values'}{'_dictionary_history'} ) {
        set_loop_tag( $ddlm_datablock,
                      '_dictionary_audit.version',
                      '_dictionary_audit.version',
                      [ $dic_version ] );
        set_loop_tag( $ddlm_datablock,
                      '_dictionary_audit.date',
                      '_dictionary_audit.version',
                      [ $date ] );

        my $old_log_message = $ddl_datablocks->[0]{'values'}
                                                  {'_dictionary_history'}[0];
        $old_log_message =~ s/^(?:[ \t]*\n)*|\s*$//gs;

        my $new_log_message = "\n" .
            'Automatically converted from DDL1 to DDLm.' .
            "\n\n" .
            'History of the original DDL1 dictionary:' .
            "\n\n" .
            $old_log_message;

        set_loop_tag( $ddlm_datablock,
                      '_dictionary_audit.revision',
                      '_dictionary_audit.version',
                      [ $new_log_message ] );
    }

    return $ddlm_datablock;
}

##
# Moves the '_category_key.name' attribute from data item definitions to the
# definitions of parent categories.
#
# Composite keys as well as key items from external dictionaries are currently
# not supported and are silently left unmodified. Invalid definitions are also
# silently left unmodified. 
#
# @param $ddlm_dic_block
#       Reference to a DDLm dictionary data block as returned by the
#       COD::CIF::Parser module.
# @param $data_name_to_frame
#       Reference to a hash data structure in which all definition save frames
#       from a single dictionary are referenced by their main data name.
##
sub move_ddlm_keys_to_category_definitions
{
    my ($ddlm_dic_block, $data_name_to_frame) = @_;

    # Group data items that share the same key.
    my %key_item_to_loop_items;
    for my $save_frame (@{$ddlm_dic_block->{'save_blocks'}}) {
        next if !defined $save_frame->{'values'}{'_category_key.name'};
        # TODO: implement the handling of composite keys.
        next if @{$save_frame->{'values'}{'_category_key.name'}} > 1;
        my $key_name = $save_frame->{'values'}{'_category_key.name'}[0];
        push @{$key_item_to_loop_items{$key_name}}, $save_frame;
    }

    for my $key_item_name (sort keys %key_item_to_loop_items) {
        my $key_item_block = $data_name_to_frame->{uc $key_item_name};

        # TODO: handle key items that are defined in external dictionaries
        # (e.g. _atom_site_label).
        next if !defined $key_item_block;

        my $category_name = $key_item_block->{'values'}{'_name.category_id'}[0];

        # Safeguard against missing category definitions.
        next if !defined $data_name_to_frame->{uc $category_name};
        my $category_block = $data_name_to_frame->{uc $category_name};
        # Avoid overriding existing category keys.
        next if defined $category_block->{'values'}{'_category_key.name'};

        my $move_key_to_category = 0;
        for my $loop_item (@{$key_item_to_loop_items{$key_item_name}}) {
            # Key item and loop item must share the same category. 
            next if uc $loop_item->{'values'}{'_name.category_id'}[0] ne
                    uc $category_name;
            exclude_tag($loop_item, '_category_key.name');
            $move_key_to_category = 1;
        }
        if ($move_key_to_category) {
            set_tag( $category_block, '_category_key.name', $key_item_name );
            set_tag( $category_block, '_definition.class', 'Loop' );
            # A simple non-composite key item is mandatory in a loop
            # and thus satisfies the '_list_mandatory' constraints.
            next if !defined get_dic_item_value( $key_item_block,
                                                 '_list_mandatory' );
            exclude_tag( $key_item_block, '_list_mandatory' );
        }
    }

    return;
}

##
# Converts the '_list_link_child' DDL1 attribute to an equivalent DDLm
# attribute. This subroutine assumes that the '_list_link_parent' DDL1
# attribute in all save frames has already been converted to the DDLm
# equivalent.
#
# @param $save_frame
#       Reference to a save frame that contains a single item or category
#       definition. The overall data structure is identical to that returned
#       by the COD::CIF::Parser.
# @param $data_name_to_frame
#       Reference to a hash data structure in which all definition save frames
#       from a single dictionary are referenced by their main data name.
##
sub convert_ddl1_child_item_links
{
    my ($save_frame, $data_name_to_frame) = @_;

    return if !defined $save_frame->{'values'}{'_list_link_child'};
    my @child_names = @{ $save_frame->{'values'}{'_list_link_child'} };
    my $parent_name = $save_frame->{'values'}{'_definition.id'}[0];
    for my $child_name (@child_names) {
        if (defined $data_name_to_frame->{uc $child_name}) {
            my $child_frame = $data_name_to_frame->{uc $child_name};
            if (defined $child_frame->{'values'}{'_name.linked_item_id'}) {
                my $current_parent_name =
                            $child_frame->{'values'}{'_name.linked_item_id'}[0];
                next if uc $current_parent_name eq uc $parent_name;
                warn "unable to mark item '$child_name' as linked to item " .
                     "'$parent_name' based on the value of the " .
                     "\'_list_link_child\' DDL1 attribute -- item is already " .
                     "linked to the '$current_parent_name' data item" . ".\n";
            } else {
                set_tag( $child_frame, '_name.linked_item_id', $parent_name )
            }
        } else {
            warn "unable to mark item '$child_name' as linked to item " .
                 "'$parent_name' based on the value of the " .
                 "\'_list_link_child\' DDL1 attribute -- item could not be " .
                 "located in the given dictionary" . ".\n";
        }
    }
    exclude_tag( $save_frame, '_list_link_child' );

    return;
}

##
# Converts (in a rather crude way) CIF data block to a DDLm dictionary.
##
sub cif_to_ddlm
{
    my( $dataset ) = @_;

    my $ddlm = new_datablock( 'CIF_PRELIMINARY', '2.0' );

    set_tag( $ddlm, '_dictionary.title', 'CIF_PRELIMINARY' );
    set_tag( $ddlm, '_definition.class', 'Reference' );

    push @{$ddlm->{save_blocks}}, new_datablock( 'PRELIMINARY_GROUP', '2.0' );
    set_tag( $ddlm->{save_blocks}[0], '_definition.id', 'PRELIMINARY_GROUP' );
    set_tag( $ddlm->{save_blocks}[0], '_definition.scope', 'Category' );
    set_tag( $ddlm->{save_blocks}[0], '_definition.class', 'Head' );

    my @loop_names;

    for my $i (0..$#{$dataset->{loops}}) {
        my $loop = $dataset->{loops}[$i];
        my $name = make_category_name( @$loop );
        $name = 'loop' . ( $name ? $name : "_$i" );
        push @loop_names, $name;

        my $description = new_datablock( $name, '2.0' );

        set_tag( $description, '_definition.id', $name );
        set_tag( $description, '_definition.scope', 'Category' );
        set_tag( $description, '_definition.class', 'Loop' );
        set_tag( $description, '_name.category_id', 'PRELIMINARY_GROUP' );

        push @{$ddlm->{save_blocks}}, $description;
    }

    for my $tag (@{$dataset->{tags}}) {
        my $description = new_datablock( $tag, '2.0' );

        set_tag( $description, '_definition.id', $tag );
        set_tag( $description, '_definition.scope', 'Item' );
        set_tag( $description, '_definition.class', 'Attribute' );
        set_tag( $description,
                 '_name.category_id',
                 defined $dataset->{inloop}{$tag}
                    ? $loop_names[$dataset->{inloop}{$tag}]
                    : 'PRELIMINARY_GROUP' );

        push @{$ddlm->{save_blocks}}, $description;
    }

    return $ddlm;
}

sub make_category_name
{
    my @tags = @_;

    if( $tags[0] =~ /^([^\.]+)\./ ) {
        my $prefix = $1;
        return $prefix
            unless grep { my( $p ) = split /\./, $_; $p ne $prefix } @tags;
    }

    return longest_common_tag_prefix( @tags );
}

sub longest_common_tag_prefix
{
    my @strings = @_;
    my( $shortest ) = sort { length($a) <=> length($b) } @strings;

    my @parts = $shortest =~ /([_\.][^_\.]+)/g;
    my $prefix;
    for( my $i = 0; $i < @parts; $i++ ) {
        my $prefix_now = join '', @parts[0..$i];
        last if grep { substr( $_, 0, length( $prefix_now ) ) ne $prefix_now } @strings;
        $prefix = $prefix_now;
    }
    return $prefix;
}

sub dic_filename_to_title
{
    my( $filename ) = @_;
    $filename = uc $filename if $filename =~ s/\.dic$//;
    return $filename;
}

sub get_dic_item_value
{
    my ( $data_frame, $data_name ) = @_;

    my $value;
    if ( exists $data_frame->{'values'}{$data_name} ) {
        $value = $data_frame->{'values'}{$data_name}[0];
    };

    return $value;
}

1;
