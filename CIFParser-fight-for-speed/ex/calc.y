%{
%}

%token NUMBER EOL
%left '+' '-'
%left '*' '/'

%%
start:	|
		start input
	;

input:		expr EOL	{ print $1 . "\n"; }
	|	EOL
	;

expr:		NUMBER		{ $$ = $1; }
	|	expr '+' expr	{ $$ = $1 + $3; }
	|	expr '-' expr	{ $$ = $1 - $3; }
	|	expr '*' expr	{ $$ = $1 * $3; }
	|	expr '/' expr	{ $$ = $1 / $3; }
	|	'(' expr ')'	{ $$ = $2; }
	;
%%
# $Id$

sub yylex
{
    my ($s) = @_;
    my ($c, $val);

    while (($c = $s->getc) eq ' ' || $c eq "\t") {
    }

    if ($c eq '') {
	return 0;
    }

    elsif ($c eq "\n") {
	return $EOL;
    }

    elsif ($c =~ /[0-9]/) {
	$val = $c;
	while (($c = $s->getc) =~ /[0-9]/) {
	    $val .= $c;
	}
	$s->ungetc;
	return ($NUMBER, $val);
    }

    else {
	return ord($c);
    }
}

sub yyerror {
    my ($msg, $s) = @_;
    die "$msg at " . $s->name . " line " . $s->lineno . ".\n";
}
