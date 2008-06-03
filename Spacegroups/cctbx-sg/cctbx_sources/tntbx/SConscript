import libtbx.load_env
Import("env_etc")

env_etc.tntbx_dist = libtbx.env.dist_path("tntbx")
env_etc.tntbx_include = env_etc.tntbx_dist
env_etc.tntbx_tnt_include = libtbx.env.under_dist("tntbx", "include")

env_etc.tntbx_common_includes = [
  env_etc.libtbx_include,
  env_etc.tntbx_include,
  env_etc.tntbx_tnt_include,
  env_etc.scitbx_include,
  env_etc.boost_include,
]

Import("env_base", "env_etc")
env = env_base.Copy(
  CXXFLAGS=env_etc.cxxflags_base,
  LIBS=env_etc.libm,
  LIBPATH=["#lib"]
)
env_etc.include_registry.append(
  env=env,
  paths=env_etc.tntbx_common_includes)

if (not env_etc.no_boost_python):
  Import("env_scitbx_boost_python_ext")
  env_bpl = env_scitbx_boost_python_ext.Copy()
  env_etc.include_registry.append(
    env=env_bpl,
    paths=env_etc.tntbx_common_includes)
  env_bpl.SharedLibrary(
    target="#lib/tntbx_eigensystem_ext",
    source=["tntbx/eigensystem_ext.cpp"])
  env_bpl.SharedLibrary(
    target="#lib/tntbx_ext",
    source=["tntbx/ext.cpp"])
