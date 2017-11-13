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
from pycodcif import CifFile, CifDatablock

datablock = CifDatablock("new")

datablock.add_loop( [ '_a', '_b' ], [[1, 2], [3, 4]] )
datablock.add_loop( [ '_c', '_d', '_e' ], [[1, 2, 3], [3, 4, 4], ['c', 'd', 'e']] )

cif = CifFile()
cif.append( datablock )
print cif

# This should cause an error
datablock.add_loop( [ '_a', '_f' ], [[ 1, 1 ]] )
print cif
