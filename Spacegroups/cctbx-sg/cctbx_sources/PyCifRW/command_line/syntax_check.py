from PyCifRW.CifFile import CifFile
from libtbx.str_utils import show_string
import sys

def run():
  for arg in sys.argv[1:]:
    print "Parsing file: %s" % show_string(arg)
    CifFile(arg)
    print

if (__name__ == "__main__"):
  run()
