#!/bin/sh

sudo yum install -y \
    perl-Digest-SHA \
    perl-Clone \
    perl-DBD-MySQL \
    perl-DBD-SQLite \
    perl-JSON \
    perl-List-MoreUtils \
    perl-WWW-Curl \
    perl-XML-Simple
sudo yum install --enablerepo=epel -y \
    openbabel \
    perl-DateTime-Format-RFC3339 \
    perl-Capture-Tiny \
    perl-Carp-Assert \
    perl-openbabel
