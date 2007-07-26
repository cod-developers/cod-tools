#! /usr/bin/perl -w

#
# here we link libraries
#
use strict;
use warnings;
#use SOptions;
use Getopt::Long;
use ShowStruct;
use CIFParser;

#
# here we define variables
#	first - constant values
#	then  - common variables
#
my $version = 0.1;

my $outputFile;
my $dictFile;
my $quiet = 0;
my $parser = new CIFParser;

#
# here we declare subroutines
#

# subroutine to print module version and copyright notice
sub VersionMessage;

# subroutine to print help on module usage
sub HelpMessage;


#
# main program code
#

# check parameters passed
Getopt::Long::GetOptions
	("output=s"			=> \$outputFile,
		"dictionary=s"	=> \$dictFile,
		"version"		=> sub { VersionMessage() },
		"quiet"			=> sub { $quiet = 1; },
		"no-quiet"		=> sub { $quiet = 0; },
		"help|?"		=> sub { HelpMessage() }
	);

# parse CIF files. If none is passed - display help message
if(@ARGV > 0)
{
	my @CIFfile = ();
	if(@ARGV > 1)
	{
		while(my $i < @ARGV)
		{
			push(@CIFfile, $parser->Run($ARGV[$i]));
			$i++;
		}
	} else {
		my @CIFfile = $parser->CIFParser::Run($ARGV[0]);
	}
} else {
	HelpMessage();
}

#
# here goes all subroutines bodies
#

sub VersionMessage
{
	print <<END_M;
cif_check_dict (using CIFParser v.$CIFParser::version) v.$version
Copyright (C) 2007 ???
This is free software. You may redistribute copies of it under the terms of
the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
There is NO WARRANTY, to the extent permitted by law.

Written by Justas Butkus.
END_M
}

sub HelpMessage
{
	print <<END_M;
I hope you know, what you are doing.
If not - feel recommended to wait until release of production version.
END_M
}
