#! /bin/sh
#!perl -w # --*- Perl -*--
eval 'exec perl5 -x $0 ${1+"$@"}'
    if 0;
#------------------------------------------------------------------------------
#$Author:$
#$Date:$ 
#$Revision:$
#$URL:$
#------------------------------------------------------------------------------
#*
#  Perl script ...
#**

use strict;

local $\ = "\n";
local $, = "||";

while(<>) {
    my $line = $_;
    my $pos = 0;
    my @tokens = ();

    #scalars storing regular expressions, common to several matches
    my $ORDINARY_CHAR	=	
	qr/[a-zA-Z0-9!%&\(\)\*\+,-\.\/\:<=>\?@\\\^`{\|}~]/is;
    my $SPECIAL_CHAR	=	qr/["#\$'_\[\]]/is;
    my $NON_BLANK_CHAR	=	qr/(?:$ORDINARY_CHAR|$SPECIAL_CHAR|;)/is;
    my $TEXT_LEAD_CHAR	=	qr/(?:$ORDINARY_CHAR|$SPECIAL_CHAR|\s)/s;
    my $ANY_PRINT_CHAR	=	qr/(?:$NON_BLANK_CHAR|\s)/is;
    my $INTEGER		=	qr/[-+]?[0-9]+/s;
    my $EXPONENT	=	qr/e[-+]?[0-9]+/is;
    my $FLOAT11		=	qr/(?: $INTEGER $EXPONENT)/ix;
    my $FLOAT21		=	qr/(?: [+-]? [0-9]* \. [0-9]+ $EXPONENT ?)/ix;
    my $FLOAT31		=	qr/(?: $INTEGER \. $EXPONENT ?)/ix;
    my $FLOAT		=	qr/(?: (?: $FLOAT11 | $FLOAT21 | $FLOAT31))/six;

    while( $line ) {
	#matching white space characters
	if( $line =~ s/(\s*)//s ) {
	    advance_token($line);
	}
		
	for ($line)
	{
	    #matching floats:
	    if( s/^(?: ($FLOAT (?:\([0-9]+\))?) (\s) )/$2/six
		|| s/^($FLOAT (?:\([0-9]+\))?)$//six )
	    {
		advance_token($line);
		push( @tokens, 'FLOAT', $1);
	    }
	    #matching integers:
	    if( s/^($INTEGER (?:\([0-9]+\))?)(\s)/$2/sx
		|| s/^($INTEGER (?:\([0-9]+\))?)$//sx )
	    {
		advance_token($line);
		push(@tokens, 'INT', $1);
	    }
	    #matching double quoted strings
	    if( s/^("${ANY_PRINT_CHAR}*?")(\s)/$2/s
		|| s/^("${ANY_PRINT_CHAR}*?")$//s )
	    {
		advance_token($line);
		push(@tokens, 'DQSTRING', $1);
	    }
	    #matching single quoted strings
	    if( s/^('${ANY_PRINT_CHAR}*?')(\s)/$2/s
		|| s/^('${ANY_PRINT_CHAR}*?')$//s )
	    {
		advance_token($line);
		push(@tokens, 'SQSTRING', $1);
	    }
	    #matching text field
	    if( $pos == 0 )
	    {
		if( s/^;(${ANY_PRINT_CHAR}*)$//s )
		{
		    my $eotf = 0;
		    my $tfield;	#all textfield
		    $tfield = $1;
		    while( 1 )
		    {
			my $line = <>;
			if( defined $line )
			{
			    chomp $line;
			    $line=~s/\r$//g;
			    $line=~s/\t/    /g;
			    if( $line =~ s/^;//s )
			    {
				if( defined $line )
				{
				    $line
					= $line;
				    $pos = 1;
				}
				last;
			    } else {
				$tfield .= "\n" . $line;
			    }
			} else {
			    undef $line;
			    last;
			}
		    }
		    if( !defined $line )
		    {
			print STDERR
			"ERROR encountered while in text field. ".
			"Possible runaway of closing ';', or unexpected ".
			"end of file.";
			die;
		    }
		    push(@tokens, 'TEXT_FIELD', $tfield);
		}
	    }
	    #matching [local] attribute
	    if( s/^(\[local\])//si )
	    {
		advance_token($line);
		push(@tokens, 'LOCAL', $1);
	    }
	    #matching GLOBAL_ field
	    if( s/^(global_.*)$//si )
	    {
		advance_token($line);
		print STDERR "GLOBAL_ symbol detected";
		push(@tokens, 'GLOBAL_', $1);
	    }
	    #matching SAVE_ head
	    if( s/^(save_${NON_BLANK_CHAR}+)//si )
	    {
		advance_token($line);
		push(@tokens, 'SAVE_HEAD', $1);
	    }
	    #matching SAVE_ foot
	    if( s/^(save_)//si )
	    {
		advance_token($line);
		push(@tokens, 'SAVE_FOOT', $1);
	    }
	    #matching STOP_ field
	    if( s/^(stop_.*)$//si )
	    {
		advance_token($line);
		print STDERR "STOP_ symbol detected";
		##die;
		push(@tokens, 'STOP_', $1);
	    }
	    #matching DATA_ field
	    if( s/^(data_${NON_BLANK_CHAR}+)//si )
	    {
		advance_token($line);
		push(@tokens, 'DATA_', $1);
	    }
	    #matching LOOP_ begining
	    if( s/^(loop_)//si )
		{
		    advance_token($line);
		    push(@tokens, 'LOOP_', $1);
		}
		#matching TAG's
	    if( s/^(_${NON_BLANK_CHAR}+)//si )
	    {
		advance_token($line);
		push(@tokens, 'TAG', $1);
	    }
	    #matching unquoted strings
	    if( $pos == 0 )
	    { #UQSTRING at first pos. of line
		if( s/^(?: ( ($ORDINARY_CHAR | \[ )
				($NON_BLANK_CHAR)*) )
				//sx)
		{
		    advance_token($line);
		    push(@tokens, 'UQSTRING', $1);
		}
	    } else { #UQSTRING in line
		if( s/^(?: ( ($ORDINARY_CHAR | ; | \[ )
				($NON_BLANK_CHAR)*) )
				//sx )
		{
		    advance_token($line);
		    push(@tokens, 'UQSTRING', $1);
		}
	    }
	    #matching any still unmatched symbol:
	    if( s/^(.)//m )
	    {
		advance_token($line);
		push(@tokens, $1,$1);
	    }
	}
    }
    print ">>>", @tokens, "<<<";
}

sub advance_token
{
}
