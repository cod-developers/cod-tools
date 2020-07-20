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
from pycodcif import new_cif, cif_start_datablock, datablock_insert_cifvalue, cif_datablock_list, cif_print

cif = new_cif( None )
cif_start_datablock( cif, "first", None )

datablock_insert_cifvalue( cif_datablock_list( cif ), "_number",  12.3456789, None )
datablock_insert_cifvalue( cif_datablock_list( cif ), "_string",  "Someone Else", None )
datablock_insert_cifvalue( cif_datablock_list( cif ), "_unknown", None, None )

cif_print( cif )
