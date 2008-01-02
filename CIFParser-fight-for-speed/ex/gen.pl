#!/usr/bin/perl

# This is a Perl rewrite of a C program I wrote a while back that
# generates random strings from a language specified in BNF. Try
# 'gen.pl < thought' to see how it works.

# $Id: gen.pl,v 1.1 2002/04/10 04:58:09 srz Exp $

# Structs for the grammar.

# These two aren't really used as classes per se but it's convenient
# to bless things into them so you can see what's going on in the
# debugger.
package Rule;
package Branch;

package Literal;
sub new {
  my ($class, $value) = @_;
  bless { value => $value }, $class;
}

package Name;
sub new {
  my ($class, $name) = @_;
  bless  { name => $name }, $class;
}

# Here is the actual generation code.

package main;

use GenParser;
use Fstream;

srand(time|$$);

$s = Fstream->new(\*STDIN, 'STDIN');
$p = GenParser->new(\&GenParser::yylex, \&GenParser::yyerror, 0);
$p->yyparse($s);

&fixup_names;
&gen($rules{$start});

# connect rule invocations to the actual rule.
sub fixup_names {
  my ($rule, $branch, $item);

  foreach $rule (values %rules) {
    foreach $branch (@$rule) {
      foreach $item (@$branch) {
	if ($item->isa("Name")) {
	  my $r = $rules{$item->{name}} or
	    die "Undefined rule " . $item->{name};
	  $item->{blist} = $r;
	}
      }
    }
  }
}

# generate language. We keep a manual stack instead of doing a
# recursive call (just for the hell of it).
sub gen {
  my ($blist) = @_;
  my @stack;

 LOOP:

  my $ilist = [ @{$$blist[int(rand(@$blist))]} ];
  push(@stack, $ilist);

  while (@stack) {
    my $ilist = $stack[-1];
    while (@$ilist) {
      my $item = shift @$ilist;
      if ($item->isa("Literal")) {
	print $item->{value};
      }
      elsif ($item->isa("Name")) {
	$blist = $item->{blist};
	goto LOOP;
      }
    }
    pop @stack;
  }
}
