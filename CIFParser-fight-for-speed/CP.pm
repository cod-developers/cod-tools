# @(#)yaccpar 1.8 (Berkeley) 01/20/91 (JAKE-P5BP-0.6 04/26/98)
package CP;
#line 16 "CP.yp"
use warnings;
use ShowStruct;
use FileHandle;

$CP::version = '1.0';

my $SVNID = '$Id$';

$CP::debug = 0;

sub merge_data_lists($$)
{
    my $list = $_[0];
    my $item = $_[1];

    for my $tag (@{$item->{tags}}) {

	push( @{$list->{tags}}, $tag );

	$list->{values}{$tag} =
	    $item->{values}{$tag};

	$list->{types}{$tag} =
	    $item->{types}{$tag};

	if( exists $item->{precisions}{$tag} ) {
	    $list->{precisions}{$tag} =
		$item->{precisions}{$tag};
	}

    }

    if( exists $item->{loops} ) {
	if( defined $list->{loops} ) {
	    $list->{loops} = [ @{$list->{loops}}, $item->{loops}[0] ];
	} else {
	    $list->{loops} = [ $item->{loops}[0] ];
	}
    }

    if( exists $item->{inloop} ) {
	my $loop_nr = $#{$list->{loops}};
	for my $key (keys %{$item->{inloop}} ) {
	    $list->{inloop}{$key} = $loop_nr;
	}
    }

    if( exists $item->{save_blocks} ) {
	if( defined $list->{save_blocks} ) {
	    $list->{save_blocks} =
		[ @{$list->{save_blocks}}, $item->{save_blocks}[0] ];
	} else {
	    $list->{save_blocks} = [ $item->{save_blocks}[0] ];
	}
    }

    return $list;
}

$CP::parser = {};

#line 65 "CP.pm"
$DATA_=257;
$TAG=258;
$LOCAL=259;
$LOOP_=260;
$SAVE_HEAD=261;
$SAVE_FOOT=262;
$textfield=263;
$SQSTRING=264;
$DQSTRING=265;
$UQSTRING=266;
$TEXT_FIELD=267;
$FLOAT=268;
$INT=269;
$YYERRCODE=256;
@yylhs = (                                               -1,
    0,    0,    0,    4,    5,    0,    1,    1,    6,    6,
    8,    8,    7,    2,    2,   11,   11,    9,    9,   12,
   12,   13,   14,   14,   15,   15,   10,    3,    3,    3,
   16,   16,   16,   16,   17,   17,
);
@yylen = (                                                2,
    0,    1,    1,    0,    0,    3,    2,    1,    2,    1,
    2,    1,    1,    1,    1,    2,    1,    1,    1,    2,
    3,    3,    2,    1,    2,    1,    3,    1,    1,    1,
    1,    1,    1,    1,    1,    1,
);
@yydefred = (                                             0,
   13,    0,    0,    0,    0,   30,   31,   32,   33,   34,
   35,   36,    0,    0,    3,    4,    8,    0,   14,   15,
   18,   19,   28,   29,   20,    0,   24,    0,   17,    0,
    7,    5,   12,    0,   21,   23,   26,    0,   27,   16,
    6,   11,   25,
);
@yydgoto = (                                             13,
   14,   15,   16,   32,   41,   17,   18,   34,   19,   20,
   30,   21,   22,   28,   38,   23,   24,
);
@yysindex = (                                          -226,
    0, -219, -253, -252, -237,    0,    0,    0,    0,    0,
    0,    0,    0, -232,    0,    0,    0, -207,    0,    0,
    0,    0,    0,    0,    0, -219,    0, -254,    0, -242,
    0,    0,    0, -207,    0,    0,    0, -219,    0,    0,
    0,    0,    0,
);
@yyrindex = (                                            28,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,   29,    0,    0,    0,    7,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    8,    0,    0,    0,    1,    0,    0,
    0,    0,    0,
);
@yygindex = (                                             0,
    0,  -15,   -2,    0,    0,   16,    0,    0,   -3,    0,
    0,    0,    0,    0,    0,    0,    0,
);
$YYTABLESIZE=265;
@yytable = (                                             25,
   22,   29,   33,   36,   26,   27,   10,    9,    6,    7,
    8,    9,   10,   11,   12,    2,    3,    4,   42,   39,
    2,    3,    4,   35,    1,   37,   40,    1,    2,   31,
    1,    2,    3,    4,    5,   43,    6,    7,    8,    9,
   10,   11,   12,    6,    7,    8,    9,   10,   11,   12,
    2,    3,    4,    5,    0,    0,    0,    0,    0,    0,
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
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,   22,   22,   22,
   22,   22,   22,   10,    9,
);
@yycheck = (                                              2,
    0,    5,   18,  258,  258,  258,    0,    0,  263,  264,
  265,  266,  267,  268,  269,  258,  259,  260,   34,  262,
  258,  259,  260,   26,  257,   28,   30,    0,    0,   14,
  257,  258,  259,  260,  261,   38,  263,  264,  265,  266,
  267,  268,  269,  263,  264,  265,  266,  267,  268,  269,
  258,  259,  260,  261,   -1,   -1,   -1,   -1,   -1,   -1,
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
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,  257,  258,  259,
  260,  261,  262,  257,  257,
);
$YYFINAL=13;
#ifndef YYDEBUG
#define YYDEBUG 0
#endif
$YYMAXTOKEN=269;
#if YYDEBUG
@yyname = (
"end-of-file",'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','',"DATA_","TAG","LOCAL","LOOP_",
"SAVE_HEAD","SAVE_FOOT","textfield","SQSTRING","DQSTRING","UQSTRING",
"TEXT_FIELD","FLOAT","INT",
);
@yyrule = (
"\$accept : start",
"start :",
"start : data_block_list",
"start : data_item",
"\$$1 :",
"\$$2 :",
"start : cif_value $$1 $$2",
"data_block_list : data_block_list data_block",
"data_block_list : data_block",
"data_block : data_block_head data_item_list",
"data_block : data_block_head",
"data_item_list : data_item_list data_item",
"data_item_list : data_item",
"data_block_head : DATA_",
"data_item : save_item",
"data_item : save_block",
"save_item_list : save_item_list save_item",
"save_item_list : save_item",
"save_item : cif_entry",
"save_item : loop",
"cif_entry : TAG cif_value",
"cif_entry : LOCAL TAG cif_value",
"loop : LOOP_ loop_tags loop_values",
"loop_tags : loop_tags TAG",
"loop_tags : TAG",
"loop_values : loop_values cif_value",
"loop_values : cif_value",
"save_block : SAVE_HEAD save_item_list SAVE_FOOT",
"cif_value : string",
"cif_value : number",
"cif_value : textfield",
"string : SQSTRING",
"string : DQSTRING",
"string : UQSTRING",
"string : TEXT_FIELD",
"number : FLOAT",
"number : INT",
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
#line 102 "CP.yp"
{
			$CP::parser->{USER}->{CIFfile} =
                            [ { name => undef, values => {}, tags => [] } ];
		}
}
if ($p->{yyn} == 2) {
#line 107 "CP.yp"
{
			if($CIFParser::debug >= 3)
			{
				showRef($p->{yyvs}->[$p->{yyvsp}-0]);
			}
			$CP::parser->{USER}->{CIFfile} = $p->{yyvs}->[$p->{yyvsp}-0];
		}
}
if ($p->{yyn} == 3) {
#line 115 "CP.yp"
{
			$CP::parser->{ERRMSG} = "No data block heading (i.e." .
			" data_somecif) found in file!\n";
			$CP::parser->{USER}->{CIFfile} = [ { name => "", values => {}, tags => [] } ];
			$CP::parser->YYError();
		}
}
if ($p->{yyn} == 4) {
#line 121 "CP.yp"
{
			$CP::parser->{USER}->{CIFfile} =
                            [ { name => undef, values => {}, tags => [] } ];
		}
}
if ($p->{yyn} == 5) {
#line 125 "CP.yp"
{
			$CP::parser->{USER}->{CIFfile} =
                            [ { name => undef, values => {}, tags => [] } ];
		}
}
if ($p->{yyn} == 6) {
#line 130 "CP.yp"
{
			$CP::parser->{ERRMSG} = "No data block heading (i.e." .
			" data_somecif) found in file!\n";
			$CP::parser->{USER}->{CIFfile} = [ { name => "", values => {}, tags => [] } ];
			$CP::parser->YYError();
		}
}
if ($p->{yyn} == 7) {
#line 140 "CP.yp"
{
			my $val = $p->{yyvs}->[$p->{yyvsp}-1];
			push( @{$val}, $p->{yyvs}->[$p->{yyvsp}-0] );
			$p->{yyval} = $val;
		}
}
if ($p->{yyn} == 8) {
#line 146 "CP.yp"
{
			$p->{yyval} = [ $p->{yyvs}->[$p->{yyvsp}-0] ];
		}
}
if ($p->{yyn} == 9) {
#line 153 "CP.yp"
{
			## my $val = { name => $1 };
			## $val->{content} = $2->{value};
			## $val->{kind} = $2->{kind};
			## $val->{type} = "DATA";
			my $name = $p->{yyvs}->[$p->{yyvsp}-1];
		        my $val = $p->{yyvs}->[$p->{yyvsp}-0];
			$val->{name} = $name;
			$p->{yyval} = $val;
		}
}
if ($p->{yyn} == 10) {
#line 164 "CP.yp"
{
			$p->{yyval} =
                            { name => $p->{yyvs}->[$p->{yyvsp}-0], values => {}, tags => [] };
		}
}
if ($p->{yyn} == 11) {
#line 172 "CP.yp"
{
		        ## my $val = $1;
			## push(@{$val->{value}}, $2);
			## $$ = $val;
                        my $list = $p->{yyvs}->[$p->{yyvsp}-1];
                        my $item = $p->{yyvs}->[$p->{yyvsp}-0];
                        $list = merge_data_lists( $list, $item );
			$p->{yyval} = $list;
		}
}
if ($p->{yyn} == 12) {
#line 182 "CP.yp"
{
			## my $val = { kind => 'DATA' };
			## push(@{$val->{value}}, $1);
		        my $val = $p->{yyvs}->[$p->{yyvsp}-0];
			$p->{yyval} = $val;
		}
}
if ($p->{yyn} == 13) {
#line 192 "CP.yp"
{
			##$1 =~ m/^(data_)(.*)/si;
			$p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-0];
		}
}
if ($p->{yyn} == 14) {
#line 200 "CP.yp"
{
			$p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-0];
		}
}
if ($p->{yyn} == 15) {
#line 204 "CP.yp"
{
			$p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-0];
		}
}
if ($p->{yyn} == 16) {
#line 212 "CP.yp"
{
			## my $val = $1;
			## push( @{$val->{value}}, $2 );
			## $$ = $val;
		        my $list = $p->{yyvs}->[$p->{yyvsp}-1];
			my $item = $p->{yyvs}->[$p->{yyvsp}-0];
                        $list = merge_data_lists( $list, $item );
			$p->{yyval} = $list;
		}
}
if ($p->{yyn} == 17) {
#line 222 "CP.yp"
{
			my $val = $p->{yyvs}->[$p->{yyvsp}-0];
			$p->{yyval} = $val;
		}
}
if ($p->{yyn} == 18) {
#line 230 "CP.yp"
{
		    # Here we convert to new structure:
			## $$ = $1;
		        my $entry = $p->{yyvs}->[$p->{yyvsp}-0];
			my $item = {
			    values => {
				$entry->{name} => [ $entry->{value} ]
			    },
			    types => {
				$entry->{name} => [ $entry->{type} ]
			    },
			    tags => [ $entry->{name} ]
			};
			if( exists $entry->{precision} ) {
			    $item->{precisions} = {
				$entry->{name} => [ $entry->{precision} ]
			    }
			}
			$p->{yyval} = $item;
		}
}
if ($p->{yyn} == 19) {
#line 251 "CP.yp"
{
		        $p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-0];
		}
}
if ($p->{yyn} == 20) {
#line 258 "CP.yp"
{
			my $val;
			if(defined $p->{yyvs}->[$p->{yyvsp}-0]->{precision})
			{
				$val = { name => $p->{yyvs}->[$p->{yyvsp}-1],
					kind => 'TAG',
					value => $p->{yyvs}->[$p->{yyvsp}-0]->{value},
					type => $p->{yyvs}->[$p->{yyvsp}-0]->{type},
					precision => $p->{yyvs}->[$p->{yyvsp}-0]->{precision}
				};
			} else {
				$val = { name => $p->{yyvs}->[$p->{yyvsp}-1],
					kind => 'TAG',
					value => $p->{yyvs}->[$p->{yyvsp}-0]->{value},
					type => $p->{yyvs}->[$p->{yyvsp}-0]->{type}
				};
			}
			if($CIFParser::debug >= 1 && $CIFParser::debug <= 2)
			{
				showRef($val);
			}
			$p->{yyval} = $val;
		}
}
if ($p->{yyn} == 21) {
#line 282 "CP.yp"
{
			my $val;
			if(defined $p->{yyvs}->[$p->{yyvsp}-0]->{precision})
			{
				$val = { name => $p->{yyvs}->[$p->{yyvsp}-1],
					kind => 'LOCAL',
					value => $p->{yyvs}->[$p->{yyvsp}-0]->{value},
					type => $p->{yyvs}->[$p->{yyvsp}-0]->{type},
					precision => $p->{yyvs}->[$p->{yyvsp}-0]->{precision}
				};
			} else {
				$val = { name => $p->{yyvs}->[$p->{yyvsp}-1],
					kind => 'LOCAL',
					value => $p->{yyvs}->[$p->{yyvsp}-0]->{value},
					type => $p->{yyvs}->[$p->{yyvsp}-0]->{type}
				};
			}
			if($CIFParser::debug >= 1 && $CIFParser::debug <= 2)
			{
				showRef($val);
			}
			$p->{yyval} = $val;
		}
}
if ($p->{yyn} == 22) {
#line 309 "CP.yp"
{
		        my $val = {};
		        my $tags = $p->{yyvs}->[$p->{yyvsp}-1];
			my @values = @{$p->{yyvs}->[$p->{yyvsp}-0]};

                        $val->{loops} = [ [ @{$tags} ] ];
                        $val->{tags} = $tags;

		      VALUES:
			while( int( @values ) > 0 ) {
			    for my $tag (@{$tags}) {
				my $value = shift( @values );
				if( defined $value ) {
				    push( @{$val->{values}{$tag}},
					  $value->{value} );
				    push( @{$val->{types}{$tag}},
					  $value->{type} );
				    if( exists $value->{precision} ) {
					push( @{$val->{precisionss}{$tag}},
					      $value->{precision} );
				    }
				    $val->{inloop}{$tag} = 0;
				} else {
				    $CP::parser->{ERRMSG} =
					"Wrong number of elements in the"
					. " loop block starting in line "
					. $CP::parser->{VARS}{loop_begin}
				    . "!\n";
				    $CP::parser->YYError();
				    last VALUES;
				}
			    }
			}
                        $p->{yyval} = $val;
		}
}
if ($p->{yyn} == 23) {
#line 348 "CP.yp"
{
			my $val = $p->{yyvs}->[$p->{yyvsp}-1];
			push( @{$val}, $p->{yyvs}->[$p->{yyvsp}-0] );
			$p->{yyval} = $val;
		}
}
if ($p->{yyn} == 24) {
#line 354 "CP.yp"
{
			my $val = [ $p->{yyvs}->[$p->{yyvsp}-0] ];
			$p->{yyval} = $val;
		}
}
if ($p->{yyn} == 25) {
#line 362 "CP.yp"
{
			my $arr = $p->{yyvs}->[$p->{yyvsp}-1];
			my $val = $p->{yyvs}->[$p->{yyvsp}-0];
			## push( @{$val->{value}}, $2->{value} );
			## push( @{$val->{type}}, $2->{type} );
			## if( defined $2->{precision} )
			## {
			## 	push( @{$val->{precision}}, $2->{precision} );
			## }
			$p->{yyval} = [ @{$arr}, $val ];
		}
}
if ($p->{yyn} == 26) {
#line 374 "CP.yp"
{
			my $val = $p->{yyvs}->[$p->{yyvsp}-0];
			## { type => [ $1->{type} ] };
			## push( @{$val->{value}}, $1->{value} );
			## if( defined $1->{precision} )
			## {
			## 	push( @{$val->{precision}}, $1->{precision} );
			## }
			$p->{yyval} = [ $val ];
		}
}
if ($p->{yyn} == 27) {
#line 388 "CP.yp"
{
			## my $value = $2->{value};
			## $1 =~ m/^(save_)(.*)$/si;
			## my $val = { kind => 'SAVE',
			## 		name => $2 };
			## $val->{type} = "SAVE";
			## $val->{content} = $value;
			## $$ = $val;
                        my $val = {
			    save_blocks => [
				{
				    name => $p->{yyvs}->[$p->{yyvsp}-2],
				    %{$p->{yyvs}->[$p->{yyvsp}-1]}
				}
			    ]
                        };
                        $p->{yyval} = $val;
		}
}
if ($p->{yyn} == 28) {
#line 410 "CP.yp"
{	print $p->{yyvs}->[$p->{yyvsp}-0]->{type} . "\t->\t"
				. $p->{yyvs}->[$p->{yyvsp}-0]->{value} . "\n" 
                        if( $CIFParser::debug >= 1 && $CIFParser::debug <= 2) ;
			$p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-0];
		}
}
if ($p->{yyn} == 29) {
#line 416 "CP.yp"
{	print $p->{yyvs}->[$p->{yyvsp}-0]->{type} . "\t\t->\t"
				. $p->{yyvs}->[$p->{yyvsp}-0]->{value} . " -- "
				. $p->{yyvs}->[$p->{yyvsp}-0]->{precision}
				. "\n" if( $CIFParser::debug >= 1 && $CIFParser::debug <= 2);
			$p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-0];
		}
}
if ($p->{yyn} == 30) {
#line 423 "CP.yp"
{	print "TFIELD\t\t->\t" .
				$p->{yyvs}->[$p->{yyvsp}-0]->{value} . "\n"
				if( $CIFParser::debug >= 1 && $CIFParser::debug <= 2);
			$p->{yyval} = $p->{yyvs}->[$p->{yyvsp}-0];
		}
}
if ($p->{yyn} == 31) {
#line 432 "CP.yp"
{
			##$1 =~ m/^(')(.*)(')$/si;
			$p->{yyval} = { value => $p->{yyvs}->[$p->{yyvsp}-0],
				type => 'SQSTRING'};
		}
}
if ($p->{yyn} == 32) {
#line 438 "CP.yp"
{
			##$1 =~ m/^(")(.*)(")$/si;
			$p->{yyval} = { value => $p->{yyvs}->[$p->{yyvsp}-0],
				type => 'DQSTRING'};
		}
}
if ($p->{yyn} == 33) {
#line 443 "CP.yp"
{ $p->{yyval} = { value => $p->{yyvs}->[$p->{yyvsp}-0],
			type => 'UQSTRING'} }
}
if ($p->{yyn} == 34) {
#line 445 "CP.yp"
{ $p->{yyval} = { value => $p->{yyvs}->[$p->{yyvsp}-0],
			type => 'TEXTFIELD' };
		}
}
if ($p->{yyn} == 35) {
#line 452 "CP.yp"
{
		    $p->{yyval} = {	
                        type => 'FLOAT',
                        value => $p->{yyvs}->[$p->{yyvsp}-0],
                        precision => 'undef'
		    }
		}
}
if ($p->{yyn} == 36) {
#line 460 "CP.yp"
{
		    $p->{yyval} = {	type => 'INT',
                        value => $p->{yyvs}->[$p->{yyvsp}-0],
                        precision => 'undef'
		    }
		}
}
#line 778 "CP.pm"
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
#line 469 "CP.yp"
# --------------------------------------------------------------
# begin of footer
# --------------------------------------------------------------

sub _Error
{
        $_[0]->{ERRCOUNT}++;
	exists $_[0]->{ERRMSG}
	and do {
		print STDERR $_[0]->{ERRMSG};
		delete $_[0]->{ERRMSG};
		return;
	};
	print STDERR "Analyzed symbols line containing bogus data (num. " . 
		$_[0]->{VARS}{lines} . " pos. " . 
		$_[0]->{VARS}{token_prev_pos} . ") was:\n" . 
		$_[0]->{VARS}{current_line} . "\n";
	print STDERR " " x $_[0]->{VARS}{token_prev_pos};
	print STDERR "^\n";
}

sub yylex
{
    my ($stream) = @_;
	my $parser = {INPUT=>undef, ISTREAM=>$stream};
	my $input = $parser->{INPUT};

	#trimming tokenized comments
	if( defined $input &&
		$input =~
			s/^(\s*#.*)$//s )
	{
		advance_token($parser);
	}

	if( !defined $input ||
		$input =~ m/^\s*$/ )
	{
		do
		{
			$input = <$stream>;
			$parser->{VARS}{lines}++;
		} until ( !defined $input ||
			$input !~ m/^(\s*(#.*)?)$/s );
		if( defined $input )
		{
			chomp $input;
			$input=~s/\r$//g;
			$input=~s/\t/    /g;
			$parser->{VARS}{current_line} = 
				$input;
			$parser->{VARS}{token_pos} = 0;
		} else {
			$parser->{INPUT} = $input; return('',undef);
		}
	}

#scalars storing regular expressions, common to several matches
my $ORDINARY_CHAR	=	
	qr/[a-zA-Z0-9!%&\(\)\*\+,-\.\/\:<=>\?@\\\^`{\|}~]/is;
my $SPECIAL_CHAR	=	qr/["#\$'_\[\]]/is;
my $NON_BLANK_CHAR	=	qr/(?:$ORDINARY_CHAR|$SPECIAL_CHAR|;)/is;
my $TEXT_LEAD_CHAR	=	qr/(?:$ORDINARY_CHAR|$SPECIAL_CHAR|\s)/s;
my $ANY_PRINT_CHAR	=	qr/(?:$NON_BLANK_CHAR|\s)/is;
my $INTEGER		=	qr/[-+]?[0-9]+/s;
my $EXPONENT		=	qr/e[-+]?[0-9]+/is;
my $FLOAT11		=	qr/(?: $INTEGER $EXPONENT)/ix;
my $FLOAT21		=	qr/(?: [+-]? [0-9]* \. [0-9]+ $EXPONENT ?)/ix;
my $FLOAT31		=	qr/(?: $INTEGER \. $EXPONENT ?)/ix;
my $FLOAT		=	qr/(?: (?: $FLOAT11 | $FLOAT21 | $FLOAT31))/six;

	#matching white space characters
	if( $input =~ s/(\s*)//s )
	{
		advance_token($parser);
	}
		
	if($CIFParser::debug >= 2 && $CIFParser::debug < 3)
	{
		print ">>> '", $input, "'\n";
	}

	for ($input)
	{
		#matching floats:
                if( s/^(?: ($FLOAT (?:\([0-9]+\))?) (\s) )/$2/six
                        || s/^($FLOAT (?:\([0-9]+\))?)$//six )
		{
			advance_token($parser);
			$parser->{INPUT} = $input; return($FLOAT, $1);
		}
		#matching integers:
                if( s/^($INTEGER (?:\([0-9]+\))?)(\s)/$2/sx
                        || s/^($INTEGER (?:\([0-9]+\))?)$//sx )
		{
			advance_token($parser);
			$parser->{INPUT} = $input; return($INT, $1);
		}
		#matching double quoted strings
		if( s/^("${ANY_PRINT_CHAR}*?")(\s)/$2/s
			|| s/^("${ANY_PRINT_CHAR}*?")$//s )
		{
			advance_token($parser);
			$parser->{INPUT} = $input; return($DQSTRING, $1);
		}
		#matching single quoted strings
		if( s/^('${ANY_PRINT_CHAR}*?')(\s)/$2/s
			|| s/^('${ANY_PRINT_CHAR}*?')$//s )
		{
			advance_token($parser);
			$parser->{INPUT} = $input; return($SQSTRING, $1);
		}
		#matching text field
		if( $parser->{VARS}{token_pos} == 0 )
		{
			if( s/^;(${ANY_PRINT_CHAR}*)$//s )
			{
				my $eotf = 0;
				my $tfield;	#all textfield
				my $tf_line_begin =
					$parser->{VARS}{lines};
				$tfield = $1;
				while( 1 )
				{
					my $line = <$CIFParser::FILEIN>;
					if( defined $line )
					{
						chomp $line;
						$line=~s/\r$//g;
						$line=~s/\t/    /g;
						$parser->{VARS}{current_line} = 
							$line;
						$parser->{VARS}{lines}++;
						if( $line =~
							s/^;//s )
						{
							if( defined $line )
							{
							$input
								= $line;
							$parser->{VARS}{token_pos} = 1;
							}
							last;
						} else {
							$tfield .= "\n" . $line;
						}
					} else {
						undef $input;
						last;
					}
				}
				if( !defined $input )
				{
					$parser->{ERRMSG} = <<END_M;
ERROR encountered while in text field, which started in line $tf_line_begin.
Possible runaway of closing ';', or unexpected end of file.
END_M
					$parser->YYError();
				}
				$parser->{INPUT} = $input; return($TEXT_FIELD, $tfield);
			}
		}
		#matching [local] attribute
		if( s/^(\[local\])//si )
		{
			advance_token($parser);
			$parser->{INPUT} = $input; return($LOCAL, $1);
		}
		#matching GLOBAL_ field
		if( s/^(global_.*)$//si )
		{
			advance_token($parser);
			$parser->{ERRMSG} = "GLOBAL_ symbol detected" .
				" in line " .
				$parser->{VARS}{lines} .
				", pos. " .
				$parser->{VARS}{token_prev_pos} . ":\n--\n" .
				$parser->{VARS}{current_line} . "\n--\n" .
				"It is not acceptable in this version!\n";
			$parser->YYError();
			$parser->{INPUT} = $input; return($GLOBAL_, $1);
		}
		#matching SAVE_ head
		if( s/^(save_${NON_BLANK_CHAR}+)//si )
		{
			advance_token($parser);
			$parser->{INPUT} = $input; return($SAVE_HEAD, $1);
		}
		#matching SAVE_ foot
		if( s/^(save_)//si )
		{
			advance_token($parser);
			$parser->{INPUT} = $input; return($SAVE_FOOT, $1);
		}
		#matching STOP_ field
		if( s/^(stop_.*)$//si )
		{
			advance_token($parser);
			$parser->{ERRMSG} = "STOP_ symbol detected" .
				" in line " .
				$parser->{VARS}{lines} .
				", pos. " .
				$parser->{VARS}{token_prev_pos} . ":\n--\n" .
				$parser->{VARS}{current_line} . "\n--\n" .
				"It is not acceptable in this version!\n";
			$parser->YYError();
			$parser->{INPUT} = $input; return($STOP_, $1);
		}
		#matching DATA_ field
		if( s/^(data_${NON_BLANK_CHAR}+)//si )
		{
			advance_token($parser);
			$parser->{INPUT} = $input; return($DATA_, $1);
		}
		#matching LOOP_ begining
		if( s/^(loop_)//si )
		{
			advance_token($parser);
			$parser->{VARS}{loop_begin} =
					$parser->{VARS}{lines};
			$parser->{INPUT} = $input; return($LOOP_, $1);
		}
		#matching TAG's
		if( s/^(_${NON_BLANK_CHAR}+)//si )
		{
			advance_token($parser);
			$parser->{INPUT} = $input; return($TAG, $1);
		}
		#matching unquoted strings
		if( $parser->{VARS}{token_pos} == 0 )
		{ #UQSTRING at first pos. of line
			if( s/^(?: ( ($ORDINARY_CHAR | \[ )
				($NON_BLANK_CHAR)*) )
				//sx)
			{
				advance_token($parser);
				$parser->{INPUT} = $input; return($UQSTRING, $1);
			}
		} else { #UQSTRING in line
			if( s/^(?: ( ($ORDINARY_CHAR | ; | \[ )
				($NON_BLANK_CHAR)*) )
				//sx )
			{
				advance_token($parser);
				$parser->{INPUT} = $input; return($UQSTRING, $1);
			}
		}
		#matching any still unmatched symbol:
		if( s/^(.)//m )
		{
			advance_token($parser);
			$parser->{INPUT} = $input; return($1,$1);
		}
	}
}

sub advance_token
{
	my $parser = shift;
	$parser->{VARS}{token_prev_pos} =
		$parser->{VARS}{token_pos};
	$parser->{VARS}{token_pos} += length($1);
}

sub yyerror
{
    print STDERR "$.: $@\n";
}

return 1;
#line 1094 "CP.pm"
1;
