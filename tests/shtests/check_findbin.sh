#!/bin/sh

# This Shell test checks whether the scrips can find their own
# libraries even when PERL5LIB does not include the cod-tools modules
# in the path.

# As a first attempt, I just unset the PERL5LIB and see if the
# --vesion works. If, in the future, the '--version' function wil
# require some Perl modules from the original PERL5LIB path, we wil
# have to do more complex editing of the PERL5LIB value to remove the
# cod-tools module paths:

unset PERL5LIB

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPTS=$(find scripts -maxdepth 1 -name \*~ -prune -o -type f -a -executable -print | LC_ALL=C sort | xargs echo)
#END DEPEND--------------------------------------------------------------------

for i in ${INPUT_SCRIPTS}
do
    $i --version
done \
| uniq
