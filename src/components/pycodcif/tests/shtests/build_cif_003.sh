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
from pycodcif import CifFile

cif = CifFile( file = "tests/inputs/1YGG.cif" )
print( cif )
print( cif.keys() )
