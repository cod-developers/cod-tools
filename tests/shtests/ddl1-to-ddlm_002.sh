#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/ddl1-to-ddlm
INPUT_DIC=tests/inputs/ddl1-to-ddlm/replace.dic
#END DEPEND--------------------------------------------------------------------

##
# Tests the way the '_alias.deprecation_date' attribute value is assigned.
##

CURRENT_DATE=$(date +%F --utc)
${INPUT_SCRIPT} ${INPUT_DIC} | perl -lpe "s/${CURRENT_DATE}\$/YYYY-MM-DD/"
