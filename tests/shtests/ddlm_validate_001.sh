#!/bin/bash
##
# Tests the way dictionary files that contain imports statements from
# dictionaries that do not appear in the default search path are handled.
# Warning messages about inability to locate these dictionaries should be
# issued and the data items that should have been imported should be reported
# as unrecognised. 
##

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=scripts/ddlm_validate
INPUT_CIF=tests/inputs/ddlm_validate/cif/cif2_multi_dir_import_dic.cif
INPUT_DIC=tests/inputs/ddlm_validate/dic/import_directory/ddlm_multi_dir_import.dic

#END DEPEND--------------------------------------------------------------------

COD_TOOLS_DDLM_PATH=""
export COD_TOOLS_DDLM_PATH

${INPUT_SCRIPT} -d ${INPUT_DIC} ${INPUT_CIF}
