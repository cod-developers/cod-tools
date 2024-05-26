#!/bin/sh
##
# Tests the way the -I (--add-dictionary-import-path) option are handled.
##

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/ddlm_validate
INPUT_CIF=tests/inputs/ddlm_validate/cif/cif2_multi_dir_import_dic.cif
INPUT_DIC=tests/inputs/ddlm_validate/dic/import_directory/ddlm_multi_dir_import.dic
#END DEPEND--------------------------------------------------------------------

PATH_DIR_1=./tests/inputs/ddlm_validate/dic/import_directory/import_subdirectory_1
PATH_DIR_2=./tests/inputs/ddlm_validate/dic/import_directory/import_subdirectory_2

COD_TOOLS_DDLM_IMPORT_PATH=""
export COD_TOOLS_DDLM_IMPORT_PATH

"${INPUT_SCRIPT}" -d "${INPUT_DIC}" \
                  -I "${PATH_DIR_1}" \
                  -I "${PATH_DIR_2}" \
                  "${INPUT_CIF}"
