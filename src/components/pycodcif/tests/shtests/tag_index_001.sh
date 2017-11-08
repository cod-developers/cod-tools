#!/usr/bin/python
# -*- coding: utf-8 -*-
#------------------------------------------------------------------------------
#$Author$
#$Revision$
#$URL$
#$Date$
#$Id$
#------------------------------------------------------------------------------
#*
#  Test driver for pycodcif module.
#**
import sys
from pycodcif import new_cif_from_cif_file, new_value_from_scalar, datablock_tag_index, datablock_overwrite_cifvalue, cif_option_default, cif_datablock_list, value_dump, datablock_cifvalue

cif = new_cif_from_cif_file( "tests/inputs/1YGG.cif", cif_option_default(), None )
datablock = cif_datablock_list( cif )
print datablock_tag_index( datablock, "_audit_author.name" )
print datablock_tag_index( datablock, "_this_tag_does_not_exist" )

# Overwrites an existing value in the datablock
cifvalue = new_value_from_scalar( "Someone Else", "CIF_UQSTRING", None )
datablock_overwrite_cifvalue( datablock, 22, 0, cifvalue, None )

# Checks whether the value is correctly overwritten
cifvalue = datablock_cifvalue( datablock, 22, 0 )
value_dump( cifvalue )
print ""
