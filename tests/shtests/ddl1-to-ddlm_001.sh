#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=tools/ddl1-to-ddlm
INPUT_DIC=tests/inputs/cif_cod.dic
#END DEPEND--------------------------------------------------------------------

${INPUT_SCRIPT} --keep-original-date ${INPUT_DIC}
