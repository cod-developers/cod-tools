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
from pycodcif import new_cif_from_cif_file, datablock_tag_index, cif_option_default, cif_datablock_list

cif = new_cif_from_cif_file( "tests/inputs/1YGG.cif", cif_option_default(), None )
datablock = cif_datablock_list( cif )
print datablock_tag_index( datablock, "_audit_author.name" )
print datablock_tag_index( datablock, "_this_tag_does_not_exist" )
