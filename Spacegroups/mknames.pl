#!/usr/bin/perl -w

use strict;
use Spacegroups;

while( my( $k, $v ) = each %space_groups ) {
    my $p="$v->{number}, \"" . ucfirst($k) . "\"";
    if( !defined $v->{settings} && !defined $v->{short} ) {
	print "[ ", $p, ", \"", ucfirst($k), "\"", " ],\n"
    }
    if( defined $v->{settings} ) {
	for ( @{$v->{settings}} ) {
	    print "[ ", $p, ", \"", ucfirst($_), "\"", " ],\n"
	}
    }
    if( defined $v->{short} ) {
	for ( @{$v->{short}} ) {
	    print "[ ", $p, ", \"", ucfirst($_), "\"", " ],\n"
	}
    }
}
