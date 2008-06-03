from libtbx.utils import Sorry, show_times_at_exit
from libtbx.str_utils import show_string
import libtbx.load_env
import time
import sys, os

def find_scons_engine_path():
  join = os.path.join
  isdir = os.path.isdir
  if (libtbx.env.scons_dist_path is not None):
    result = join(libtbx.env.scons_dist_path, "engine")
    if (isdir(result)): return result
    result = join(libtbx.env.scons_dist_path, "src", "engine")
    if (isdir(result)): return result
  for path in libtbx.env.repository_paths:
    result = join(path, "scons", "engine")
    if (isdir(result)): return result
    result = join(path, "scons", "src", "engine")
    if (isdir(result)): return result
  return None

def run():
  engine_path = find_scons_engine_path()
  if (engine_path is not None):
    sys.path.insert(0, engine_path)
    try: import SCons
    except ImportError: del sys.path[0]
  try: import SCons.Script
  except ImportError:
    msg = ["SCons is not available.",
      "  A possible solution is to unpack a SCons distribution in",
      "  one of these directories:"]
    for path in libtbx.env.repository_paths:
      msg.append("    " + show_string(path))
    msg.extend([
      "  SCons distributions are available at this location:",
      "    http://www.scons.org/",
      "  It may be necessary to rename the unpacked distribution, e.g.:",
      "    mv scons-0.96.1 scons"])
    raise Sorry("\n".join(msg))
  show_times_at_exit()
  SCons.Script.main()

if (__name__ == "__main__"):
  run()
