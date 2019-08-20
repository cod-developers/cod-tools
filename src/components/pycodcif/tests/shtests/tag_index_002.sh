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
from pycodcif import CifFile, CifDatablock

datablock = CifDatablock("new")
datablock['_tag'] = 10

print datablock['_tag']

cif = CifFile()
cif.append( datablock )
print cif

print cif['new']['_tag']
print cif[0]['_tag']
print cif[0].keys()
