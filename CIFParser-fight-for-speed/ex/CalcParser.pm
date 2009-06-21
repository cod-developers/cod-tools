# @(#)yaccpar 1.8 (Berkeley) 01/20/91 (JAKE-P5BP-0.6 04/26/98)
package CalcParser;
#line 2 "calc.y"
#line 4 "CalcParser.pm"
$NUMBER=257;
$EOL=258;
$YYERRCODE=256;
@yylhs = (                                               -1,
    0,    0,    1,    1,    2,    2,    2,    2,    2,    2,
);
@yylen = (                                                2,
    0,    2,    2,    1,    1,    3,    3,    3,    3,    3,
);
@yydefred = (                                             1,
    0,    5,    4,    0,    2,    0,    0,    3,    0,    0,
    0,    0,   10,    0,    0,    8,    9,
);
@yydgoto = (                                              1,
    5,    6,
);
@yysindex = (                                             0,
  -40,    0,    0,  -32,    0,  -31,  -19,    0,  -32,  -32,
  -32,  -32,    0,  -17,  -17,    0,    0,
);
@yyrindex = (                                             0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,  -39,  -38,    0,    0,
);
@yygindex = (                                             0,
    0,    9,
);
$YYTABLESIZE=227;
@yytable = (                                              4,
    0,    6,    7,    6,    7,    6,    7,    4,    0,    0,
   11,    9,    7,   10,    0,   12,    0,   14,   15,   16,
   17,   13,   11,    9,   11,   10,    0,   12,    0,   12,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    2,    3,    6,    7,
    0,    0,    0,    0,    2,    0,    8,
);
@yycheck = (                                             40,
   -1,   41,   41,   43,   43,   45,   45,   40,   -1,   -1,
   42,   43,    4,   45,   -1,   47,   -1,    9,   10,   11,
   12,   41,   42,   43,   42,   45,   -1,   47,   -1,   47,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,  257,  258,  258,  258,
   -1,   -1,   -1,   -1,  257,   -1,  258,
);
$YYFINAL=1;
#ifndef YYDEBUG
#define YYDEBUG 0
#endif
$YYMAXTOKEN=258;
#if YYDEBUG
@yyname = (
"end-of-file",'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','',"'('","')'","'*'","'+'",'',"'-'",'',"'/'",'','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',"NUMBER",
"EOL",
);
@yyrule = (
"\$accept : start",
"start :",
"start : start input",
"input : expr EOL",
"input : EOL",
"expr : NUMBER",
"expr : expr '+' expr",
"expr : expr '-' expr",
"expr : expr '*' expr",
"expr : expr '/' expr",
"expr : '(' expr ')'",
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
if ($p->{yyn} == 3) {
#line 13 "calc.y"
{ print $p->{yyvs}->[$p->{yyvsp}-1] . "\n"; }
}
if ($p->{yyn} == 5) {
#line 17 "calc.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-0]; }
}
if ($p->{yyn} == 6) {
#line 18 "calc.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-2] + $p->{yyvs}->[$p->{yyvsp}-0]; }
}
if ($p->{yyn} == 7) {
#line 19 "calc.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-2] - $p->{yyvs}->[$p->{yyvsp}-0]; }
}
if ($p->{yyn} == 8) {
#line 20 "calc.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-2] * $p->{yyvs}->[$p->{yyvsp}-0]; }
}
if ($p->{yyn} == 9) {
#line 21 "calc.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-2] / $p->{yyvs}->[$p->{yyvsp}-0]; }
}
if ($p->{yyn} == 10) {
#line 22 "calc.y"
{ $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-1]; }
}
#line 287 "CalcParser.pm"
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
#line 25 "calc.y"
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
#line 369 "CalcParser.pm"
1;
