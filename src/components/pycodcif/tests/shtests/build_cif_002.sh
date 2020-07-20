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
from pycodcif import CifFile, CifDatablock, CifUnknownValue, CifInapplicableValue

datablock = CifDatablock("new")

datablock.add_loop( [ '_a', '_b' ], [[1, 2], [3, 4]] )
datablock.add_loop( [ '_c', '_d', '_e' ], [[1, 2, 3], [3, 4, 4], ['c', 'd', 'e']] )

cif = CifFile()
cif.append( datablock )
print( cif )

# This should cause an error
try:
    datablock.add_loop( [ '_a', '_f' ], [[ 1, 1 ]] )
except KeyError as e:
    print( e )

datablock['_overwritten'] = 'first'
print( cif )

datablock['_overwritten'] = 'second'
print( cif )

datablock['_simple_loop'] = [ 10, 12, 13 ]
datablock['_unknown']      = CifUnknownValue()
datablock['_inapplicable'] = CifInapplicableValue()
print( cif )
