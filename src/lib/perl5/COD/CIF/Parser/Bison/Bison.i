%module(package="COD::CIF::Parser::Bison") "COD::CIF::Parser::Bison"
%{
    #include <EXTERN.h>
    #include <perl.h>
    #include <XSUB.h>

    SV * parse_cif( char * fname, char * prog, SV * options );
%}

%perlcode %{
use strict;
use warnings;
use Encode qw(decode);

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
        foreach my $tag ( keys %{$datablock->{types}} ) {
            my $precisions =
                extract_precision( $datablock->{values}{$tag},
                                   $datablock->{types}{$tag},
                                   exists $datablock->{inloop}{$tag} );
            if( defined $precisions ) {
                $datablock->{precisions}{$tag} = $precisions;
            }
        }
        foreach my $saveblock ( @{$datablock->{'save_blocks'}} ) {
            $saveblock->{'precisions'} = {};
            foreach my $tag ( keys %{$saveblock->{types}} ) {
                my $precisions =
                    extract_precision( $saveblock->{values}{$tag},
                                       $saveblock->{types}{$tag},
                                       exists $saveblock->{inloop}{$tag} );
                if( defined $precisions ) {
                    $saveblock->{precisions}{$tag} = $precisions;
                }
            }
        }
    }

    $data = [ map { decode_utf8_frame($_) } @{$data} ];

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
    my( $values, $types, $is_in_loop ) = @_;
    if( ref( $types ) eq 'ARRAY' ) {
        my @precisions;
        for( my $i = 0; $i < @$values; $i++ ) {
            push @precisions,
                extract_precision( $values->[$i], $types->[$i] );
        }
        if( grep( defined $_, @precisions ) ||
            grep( ref $_, @$types ) ||
            ( $is_in_loop && grep { $_ eq 'INT' || $_ eq 'FLOAT' } @$types ) ) {
            return \@precisions;
        } else {
            return undef;
        }
    } elsif( ref( $types ) eq 'HASH' ) {
        my %precisions;
        foreach (keys %$values) {
            $precisions{$_} =
                extract_precision( $values->{$_}, $types->{$_} );
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

sub decode_utf8_frame
{
    my ( $frame ) = @_;

    foreach ( 'name', 'tags', 'loops' ) {
        if ( exists $frame->{$_} ) {
            $frame->{$_} = decode_utf8_values($frame->{$_});
        };
    }

    foreach ( 'precisions', 'inloop', 'values', 'types' ) {
        if ( exists $frame->{$_} ) {
            $frame->{$_} = decode_utf8_hash_keys($frame->{$_});
        };
    }

    if ( exists $frame->{'values'} &&  exists $frame->{'types'} ) {
        $frame->{'values'} = decode_utf8_typed_values($frame->{'values'},
                                                      $frame->{'types'});
    }

    if ( exists $frame->{'save_blocks'} ) {
        $frame->{'save_blocks'} = [ map { decode_utf8_frame($_) }
                                        @{$frame->{'save_blocks'}} ];
    }

    return $frame;
}

sub decode_utf8_hash_keys
{
    my ( $values ) = @_;

    if ( ref( $values ) eq 'ARRAY' ) {
        for( my $i = 0; $i < @{$values}; $i++ ) {
            $values->[$i] = decode_utf8_hash_keys($values->[$i]);
        }
    } elsif ( ref( $values ) eq 'HASH' ) {
        foreach my $key ( keys %{$values} ) {
           $values->{$key} = decode_utf8_hash_keys($values->{$key});
           my $new_key = decode_utf8_values($key);
           if ($new_key ne $key) {
               $values->{$new_key} = $values->{$key};
               delete $values->{$key};
           }
        }
    }

    return $values;
}

sub decode_utf8_values
{
    my ( $values ) = @_;

    if ( ref( $values ) eq 'ARRAY' ) {
        for( my $i = 0; $i < @{$values}; $i++ ) {
            $values->[$i] = decode_utf8_values($values->[$i]);
        }
    } elsif ( ref( $values ) eq 'HASH' ) {
        foreach my $key ( keys %{$values} ) {
           $values->{$key} = decode_utf8_values($values->{$key});
        }
    } else {
        $values = decode('utf8', $values);
    }

    return $values;
}

sub decode_utf8_typed_values
{
    my ( $values, $types ) = @_;

    if ( ref( $values ) eq 'ARRAY' ) {
        for( my $i = 0; $i < @{$values}; $i++ ) {
            $values->[$i] = decode_utf8_typed_values($values->[$i], $types->[$i]);
        }
    } elsif ( ref( $values ) eq 'HASH' ) {
        foreach my $key ( keys %{$values} ) {
           $values->{$key} = decode_utf8_typed_values($values->{$key}, $types->{$key});
        }
    } elsif ( $types ne 'INT' && $types ne 'FLOAT' ) {
        $values = decode_utf8_values($values);
    }

    return $values;
}

%}

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

SV * parse_cif( char * fname, char * prog, SV * options );
