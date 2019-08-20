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
from pycodcif import parse, CifParserException

filename = sys.argv.pop()

try:
    parse( "sąžininga žąsis" )
except CifParserException as e:
    pass

try:
    parse( u"sąžininga žąsis" )
except CifParserException as e:
    pass
