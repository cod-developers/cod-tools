import libtbx.load_env
import sys, os

Import("env_base","env_etc")

env_etc.ccp4io_dist = libtbx.env.dist_path("ccp4io")
env_etc.ccp4io_include = libtbx.env.under_dist("ccp4io", "lib/src")

if (sys.platform == "win32"):
  env_etc.ccp4io_defines = ["-Di386"]
else:
  env_etc.ccp4io_defines = []

ccflags = env_etc.ccflags_base[:]
ccflags.extend(env_etc.ccp4io_defines)

env = env_base.Copy(
  CCFLAGS=ccflags,
  SHCCFLAGS=ccflags,
  SHLINKFLAGS=env_etc.shlinkflags,
)
env.Append(LIBS=env_etc.libm)
if (env_etc.static_libraries): builder = env.StaticLibrary
else:                          builder = env.SharedLibrary
if (   os.path.normcase(os.path.dirname(env_etc.ccp4io_dist))
    != os.path.normcase("ccp4io")):
  env.Repository(os.path.dirname(env_etc.ccp4io_dist))
prefix = "#"+os.path.join(os.path.basename(env_etc.ccp4io_dist), "lib", "src")
builder(target='#lib/cmtz',
  source = [os.path.join(prefix,file_name) for file_name in [
    "library_err.c",
    "library_file.c",
    "library_utils.c",
    "ccp4_array.c",
    "ccp4_parser.c",
    "ccp4_unitcell.c",
    "cvecmat.c",
    "cmtzlib.c",
    "csymlib.c",
  ]])
