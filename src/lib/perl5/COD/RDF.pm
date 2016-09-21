#------------------------------------------------------------------------------
#$Author: antanas $
#$Date: 2015-11-20 16:05:15 +0200 (Fri, 20 Nov 2015) $ 
#$Revision: 4318 $
#$URL: svn://www.crystallography.net/cod-tools/trunk/src/lib/perl5/COD/CIF/Data.pm $
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

    my $rdf = '';

    if( $options->{print_header} ) {
        $rdf .= "<?xml version=\"1.0\"?>\n" .
                "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"";
        $rdf .= "\n" if keys %{$options->{vocabularies}} > 0;
        $rdf .= join( "\n", map { ' ' x 9 . "xmlns:$_=\"$options->{vocabularies}{$_}\"" }
                           sort keys %{$options->{vocabularies}} ) . ">\n";
    }

    for my $struct (@$data) {
        $rdf .= "  <rdf:Description rdf:about=\"$options->{url_prefix}" .
                $struct->{file} . "$options->{url_postfix}\">\n";

        if( exists $struct->{links} ) {
            for my $prop (sort { $a->{db} cmp $b->{db} ||
                                 $a->{ext_id} cmp $b->{ext_id} }
                               @{$struct->{links}}) {
                my $db = $prop->{db};
                $rdf .= "    <$prop->{vocabulary}:$prop->{relation}\n" .
                        "     rdf:resource=\"" .
                        $options->{databases}{$db}->{url_prefix} .
                        $prop->{ext_id} .
                        $options->{databases}{$db}->{url_postfix} .
                        "\" />\n";
            }
        }

        for my $field (sort keys %$struct) {
            next if $field eq 'file' || $field eq 'links';
            next if !$struct->{$field};
            $struct->{$field} = decode( 'UTF-8', $struct->{$field} );
            $struct->{$field} = encode_entities( $struct->{$field},
                                                 "\"'<>\&" );
            if( $field ne 'authors' || !$options->{split_author_names} ) {
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
                            } split /\s*;\s*/, $struct->{$field} ) . "\n";
            }
        }
        $rdf .= "  </rdf:Description>\n";
    }

    $rdf .= "</rdf:RDF>\n" if $options->{print_footer};

    return $rdf;
}

sub rdf_n3
{
}

sub rdf_ntriples
{
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
