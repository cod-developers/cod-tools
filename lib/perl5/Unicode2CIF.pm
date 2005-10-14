#------------------------------------------------------------------------
#$Author: saulius $
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------

package Unicode2CIF;

use strict;
## use utf8;
use charnames ':full';

require Exporter;
@ShowStruct::ISA = qw(Exporter);
@ShowStruct::EXPORT = qw(unicode2cif cif2unicode);

my %cif = (
    "\N{RIGHTWARDS ARROW}" => '\\\\rightarrow ',
    "\N{LEFTWARDS ARROW}"  => '\\\\leftarrow ',
    "\N{UP TACK}"          => '\\\\x{22A5}',
    "\x{27C2}"             => '\\\\x{27C2}', # PERPENDICULAR
    "\x{03B1}" => '\a', # alpha
    "\x{03B2}" => '\b', # beta
    "\x{03B3}" => '\g', # gamma
    "\x{03B4}" => '\d', # delta
    "\x{03B5}" => '\e', # epsilon
    "\x{03B6}" => '\z', # zeta
    "\x{03B7}" => '\h', # eta
    "\x{03B8}" => '\q', # theta
    "\x{03B9}" => '\i', # iota
    "\x{03BA}" => '\k', # kappa
    "\x{03BB}" => '\l', # lambda
    "\x{03BC}" => '\m', # miu
    "\x{03BD}" => '\n', # niu
    "\x{03BE}" => '\x', # ksi
    "\x{03BF}" => '\o', # omicron
    "\x{03C0}" => '\p', # pi
    "\x{03C1}" => '\r', # rho
    "\x{03C2}" => '\s', # varsigma
    "\x{03C3}" => '\s', # sigma
    "\x{03C4}" => '\t', # tau
    "\x{03C5}" => '\u', # upsilon
    "\x{03C6}" => '\f', # phi
    "\x{03C7}" => '\c', # chi
    "\x{03C8}" => '\y', # psi
    "\x{03C9}" => '\w', # omega
);

for my $i ( 0x0391 .. 0x03A9 ) {
    if( $i != 0x03A2 ) { # reserved code-point, could be an uppercase varsigma
	my $c = chr($i);
	$cif{$c} = uc($cif{lc($c)});
	## binmode(STDOUT,":utf8");
	## print ">>> $c, $cif{$c}\n";
    }
}

sub unicode2cif
{
    my $text = $_[0];

    for my $pattern (keys %cif) {
	$text =~ s/$pattern/$cif{$pattern}/g;
    }
    return $text;
}

return 1;
