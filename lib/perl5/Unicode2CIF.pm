#------------------------------------------------------------------------
#$Author$
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
@Unicode2CIF::ISA = qw(Exporter);
@Unicode2CIF::EXPORT = qw(unicode2cif cif2unicode);

my %commands = (
#
# Arrows and mathematical symbols:
#
    "\x{2190}" => '\\\\leftarrow ',  # LEFTWARDS ARROW
    "\x{2192}" => '\\\\rightarrow ', # RIGHTWARDS ARROW
    "\x{00D7}" => '\\\\times ',      # MULTIPLICATION SIGN (times)
    "\x{2012}" => '--',              # EN DASH             (dash) (?)
    "\x{2013}" => '--',              # EN DASH             (dash)
    "\x{2014}" => '---',             # EM DASH             (single bond)
    "\x{00B1}" => '+-',              # PLUS-MINUS SIGN     (plus-minus)
    "\x{2213}" => '-+',              # MINUS-OR-PLUS SIGN  (minus-plus)
    ## "\x{003D}" => '\\\\db ',      # EQUALS SIGN         (double bond)
    ## "\x{2A75}" => '\\\\db ',      # TWO EQUALS SIGNS    (used for double bond)
    "\x{25A1}" => '\\\\square ',     # WHITE SQUARE        (square)
    "\x{2261}" => '\\\\tb ',         # IDENTICAL TO        (triple bond)
    "\x{2260}" => '\\\\neq ',        # NOT EQUAL TO

    # For this symbol, no suitable Unicode character could be found.
    # '\\ddb' delocalized double bond

    "\x{223C}" => '\\sim ', # TILDE OPERATOR
    "\x{2329}" => '\\\\langle ', # LEFT-POINTING ANGLE BRACKET     (langle)
    "\x{232A}" => '\\\\rangle ', # RIGHT-POINTING ANGLE BRACKET     (rangle)
    "\x{2243}" => '\\\\simeq ',  # ASYMPTOTICALLY EQUAL TO
    "\x{221E}" => '\\\\infty ',  # INFINITY
);

#
# %alt_cmd is used only to transform from Unicode to CIF commands. For
# back translation only main forms, %commands, are used, since
# information about the variety of Unicode characters is lost.
#

my %alt_cmd = (
#
# Alternative Unicode encoding of some commands:
#
    # Main:
    # "\x{232A}" => '\\\\rangle ', # RIGHT-POINTING ANGLE BRACKET     (rangle)
    #
    # Alternatives:
    #">"       => '\\\\rangle ',   # GREATER-THAN SIGN
    "\x{27E9}" => '\\\\rangle ',   # MATHEMATICAL RIGHT ANGLE BRACKET (rangle)
    "\x{3009}" => '\\\\rangle ',   # RIGHT ANGLE BRACKET              (rangle)
    # "\x{203A}" => '\\\\rangle ', # SINGLE RIGHT-POINTING ANGLE QUOTATION

    # Main:
    # "\x{2329}" => '\\\\langle ', # LEFT-POINTING ANGLE BRACKET     (langle)
    #
    # Alternatives:
    #"<"       => '\\\\langle ',   # LESS-THAN SIGN
    "\x{27E8}" => '\\\\langle ',   # MATHEMATICAL LEFT ANGLE BRACKET (langle)
    "\x{3008}" => '\\\\langle ',   # LEFT ANGLE BRACKET              (langle)
    # "\x{2039}" => '\\\\langle ', # SINGLE LEFT-POINTING ANGLE QUOTATION

    # Main:
    # "\x{223C}" => '\\sim ', # TILDE OPERATOR
    #
    # Alternatives:
    "\x{02DC}" => '\\sim ',   # SMALL TILDE
    "\x{2053}" => '\\sim ',   # SWUNG DASH
    "\x{FF5E}" => '\\sim ',   # FULLWIDTH TILDE
    # character '~' (TILDE) is not used since it denotes subscript in CIF.

    # Main: "\x{25A1}" => '\\\\square ', # WHITE SQUARE        (square)
    # "\x{2610}" => '\\\\square ',       # BALLOT BOX          (square) (?)
    #
    # 'Ballot box' character, though similar to 'square', seems inappropriate
    # to denote mathematical and chemical formulae and therefore
    # is at present not interpreted.
    #
);

my %letters = (
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
#
# Some special European letters
#
    "\x{00DF}" => '\&s',  # LATIN SMALL LETTER SHARP S (German eszett)
    "\x{0141}" => '\/L',  # LATIN CAPITAL LETTER L WITH STROKE
    "\x{0142}" => '\/l',  # LATIN SMALL LETTER L WITH STROKE
    "\x{00D8}" => '\/O',  # LATIN CAPITAL LETTER O WITH STROKE
    "\x{00F8}" => '\/o',  # LATIN SMALL LETTER O WITH STROKE
    "\x{0110}" => '\/D',  # LATIN CAPITAL LETTER D WITH STROKE (barred D ?)
    "\x{0111}" => '\/d',  # LATIN SMALL LETTER D WITH STROKE (barred d ?)
    "\x{0131}" => '\?i',  # LATIN SMALL LETTER DOTLESS I
    "A\x{030A}" => '\%A', # LATIN CAPITAL LETER A with ring above
    "a\x{030A}" => '\%a', # LATIN SMALL LETER A with ring above
    "U\x{030A}" => '\%U', # LATIN CAPITAL LETER U with ring above
    "u\x{030A}" => '\%u', # LATIN SMALL LETER U with ring above
);

#
# Special signs are CIF sequences that need to be transformed after
# the letters, only if the letters do not match. Since the letetrs
# themselves must be transformed after the %commands list, these
# special signs can not be included into the %commands hash.
#

my %special_signs = (
    "\x{00B0}" => '\%',          # DEGREE SIGN
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
   ## "\x{030A}" => '\%',   #   COMBINING RING ABOVE (ring)
   ## "\x{0338}" => '\/',   #   COMBINING LONG SOLIDUS OVERLAY (ring)
   ## # alternatives:
   ## "\x{0337}" => '\/',   #   COMBINING SHORT SOLIDUS OVERLAY (ring)
); 

#
# Add upper-case Greek letters:
#

for my $i ( 0x0391 .. 0x03A9 ) {
    if( $i != 0x03A2 ) { # reserved code-point, could be an uppercase varsigma
	my $c = chr($i);
	$letters{$c} = uc($letters{lc($c)});
	## binmode(STDOUT,":utf8");
	## print ">>> $c, $cif{$c}\n";
    }
}

my %cif = ( %commands, %alt_cmd, %letters, %special_signs );

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
    $text =~ s/([^\x{0000}-\x{007F}])/sprintf("&#x%04X;",ord($1))/eg;
    return $text;
}

sub cif2unicode
{
    my $text = $_[0];

    $text =~ s/\\\\db /\x{003D}/g;
    for my $pattern (keys %commands) {
	my $value = $commands{$pattern};
    	$text =~ s/\Q$value/$pattern/g;
    	if( $pattern =~ /\s$/ ) {
    	    my $core = $value;
    	    $core =~ s/\s$//;
    	    $text =~ s/\Q$core\E([^a-zA-Z0-9])/$pattern$1/g;
    	    $text =~ s/\Q$core\E([^a-zA-Z0-9])/$pattern$1/g;
    	    $text =~ s/\Q$core\E$/$pattern/g;
    	}
    }
    for my $pattern (keys %letters) {
	$text =~ s/\Q$letters{$pattern}\E/$pattern/g;
    }
    for my $pattern (keys %special_signs) {
	$text =~ s/\Q$special_signs{$pattern}\E/$pattern/g;
    }
    for my $pattern (keys %combining) {
	$text =~ s/(\Q$combining{$pattern}\E)(.)/$2$1/g;
	$text =~ s/\Q$combining{$pattern}\E/$pattern/g;
    }
    $text =~ s/\&\#x([0-9A-Fa-f]+);/chr(hex($1))/eg;
    return Unicode::Normalize::normalize( 'C', $text );
}

return 1;
