#!/bin/sh

sudo dnf install -y \
    openbabel \
    perl-Carp-Assert \
    perl-Clone \
    perl-Data-Compare \
    perl-Date-Calc \
    perl-DateTime-Format-RFC3339 \
    perl-DBD-MySQL \
    perl-DBD-SQLite \
    perl-Digest-SHA \
    perl-Graph \
    perl-HTML-Parser \
    perl-JSON \
    perl-List-MoreUtils \
    perl-Math-BigRat \
    perl-Math-GMP \
    perl-open \
    perl-Text-Unidecode \
    perl-WWW-Curl \
    perl-XML-Simple \
;

# The 'perl-Math-GMP' package is not explicitly required,
# but it greatly improves the speed of BigRat arithmetics
