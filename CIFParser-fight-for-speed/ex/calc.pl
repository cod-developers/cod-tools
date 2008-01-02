#!/usr/bin/perl

# $Id: calc.pl,v 1.1 2002/04/10 04:58:09 srz Exp $

# Really trivial calculator.

use CalcParser;
use Fstream;

$s = Fstream->new(\*STDIN, 'STDIN');
$p = CalcParser->new(\&CalcParser::yylex, \&CalcParser::yyerror, 0);

$p->yyparse($s);
