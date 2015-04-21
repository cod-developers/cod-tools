#!/usr/local/bin/perl -w
# ===========================================================================
#
#                            PUBLIC DOMAIN NOTICE
#               National Center for Biotechnology Information
#
#  This software/database is a "United States Government Work" under the
#  terms of the United States Copyright Act.  It was written as part of
#  the author's official duties as a United States Government employee and
#  thus cannot be copyrighted.  This software/database is freely available
#  to the public for use. The National Library of Medicine and the U.S.
#  Government have not placed any restriction on its use or reproduction.
#
#  Although all reasonable efforts have been taken to ensure the accuracy
#  and reliability of the software and data, the NLM and the U.S.
#  Government do not and cannot warrant the performance or results that
#  may be obtained by using this software or data. The NLM and the U.S.
#  Government disclaim all warranties, express or implied, including
#  warranties of performance, merchantability or fitness for any particular
#  purpose.
#
#  Please cite the author in any work or product based on this material.
#
# ===========================================================================
#
# Author:  Oleg Khovayko
#
# File Description: ePost/eSummary calling example
#  

# ---------------------------------------------------------------------------
my $eutils_root  = "http://www.ncbi.nlm.nih.gov/entrez/eutils";
my $ePost_url    = "$eutils_root/epost.fcgi";
my $eSummary_url = "$eutils_root/esummary.fcgi";

my $db_name = "PubMed";

# ---------------------------------------------------------------------------
use strict;

use LWP::UserAgent;
use LWP::Simple;
use HTTP::Request;
use HTTP::Headers;
use CGI;

# ---------------------------------------------------------------------------
# Read input file into variable $file
# File name - forst argument $ARGV[0]

undef $/;  #for load whole file

open IF, $ARGV[0] || die "Can't open for read: $!\n";
my $file = <IF>;
close IF;
print "Loaded file: [$file]\n";

# Prepare file - substitute all separators to comma

$file =~ s/\s+/,/gs;
print "Prepared file: [$file]\n";

#Create CGI param line

my $form_data = "db=$db_name&id=$file";

# ---------------------------------------------------------------------------
# Create HTTP request

my $headers = new HTTP::Headers(
	Accept		=> "text/html, text/plain",
	Content_Type	=> "application/x-www-form-urlencoded"
);

my $request = new HTTP::Request("POST", $ePost_url, $headers );

$request->content($form_data);

# Create the user agent object

my $ua = new LWP::UserAgent;
$ua->agent("ePost/example");

# ---------------------------------------------------------------------------
# send file to ePost by HTTP

my $response = $ua->request($request);

# ---------------------------------------------------------------------------

print "Responce status message: [" . $response->message . "]\n";
print "Responce content: [" .        $response->content . "]\n";

# ---------------------------------------------------------------------------
# Parse response->content and extract QueryKey & WebEnv
$response->content =~ 
  m|<QueryKey>(\d+)</QueryKey>.*<WebEnv>(\S+)</WebEnv>|s;

my $QueryKey = $1;
my $WebEnv   = $2;

print "\nEXTRACTED:\nQueryKey = $QueryKey;\nWebEnv = $WebEnv\n\n";

# ---------------------------------------------------------------------------
# Retrieve DocSum from eSummary by simple::get method and print it
#
print "eSummary result: [" . 
  get("$eSummary_url?db=$db_name&query_key=$QueryKey&WebEnv=$WebEnv") . 
  "]\n";



