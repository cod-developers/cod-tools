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
sudo cpan Capture::Tiny
sudo cpan Carp::Assert
