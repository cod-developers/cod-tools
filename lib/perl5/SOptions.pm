#------------------------------------------------------------------------
#$Author: saulius $
#$Date: 2006-05-03 13:16:28 +0300 (Wed, 03 May 2006) $ 
#$Revision: 988 $
#$URL: svn+ssh://lokys.ibt.lt/home/saulius/svn-repositories/cce/aux/SOptions.pm $
#------------------------------------------------------------------------
#* 
#  Simple option processing package
#**

package SOptions;

use strict;
require Exporter;
@SOptions::ISA = qw(Exporter);
@SOptions::EXPORT = qw( getOptions get_value get_int get_ints
			get_float get_floats );

my @args;

sub getOptions
{
    my %options = @_;
    my @files = ();
    @args = map { /^-[-\w]+=/o ? split( "=", $_, 2) : $_ } @ARGV;

    %options = map { my @synonims = split( ",", $_ );
		     my $value = $options{$_};
		     map {($_,$value)} @synonims } keys %options;

    while( @args ) {

	if( $args[0] =~ /^@/ ) { 
	    splice( @args, 0, 1, &interpolateFile( $args[0] ) );
	}
	if( $args[0] !~ /^-/ ) { push( @files, shift( @args )); next; }
        if( $args[0] eq "-"  ) { push( @files, shift( @args )); next; }
	if( $args[0] eq "--" ) { shift @args; return ( @files, @args ); }

	my @matches = ();
	if( exists $options{$args[0]} ) {
	    @matches = ( $args[0] );
	} elsif( $args[0] !~ /^-[^-]/ ) {
	    foreach ( keys( %options )) {
		if( /^\Q$args[0]\E/ ) {
		    push( @matches, $_ );
		}
	    }
	}

	if( @matches > 1 ) {
	    local ($", $\) = (", ", "\n");
	    print STDERR "$0: Option prefix '$args[0]' is not uniq:";
	    print STDERR "possible options are @matches";
	    die;
	} elsif( @matches == 1 ) {
	    my $var = $options{$matches[0]};
	    for( ref( $var )) {
		if( /ARRAY/ )  { push( @$var, &get_value); last }
		if( /HASH/ )   { $$var{$matches[0]} = &get_value; last }
		if( /SCALAR/ ) { $$var = &get_value; last }
		if( /CODE/ )   { &$var; last }
	    }
	    shift @args;
        } else {
	    die( "$0: unknown option $args[0]\n" );
	}
    } # while 
    return @files;
}

sub get_value
{
    my $option = shift @args;
    if( @args == 0 ) {
	local $\ = "\n";
        print( STDERR "missing argument to option $option for $0");
	die;
    }
    return $args[0] =~ /^@/ ?
	scalar( &interpolateFile( substr( $args[0], 0 ))) :
	$args[0];
}

#-----------------------------------------------------------------------------

my $integer = '[-+]? \d+';
my $float = '[-+]? (\d+(\.\d*)? | (\.\d+)) ([eE][-+]?\d+)?';

sub get_int
{
    my $option = $args[0];
    my $value = &get_value;
    die( "Option $option requires one integer argument\n" )
	if $value !~ /^ \s* $integer \s* $/x;
    return $value;
}

sub get_float
{
    my $option = $args[0];
    my $value = &get_value;
    die( "Option $option requires one floating-point argument\n" )
	if $value !~ /^ \s* $float \s* $/x;
    return $value;
}

sub get_ints
{
    my $option = $args[0];
    my $value = &get_value;
    die( "Option $option requires one or several integer arguments\n" )
	if $value !~ /^ \s* ($integer\s*)+ \s* $/x;
    return $value;
}

sub get_floats
{
    my $option = $args[0];
    my $value = &get_value;
    die( "Option $option requires one or several floating-point argument\n" )
	if $value !~ /^ \s* ($float\s*)+ \s* $/x;
    return $value;
}

#-----------------------------------------------------------------------------

sub interpolateFile
{
    my ($file_name, $option) = @_;
    my $noat_file_name = substr( $file_name, 1 );

    if( -f $noat_file_name && -f $file_name ) {
	warn( "$0: WARNING: ".
	      "both '$noat_file_name' and '$file_name' exist:\n" );
	warn( "$0: taking options from '$file_name'" );
    } elsif( !-f $file_name ) {
	$file_name = $noat_file_name;
    }
    open( VALUE, $file_name ) or do {
	print STDERR "Could not open file '$file_name': $!\n";
        print STDERR "(the file was an argument for option $option of $0)\n" 
	    if $option;
        die;
    };
    if( wantarray ) { 
	my @return = map {
	    chomp($_);
	    s/\s*$//;
	    if( /^\s*-/ ) {
		my @file_line =
		    # split option/value pairs with '=':
		    # '--option=value' becomes '--option value':
		    /^\s*-{1,2}[^\s=]+\s*=/ ?
			split(/=/,$_, 2) : split(' ',$_, 2);

		# remove trailing spaces from the option name, if any:
		$file_line[0] =~ s/\s+$//g if $file_line[0];

		# remove quotes around the option values, to emulate
		# shell behaviour:
		# '--option "value"' becomes '--option value'
		# Note, however, that the 'value' will never be passed
		# to shell, so the spaces in the 'value' will be processed
		# correctly:
		# '--option "1 2 3"' will be interpreted as --option with
		# an argument '1 2 3'
		$file_line[1] =~ s/^\s*['"]?|["']?\s*$//g 
		    if $file_line[1];
		@file_line
	    } else { $_ } 
	}
	grep !/^\s*#|^\s*$/, <VALUE>;
	close(VALUE) or die("Error reading $file_name: $!");
	@return;
    } else {
        my $return = join("", grep !/^\s*#/, <VALUE>);
	close(VALUE) or die("Error reading $file_name: $!");
	chomp $return;
	$return;
    }
}
