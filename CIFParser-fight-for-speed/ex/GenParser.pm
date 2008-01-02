# @(#)yaccpar 1.8 (Berkeley) 01/20/91 (JAKE-P5BP-0.6 04/26/98)
package GenParser;
#line 2 "gen.y"
#line 4 "GenParser.pm"
$NUMBER=257;
$LITERAL=258;
$NAME=259;
$YYERRCODE=256;
@yylhs = (                                               -1,
    0,    0,    1,    2,    2,    3,    3,    4,    4,
);
@yylen = (                                                2,
    1,    2,    4,    1,    3,    1,    2,    1,    1,
);
@yydefred = (                                             0,
    0,    0,    1,    0,    2,    8,    9,    0,    0,    6,
    3,    0,    7,    0,
);
@yydgoto = (                                              2,
    3,    8,    9,   10,
);
@yysindex = (                                          -253,
  -54, -253,    0, -254,    0,    0,    0,  -59, -254,    0,
    0, -254,    0, -254,
);
@yyrindex = (                                             0,
    0,    0,    0,    0,    0,    0,    0,    0,  -58,    0,
    0,    0,    0,  -57,
);
@yygindex = (                                             0,
    7,    0,   -2,   -6,
);
$YYTABLESIZE=67;
@yytable = (                                             11,
    4,    5,   13,    6,    7,    1,    4,   13,    5,   14,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,   12,    4,    5,
);
@yycheck = (                                             59,
   59,   59,    9,  258,  259,  259,   61,   14,    2,   12,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,  124,  124,  124,
);
$YYFINAL=2;
#ifndef YYDEBUG
#define YYDEBUG 0
#endif
$YYMAXTOKEN=259;
#if YYDEBUG
@yyname = (
"end-of-file",'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','',"';'",'',"'='",'','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','',"'|'",'','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','',"NUMBER","LITERAL",
"NAME",
);
@yyrule = (
"\$accept : ruleset",
"ruleset : rule",
"ruleset : ruleset rule",
"rule : NAME '=' blist ';'",
"blist : branch",
"blist : blist '|' branch",
"branch : item",
"branch : branch item",
"item : LITERAL",
"item : NAME",
);
#endif
sub yyclearin {
  my  $p;
  ($p) = @_;
  $p->{yychar} = -1;
}
sub yyerrok {
  my  $p;
  ($p) = @_;
  $p->{yyerrflag} = 0;
}
sub new {
  my $p = bless {}, $_[0];
  $p->{yylex} = $_[1];
  $p->{yyerror} = $_[2];
  $p->{yydebug} = $_[3];
  return $p;
}
sub YYERROR {
  my  $p;
  ($p) = @_;
  ++$p->{yynerrs};
  $p->yy_err_recover;
}
sub yy_err_recover {
  my  $p;
  ($p) = @_;
  if ($p->{yyerrflag} < 3)
  {
    $p->{yyerrflag} = 3;
    while (1)
    {
      if (($p->{yyn} = $yysindex[$p->{yyss}->[$p->{yyssp}]]) && 
          ($p->{yyn} += $YYERRCODE) >= 0 && 
          $p->{yyn} <= $#yycheck &&
          $yycheck[$p->{yyn}] == $YYERRCODE)
      {
        warn("yydebug: state " . 
                     $p->{yyss}->[$p->{yyssp}] . 
                     ", error recovery shifting to state" . 
                     $yytable[$p->{yyn}] . "\n") 
                       if $p->{yydebug};
        $p->{yyss}->[++$p->{yyssp}] = 
          $p->{yystate} = $yytable[$p->{yyn}];
        $p->{yyvs}->[++$p->{yyvsp}] = $p->{yylval};
        next yyloop;
      }
      else
      {
        warn("yydebug: error recovery discarding state ".
              $p->{yyss}->[$p->{yyssp}]. "\n") 
                if $p->{yydebug};
        return(undef) if $p->{yyssp} <= 0;
        --$p->{yyssp};
        --$p->{yyvsp};
      }
    }
  }
  else
  {
    return (undef) if $p->{yychar} == 0;
    if ($p->{yydebug})
    {
      $p->{yys} = '';
      if ($p->{yychar} <= $YYMAXTOKEN) { $p->{yys} = 
        $yyname[$p->{yychar}]; }
      if (!$p->{yys}) { $p->{yys} = 'illegal-symbol'; }
      warn("yydebug: state " . $p->{yystate} . 
                   ", error recovery discards " . 
                   "token " . $p->{yychar} . "(" . 
                   $p->{yys} . ")\n");
    }
    $p->{yychar} = -1;
    next yyloop;
  }
0;
} # yy_err_recover

sub yyparse {
  my  $p;
  my $s;
  ($p, $s) = @_;
  if ($p->{yys} = $ENV{'YYDEBUG'})
  {
    $p->{yydebug} = int($1) if $p->{yys} =~ /^(\d)/;
  }

  $p->{yynerrs} = 0;
  $p->{yyerrflag} = 0;
  $p->{yychar} = (-1);

  $p->{yyssp} = 0;
  $p->{yyvsp} = 0;
  $p->{yyss}->[$p->{yyssp}] = $p->{yystate} = 0;

yyloop: while(1)
  {
    yyreduce: {
      last yyreduce if ($p->{yyn} = $yydefred[$p->{yystate}]);
      if ($p->{yychar} < 0)
      {
        if ((($p->{yychar}, $p->{yylval}) = 
            &{$p->{yylex}}($s)) < 0) { $p->{yychar} = 0; }
        if ($p->{yydebug})
        {
          $p->{yys} = '';
          if ($p->{yychar} <= $#yyname) 
             { $p->{yys} = $yyname[$p->{yychar}]; }
          if (!$p->{yys}) { $p->{yys} = 'illegal-symbol'; };
          warn("yydebug: state " . $p->{yystate} . 
                       ", reading " . $p->{yychar} . " (" . 
                       $p->{yys} . ")\n");
        }
      }
      if (($p->{yyn} = $yysindex[$p->{yystate}]) && 
          ($p->{yyn} += $p->{yychar}) >= 0 && 
          $p->{yyn} <= $#yycheck &&
          $yycheck[$p->{yyn}] == $p->{yychar})
      {
        warn("yydebug: state " . $p->{yystate} . 
                     ", shifting to state " .
              $yytable[$p->{yyn}] . "\n") if $p->{yydebug};
        $p->{yyss}->[++$p->{yyssp}] = $p->{yystate} = 
          $yytable[$p->{yyn}];
        $p->{yyvs}->[++$p->{yyvsp}] = $p->{yylval};
        $p->{yychar} = (-1);
        --$p->{yyerrflag} if $p->{yyerrflag} > 0;
        next yyloop;
      }
      if (($p->{yyn} = $yyrindex[$p->{yystate}]) && 
          ($p->{yyn} += $p->{'yychar'}) >= 0 &&
          $p->{yyn} <= $#yycheck &&
          $yycheck[$p->{yyn}] == $p->{yychar})
      {
        $p->{yyn} = $yytable[$p->{yyn}];
        last yyreduce;
      }
      if (! $p->{yyerrflag}) {
        &{$p->{yyerror}}('syntax error', $s);
        ++$p->{yynerrs};
      }
      return(undef) if $p->yy_err_recover;
    } # yyreduce
    warn("yydebug: state " . $p->{yystate} . 
                 ", reducing by rule " . 
                 $p->{yyn} . " (" . $yyrule[$p->{yyn}] . 
                 ")\n") if $p->{yydebug};
    $p->{yym} = $yylen[$p->{yyn}];
    $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}+1-$p->{yym}];
if ($p->{yyn} == 1) {
#line 5 "gen.y"
{ $main::start = $p->{yyvs}->[$p->{yyvsp}-0]; }
}
if ($p->{yyn} == 3) {
#line 9 "gen.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-3];
					  $main::rules{$p->{yyvs}->[$p->{yyvsp}-3]} = $p->{yyvs}->[$p->{yyvsp}-1]; }
}
if ($p->{yyn} == 4) {
#line 13 "gen.y"
{ $p->{yyval} = bless [$p->{yyvs}->[$p->{yyvsp}-0]], Rule; }
}
if ($p->{yyn} == 5) {
#line 14 "gen.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-2]; push (@{$p->{yyval}}, $p->{yyvs}->[$p->{yyvsp}-0]); }
}
if ($p->{yyn} == 6) {
#line 17 "gen.y"
{ $p->{yyval} = bless [$p->{yyvs}->[$p->{yyvsp}-0]], Branch; }
}
if ($p->{yyn} == 7) {
#line 18 "gen.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-1]; push (@{$p->{yyval}}, $p->{yyvs}->[$p->{yyvsp}-0]); }
}
if ($p->{yyn} == 8) {
#line 21 "gen.y"
{ $p->{yyval} = new Literal($p->{yyvs}->[$p->{yyvsp}-0]); }
}
if ($p->{yyn} == 9) {
#line 22 "gen.y"
{ $p->{yyval} = new Name($p->{yyvs}->[$p->{yyvsp}-0]); }
}
#line 260 "GenParser.pm"
    $p->{yyssp} -= $p->{yym};
    $p->{yystate} = $p->{yyss}->[$p->{yyssp}];
    $p->{yyvsp} -= $p->{yym};
    $p->{yym} = $yylhs[$p->{yyn}];
    if ($p->{yystate} == 0 && $p->{yym} == 0)
    {
      warn("yydebug: after reduction, shifting from state 0 ",
            "to state $YYFINAL\n") if $p->{yydebug};
      $p->{yystate} = $YYFINAL;
      $p->{yyss}->[++$p->{yyssp}] = $YYFINAL;
      $p->{yyvs}->[++$p->{yyvsp}] = $p->{yyval};
      if ($p->{yychar} < 0)
      {
        if ((($p->{yychar}, $p->{yylval}) = 
            &{$p->{yylex}}($s)) < 0) { $p->{yychar} = 0; }
        if ($p->{yydebug})
        {
          $p->{yys} = '';
          if ($p->{yychar} <= $#yyname) 
            { $p->{yys} = $yyname[$p->{yychar}]; }
          if (!$p->{yys}) { $p->{yys} = 'illegal-symbol'; }
          warn("yydebug: state $YYFINAL, reading " . 
               $p->{yychar} . " (" . $p->{yys} . ")\n");
        }
      }
      return ($p->{yyvs}->[1]) if $p->{yychar} == 0;
      next yyloop;
    }
    if (($p->{yyn} = $yygindex[$p->{yym}]) && 
        ($p->{yyn} += $p->{yystate}) >= 0 && 
        $p->{yyn} <= $#yycheck && 
        $yycheck[$p->{yyn}] == $p->{yystate})
    {
        $p->{yystate} = $yytable[$p->{yyn}];
    } else {
        $p->{yystate} = $yydgoto[$p->{yym}];
    }
    warn("yydebug: after reduction, shifting from state " . 
        $p->{yyss}->[$p->{yyssp}] . " to state " . 
        $p->{yystate} . "\n") if $p->{yydebug};
    $p->{yyss}[++$p->{yyssp}] = $p->{yystate};
    $p->{yyvs}[++$p->{yyvsp}] = $p->{yyval};
  } # yyloop
} # yyparse
#line 25 "gen.y"
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
#line 357 "GenParser.pm"
1;
