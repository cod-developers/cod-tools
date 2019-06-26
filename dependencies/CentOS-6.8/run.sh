#!/bin/sh

sudo yum install -y \
    perl-Digest-SHA \
    perl-Clone \
    perl-DBD-MySQL \
    perl-DBD-SQLite \
    perl-JSON \
    perl-List-MoreUtils \
    perl-Text-Unidecode \
    perl-WWW-Curl \
    perl-XML-Simple
sudo yum install --enablerepo=epel -y \
    openbabel \
    perl-Data-Compare \
    perl-Date-Calc \
    perl-DateTime-Format-RFC3339 \
    perl-Capture-Tiny \
    perl-Carp-Assert \
    perl-openbabel
