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
    libmath-bigint-perl \
    libparse-yapp-perl \
    libtext-unidecode-perl \
    libwww-curl-perl \
    libxml-simple-perl \
    openbabel \
    perl \
;

# The 'libmath-bigint-gmp-perl' package is not mandatory,
# but it greatly improves the speed of BigRat arithmetics.
sudo apt-get install -y \
    libmath-bigint-gmp-perl \
;
