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

my $CIFfile;
my $CIFtags;
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

# subroutine to extract tags from CIFfile array
sub getTags;

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
	if(@ARGV > 1)
	{
		my $filen = 0;
		while($filen < @ARGV)
		{
			push(@{$CIFfile}, { kind => 'FILE',
								content => $parser->Run($ARGV[$filen]),
								name => $ARGV[$filen] });
			$filen++;
		}
	} else {
		$CIFfile = $parser->Run($ARGV[0]);
	}
} else {
	HelpMessage();
}

if($quiet == 0)
{
	print "Got structure for file(s) parsed:\n";
	showRef($CIFfile);
	print "\n";
}

# take tags from parsed CIF file
if(@ARGV > 1)
{
	my $filen = 0;
	while($filen < @ARGV)
	{
		push(@{$CIFtags}, getTags($CIFfile->[$filen]));
		$filen++;
	}
} else {
	$CIFtags = getTags($CIFfile);
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

sub getTags
{
	my $file = shift;
	my $size = scalar @$file;
	my @tags;
	if($size > 1)
	{
		my $datan = 0;
		while($datan < $size)
		{
			$datan++;
		}
	} else {
		my $dataname = $file->[0]->{name};
		my $noitems = scalar @{$file->[0]->{content}};
		my $content = $file->[0]->{content};
		for(my $i = 0; $i < $noitems; $i++)
		{
			my $item = $content->[$i];
			if($item->{kind} eq 'TAG')
			{
				push(@tags, $item->{name});
			} elsif($item->{kind} eq 'loop') {
				foreach my $tag (@{$item->{name}})
				{
					push( @tags, $tag );
				}
			} elsif($item->{kind} eq 'SAVE') {
				my $savetags = getTags( [$item] );
				foreach my $tag ( @$savetags )
				{
					push(@tags, $tag);
				}
			} else {
				die("ERROR: file contains elements, not handled by ".
				"this module!\n");
			}
		}
	}
	if( $quiet == 0 )
	{
		print "Got following tags from file:\n";
		showRef(\@tags);
		print "\n";
	}
	return \@tags;
}
