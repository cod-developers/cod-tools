#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------

package COD::CIF::Unicode2CIF;

use strict;
use warnings;
use HTML::Entities;
use Unicode::Normalize qw( normalize );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    unicode2cif
    cif2unicode
);

my %commands = (
#
# Arrows and mathematical symbols:
#
    "\x{2190}" => '\\\\leftarrow',  # LEFTWARDS ARROW
    "\x{2192}" => '\\\\rightarrow', # RIGHTWARDS ARROW
    "\x{00D7}" => '\\\\times',   # MULTIPLICATION SIGN (times)
    "\x{2013}" => '--',          # EN DASH             (dash)
    "\x{2014}" => '---',         # EM DASH             (single bond)
    "\x{00B1}" => '+-',          # PLUS-MINUS SIGN     (plus-minus)
    "\x{2213}" => '-+',          # MINUS-OR-PLUS SIGN  (minus-plus)
    "\x{25A1}" => '\\\\square',  # WHITE SQUARE        (square)
  # "\x{2260}"  => '\\\\neq',    # NOT EQUAL TO [Unicode NFC]
    "=\x{0338}" => '\\\\neq',    # NOT EQUAL TO [Unicode NFD]
    "\x{223C}" => '\\\\sim',     # TILDE OPERATOR
    "\x{2243}" => '\\\\simeq',   # ASYMPTOTICALLY EQUAL TO
    "\x{221E}" => '\\\\infty',   # INFINITY
    "\x{27E8}" => '\\\\langle',  # MATHEMATICAL LEFT ANGLE BRACKET  (langle)
    "\x{27E9}" => '\\\\rangle',  # MATHEMATICAL RIGHT ANGLE BRACKET (rangle)

# IUCr notes that \\db, \\tb and \\ddb should always
# be followed by a space, e.g. C=C is denoted by C\\db C
  # "\x{003D}" => '\\\\db ',     # EQUALS SIGN         (double bond)
  # "\x{2A75}" => '\\\\db ',     # TWO EQUALS SIGNS    (double bond)
    "\x{2393}" => '\\\\ddb ',    # DIRECT CURRENT SYMBOL FORM TWO (delocalized double bond)
    "\x{2261}" => '\\\\tb ',     # IDENTICAL TO        (triple bond)
);

#
# %alt_cmd is used only to transform from Unicode to CIF commands.
# For back translation only main forms, %commands, are used, since
# information about the variety of Unicode characters is lost.
#

my %alt_cmd = (
#
# Alternative Unicode encoding of some commands:
#
    # Main:
    # "\x{2013}" => '--' # EN DASH      (dash)
    "\x{2012}" => '--',  # FIGURE DASH  (dash)

    # Main:
    # "\x{27E9}" => '\\\\rangle',  # MATHEMATICAL RIGHT ANGLE BRACKET (rangle)
    #
    # Alternatives:
    # ">"      => '\\\\rangle',    # GREATER-THAN SIGN
    "\x{232A}" => '\\\\rangle',    # RIGHT-POINTING ANGLE BRACKET     (rangle)
    "\x{3009}" => '\\\\rangle',    # RIGHT ANGLE BRACKET              (rangle)
    # "\x{203A}" => '\\\\rangle',  # SINGLE RIGHT-POINTING ANGLE QUOTATION

    # Main:
    # "\x{27E8}" => '\\\\langle', # MATHEMATICAL LEFT ANGLE BRACKET   (langle)
    #
    # Alternatives:
    # "<"      => '\\\\langle',   # LESS-THAN SIGN
    "\x{2329}" => '\\\\langle',   # LEFT-POINTING ANGLE BRACKET       (langle)
    "\x{3008}" => '\\\\langle',   # LEFT ANGLE BRACKET                (langle)
    # "\x{2039}" => '\\\\langle', # SINGLE LEFT-POINTING ANGLE QUOTATION

    # Main:
    # "\x{223C}" => '\\sim',   # TILDE OPERATOR
    #
    # Alternatives:
    "\x{02DC}" => '\\\\sim',   # SMALL TILDE
    "\x{2053}" => '\\\\sim',   # SWUNG DASH
    "\x{FF5E}" => '\\\\sim',   # FULLWIDTH TILDE
    # character '~' (TILDE) is not used since it denotes subscript in CIF.

    # Main: "\x{25A1}" => '\\\\square', # WHITE SQUARE        (square)
    # "\x{2610}" => '\\\\square',       # BALLOT BOX          (square) (?)
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
    "\x{1E9E}" => '\&S',  # LATIN CAPITAL LETTER SHARP S
    "\x{0141}" => '\/L',  # LATIN CAPITAL LETTER L WITH STROKE
    "\x{0142}" => '\/l',  # LATIN SMALL LETTER L WITH STROKE
    "\x{00D8}" => '\/O',  # LATIN CAPITAL LETTER O WITH STROKE
    "\x{00F8}" => '\/o',  # LATIN SMALL LETTER O WITH STROKE
    "\x{0110}" => '\/D',  # LATIN CAPITAL LETTER D WITH STROKE (barred D ?)
    "\x{0111}" => '\/d',  # LATIN SMALL LETTER D WITH STROKE (barred d ?)
    "\x{0131}" => '\?i',  # LATIN SMALL LETTER DOTLESS I
  # "\x{00C5}"  => '\%A', # LATIN CAPITAL LETTER A WITH RING ABOVE [Unicode NFC]
    "A\x{030A}" => '\%A', # LATIN CAPITAL LETTER A WITH RING ABOVE [Unicode NFD]
  # "\x{00E5}"  => '\%a', # LATIN SMALL LETTER A WITH RING ABOVE [Unicode NFC]
    "a\x{030A}" => '\%a', # LATIN SMALL LETTER A WITH RING ABOVE [Unicode NFD]
);

#
# Special signs are CIF sequences that need to be transformed after
# the letters, only if the letters do not match. Since the letters
# themselves must be transformed after the %commands list, these
# special signs cannot be included into the %commands hash.
#

my %special_signs = (
    "\x{00B0}" => '\%',          # DEGREE SIGN
);

my %combining = (
#
# Combining diacritical marks:
#
   "\x{0300}" => '\\`',  #   COMBINING GRAVE ACCENT (grave)
   "\x{0301}" => '\\\'', #   COMBINING ACUTE ACCENT (acute)
   "\x{0308}" => '\"',   #   COMBINING DIAERESIS    (umlaut)
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
    # reserved code-point, could be an uppercase varsigma
    next if $i == 0x03A2;
    my $c = chr($i);
    $letters{$c} = uc($letters{lc($c)});
}

my %cif = ( %commands, %alt_cmd, %letters, %special_signs );

sub unicode2cif
{
    my ($text) = @_;

    $text = normalize( 'D', $text );
    for my $pattern (sort keys %cif) {
        $text =~ s/$pattern/$cif{$pattern}/g;
    }

    for my $pattern (sort keys %combining) {
        $text =~ s/(.)($pattern)/$2$1/g;
        $text =~ s/$pattern/$combining{$pattern}/g;
    }

    $text = encode_non_cif_characters($text);

    return $text;
}

sub cif2unicode
{
    my ($text) = @_;

    # In some rare cases, when the input contains a CIF special code for
    # the 'LATIN SMALL LETTER SHARP S (German eszett)' ('\&s'), the $text
    # gets incorrectly converted into bytes when its is originally marked
    # as 'bytes' and not 'utf8'. The Encode::decode_utf8() should force
    # Perl to believe that $text is in utf8 and make all substitutions
    # correctly
    use Encode;
    $text = Encode::decode_utf8($text);

    # The COD convention is to represent the CIF special code for a double
    # bond ('\\db ') as an equals sign ('='). Due to this, the '\\db ' code
    # is purposely not included in the %commands hash to prevent undesired
    # conversions of regular '=' characters to CIF special codes when using
    # the unicode2cif() subroutine. Consequently, the '\\db ' code needs to
    # be decoded using a separate statement
    $text =~ s/\\\\db /=/g;

    # The '--' special code is a substring of the '---' special code, 
    # therefore the '---' code must be replaced before the '--' code
    $text =~ s/---/\x{2014}/g;

    # The '\\sim' special code is a substring of the '\\simeq' special code,
    # therefore the '\\simeq' code must be replaced before the '\\sim' code
    $text =~ s/\\\\simeq/\x{2243}/g;

    for my $replacement ( \%commands, \%letters, \%special_signs ) {
        for my $cif_code (sort keys %{$replacement}) {
            my $utf_value = $replacement->{$cif_code};
            $text =~ s/\Q${utf_value}\E/${cif_code}/g;
        }
    }

    for my $cif_code (sort keys %combining) {
        my $utf_value = $combining{$cif_code};
        $text =~ s/(\Q${utf_value}\E)(.)/$2$1/g;
        $text =~ s/\Q${utf_value}\E/${cif_code}/g;
    }

    $text = decode_non_cif_characters($text);
    $text = normalize( 'C', $text );

    return $text;
}

# TODO: certain ASCII character are also not supported by the CIF 1.1 file
# format (i.e. various control symbols) and should be properly encoded. 
##
# Encodes text to a form that is compatible with the CIF 1.1 file format.
# All incompatible characters such as the non-ASCII Unicode characters
# are converted to hexadecimal numeric character references.
#
# @param $text
#       Text string that should be encoded.
# @return
#       Encoded text string.
##
sub encode_non_cif_characters
{
    my ($text) = @_;

    $text =~ s/([^\x{0000}-\x{007F}])/sprintf("&#x%04X;",ord($1))/eg;

    return $text;
}

# FIXME: the currently used HTML::Entities::decode_entities subroutine
# decodes multiple codes that are not produced by the encode_non_cif_characters()
# subroutine, i.e. decimal numeric character references, character entity
# references
##
# Decodes text from the form that is compatible with the CIF 1.1 file format
# as produced by the encode_non_cif_characters() subroutine. All hexadecimal
# numeric character references are converted to proper Unicode characters.
#
# @param $text
#       Text string that should be decoded.
# @return
#       Decoded text string.
##
sub decode_non_cif_characters
{
    my ($text) = @_;

    $text = decode_entities($text);

    return $text;
}

1;
