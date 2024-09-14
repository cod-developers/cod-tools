#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/ddl1-to-ddlm
INPUT_DIC=tests/inputs/cif_cod.dic
#END DEPEND--------------------------------------------------------------------

CURRENT_DATE=$(date +%F --utc)
${INPUT_SCRIPT} ${INPUT_DIC} | perl -lpe "s/${CURRENT_DATE}\$/YYYY-MM-DD/"
