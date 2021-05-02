#------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------
#*
#  Simple option processing package
#**

package COD::SOptions;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    getOptions
    get_value
    get_int
    get_ints
    get_float
    get_floats
);

my @args;

sub getOptions
{
    my %options = @_;
    my @files = ();
    @args = map { /^-[-\w]+=/o ? split( /=/, $_, 2) : $_ } @ARGV;

    %options = map { my @synonims = split( /,/, $_ );
                     my $value = $options{$_};
                     map {($_,$value)} @synonims } keys %options;

    while( @args ) {

        if( $args[0] =~ /^@/ ) {
            splice( @args, 0, 1, interpolate_file( $args[0] ) );
        }
        if( $args[0] !~ /^-/ ) { push( @files, shift( @args ) ); next; }
        if( $args[0] eq '-'  ) { push( @files, shift( @args ) ); next; }
        if( $args[0] eq '--' ) { shift @args; return ( @files, @args ); }

        my @matches = ();
        if( exists $options{$args[0]} ) {
            @matches = ( $args[0] );
        } elsif( $args[0] !~ /^-[^-]/ ) {
            foreach ( keys( %options ) ) {
                if( /^\Q$args[0]\E/ ) {
                    push( @matches, $_ );
                }
            }
        }

        if( @matches > 1 ) {
            my $matches = join ', ', map { "'$_'" } @matches;
            die "$0:: ERROR, option prefix '$args[0]' is not unique -- "
              . "possible options are $matches" . ".\n";
        } elsif( @matches == 1 ) {
            my $var = $options{$matches[0]};
            for( ref( $var ) ) {
                if( /ARRAY/ )  { push( @{$var}, get_value() ); last }
                if( /HASH/ )   { $var->{$matches[0]} = get_value(); last }
                if( /SCALAR/ ) { ${$var} = get_value(); last }
                if( /CODE/ )   { &{$var}; last }
            }
            shift @args;
        } else {
            die "$0:: ERROR, unknown option '$args[0]'.\n";
        }
    } # while
    return @files;
}

sub get_value
{
    my $option = shift @args;
    if( @args == 0 ) {
        die "$0:: ERROR, missing argument to option '$option'.\n";
    }
    return $args[0] =~ /^@/ ?
        scalar( interpolate_file( substr( $args[0], 0 ), $option ) ) :
        $args[0];
}

#-----------------------------------------------------------------------------

my $integer = '[-+]? [0-9]+';
my $float = '[-+]? ([0-9]+(\.[0-9]*)? | (\.[0-9]+)) ([eE][-+]?[0-9]+)?';

sub get_int
{
    my $option = $args[0];
    my $value = get_value();
    if ( $value !~ /^ \s* $integer \s* $/x ) {
        die "$0:: ERROR, option '$option' requires one integer argument.\n";
    }
    return $value;
}

sub get_float
{
    my $option = $args[0];
    my $value = get_value();
    if ( $value !~ /^ \s* $float \s* $/x ) {
        die "$0:: ERROR, option '$option' requires one floating-point "
          . "argument.\n";
    }
    return $value;
}

sub get_ints
{
    my $option = $args[0];
    my $value = get_value();
    if ( $value !~ /^ \s* (?:$integer\s*)+ \s* $/x ) {
        die "$0:: ERROR, option '$option' requires one or several "
          . "integer arguments.\n";
    }
    return $value;
}

sub get_floats
{
    my $option = $args[0];
    my $value = get_value();
    if ($value !~ /^ \s* (?:$float\s*)+ \s* $/x) {
        die "$0:: ERROR, option '$option' requires one or several "
          . "floating-point arguments.\n";
    }
    return $value;
}

#-----------------------------------------------------------------------------

sub interpolate_file
{
    my ($file_name, $option) = @_;
    my $noat_file_name = substr( $file_name, 1 );

    if( -f $noat_file_name && -f $file_name ) {
        warn "$0:: WARNING, both '$noat_file_name' and '$file_name' files "
           . "exist -- taking options from file '$file_name'.\n";
    } elsif( !-f $file_name ) {
        $file_name = $noat_file_name;
    }

    open( my $file, '<', $file_name ) or do {
        die "$0: $file_name: ERROR, could not open file -- " . lcfirst($!)
          . ( $option
               ? ". The filename was given as an argument for option '$option'"
               : '' ) . ".\n";
    };

    my $return;
    if( wantarray ) {
        foreach ( grep { !/^\s*#|^\s*$/ } <$file> ) {
            chomp($_);
            s/\s*$//;
            if( /^\s*-/ ) {
                my @file_line =
                    # split option/value pairs with '=':
                    # '--option=value' becomes '--option value':
                    /^\s*-{1,2}[^\s=]+\s*=/ ?
                        split(/=/,$_, 2) : split(' ',$_, 2);

                # remove trailing spaces from the option name, if any:
                if ( $file_line[0] ) { $file_line[0] =~ s/\s+$//g };

                # remove quotes around the option values, to emulate
                # shell behaviour:
                # '--option "value"' becomes '--option value'
                # Note, however, that the 'value' will never be passed
                # to shell, so the spaces in the 'value' will be processed
                # correctly:
                # '--option "1 2 3"' will be interpreted as --option with
                # an argument '1 2 3'
                if ( $file_line[1] ) {
                    $file_line[1] =~ s/^\s*['"]?|["']?\s*$//g
                };

                push @{$return}, @file_line;
            } else {
                push @{$return}, $_;
            }
        }
    } else {
        $return = join('', grep { !/^\s*#/ } <$file>);
        chomp $return;
    }

    close($file) or
        die "$0: $file_name: ERROR, while closing file after reading -- "
          . lcfirst($!) . ".\n";

    return wantarray ? @{$return} : $return;
}

1;
