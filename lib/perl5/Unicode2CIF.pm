#------------------------------------------------------------------------
#$Author: saulius $
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------

package Unicode2CIF;

use strict;
use Unicode::Normalize;
## use utf8;
## use charnames ':full';

require Exporter;
@ShowStruct::ISA = qw(Exporter);
@ShowStruct::EXPORT = qw(unicode2cif cif2unicode);

my %cif = (
#
# Arrows and mathematical symbols:
#
    "\x{2190}" => '\\\\leftarrow ',  # LEFTWARDS ARROW
    "\x{2192}" => '\\\\rightarrow ', # RIGHTWARDS ARROW
    "\x{22A5}" => '\\x{22A5}',       # UP TACK, similar to PERPENDICULAR
    "\x{27C2}" => '\\x{27C2}',       # PERPENDICULAR

    "\x{00B0}" => '\%',       # DEGREE SIGN
    "\x{00D7}" => '\\times ', # MULTIPLICATION SIGN

# --
# dash

# 
# +-
# ±
# 
# ---
# single bond
# 
# -+
# 
# \\db
# double bond
# 
# \\square
# square
# 
# \\tb
# triple bond
# 
# \\neq
# 
# \\ddb
# delocalized double bond
# 
# \\rangle
# 
# \\sim
# 
# \\langle
# 
# (N.B. ~  is the code for subscript)
# \\rightarrow
# 
# \\simeq
# 
# \\leftarrow
# 
# \\infty

#
# Greek letters:
#
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

my %combining = (
#
# Combining diacritical marks:
#
   "\x{0300}" => '\\`',  #   COMBINING GRAVE ACCENT (grave)
   "\x{0301}" => '\\\'', #'# COMBINING ACUTE ACCENT (acute)
   "\x{0308}" => '\"',   #   COMBINING DIARESIS     (umlaut)
   "\x{0304}" => '\=',   #   COMBINING MACRON       (overbar)
   "\x{0303}" => '\~',   #   COMBINING TILDE        (tilde)
   "\x{0307}" => '\.',   #   COMBINING DOT ABOVE    (overdot)
   "\x{0302}" => '\^',   #   COMBINING CIRCUMFLEX ACCENT (circumflex)
   "\x{0328}" => '\;',   #   COMBINING OGONEK       (ogonek)
   "\x{030C}" => '\<',   #   COMBINING CARON        (hacek)
   "\x{0327}" => '\,',   #   COMBINING CEDILLA      (cedilla)
   "\x{030B}" => '\>',   #   COMBINING DOUBLE ACUTE ACCENT (Hungarian umlaut)
   "\x{0306}" => '\(',   #   COMBINING BREVE (breve)
); 

#
# Add upper-case Greek letters:
#

for my $i ( 0x0391 .. 0x03A9 ) {
    if( $i != 0x03A2 ) { # reserved code-point, could be an uppercase varsigma
	my $c = chr($i);
	$cif{$c} = uc($cif{lc($c)});
	## binmode(STDOUT,":utf8");
	## print ">>> $c, $cif{$c}\n";
    }
}

my %utf = ();

while( my ($key,$val) = each %cif ) {
    $utf{$val} = $key;
}

sub unicode2cif
{
    my $text = Unicode::Normalize::normalize( 'D', $_[0] );

    for my $pattern (keys %cif) {
	$text =~ s/$pattern/$cif{$pattern}/g;
    }
    for my $pattern (keys %combining) {
	$text =~ s/(.)($pattern)/$2$1/g;
	$text =~ s/$pattern/$combining{$pattern}/g;
    }
    return $text;
}

sub cif2unicode
{
    my $text = $_[0];

    for my $pattern (keys %combining) {
	$text =~ s/(\Q$combining{$pattern}\E)(.)/$2$1/g;
	$text =~ s/\Q$combining{$pattern}\E/$pattern/g;
    }
    for my $pattern (keys %utf) {
    	$text =~ s/\Q$pattern/$utf{$pattern}/g;
    	if( $pattern =~ /\s$/ ) {
    	    my $core = $pattern;
    	    $core =~ s/\s$//;
    	    $text =~ s/\Q$core\E([^a-zA-Z0-9])/$utf{$pattern}$1/g;
    	    $text =~ s/\Q$core\E([^a-zA-Z0-9])/$utf{$pattern}$1/g;
    	    $text =~ s/\Q$core\E$/$utf{$pattern}/g;
    	}
    }
    return $text;
}

return 1;
