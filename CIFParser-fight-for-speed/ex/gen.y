%{
%}
%token NUMBER LITERAL NAME
%%
ruleset:	rule			{ $main::start = $1; }
	|	ruleset rule
	;

rule:		NAME '=' blist ';'	{ $$ = $1;
					  $main::rules{$1} = $3; }
	;

blist:		branch			{ $$ = bless [$1], Rule; }
	|	blist '|' branch	{ $$ = $1; push (@{$$}, $3); }
	;

branch:		item			{ $$ = bless [$1], Branch; }
	|	branch item		{ $$ = $1; push (@{$$}, $2); }
	;

item:		LITERAL			{ $$ = new Literal($1); }
	|	NAME			{ $$ = new Name($1); }
	;
%%
sub yylex
{
    my ($s) = @_;
    my ($c, $val);

 AGAIN:
    while (($c = $s->getc) eq ' ' || $c eq "\t" || $c eq "\n") { }

    if ($c eq '') { return 0; }

    # read a comment
    elsif ($c eq '#') {
      while (($c = $s->getc) ne '' && $c ne "\n") { }
      $s->ungetc;
      goto AGAIN;
    }

    # read a string literal
    elsif ($c eq "\"") {
      while (($c = $s->getc) ne '' && $c ne "\"") {
	if ($c eq "\\") {
	  $c = $s->getc;
	  if    ($c eq "\\") { $c = "\\"; }
	  elsif ($c eq "n")  { $c = "\n"; }
	  elsif ($c eq "t")  { $c = "\t"; }
	  elsif ($c eq "\"") { $c = "\""; }
	}
	$val .= $c;
      }
      return ($LITERAL, $val);
    }

    # read a rule name
    elsif ($c =~ /[a-zA-Z_-]/) {
	$val = $c;
	while (($c = $s->getc) =~ /[a-zA-Z0-9_-]/) {
	    $val .= $c;
	}
	$s->ungetc;
	return ($NAME, $val);
    }

    else {
	return ord($c);
    }
}

sub yyerror {
    my ($msg, $s) = @_;
    die "$msg at " . $s->name . " line " . $s->lineno . ".\n";
}
