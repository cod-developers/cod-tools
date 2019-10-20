#*
# Source this file into your current shell to set up PERL5LIB so that
# librarries in this repository are found first:
#
# USAGE:
#     source $0
#**

PERL5LIB=$(pwd)/src/lib/perl5${PERL5LIB:+:${PERL5LIB}}
