#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Common subroutines for RDF generation.
#**

package COD::RDF;

use strict;
use warnings;
use Encode qw( decode );
use HTML::Entities qw( encode_entities );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    rdf_n3
    rdf_ntriples
    rdf_xml
);

sub rdf_xml
{
    my( $data, $options ) = @_;
    $options = {} unless $options;

    $options->{print_header} = 1  if !exists $options->{print_header};
    $options->{print_footer} = 1  if !exists $options->{print_footer};
    $options->{vocabularies} = {} if !exists $options->{vocabularies};
    $options->{databases}    = {} if !exists $options->{databases};
    $options->{utf_code_point_format} = '&#x%04X;'
        if !exists $options->{utf_code_point_format};
    $options->{split_author_names} = 1
        if !exists $options->{split_author_names};
    $options->{decode} = 1 if !exists $options->{decode};

    my $rdf = '';

    if( $options->{print_header} ) {
        $rdf .= "<?xml version=\"1.0\"?>\n" .
                "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"";
        $rdf .= "\n" if keys %{$options->{vocabularies}} > 0;
        $rdf .= join( "\n", map { ' ' x 9 . "xmlns:$_=\"$options->{vocabularies}{$_}\"" }
                           sort keys %{$options->{vocabularies}} ) . ">\n";
    }

    for my $struct (@$data) {
        $rdf .= "  <rdf:Description rdf:about=\"$struct->{url}\">\n";

        if( exists $struct->{links} ) {
            for my $prop (sort { $a->{db} cmp $b->{db} ||
                                 $a->{ext_id} cmp $b->{ext_id} }
                               @{$struct->{links}}) {
                my $db = $prop->{db};
                $rdf .= "    <$prop->{vocabulary}:$prop->{relation}\n" .
                        "     rdf:resource=\"" .
                        $options->{databases}{$db}{url_prefix} .
                        $prop->{ext_id} .
                        $options->{databases}{$db}{url_postfix} .
                        "\" />\n";
            }
        }

        for my $field (sort keys %$struct) {
            next if $field eq 'file' || $field eq 'links' || $field eq 'url';
            next if !$struct->{$field};
            $struct->{$field} = decode( 'UTF-8', $struct->{$field} )
                if $options->{decode};
            if( $field ne 'authors' || !$options->{split_author_names} ) {
                $struct->{$field} = encode_entities( $struct->{$field},
                                                     "\"'<>\&" );
                if( defined $options->{replace_utf_code_points_from} ) {
                    $struct->{$field} =
                        replace_utf_codepoints( $struct->{$field},
                                                $options->{replace_utf_code_points_from},
                                                $options->{utf_code_point_format} );
                }
                $rdf .= "    <$options->{vocabulary_name}:$field>" .
                        $struct->{$field} .
                        "</$options->{vocabulary_name}:$field>\n";
            } else {
                $rdf .= join( "\n",
                            map { "    <$options->{vocabulary_name}:author>" .
                                 ( defined $options->{replace_utf_code_points_from}
                                     ? replace_utf_codepoints( $_,
                                               $options->{replace_utf_code_points_from},
                                               $options->{utf_code_point_format} )
                                     : $_ ) .
                                 "</$options->{vocabulary_name}:author>"
                            }
                            map { encode_entities( $_, "\"'<>\&" ) }
                            split /\s*;\s*/, $struct->{$field} ) . "\n";
            }
        }
        $rdf .= "  </rdf:Description>\n";
    }

    $rdf .= "</rdf:RDF>\n" if $options->{print_footer};

    return $rdf;
}

# Implemented as described in http://www.w3.org/TeamSubmission/n3/#grammar
# A similar parser and validator can be found at
# http://www.rdfabout.com/demo/validator/validate.xpd
sub rdf_n3
{
    my( $data, $options ) = @_;
    $options = {} unless $options;

    $options->{print_header} = 1  if !exists $options->{print_header};
    $options->{print_footer} = 1  if !exists $options->{print_footer};
    $options->{vocabularies} = {} if !exists $options->{vocabularies};
    $options->{databases}    = {} if !exists $options->{databases};
    $options->{utf_code_point_format} = '&#x%04X;'
        if !exists $options->{utf_code_point_format};
    $options->{split_author_names} = 1
        if !exists $options->{split_author_names};
    $options->{decode} = 1 if !exists $options->{decode};

    my $rdf = '';

    if( $options->{print_header} ) {
        $rdf .= "\@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>.\n" .
                join( "\n", map { "\@prefix $_: <$options->{vocabularies}{$_}>." }
                                sort keys %{$options->{vocabularies}} ) . "\n";
        $rdf .= "\n" if keys %{$options->{vocabularies}} > 0;
    }

    for my $struct (@$data) {
        $rdf .= "<$struct->{url}>\n";

        if( exists $struct->{links} ) {
            for my $prop (sort { $a->{db} cmp $b->{db} ||
                                 $a->{ext_id} cmp $b->{ext_id} }
                               @{$struct->{links}}) {
                my $db = $prop->{db};
                $rdf .= "  $prop->{vocabulary}:$prop->{relation} <" .
                        $options->{databases}{$db}{url_prefix} .
                        $prop->{ext_id} .
                        $options->{databases}{$db}{url_postfix} . ">;\n";
            }
        }

        my $first_line = 1;
        for my $field (sort keys %$struct) {
            next if $field eq 'file' || $field eq 'links' || $field eq 'url';
            next if !$struct->{$field};

            $rdf .= ";\n" if !$first_line;
            $struct->{$field} = decode( 'UTF-8', $struct->{$field} )
                if $options->{decode};
            # Escaping special symbols with "\"
            $struct->{$field} =~ s/((['"\\]))/\\$1/g;
            $struct->{$field} =~ s/\n/\\n/g;
            $struct->{$field} =~ s/\r/\\r/g;
            $struct->{$field} =~ s/\t/\\t/g;
            if( $field ne 'authors' || !$options->{split_author_names} ) {
                # Adding '"' or '"""'quotes on a literal
                $struct->{$field} = quote_literals( $struct->{$field} );
                if( defined $options->{replace_utf_code_points_from} ) {
                    $struct->{$field} =
                        replace_utf_codepoints( $struct->{$field},
                                                $options->{replace_utf_code_points_from},
                                                $options->{utf_code_point_format} );
                }
                $rdf .= "  $options->{vocabulary_name}:$field " .
                        $struct->{$field};
            } else {
                $rdf .= "  $options->{vocabulary_name}:author ";
                my $length = length( "  $options->{vocabulary_name}:author " );
                my $authors = (join( ",\n",
                                map { defined $options->{replace_utf_code_points_from}
                                          ? replace_utf_codepoints(
                                              ( ' ' x $length ) . quote_literals($_),
                                              $options->{replace_utf_code_points_from},
                                              $options->{utf_code_point_format} )
                                          : ( ' ' x $length ) . quote_literals($_)
                                } split /\s*;\s*/, $struct->{$field} ) );
                $authors =~ s/\s*//;
                $rdf .= $authors;
            }
            $first_line = 0;
        }
        $rdf .= ".\n";
    }

    return $rdf;
}

# Implemented as described in http://www.w3.org/TR/n-triples/#canonical-ntriples
# A similar parser and validator can be found at
# http://www.rdfabout.com/demo/validator/validate.xpd
sub rdf_ntriples
{
    my( $data, $options ) = @_;
    $options = {} unless $options;

    $options->{vocabularies} = {} if !exists $options->{vocabularies};
    $options->{databases}    = {} if !exists $options->{databases};
    $options->{utf_code_point_format} = '&#x%04X;'
        if !exists $options->{utf_code_point_format};
    $options->{split_author_names} = 1
        if !exists $options->{split_author_names};
    $options->{decode} = 1 if !exists $options->{decode};

    my $rdf = '';

    for my $struct (@$data) {
        my $subject = "<$struct->{url}>";

        if( exists $struct->{links} ) {
            for my $prop (sort { $a->{db} cmp $b->{db} ||
                                 $a->{ext_id} cmp $b->{ext_id} }
                               @{$struct->{links}}) {
                my $db = $prop->{db};
                $rdf .= $subject .
                      " <$options->{vocabulary_url_prefix}$prop->{relation}>" .
                      " <$options->{databases}{$db}{url_prefix}$prop->{ext_id}" .
                      $options->{databases}{$db}{url_postfix} . ">.\n";
            }
        }

        for my $field (sort keys %$struct) {
            next if $field eq 'file' || $field eq 'links' || $field eq 'url';
            next if !$struct->{$field};

            $struct->{$field} = decode( 'UTF-8', $struct->{$field} )
                if $options->{decode};
            # Escaping special symbols with "\"
            $struct->{$field} =~ s/((["\\]))/\\$1/g;
            $struct->{$field} =~ s/\n/\\n/g;
            $struct->{$field} =~ s/\r/\\r/g;
            $struct->{$field} =~ s/\t/\\t/g;
            if( $field ne 'authors' || !$options->{split_author_names} ) {
                # Adding '"' quotes on a literal
                $struct->{$field} = '"' . $struct->{$field} . '"';
                if( defined $options->{replace_utf_code_points_from} ) {
                    $struct->{$field} =
                        replace_utf_codepoints( $struct->{$field},
                                                $options->{replace_utf_code_points_from},
                                                $options->{utf_code_point_format} );
                }
                $rdf .= "$subject <$options->{vocabulary_url_prefix}$field> " .
                        $struct->{$field} . ".\n";
            } else {
                foreach my $object ( split( /\s*;\s*/, $struct->{$field} ) ) {
                    if( defined $options->{replace_utf_code_points_from} ) {
                        $object = replace_utf_codepoints ( $object,
                                                $options->{replace_utf_code_points_from},
                                                $options->{utf_code_point_format} );
                    }

                    $rdf .= "$subject <$options->{vocabulary_url_prefix}author> " .
                            '"' . $object . '"' . ".\n";
                }
            }
        }
    }

    return $rdf;
}

sub quote_literals
{
    my ( $string ) = @_;
    if ( $string =~ m/(\n|'|")/ ) {
        $string = '"""' . $string . '"""';
    } else {
        $string = '"' . $string . '"';
   }
   return $string;
}

sub replace_utf_codepoints
{
    my ( $string, $from, $format ) = @_;
    my $hex = sprintf( "%x", $from );
    $string =~
        s/([\x{$hex}-\x{7FFFFFFF}])/sprintf($format, ord($1))/eg;
    return $string;
}

1;
