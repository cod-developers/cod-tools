#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Subroutines that provide a functional interface to COD::CIF::Parser::Yapp
#  and COD::CIF::Parser::Bison CIF parsers.
#**

package COD::CIF::Parser;

use strict;
use warnings;
use COD::CIF::Parser::Yapp;
use COD::UserMessage qw( warning error );
use COD::CIF::JSON;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( parse_cif );

my $default_options = {
    'fix_errors' => 0,
    'fix_non_ascii_symbols' => 0,
    'fix_duplicate_tags_with_same_values' => 0,
    'fix_duplicate_tags_with_empty_values' => 0,
    'fix_data_header' => 0,
    'fix_datablock_names' => 0,
    'fix_string_quotes' => 0,
    'fix_missing_closing_double_quote' => 0,
    'fix_missing_closing_single_quote' => 0,
    'fix_ctrl_z' => 0,
    'allow_uqstring_brackets' => 0,
    'do_not_unprefix_text' => 0,
    'do_not_unfold_text' => 0,
    'no_print' => 0,
    'reporter' => undef,
    'parser' => 'c'
};

sub parse_cif
{
    my ($filename, $options) = @_;

    if ( !defined $options ) {
        $options = {};
    } elsif( ref $options ne "HASH" ) {
        error( {
            'program'  => $0,
            'filename' => $filename,
            'message'  =>
                'options for the CIF parser should be provided ' .
                'via a hash reference'
        } );
        exit 1;
    }

    my $unrecognised;
    ($options, $unrecognised) = check_options($options, $default_options);
    foreach ( @$unrecognised ) {
        warning( {
            'program'  => $0,
            'filename' => $filename,
            'message'  => "option '$_' is not supported by the CIF parser"
        } );
    }

    my $parser;
    if ( $options->{parser} eq 'c' ) {
        use COD::CIF::Parser::Bison;
        $parser = new COD::CIF::Parser::Bison;
    } elsif ( $options->{parser} eq 'perl' ) {
        $parser = new COD::CIF::Parser::Yapp;
    } elsif ( $options->{parser} eq 'json' ) {
        $parser = new COD::CIF::JSON;
    } else {
        error( {
            'program'  => $0,
            'filename' => $filename,
            'message'  =>
                "parser type '" . $options->{parser} . "' is not recognised " .
                "-- please select either 'c' or 'perl' CIF parsers"
        } );
        exit 1;
    }

    if ($options->{parser} eq 'c') {
        if ( defined $options->{reporter} ) {
            warning( {
                'program'  => $0,
                'filename' => $filename,
                'message'  =>
                    "option 'reporter' is only supported by the perl " .
                    'CIF parser -- option will be ignored'
            } );
            delete $options->{reporter};
        }
    }
    # 'parser' option should not be passed to the parser itself
    delete $options->{parser}; 

    my $data = $parser->Run($filename, $options);

    return ( $data,
             $parser->YYData->{ERRCOUNT},
             $parser->YYData->{ERROR_MESSAGES} );
}

sub check_options
{
    my ($options, $default_options) = @_;

    my %checked_options;
    my @unrecognised_options;

    foreach my $key (keys %{$options}) {
        if ( !exists $default_options->{$key} ) {
            push @unrecognised_options, $key;
        }
        $checked_options{$key} = $$options{$key};
    }

    foreach my $key (keys %{$default_options}) {
        if ( !defined $checked_options{$key} ) {
            $checked_options{$key} = $$default_options{$key};
        }
    }

    return \%checked_options, \@unrecognised_options;
}

1;
