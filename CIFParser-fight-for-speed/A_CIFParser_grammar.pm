####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package A_CIFParser_grammar;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 15 "A_CIFParser_grammar.yp"

use warnings;
use ShowStruct;
use FileHandle;

$CIFParser::version = '1.0';

my $SVNID = '$Id: CIFParser.yp 325 2008-01-02 15:13:24Z saulius $';

# 0 - no debug
# 1 - only YAPP output (type -> value)
# 2 - lex & yapp output
# 3 - generated array dump
$CIFParser::debug = 0;

sub merge_data_lists($$)
{
    return;

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



sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'TEXT_FIELD' => 18,
			'TAG' => 3,
			'INT' => 19,
			'DQSTRING' => 5,
			'SAVE_HEAD' => 9,
			'SQSTRING' => 8,
			'DATA_' => 12,
			'textfield' => 13,
			'LOOP_' => 14,
			'UQSTRING' => 15,
			'FLOAT' => 16,
			'LOCAL' => 17
		},
		DEFAULT => -1,
		GOTOS => {
			'save_block' => 1,
			'data_item' => 4,
			'number' => 2,
			'cif_value' => 7,
			'string' => 6,
			'cif_file' => 20,
			'data_block_list' => 11,
			'loop' => 10,
			'data_block' => 21,
			'cif_entry' => 22,
			'data_block_head' => 23,
			'save_item' => 24
		}
	},
	{#State 1
		DEFAULT => -13
	},
	{#State 2
		DEFAULT => -27
	},
	{#State 3
		ACTIONS => {
			'TEXT_FIELD' => 18,
			'textfield' => 13,
			'UQSTRING' => 15,
			'INT' => 19,
			'DQSTRING' => 5,
			'FLOAT' => 16,
			'SQSTRING' => 8
		},
		GOTOS => {
			'number' => 2,
			'cif_value' => 25,
			'string' => 6
		}
	},
	{#State 4
		DEFAULT => -3
	},
	{#State 5
		DEFAULT => -30
	},
	{#State 6
		DEFAULT => -26
	},
	{#State 7
		DEFAULT => -4
	},
	{#State 8
		DEFAULT => -29
	},
	{#State 9
		ACTIONS => {
			'LOOP_' => 14,
			'TAG' => 3,
			'LOCAL' => 17
		},
		GOTOS => {
			'cif_entry' => 22,
			'save_item_list' => 26,
			'save_item' => 27,
			'loop' => 10
		}
	},
	{#State 10
		DEFAULT => -17
	},
	{#State 11
		ACTIONS => {
			'DATA_' => 12
		},
		DEFAULT => -2,
		GOTOS => {
			'data_block' => 28,
			'data_block_head' => 23
		}
	},
	{#State 12
		DEFAULT => -11
	},
	{#State 13
		DEFAULT => -28
	},
	{#State 14
		ACTIONS => {
			'TAG' => 30
		},
		GOTOS => {
			'loop_tags' => 29
		}
	},
	{#State 15
		DEFAULT => -31
	},
	{#State 16
		DEFAULT => -33
	},
	{#State 17
		ACTIONS => {
			'TAG' => 31
		}
	},
	{#State 18
		DEFAULT => -32
	},
	{#State 19
		DEFAULT => -34
	},
	{#State 20
		ACTIONS => {
			'' => 32
		}
	},
	{#State 21
		DEFAULT => -6
	},
	{#State 22
		DEFAULT => -16
	},
	{#State 23
		ACTIONS => {
			'LOOP_' => 14,
			'TAG' => 3,
			'SAVE_HEAD' => 9,
			'LOCAL' => 17
		},
		DEFAULT => -8,
		GOTOS => {
			'save_block' => 1,
			'cif_entry' => 22,
			'data_item' => 33,
			'data_item_list' => 34,
			'save_item' => 24,
			'loop' => 10
		}
	},
	{#State 24
		DEFAULT => -12
	},
	{#State 25
		DEFAULT => -18
	},
	{#State 26
		ACTIONS => {
			'LOOP_' => 14,
			'TAG' => 3,
			'SAVE_FOOT' => 35,
			'LOCAL' => 17
		},
		GOTOS => {
			'cif_entry' => 22,
			'save_item' => 36,
			'loop' => 10
		}
	},
	{#State 27
		DEFAULT => -15
	},
	{#State 28
		DEFAULT => -5
	},
	{#State 29
		ACTIONS => {
			'TEXT_FIELD' => 18,
			'textfield' => 13,
			'UQSTRING' => 15,
			'TAG' => 37,
			'INT' => 19,
			'DQSTRING' => 5,
			'FLOAT' => 16,
			'SQSTRING' => 8
		},
		GOTOS => {
			'number' => 2,
			'loop_values' => 38,
			'cif_value' => 39,
			'string' => 6
		}
	},
	{#State 30
		DEFAULT => -22
	},
	{#State 31
		ACTIONS => {
			'TEXT_FIELD' => 18,
			'textfield' => 13,
			'UQSTRING' => 15,
			'INT' => 19,
			'DQSTRING' => 5,
			'FLOAT' => 16,
			'SQSTRING' => 8
		},
		GOTOS => {
			'number' => 2,
			'cif_value' => 40,
			'string' => 6
		}
	},
	{#State 32
		DEFAULT => 0
	},
	{#State 33
		DEFAULT => -10
	},
	{#State 34
		ACTIONS => {
			'LOOP_' => 14,
			'TAG' => 3,
			'SAVE_HEAD' => 9,
			'LOCAL' => 17
		},
		DEFAULT => -7,
		GOTOS => {
			'save_block' => 1,
			'cif_entry' => 22,
			'data_item' => 41,
			'save_item' => 24,
			'loop' => 10
		}
	},
	{#State 35
		DEFAULT => -25
	},
	{#State 36
		DEFAULT => -14
	},
	{#State 37
		DEFAULT => -21
	},
	{#State 38
		ACTIONS => {
			'TEXT_FIELD' => 18,
			'INT' => 19,
			'DQSTRING' => 5,
			'SQSTRING' => 8,
			'textfield' => 13,
			'UQSTRING' => 15,
			'FLOAT' => 16
		},
		DEFAULT => -20,
		GOTOS => {
			'number' => 2,
			'cif_value' => 42,
			'string' => 6
		}
	},
	{#State 39
		DEFAULT => -24
	},
	{#State 40
		DEFAULT => -19
	},
	{#State 41
		DEFAULT => -9
	},
	{#State 42
		DEFAULT => -23
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'cif_file', 0, undef
	],
	[#Rule 2
		 'cif_file', 1, undef
	],
	[#Rule 3
		 'cif_file', 1, undef
	],
	[#Rule 4
		 'cif_file', 1, undef
	],
	[#Rule 5
		 'data_block_list', 2, undef
	],
	[#Rule 6
		 'data_block_list', 1, undef
	],
	[#Rule 7
		 'data_block', 2, undef
	],
	[#Rule 8
		 'data_block', 1, undef
	],
	[#Rule 9
		 'data_item_list', 2, undef
	],
	[#Rule 10
		 'data_item_list', 1, undef
	],
	[#Rule 11
		 'data_block_head', 1, undef
	],
	[#Rule 12
		 'data_item', 1, undef
	],
	[#Rule 13
		 'data_item', 1, undef
	],
	[#Rule 14
		 'save_item_list', 2, undef
	],
	[#Rule 15
		 'save_item_list', 1, undef
	],
	[#Rule 16
		 'save_item', 1, undef
	],
	[#Rule 17
		 'save_item', 1, undef
	],
	[#Rule 18
		 'cif_entry', 2, undef
	],
	[#Rule 19
		 'cif_entry', 3, undef
	],
	[#Rule 20
		 'loop', 3, undef
	],
	[#Rule 21
		 'loop_tags', 2, undef
	],
	[#Rule 22
		 'loop_tags', 1, undef
	],
	[#Rule 23
		 'loop_values', 2, undef
	],
	[#Rule 24
		 'loop_values', 1, undef
	],
	[#Rule 25
		 'save_block', 3, undef
	],
	[#Rule 26
		 'cif_value', 1, undef
	],
	[#Rule 27
		 'cif_value', 1, undef
	],
	[#Rule 28
		 'cif_value', 1, undef
	],
	[#Rule 29
		 'string', 1, undef
	],
	[#Rule 30
		 'string', 1, undef
	],
	[#Rule 31
		 'string', 1, undef
	],
	[#Rule 32
		 'string', 1, undef
	],
	[#Rule 33
		 'number', 1, undef
	],
	[#Rule 34
		 'number', 1, undef
	]
],
                                  @_);
    bless($self,$class);
}

#line 172 "A_CIFParser_grammar.yp"

# --------------------------------------------------------------
# begin of footer
# --------------------------------------------------------------

sub _Error
{
        $_[0]->YYData->{ERRCOUNT}++;
	exists $_[0]->YYData->{ERRMSG}
	and do {
		print STDERR $_[0]->YYData->{ERRMSG};
		delete $_[0]->YYData->{ERRMSG};
		return;
	};
	print STDERR "Analyzed symbols line containing bogus data (num. " . 
		$_[0]->YYData->{VARS}{lines} . " pos. " . 
		$_[0]->YYData->{VARS}{token_prev_pos} . ") was:\n" . 
		$_[0]->YYData->{VARS}{current_line} . "\n";
	print STDERR " " x $_[0]->YYData->{VARS}{token_prev_pos};
	print STDERR "^\n";
}

sub _Lexer
{
	my($parser) = shift;
	my $input = $parser->YYData->{INPUT};

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
			$input = <$CIFParser::FILEIN>;
			$parser->YYData->{VARS}{lines}++;
		} until ( !defined $input ||
			$input !~ m/^(\s*(#.*)?)$/s );
		if( defined $input )
		{
			chomp $input;
			$input=~s/\r$//g;
			$input=~s/\t/    /g;
			$parser->YYData->{VARS}{current_line} = 
				$input;
			$parser->YYData->{VARS}{token_pos} = 0;
		} else {
			$parser->YYData->{INPUT} = $input; return('',undef);
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
			$parser->YYData->{INPUT} = $input; return('FLOAT', $1);
		}
		#matching integers:
                if( s/^($INTEGER (?:\([0-9]+\))?)(\s)/$2/sx
                        || s/^($INTEGER (?:\([0-9]+\))?)$//sx )
		{
			advance_token($parser);
			$parser->YYData->{INPUT} = $input; return('INT', $1);
		}
		#matching double quoted strings
		if( s/^("${ANY_PRINT_CHAR}*?")(\s)/$2/s
			|| s/^("${ANY_PRINT_CHAR}*?")$//s )
		{
			advance_token($parser);
			$parser->YYData->{INPUT} = $input; return('DQSTRING', $1);
		}
		#matching single quoted strings
		if( s/^('${ANY_PRINT_CHAR}*?')(\s)/$2/s
			|| s/^('${ANY_PRINT_CHAR}*?')$//s )
		{
			advance_token($parser);
			$parser->YYData->{INPUT} = $input; return('SQSTRING', $1);
		}
		#matching text field
		if( $parser->YYData->{VARS}{token_pos} == 0 )
		{
			if( s/^;(${ANY_PRINT_CHAR}*)$//s )
			{
				my $eotf = 0;
				my $tfield;	#all textfield
				my $tf_line_begin =
					$parser->YYData->{VARS}{lines};
				$tfield = $1;
				while( 1 )
				{
					my $line = <$CIFParser::FILEIN>;
					if( defined $line )
					{
						chomp $line;
						$line=~s/\r$//g;
						$line=~s/\t/    /g;
						$parser->YYData->{VARS}{current_line} = 
							$line;
						$parser->YYData->{VARS}{lines}++;
						if( $line =~
							s/^;//s )
						{
							if( defined $line )
							{
							$input
								= $line;
							$parser->YYData->{VARS}{token_pos} = 1;
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
					$parser->YYData->{ERRMSG} = <<END_M;
ERROR encountered while in text field, which started in line $tf_line_begin.
Possible runaway of closing ';', or unexpected end of file.
END_M
					$parser->YYError();
				}
				$parser->YYData->{INPUT} = $input; return('TEXT_FIELD', $tfield);
			}
		}
		#matching [local] attribute
		if( s/^(\[local\])//si )
		{
			advance_token($parser);
			$parser->YYData->{INPUT} = $input; return('LOCAL', $1);
		}
		#matching GLOBAL_ field
		if( s/^(global_.*)$//si )
		{
			advance_token($parser);
			$parser->YYData->{ERRMSG} = "GLOBAL_ symbol detected" .
				" in line " .
				$parser->YYData->{VARS}{lines} .
				", pos. " .
				$parser->YYData->{VARS}{token_prev_pos} . ":\n--\n" .
				$parser->YYData->{VARS}{current_line} . "\n--\n" .
				"It is not acceptable in this version!\n";
			$parser->YYError();
			$parser->YYData->{INPUT} = $input; return('GLOBAL_', $1);
		}
		#matching SAVE_ head
		if( s/^(save_${NON_BLANK_CHAR}+)//si )
		{
			advance_token($parser);
			$parser->YYData->{INPUT} = $input; return('SAVE_HEAD', $1);
		}
		#matching SAVE_ foot
		if( s/^(save_)//si )
		{
			advance_token($parser);
			$parser->YYData->{INPUT} = $input; return('SAVE_FOOT', $1);
		}
		#matching STOP_ field
		if( s/^(stop_.*)$//si )
		{
			advance_token($parser);
			$parser->YYData->{ERRMSG} = "STOP_ symbol detected" .
				" in line " .
				$parser->YYData->{VARS}{lines} .
				", pos. " .
				$parser->YYData->{VARS}{token_prev_pos} . ":\n--\n" .
				$parser->YYData->{VARS}{current_line} . "\n--\n" .
				"It is not acceptable in this version!\n";
			$parser->YYError();
			$parser->YYData->{INPUT} = $input; return('STOP_', $1);
		}
		#matching DATA_ field
		if( s/^(data_${NON_BLANK_CHAR}+)//si )
		{
			advance_token($parser);
			$parser->YYData->{INPUT} = $input; return('DATA_', $1);
		}
		#matching LOOP_ begining
		if( s/^(loop_)//si )
		{
			advance_token($parser);
			$parser->YYData->{VARS}{loop_begin} =
					$parser->YYData->{VARS}{lines};
			$parser->YYData->{INPUT} = $input; return('LOOP_', $1);
		}
		#matching TAG's
		if( s/^(_${NON_BLANK_CHAR}+)//si )
		{
			advance_token($parser);
			$parser->YYData->{INPUT} = $input; return('TAG', $1);
		}
		#matching unquoted strings
		if( $parser->YYData->{VARS}{token_pos} == 0 )
		{ #UQSTRING at first pos. of line
			if( s/^(?: ( ($ORDINARY_CHAR | \[ )
				($NON_BLANK_CHAR)*) )
				//sx)
			{
				advance_token($parser);
				$parser->YYData->{INPUT} = $input; return('UQSTRING', $1);
			}
		} else { #UQSTRING in line
			if( s/^(?: ( ($ORDINARY_CHAR | ; | \[ )
				($NON_BLANK_CHAR)*) )
				//sx )
			{
				advance_token($parser);
				$parser->YYData->{INPUT} = $input; return('UQSTRING', $1);
			}
		}
		#matching any still unmatched symbol:
		if( s/^(.)//m )
		{
			advance_token($parser);
			$parser->YYData->{INPUT} = $input; return($1,$1);
		}
	}
}

sub advance_token
{
	my $parser = shift;
	$parser->YYData->{VARS}{token_prev_pos} =
		$parser->YYData->{VARS}{token_pos};
	$parser->YYData->{VARS}{token_pos} += length($1);
}

sub Run
{
	my($self) = shift;
	my($filename) = shift;

	$filename = "-" unless $filename;
	$CIFParser::FILEIN = new FileHandle $filename;
	$| = 1;
	if( $CIFParser::debug >= 2 && $CIFParser::debug < 3)
	{
		$self->YYParse( yylex => \&_Lexer,
				yyerror => \&_Error,
				yydebug => 0x05 );
	} else {
		$self->YYParse( yylex => \&_Lexer, yyerror => \&_Error );
	}
	if( $self->YYNberr() == 0 )
	{
		if( $CIFParser::debug >= 1 && $CIFParser::debug < 3)
		{
			print "File syntax is CORRECT!\n";
		}
		undef $CIFParser::FILEIN;
	} else {
		if( $CIFParser::debug >= 1 && $CIFParser::debug < 3)
		{
			print "Syntax check failed.\n";
		}
		undef $CIFParser::FILEIN;
	}
	return $self->{USER}->{CIFfile};
}

return 1;

1;
