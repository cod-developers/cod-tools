%module(package="COD::CIF::Parser::Bison") "COD::CIF::Parser::Bison"
%{
    #include <EXTERN.h>
    #include <perl.h>
    #include <XSUB.h>

    SV * parse_cif( char * fname, char * prog, SV * options );
%}

%perlcode %{
use COD::Precision qw( unpack_precision );
use COD::UserMessage qw( sprint_message );

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
            $datablock->{precisions}{$tag} =
                extract_precision( $datablock->{values}{$tag},
                                   $datablock->{types}{$tag} );
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
        return( $data, $nerrors, \@errors );
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

sub extract_precision
{
    my( $values, $types ) = @_;
    if( ref( $types ) eq 'ARRAY' ) {
        my @precisions;
        for( my $i = 0; $i < @$values; $i++ ) {
            push @precisions,
                extract_precision( $values->[$i], $types->[$i] );
        }
        return \@precisions;
    } elsif( ref( $types ) eq 'HASH' ) {
        my %precisions;
        foreach (keys %$values) {
            $precisions{$_} =
                extract_precision( $values->{$i}, $types->{$i} );
        }
        return \%precisions;
    } elsif( $types eq 'FLOAT' ) {
        if( $values =~ /^(.*)( \( ([0-9]+) \) )$/sx ) {
            return unpack_precision( $1, $3 );
        } else {
            return undef;
        }
    } elsif( $types eq 'INT' ) {
        if( $values =~ /^(.*)( \( ([0-9]+) \) )$/sx ) {
            return $3;
        } else {
            return undef;
        }
    } else {
        return undef;
    }
}

%}

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

SV * parse_cif( char * fname, char * prog, SV * options );
