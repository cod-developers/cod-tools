%module(package="COD::CIF::Parser::Bison") "COD::CIF::Parser::Bison"
%{
    #include <EXTERN.h>
    #include <perl.h>
    #include <XSUB.h>

    SV * parse_cif( char * fname, char * prog, SV * options );
    SV * parse_cif_string( char * buffer, char * prog, SV * options );
    double unpack_precision( char * value, double precision );
%}

%perlcode %{
use strict;
use warnings;
use Encode qw(decode);

use COD::UserMessage qw( sprint_message );

sub process_parse_result
{
    my( $parse_result, $no_print ) = @_;
    my $data = $parse_result->{datablocks};
    my $messages = $parse_result->{messages};
    my $nerrors = $parse_result->{nerrors};

    foreach my $datablock ( @{$data} ) {
        postprocess_datablock( $datablock, $datablock->{cifversion} );
    }

    my @errors;
    my @warnings;
    foreach my $message ( @{$messages} ) {
        my $datablock = $message->{addpos};
        if( defined $datablock ) {
            $datablock = "data_$datablock";
        }
        my $explanation = $message->{explanation};
        $explanation = lcfirst $explanation if (defined $explanation);
        my $msg = sprint_message( {
            'program'      => $message->{'program'},
            'filename'     => $message->{'filename'},
            'add_pos'      => $datablock,
            'err_level'    => $message->{'status'},
            'message'      => $message->{'message'} .
                             ( defined $explanation ? " -- $explanation" : '' ),
            'line_no'      => $message->{'lineno'},
            'column_no'    => $message->{'columnno'},
            'line_content' => $message->{'line'}
        } );
        $msg = decode( 'utf8', $msg );

        if( $message->{status} eq 'ERROR' ) {
            push @errors, $msg;
        } else {
            push @warnings, $msg;
        }
    }

    if( !$no_print ) {
        print STDERR $_ foreach( @warnings );
        my $last_error = pop @errors;
        print STDERR $_ foreach( @errors );
        if (defined $last_error) {
            die $last_error;
        }
    }

    unshift @errors, @warnings;

    return( $data, $nerrors, \@errors );
}

sub parse
{
    my( $filename, $options ) = @_;
    $options = {} unless $options;
    my $parse_result = parse_cif( $filename, $0, $options );
    my( $data, $nerrors, $errors ) =
        process_parse_result( $parse_result, $options->{no_print} );

    if( wantarray ) {
        return( $data, $nerrors, $errors );
    } else {
        return $data;
    }
}

sub parse_string
{
    my( $buffer, $options ) = @_;
    $options = {} unless $options;
    my $parse_result = parse_cif_string( $buffer, $0, $options );
    my( $data, $nerrors, $errors ) =
        process_parse_result( $parse_result, $options->{no_print} );

    if( wantarray ) {
        return( $data, $nerrors, $errors );
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

    if( ref $options eq 'HASH' ) {
        $self->{USER}{OPTIONS} = $options;
    }

    return $data;
}

sub YYData
{
    my( $self ) = @_;
    return $self->{YYData};
}

sub postprocess_datablock
{
    my( $datablock, $cifversion ) = @_;

    $datablock->{cifversion}{major} = $cifversion->{major};
    $datablock->{cifversion}{minor} = $cifversion->{minor};
    $datablock->{precisions} = {};
    foreach my $tag ( keys %{$datablock->{types}} ) {
        my( $precisions ) =
            extract_precision( $datablock->{values}{$tag},
                               $datablock->{types}{$tag} );
        if( defined $precisions ) {
            $datablock->{precisions}{$tag} = $precisions;
        }
    }
    foreach my $saveblock ( @{$datablock->{'save_blocks'}} ) {
        postprocess_datablock( $saveblock, $cifversion );
    }
}

sub extract_precision
{
    my( $values, $types ) = @_;
    if( ref( $types ) eq 'ARRAY' ) {
        my @precisions;
        my @important;
        for( my $i = 0; $i < @{$values}; $i++ ) {
            my( $precision, $is_important ) =
                extract_precision( $values->[$i], $types->[$i] );
            push @precisions, $precision;
            push @important, $is_important;
        }
        if( grep { $_ == 1 } @important ) {
            return ( \@precisions, 1 );
        } else {
            return ( undef, 0 );
        }
    } elsif( ref( $types ) eq 'HASH' ) {
        my %precisions;
        foreach (keys %{$values}) {
            my( $precision, $is_important ) =
                extract_precision( $values->{$_}, $types->{$_} );
            next if !$is_important;
            $precisions{$_} = $precision;
        }
        if( %precisions ) {
            return ( \%precisions, 1 );
        } else {
            return ( undef, 0 );
        }
    } elsif( $types eq 'FLOAT' ) {
        if( $values =~ /^(.*)( \( ([0-9]+) \) )$/sx ) {
            return ( unpack_precision( $1, $3 ), 1 );
        } else {
            return ( undef, 1 );
        }
    } elsif( $types eq 'INT' ) {
        if( $values =~ /^(.*)( \( ([0-9]+) \) )$/sx ) {
            return ( $3, 1 );
        } else {
            return ( undef, 1 );
        }
    } else {
        return ( undef, 0 );
    }
}

%}

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

SV * parse_cif( char * fname, char * prog, SV * options );
SV * parse_cif_string( char * buffer, char * prog, SV * options );
double unpack_precision( char * value, double precision );
