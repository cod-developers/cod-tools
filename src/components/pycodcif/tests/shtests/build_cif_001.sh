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
from pycodcif import new_cif, cif_start_datablock, new_value_from_scalar, datablock_insert_cifvalue, cif_option_default, cif_datablock_list, cif_print

cif = new_cif( None )
cif_start_datablock( cif, "first", None )

number = new_value_from_scalar( "12.3456789", "CIF_FLOAT", None )
string = new_value_from_scalar( "Someone Else", "CIF_SQSTRING", None )
datablock_insert_cifvalue( cif_datablock_list( cif ), "_number", number, None )
datablock_insert_cifvalue( cif_datablock_list( cif ), "_string", string, None )

cif_print( cif )
