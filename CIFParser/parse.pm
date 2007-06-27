####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package parse;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 8 "parse.yp"

use warnings;


sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'FLOAT' => 1
		},
		DEFAULT => -1,
		GOTOS => {
			'cif_elements' => 2,
			'cif_file' => 3
		}
	},
	{#State 1
		DEFAULT => -4
	},
	{#State 2
		ACTIONS => {
			'FLOAT' => 4
		},
		DEFAULT => -2
	},
	{#State 3
		ACTIONS => {
			'' => 5
		}
	},
	{#State 4
		DEFAULT => -3
	},
	{#State 5
		DEFAULT => 0
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
		 'cif_elements', 2, undef
	],
	[#Rule 4
		 'cif_elements', 1,
sub
#line 23 "parse.yp"
{ $_[0]->YYData->{VARS}{$_[1]} }
	]
],
                                  @_);
    bless($self,$class);
}

#line 26 "parse.yp"

# --------------------------------------------------------------
# begin of footer
# --------------------------------------------------------------

sub _Error
{
	exists $_[0]->YYData->{ERRMSG}
	and do {
		print $_[0]->YYData->{ERRMSG};
		delete $_[0]->YYData->{ERRMSG};
		return;
	};
	print "Syntax error.\n";
}

sub _Lexer
{
	my($parser) = shift;

	if( !$parser->YYData->{INPUT} ) {
		$parser->YYData->{INPUT} = <STDIN>;
		if( defined $parser->YYData->{INPUT} )
		{
			chomp $parser->YYData->{INPUT};
		} else {
			return('',undef);
		}
	}

	$parser->YYData->{INPUT}=~s/^[ \t]//;

#	print ">>> '", $parser->YYData->{INPUT}, "'\n";

	for ($parser->YYData->{INPUT})
	{
#matching floats
		s/^([0-9]*\.[0-9]+)//
			and return('FLOAT', $1);
#any unmatched symbol
		s/^(.)//s
			and return($1,$1);
	}
}

sub Run
{
	my($self) = shift;
	$self->YYParse( yylex => \&_Lexer, yyerror => \&_Error );
	if( $self->YYNberr() == 0 )
	{
		print "File syntax is CORRECT!\n";
	} else {
		print "Syntax check failed.\n";
	}

}

my($prog) = new parse;
$prog->Run;


1;
