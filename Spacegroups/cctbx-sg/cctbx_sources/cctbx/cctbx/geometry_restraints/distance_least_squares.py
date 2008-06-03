from cctbx import geometry_restraints
import cctbx.geometry_restraints.flags
import cctbx.geometry_restraints.manager
import cctbx.geometry_restraints.lbfgs
from cctbx import xray
from cctbx import crystal
import cctbx.crystal.coordination_sequences
from cctbx import sgtbx
from cctbx.array_family import flex
from scitbx import matrix as mx
import scitbx.lbfgs
from libtbx.str_utils import format_value
from libtbx.itertbx import count
import sys

if (1):
  flex.set_random_seed(0)

class restraint_parameters(object):

  def __init__(self, distance_ideal, weight):
    self.distance_ideal = distance_ideal
    self.weight = weight

restraint_parameters_si_o = restraint_parameters(1.61, 2.0)
restraint_parameters_o_si_o = restraint_parameters(2.629099, 0.41)
restraint_parameters_si_o_si = restraint_parameters(3.070969, 0.2308)

def setup_bond_params_table(structure, bond_sym_table):
  scatterers = structure.scatterers()
  t = geometry_restraints.bond_params_table(scatterers.size())
  for i_seq,bond_sym_dict in enumerate(bond_sym_table):
    for j_seq in bond_sym_dict.keys():
      i_seqs = [i_seq, j_seq]
      i_seqs.sort()
      scattering_types = [scatterers[i].scattering_type for i in i_seqs]
      scattering_types.sort()
      if (scattering_types == ["Si", "Si"]):
        params = restraint_parameters_si_o_si
      elif (scattering_types == ["O", "Si"]):
        params = restraint_parameters_si_o
      elif (scattering_types == ["O", "O"]):
        params = restraint_parameters_o_si_o
      else:
        raise AssertionError("Unknown scattering type pair.")
      if (not t[i_seq].has_key(j_seq)):
        t[i_seq][j_seq] = geometry_restraints.bond_params(
          distance_ideal=params.distance_ideal,
          weight=params.weight)
      else:
        prev_params = t[i_seq][j_seq]
        assert abs(prev_params.distance_ideal - params.distance_ideal) < 1.e-8
        assert abs(prev_params.weight - params.weight) < 1.e-8
  return t

def setup_nonbonded_params():
  p = geometry_restraints.nonbonded_params()
  d = p.distance_table
  d.setdefault("Si")["Si"] = 3.1
  d.setdefault("Si")["O"] = 1.5
  d.setdefault("O")["O"] = 2.0
  return p

class add_oxygen(object):

  def __init__(self, si_structure, si_pair_asu_table):
    self.structure = si_structure.deep_copy_scatterers()
    self.bond_sym_table = crystal.pair_sym_table(
      si_pair_asu_table.table().size())
    sites_frac = si_structure.sites_frac()
    si_asu_mappings = si_pair_asu_table.asu_mappings()
    i_oxygen = count(1)
    for i_seq,asu_dict in enumerate(si_pair_asu_table.table()):
      rt_mx_i_inv = si_asu_mappings.get_rt_mx(i_seq, 0).inverse()
      site_frac_i = sites_frac[i_seq]
      for j_seq,j_sym_groups in asu_dict.items():
        for i_group,j_sym_group in enumerate(j_sym_groups):
          if (j_seq < i_seq): continue
          j_sym = j_sym_group[0]
          rt_mx_ji = rt_mx_i_inv.multiply(
            si_asu_mappings.get_rt_mx(j_seq, j_sym))
          site_frac_ji = rt_mx_ji * sites_frac[j_seq]
          bond_center = (mx.col(site_frac_i) + mx.col(site_frac_ji)) / 2
          i_seq_o = self.structure.scatterers().size()
          self.structure.add_scatterer(xray.scatterer(
            label="O%d"%i_oxygen.next(),
            site=bond_center))
          self.bond_sym_table[i_seq].setdefault(i_seq_o).append(
            sgtbx.rt_mx(1,1))
          self.bond_sym_table[j_seq].setdefault(i_seq_o).append(
            rt_mx_ji.inverse_cancel())

def make_o_si_o_asu_table(si_o_structure, si_o_bond_asu_table):
  scatterers = si_o_structure.scatterers()
  asu_mappings = si_o_bond_asu_table.asu_mappings()
  o_si_o_asu_table = crystal.pair_asu_table(
    asu_mappings=asu_mappings)
  for i_seq,asu_dict in enumerate(si_o_bond_asu_table.table()):
    if (scatterers[i_seq].scattering_type != "Si"): continue
    pair_list = []
    for j_seq,j_sym_groups in asu_dict.items():
      if (scatterers[j_seq].scattering_type != "O"): continue
      for i_group,j_sym_group in enumerate(j_sym_groups):
        for j_sym in j_sym_group:
          pair_list.append((j_seq,j_sym))
    for i_jj1 in xrange(0,len(pair_list)-1):
      jj1 = pair_list[i_jj1]
      rt_mx_jj1_inv = asu_mappings.get_rt_mx(*jj1).inverse()
      for i_jj2 in xrange(i_jj1+1,len(pair_list)):
        jj2 = pair_list[i_jj2]
        rt_mx_jj21 = rt_mx_jj1_inv.multiply(asu_mappings.get_rt_mx(*jj2))
        o_si_o_asu_table.add_pair(
          i_seq=jj1[0],
          j_seq=jj2[0],
          rt_mx_ji=rt_mx_jj21)
  return o_si_o_asu_table

class distance_and_repulsion_least_squares:

  def __init__(self,
        si_structure,
        distance_cutoff,
        nonbonded_distance_cutoff=None,
        nonbonded_buffer=1,
        nonbonded_repulsion_function_type="gaussian",
        nonbonded_max_residual_bond_stretch_factor=1.0,
        n_trials=1,
        n_macro_cycles=2,
        max_exceptions_handled=10,
        connectivities=None,
        out=None):
    assert nonbonded_repulsion_function_type in ["gaussian", "cos", "prolsq"]
    assert n_trials > 0
    assert n_macro_cycles > 0
    assert max_exceptions_handled >= 0
    if (out is None): out = sys.stdout
    si_structure.show_summary(f=out).show_scatterers(f=out)
    print >> out
    out.flush()
    si_asu_mappings = si_structure.asu_mappings(
      buffer_thickness=distance_cutoff)
    si_pair_asu_table = crystal.pair_asu_table(
      asu_mappings=si_asu_mappings)
    si_pair_asu_table.add_all_pairs(distance_cutoff=distance_cutoff)
    si_pairs = si_structure.show_distances(
      pair_asu_table=si_pair_asu_table,
      out=out)
    if (connectivities is not None):
      assert list(si_pairs.pair_counts) == connectivities
    print >> out
    out.flush()
    si_o = add_oxygen(
      si_structure=si_structure,
      si_pair_asu_table=si_pair_asu_table)
    si_o.structure.show_summary(f=out).show_scatterers(f=out)
    print >> out
    out.flush()
    si_o_asu_mappings = si_o.structure.asu_mappings(
      buffer_thickness=distance_cutoff/2.*3)
    si_o_bond_asu_table = crystal.pair_asu_table(
      asu_mappings=si_o_asu_mappings)
    si_o_bond_asu_table.add_pair_sym_table(sym_table=si_o.bond_sym_table)
    si_o_bonds = si_o.structure.show_distances(
      pair_asu_table=si_o_bond_asu_table,
      out=out)
    n_si = si_pairs.pair_counts.size()
    n_si_o = si_o_bonds.pair_counts.size()
    assert si_o_bonds.pair_counts[:n_si].all_eq(si_pairs.pair_counts)
    assert si_o_bonds.pair_counts[n_si:].count(2) == n_si_o-n_si
    print >> out
    out.flush()
    o_si_o_asu_table = make_o_si_o_asu_table(
      si_o_structure=si_o.structure,
      si_o_bond_asu_table=si_o_bond_asu_table)
    o_si_o_pairs = si_o.structure.show_distances(
      pair_asu_table=o_si_o_asu_table,
      out=out)
    assert o_si_o_pairs.pair_counts[:n_si].all_eq(0)
    if (si_pairs.pair_counts.count(4) == n_si):
      assert o_si_o_pairs.pair_counts[n_si:].all_eq(6)
    print >> out
    out.flush()
    shell_asu_tables = crystal.coordination_sequences.shell_asu_tables(
      pair_asu_table=si_o_bond_asu_table,
      max_shell=3)
    if (1):
      si_o_bond_asu_table.add_pair_sym_table(
        sym_table=si_pair_asu_table.extract_pair_sym_table())
    if (1):
      si_o_bond_asu_table.add_pair_sym_table(
        sym_table=o_si_o_asu_table.extract_pair_sym_table())
    shell_sym_tables = [si_o_bond_asu_table.extract_pair_sym_table()]
    for shell_asu_table in shell_asu_tables[1:]:
      shell_sym_tables.append(shell_asu_table.extract_pair_sym_table())
    bond_params_table = setup_bond_params_table(
      structure=si_o.structure,
      bond_sym_table=shell_sym_tables[0])
    nonbonded_params = setup_nonbonded_params()
    nonbonded_types = flex.std_string()
    for scatterer in si_o.structure.scatterers():
      nonbonded_types.append(scatterer.scattering_type)
    if (nonbonded_repulsion_function_type == "gaussian"):
      nonbonded_function = geometry_restraints.gaussian_repulsion_function(
        max_residual=bond_params_table.mean_residual(
          bond_stretch_factor=nonbonded_max_residual_bond_stretch_factor))
      if (nonbonded_distance_cutoff is None):
        nonbonded_distance_cutoff = 7
    elif (nonbonded_repulsion_function_type == "cos"):
      nonbonded_function = geometry_restraints.cos_repulsion_function(
        max_residual=bond_params_table.mean_residual(
          bond_stretch_factor=nonbonded_max_residual_bond_stretch_factor))
    else:
      nonbonded_function = geometry_restraints.prolsq_repulsion_function()
    geometry_restraints_manager = geometry_restraints.manager.manager(
      crystal_symmetry=si_o.structure,
      site_symmetry_table=si_o.structure.site_symmetry_table(),
      bond_params_table=bond_params_table,
      shell_sym_tables=shell_sym_tables,
      nonbonded_params=nonbonded_params,
      nonbonded_types=nonbonded_types,
      nonbonded_function=nonbonded_function,
      nonbonded_distance_cutoff=nonbonded_distance_cutoff,
      nonbonded_buffer=nonbonded_buffer,
      max_reasonable_bond_distance=100)
    minimized = None
    for i_trial in xrange(n_trials):
      for i_exceptions_handled in xrange(max_exceptions_handled+1):
        trial_structure = si_o.structure.deep_copy_scatterers()
        if (i_trial > 0):
          n_scatterers = trial_structure.scatterers().size()
          trial_structure.set_sites_cart(flex.vec3_double(flex.random_double(
            size=n_scatterers*3)*10-5))
          trial_structure.apply_symmetry_sites()
        trial_minimized = []
        trial_sites_cart = None
        for i_macro_cycle in xrange(n_macro_cycles):
          if (trial_sites_cart is not None):
            trial_structure.set_sites_cart(sites_cart=trial_sites_cart)
            trial_structure = trial_structure.random_shift_sites(
              max_shift_cart=0.2)
            trial_structure.apply_symmetry_sites()
          trial_sites_cart = trial_structure.sites_cart()
          geometry_restraints_flags = geometry_restraints.flags.flags(
            bond=True,
            nonbonded=((i_macro_cycle % 2) != (n_macro_cycles % 2)))
          try:
            m = geometry_restraints.lbfgs.lbfgs(
              sites_cart=trial_sites_cart,
              geometry_restraints_manager=geometry_restraints_manager,
              geometry_restraints_flags=geometry_restraints_flags,
              lbfgs_termination_params=scitbx.lbfgs.termination_parameters(
                max_iterations=100),
              lbfgs_exception_handling_params=
                scitbx.lbfgs.exception_handling_parameters(
                  ignore_line_search_failed_step_at_lower_bound=True))
          except RuntimeError, lbfgs_error:
            if (i_trial == 0): raise
            if (not str(lbfgs_error).startswith(
                  "Bond distance > max_reasonable_bond_distance: ")): raise
            m = None
            break
          else:
            trial_minimized.append(m)
            trial_structure.set_sites_cart(sites_cart=trial_sites_cart)
        if (m is not None):
          break
      else:
        raise RuntimeError(
          "max_exceptions_handled=%d exceeded: %s" % (
            max_exceptions_handled, str(lbfgs_error)))
      ftr = trial_minimized[-1].final_target_result
      pair_proxies = geometry_restraints_manager.pair_proxies(
        sites_cart=trial_sites_cart)
      min_nonbonded_distance = flex.min_default(
        pair_proxies.nonbonded_proxies.deltas(sites_cart=trial_sites_cart),
        None)
      print >> out, \
        "i_trial, bond, nonbonded, min distance: %d, %.6g, %.6g, %s" % (
          i_trial,
          ftr.bond_residual_sum,
          ftr.nonbonded_residual_sum,
          format_value(format="%.4g", value=min_nonbonded_distance))
      out.flush()
      if (minimized is None or       minimized[-1].final_target_result.target
                             > trial_minimized[-1].final_target_result.target):
        minimized = trial_minimized
        minimized_structure = trial_structure
        best_i_trial = i_trial
    assert minimized is not None
    for im,m in enumerate(minimized):
      print >> out
      print >> out, "Energies at start of %d. minimization:" % (im+1)
      m.first_target_result.show(f=out)
      print >> out
      print >> out, "Energies at end of %d. minimization:" % (im+1)
      m.final_target_result.show(f=out)
    print >> out
    print >> out, "Final target value (i_trial=%d): %.6g" % (
      best_i_trial, minimized[-1].final_target_result.target)
    if (minimized[-1].final_target_result.target > 0.1):
      print >> out, "WARNING: LARGE final target value: %.6g" % (
        minimized[-1].final_target_result.target)
    print >> out
    minimized_structure.show_distances(
      pair_asu_table=si_o_bond_asu_table,
      out=out)
    print >> out
    sites_cart = minimized_structure.sites_cart()
    pair_proxies = geometry_restraints_manager.pair_proxies(
      sites_cart=sites_cart)
    pair_proxies.bond_proxies.show_sorted_by_residual(
      sites_cart=sites_cart,
      labels=[scatterer.label
        for scatterer in minimized_structure.scatterers()],
      f=out)
    print >> out
    pair_proxies.nonbonded_proxies.show_histogram_of_model_distances(
      sites_cart=sites_cart,
      f=out)
    print >> out
    out.flush()
    self.geometry_restraints_manager = geometry_restraints_manager
    self.start_structure = si_o.structure
    self.minimized_structure = minimized_structure
