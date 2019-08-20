#!/usr/bin/python3
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
from pycodcif import new_cif_from_cif_file, new_value_from_scalar, datablock_tag_index, datablock_overwrite_cifvalue, datablock_insert_cifvalue, cif_option_default, cif_datablock_list, value_dump, datablock_cifvalue

cif = new_cif_from_cif_file( "tests/inputs/1YGG.cif", cif_option_default(), None )
datablock = cif_datablock_list( cif )
print datablock_tag_index( datablock, "_audit_author.name" )
print datablock_tag_index( datablock, "_this_tag_does_not_exist" )

datablock_insert_cifvalue( datablock, "_this_tag_does_not_exist", 12345, None )

# Checks whether the value is correctly inserted
tag_id = datablock_tag_index( datablock, "_this_tag_does_not_exist" )
cifvalue = datablock_cifvalue( datablock, tag_id, 0 )
value_dump( cifvalue )
print ""

# Overwrites an existing value in the datablock
datablock_overwrite_cifvalue( datablock, 22, 0, "Someone Else", None )

# Checks whether the value is correctly overwritten
cifvalue = datablock_cifvalue( datablock, 22, 0 )
value_dump( cifvalue )
print ""
