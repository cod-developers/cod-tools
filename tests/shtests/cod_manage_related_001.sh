#!/bin/sh
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Tests the way the 'cod_manage_related' script handles reading from STDIN.
#**

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cod_manage_related
INPUT_CIF=tests/inputs/related_empty_entry.cif
#END DEPEND--------------------------------------------------------------------

set -ue

PATH=.:${PATH}

cat ${INPUT_CIF} | ${INPUT_SCRIPT} \
--related-entry-database    "COD on a ROD" \
--related-entry-code        "F15H" \
--related-entry-description "It might struggle!" \
--related-entry-uri         "http://www.fishonastick.com"
