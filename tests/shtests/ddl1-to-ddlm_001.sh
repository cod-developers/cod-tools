#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/ddl1-to-ddlm
INPUT_DIC=tests/inputs/cif_cod.dic
#END DEPEND--------------------------------------------------------------------

${INPUT_SCRIPT} ${INPUT_DIC} | perl -lpe 's/\d{4}-\d{2}-\d{2}$/YYYY-MM-DD/'
