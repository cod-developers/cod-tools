#!/bin/sh

sudo apt-get install -y \
    curl \
    gawk \
    libcarp-assert-perl \
    libclone-perl \
    libdata-compare-perl \
    libdate-calc-perl \
    libdatetime-format-rfc3339-perl \
    libdbd-mysql-perl \
    libdbd-sqlite3-perl \
    libdbi-perl \
    libdigest-sha-perl \
    libgraph-perl \
    libhtml-parser-perl \
    libjson-perl \
    liblist-moreutils-perl \
    libparse-yapp-perl \
    libtext-unidecode-perl \
    libwww-curl-perl \
    libxml-simple-perl \
    openbabel \
    perl \
    python-argparse \
    libmath-bigint-gmp-perl \
;

# The 'libmath-bigint-gmp-perl' package greatly improves the speed of
# BigRat arithmetics.
