from cctbx.array_family import flex
import math, time
from libtbx import adopt_init_args
from libtbx.test_utils import approx_equal, not_approx_equal
import sys
from stdlib import math
from cctbx import xray
from cctbx import adptbx
import mmtbx.restraints
from iotbx import pdb
from cctbx import geometry_restraints
from cctbx.geometry_restraints.lbfgs import lbfgs as cctbx_geometry_restraints_lbfgs
import scitbx.lbfgs
from libtbx.utils import Sorry, user_plus_sys_time
from mmtbx.tls import tools
from cctbx import adp_restraints
from mmtbx import ias
from mmtbx import utils
from mmtbx import model_statistics
from mmtbx.solvent import ordered_solvent
import iotbx.pdb


time_model_show = 0.0

def find_common_water_resseq_max(pdb_hierarchy):
  get_class = iotbx.pdb.common_residue_names_get_class
  hy36decode = iotbx.pdb.hy36decode
  result = None
  for model in pdb_hierarchy.models():
    for chain in model.chains():
      for rg in chain.residue_groups():
        for ag in rg.atom_groups():
          if (get_class(name=ag.resname) == "common_water"):
            try: i = hy36decode(width=4, s=rg.resseq)
            except (RuntimeError, ValueError): pass
            else:
              if (result is None or result < i):
                result = i
            break
  return result

class xh_connectivity_table(object):
  # XXX need angle information as well
  def __init__(self, geometry, xray_structure):
    bond_proxies_simple = geometry.geometry.pair_proxies(sites_cart =
      xray_structure.sites_cart()).bond_proxies.simple
    self.table = []
    scatterers = xray_structure.scatterers()
    for proxy in bond_proxies_simple:
      i_seq, j_seq = proxy.i_seqs
      i_x, i_h = None, None
      if(scatterers[i_seq].element_symbol() in ["H", "D"]):
        i_h = i_seq
        i_x = j_seq
        site_x = scatterers[i_x].site
        site_h = scatterers[i_h].site
        const_vect = flex.double(site_h)-flex.double(site_x)
        distance_model = xray_structure.unit_cell().distance(site_x, site_h)
        self.table.append([i_x, i_h, const_vect, proxy.distance_ideal,
                           distance_model])
      if(scatterers[j_seq].element_symbol() in ["H", "D"]):
        i_h = j_seq
        i_x = i_seq
        site_x = scatterers[i_x].site
        site_h = scatterers[i_h].site
        const_vect = flex.double(site_h)-flex.double(site_x)
        distance_model = xray_structure.unit_cell().distance(site_x, site_h)
        self.table.append([i_x, i_h, const_vect, proxy.distance_ideal,
                           distance_model])

class manager(object):
  def __init__(self, xray_structure,
                     pdb_hierarchy,
                     processed_pdb_files_srv = None,
                     restraints_manager = None,
                     ias_xray_structure = None,
                     refinement_flags = None,
                     ias_manager = None,
                     wilson_b = None,
                     tls_groups = None,
                     anomalous_scatterer_groups = None,
                     log = None):
    self.log = log
    self.processed_pdb_files_srv = processed_pdb_files_srv
    self.restraints_manager = restraints_manager
    self.xray_structure = xray_structure
    self.xray_structure_initial = self.xray_structure.deep_copy_scatterers()
    self.pdb_hierarchy = pdb_hierarchy
    self.pdb_atoms = pdb_hierarchy.atoms()
    self.pdb_atoms.reset_i_seq()
    self.refinement_flags = refinement_flags
    self.wilson_b = wilson_b
    self.tls_groups = tls_groups
    if(anomalous_scatterer_groups is not None and
      len(anomalous_scatterer_groups) == 0):
      anomalous_scatterer_groups = None
    self.anomalous_scatterer_groups = anomalous_scatterer_groups
    # IAS related, need a real cleaning!
    self.ias_manager = ias_manager
    self.ias_xray_structure = ias_xray_structure
    self.use_ias = False
    self.ias_selection = None

  def xh_connectivity_table(self):
    result = None
    if(self.restraints_manager is not None):
      if(self.xray_structure.hd_selection().count(True) > 0):
        xray_structure = self.xray_structure
        if(self.ias_selection and self.ias_selection.count(True) > 0):
          xray_structure = self.xray_structure.select(~self.ias_selection)
        result = xh_connectivity_table(
          geometry       = self.restraints_manager,
          xray_structure = xray_structure).table
    return result

  def idealize_h(self, xh_bond_distance_deviation_limit=0, show=True): # XXX _limit is not used
    if(self.xray_structure.hd_selection().count(True) > 0):
      sol_hd = self.solvent_selection().set_selected(
        ~self.xray_structure.hd_selection(), False)
      mac_hd = self.xray_structure.hd_selection().set_selected(
        self.solvent_selection(), False)
      selx = ~self.xray_structure.hd_selection()
      if(self.ias_selection is not None):
        selx.set_selected(self.ias_selection, False)
      sites_cart_mac_before = self.xray_structure.sites_cart().select(selx)
      xhd = flex.double()
      for t in self.xh_connectivity_table():
        xhd.append(abs(t[-1]-t[-2]))
        if(abs(t[3]-t[4]) < xh_bond_distance_deviation_limit):
          sol_hd[t[1]] = False
          mac_hd[t[1]] = False
      if(show):
        print >> self.log, \
        "X-H deviation from ideal before regularization (bond): mean=%6.3f max=%6.3f"%\
        (flex.mean(xhd), flex.max(xhd))
      for sel_pair in [(mac_hd, False), (sol_hd, True)]*2:
        if(sel_pair[0].count(True) > 0):
          sel = sel_pair[0]
          if(self.ias_selection is not None and self.ias_selection.count(True) > 0):
            sel = sel.select(~self.ias_selection)
          self.geometry_minimization(
            selection = sel,
            bond      = True,
            nonbonded = sel_pair[1],
            angle     = True,
            dihedral  = True,
            chirality = True,
            planarity = True)
      sites_cart_mac_after = self.xray_structure.sites_cart().select(selx)
      assert approx_equal(flex.max(sites_cart_mac_before.as_double() -
        sites_cart_mac_after.as_double()), 0)
      xhd = flex.double()
      for t in self.xh_connectivity_table():
        xhd.append(abs(t[-1]-t[-2]))
      if(show):
        print >> self.log,\
        "X-H deviation from ideal after  regularization (bond): mean=%6.3f max=%6.3f"%\
        (flex.mean(xhd), flex.max(xhd))

  def extract_water_residue_groups(self):
    result = []
    solvent_sel = self.solvent_selection()
    get_class = iotbx.pdb.common_residue_names_get_class
    for model in self.pdb_hierarchy.models():
      for chain in model.chains():
        for rg in chain.residue_groups():
          first_water = None
          first_other = None
          for ag in rg.atom_groups():
            residue_id = "%3s%4s%1s" % (ag.resname, rg.resseq, rg.icode)
            if (get_class(name=ag.resname) == "common_water"):
              for atom in ag.atoms():
                i_seq = atom.i_seq
                assert solvent_sel[i_seq]
                if (first_water is None):
                  first_water = atom
            else:
              for atom in ag.atoms():
                assert not solvent_sel[atom.i_seq]
                if (first_other is None):
                  first_other = atom
          if (first_water is not None):
            if (first_other is not None):
              raise RuntimeError(
                "residue_group with mix of water and non-water:\n"
                + "  %s\n" % first_water.quote()
                + "  %s" % first_other.quote())
            result.append(rg)
    return result

  def renumber_water(self):
    for i,rg in enumerate(self.extract_water_residue_groups()):
      rg.resseq = pdb.resseq_encode(value=i+1)
      rg.icode = " "

  def add_hydrogens(self, element = "H"):
    result = []
    xs = self.xray_structure
    frac = xs.unit_cell().fractionalize
    sites_cart = xs.sites_cart()
    u_isos = xs.extract_u_iso_or_u_equiv()
    next_to_i_seqs = []
    last_insert_i_seq = [sites_cart.size()]
    def insert_atoms(atom, atom_names, element):
      i_seq = atom.i_seq
      assert i_seq < last_insert_i_seq[0]
      last_insert_i_seq[0] = i_seq
      xyz = sites_cart[i_seq]
      sign = True
      for i,atom_name in enumerate(atom_names):
        h = atom.detached_copy()
        h.name = atom_name
        if(sign):
          h.xyz = [a+b for a,b in zip(xyz, (1,0,0))]
          sign = False
        else:
          h.xyz = [a+b for a,b in zip(xyz, (-1,0,0))]
          sign = True
        h.sigxyz = (0,0,0)
        h.occ = 1.0
        h.sigocc = 0
        h.b = adptbx.u_as_b(u_isos[i_seq])
        h.sigb = 0
        h.uij = (-1,-1,-1,-1,-1,-1)
        if (pdb.hierarchy.atom.has_siguij()):
          h.siguij = (-1,-1,-1,-1,-1,-1)
        h.element = "%2s" % element.strip()
        ag.append_atom(atom=h)
        scatterer = xray.scatterer(
          label           = h.name,
          scattering_type = h.element,
          site            = frac(h.xyz),
          u               = adptbx.b_as_u(h.b),
          occupancy       = h.occ)
        xs.add_scatterer(
          scatterer = scatterer,
          insert_at_index = i_seq+i+1)
        next_to_i_seqs.append(i_seq) # not i_seq+i because refinement_flags.add
                                     # sorts next_to_i_seqs internally :-(
    water_rgs = self.extract_water_residue_groups()
    water_rgs.reverse()
    for rg in water_rgs:
      if (rg.atom_groups_size() != 1):
        raise RuntimeError(
          "Not implemented: cannot handle water with alt. conf.")
      ag = rg.only_atom_group()
      atoms = ag.atoms()
      if (atoms.size() == 2):
        o_atom = None
        h_atom = None
        for atom in atoms:
          if (atom.element.strip() == "O"): o_atom = atom
          else:                             h_atom = atom
        assert [o_atom, h_atom].count(None) == 0
        h_name = h_atom.name.strip()
        if(len(h_name) == 1):
          atom_name = h_name+"1"
        elif(len(h_name) == 2):
          if(h_name[0].isdigit()):
            if(int(h_name[0]) == 1): atom_name = h_name[1]+"2"
            elif(int(h_name[0]) == 2): atom_name = h_name[1]+"1"
            else: raise RuntimeError
          elif(h_name[1].isdigit()):
            if(int(h_name[1]) == 1): atom_name = h_name[0]+"2"
            elif(int(h_name[1]) == 2): atom_name = h_name[0]+"1"
            else: raise RuntimeError
          else: raise RuntimeError
        else: raise RuntimeError
        insert_atoms(
          atom=o_atom,
          atom_names=[atom_name],
          element=h_atom.element)
      elif (atoms.size() == 1):
        atom = atoms[0]
        assert atom.element.strip() == "O"
        insert_atoms(
          atom=atom,
          atom_names=[element+n for n in ["1","2"]],
          element=element)
    #
    print >> self.log, "Number of H added:", len(next_to_i_seqs)
    if (len(next_to_i_seqs) == 0): return
    if (self.refinement_flags is not None):
      self.refinement_flags.add(
        next_to_i_seqs=next_to_i_seqs,
        sites_individual=True)
    # XXX very inefficient: re-process PDB from scratch and create restraints
    raw_records = [pdb.format_cryst1_record(
      crystal_symmetry=self.xray_structure)]
    raw_records.extend(self.pdb_hierarchy.as_pdb_string().splitlines())
    processed_pdb_file, pdb_inp = self.processed_pdb_files_srv.\
      process_pdb_files(raw_records = raw_records)
    new_xray_structure = processed_pdb_file.xray_structure(
      show_summary = False).deep_copy_scatterers()
    new_pdb_hierarchy = processed_pdb_file.all_chain_proxies.pdb_hierarchy
    new_pdb_atoms = processed_pdb_file.all_chain_proxies.pdb_atoms
    old_pdb_atoms = self.pdb_hierarchy.atoms()
    assert len(new_pdb_atoms) == len(old_pdb_atoms)
    for a1, a2 in zip(old_pdb_atoms, new_pdb_atoms):
      assert a1.name.strip() == a2.name.strip()
      assert a1.element.strip() == a2.element.strip()
      assert approx_equal(a1.xyz, a2.xyz, 0.001)
    self.pdb_hierarchy = new_pdb_hierarchy
    self.pdb_atoms = new_pdb_atoms
    # XXX now we gonna loose old grm (with all NCS, edits, etc...)
    if(self.restraints_manager.ncs_groups is not None):
      raise Sorry("Hydrogen building is not compatible with NCS refinement.")
    sctr_keys = \
      self.xray_structure.scattering_type_registry().type_count_dict().keys()
    has_hd = "H" in sctr_keys or "D" in sctr_keys
    geometry = processed_pdb_file.geometry_restraints_manager(
      show_energies      = False,
      plain_pairs_radius = self.restraints_manager.geometry.plain_pairs_radius,
      edits              = None, #self.params.geometry_restraints.edits, XXX
      assume_hydrogens_all_missing = not has_hd)
    # self.remove_selected_geometry_restraints(manager = geometry) XXX this is lost too
    new_restraints_manager = mmtbx.restraints.manager(
      geometry      = geometry,
      normalization = self.restraints_manager.normalization)
    self.restraints_manager = new_restraints_manager
    self.idealize_h()

  def geometry_minimization(self,
                            max_number_of_iterations = 500,
                            number_of_macro_cycles   = 3,
                            selection                = None,
                            bond                     = False,
                            nonbonded                = False,
                            angle                    = False,
                            dihedral                 = False,
                            chirality                = False,
                            planarity                = False):
    assert max_number_of_iterations+number_of_macro_cycles > 0
    assert [bond,nonbonded,angle,dihedral,chirality,planarity].count(False) < 6
    from mmtbx.command_line import geometry_minimization
    import scitbx.lbfgs
    lbfgs_termination_params = scitbx.lbfgs.termination_parameters(
      max_iterations = max_number_of_iterations)
    geometry_restraints_flags = geometry_restraints.flags.flags(
      bond      = bond,
      nonbonded = nonbonded,
      angle     = angle,
      dihedral  = dihedral,
      chirality = chirality,
      planarity = planarity)
    for i in xrange(number_of_macro_cycles):
      sites_cart = self.xray_structure.sites_cart()
      sites_cart_orig = sites_cart.deep_copy()
      if(self.ias_selection is not None and self.ias_selection.count(True) > 0):
        sites_cart = sites_cart.select(~self.ias_selection)
      exception_handling_params = scitbx.lbfgs.exception_handling_parameters(
        ignore_line_search_failed_step_at_lower_bound = True)
      minimized = geometry_minimization.lbfgs(
        sites_cart                  = sites_cart,
        geometry_restraints_manager = self.restraints_manager.geometry,
        geometry_restraints_flags   = geometry_restraints_flags,
        lbfgs_termination_params    = lbfgs_termination_params,
        lbfgs_exception_handling_params = exception_handling_params,
        sites_cart_selection        = selection)
      if(self.ias_selection is not None):
        for i_seq, ias_s in enumerate(self.ias_selection): # assumes that IAS appended to the back
          if(not ias_s):
            sites_cart_orig[i_seq] = sites_cart[i_seq]
      else:
        sites_cart_orig = sites_cart
      self.xray_structure.set_sites_cart(sites_cart = sites_cart_orig)

  def extract_ncs_groups(self):
    result = None
    if(self.restraints_manager.ncs_groups is not None):
      result = self.restraints_manager.ncs_groups.extract_ncs_groups(
        sites_cart = self.xray_structure.sites_cart())
    return result

  def deep_copy(self):
    return self.select(selection = flex.bool(
      self.xray_structure.scatterers().size(), True))

  def add_ias(self, fmodel=None, ias_params=None, file_name=None,
                                                             build_only=False):
    if(self.ias_manager is not None):
       self.remove_ias()
       fmodel.update_xray_structure(xray_structure = self.xray_structure,
                                    update_f_calc = True)
    print >> self.log, ">>> Adding IAS.........."
    self.old_refinement_flags = None
    if not build_only: self.use_ias = True
    self.ias_manager = ias.manager(
                    geometry             = self.restraints_manager.geometry,
                    pdb_atoms            = self.pdb_atoms,
                    xray_structure       = self.xray_structure,
                    fmodel               = fmodel,
                    params               = ias_params,
                    file_name            = file_name,
                    log                  = self.log)
    if(not build_only):
      self.ias_xray_structure = self.ias_manager.ias_xray_structure
      ias_size = self.ias_xray_structure.scatterers().size()
      tail = flex.bool(ias_size, True)
      tail_false = flex.bool(ias_size, False)
      self.ias_selection = flex.bool(
                      self.xray_structure.scatterers().size(),False)
      self.ias_selection.extend(tail)
      self.xray_structure.concatenate_inplace(other = self.ias_xray_structure)
      print >> self.log, "Scattering dictionary for combined xray_structure:"
      self.xray_structure.scattering_type_registry().show()
      self.xray_structure_initial.concatenate_inplace(
                                           other = self.ias_xray_structure)
      if(self.refinement_flags is not None):
         self.old_refinement_flags = self.refinement_flags.deep_copy()
         # define flags
         ssites = flex.bool(self.ias_xray_structure.scatterers().size(), False)
         sadp = flex.bool(self.ias_xray_structure.scatterers().size(), False)
         # XXX set occ refinement ONLY for involved atoms
         # XXX now it refines only occupancies of IAS !!!
         occupancy_flags = []
         ms = self.ias_selection.count(False)
         for i in range(1, self.ias_selection.count(True)+1):
           occupancy_flags.append([flex.size_t([ms+i-1])])
         # set flags
         self.refinement_flags.inflate(
           sites_individual     = ssites,
           s_occupancies        = occupancy_flags,
           adp_individual_iso   = sadp,
           adp_individual_aniso = sadp)
         # adjust flags
         self.refinement_flags.sites_individual.set_selected(self.ias_selection, False)
         self.refinement_flags.sites_individual.set_selected(~self.ias_selection, True)
         self.refinement_flags.adp_individual_aniso.set_selected(self.ias_selection, False)
         self.refinement_flags.adp_individual_iso.set_selected(self.ias_selection, True)

         #occs = flex.double(self.xray_structure.scatterers().size(), 0.9)
         #self.xray_structure.scatterers().set_occupancies(occs, ~self.ias_selection)
         # D9
         sel = self.xray_structure.scatterers().extract_scattering_types() == "D9"
         self.xray_structure.convert_to_anisotropic(selection = sel)
         self.refinement_flags.adp_individual_aniso.set_selected(sel, True)
         self.refinement_flags.adp_individual_iso.set_selected(sel, False)
    # add to pdb_hierarchy:
    # XXX XXX CONSOLIDATE WITH add_solvent
    pdb_model = self.pdb_hierarchy.only_model()
    new_chain = pdb.hierarchy.chain(id=" ")
    orth = self.ias_xray_structure.unit_cell().orthogonalize
    n_seq = self.pdb_atoms.size()
    i_seq = 0
    for sc in self.ias_xray_structure.scatterers():
      i_seq += 1
      new_atom_name = sc.label.strip()
      if(len(new_atom_name) < 4): new_atom_name = " " + new_atom_name
      while(len(new_atom_name) < 4): new_atom_name = new_atom_name+" "
      new_atom = (pdb.hierarchy.atom()
        .set_serial(new_serial=pdb.hy36encode(width=5, value=n_seq+i_seq))
        .set_name(new_name=new_atom_name)
        .set_xyz(new_xyz=orth(sc.site))
        .set_occ(new_occ=sc.occupancy)
        .set_b(new_b=adptbx.u_as_b(sc.u_iso))
        .set_element(sc.scattering_type[:1])
        .set_charge(sc.scattering_type[1:3])
        .set_hetero(new_hetero=True))
      new_atom_group = pdb.hierarchy.atom_group(altloc="", resname="IAS")
      new_atom_group.append_atom(atom=new_atom)
      new_residue_group = pdb.hierarchy.residue_group(
        resseq=pdb.resseq_encode(value=i_seq), icode=" ")
      new_residue_group.append_atom_group(atom_group=new_atom_group)
      new_chain.append_residue_group(residue_group=new_residue_group)
    if (new_chain.residue_groups_size() != 0):
      pdb_model.append_chain(chain=new_chain)
    self.pdb_atoms = self.pdb_hierarchy.atoms()
    self.pdb_atoms.reset_i_seq()

  def remove_ias(self):
    print >> self.log, ">>> Removing IAS..............."
    self.use_ias = False
    if(self.ias_manager is not None):
       self.ias_manager = None
    if(self.old_refinement_flags is not None):
       self.refinement_flags = self.old_refinement_flags.deep_copy()
       self.old_refinement_flags = None
    if(self.ias_selection is not None):
       self.xray_structure.select_inplace(
         selection = ~self.ias_selection)
       self.xray_structure.scattering_type_registry().show()
       self.pdb_hierarchy = self.pdb_hierarchy.select(
         atom_selection = ~self.ias_selection)
       self.pdb_atoms = self.pdb_hierarchy.atoms()
       self.ias_selection = None

  def show_rigid_bond_test(self, out=None):
    if (out is None): out = sys.stdout
    scatterers = self.xray_structure.scatterers()
    unit_cell = self.xray_structure.unit_cell()
    rbt_array = flex.double()
    for proxy in self.restraints_manager.geometry.pair_proxies() \
                   .bond_proxies.simple:
      i_seqs = proxy.i_seqs
      i,j = proxy.i_seqs
      atom_i = self.pdb_atoms[i]
      atom_j = self.pdb_atoms[j]
      if (    atom_i.element.strip() not in ["H","D"]
          and atom_j.element.strip() not in ["H","D"]):
        sc_i = scatterers[i]
        sc_j = scatterers[j]
        if (sc_i.flags.use_u_aniso() and sc_j.flags.use_u_aniso()):
          p = adp_restraints.rigid_bond_pair(
            sc_i.site, sc_j.site, sc_i.u_star, sc_j.u_star, unit_cell)
          rbt_value = p.delta_z()*10000.
          rbt_array.append(rbt_value)
          print >> out, "%s %s %10.3f"%(atom_i.name, atom_j.name, rbt_value)
    if (rbt_array.size() != 0):
      print >> out, "RBT values (*10000):"
      print >> out, "  mean = %.3f"%flex.mean(rbt_array)
      print >> out, "  max  = %.3f"%flex.max(rbt_array)
      print >> out, "  min  = %.3f"%flex.min(rbt_array)

  def restraints_manager_energies_sites(self,
                                        geometry_flags    = None,
                                        compute_gradients = False,
                                        gradients         = None,
                                        disable_asu_cache = False):
    sites_cart = self.xray_structure.sites_cart()
    if(self.use_ias and self.ias_selection is not None and
       self.ias_selection.count(True) > 0):
      sites_cart = sites_cart.select(~self.ias_selection)
    return self.restraints_manager.energies_sites(
      sites_cart        = sites_cart,
      geometry_flags    = geometry_flags,
      compute_gradients = compute_gradients,
      gradients         = gradients,
      disable_asu_cache = disable_asu_cache)

  def solvent_selection(self):
    water = ordered_solvent.water_ids()
    result = flex.bool()
    get_class = iotbx.pdb.common_residue_names_get_class
    for a in self.pdb_atoms:
      element = (a.element).strip().upper()
      resname = (a.parent().resname).strip()
      name    = (a.name).strip()
      if((element in water.element_types) and
         (name in water.atom_names) and \
         (get_class(name = resname) == "common_water")):
        result.append(True)
      else: result.append(False)
    return result

  def xray_structure_macromolecule(self):
    sel = self.solvent_selection()
    if(self.use_ias): sel = sel | self.ias_selection
    result = self.xray_structure.select(~sel)
    return result

  def select(self, selection):
    # XXX ignores IAS
    new_pdb_hierarchy = self.pdb_hierarchy.select(selection, copy_atoms=True)
    new_refinement_flags = None
    if(self.refinement_flags is not None):
      new_refinement_flags = self.refinement_flags.select(selection)
    new_restraints_manager = None
    if(self.restraints_manager is not None):
      new_restraints_manager = self.restraints_manager.select(
        selection = selection)
      new_restraints_manager.geometry.pair_proxies(sites_cart =
        self.xray_structure.sites_cart().select(selection)) # XXX is it necessary ?
    new = manager(
      processed_pdb_files_srv    = self.processed_pdb_files_srv,
      restraints_manager         = new_restraints_manager,
      xray_structure             = self.xray_structure.select(selection),
      pdb_hierarchy              = new_pdb_hierarchy,
      refinement_flags           = new_refinement_flags,
      tls_groups                 = self.tls_groups, # XXX not selected, potential bug
      anomalous_scatterer_groups = self.anomalous_scatterer_groups,
      log                        = self.log)
    new.xray_structure_initial = \
      self.xray_structure_initial.deep_copy_scatterers()
    new.xray_structure.scattering_type_registry()
    return new

  def number_of_ordered_solvent_molecules(self):
    return self.solvent_selection().count(True)

  def show_groups(self, rigid_body = None, tls = None,
                        out = None, text="Information about rigid groups"):
    global time_model_show
    timer = user_plus_sys_time()
    selections = None
    if(rigid_body is not None):
       selections = self.refinement_flags.sites_rigid_body
    if(tls is not None): selections = self.refinement_flags.adp_tls
    if(self.refinement_flags.sites_rigid_body is None and
                                 self.refinement_flags.adp_tls is None): return
    assert selections is not None
    if (out is None): out = sys.stdout
    print >> out
    line_len = len("| "+text+"|")
    fill_len = 80 - line_len-1
    upper_line = "|-"+text+"-"*(fill_len)+"|"
    print >> out, upper_line
    next = "| Total number of atoms = %-6d  Number of rigid groups = %-3d                |"
    natoms_total = self.xray_structure.scatterers().size()
    print >> out, next % (natoms_total, len(selections))
    print >> out, "| group: start point:                        end point:                       |"
    print >> out, "|               x      B  atom  residue  <>        x      B  atom  residue    |"
    next = "| %5d: %8.3f %6.2f %5s %3s %5s <> %8.3f %6.2f %5s %3s %5s   |"
    sites = self.xray_structure.sites_cart()
    b_isos = self.xray_structure.extract_u_iso_or_u_equiv() * math.pi**2*8
    for i_seq, selection in enumerate(selections):
      if (isinstance(selection, flex.bool)):
        i_selection = selection.iselection()
      else:
        i_selection = selection
      start = i_selection[0]
      final = i_selection[i_selection.size()-1]
      first = self.pdb_atoms[start]
      last  = self.pdb_atoms[final]
      first_ag = first.parent()
      first_rg = first_ag.parent()
      last_ag = last.parent()
      last_rg = last_ag.parent()
      print >> out, next % (i_seq+1,
        sites[start][0], b_isos[start],
          first.name, first_ag.resname, first_rg.resid(),
        sites[final][0], b_isos[final],
          last.name, last_ag.resname, last_rg.resid())
    print >> out, "|"+"-"*77+"|"
    print >> out
    out.flush()
    time_model_show += timer.elapsed()

  def remove_solvent(self):
    result = self.select(selection = ~self.solvent_selection())
    return result

  def show_occupancy_statistics(self, out=None, text=""):
    global time_model_show
    timer = user_plus_sys_time()
    # XXX make this more complete and smart
    if(out is None): out = sys.stdout
    print >> out, "|-"+text+"-"*(80 - len("| "+text+"|") - 1)+"|"
    occ = self.xray_structure.scatterers().extract_occupancies()
    occ_min = flex.min(occ)
    occ_max = flex.max(occ)
    n_zeros = (occ < 0.1).count(True)
    percent_small = n_zeros * 100 / occ.size()
    n_large = (occ > 2.0).count(True)
    if(occ_min < 0.0):
       raise Sorry("There are atoms with negative occupancies. Check input "\
                   "PDB file.")
    if(percent_small > 30.0):
       print >> out, "| *** WARNING: there more than 30 % of atoms with small occupancy (< 0.1) *** |"
    if(n_large > 0):
       print >> out, "| *** WARNING: there are some atoms with large occupancy (> 2.0) ***          |"
    if(abs(occ_max-occ_min) >= 0.01):
       print >> out, "| occupancies: max = %-6.2f min = %-6.2f number of "\
                     "occupancies < 0.1 = %-6d |"%(occ_max,occ_min,n_zeros)
    else:
       print >> out, "| occupancies: max = %-6.2f min = %-6.2f number of "\
                     "occupancies < 0.1 = %-6d |"%(occ_max,occ_min,n_zeros)
    print >> out, "|"+"-"*77+"|"
    out.flush()
    time_model_show += timer.elapsed()

  def write_pdb_file(self, out = None, selection = None, xray_structure = None):
    return utils.write_pdb_file(
      xray_structure       = self.xray_structure,
      pdb_hierarchy        = self.pdb_hierarchy,
      pdb_atoms            = self.pdb_atoms,
      selection            = selection,
      out                  = out)

  def add_solvent(self, solvent_xray_structure,
                        atom_name    = "O",
                        residue_name = "HOH",
                        chain_id     = " ",
                        refine_occupancies = False,
                        refine_adp = None):
    assert refine_adp is not None
    if(refine_adp == "isotropic"):
      solvent_xray_structure.convert_to_isotropic()
    elif(refine_adp == "anisotropic"):
      solvent_xray_structure.convert_to_anisotropic(selection =
        ~solvent_xray_structure.hd_selection())
    else: raise RuntimeError
    ms = self.xray_structure.scatterers().size() #
    self.xray_structure = \
      self.xray_structure.concatenate(solvent_xray_structure)
    occupancy_flags = None
    if(refine_occupancies):
      occupancy_flags = []
      for i in range(1, solvent_xray_structure.scatterers().size()+1):
        occupancy_flags.append([flex.size_t([ms+i-1])])
    if(self.refinement_flags.individual_sites):
      ssites = flex.bool(solvent_xray_structure.scatterers().size(), True)
    else: ssites = None
    if(self.refinement_flags.adp_individual_iso):
      sadp_iso = solvent_xray_structure.use_u_iso()
    else: sadp_iso = None
    if(self.refinement_flags.adp_individual_aniso):
      sadp_aniso = solvent_xray_structure.use_u_aniso()
    else: sadp_aniso = None
    self.refinement_flags.inflate(
      sites_individual       = ssites,
      adp_individual_iso     = sadp_iso,
      adp_individual_aniso   = sadp_aniso,
      s_occupancies          = occupancy_flags)
    new_atom_name = atom_name.strip()
    if(len(new_atom_name) < 4): new_atom_name = " " + new_atom_name
    while(len(new_atom_name) < 4): new_atom_name = new_atom_name+" "
    #
    i_seq = find_common_water_resseq_max(pdb_hierarchy=self.pdb_hierarchy)
    if (i_seq is None or i_seq < 0): i_seq = 0
    #
    # XXX XXX CONSOLIDATE WITH add_ias
    pdb_model = self.pdb_hierarchy.only_model()
    new_chain = pdb.hierarchy.chain(id=chain_id)
    orth = solvent_xray_structure.unit_cell().orthogonalize
    serial_offs = self.pdb_atoms.size() - i_seq
    for sc in solvent_xray_structure.scatterers():
      i_seq += 1
      new_atom = (pdb.hierarchy.atom()
        .set_serial(new_serial=pdb.hy36encode(width=5, value=serial_offs+i_seq))
        .set_name(new_name=new_atom_name)
        .set_xyz(new_xyz=orth(sc.site))
        .set_occ(new_occ=sc.occupancy)
        .set_b(new_b=adptbx.u_as_b(sc.u_iso))
        .set_element(sc.scattering_type[:1])
        .set_charge(sc.scattering_type[1:3])
        .set_hetero(new_hetero=True))
      new_atom_group = pdb.hierarchy.atom_group(
        altloc="", resname=residue_name)
      assert new_atom.parent() is None
      new_atom_group.append_atom(atom=new_atom)
      assert new_atom.parent().memory_id() == new_atom_group.memory_id()
      new_residue_group = pdb.hierarchy.residue_group(
        resseq=pdb.resseq_encode(value=i_seq), icode=" ")
      new_residue_group.append_atom_group(atom_group=new_atom_group)
      new_chain.append_residue_group(residue_group=new_residue_group)
    if (new_chain.residue_groups_size() != 0):
      pdb_model.append_chain(chain=new_chain)
    self.pdb_atoms = self.pdb_hierarchy.atoms()
    self.pdb_atoms.reset_i_seq()
    #
    geometry = self.restraints_manager.geometry
    number_of_new_solvent = solvent_xray_structure.scatterers().size()
    if(geometry.model_indices is None):
       model_indices = None
    else:
       model_indices = flex.size_t(number_of_new_solvent, 0)
    if(geometry.conformer_indices is None):
       conformer_indices = None
    else:
       conformer_indices = flex.size_t(number_of_new_solvent, 0)
    geometry = geometry.new_including_isolated_sites(
           n_additional_sites  = number_of_new_solvent,
           model_indices       = model_indices,
           conformer_indices   = conformer_indices,
           site_symmetry_table = solvent_xray_structure.site_symmetry_table(),
           nonbonded_types     = flex.std_string(number_of_new_solvent, "OH2"))
    self.restraints_manager = mmtbx.restraints.manager(
                         geometry      = geometry,
                         ncs_groups    = self.restraints_manager.ncs_groups,
                         normalization = self.restraints_manager.normalization)
    if (self.restraints_manager.ncs_groups is not None):
      self.restraints_manager.ncs_groups.register_additional_isolated_sites(
        number=number_of_new_solvent)
    self.restraints_manager.geometry.update_plain_pair_sym_table(
                                 sites_frac = self.xray_structure.sites_frac())
    assert self.pdb_atoms.size() == self.xray_structure.scatterers().size()

  def scale_adp(self, scale_max, scale_min):
    b_isos = self.xray_structure.extract_u_iso_or_u_equiv() * math.pi**2*8
    b_isos_mean = flex.mean(b_isos)
    max_b_iso = b_isos_mean * scale_max
    min_b_iso = b_isos_mean / scale_min
    sel_outliers_max = b_isos > max_b_iso
    sel_outliers_min = b_isos < min_b_iso
    b_isos.set_selected(sel_outliers_max, max_b_iso)
    b_isos.set_selected(sel_outliers_min, min_b_iso)
    self.xray_structure.set_b_iso(values = b_isos)

  def geometry_statistics(self):
    sites_cart = self.xray_structure.sites_cart()
    if(self.use_ias): sites_cart = sites_cart.select(~self.ias_selection)
    return model_statistics.geometry(
      sites_cart         = sites_cart,
      restraints_manager = self.restraints_manager)

  def show_geometry_statistics(self, message = "", out = None):
    global time_model_show
    if(out is None): out = self.log
    timer = user_plus_sys_time()
    result = self.geometry_statistics()
    result.show(message = message, out = out)
    time_model_show += timer.elapsed()
    return result

  def adp_statistics(self):
    return model_statistics.adp(model = self)

  def show_adp_statistics(self,
                          prefix         = "",
                          padded         = False,
                          pdb_deposition = False,
                          out            = None):
    global time_model_show
    if(out is None): out = self.log
    timer = user_plus_sys_time()
    result = self.adp_statistics()
    result.show(out = out, prefix = prefix, padded = padded,
      pdb_deposition = pdb_deposition)
    time_model_show += timer.elapsed()
    return result

  def energies_adp(self, iso_restraints, compute_gradients, use_hd):
    assert self.refinement_flags is not None
    n_aniso = 0
    if(self.refinement_flags.adp_individual_aniso is not None):
      n_aniso = self.refinement_flags.adp_individual_aniso.count(True)
    if(n_aniso == 0):
      energies_adp_iso = self.restraints_manager.energies_adp_iso(
        xray_structure    = self.xray_structure,
        parameters        = iso_restraints,
        use_u_local_only  = iso_restraints.use_u_local_only,
        use_hd            = use_hd,
        compute_gradients = compute_gradients)
      target = energies_adp_iso.target
    else:
      energies_adp_aniso = self.restraints_manager.energies_adp_aniso(
        xray_structure    = self.xray_structure,
        compute_gradients = compute_gradients)
      target = energies_adp_aniso.target
    u_iso_gradients = None
    u_aniso_gradients = None
    if(compute_gradients):
      if(n_aniso == 0):
        u_iso_gradients = energies_adp_iso.gradients
      else:
        u_aniso_gradients = energies_adp_aniso.gradients_aniso_star
        u_iso_gradients = energies_adp_aniso.gradients_iso
    class result(object):
      def __init__(self):
        self.target = target
        self.u_iso_gradients = u_iso_gradients
        self.u_aniso_gradients = u_aniso_gradients
    return result()

  def set_refine_individual_sites(self, selection = None):
    self.xray_structure.scatterers().flags_set_grads(state=False)
    if(selection is None):
      selection = self.refinement_flags.sites_individual
    self.xray_structure.scatterers().flags_set_grad_site(
      iselection = selection.iselection())

  def set_refine_individual_adp(self, selection_iso = None,
                                      selection_aniso = None):
    self.xray_structure.scatterers().flags_set_grads(state=False)
    if(selection_iso is None):
      selection_iso = self.refinement_flags.adp_individual_iso
    if(selection_iso is not None):
      self.xray_structure.scatterers().flags_set_grad_u_iso(
        iselection = selection_iso.iselection())
    if(selection_aniso is None):
      selection_aniso = self.refinement_flags.adp_individual_aniso
    if(selection_aniso is not None):
      self.xray_structure.scatterers().flags_set_grad_u_aniso(
        iselection = selection_aniso.iselection())
