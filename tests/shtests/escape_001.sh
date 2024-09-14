#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/Escape.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( escape unescape )" \
<<'END_SCRIPT'

use strict;
use warnings;

# use COD::Escape qw( escape unescape );

sub print_escape
{
    my( $text, $escape_sequence, $escaped_symbols ) = @_;
    $escape_sequence = '\\' if !defined $escape_sequence;
    $escaped_symbols = {} if !defined $escaped_symbols;
    print escape( $text, {
        sequence => $escape_sequence,
        escaped_symbols => $escaped_symbols
    } );
}

sub print_unescape
{
    my( $text, $escape_sequence, $escaped_symbols ) = @_;
    $escape_sequence = '\\' if !defined $escape_sequence;
    $escaped_symbols = {} if !defined $escaped_symbols;
    $escaped_symbols = { reverse %$escaped_symbols };
    print unescape( $text, {
        sequence => $escape_sequence,
        escaped_symbols => $escaped_symbols
    } );
}

my $esc_whitespace = { "\t" => 't',
                       "\r" => 'r',
                       "\n" => 'n',
                       " "  => ' ' };

print_escape( <<'END' );
\a \\b \\\c \\\\d \\\\\e
\\ \\\\ \\\\\\
\ \\\ \\\\\
END

print "\n";

print_unescape( <<'END' );
\\a \\\\b \\\\\\c \\\\\\\\d \\\\\\\\\\e
\\\\ \\\\\\\\ \\\\\\\\\\\\
\\ \\\\\\ \\\\\\\\\\
END

print "\n";

print_escape( <<'END', undef, $esc_whitespace );
BOND     1  1.477027         ? C(CCCH)(OCH)(OC) C(CCCH)(CCOO)(HC)
BOND     1  1.330299         ? C(C[6]C3)(CCCH)(HC) C(CCCH)(CCOO)(HC)
BOND     2  1.516531  0.014741 C(C[6]C3)(CCH3)(NCCH)(HC) C(CCCHN)(HC)3
BOND     1  1.472368         ? C[6](C[6]CCH)(C[6]CCN)(CCCH) C(C[6]C3)(CCCH)(HC)
BOND     1  1.408714         ? C[6](C[6]CCH)(C[6]CCN)(CCCH) C[6](C[6]CCH)(C[6]C3)(HC)
BOND     1  1.404715         ? C[6](C[6]CCH)(C[6]CCN)(CCCH) C[6](C[6]CCH)(C[6]C3)(NCOO)
BOND     1  1.385633         ? C[6](C[6]CCH)(C[6]CCN)(HC) C[6](C[6]CCH)(C[6]C3)(HC)
BOND     2  1.520173  0.000796 C[6](C[6]CCH)2(CCCHN) C(C[6]C3)(CCH3)(NCCH)(HC)
BOND     4  1.371865  0.008216 C[6](C[6]CCH)2(CCCHN) C[6](C[6]CCH)(C[6]C3)(HC)
BOND     4  1.376174  0.006906 C[6](C[6]CCH)2(HC) C[6](C[6]CCH)(C[6]C3)(HC)
BOND     4  1.361172  0.012574 C[6](C[6]CCH)2(HC) C[6](C[6]CCH)2(HC)
BOND     1  1.388732         ? C[6](C[6]CCH)2(NCOO) C[6](C[6]CCH)(C[6]CCN)(HC)
BOND     1  1.383281         ? C[6](C[6]CCN)2(HC) C[6](C[6]CCH)(C[6]C3)(NCOO)
BOND     1  1.380685         ? C[6](C[6]CCN)2(HC) C[6](C[6]CCH)2(NCOO)
BOND     1  0.960775         ? H(CCCH) C(CCCH)(CCOO)(HC)
BOND     1  0.916345         ? H(CCCH) C(C[6]C3)(CCCH)(HC)
BOND     2  0.979244  0.000096 H(CCCHN) C(C[6]C3)(CCH3)(NCCH)(HC)
BOND     6  0.959850  0.000371 H(CCH3) C(CCCHN)(HC)3
BOND     5  0.939830  0.020270 H(C[6]CCH) C[6](C[6]CCH)(C[6]C3)(HC)
BOND     1  0.963558         ? H(C[6]CCH) C[6](C[6]CCH)(C[6]CCN)(HC)
BOND     6  0.930039  0.000254 H(C[6]CCH) C[6](C[6]CCH)2(HC)
BOND     1  0.941765         ? H(C[6]CCH) C[6](C[6]CCN)2(HC)
BOND     2  1.445461  0.001200 N(CCCHN)(CNNS)(HN) C(C[6]C3)(CCH3)(NCCH)(HC)
BOND     2  1.321007  0.004696 N(CCCHN)(CNNS)(HN) C(NCCH)2(SC)
BOND     2  0.889133  0.001107 N(CCCHN)(CNNS)(HN) H(NCCH)
BOND     1  1.477195         ? N(C[6]CCN)(ON)2 C[6](C[6]CCH)(C[6]C3)(NCOO)
BOND     1  1.472404         ? N(C[6]CCN)(ON)2 C[6](C[6]CCH)2(NCOO)
BOND     1  1.227043         ? O(CCOO) C(CCCH)(OCH)(OC)
BOND     1  1.322195         ? O(CCOO)(HO) C(CCCH)(OCH)(OC)
BOND     1  0.871168         ? O(CCOO)(HO) H(OCH)
BOND     4  1.231718  0.001966 O(NCOO) N(C[6]CCN)(ON)2
BOND     1  1.710209         ? S(CNNS) C(NCCH)2(SC)
CLASS    26 C
CLASS     1 C(CCCH)(CCOO)(HC) CCCH
CLASS     1 C(CCCH)(OCH)(OC) CCOO
CLASS     2 C(CCCHN)(HC)3 CCH3
CLASS     1 C(C[6]C3)(CCCH)(HC) CCCH
CLASS     2 C(C[6]C3)(CCH3)(NCCH)(HC) CCCHN
CLASS     1 C(NCCH)2(SC) CNNS
CLASS     2 CCCH C
CLASS     2 CCCHN C
CLASS     2 CCH3 C
CLASS     1 CCOO C
CLASS     1 CNNS C
CLASS     5 C[6](C[6]CCH)(C[6]C3)(HC) C[6]CCH
CLASS     1 C[6](C[6]CCH)(C[6]C3)(NCOO) C[6]CCN
CLASS     1 C[6](C[6]CCH)(C[6]CCN)(CCCH) C[6]C3
CLASS     1 C[6](C[6]CCH)(C[6]CCN)(HC) C[6]CCH
CLASS     2 C[6](C[6]CCH)2(CCCHN) C[6]C3
CLASS     6 C[6](C[6]CCH)2(HC) C[6]CCH
CLASS     1 C[6](C[6]CCH)2(NCOO) C[6]CCN
CLASS     1 C[6](C[6]CCN)2(HC) C[6]CCH
CLASS     3 C[6]C3 C
CLASS    13 C[6]CCH C
CLASS     2 C[6]CCN C
CLASS    26 H
CLASS     2 H(CCCH) HC
CLASS     2 H(CCCHN) HC
CLASS     6 H(CCH3) HC
CLASS    13 H(C[6]CCH) HC
CLASS     2 H(NCCH) HN
CLASS     1 H(OCH) HO
CLASS    23 HC H
CLASS     2 HN H
CLASS     1 HO H
CLASS     4 N
CLASS     2 N(CCCHN)(CNNS)(HN) NCCH
CLASS     2 N(C[6]CCN)(ON)2 NCOO
CLASS     2 NCCH N
CLASS     2 NCOO N
CLASS     6 O
CLASS     1 O(CCOO) OC
CLASS     1 O(CCOO)(HO) OCH
CLASS     4 O(NCOO) ON
CLASS     1 OC O
CLASS     1 OCH O
CLASS     4 ON O
CLASS     1 S
CLASS     1 S(CNNS) SC
CLASS     1 SC S
OBSBOND  1.477027 C(CCCH)(OCH)(OC) C(CCCH)(CCOO)(HC) C8 C9 2005910_mols.cif 2005910_molecule_0
OBSBOND  1.330299 C(C[6]C3)(CCCH)(HC) C(CCCH)(CCOO)(HC) C7 C8 2005910_mols.cif 2005910_molecule_0
OBSBOND  1.526954 C(C[6]C3)(CCH3)(NCCH)(HC) C(CCCHN)(HC)3 C2A C3A 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.506108 C(C[6]C3)(CCH3)(NCCH)(HC) C(CCCHN)(HC)3 C2B C3B 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.472368 C[6](C[6]CCH)(C[6]CCN)(CCCH) C(C[6]C3)(CCCH)(HC) C1 C7 2005910_mols.cif 2005910_molecule_0
OBSBOND  1.408714 C[6](C[6]CCH)(C[6]CCN)(CCCH) C[6](C[6]CCH)(C[6]C3)(HC) C1 C6 2005910_mols.cif 2005910_molecule_0
OBSBOND  1.404715 C[6](C[6]CCH)(C[6]CCN)(CCCH) C[6](C[6]CCH)(C[6]C3)(NCOO) C1 C2 2005910_mols.cif 2005910_molecule_0
OBSBOND  1.385633 C[6](C[6]CCH)(C[6]CCN)(HC) C[6](C[6]CCH)(C[6]C3)(HC) C5 C6 2005910_mols.cif 2005910_molecule_0
OBSBOND  1.519610 C[6](C[6]CCH)2(CCCHN) C(C[6]C3)(CCH3)(NCCH)(HC) C2A C4A 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.520736 C[6](C[6]CCH)2(CCCHN) C(C[6]C3)(CCH3)(NCCH)(HC) C2B C4B 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.361444 C[6](C[6]CCH)2(CCCHN) C[6](C[6]CCH)(C[6]C3)(HC) C4A C5A 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.374119 C[6](C[6]CCH)2(CCCHN) C[6](C[6]CCH)(C[6]C3)(HC) C4A C9A 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.381215 C[6](C[6]CCH)2(CCCHN) C[6](C[6]CCH)(C[6]C3)(HC) C4B C5B 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.370684 C[6](C[6]CCH)2(CCCHN) C[6](C[6]CCH)(C[6]C3)(HC) C4B C9B 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.386372 C[6](C[6]CCH)2(HC) C[6](C[6]CCH)(C[6]C3)(HC) C5A C6A 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.371980 C[6](C[6]CCH)2(HC) C[6](C[6]CCH)(C[6]C3)(HC) C5B C6B 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.371855 C[6](C[6]CCH)2(HC) C[6](C[6]CCH)(C[6]C3)(HC) C8A C9A 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.374489 C[6](C[6]CCH)2(HC) C[6](C[6]CCH)(C[6]C3)(HC) C8B C9B 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.354583 C[6](C[6]CCH)2(HC) C[6](C[6]CCH)2(HC) C6A C7A 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.358005 C[6](C[6]CCH)2(HC) C[6](C[6]CCH)2(HC) C6B C7B 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.379711 C[6](C[6]CCH)2(HC) C[6](C[6]CCH)2(HC) C7A C8A 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.352389 C[6](C[6]CCH)2(HC) C[6](C[6]CCH)2(HC) C7B C8B 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.388732 C[6](C[6]CCH)2(NCOO) C[6](C[6]CCH)(C[6]CCN)(HC) C4 C5 2005910_mols.cif 2005910_molecule_0
OBSBOND  1.383281 C[6](C[6]CCN)2(HC) C[6](C[6]CCH)(C[6]C3)(NCOO) C2 C3 2005910_mols.cif 2005910_molecule_0
OBSBOND  1.380685 C[6](C[6]CCN)2(HC) C[6](C[6]CCH)2(NCOO) C3 C4 2005910_mols.cif 2005910_molecule_0
OBSBOND  0.960775 H(CCCH) C(CCCH)(CCOO)(HC) C8 H8 2005910_mols.cif 2005910_molecule_0
OBSBOND  0.916345 H(CCCH) C(C[6]C3)(CCCH)(HC) C7 H7 2005910_mols.cif 2005910_molecule_0
OBSBOND  0.979311 H(CCCHN) C(C[6]C3)(CCH3)(NCCH)(HC) C2A H2A 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.979176 H(CCCHN) C(C[6]C3)(CCH3)(NCCH)(HC) C2B H2B 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.960382 H(CCH3) C(CCCHN)(HC)3 C3A H3A1 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.959851 H(CCH3) C(CCCHN)(HC)3 C3A H3A2 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.959813 H(CCH3) C(CCCHN)(HC)3 C3A H3A3 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.959227 H(CCH3) C(CCCHN)(HC)3 C3B H3B1 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.959844 H(CCH3) C(CCCHN)(HC)3 C3B H3B2 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.959979 H(CCH3) C(CCCHN)(HC)3 C3B H3B3 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.976085 H(C[6]CCH) C[6](C[6]CCH)(C[6]C3)(HC) C6 H6 2005910_mols.cif 2005910_molecule_0
OBSBOND  0.930450 H(C[6]CCH) C[6](C[6]CCH)(C[6]C3)(HC) C5A H5A 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.930431 H(C[6]CCH) C[6](C[6]CCH)(C[6]C3)(HC) C5B H5B 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.930918 H(C[6]CCH) C[6](C[6]CCH)(C[6]C3)(HC) C9A H9A 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.931268 H(C[6]CCH) C[6](C[6]CCH)(C[6]C3)(HC) C9B H9B 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.963558 H(C[6]CCH) C[6](C[6]CCH)(C[6]CCN)(HC) C5 H5 2005910_mols.cif 2005910_molecule_0
OBSBOND  0.930180 H(C[6]CCH) C[6](C[6]CCH)2(HC) C6A H6A 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.930079 H(C[6]CCH) C[6](C[6]CCH)2(HC) C6B H6B 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.929723 H(C[6]CCH) C[6](C[6]CCH)2(HC) C7A H7A 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.930365 H(C[6]CCH) C[6](C[6]CCH)2(HC) C7B H7B 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.929747 H(C[6]CCH) C[6](C[6]CCH)2(HC) C8A H8A 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.930140 H(C[6]CCH) C[6](C[6]CCH)2(HC) C8B H8B 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.941765 H(C[6]CCH) C[6](C[6]CCN)2(HC) C3 H3 2005910_mols.cif 2005910_molecule_0
OBSBOND  1.444613 N(CCCHN)(CNNS)(HN) C(C[6]C3)(CCH3)(NCCH)(HC) C2A N1A 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.446310 N(CCCHN)(CNNS)(HN) C(C[6]C3)(CCH3)(NCCH)(HC) C2B N1B 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.317686 N(CCCHN)(CNNS)(HN) C(NCCH)2(SC) C N1A 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.324328 N(CCCHN)(CNNS)(HN) C(NCCH)2(SC) C N1B 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.889915 N(CCCHN)(CNNS)(HN) H(NCCH) H1A N1A 2005934_mols.cif 2005934_molecule_0
OBSBOND  0.888351 N(CCCHN)(CNNS)(HN) H(NCCH) H1B N1B 2005934_mols.cif 2005934_molecule_0
OBSBOND  1.477195 N(C[6]CCN)(ON)2 C[6](C[6]CCH)(C[6]C3)(NCOO) C2 N1 2005910_mols.cif 2005910_molecule_0
OBSBOND  1.472404 N(C[6]CCN)(ON)2 C[6](C[6]CCH)2(NCOO) C4 N2 2005910_mols.cif 2005910_molecule_0
OBSBOND  1.227043 O(CCOO) C(CCCH)(OCH)(OC) C9 O2 2005910_mols.cif 2005910_molecule_0
OBSBOND  1.322195 O(CCOO)(HO) C(CCCH)(OCH)(OC) C9 O1 2005910_mols.cif 2005910_molecule_0
OBSBOND  0.871168 O(CCOO)(HO) H(OCH) H9 O1 2005910_mols.cif 2005910_molecule_0
OBSBOND  1.231894 O(NCOO) N(C[6]CCN)(ON)2 N1 O3 2005910_mols.cif 2005910_molecule_0
OBSBOND  1.228953 O(NCOO) N(C[6]CCN)(ON)2 N1 O4 2005910_mols.cif 2005910_molecule_0
OBSBOND  1.232481 O(NCOO) N(C[6]CCN)(ON)2 N2 O5 2005910_mols.cif 2005910_molecule_0
OBSBOND  1.233546 O(NCOO) N(C[6]CCN)(ON)2 N2 O6 2005910_mols.cif 2005910_molecule_0
OBSBOND  1.710209 S(CNNS) C(NCCH)2(SC) C S 2005934_mols.cif 2005934_molecule_0
END

print "\n";

print_escape( <<'END', undef, $esc_whitespace );
BOND\ \ \ \ \ 1\ \ 1.477027\ \ \ \ \ \ \ \ \ ?\ C(CCCH)(OCH)(OC)\ C(CCCH)(CCOO)(HC)\nBOND\ \ \ \ \ 1\ \ 1.330299\ \ \ \ \ \ \ \ \ ?\ C(C[6]C3)(CCCH)(HC)\ C(CCCH)(CCOO)(HC)\nBOND\ \ \ \ \ 2\ \ 1.516531\ \ 0.014741\ C(C[6]C3)(CCH3)(NCCH)(HC)\ C(CCCHN)(HC)3\nBOND\ \ \ \ \ 1\ \ 1.472368\ \ \ \ \ \ \ \ \ ?\ C[6](C[6]CCH)(C[6]CCN)(CCCH)\ C(C[6]C3)(CCCH)(HC)\nBOND\ \ \ \ \ 1\ \ 1.408714\ \ \ \ \ \ \ \ \ ?\ C[6](C[6]CCH)(C[6]CCN)(CCCH)\ C[6](C[6]CCH)(C[6]C3)(HC)\nBOND\ \ \ \ \ 1\ \ 1.404715\ \ \ \ \ \ \ \ \ ?\ C[6](C[6]CCH)(C[6]CCN)(CCCH)\ C[6](C[6]CCH)(C[6]C3)(NCOO)\nBOND\ \ \ \ \ 1\ \ 1.385633\ \ \ \ \ \ \ \ \ ?\ C[6](C[6]CCH)(C[6]CCN)(HC)\ C[6](C[6]CCH)(C[6]C3)(HC)\nBOND\ \ \ \ \ 2\ \ 1.520173\ \ 0.000796\ C[6](C[6]CCH)2(CCCHN)\ C(C[6]C3)(CCH3)(NCCH)(HC)\nBOND\ \ \ \ \ 4\ \ 1.371865\ \ 0.008216\ C[6](C[6]CCH)2(CCCHN)\ C[6](C[6]CCH)(C[6]C3)(HC)\nBOND\ \ \ \ \ 4\ \ 1.376174\ \ 0.006906\ C[6](C[6]CCH)2(HC)\ C[6](C[6]CCH)(C[6]C3)(HC)\nBOND\ \ \ \ \ 4\ \ 1.361172\ \ 0.012574\ C[6](C[6]CCH)2(HC)\ C[6](C[6]CCH)2(HC)\nBOND\ \ \ \ \ 1\ \ 1.388732\ \ \ \ \ \ \ \ \ ?\ C[6](C[6]CCH)2(NCOO)\ C[6](C[6]CCH)(C[6]CCN)(HC)\nBOND\ \ \ \ \ 1\ \ 1.383281\ \ \ \ \ \ \ \ \ ?\ C[6](C[6]CCN)2(HC)\ C[6](C[6]CCH)(C[6]C3)(NCOO)\nBOND\ \ \ \ \ 1\ \ 1.380685\ \ \ \ \ \ \ \ \ ?\ C[6](C[6]CCN)2(HC)\ C[6](C[6]CCH)2(NCOO)\nBOND\ \ \ \ \ 1\ \ 0.960775\ \ \ \ \ \ \ \ \ ?\ H(CCCH)\ C(CCCH)(CCOO)(HC)\nBOND\ \ \ \ \ 1\ \ 0.916345\ \ \ \ \ \ \ \ \ ?\ H(CCCH)\ C(C[6]C3)(CCCH)(HC)\nBOND\ \ \ \ \ 2\ \ 0.979244\ \ 0.000096\ H(CCCHN)\ C(C[6]C3)(CCH3)(NCCH)(HC)\nBOND\ \ \ \ \ 6\ \ 0.959850\ \ 0.000371\ H(CCH3)\ C(CCCHN)(HC)3\nBOND\ \ \ \ \ 5\ \ 0.939830\ \ 0.020270\ H(C[6]CCH)\ C[6](C[6]CCH)(C[6]C3)(HC)\nBOND\ \ \ \ \ 1\ \ 0.963558\ \ \ \ \ \ \ \ \ ?\ H(C[6]CCH)\ C[6](C[6]CCH)(C[6]CCN)(HC)\nBOND\ \ \ \ \ 6\ \ 0.930039\ \ 0.000254\ H(C[6]CCH)\ C[6](C[6]CCH)2(HC)\nBOND\ \ \ \ \ 1\ \ 0.941765\ \ \ \ \ \ \ \ \ ?\ H(C[6]CCH)\ C[6](C[6]CCN)2(HC)\nBOND\ \ \ \ \ 2\ \ 1.445461\ \ 0.001200\ N(CCCHN)(CNNS)(HN)\ C(C[6]C3)(CCH3)(NCCH)(HC)\nBOND\ \ \ \ \ 2\ \ 1.321007\ \ 0.004696\ N(CCCHN)(CNNS)(HN)\ C(NCCH)2(SC)\nBOND\ \ \ \ \ 2\ \ 0.889133\ \ 0.001107\ N(CCCHN)(CNNS)(HN)\ H(NCCH)\nBOND\ \ \ \ \ 1\ \ 1.477195\ \ \ \ \ \ \ \ \ ?\ N(C[6]CCN)(ON)2\ C[6](C[6]CCH)(C[6]C3)(NCOO)\nBOND\ \ \ \ \ 1\ \ 1.472404\ \ \ \ \ \ \ \ \ ?\ N(C[6]CCN)(ON)2\ C[6](C[6]CCH)2(NCOO)\nBOND\ \ \ \ \ 1\ \ 1.227043\ \ \ \ \ \ \ \ \ ?\ O(CCOO)\ C(CCCH)(OCH)(OC)\nBOND\ \ \ \ \ 1\ \ 1.322195\ \ \ \ \ \ \ \ \ ?\ O(CCOO)(HO)\ C(CCCH)(OCH)(OC)\nBOND\ \ \ \ \ 1\ \ 0.871168\ \ \ \ \ \ \ \ \ ?\ O(CCOO)(HO)\ H(OCH)\nBOND\ \ \ \ \ 4\ \ 1.231718\ \ 0.001966\ O(NCOO)\ N(C[6]CCN)(ON)2\nBOND\ \ \ \ \ 1\ \ 1.710209\ \ \ \ \ \ \ \ \ ?\ S(CNNS)\ C(NCCH)2(SC)\nCLASS\ \ \ \ 26\ C\nCLASS\ \ \ \ \ 1\ C(CCCH)(CCOO)(HC)\ CCCH\nCLASS\ \ \ \ \ 1\ C(CCCH)(OCH)(OC)\ CCOO\nCLASS\ \ \ \ \ 2\ C(CCCHN)(HC)3\ CCH3\nCLASS\ \ \ \ \ 1\ C(C[6]C3)(CCCH)(HC)\ CCCH\nCLASS\ \ \ \ \ 2\ C(C[6]C3)(CCH3)(NCCH)(HC)\ CCCHN\nCLASS\ \ \ \ \ 1\ C(NCCH)2(SC)\ CNNS\nCLASS\ \ \ \ \ 2\ CCCH\ C\nCLASS\ \ \ \ \ 2\ CCCHN\ C\nCLASS\ \ \ \ \ 2\ CCH3\ C\nCLASS\ \ \ \ \ 1\ CCOO\ C\nCLASS\ \ \ \ \ 1\ CNNS\ C\nCLASS\ \ \ \ \ 5\ C[6](C[6]CCH)(C[6]C3)(HC)\ C[6]CCH\nCLASS\ \ \ \ \ 1\ C[6](C[6]CCH)(C[6]C3)(NCOO)\ C[6]CCN\nCLASS\ \ \ \ \ 1\ C[6](C[6]CCH)(C[6]CCN)(CCCH)\ C[6]C3\nCLASS\ \ \ \ \ 1\ C[6](C[6]CCH)(C[6]CCN)(HC)\ C[6]CCH\nCLASS\ \ \ \ \ 2\ C[6](C[6]CCH)2(CCCHN)\ C[6]C3\nCLASS\ \ \ \ \ 6\ C[6](C[6]CCH)2(HC)\ C[6]CCH\nCLASS\ \ \ \ \ 1\ C[6](C[6]CCH)2(NCOO)\ C[6]CCN\nCLASS\ \ \ \ \ 1\ C[6](C[6]CCN)2(HC)\ C[6]CCH\nCLASS\ \ \ \ \ 3\ C[6]C3\ C\nCLASS\ \ \ \ 13\ C[6]CCH\ C\nCLASS\ \ \ \ \ 2\ C[6]CCN\ C\nCLASS\ \ \ \ 26\ H\nCLASS\ \ \ \ \ 2\ H(CCCH)\ HC\nCLASS\ \ \ \ \ 2\ H(CCCHN)\ HC\nCLASS\ \ \ \ \ 6\ H(CCH3)\ HC\nCLASS\ \ \ \ 13\ H(C[6]CCH)\ HC\nCLASS\ \ \ \ \ 2\ H(NCCH)\ HN\nCLASS\ \ \ \ \ 1\ H(OCH)\ HO\nCLASS\ \ \ \ 23\ HC\ H\nCLASS\ \ \ \ \ 2\ HN\ H\nCLASS\ \ \ \ \ 1\ HO\ H\nCLASS\ \ \ \ \ 4\ N\nCLASS\ \ \ \ \ 2\ N(CCCHN)(CNNS)(HN)\ NCCH\nCLASS\ \ \ \ \ 2\ N(C[6]CCN)(ON)2\ NCOO\nCLASS\ \ \ \ \ 2\ NCCH\ N\nCLASS\ \ \ \ \ 2\ NCOO\ N\nCLASS\ \ \ \ \ 6\ O\nCLASS\ \ \ \ \ 1\ O(CCOO)\ OC\nCLASS\ \ \ \ \ 1\ O(CCOO)(HO)\ OCH\nCLASS\ \ \ \ \ 4\ O(NCOO)\ ON\nCLASS\ \ \ \ \ 1\ OC\ O\nCLASS\ \ \ \ \ 1\ OCH\ O\nCLASS\ \ \ \ \ 4\ ON\ O\nCLASS\ \ \ \ \ 1\ S\nCLASS\ \ \ \ \ 1\ S(CNNS)\ SC\nCLASS\ \ \ \ \ 1\ SC\ S\nOBSBOND\ \ 1.477027\ C(CCCH)(OCH)(OC)\ C(CCCH)(CCOO)(HC)\ C8\ C9\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 1.330299\ C(C[6]C3)(CCCH)(HC)\ C(CCCH)(CCOO)(HC)\ C7\ C8\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 1.526954\ C(C[6]C3)(CCH3)(NCCH)(HC)\ C(CCCHN)(HC)3\ C2A\ C3A\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.506108\ C(C[6]C3)(CCH3)(NCCH)(HC)\ C(CCCHN)(HC)3\ C2B\ C3B\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.472368\ C[6](C[6]CCH)(C[6]CCN)(CCCH)\ C(C[6]C3)(CCCH)(HC)\ C1\ C7\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 1.408714\ C[6](C[6]CCH)(C[6]CCN)(CCCH)\ C[6](C[6]CCH)(C[6]C3)(HC)\ C1\ C6\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 1.404715\ C[6](C[6]CCH)(C[6]CCN)(CCCH)\ C[6](C[6]CCH)(C[6]C3)(NCOO)\ C1\ C2\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 1.385633\ C[6](C[6]CCH)(C[6]CCN)(HC)\ C[6](C[6]CCH)(C[6]C3)(HC)\ C5\ C6\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 1.519610\ C[6](C[6]CCH)2(CCCHN)\ C(C[6]C3)(CCH3)(NCCH)(HC)\ C2A\ C4A\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.520736\ C[6](C[6]CCH)2(CCCHN)\ C(C[6]C3)(CCH3)(NCCH)(HC)\ C2B\ C4B\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.361444\ C[6](C[6]CCH)2(CCCHN)\ C[6](C[6]CCH)(C[6]C3)(HC)\ C4A\ C5A\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.374119\ C[6](C[6]CCH)2(CCCHN)\ C[6](C[6]CCH)(C[6]C3)(HC)\ C4A\ C9A\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.381215\ C[6](C[6]CCH)2(CCCHN)\ C[6](C[6]CCH)(C[6]C3)(HC)\ C4B\ C5B\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.370684\ C[6](C[6]CCH)2(CCCHN)\ C[6](C[6]CCH)(C[6]C3)(HC)\ C4B\ C9B\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.386372\ C[6](C[6]CCH)2(HC)\ C[6](C[6]CCH)(C[6]C3)(HC)\ C5A\ C6A\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.371980\ C[6](C[6]CCH)2(HC)\ C[6](C[6]CCH)(C[6]C3)(HC)\ C5B\ C6B\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.371855\ C[6](C[6]CCH)2(HC)\ C[6](C[6]CCH)(C[6]C3)(HC)\ C8A\ C9A\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.374489\ C[6](C[6]CCH)2(HC)\ C[6](C[6]CCH)(C[6]C3)(HC)\ C8B\ C9B\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.354583\ C[6](C[6]CCH)2(HC)\ C[6](C[6]CCH)2(HC)\ C6A\ C7A\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.358005\ C[6](C[6]CCH)2(HC)\ C[6](C[6]CCH)2(HC)\ C6B\ C7B\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.379711\ C[6](C[6]CCH)2(HC)\ C[6](C[6]CCH)2(HC)\ C7A\ C8A\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.352389\ C[6](C[6]CCH)2(HC)\ C[6](C[6]CCH)2(HC)\ C7B\ C8B\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.388732\ C[6](C[6]CCH)2(NCOO)\ C[6](C[6]CCH)(C[6]CCN)(HC)\ C4\ C5\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 1.383281\ C[6](C[6]CCN)2(HC)\ C[6](C[6]CCH)(C[6]C3)(NCOO)\ C2\ C3\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 1.380685\ C[6](C[6]CCN)2(HC)\ C[6](C[6]CCH)2(NCOO)\ C3\ C4\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 0.960775\ H(CCCH)\ C(CCCH)(CCOO)(HC)\ C8\ H8\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 0.916345\ H(CCCH)\ C(C[6]C3)(CCCH)(HC)\ C7\ H7\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 0.979311\ H(CCCHN)\ C(C[6]C3)(CCH3)(NCCH)(HC)\ C2A\ H2A\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.979176\ H(CCCHN)\ C(C[6]C3)(CCH3)(NCCH)(HC)\ C2B\ H2B\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.960382\ H(CCH3)\ C(CCCHN)(HC)3\ C3A\ H3A1\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.959851\ H(CCH3)\ C(CCCHN)(HC)3\ C3A\ H3A2\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.959813\ H(CCH3)\ C(CCCHN)(HC)3\ C3A\ H3A3\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.959227\ H(CCH3)\ C(CCCHN)(HC)3\ C3B\ H3B1\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.959844\ H(CCH3)\ C(CCCHN)(HC)3\ C3B\ H3B2\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.959979\ H(CCH3)\ C(CCCHN)(HC)3\ C3B\ H3B3\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.976085\ H(C[6]CCH)\ C[6](C[6]CCH)(C[6]C3)(HC)\ C6\ H6\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 0.930450\ H(C[6]CCH)\ C[6](C[6]CCH)(C[6]C3)(HC)\ C5A\ H5A\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.930431\ H(C[6]CCH)\ C[6](C[6]CCH)(C[6]C3)(HC)\ C5B\ H5B\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.930918\ H(C[6]CCH)\ C[6](C[6]CCH)(C[6]C3)(HC)\ C9A\ H9A\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.931268\ H(C[6]CCH)\ C[6](C[6]CCH)(C[6]C3)(HC)\ C9B\ H9B\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.963558\ H(C[6]CCH)\ C[6](C[6]CCH)(C[6]CCN)(HC)\ C5\ H5\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 0.930180\ H(C[6]CCH)\ C[6](C[6]CCH)2(HC)\ C6A\ H6A\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.930079\ H(C[6]CCH)\ C[6](C[6]CCH)2(HC)\ C6B\ H6B\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.929723\ H(C[6]CCH)\ C[6](C[6]CCH)2(HC)\ C7A\ H7A\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.930365\ H(C[6]CCH)\ C[6](C[6]CCH)2(HC)\ C7B\ H7B\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.929747\ H(C[6]CCH)\ C[6](C[6]CCH)2(HC)\ C8A\ H8A\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.930140\ H(C[6]CCH)\ C[6](C[6]CCH)2(HC)\ C8B\ H8B\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.941765\ H(C[6]CCH)\ C[6](C[6]CCN)2(HC)\ C3\ H3\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 1.444613\ N(CCCHN)(CNNS)(HN)\ C(C[6]C3)(CCH3)(NCCH)(HC)\ C2A\ N1A\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.446310\ N(CCCHN)(CNNS)(HN)\ C(C[6]C3)(CCH3)(NCCH)(HC)\ C2B\ N1B\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.317686\ N(CCCHN)(CNNS)(HN)\ C(NCCH)2(SC)\ C\ N1A\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.324328\ N(CCCHN)(CNNS)(HN)\ C(NCCH)2(SC)\ C\ N1B\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.889915\ N(CCCHN)(CNNS)(HN)\ H(NCCH)\ H1A\ N1A\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 0.888351\ N(CCCHN)(CNNS)(HN)\ H(NCCH)\ H1B\ N1B\ 2005934_mols.cif\ 2005934_molecule_0\nOBSBOND\ \ 1.477195\ N(C[6]CCN)(ON)2\ C[6](C[6]CCH)(C[6]C3)(NCOO)\ C2\ N1\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 1.472404\ N(C[6]CCN)(ON)2\ C[6](C[6]CCH)2(NCOO)\ C4\ N2\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 1.227043\ O(CCOO)\ C(CCCH)(OCH)(OC)\ C9\ O2\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 1.322195\ O(CCOO)(HO)\ C(CCCH)(OCH)(OC)\ C9\ O1\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 0.871168\ O(CCOO)(HO)\ H(OCH)\ H9\ O1\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 1.231894\ O(NCOO)\ N(C[6]CCN)(ON)2\ N1\ O3\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 1.228953\ O(NCOO)\ N(C[6]CCN)(ON)2\ N1\ O4\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 1.232481\ O(NCOO)\ N(C[6]CCN)(ON)2\ N2\ O5\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 1.233546\ O(NCOO)\ N(C[6]CCN)(ON)2\ N2\ O6\ 2005910_mols.cif\ 2005910_molecule_0\nOBSBOND\ \ 1.710209\ S(CNNS)\ C(NCCH)2(SC)\ C\ S\ 2005934_mols.cif\ 2005934_molecule_0\n
END
END_SCRIPT
