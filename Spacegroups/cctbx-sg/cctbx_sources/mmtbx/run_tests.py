from libtbx import test_utils
import libtbx.load_env

def run():
  tst_list = (
  "$D/mmtbx/chemical_components/tst.py",
  "$D/mmtbx/regression/tst_add_h_to_water.py",
  "$D/mmtbx/rotamer/rotamer_eval.py",
  "$D/mmtbx/tst_validate_utils.py",
  "$D/mmtbx/wwpdb/tst_standard_geometry_cif.py",
  "$D/mmtbx/tst_pdbtools.py",
  "$D/mmtbx/real_space/tst.py",
  "$D/mmtbx/ias/tst_ias.py",
  ["$D/mmtbx/refinement/tst_anomalous_scatterer_groups.py", "P3"],
  "$D/mmtbx/refinement/tst_rigid_body.py",
  "$D/mmtbx/refinement/tst_refinement_flags.py",
  "$D/mmtbx/tst_model.py",
  "$D/mmtbx/tst_fmodel.py",
  "$D/mmtbx/tst_utils.py",
  "$D/mmtbx/tst_alignment.py",
  ["$D/mmtbx/tst_fmodel_fd.py", "P31"],
  "$D/ncs/tst_restraints.py",
  "$D/mmtbx/ncs/tst_restraints.py",
  ["$D/mmtbx/ncs/ncs.py", "exercise"],
  "$D/mmtbx/regression/tst_adp_restraints.py",
  "$D/mmtbx/scaling/tst_scaling.py",
  "$D/mmtbx/scaling/tst_outlier.py",
  ["$D/mmtbx/scaling/thorough_outlier_test.py", "P21"],
  "$D/mmtbx/twinning/probabalistic_detwinning.py",
  "$D/mmtbx/monomer_library/tst_rna_sugar_pucker_analysis.py",
  "$D/mmtbx/monomer_library/tst_cif_types.py",
  "$D/mmtbx/monomer_library/tst_motif.py",
  "$D/mmtbx/monomer_library/tst_selection.py",
  "$D/mmtbx/monomer_library/tst_tyr_from_gly_and_bnz.py",
  "$D/mmtbx/monomer_library/tst_pdb_interpretation.py",
  "$D/mmtbx/monomer_library/tst_rna_dna_interpretation.py",
  "$D/mmtbx/monomer_library/tst_protein_interpretation.py",
  "$D/mmtbx/regression/tst_altloc_chain_break.py",
  "$D/mmtbx/hydrogens/build_hydrogens.py",
  "$D/mmtbx/max_lik/tst_maxlik.py",
  "$D/masks/tst_masks.py",
  "$D/max_lik/tst_max_lik.py",
  "$D/mmtbx/dynamics/tst_cartesian_dynamics.py",
  "$D/mmtbx/tls/tst_tls.py",
  "$D/mmtbx/tls/tst_get_t_scheme.py",
  "$D/mmtbx/tls/tst_tls_refinement_fft.py",
  "$D/mmtbx/examples/f_model_manager.py",
  "$D/mmtbx/bulk_solvent/tst_bulk_solvent_and_scaling.py",
  "$D/mmtbx/alignment.py",
  "$D/mmtbx/invariant_domain.py",
  )

  build_dir = libtbx.env.under_build("mmtbx")
  dist_dir = libtbx.env.dist_path("mmtbx")

  test_utils.run_tests(build_dir, dist_dir, tst_list)

if (__name__ == "__main__"):
  run()
