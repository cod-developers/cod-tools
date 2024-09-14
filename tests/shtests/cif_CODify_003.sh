#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif_CODify
INPUT_CIF=""
#END DEPEND--------------------------------------------------------------------

#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#**
#* Tests the way the 'cif_CODify' script behaves when the input CIF file
#* is not provided.
#**

set -ue

PATH=.:${PATH}

${INPUT_SCRIPT} "${INPUT_CIF}"
