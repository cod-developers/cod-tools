#!/bin/sh

sudo apt-get install -y \
    curl \
    gawk \
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
    libpython2.7-stdlib \
    libtext-unidecode-perl \
    libwww-curl-perl \
    libxml-simple-perl \
    openbabel \
    perl \
    libmath-bigint-gmp-perl \
;

# The 'libmath-bigint-gmp-perl' package greatly improves the speed of
# BigRat arithmetics.
