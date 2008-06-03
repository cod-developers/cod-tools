from libtbx import test_utils
import libtbx.load_env

def run():
  tst_list = (
  "$B/../exe_dev/cctbx.getting_started",
  "$B/../exe_dev/cctbx.sym_equiv_sites",
  "$D/cctbx/examples/getting_started.py",
  ["$D/cctbx/examples/space_group_matrices.py", "P31"],
  "$D/cctbx/examples/quartz_structure.py",
  "$D/cctbx/examples/analyze_adp.py",
  "$D/cctbx/examples/g_exp_i_partial_derivatives.py",
  "$D/cctbx/examples/tst_exp_i_alpha_derivatives.py",
  "$D/cctbx/examples/tst_g_exp_i_alpha_derivatives.py",
  "$D/cctbx/examples/tst_structure_factor_derivatives.py",
  "$D/cctbx/examples/tst_structure_factor_derivatives_2.py",
  ["$D/cctbx/examples/tst_structure_factor_derivatives_3.py", "P31"],
  ["$D/cctbx/examples/tst_structure_factor_derivatives_4.py", "--tag=internal"],
  "$D/cctbx/examples/structure_factor_calculus/site_derivatives.py",
  "$D/cctbx/examples/structure_factor_calculus/u_star_derivatives.py",
  "$D/cctbx/examples/structure_factor_calculus/sites_derivatives.py",
  "$D/cctbx/examples/structure_factor_calculus/sites_least_squares_derivatives.py",
  ["$D/cctbx/examples/all_axes.py", "P31"],
  ["$D/cctbx/examples/tst_phase_o_phrenia.py", "P2"],
  "$D/cctbx/examples/map_skewness.py",
  "$D/cctbx/examples/site_symmetry_table.py",
  "$D/cctbx/examples/site_symmetry_constraints.py",
  "$D/cctbx/examples/adp_symmetry_constraints.py",
  "$D/cctbx/examples/unit_cell_refinement.py",
  "$D/cctbx/examples/miller_common_sets.py",
  "$D/cctbx/examples/change_hand_p31.py",
  "$D/cctbx/examples/steve_collins.py",
  "$D/cctbx/examples/cr2o3_primitive_cell.py",
  "$D/cctbx/examples/cr2o3_consistency_checks.py",
  "$D/cctbx/examples/reduced_cell_two_folds.py",
  "$D/cctbx/examples/lebedev_2005_perturbation.py",
  "$D/cctbx/examples/le_page_1982_vs_lebedev_2005.py",
  )

  build_dir = libtbx.env.under_build("cctbx")
  dist_dir = libtbx.env.dist_path("cctbx")

  test_utils.run_tests(build_dir, dist_dir, tst_list)

if (__name__ == "__main__"):
  run()
