#!/bin/sh

sudo dnf install -y \
    openbabel \
    perl-Clone \
    perl-Data-Compare \
    perl-Date-Calc \
    perl-DateTime-Format-RFC3339 \
    perl-DBD-MySQL \
    perl-DBD-SQLite \
    perl-Digest-SHA \
    perl-fields \
    perl-Graph \
    perl-HTML-Parser \
    perl-JSON \
    perl-List-MoreUtils \
    perl-Math-BigRat \
    perl-open \
    perl-Text-Unidecode \
    perl-Unicode-Normalize \
    perl-WWW-Curl \
    perl-XML-Simple \
;

# The 'perl-Math-GMP' package is not explicitly required,
# but it greatly improves the speed of BigRat arithmetics
sudo dnf install -y \
    perl-Math-GMP \
;
