%module CCIFParserSWIG
%{
    #include <EXTERN.h>
    #include <perl.h>
    #include <XSUB.h>
    #include <stdio.h>
    #include <stdlib.h>
    #include <unistd.h>
    #include <setjmp.h>
    #include <string.h>
    #include <cif_grammar_y.h>
    #include <cif_grammar_flex.h>
    #include <allocx.h>
    #include <cxprintf.h>
    #include <getoptions.h>
    #include <cexceptions.h>
    #include <stdiox.h>
    #include <stringx.h>
    #include <stdarg.h>
    #include <yy.h>
    #include <assert.h>
    #include <cif.h>
    #include <datablock.h>

    SV * parse_cif( char * fname, char * prog );
%}

%perlcode %{
use Precision;
sub parse
{
    my( $filename, $options ) = @_;
    my $parse_result = parse_cif( $filename, $0 );
    my $data = $parse_result->{datablocks};
    my $nerrors = $parse_result->{nerrors};

    foreach my $datablock ( @$data ) {
        $datablock->{precisions} = {};
        foreach my $tag   ( keys %{$datablock->{types}} ) {
            my @prec;
            my $has_numeric_values = 0;
            for( my $i = 0; $i < @{$datablock->{types}{$tag}}; $i++ ) {
                next unless $datablock->{types}{$tag}[$i] eq "INT" ||
                            $datablock->{types}{$tag}[$i] eq "FLOAT";
                $has_numeric_values = 1;
                if(         $datablock->{types}{$tag}[$i] eq "FLOAT" &&
                            $datablock->{values}{$tag}[$i] =~
                            m/^(.*)( \( ([0-9]+) \) )$/six ) {
                            $prec[$i] = unpack_precision( $1, $3 );
                } elsif(    $datablock->{types}{$tag}[$i] eq "INT" &&
                            $datablock->{values}{$tag}[$i] =~
                            m/^(.*)( \( ([0-9]+) \) )$/sx ) {
                            $prec[$i] = $3;
                }
            }
            if( @prec > 0 || ( exists $datablock->{inloop}{$tag} &&
                $has_numeric_values ) ) {
                if( @prec < @{$datablock->{types}{$tag}} ) {
                    $prec[ @{$datablock->{types}{$tag}} - 1 ] = undef;
                }
                $datablock->{precisions}{$tag} = \@prec;
            }
        }
    }

    if( wantarray ) {
        return( $data, $nerrors );
    } else {
        return $data;
    }
}
%}

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <setjmp.h>
#include <string.h>
#include <cif_grammar_y.h>
#include <cif_grammar_flex.h>
#include <allocx.h>
#include <cxprintf.h>
#include <getoptions.h>
#include <cexceptions.h>
#include <stdiox.h>
#include <stringx.h>
#include <stdarg.h>
#include <yy.h>
#include <assert.h>
#include <cif.h>
#include <datablock.h>

SV * parse_cif( char * fname, char * prog );
