#!/bin/sh
##
# Tests the way the order of values in the -I (--add-dictionary-import-path)
# command line option and the COD_TOOLS_DDLM_PATH environment variable
# interact. The command line option should be treated as having a higher
# priority. As a result, no validation issues regarding the
# _ddlm_sub_dic_a_category.item data item should be output. 
##

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/ddlm_validate
INPUT_CIF=tests/inputs/ddlm_validate/cif/cif2_multi_dir_import_dic.cif
INPUT_DIC=tests/inputs/ddlm_validate/dic/import_directory/ddlm_multi_dir_import.dic
#END DEPEND--------------------------------------------------------------------

PATH_DIR_1=./tests/inputs/ddlm_validate/dic/import_directory/import_subdirectory_1
PATH_DIR_2=./tests/inputs/ddlm_validate/dic/import_directory/import_subdirectory_2

COD_TOOLS_DDLM_IMPORT_PATH=${PATH_DIR_1}:${PATH_DIR_2}
export COD_TOOLS_DDLM_IMPORT_PATH

"${INPUT_SCRIPT}" -d "${INPUT_DIC}" \
                  -I "${PATH_DIR_2}" \
                  "${INPUT_CIF}" 
