#! /bin/sh
#!perl -w # --*- Perl -*--
eval 'exec perl -x $0 ${1+"$@"}'
    if 0;

#------------------------------------------------------------------------------
#$Author: $
#$Date: $
#$Revision: $
#$URL: $
#------------------------------------------------------------------------------
#*
#  Parse CIF file(s) and CIF dictionary(ies).
#  Check CIF file against CIF dictionaries.
#**

#
# here we link libraries
#
use strict;
use warnings;
use lib "./lib/perl5";
use lib "./CIFParser";
use CIFParser;
use ShowStruct;
use SOptions;
use Getopt::Long;

#
# here we define variables
#	first - constant values
#	then  - common variables
#
my $version = 0.1;

my $CIFfile = {};
my $CIFtags;
my $outputFile;
my $dictFiles = [];
my $dictFilesParsed = [];
my $dictTags = {};
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

# subroutine to extract tags from data block array
sub getTagsSData;

# subroutine to be used then printing information (debug output could be 
# made using print STDOUT|STDERR "")
sub output;

# subroutine to convert reference (r. to array, hash, scalar) to scalar
sub refToScalar;

# subroutine to extract tags from dictionary (parsed using CIFParser)
# it takes reference to CIFParser output
# returns hash of tags and related references to parsed data blocks
sub getDict;

# subroutine to check if tags in data block provided are defined within 
# dictionary. It takes arguments:
#	- reference to data block array
#	- data block index (of array @{$CIFfile})
#	- data file index (of array @ARGV)
sub checkTags;

# subroutine is used to check if types of elements matches ones defined 
# within dictionary
# It takes arguments:
#   1. reference to data block element
#   2. reference to dictionary(-ies)
#   3. accordingly (to 2) array of dictionary names
sub checkTypes;

#
# main program code
#

# check parameters passed
@ARGV = getOptions(
        "--output"
            => \$outputFile,
        "--dictionary" ## @todo load multiple dictionaries
            => $dictFiles,
        "--version"
            => sub{ VersionMessage() },
        "--quiet"
            => sub{ $quiet = 1; },
        "--no-quiet"
            => sub{ $quiet = 0; },
        "--help"
            => sub{ HelpMessage() }
    );

if( @$dictFiles )
{
    for( @{$dictFiles} ) {
        my $parsed = $parser->Run( $_ );
        push( @$dictFilesParsed, $parsed );
        $$dictTags{$_} = getDict( $parsed );
        undef $parsed;
    }
} else {
    die "You must specify dictionary using '--dictionary'. Automatic "
            . "dictionary download is not implemeted yet.\n";
    my $dictIUCRURI = "ftp://ftp.iucr.org/pub/cif_core.dic";
}

## don't dare to touch - dictionaries are being parsed for now
## if($quiet == 0)
## {
## 	print "Got dictionary tags:\n";
## 	while( my( $fname, $tags ) = each %$dictTags ) {
## 	    print "For dictionary [" . $fname . "]:\n";
## 	    while( my($tag, $data) = each %$tags ) {
## 	        print "\t"
## 	                . $tag
## 	                . ' :: '
## 	                . ${$$data}{values}{_type}[0]
## 	                . "\n";
## 	    }
## 	}
## 	print "\n";
## }

# parse CIF files. If none is passed - display help message
if( !@ARGV ) {
	HelpMessage();
	exit( 1 );
}

for( @ARGV ) {
    $$CIFfile{$_} = $parser->Run( $_ );
}

while( my($cifF, $data) = each %$CIFfile ) {
    for( @$data ) {
    showRef( $_ );
        if( $quiet == 0 ) {
            print "Analysing file ["
                    . $cifF . "], data block ["
                    . $_->{name} . "]:\n";
        }
        my $block = $_;
        for( @{$block->{tags}} ) {
            # if check tags
            my $defined = false;
            for( my($dictF, $dictD) = each $dictTags ) {
                if( exists $$dictD{$_} ) {
                    $defined = true;
                } else {
                    if( $quiet == 0 ) {
                        print $cifF . ', ' . $block{name}
                                . ', tag: [' . $_ . ']'
                                . ' does not exist' . "\n";
                    }
                }
            }
            # end-if check tags
#            print "Tag: " . $_ . "\n";
#            my $values = $$block{values}{$_};
#            showRef( $values );
        }
    }
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
	my $tags;
	if($size > 1)
	{
		my $datan = 0;
		while($datan < $size)
		{
			push( @{$tags}, getTagsSData( $file->[$datan] ) );
			$datan++;
		}
	} else {
		$tags = [getTagsSData($file->[0])];
	}
	return $tags;
}

sub getTagsSData
{
	my $data = shift;
	my @tags;
	my $dataname = $data->{name};
	my $noitems = scalar @{$data->{content}};
	my $content = $data->{content};
	for(my $i = 0; $i < $noitems; $i++)
	{
		my $item = $content->[$i];
		if( $item->{kind} eq 'TAG' || $item->{kind} eq 'LOCAL' )
		{
			push(@tags, $item->{name});
		} elsif($item->{kind} eq 'loop') {
			foreach my $tag (@{$item->{name}})
			{
				push( @tags, $tag );
			}
		} elsif($item->{kind} eq 'SAVE') {
			my $savetags = getTagsSData( $item );
			foreach my $tag ( @{$savetags->{content}} )
			{
				push(@tags, $tag);
			}
		} else {
			die("ERROR: file contains elements, not handled by ".
			"this module!\n");
		}
	}
	return { kind => 'DATATAGS',
				name => $dataname,
				content => \@tags };
}

sub output
{
	my $data = shift;
	if( !defined($outputFile) || (length($outputFile) == 0) )
	{
		print $data;
	} else {
		my $fh = new FileHandle "> $outputFile";
		if( defined $fh )
		{
			$data = refToScalar($data, 0);
			print $fh $data;
			$fh->close;
		} else {
			die("Please check your output file ["
				. $outputFile . "]. There was an error"
				. " openning it!\n");
		}
	}
}

sub refToScalar
{
	my $reference = shift;
	my $indent;
	my $value = '';
	my $type = ref($reference);
	if( !ref($reference) )
	{
		return $reference;
	}
	if( $type eq "ARRAY" )
	{
		foreach my $entry ( @{$reference} )
		{
			if( !ref($entry) )
			{
				$value .= $entry . " | ";
			} else {
				$value .= refToScalar($entry)
					. "\n";
			}
		}
	} elsif ( $type eq "HASH" )
	{
		foreach my $key ( keys %{$reference} )
		{
			if( !ref($reference->{$key}) )
			{
				$value .= $reference->{$key} . " \\ ";
			} else {
				$value .= refToScalar($reference->{$key})
					. "\n";
			}
		}
	} elsif ( $type eq "SCALAR" ) {
		$value .= $$reference;
	} else {
		return $value;
	}
	return $value;
}

sub getDict
{
	my $dictF = shift;
	my $tags = {};
	my $datan = 0;
   	while( $datan < @$dictF )
    {
        $datan++ and next if
            !exists $$dictF[$datan]{values}{_type};
        for ( @{$$dictF[$datan]{values}{_name}} ) {
            $$tags{lc $_} = \$$dictF[$datan];
        }
        $datan++;
	}
	return $tags;
}

sub checkTags
{
	my $data = shift;
	my $i = shift;
	my $filen = shift;
	my %lcCIFtags;
	%lcCIFtags = map { lc($_) => $_ } @{$data};
	if( $quiet == 0 )
	{
		print "Got following tags for file "
			. $ARGV[$filen] . ", data block "
			. @{$CIFtags}[$i]->{name} . ":\n";
		foreach my $key ( keys %lcCIFtags )
		{
		    print $key . "\t-->\t"
		    		. $lcCIFtags{$key}
		    		. "\n";
	    }
	    print "\n";
	}
	foreach my $key ( keys %lcCIFtags )
	{
		if( !defined $key ) # TODO: check keys
		{
			print <<END_M;
Got tag '$key' which is not in dictionary provided. This tag was found 
in file '$ARGV[$filen]', data block '@{$CIFtags}[$i]->{name}'.
Please check this tag - it might be wrong.

END_M
		}
	}
}

# TODO: implement
sub checkTypes {
    return undef;
}
