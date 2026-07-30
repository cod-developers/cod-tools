#!/bin/sh

# Dependencies listed in this file are used in the development of
# the 'cod-tools' package. Although these dependencies are needed
# to run certain Make rules (e.g. 'make cover'), they are not
# strictly required to build the package or run the tests:

sudo dnf install -y \
    gcovr \
    lcov \
    perl-Devel-Cover \
;
