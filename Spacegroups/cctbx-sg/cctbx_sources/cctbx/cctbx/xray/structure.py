from cctbx.xray import ext
from cctbx.xray import structure_factors
from cctbx import miller
from cctbx import crystal
import cctbx.crystal.direct_space_asu
from cctbx import sgtbx
import cctbx.eltbx.xray_scattering
from cctbx import adptbx
from cctbx import eltbx
from cctbx.array_family import flex
import scitbx.math
from scitbx import matrix
from stdlib import math
import types
import sys
import random
from libtbx.utils import count_max
from libtbx.test_utils import approx_equal
from libtbx.itertbx import count
from cctbx.eltbx.neutron import neutron_news_1992_table
from cctbx import eltbx

class scattering_type_registry_params(object):
  def __init__(self,
               custom_dict = None,
               d_min       = None,
               table       = None,
               types_without_a_scattering_contribution = None):
    self.custom_dict = custom_dict
    self.d_min       = d_min
    self.table       = table
    self.types_without_a_scattering_contribution = \
                                        types_without_a_scattering_contribution

class structure(crystal.special_position_settings):

  def __init__(self,
        special_position_settings=None,
        scatterers=None,
        site_symmetry_table=None,
        scattering_type_registry=None,
        crystal_symmetry=None):
    assert [special_position_settings, crystal_symmetry].count(None) == 1
    assert scatterers is not None or site_symmetry_table is None
    if (special_position_settings is None):
      special_position_settings = crystal.special_position_settings(
        crystal_symmetry=crystal_symmetry)
    crystal.special_position_settings._copy_constructor(
      self, special_position_settings)
    self.erase_scatterers()
    self._scattering_type_registry = scattering_type_registry
    if (scatterers is not None):
      self.add_scatterers(
        scatterers=scatterers,
        site_symmetry_table=site_symmetry_table)
    self.scattering_type_registry_params = None

  def _copy_constructor(self, other):
    crystal.special_position_settings._copy_constructor(
      self, special_position_settings)
    self._scatterers = other._scatterers
    self._site_symmetry_table = other._site_symmetry_table
    self._scattering_type_registry = other._scattering_type_registry
    self._scattering_type_registry_is_out_of_date \
      = other._scattering_type_registry_is_out_of_date

  def crystal_symmetry(self):
    return crystal.symmetry(
      unit_cell = self.unit_cell(),
      space_group_info = self.space_group_info())

  def erase_scatterers(self):
    self._scatterers = flex.xray_scatterer()
    self._site_symmetry_table = sgtbx.site_symmetry_table()
    self._scattering_type_registry_is_out_of_date = True

  def deep_copy_scatterers(self):
    cp = structure(self,
      scattering_type_registry=self._scattering_type_registry)
    cp._scatterers = self._scatterers.deep_copy()
    cp._site_symmetry_table = self._site_symmetry_table.deep_copy()
    if (getattr(self, "scatterer_pdb_records", None) is not None):
      cp.scatterer_pdb_records = self.scatterer_pdb_records
    return cp

  def scatterers(self):
    return self._scatterers

  def set_u_iso(self, value = None, values = None, selection = None):
    assert [value, values].count(None) == 1
    s = self._scatterers
    if(selection is None): selection = flex.bool(s.size(), True)
    else:                  assert selection.size() == s.size()
    if(value is not None):
      s.set_u_iso(flex.double(s.size(), value), selection)
    else:
      assert values.size() == s.size()
      s.set_u_iso(values, selection)
    return self

  def set_b_iso(self, value = None, values = None, selection = None):
    assert [value, values].count(None) == 1
    s = self._scatterers
    if(value is not None):
      self.set_u_iso(value = adptbx.b_as_u(value), selection = selection)
    else:
      assert values.size() == s.size()
      b_iso = values
      u_iso_values = b_iso*adptbx.b_as_u(1)
      self.set_u_iso(values = u_iso_values, selection = selection)
    return self

  def random_remove_sites_selection(self, fraction):
    scatterers_size = self._scatterers.size()
    if(abs(fraction-0.0) < 1.e-3):
      return flex.bool(scatterers_size, True)
    if(fraction < 0.01 or fraction > 0.99):
      raise RuntimeError("fraction must be between 0.01 and 0.99.")
    tol = 999.
    selection = None
    l = max(fraction - 0.05, 0.0)
    r = min(fraction + 0.05, 1.0)
    for i in xrange(5):
      while l <= r:
        arr = flex.random_double(scatterers_size)-l
        sel = arr > 0.0
        deleted = float((scatterers_size - sel.count(True))) / scatterers_size
        if abs(fraction - deleted) < tol:
          tol = abs(fraction - deleted)
          selection = sel
        l += 0.0001
    return selection

  def replace_sites_cart(self, new_sites):
    cp = structure(self,
      scattering_type_registry=self._scattering_type_registry)
    new_scatterers = self._scatterers.deep_copy()
    new_scatterers.set_sites(
      self.unit_cell().fractionalize(sites_cart=new_sites))
    cp._scatterers = new_scatterers
    cp._site_symmetry_table = self._site_symmetry_table.deep_copy()
    if(getattr(self, "scatterer_pdb_records", None) is not None):
      cp.scatterer_pdb_records = self.scatterer_pdb_records
    return cp

  def replace_sites_frac(self, new_sites):
    cp = structure(self,
      scattering_type_registry=self._scattering_type_registry)
    new_scatterers = self._scatterers.deep_copy()
    new_scatterers.set_sites(new_sites)
    cp._scatterers = new_scatterers
    cp._site_symmetry_table = self._site_symmetry_table.deep_copy()
    if(getattr(self, "scatterer_pdb_records", None) is not None):
      cp.scatterer_pdb_records = self.scatterer_pdb_records
    return cp

  def adjust_u_iso(self):
    self._scatterers.adjust_u_iso()

  def adjust_occupancy(self, occ_max, occ_min, selection = None):
    if(selection is not None):
      if(("%s"%selection.__class__).count("array_family_flex_ext.size_t") > 0):
        selection = flex.bool(self._scatterers.size(), selection)
    occ = self._scatterers.extract_occupancies()
    sel = (occ >= occ_max)
    occ = occ.set_selected(sel, occ_max)
    sel = (occ <= occ_min)
    occ = occ.set_selected(sel, occ_min)
    if(selection is None):
      self._scatterers.set_occupancies(occ)
    else:
      self._scatterers.set_occupancies(occ, selection)

  def all_selection(self):
    return flex.bool(self._scatterers.size(), True)

  def translate(self, x=0, y=0, z=0):
    sites_cart = self.sites_cart()
    cp = structure(self,
      scattering_type_registry=self._scattering_type_registry)
    new_scatterers = self._scatterers.deep_copy()
    new_scatterers.set_sites(
      self.unit_cell().fractionalize(
        sites_cart=sites_cart+flex.vec3_double(sites_cart.size(),[x,y,z])))
    cp._scatterers = new_scatterers
    cp._site_symmetry_table = self._site_symmetry_table.deep_copy()
    if(getattr(self, "scatterer_pdb_records", None) is not None):
      cp.scatterer_pdb_records = self.scatterer_pdb_records
    return cp

  def mean_distance(self, other, selection = None):
    return flex.mean( self.distances(other = other, selection = selection) )

  def distances(self, other, selection = None):
    if(selection is None): selection = flex.bool(self._scatterers.size(), True)
    s1 = self.sites_cart().select(selection)
    s2 = other.sites_cart().select(selection)
    if(s1.size() != s2.size()):
      raise RuntimeError("Models must of equal size.")
    return flex.sqrt((s1 - s2).dot())

  def max_distance(self, other):
    return flex.max( self.distances(other = other, selection = selection) )

  def min_distance(self, other):
    return flex.min( self.distances(other = other, selection = selection) )

  def scale_adp(self, factor, selection=None):
    if(selection is not None):
      assert selection.size() == self._scatterers.size()
    else:
      selection = flex.bool(self._scatterers.size(), True)
    for sc,sel in zip(self._scatterers, selection):
      if(sc.flags.use()):
        if(sc.flags.use_u_iso()):
          sc.u_iso = sc.u_iso * factor
        if(sc.flags.use_u_aniso()):
          result = []
          for i in xrange(6): result.append(sc.u_star[i] * factor)
          sc.u_star = result

  def shake_adp(self, b_max=None, b_min=None, spread=10.0, aniso_spread=0.1,
             keep_anisotropic=False, random_u_cart_scale=1.0, selection=None):
    assert [b_max, b_min].count(None) in [0,2]
    if([b_max, b_min].count(None) == 0): assert spread == 0.0
    if([b_max, b_min].count(None) == 2):
      u_isos = self._scatterers.extract_u_iso().select(self.use_u_iso())
      if(u_isos.size() > 0):
        b_mean = adptbx.u_as_b(flex.mean(u_isos))
        b_max = int(b_mean + spread)
        b_min = int(max(0.0, b_mean - spread))
    assert b_min <= b_max
    if(selection is not None):
      assert selection.size() == self._scatterers.size()
    else:
      selection = flex.bool(self._scatterers.size(), True)
    is_special_position = self.site_symmetry_table().is_special_position
    for i_seq,sc,sel in zip(count(), self._scatterers, selection):
      if(sel and sc.flags.use()):
        if(sc.flags.use_u_iso() and b_min != b_max):
          r = max(0, random.randrange(b_min, b_max, 1) + random.random())
          sc.u_iso=adptbx.b_as_u(r)
        if(sc.flags.use_u_aniso() and not keep_anisotropic):
          result = []
          for i in xrange(6):
            result.append(sc.u_star[i]+sc.u_star[i]*random.choice(
                                             (-aniso_spread,aniso_spread)))
          if(is_special_position(i_seq=i_seq)):
            result = self.space_group().average_u_star(result)
          sc.u_star = result

  def shake_adp_if_all_equal(self, b_iso_tolerance = 0.1):
    performed = False
    if(self.use_u_aniso().count(True) == 0):
      u_isos = self.extract_u_iso_or_u_equiv()
      b_max  = adptbx.u_as_b(flex.max(u_isos))
      b_min  = adptbx.u_as_b(flex.min(u_isos))
      b_mean = adptbx.u_as_b(flex.mean(u_isos))
      if(abs(b_max - b_mean) <= b_iso_tolerance and
                                      abs(b_min - b_mean) <= b_iso_tolerance):
          self.shake_adp()
          performed = True
    return performed

  def min_u_cart_eigenvalue(self):
    u_carts = self._scatterers.extract_u_total_as_u_cart(self.unit_cell())
    result = flex.double()
    for i_seq, sc in enumerate(self._scatterers):
      if(sc.flags.use_u_iso() or sc.flags.use_u_aniso()):
        assert u_carts[i_seq] != (-1,-1,-1,-1,-1,-1)
        result.append(min(adptbx.eigenvalues(u_carts[i_seq])))
    return flex.min(result)

  def shake_occupancies(self, selection = None):
    s = self._scatterers
    q_new = flex.random_double(s.size())*2.
    if(selection is None):
      s.set_occupancies(q_new)
    else:
      assert selection.size() == s.size()
      s.set_occupancies(q_new, selection)

  def set_occupancies(self, value, selection = None):
    if(selection is not None and isinstance(selection, flex.size_t)):
      selection = flex.bool(self._scatterers.size(), selection)
    s = self._scatterers
    if(hasattr(value, 'size')):
      values = value
      if(selection is not None):
        assert values.size() == selection.size()
    else:
      values = flex.double(s.size(), value)
    if(selection is None):
      s.set_occupancies(values)
    else:
      assert selection.size() == s.size()
      s.set_occupancies(values, selection)

  def coordinate_degrees_of_freedom_counts(self, selection=None):
    assert selection is None or selection.size() == self._scatterers.size()
    site_symmetry_table = self._site_symmetry_table
    assert site_symmetry_table.indices().size() == self._scatterers.size()
    result = {
      0: 0,
      1: 0,
      2: 0,
      3: -site_symmetry_table.special_position_indices().size()}
    if (selection is None):
      result[3] += self._scatterers.size()
    else:
      result[3] += selection.count(True)
    for i in site_symmetry_table.special_position_indices():
      if (selection is None or selection[i]):
        result[site_symmetry_table
                 .get(i).site_constraints()
                   .n_independent_params()] += 1
    return result

  def shake_sites_in_place(self,
        rms_difference=None,
        mean_distance=None,
        selection=None):
    assert [rms_difference, mean_distance].count(None) == 1
    if (rms_difference is not None):
      assert rms_difference >= 0
      target_difference = rms_difference
    else:
      assert mean_distance >= 0
      target_difference = mean_distance
    if (target_difference == 0): return
    assert self._scatterers.size() > 0
    site_symmetry_table = self._site_symmetry_table
    assert site_symmetry_table.indices().size() == self._scatterers.size()
    if (selection is not None):
      assert selection.size() == self._scatterers.size()
      n_variable = selection.count(True)
      if (n_variable == 0):
        raise RuntimeError("No scatterers selected.")
      all = " selected"
    else:
      n_variable = self._scatterers.size()
      all = ""
    selection_fixed = flex.size_t()
    for i in site_symmetry_table.special_position_indices():
      if (site_symmetry_table.get(i)
            .site_constraints()
               .n_independent_params() == 0):
        if (selection is None or selection[i]):
          selection_fixed.append(i)
    n_variable -= selection_fixed.size()
    if (n_variable == 0):
      raise RuntimeError(
        "All%s scatterers are fixed on special positions." % all)
    if (n_variable == self._scatterers.size()):
      selection = None
    scatterers = self._scatterers
    frac = self.unit_cell().fractionalize
    orth = self.unit_cell().orthogonalize
    for i in count_max(assert_less_than=10):
      shifts_cart = flex.vec3_double(flex.random_double(
        size=self._scatterers.size()*3, factor=2) - 1)
      if (selection is not None):
        shifts_cart.set_selected(~selection, (0,0,0))
      shifts_cart.set_selected(selection_fixed, (0,0,0))
      for i in site_symmetry_table.special_position_indices():
        site_frac_orig = matrix.col(scatterers[i].site)
        site_frac = site_symmetry_table.get(i).special_op() \
                  * (site_frac_orig + matrix.col(frac(shifts_cart[i])))
        shifts_cart[i] = orth(matrix.col(site_frac) - site_frac_orig)
      if (rms_difference is not None):
        difference = (flex.sum(shifts_cart.dot()) / n_variable) ** 0.5
      else:
        difference = flex.sum(flex.sqrt(shifts_cart.dot())) / n_variable
      if (difference > 1.e-6): break # to avoid numerical problems
    shifts_cart *= (target_difference / difference)
    self.set_sites_frac(
      self.sites_frac() + self.unit_cell().fractionalize(shifts_cart))

  def b_iso_min_max_mean(self):
    b_isos = self._scatterers.extract_u_iso()/adptbx.b_as_u(1)
    b_min  = flex.min(b_isos)
    b_max  = flex.max(b_isos)
    b_mean = flex.mean(b_isos)
    return b_min, b_max, b_mean

  def n_undefined_multiplicities(self):
    return ext.n_undefined_multiplicities(self._scatterers)

  def sites_frac(self):
    return self._scatterers.extract_sites()

  def use_u_iso(self):
    return self._scatterers.extract_use_u_iso()

  def use_u_aniso(self):
    return self._scatterers.extract_use_u_aniso()

  def set_sites_frac(self, sites_frac):
    assert sites_frac.size() == self._scatterers.size()
    self._scatterers.set_sites(sites_frac)

  def sites_cart(self):
    return self.unit_cell().orthogonalize(sites_frac=self.sites_frac())

  def set_sites_cart(self, sites_cart):
    self.set_sites_frac(self.unit_cell().fractionalize(sites_cart=sites_cart))

  def scattering_types(self):
    result = flex.std_string()
    for sct in self._scatterers.extract_scattering_types():
      result.append(sct.strip().upper())
    return result

  def extract_u_cart_or_u_cart_plus_u_iso(self):
    return self._scatterers.extract_u_cart_or_u_cart_plus_u_iso(
      unit_cell=self.unit_cell())

  def extract_u_iso_or_u_equiv(self):
    return self._scatterers.extract_u_iso_or_u_equiv(
      unit_cell=self.unit_cell())

  def switch_to_neutron_scattering_dictionary(self):
    # XXX First step. In future: better to do bookkeeping and be able to swith
    # XXX back and forth between original scat_dict and neutron.
    # XXX Add regression test.
    neutron_scattering_dict = {}
    reg = self.scattering_type_registry()
    for scattering_type in reg.type_index_pairs_as_dict().keys():
      scattering_info = neutron_news_1992_table(scattering_type, 1)
      b = scattering_info.bound_coh_scatt_length()
      if(b.imag != 0.0): return None
      neutron_scattering_dict[scattering_type] = \
        eltbx.xray_scattering.gaussian(b.real)
    self.scattering_type_registry(custom_dict = neutron_scattering_dict)
    return neutron_scattering_dict

  def hd_selection(self):
    scattering_types = self._scatterers.extract_scattering_types()
    result = flex.bool()
    for sct in scattering_types:
      if(sct.strip() in ['H','D']): result.append(True)
      else: result.append(False)
    return result

  def apply_rigid_body_shift(self, rot, trans, selection = None):
    if(selection is None):
      selection = flex.bool(self._scatterers.size(), True).iselection()
    rbs_obj = self.apply_rigid_body_shift_obj(
                                        sites_cart     = self.sites_cart(),
                                        sites_frac     = self.sites_frac(),
                                        rot            = rot,
                                        trans          = trans,
                                        selection      = selection,
                                        unit_cell      = self.unit_cell(),
                                        atomic_weights = self.atomic_weights())
    self.set_sites_frac(sites_frac = rbs_obj.sites_frac)

  def apply_rigid_body_shift_obj(self,
                                 sites_cart,
                                 sites_frac,
                                 rot,
                                 trans,
                                 selection,
                                 unit_cell,
                                 atomic_weights):
    return ext.apply_rigid_body_shift(sites_cart     = sites_cart,
                                      sites_frac     = sites_frac,
                                      rot            = rot,
                                      trans          = trans,
                                      atomic_weights = atomic_weights,
                                      unit_cell      = unit_cell,
                                      selection      = selection)

  def convert_to_isotropic(self, selection=None):
    if(selection is None):
      self._scatterers.convert_to_isotropic(unit_cell=self.unit_cell())
    else:
      self._scatterers.convert_to_isotropic(unit_cell=self.unit_cell(),
                                            selection=selection)

  def convert_to_anisotropic(self, selection=None):
    if(selection is None):
      self._scatterers.convert_to_anisotropic(unit_cell=self.unit_cell())
    else:
      self._scatterers.convert_to_anisotropic(unit_cell=self.unit_cell(),
                                              selection=selection)

  def show_u_statistics(self, text="", out=None, use_hydrogens=False):
    if(out is None): out = sys.stdout
    size = self._scatterers.size()
    if(use_hydrogens):
      hd_selection = flex.bool(size, True)
    else:
      hd_selection = self.hd_selection()
    epis = 8*math.pi**2
    use_u_aniso = self.use_u_aniso().select(~hd_selection)
    use_u_iso   = self.use_u_iso().select(~hd_selection)
    sel_used = use_u_aniso | use_u_iso
    n_anisotropic = use_u_aniso.count(True)
    n_isotropic   = use_u_iso.count(True)
    ipd = self.is_positive_definite_u().select(~hd_selection)
    npd = ipd.count(True)
    nnpd = ipd.count(False)
    beq = (self.extract_u_iso_or_u_equiv() * epis).select(~hd_selection).select(sel_used)
    bisos = (self.scatterers().extract_u_iso() * epis).select(~hd_selection).select(use_u_iso)
    if(bisos.size() == 0): bisos = beq
    part1 = "|-"+text
    part2 = "-|"
    n = 79 - len(part1+part2)
    print >> out, part1 + "-"*n + part2
    n = 79 - len(part1 + "|")
    print >> out, "| iso = %-5d   aniso = %-5d   pos. def. = %-5d   "\
          "non-pos. def. = %-5d     |"%(n_isotropic,n_anisotropic,npd,nnpd)
    print >> out, "| Total B(isotropic equivalent): min = %-6.2f   "\
                  "max = %-6.2f   mean = %-6.2f"%(flex.min(beq),flex.max(beq),
                  flex.mean(beq))+" "*2+"|"
    print >> out, "| Isotropic B only:              min = %-6.2f   "\
                  "max = %-6.2f   mean = %-6.2f"%(flex.min(bisos),
                  flex.max(bisos),flex.mean(bisos))+" "*2+"|"
    print >> out, "| "+"- "*38+"|"
    print >> out, "|                     Distribution of isotropic B-factors:"\
                  "                    |"
    print >> out, "|            Isotropic                |             Total "\
                  "                    |"
    histogram_1 = flex.histogram(data = bisos, n_slots = 10)
    low_cutoff_1 = histogram_1.data_min()
    histogram_2 = flex.histogram(data = beq, n_slots = 10)
    low_cutoff_2 = histogram_2.data_min()
    for (i_1,n_1),(i_2,n_2) in zip(enumerate(histogram_1.slots()),
                                   enumerate(histogram_2.slots())):
      high_cutoff_1 = histogram_1.data_min() + histogram_1.slot_width()*(i_1+1)
      high_cutoff_2 = histogram_2.data_min() + histogram_2.slot_width()*(i_2+1)
      print >> out, "|  %9.3f -%9.3f:%8d      |    %9.3f -%9.3f:%8d      |" % \
             (low_cutoff_1,high_cutoff_1,n_1,low_cutoff_2,high_cutoff_2,n_2)
      low_cutoff_1 = high_cutoff_1
      low_cutoff_2 = high_cutoff_2
    print >> out, "|" +"-"*77+"|"

  def site_symmetry_table(self):
    return self._site_symmetry_table

  def special_position_indices(self):
    return self._site_symmetry_table.special_position_indices()

  def scattering_type_registry(self,
        custom_dict=None,
        d_min=None,
        table=None,
        types_without_a_scattering_contribution=None):
    assert table in [None, "n_gaussian", "it1992", "wk1995"]
    if (table == "it1992"): assert d_min in [0,None] or d_min >= 1/4.
    if (table == "wk1995"): assert d_min in [0,None] or d_min >= 1/12.
    if (   self._scattering_type_registry_is_out_of_date
        or custom_dict is not None
        or d_min is not None
        or table is not None
        or types_without_a_scattering_contribution is not None):
      self.scattering_type_registry_params = \
          scattering_type_registry_params(
             custom_dict = custom_dict,
             d_min       = d_min,
             table       = table,
             types_without_a_scattering_contribution = \
               types_without_a_scattering_contribution)
      new_dict = {"const": eltbx.xray_scattering.gaussian(1)}
      old_dict = {}
      if (self._scattering_type_registry is not None):
        ugs = self._scattering_type_registry.unique_gaussians_as_list()
        tip = self._scattering_type_registry.type_index_pairs_as_dict()
        for t,i in tip.items():
          if (ugs[i] is not None): old_dict[t] = ugs[i]
        if (d_min is None and table is None):
          new_dict.update(old_dict)
      if (types_without_a_scattering_contribution is not None):
        for t in types_without_a_scattering_contribution:
          new_dict[t] = eltbx.xray_scattering.gaussian(0)
      if (custom_dict is not None):
        new_dict.update(custom_dict)
      if (d_min is None): d_min = 0
      self._scattering_type_registry = ext.scattering_type_registry()
      self._scattering_type_registry.process(self._scatterers)
      for t_undef in self._scattering_type_registry.unassigned_types():
        val = new_dict.get(t_undef, None)
        if (val is None):
          std_lbl = eltbx.xray_scattering.get_standard_label(
            label=t_undef, exact=True, optional=True)
          if (std_lbl is not None):
            if (table == "it1992"):
              val = eltbx.xray_scattering.it1992(std_lbl, True).fetch()
            elif (table == "wk1995"):
              val = eltbx.xray_scattering.wk1995(std_lbl, True).fetch()
            else:
              val = eltbx.xray_scattering.n_gaussian_table_entry(
                std_lbl, d_min, 0).gaussian()
        if (val is None):
          val = old_dict.get(t_undef, None)
        if (val is not None):
          self._scattering_type_registry.assign(t_undef, val)
      self._scattering_type_registry_is_out_of_date = False
    return self._scattering_type_registry

  def __getitem__(self, slice_object):
    assert type(slice_object) == types.SliceType
    assert self.scatterers() is not None
    sel = flex.slice_indices(
      array_size=self._scatterers.size(),
      python_slice=slice_object)
    return structure(
      special_position_settings=self,
      scatterers=self._scatterers.select(sel),
      site_symmetry_table=self._site_symmetry_table.select(sel),
      scattering_type_registry=self._scattering_type_registry)

  def select(self, selection, negate=False):
    assert self.scatterers() is not None
    if (negate): selection = ~selection
    return structure(
      special_position_settings=self,
      scatterers=self._scatterers.select(selection),
      site_symmetry_table=self._site_symmetry_table.select(selection),
      scattering_type_registry=self._scattering_type_registry)

  def select_inplace(self, selection):
    assert self.scatterers() is not None
    self._scatterers          = self._scatterers.select(selection)
    self._site_symmetry_table = self._site_symmetry_table.select(selection)
    self._scattering_type_registry_is_out_of_date = True

  def add_scatterer(self,
        scatterer,
        site_symmetry_ops=None,
        insert_at_index=None):
    if (insert_at_index is None):
      insert_at_index = self._scatterers.size()
    self._scatterers.insert(insert_at_index, scatterer)
    if (site_symmetry_ops is None):
      site_symmetry_ops = self._scatterers[insert_at_index].apply_symmetry(
        unit_cell=self.unit_cell(),
        space_group=self.space_group(),
        min_distance_sym_equiv=self.min_distance_sym_equiv(),
        u_star_tolerance=self.u_star_tolerance(),
        assert_min_distance_sym_equiv=self.assert_min_distance_sym_equiv())
    else:
      self._scatterers[insert_at_index].apply_symmetry(
        site_symmetry_ops=site_symmetry_ops,
        u_star_tolerance=self.u_star_tolerance())
    self._site_symmetry_table.process(
      insert_at_index=insert_at_index, site_symmetry_ops=site_symmetry_ops)
    self._scattering_type_registry_is_out_of_date = True

  def add_scatterers(self, scatterers, site_symmetry_table=None):
    if (site_symmetry_table is None):
      site_symmetry_table = sgtbx.site_symmetry_table()
    else:
      assert site_symmetry_table.indices().size() == scatterers.size()
    self._scatterers.extend(scatterers)
    ext.add_scatterers_ext(
      unit_cell=self.unit_cell(),
      space_group=self.space_group(),
      scatterers=self._scatterers,
      site_symmetry_table=self._site_symmetry_table,
      site_symmetry_table_for_new=site_symmetry_table,
      min_distance_sym_equiv=self.min_distance_sym_equiv(),
      u_star_tolerance=self.u_star_tolerance(),
      assert_min_distance_sym_equiv=self.assert_min_distance_sym_equiv())
    self._scattering_type_registry_is_out_of_date = True

  def concatenate(self, other):
    result = self.deep_copy_scatterers()
    result.add_scatterers(
      scatterers=other._scatterers,
      site_symmetry_table=other._site_symmetry_table)
    return result

  def concatenate_inplace(self, other):
    d1 = self.scattering_type_registry().as_type_gaussian_dict()
    d2 = other.scattering_type_registry().as_type_gaussian_dict()
    for key1, item1 in zip(d1.keys(), d1.items()):
      for key2, item2 in zip(d2.keys(), d2.items()):
        if(key1 == key2):
          i1 = item1[1]
          i2 = item2[1]
          problem_flag = False
          for a1, a2 in zip(i1.array_of_a(), i2.array_of_a()):
            if(not approx_equal(a1, a2)): problem_flag = True
          for b1, b2 in zip(i1.array_of_b(), i2.array_of_b()):
            if(not approx_equal(b1, b2)): problem_flag = True
          if(not approx_equal(i1.c(), i2.c())): problem_flag = True
          if(problem_flag):
            raise RuntimeError("Cannot concatenate: conflicting scatterers")
    self.add_scatterers(scatterers          = other._scatterers,
                        site_symmetry_table = other._site_symmetry_table)
    strp1 = self.scattering_type_registry_params
    strp2 = other.scattering_type_registry_params
    self.scattering_type_registry(
      custom_dict = strp1.custom_dict,
      d_min       = strp1.d_min,
      table       = strp1.table,
      types_without_a_scattering_contribution =
                                strp1.types_without_a_scattering_contribution)
    self.scattering_type_registry(
      custom_dict = strp2.custom_dict,
      d_min       = strp2.d_min,
      table       = strp2.table,
      types_without_a_scattering_contribution =
                                strp2.types_without_a_scattering_contribution)

  def replace_scatterers(self, scatterers, site_symmetry_table="existing"):
    if (site_symmetry_table == "existing"):
      site_symmetry_table = self._site_symmetry_table
    if (site_symmetry_table is not None):
      assert site_symmetry_table.indices().size() == self.scatterers().size()
    self.erase_scatterers()
    self.add_scatterers(
      scatterers=scatterers,
      site_symmetry_table=site_symmetry_table)

  def structure_factors(self, anomalous_flag=None, d_min=None,
                              algorithm=None,
                              cos_sin_table=False,
                              quality_factor=None,
                              u_base=None,
                              b_base=None,
                              wing_cutoff=None):
    if (anomalous_flag is None):
      if (self.scatterers().count_anomalous() != 0):
        anomalous_flag = True
      else:
        anomalous_flag = False
    elif (not anomalous_flag):
      if (self.scatterers().count_anomalous() != 0):
        raise RuntimeError(
            "xray.structure with anomalous scatterers"
          + " but miller.array is non-anomalous.")
    miller_set = miller.build_set(self, anomalous_flag, d_min)
    return structure_factors.from_scatterers(
      crystal_symmetry=self,
      d_min=d_min,
      cos_sin_table=cos_sin_table,
      quality_factor=quality_factor,
      u_base=u_base,
      b_base=b_base,
      wing_cutoff=wing_cutoff)(
        xray_structure=self,
        miller_set=miller_set,
        algorithm=algorithm)

  def show_summary(self, f=None, prefix=""):
    if (f is None): f = sys.stdout
    print >> f, prefix + "Number of scatterers:", \
      self.scatterers().size()
    print >> f, prefix + "At special positions:", \
      self.special_position_indices().size()
    crystal.symmetry.show_summary(self, f=f, prefix=prefix)
    return self

  def show_scatterers(self, f=None):
    if (f is None): f = sys.stdout
    print >> f, ("Label, Scattering, Multiplicity, Coordinates, Occupancy, "
                 "Uiso, Ustar as Uiso")
    for scatterer in self.scatterers():
      scatterer.show(f=f, unit_cell=self.unit_cell())
    return self

  def show_special_position_shifts(self,
        sites_frac_original=None,
        sites_cart_original=None,
        out=None,
        prefix=""):
    self._site_symmetry_table.show_special_position_shifts(
      special_position_settings=self,
      site_labels=self.scatterers().extract_labels(),
      sites_frac_original=sites_frac_original,
      sites_cart_original=sites_cart_original,
      sites_frac_exact=self.scatterers().extract_sites(),
      out=out,
      prefix=prefix)

  def is_positive_definite_u(self, u_cart_tolerance=None):
    if (u_cart_tolerance is None):
      return ext.is_positive_definite_u(
        scatterers=self._scatterers,
        unit_cell=self.unit_cell())
    else:
      return ext.is_positive_definite_u(
        scatterers=self._scatterers,
        unit_cell=self.unit_cell(),
        u_cart_tolerance=u_cart_tolerance)

  def tidy_us(self, u_min = 1.e-6, u_max = adptbx.b_as_u(550.0)):
    assert u_min < u_max
    ext.tidy_us(
      scatterers=self._scatterers,
      unit_cell=self.unit_cell(),
      site_symmetry_table=self._site_symmetry_table,
      u_min=u_min,
      u_max=u_max)

  def shift_us(self, u_shift=None, b_shift=None, selection=None):
    assert [u_shift, b_shift].count(None) == 1
    if (u_shift is None):
      u_shift = adptbx.b_as_u(b_shift)
    if(selection is None):
      ext.shift_us(
        scatterers=self._scatterers,
        unit_cell=self.unit_cell(),
        u_shift=u_shift)
    else:
      ext.shift_us(scatterers = self._scatterers,
                   unit_cell  = self.unit_cell(),
                   u_shift    = u_shift,
                   selection  = selection)

  def shift_occupancies(self, q_shift, selection=None):
    if(selection is not None):
      ext.shift_occupancies(scatterers = self._scatterers,
                            q_shift    = q_shift,
                            selection  = selection)
    else:
      ext.shift_occupancies(scatterers = self._scatterers,
                            q_shift    = q_shift)

  def apply_symmetry_sites(self):
    ext.apply_symmetry_sites(
      site_symmetry_table=self._site_symmetry_table,
      scatterers=self._scatterers)

  def apply_symmetry_u_stars(self):
    ext.apply_symmetry_u_stars(
      site_symmetry_table=self._site_symmetry_table,
      scatterers=self._scatterers,
      u_star_tolerance=self.u_star_tolerance())

  def re_apply_symmetry(self, i_scatterer):
    self._scatterers[i_scatterer].apply_symmetry(
      site_symmetry_ops=self._site_symmetry_table.get(i_scatterer),
      u_star_tolerance=self.u_star_tolerance())

  def apply_special_position_ops_d_target_d_site(self, d_target_d_site):
    for i in self.special_position_indices():
      special_op = self._site_symmetry_table.get(i).special_op()
      r = matrix.sqr(special_op.r().as_double())
      d_target_d_site[i] = (matrix.row(d_target_d_site[i]) * r).elems

  def asymmetric_unit_in_p1(self):
    new_structure = structure(
      crystal.special_position_settings(
        crystal.symmetry.cell_equivalent_p1(self)),
      scattering_type_registry=self._scattering_type_registry)
    new_structure._scatterers = self.scatterers().deep_copy()
    new_structure._site_symmetry_table = self.site_symmetry_table().deep_copy()
    return new_structure

  def change_basis(self, cb_op):
    return structure(
      special_position_settings
        =crystal.special_position_settings.change_basis(self, cb_op),
      scatterers=ext.change_basis(scatterers=self._scatterers, cb_op=cb_op),
      site_symmetry_table=self._site_symmetry_table.change_basis(cb_op=cb_op),
      scattering_type_registry=self._scattering_type_registry)

  def change_hand(self):
    ch_op = self.space_group_info().type().change_of_hand_op()
    return self.change_basis(ch_op)

  def expand_to_p1(self, append_number_to_labels=False):
    return structure(
      special_position_settings
        =crystal.special_position_settings(
          crystal.symmetry.cell_equivalent_p1(self)),
      scatterers=ext.expand_to_p1(
        unit_cell=self.unit_cell(),
        space_group=self.space_group(),
        scatterers=self._scatterers,
        site_symmetry_table=self._site_symmetry_table,
        append_number_to_labels=append_number_to_labels),
      scattering_type_registry=self._scattering_type_registry)

  def sites_mod_positive(self):
    return structure(
      special_position_settings=self,
      scatterers=self.scatterers().sites_mod_positive(),
      scattering_type_registry=self._scattering_type_registry)

  def sites_mod_short(self):
    return structure(
      special_position_settings=self,
      scatterers=self.scatterers().sites_mod_short(),
      scattering_type_registry=self._scattering_type_registry)

  def apply_shift(self, shift, recompute_site_symmetries=False):
    shifted_scatterers = self.scatterers().deep_copy()
    shifted_scatterers.set_sites(shifted_scatterers.extract_sites() + shift)
    if (recompute_site_symmetries):
      site_symmetry_table = None
    else:
      site_symmetry_table = self._site_symmetry_table
    return structure(
      special_position_settings=self,
      scatterers=shifted_scatterers,
      site_symmetry_table=site_symmetry_table,
      scattering_type_registry=self._scattering_type_registry)

  def random_shift_sites(self, max_shift_cart=0.2):
    shifts = flex.vec3_double(
      (flex.random_double(self.scatterers().size()*3)*2-1) * max_shift_cart)
    return self.apply_shift(self.unit_cell().fractionalize(sites_cart=shifts))

  def sort(self, by_value="occupancy", reverse=False):
    assert by_value in ("occupancy",)
    assert reverse in (False, True)
    p = flex.sort_permutation(
      data=self.scatterers().extract_occupancies(),
      reverse=reverse)
    return structure(
      special_position_settings=self,
      scatterers=self._scatterers.select(p),
      site_symmetry_table=self._site_symmetry_table.select(p),
      scattering_type_registry=self._scattering_type_registry)

  def as_emma_model(self):
    from cctbx import euclidean_model_matching as emma
    positions = []
    for scatterer in self.scatterers():
      positions.append(emma.position(scatterer.label, scatterer.site))
    return emma.model(self, positions)

  def atomic_weights(self):
    from cctbx.eltbx import tiny_pse
    result = flex.double()
    for scatterer in self.scatterers():
      std_lbl = eltbx.xray_scattering.get_standard_label(
        label=scatterer.scattering_type, exact=True, optional=True)
      if (std_lbl is None):
        raise RuntimeError(
          "Unknown atomic weight: " + scatterer.scattering_type)
      result.append(tiny_pse.table(std_lbl).weight())
    return result

  def center_of_mass(self, atomic_weights=None):
    if (atomic_weights is None):
      atomic_weights = self.atomic_weights()
    return self.sites_cart().mean_weighted(weights=atomic_weights)

  def principal_axes_of_inertia(self, atomic_weights=None):
    if (atomic_weights is None):
      atomic_weights = self.atomic_weights()
    return scitbx.math.principal_axes_of_inertia(
      points=self.sites_cart(),
      weights=atomic_weights)

  def show_scatterer_flags_summary(self, out=None):
    #XXX move to C++ (after anisotropic_flag is gone)
    if (out is None): out = sys.stdout
    n_use            = 0
    n_use_u_iso      = 0
    n_use_u_aniso    = 0
    n_grad_site      = 0
    n_grad_u_iso     = 0
    n_grad_u_aniso   = 0
    n_grad_occupancy = 0
    n_grad_fp        = 0
    n_grad_fdp       = 0
    n_anisotropic_flag = 0
    for sc in self.scatterers():
        if(sc.flags.use()           ): n_use            += 1
        if(sc.flags.use_u_iso()     ): n_use_u_iso      += 1
        if(sc.flags.use_u_aniso()   ): n_use_u_aniso    += 1
        if(sc.flags.grad_site()     ): n_grad_site      += 1
        if(sc.flags.grad_u_iso()    ): n_grad_u_iso     += 1
        if(sc.flags.grad_u_aniso()  ): n_grad_u_aniso   += 1
        if(sc.flags.grad_occupancy()): n_grad_occupancy += 1
        if(sc.flags.grad_fp()       ): n_grad_fp        += 1
        if(sc.flags.grad_fdp()      ): n_grad_fdp       += 1
        if(sc.anisotropic_flag      ): n_anisotropic_flag += 1
    print >> out, "n_use            = ", n_use
    print >> out, "n_use_u_iso      = ", n_use_u_iso
    print >> out, "n_use_u_aniso    = ", n_use_u_aniso
    print >> out, "n_grad_site      = ", n_grad_site
    print >> out, "n_grad_u_iso     = ", n_grad_u_iso
    print >> out, "n_grad_u_aniso   = ", n_grad_u_aniso
    print >> out, "n_grad_occupancy = ", n_grad_occupancy
    print >> out, "n_grad_fp        = ", n_grad_fp
    print >> out, "n_grad_fdp       = ", n_grad_fdp
    print >> out, "n_anisotropic_flag = ", n_anisotropic_flag
    print >> out, "total number of scatterers = ", self.scatterers().size()

  def n_parameters(self):
    #XXX move to C++ (after anisotropic_flag is gone)
    result_ = 0
    for sc in self.scatterers():
      if(sc.flags.grad_site()     ): result_ +=3
      if(sc.flags.grad_u_iso()   and sc.anisotropic_flag==False): result_ +=1
      if(sc.flags.grad_u_aniso() and sc.anisotropic_flag==True): result_ +=6
      if(sc.flags.grad_occupancy()): result_ +=1
      if(sc.flags.grad_fp()       ): result_ +=1
      if(sc.flags.grad_fdp()      ): result_ +=1
    return result_

  def n_grad_u_iso(self):
    return self.scatterers().n_grad_u_iso()

  def n_grad_u_aniso(self):
    return self.scatterers().n_grad_u_aniso()

  def n_parameters_XXX(self):
    #XXX move to C++ (after anisotropic_flag is gone)
    result_ = 0
    for sc in self.scatterers():
        if(sc.flags.grad_site()): result_ +=3
        if(sc.flags.grad_u_iso() and sc.flags.use_u_iso()): result_ +=1
        if(sc.flags.grad_u_aniso() and sc.flags.use_u_aniso()): result_ +=6
        if(sc.flags.grad_occupancy()): result_ +=1
        if(sc.flags.grad_fp()       ): result_ +=1
        if(sc.flags.grad_fdp()      ): result_ +=1
    return result_

  def asu_mappings(self, buffer_thickness, asu_is_inside_epsilon=None):
    result = crystal.symmetry.asu_mappings(self,
      buffer_thickness=buffer_thickness,
      asu_is_inside_epsilon=asu_is_inside_epsilon)
    ext.asu_mappings_process(
      asu_mappings=result,
      scatterers=self._scatterers,
      site_symmetry_table=self._site_symmetry_table)
    return result

  def pair_asu_table(self,
        distance_cutoff=None,
        asu_mappings_buffer_thickness=None,
        asu_is_inside_epsilon=None):
    assert (distance_cutoff is not None
            or asu_mappings_buffer_thickness is not None)
    if (asu_mappings_buffer_thickness is None):
      asu_mappings_buffer_thickness = distance_cutoff
    asu_mappings = self.asu_mappings(
      buffer_thickness=asu_mappings_buffer_thickness,
      asu_is_inside_epsilon=asu_is_inside_epsilon)
    pair_asu_table = crystal.pair_asu_table(asu_mappings=asu_mappings)
    if (distance_cutoff is not None):
      pair_asu_table.add_all_pairs(distance_cutoff=distance_cutoff)
    return pair_asu_table

  def show_distances(self,
        distance_cutoff=None,
        asu_mappings_buffer_thickness=None,
        asu_is_inside_epsilon=None,
        pair_asu_table=None,
        show_cartesian=False,
        keep_pair_asu_table=False,
        out=None):
    assert [distance_cutoff, pair_asu_table].count(None) == 1
    if (pair_asu_table is None):
      pair_asu_table = self.pair_asu_table(
        distance_cutoff=distance_cutoff,
        asu_mappings_buffer_thickness=asu_mappings_buffer_thickness,
        asu_is_inside_epsilon=asu_is_inside_epsilon)
    return pair_asu_table.show_distances(
      site_labels=self.scatterers().extract_labels(),
      sites_frac=self.sites_frac(),
      show_cartesian=show_cartesian,
      keep_pair_asu_table=keep_pair_asu_table,
      out=out)

  def conservative_pair_proxies(self, bond_sym_table, conserve_angles):
    return conservative_pair_proxies(
      structure=self,
      bond_sym_table=bond_sym_table,
      conserve_angles=conserve_angles)

  def difference_vectors_cart(self, other):
    return other.sites_cart() - self.sites_cart()

  def rms_difference(self, other):
    return self.sites_cart().rms_difference(other.sites_cart())

  def closest_distances(self, sites_frac, distance_cutoff, use_selection=None):
    class map_next_to_model_and_find_closest_distances(object):
      def __init__(self, xray_structure, sites_frac, use_selection):
        asu_mappings = xray_structure.asu_mappings(buffer_thickness =
          distance_cutoff)
        asu_mappings.process_sites_frac(sites_frac, min_distance_sym_equiv =
          xray_structure.min_distance_sym_equiv())
        pair_generator = crystal.neighbors_fast_pair_generator(asu_mappings =
          asu_mappings, distance_cutoff = distance_cutoff)
        n_xray = xray_structure.scatterers().size()
        new_sites_frac = sites_frac.deep_copy()
        smallest_distances_sq = flex.double(sites_frac.size(),
          distance_cutoff**2+1)
        i_seqs = flex.int(sites_frac.size(), -1)
        for pair in pair_generator:
          if(pair.i_seq < n_xray):
            if (pair.j_seq < n_xray): continue
            # i_seq = molecule
            # j_seq = site
            rt_mx_i = asu_mappings.get_rt_mx_i(pair)
            rt_mx_j = asu_mappings.get_rt_mx_j(pair)
            rt_mx_ji = rt_mx_i.inverse().multiply(rt_mx_j)
            i_seq_new_site_frac = pair.j_seq - n_xray
            new_site_frac = rt_mx_ji * sites_frac[i_seq_new_site_frac]
            jn = pair.i_seq
          else:
            if(pair.j_seq >= n_xray): continue
            # i_seq = site
            # j_seq = molecule
            rt_mx_i = asu_mappings.get_rt_mx_i(pair)
            rt_mx_j = asu_mappings.get_rt_mx_j(pair)
            rt_mx_ij = rt_mx_j.inverse().multiply(rt_mx_i)
            i_seq_new_site_frac = pair.i_seq - n_xray
            new_site_frac = rt_mx_ij * sites_frac[i_seq_new_site_frac]
            jn = pair.j_seq
          if(use_selection[jn]):
            if(smallest_distances_sq[i_seq_new_site_frac] >= pair.dist_sq):
              smallest_distances_sq[i_seq_new_site_frac] = pair.dist_sq
              new_sites_frac[i_seq_new_site_frac] = new_site_frac
              i_seqs[i_seq_new_site_frac] = jn
        self.remove_selection = smallest_distances_sq > distance_cutoff**2
        self.sites_frac = new_sites_frac
        self.smallest_distances = flex.sqrt(
          smallest_distances_sq).set_selected(self.remove_selection, -1)
        self.smallest_distances_sq = smallest_distances_sq.set_selected(
          self.remove_selection, -1)
        self.i_seqs = i_seqs
    if(use_selection is not None):
      assert use_selection.size() == self._scatterers.size()
    else:
      use_selection = flex.bool(self._scatterers.size(), True)
    result = map_next_to_model_and_find_closest_distances(
      xray_structure = self, sites_frac = sites_frac, use_selection =
      use_selection)
    return result

  def orthorhombic_unit_cell_around_centered_scatterers(self, buffer_size):
    sites_cart = self.sites_cart()
    sites_cart_min = sites_cart.min()
    abc = [2*buffer_size+a-i for i,a in zip(sites_cart_min,sites_cart.max())]
    sites_cart += [buffer_size-i for i in sites_cart_min]
    result = structure(
      crystal_symmetry=crystal.symmetry(
        unit_cell=abc,
        space_group_symbol="P1"),
      scatterers=self.scatterers())
    result.set_sites_cart(sites_cart)
    return result

  def cubic_unit_cell_around_centered_scatterers(self, buffer_size):
    sites_cart = self.sites_cart()
    sites_cart_min = sites_cart.min()
    span = [a-i for i,a in zip(sites_cart_min, sites_cart.max())]
    a = max(span) + 2 * buffer_size
    sites_cart += [(a-s)/2-i for i,s in zip(sites_cart_min, span)]
    result = structure(
      crystal_symmetry=crystal.symmetry(
        unit_cell=[a,a,a],
        space_group_symbol="P1"),
      scatterers=self.scatterers())
    result.set_sites_cart(sites_cart)
    return result

  def as_pdb_file(self,
        remark=None,
        remarks=[],
        fractional_coordinates=False,
        res_name=None, # XXX backward compatibility 2008-05-13
        connect=None,
        resname=None):
    assert res_name is None or resname is None
    if (resname is None): resname = res_name
    import iotbx.pdb.xray_structure
    return iotbx.pdb.xray_structure.as_pdb_file(
      self=self,
      remark=remark,
      remarks=remarks,
      fractional_coordinates=fractional_coordinates,
      resname=resname,
      connect=connect)

class conservative_pair_proxies(object):

  def __init__(self, structure, bond_sym_table, conserve_angles):
    from cctbx import geometry_restraints
    buffer_thickness = flex.max_default(
      values=crystal.get_distances(
        pair_sym_table=bond_sym_table,
        orthogonalization_matrix
          =structure.unit_cell().orthogonalization_matrix(),
        sites_frac=structure.sites_frac()),
      default=1)
    if (conserve_angles): buffer_thickness *= 2
    asu_mappings = structure.asu_mappings(buffer_thickness=buffer_thickness)
    bond_pair_asu_table = crystal.pair_asu_table(asu_mappings=asu_mappings)
    bond_pair_asu_table.add_pair_sym_table(sym_table=bond_sym_table)
    self.bond = geometry_restraints.bond_sorted_asu_proxies(
      pair_asu_table=bond_pair_asu_table)
    if (not conserve_angles):
      self.angle = None
    else:
      angle_pair_asu_table = bond_pair_asu_table.angle_pair_asu_table()
      self.angle = geometry_restraints.bond_sorted_asu_proxies(
        pair_asu_table=angle_pair_asu_table)
