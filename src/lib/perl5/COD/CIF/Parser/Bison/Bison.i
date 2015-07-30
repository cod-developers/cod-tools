%module(package="COD::CIF::Parser::Bison") "COD::CIF::Parser::Bison"
%{
    #include <EXTERN.h>
    #include <perl.h>
    #include <XSUB.h>
    #include <cif_grammar_y.h>
    #include <cif_grammar_flex.h>
    #include <allocx.h>
    #include <cxprintf.h>
    #include <getoptions.h>
    #include <cexceptions.h>
    #include <stdiox.h>
    #include <stringx.h>
    #include <yy.h>
    #include <cif.h>
    #include <datablock.h>
    #include <cifmessage.h>

    SV * parse_cif( char * fname, char * prog, SV * options );
%}

%perlcode %{
use COD::Precision;
use COD::UserMessage;

sub parse
{
    my( $filename, $options ) = @_;
    $options = {} unless $options;
    my $parse_result = parse_cif( $filename, $0, $options );
    my $data = $parse_result->{datablocks};
    my $messages = $parse_result->{messages};
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

    use strict;
    use warnings;

    my @errors;
    my @warnings;
    foreach my $message ( @$messages ) {
        my $datablock = $message->{addpos};
        if( defined $datablock ) {
            $datablock = "data_$datablock";
        }
        my $explanation = $message->{explanation};
        $explanation = lcfirst $explanation if (defined $explanation);
        my $msg = sprint_message( $message->{program},
                                  $message->{filename},
                                  $datablock,
                                  $message->{status},
                                  $message->{message},
                                  $explanation,
                                  $message->{lineno},
                                  $message->{columnno},
                                  $message->{line} );

        if( $message->{status} eq "ERROR" ) {
            push @errors, $msg;
        } else {
            push @warnings, $msg;
        }
    }

    if( !exists $options->{no_print} || $options->{no_print} == 0 ) {
        print STDERR $_ foreach( @warnings );
        my $last_error = pop @errors;
        print STDERR $_ foreach( @errors );
        if (defined $last_error) {
            die $last_error;
            push @errors, $last_error;
        }
    }

    unshift @errors, @warnings;

    if( wantarray ) {
        return( $data, $nerrors, \@warnings );
    } else {
        return $data;
    }
}

sub new
{
    my( $class ) = @_;
    my $self = {};
    bless( $self, $class );
    return $self;
}

sub Run
{
    my( $self, $filename, $options ) = @_;
    my( $data, $nerrors, $error_messages ) = parse( $filename, $options );

    $self->{YYData} = { ERRCOUNT => $nerrors,
                        ERROR_MESSAGES => $error_messages };

    if( ref $options eq "HASH" ) {
        $self->{USER}{OPTIONS} = $options;
    }

    return $data;
}

sub YYData
{
    my( $self ) = @_;
    return $self->{YYData};
}

%}

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <cif_grammar_y.h>
#include <cif_grammar_flex.h>
#include <allocx.h>
#include <cxprintf.h>
#include <getoptions.h>
#include <cexceptions.h>
#include <stdiox.h>
#include <stringx.h>
#include <yy.h>
#include <cif.h>
#include <datablock.h>
#include <cifmessage.h>

SV * parse_cif( char * fname, char * prog, SV * options );
