from __future__ import generators
from __future__ import division
from cctbx import uctbx

import boost.python
ext = boost.python.import_ext("cctbx_sgtbx_ext")
from cctbx_sgtbx_ext import *

class empty: pass

from cctbx.array_family import flex
from scitbx import matrix
import scitbx.math
from boost import rational
import random
import sys

class _space_group(boost.python.injector, ext.space_group):

  def smx(self):
    for i_smx in xrange(self.n_smx()):
      yield self(i_smx)

  def ltr(self):
    for i in xrange(self.n_ltr()):
      yield self(i,0,0).t()

  def adp_constraints(self):
    return tensor_rank_2_constraints(space_group=self, reciprocal_space=True)

  def cartesian_adp_constraints(self, unit_cell):
    return tensor_rank_2_cartesian_constraints(unit_cell, self)


class any_generator_set(object):

  def __init__(self, space_group,
               z2c_r_den=cb_r_den, z2c_t_den=cb_t_den):
    self.space_group = space_group
    gen_set = ext.any_generator_set(space_group=space_group,
                                    z2p_r_den=cb_r_den,
                                    z2p_t_den=cb_t_den)
    gen_set.set_primitive()
    self.non_primitive_generators = gen_set.z_gen()
    self.primitive_generators = gen_set.p_gen()


class space_group_info(object):

  __safe_for_unpickling__ = True

  def __init__(self,
        symbol=None,
        table_id=None,
        group=None,
        number=None,
        space_group_t_den=None):
    assert [symbol, group, number].count(None) >= 2
    if (number is not None):
      symbol = str(number)
    if (symbol is None):
      assert table_id is None
      if (space_group_t_den is not None):
        assert space_group_t_den == group.t_den()
      self._group = group
    else:
      assert group is None
      if (table_id is None):
        symbols = space_group_symbols(symbol)
      else:
        if (isinstance(symbol, int)): symbol = str(symbol)
        symbols = space_group_symbols(symbol, table_id)
      if (space_group_t_den is None):
        self._group = space_group(
          space_group_symbols=symbols)
      else:
        self._group = space_group(
          space_group_symbols=symbols, t_den=space_group_t_den)
    if (self._group is not None):
      self._group.make_tidy()
    self._space_group_info_cache = empty()

  def _copy_constructor(self, other):
    self._group = other._group
    self._space_group_info_cache = other._space_group_info_cache

  def __getstate__(self):
    return (self._group,)

  def __setstate__(self, state):
    self._group = state[0]
    self._space_group_info_cache = empty()

  def group(self):
    return self._group

  def type(self, tidy_cb_op=True, r_den=None, t_den=None):
    cache = self._space_group_info_cache
    cache_type = getattr(cache, "_type", None)
    if (cache_type is None):
      f = self._group.t_den() // sg_t_den
      if (r_den is None): r_den = f * cb_r_den
      if (t_den is None): t_den = f * cb_t_den
    else:
      cache_type_params = cache._type_params
      if (r_den is None): r_den = cache_type_params[1]
      if (t_den is None): t_den = cache_type_params[2]
    type_params = (tidy_cb_op, r_den, t_den)
    if (cache_type is None or cache_type_params != type_params):
      cache._type_params = type_params
      cache._type = cache_type = space_group_type(*(self._group,)+type_params)
    return cache_type

  def any_generator_set(self):
    cache = self._space_group_info_cache
    try:
      return cache._generators
    except AttributeError:
      cache._generators = any_generator_set(self.group())
      return cache._generators

  def reciprocal_space_asu(self):
    cache = self._space_group_info_cache
    if (not hasattr(cache, "_reciprocal_space_asu")):
      cache._reciprocal_space_asu = reciprocal_space_asu(self.type())
    return cache._reciprocal_space_asu

  def direct_space_asu(self):
    from cctbx.sgtbx.direct_space_asu import reference_table
    cache = self._space_group_info_cache
    if (not hasattr(cache, "_direct_space_asu")):
      reference_asu = reference_table.get_asu(self.type().number())
      cache._direct_space_asu = reference_asu.change_basis(
        self.change_of_basis_op_to_reference_setting().inverse())
    return cache._direct_space_asu

  def brick(self):
    cache = self._space_group_info_cache
    if (not hasattr(cache, "_brick")):
      cache._brick = brick(self.type())
    return cache._brick

  def wyckoff_table(self):
    cache = self._space_group_info_cache
    if (not hasattr(cache, "_wyckoff_table")):
      cache._wyckoff_table = wyckoff_table(self.type())
    return cache._wyckoff_table

  def structure_seminvariants(self):
    cache = self._space_group_info_cache
    if (not hasattr(cache, "_structure_seminvariants")):
      cache._structure_seminvariants = structure_seminvariants(self._group)
    return cache._structure_seminvariants

  def reference_setting(self):
    cache = self._space_group_info_cache
    if (not hasattr(cache, "_reference_setting")):
      cache._reference_setting = space_group_info(symbol=self.type().number())
    return cache._reference_setting

  def change_of_basis_op_to_reference_setting(self):
    return self.type().cb_op()

  def is_reference_setting(self):
    return self.change_of_basis_op_to_reference_setting().is_identity_op()

  def as_reference_setting(self):
    return self.change_basis(self.change_of_basis_op_to_reference_setting())

  def change_basis(self, cb_op):
    if (isinstance(cb_op, str)):
      cb_op = change_of_basis_op(cb_op)
    return space_group_info(group=self.group().change_basis(cb_op))

  def change_of_basis_op_to_other_hand(self):
    return self.type().change_of_hand_op()

  def change_hand(self):
    return self.change_basis(self.change_of_basis_op_to_other_hand())

  def primitive_setting(self):
    return self.change_basis(self.group().z2p_op())

  def reflection_intensity_equivalent_groups(self, anomalous_flag=True):
    result = []
    reference_group = self.reference_setting().group()
    reference_crystal_system = reference_group.crystal_system()
    reference_reflection_intensity_group = reference_group \
      .build_derived_reflection_intensity_group(anomalous_flag=anomalous_flag)
    reference_reflection_intensity_group.make_tidy()
    for space_group_symbols in space_group_symbol_iterator():
      if (space_group_symbols.crystal_system() != reference_crystal_system):
        continue
      other_sg = space_group(space_group_symbols)
      if (other_sg.build_derived_reflection_intensity_group(
            anomalous_flag=anomalous_flag)
          == reference_reflection_intensity_group):
        result.append(other_sg.change_basis(
          self.change_of_basis_op_to_reference_setting().inverse()))
    return result

  def __str__(self):
    cache = self._space_group_info_cache
    if (not hasattr(cache, "_lookup_symbol")):
      cache._lookup_symbol = self.type().lookup_symbol()
    return cache._lookup_symbol

  def symbol_and_number(self):
    return "%s (No. %d)" % (str(self), self.type().number())

  def show_summary(self, f=None, prefix="Space group: "):
    if (f is None): f = sys.stdout
    print >> f, "%s%s" % (prefix, self.symbol_and_number())

  def subtract_continuous_allowed_origin_shifts(self, translation_frac):
    cb_op = self.change_of_basis_op_to_reference_setting()
    return cb_op.c_inv() * self.reference_setting().structure_seminvariants() \
      .subtract_principal_continuous_shifts(
        translation=cb_op.c() * translation_frac)

  def is_allowed_origin_shift(self, shift, tolerance):
    from libtbx.math_utils import iround
    is_ltr = lambda v: max([ abs(x-iround(x)) for x in v ]) < tolerance
    z2p_op = self.group().z2p_op()
    primitive_self = self.change_basis(z2p_op)
    primitive_shift = z2p_op.c() * shift
    if is_ltr(primitive_shift):
      return True
    for s in primitive_self.any_generator_set().primitive_generators:
      w_m_i = s.r().minus_unit_mx()
      t = w_m_i * primitive_shift
      if not is_ltr(t):
        return False
    else:
      return True

  def any_compatible_unit_cell(self, volume=None, asu_volume=None):
    assert [volume, asu_volume].count(None) == 1
    if (volume is None):
      volume = asu_volume * self.group().order_z()
    sg_number = self.type().number()
    if   (sg_number <   3):
      params = (1., 1.3, 1.7, 83, 109, 129)
    elif (sg_number <  16):
      params = (1., 1.3, 1.7, 90, 109, 90)
    elif (sg_number <  75):
      params = (1., 1.3, 1.7, 90, 90, 90)
    elif (sg_number < 143):
      params = (1., 1., 1.7, 90, 90, 90)
    elif (sg_number < 195):
      params = (1., 1., 1.7, 90, 90, 120)
    else:
      params = (1., 1., 1., 90, 90, 90)
    unit_cell = self.change_of_basis_op_to_reference_setting().inverse().apply(
      uctbx.unit_cell(params))
    f = (volume / unit_cell.volume())**(1/3.)
    params = list(unit_cell.parameters())
    for i in xrange(3): params[i] *= f
    return uctbx.unit_cell(params)

  def any_compatible_crystal_symmetry(self, volume=None, asu_volume=None):
    from cctbx import crystal
    return crystal.symmetry(
      unit_cell=self.any_compatible_unit_cell(
        volume=volume, asu_volume=asu_volume),
      space_group_info=self)

def reference_space_group_infos():
  for number in xrange(1,230+1):
    yield space_group_info(number=number)

class _tr_vec(boost.python.injector, tr_vec):

  def as_rational(self):
    return matrix.col(rational.vector(self.num(), self.den()))

class le_page_1982_delta_details:

  def __init__(self, reduced_cell, rot_mx, deg=False):
    orth = matrix.sqr(reduced_cell.orthogonalization_matrix())
    frac = matrix.sqr(reduced_cell.fractionalization_matrix())
    r_info = rot_mx.info()
    self.type = r_info.type()
    self.u = rot_mx.info().ev()
    self.h = rot_mx.transpose().info().ev()
    self.t = orth * matrix.col(self.u)
    self.tau = matrix.row(self.h) * frac
    if (abs(self.type) == 1):
      self.delta = 0.0
    else:
      self.delta = self.t.accute_angle(self.tau, deg=deg)

class _rot_mx(boost.python.injector, rot_mx):

  def as_rational(self):
    return matrix.sqr(rational.vector(self.num(), self.den()))

  def le_page_1982_delta_details(self, reduced_cell, deg=False):
    return le_page_1982_delta_details(
      reduced_cell=reduced_cell, rot_mx=self, deg=deg)

  def le_page_1982_delta(self, reduced_cell, deg=False):
    return self.le_page_1982_delta_details(
      reduced_cell=reduced_cell, deg=deg).delta

  def lebedev_2005_perturbation(self, reduced_cell):
    s = matrix.sym(sym_mat3=reduced_cell.metrical_matrix())
    m = self.as_rational().as_float()
    r = m.transpose() * s * m
    sirms = s.inverse() * (r-s)
    return ((sirms * sirms).trace() / 12)**0.5

class _rt_mx(boost.python.injector, rt_mx):

  def as_rational(self):
    return matrix.rt((self.r().as_rational(), self.t().as_rational()))

  def as_4x4_rational(self):
    r = self.r().as_rational().elems
    t = self.t().as_rational().elems
    zero = rational.int(0)
    one = rational.int(1)
    return matrix.rec((
      r[0], r[1], r[2], t[0],
      r[3], r[4], r[5], t[1],
      r[6], r[7], r[8], t[2],
      zero, zero, zero,  one), (4, 4))

class _search_symmetry_flags(boost.python.injector, ext.search_symmetry_flags):

  def show_summary(self, f=None):
    if (f is None): f = sys.stdout
    print >> f, "use_space_group_symmetry:", self.use_space_group_symmetry()
    print >> f, "use_space_group_ltr:", self.use_space_group_ltr()
    print >> f, "use_normalizer_k2l:", self.use_normalizer_k2l()
    print >> f, "use_normalizer_l2n:", self.use_normalizer_l2n()
    print >> f, "use_seminvariants:", self.use_seminvariants()

class _rt_mx(boost.python.injector, ext.rt_mx):

  def __getinitargs__(self):
    return (flex.int(self.as_int_array() + (self.r().den(), self.t().den())),)

class _site_symmetry_ops(boost.python.injector, ext.site_symmetry_ops):

  def __getinitargs__(self):
    return (self.multiplicity(), self.special_op(), self.matrices())

class _site_symmetry_table(boost.python.injector, ext.site_symmetry_table):

  def __getinitargs__(self):
    return (self.indices(), self.table(), self.special_position_indices())

  def apply_symmetry_sites(self, unit_cell, sites_cart):
    sites_frac = unit_cell.fractionalize(sites_cart=sites_cart)
    for i_seq in self.special_position_indices():
      sites_frac[i_seq] = self.get(i_seq=i_seq).special_op() \
                        * sites_frac[i_seq]
    return unit_cell.orthogonalize(sites_frac=sites_frac)

  def show_special_position_shifts(self,
        special_position_settings,
        site_labels,
        sites_frac_original=None,
        sites_cart_original=None,
        sites_frac_exact=None,
        sites_cart_exact=None,
        out=None,
        prefix=""):
    assert [sites_frac_original, sites_cart_original].count(None) == 1
    assert [sites_frac_exact, sites_cart_exact].count(None) == 1
    if (out is None): out = sys.stdout
    print >> out, prefix + "Number of sites at special positions:", \
      self.special_position_indices().size()
    if (self.special_position_indices().size() > 0):
      label_len = 5
      for i_seq in self.special_position_indices():
        label_len = max(label_len, len(site_labels[i_seq]))
      label_fmt = "%%-%ds"%label_len
      print >> out, prefix \
        + "  Minimum distance between symmetrically equivalent sites: %.4g" % (
        special_position_settings.min_distance_sym_equiv())
      print >> out, prefix + "  " + label_fmt%"Label" \
        + "   Mult   Shift    Fractional coordinates"
      uc = special_position_settings.unit_cell()
      if (sites_frac_original is None):
        sites_frac_original = uc.fractionalize(sites_cart=sites_cart_original)
      if (sites_frac_exact is None):
        sites_frac_exact = uc.fractionalize(sites_cart=sites_cart_exact)
      for i_seq in self.special_position_indices():
        so = sites_frac_original[i_seq]
        se = sites_frac_exact[i_seq]
        special_ops = self.get(i_seq=i_seq)
        print >> out, prefix + "  " + label_fmt%site_labels[i_seq] \
          + "  %4d  %7.3f (%8.4f %8.4f %8.4f) original" % (
          (special_ops.multiplicity(), uc.distance(so, se)) + so)
        print >> out, prefix + label_fmt%"" \
          + "   site sym %-6s"%special_position_settings.site_symmetry(se) \
              .point_group_type() \
          + "(%8.4f %8.4f %8.4f) exact"%se
        s = str(special_ops.special_op())
        print >> out, prefix + label_fmt%"" + " "*(18+max(0,(26-len(s))//2)), s

class _wyckoff_table(boost.python.injector, wyckoff_table):

  def random_site_symmetry(self,
        special_position_settings,
        i_position,
        unit_shift_range=(-5,6),
        tolerance=1.e-8):
    position = self.position(i_position)
    run_away_counter = 0
    while 1:
      run_away_counter += 1
      assert run_away_counter < 1000
      site = position.special_op() * [random.random() for i in xrange(3)]
      if (unit_shift_range is not None):
        site = [x + random.randrange(*unit_shift_range) for x in site]
      site_symmetry = special_position_settings.site_symmetry(site)
      if (site_symmetry.distance_moved() < tolerance):
        assert site_symmetry.multiplicity() == position.multiplicity()
        return site_symmetry
