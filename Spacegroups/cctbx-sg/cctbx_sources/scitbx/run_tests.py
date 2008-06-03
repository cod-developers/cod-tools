from libtbx import test_utils
import libtbx.load_env

def run():
  tst_list = (
  "$B/array_family/tst_af_1",
  "$B/array_family/tst_af_2",
  "$B/array_family/tst_af_3",
  "$B/array_family/tst_af_4",
  "$B/array_family/tst_af_5",
  "$B/array_family/tst_vec3",
  "$B/array_family/tst_unsigned_float_arithmetic",
  "$B/array_family/tst_mat3",
  "$B/array_family/tst_sym_mat3",
  "$B/array_family/tst_mat_ref",
  "$B/array_family/tst_accessors",
  "$B/serialization/tst_base_256",
  "$D/error/tst_error.py",
  "$D/include/scitbx/stl/tst_map.py",
  "$D/include/scitbx/stl/tst_set.py",
  "$D/include/scitbx/stl/tst_vector.py",
  "$D/array_family/boost_python/regression_test.py",
  "$D/array_family/boost_python/tst_flex.py",
  "$D/array_family/boost_python/tst_smart_selection.py",
  "$D/array_family/boost_python/tst_shared.py",
  "$D/array_family/boost_python/tst_integer_offsets_vs_pointers.py",
  "$D/scitbx/matrix.py",
  "$D/scitbx/python_utils/tst_random_transform.py",
  "$D/scitbx/python_utils/tst_graph.py",
  "$D/math/boost_python/tst_math.py",
  "$D/math/boost_python/tst_r3_rotation.py",
  "$D/math/boost_python/tst_resample.py",
  "$D/math/boost_python/tst_line_search.py",
  "$D/math/boost_python/tst_gaussian.py",
  "$D/math/boost_python/tst_quadrature.py",
  "$D/math/boost_python/tst_halton.py",
  "$D/scitbx/math/tst_euler_angles.py",
  "$D/scitbx/math/tst_superpose.py",
  "$D/scitbx/math/sieve_of_eratosthenes.py",
  "$D/include/scitbx/minpack/tst.py",
  ["$D/lbfgs/boost_python/tst_lbfgs.py"],
  "$D/lbfgsb/boost_python/tst_lbfgsb.py",
  ["$D/fftpack/boost_python/tst_fftpack.py"],
  "$D/scitbx/examples/flex_array_loops.py",
  "$D/scitbx/examples/principal_axes_of_inertia.py",
  "$D/scitbx/examples/lbfgs_recipe.py",
  "$D/scitbx/examples/lbfgs_linear_least_squares_fit.py",
  "$D/scitbx/examples/chebyshev_lsq_example.py",
  "$D/scitbx/examples/immoptibox_ports.py",
  "$D/scitbx/graph/rigidity.py",
  "$D/scitbx/graph/tst_rigidity.py",
  "$D/scitbx/sparse/tests/tst_sparse.py",
  "$D/scitbx/iso_surface/tst_iso_surface.py",
  )

  build_dir = libtbx.env.under_build("scitbx")
  dist_dir = libtbx.env.dist_path("scitbx")

  test_utils.run_tests(build_dir, dist_dir, tst_list)

if (__name__ == "__main__"):
  run()
