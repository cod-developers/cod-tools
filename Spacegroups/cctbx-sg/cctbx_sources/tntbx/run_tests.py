from libtbx import test_utils
import libtbx.load_env

def run():
  tst_list = (
  "$D/tst_tntbx_ext.py",
  "$D/tst_large_eigen.py",
  )

  build_dir = libtbx.env.under_build("tntbx")
  dist_dir = libtbx.env.dist_path("tntbx")

  test_utils.run_tests(build_dir, dist_dir, tst_list)

if (__name__ == "__main__"):
  run()
