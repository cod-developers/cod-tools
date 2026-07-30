#!/bin/sh

# This Shell test checks whether the scripts can find their own
# libraries even when PERL5LIB does not include the cod-tools modules
# in the path.

# As a first attempt, I just unset the PERL5LIB and see if the
# --version works. If, in the future, the '--version' function will
# require some Perl modules from the original PERL5LIB path, we will
# have to do more complex editing of the PERL5LIB value to remove the
# cod-tools module paths:

unset PERL5LIB

# On Ubuntu 22.04, the PERL5LIB variable should be further modified to
# circumvent a bug in the libmath-bigint-gmp-perl software package:
if grep -q 'Ubuntu' /etc/os-release && grep -q 'VERSION_ID="22.04' /etc/os-release;
then
    export PERL5LIB=/usr/share/perl/5.34
fi

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPTS=$(find scripts -maxdepth 1 -name \*~ -prune -o -type f -a -executable -print | LC_ALL=C sort | xargs echo)
#END DEPEND--------------------------------------------------------------------

for i in ${INPUT_SCRIPTS}
do
    $i --version
done \
| uniq
