from __future__ import division
from __future__ import generators
import cctbx.sgtbx

import boost.python
ext = boost.python.import_ext("cctbx_miller_ext")
from cctbx_miller_ext import *

from cctbx import crystal
from cctbx import maptbx
from cctbx import sgtbx
from cctbx.sgtbx import lattice_symmetry
from cctbx import uctbx
from cctbx.array_family import flex
from scitbx import fftpack
import scitbx.math
from libtbx.math_utils import iround
from libtbx import complex_math
from scitbx.python_utils.misc import store
from libtbx.itertbx import count, izip
from libtbx import adopt_init_args
from libtbx.str_utils import show_string
from libtbx.utils import Sorry, Keep, plural_s
from libtbx import group_args
import random
import math
import types
import sys

def _slice_or_none(array, slice_object):
  assert type(slice_object) == types.SliceType
  if (array is None): return None
  return array.__getitem__(slice_object)

class binner(ext.binner):

  def __init__(self, binning, miller_set):
    ext.binner.__init__(self, binning, miller_set.indices())
    self.space_group_info = miller_set.space_group_info()
    self.anomalous_flag = miller_set.anomalous_flag()
    if (miller_set.indices().size() == 0):
      self._completeness_d_min = binning.d_min()
    else:
      self._completeness_d_min = miller_set.d_min()
    self._counts_given = None
    self._counts_complete = None
    self._have_format_strings = False

  def __getinitargs__(self):
    return (
      binning(
        self.unit_cell(),
        self.limits()),
      set(
        crystal_symmetry=crystal.symmetry(
          unit_cell=self.unit_cell(),
          space_group_info=self.space_group_info),
        indices=self.miller_indices(),
        anomalous_flag=self.anomalous_flag))

  def counts_given(self):
    if (self._counts_given is None):
      self._counts_given = []
      for i_bin in self.range_all():
        self._counts_given.append(self.count(i_bin))
    return self._counts_given

  def counts_complete(self,
        include_centric=True,
        include_acentric=True,
        d_min_tolerance=1.e-6):
    if (self._counts_complete is None):
      assert self.anomalous_flag in (False, True)
      complete_set = build_set(
        crystal_symmetry=crystal.symmetry(
          unit_cell=self.unit_cell(),
          space_group_info=self.space_group_info),
        anomalous_flag=self.anomalous_flag,
        d_min=self._completeness_d_min*(1-d_min_tolerance))
      if (not include_centric):
        complete_set = complete_set.select_acentric()
      if (not include_acentric):
        complete_set = complete_set.select_centric()
      binner_complete = binner(binning=self, miller_set=complete_set)
      self._counts_complete = binner_complete.counts_given()
    return self._counts_complete

  def n_bin_d_too_large(self):
    return self.array_indices(self.i_bin_d_too_large()).size()

  def n_bin_d_too_small(self):
    return self.array_indices(self.i_bin_d_too_small()).size()

  def n_bin_d_too_large_or_small(self):
    return self.n_bin_d_too_large() + self.n_bin_d_too_small()

  def _setup_format_strings(self):
    if (not self._have_format_strings):
      self._have_format_strings = True
      n = max(2, len(str(self.n_bins_used())))
      self.fmt_bin = "bin %%%dd:"%n
      self.fmt_unused = " "*(4+n+1-7) + "unused:"
      n = len("%.4f" % self.bin_d_range(1)[0])
      self.fmt_d = "%%%d.4f"%n
      blank_d = " "*n
      self.fmt_d_range_first = " ".join([blank_d,    "-", self.fmt_d])
      self.fmt_d_range_used  = " ".join([self.fmt_d, "-", self.fmt_d])
      self.fmt_d_range_last  = " ".join([self.fmt_d, "-", blank_d])
      self.fmt_counts_given = "%%%dd"%len(str(max(self.counts_given())))
      self.fmt_counts_complete = "%%-%dd"%len(str(max(self.counts_complete())))
      self.fmt_both_counts \
        = "["+self.fmt_counts_given+"/"+self.fmt_counts_complete+"]"

  def bin_legend(self,
        i_bin,
        show_bin_number=True,
        show_d_range=True,
        show_counts=True):
    self._setup_format_strings()
    is_first = (i_bin == self.i_bin_d_too_large())
    is_last = (i_bin == self.i_bin_d_too_small())
    result = []
    if (show_bin_number):
      if (is_first or is_last):
        result.append(self.fmt_unused)
      else:
        result.append(self.fmt_bin % i_bin)
    bin_d_range = self.bin_d_range(i_bin)
    if (show_d_range):
      if (is_first):
        result.append(self.fmt_d_range_first % bin_d_range[1])
      elif (is_last):
        result.append(self.fmt_d_range_last % bin_d_range[0])
      else:
        result.append(self.fmt_d_range_used % bin_d_range)
    if (show_counts):
      result.append(self.fmt_both_counts % (
        self._counts_given[i_bin], self._counts_complete[i_bin]))
    return " ".join(result)

  def show_summary(self,
        show_bin_number=True,
        show_d_range=True,
        show_counts=True,
        f=None,
        prefix=""):
    if (f is None): f = sys.stdout
    for i_bin in self.range_all():
      print >> f, prefix + self.bin_legend(
        i_bin=i_bin,
        show_bin_number=show_bin_number,
        show_d_range=show_d_range,
        show_counts=show_counts)

  def show_data(self,
        data,
        data_fmt=None,
        show_bin_number=True,
        show_d_range=True,
        show_counts=True,
        show_unused=True,
        f=None,
        prefix=""):
    assert len(data) == self.n_bins_all()
    if (f is None): f = sys.stdout
    if (show_unused):
      i_bins = self.range_all()
    else:
      i_bins = self.range_used()
    legend = None
    for i_bin in i_bins:
      legend = self.bin_legend(
        i_bin=i_bin,
        show_bin_number=show_bin_number,
        show_d_range=show_d_range,
        show_counts=show_counts)
      print >> f, prefix + legend,
      if (data[i_bin] is not None):
        if (isinstance(data[i_bin], str) or data_fmt is None):
          print >> f, data[i_bin],
        elif (isinstance(data_fmt, str)):
          print >> f, data_fmt % data[i_bin],
        else:
          s = data_fmt(binner=self, i_bin=i_bin, data=data)
          if (s is not None and len(s) > 0): print >> f, s,
      print >> f
    if (legend is not None): return len(legend)
    return None

class binned_data(object):

  def __init__(self, binner, data, data_fmt=None):
    self.binner = binner
    self.data = data
    self.data_fmt = data_fmt

  def show(self,
        data_fmt=None,
        show_bin_number=True,
        show_d_range=True,
        show_counts=True,
        show_unused=True,
        f=None,
        prefix=""):
    if (data_fmt is None): data_fmt = self.data_fmt
    return self.binner.show_data(
      data=self.data,
      data_fmt=data_fmt,
      show_bin_number=show_bin_number,
      show_d_range=show_d_range,
      show_counts=show_counts,
      show_unused=show_unused,
      f=f,
      prefix=prefix)

def make_lookup_dict(indices): # XXX push to C++
  result = {}
  for i in xrange(len(indices)):
    result[indices[i]] = i
  return result

class set(crystal.symmetry):

  def __init__(self, crystal_symmetry, indices, anomalous_flag=None):
    assert anomalous_flag in (None, False, True)
    crystal.symmetry._copy_constructor(self, crystal_symmetry)
    self._indices = indices
    self._anomalous_flag = anomalous_flag
    self._binner = None

  def _copy_constructor(self, other):
    crystal.symmetry._copy_constructor(self, other)
    self._indices = other._indices
    self._anomalous_flag = other._anomalous_flag
    self._binner = None

  def indices(self):
    return self._indices

  def anomalous_flag(self):
    return self._anomalous_flag

  def size(self):
    return self.indices().size()

  def copy(self):
    return set(
      crystal_symmetry=self,
      indices=self._indices,
      anomalous_flag=self._anomalous_flag)

  def deep_copy(self):
    unit_cell = self.unit_cell()
    if (unit_cell is not None):
      unit_cell = uctbx.unit_cell(parameters=unit_cell.parameters())
    if (self.space_group_info() is None):
      space_group_symbol = None
    else:
      space_group_symbol = str(self.space_group_info())
    return set(
      crystal_symmetry=crystal.symmetry(
        unit_cell=unit_cell,
        space_group_symbol=space_group_symbol),
      indices=self.indices().deep_copy(),
      anomalous_flag=self.anomalous_flag())

  def customized_copy(self,
        crystal_symmetry=Keep,
        indices=Keep,
        anomalous_flag=Keep,
        unit_cell=Keep,
        space_group_info=Keep):
    if (crystal_symmetry is Keep): crystal_symmetry = self
    if (indices is Keep): indices = self.indices()
    if (anomalous_flag is Keep): anomalous_flag = self.anomalous_flag()
    crystal_symmetry = crystal.symmetry.customized_copy(crystal_symmetry,
      unit_cell=unit_cell,
      space_group_info=space_group_info)
    return set(
      crystal_symmetry=crystal_symmetry,
      indices=indices,
      anomalous_flag=anomalous_flag)

  def array(self, data=None, sigmas=None):
    if (data is not None):
      assert data.size() == self._indices.size()
    if (sigmas is not None):
      assert sigmas.size() == self._indices.size()
    return array(miller_set=self, data=data, sigmas=sigmas)

  def __getitem__(self, slice_object):
    assert type(slice_object) == types.SliceType
    assert self.indices() is not None
    return set(
      crystal_symmetry=self,
      indices=self.indices().__getitem__(slice_object),
      anomalous_flag=self.anomalous_flag())

  def show_summary(self, f=None, prefix=""):
    "Minimal Miller set summary"
    if (f is None): f = sys.stdout
    print >> f, prefix + "Number of Miller indices:", len(self.indices())
    print >> f, prefix + "Anomalous flag:", self.anomalous_flag()
    crystal.symmetry.show_summary(self, f=f, prefix=prefix)
    return self

  def show_comprehensive_summary(self, f=None, prefix=""):
    "Comprehensive Miller set or array summary"
    if (f is None): f = sys.stdout
    self.show_summary(f=f, prefix=prefix)
    no_sys_abs = self.copy()
    if (self.space_group_info() is not None):
      sys_absent_flags = self.sys_absent_flags().data()
      n_sys_abs = sys_absent_flags.count(True)
      print >> f, prefix + "Systematic absences:", n_sys_abs
      if (n_sys_abs != 0):
        no_sys_abs = self.select(selection=~sys_absent_flags)
        print >> f, prefix + "Systematic absences not included in following:"
      n_centric = no_sys_abs.centric_flags().data().count(True)
      print >> f, prefix + "Centric reflections:", n_centric
    if (self.unit_cell() is not None):
      print >> f, prefix + "Resolution range: %.6g %.6g" % (
        no_sys_abs.resolution_range())
      if (self.space_group_info() is not None and self.indices().size() > 0):
        no_sys_abs.setup_binner(n_bins=1)
        completeness_d_max_d_min = no_sys_abs.completeness(use_binning=True)
        binner = completeness_d_max_d_min.binner
        assert binner.counts_given()[0] == 0
        assert binner.counts_given()[2] == 0
        n_obs = binner.counts_given()[1]
        n_complete = binner.counts_complete()[1]
        if (n_complete != 0):
          print >> f, prefix + "Completeness in resolution range: %.6g" % (
            n_obs / n_complete)
        n_complete += binner.counts_complete()[0]
        if (n_complete != 0):
          print >> f, prefix + "Completeness with d_max=infinity: %.6g" % (
            n_obs / n_complete)
    if (self.space_group_info() is not None and no_sys_abs.anomalous_flag()):
      asu, matches = no_sys_abs.match_bijvoet_mates()
      print >> f, prefix + "Bijvoet pairs:", matches.pairs().size()
      print >> f, prefix + "Lone Bijvoet mates:", \
        matches.n_singles() - n_centric
      if (isinstance(self, array) and self.is_real_array()):
        print >> f, prefix + "Anomalous signal: %.4f" % (
          no_sys_abs.anomalous_signal())
    return self

  def reflection_intensity_symmetry(self):
    assert self.anomalous_flag() is False or self.anomalous_flag() is True
    return self.customized_copy(
      crystal_symmetry=crystal.symmetry.reflection_intensity_symmetry(self,
        anomalous_flag=self.anomalous_flag()))

  def sys_absent_flags(self, integral_only=False):
    effective_group = self.space_group()
    if (integral_only):
      effective_group = effective_group \
        .build_derived_reflection_intensity_group(
          anomalous_flag=self.anomalous_flag())
    return self.array(data=effective_group.is_sys_absent(self.indices()))

  def centric_flags(self):
    return array(
      self,
      self.space_group().is_centric(self.indices()))

  def multiplicities(self):
    return array(
      self,
      self.space_group().multiplicity(self.indices(), self.anomalous_flag()))

  def epsilons(self):
    return array(
      self,
      self.space_group().epsilon(self.indices()))

  def d_star_sq(self):
    return array(
      self, self.unit_cell().d_star_sq(self.indices()))

  def d_star_cubed(self):
    return array(
      self, flex.pow(self.unit_cell().d_star_sq(self.indices()), 3/2))

  def d_spacings(self):
    return array(
      self, self.unit_cell().d(self.indices()))

  def sin_theta_over_lambda_sq(self):
    return array(
      self, self.unit_cell().stol_sq(self.indices()))

  def two_theta(self, wavelength, deg=False):
    return array(
      self, self.unit_cell().two_theta(self.indices(), wavelength, deg))

  def d_min(self):
    return uctbx.d_star_sq_as_d(self.unit_cell().max_d_star_sq(self.indices()))

  def min_max_d_star_sq(self):
    return self.unit_cell().min_max_d_star_sq(self.indices())

  def d_max_min(self):
    return [uctbx.d_star_sq_as_d(d_star_sq)
      for d_star_sq in self.min_max_d_star_sq()]

  def n_bijvoet_pairs(self):
    asu, matches = self.match_bijvoet_mates()
    return matches.pairs().size()

  def as_non_anomalous_set(self):
    return set(
      crystal_symmetry=self,
      indices=self.indices(),
      anomalous_flag=False)

  def auto_anomalous(self, min_n_bijvoet_pairs=None,
                           min_fraction_bijvoet_pairs=None):
    assert [min_n_bijvoet_pairs, min_fraction_bijvoet_pairs].count(None) > 0
    if (self.indices().size() == 0):
      anomalous_flag = False
    elif (min_fraction_bijvoet_pairs is not None):
      anomalous_flag = (2*self.n_bijvoet_pairs()/self.indices().size()
                        >= min_fraction_bijvoet_pairs)
    elif (min_n_bijvoet_pairs is not None):
      anomalous_flag = (self.n_bijvoet_pairs() >= min_n_bijvoet_pairs)
    else:
      anomalous_flag = (self.n_bijvoet_pairs() > 0)
    return set(
      crystal_symmetry=self,
      indices=self.indices(),
      anomalous_flag=anomalous_flag)

  def is_unique_set_under_symmetry(self):
    return ext.is_unique_set_under_symmetry(
      space_group_type=self.space_group_info().type(),
      anomalous_flag=self.anomalous_flag(),
      miller_indices=self.indices())

  def unique_under_symmetry_selection(self):
    return ext.unique_under_symmetry_selection(
      space_group_type=self.space_group_info().type(),
      anomalous_flag=self.anomalous_flag(),
      miller_indices=self.indices())

  def unique_under_symmetry(self):
    sel = self.unique_under_symmetry_selection()
    if (sel.size() == self.indices().size()): return self
    return self.select(sel)

  def map_to_asu(self):
    i = self.indices().deep_copy()
    anomalous_flag = self.anomalous_flag()
    if (anomalous_flag is None):
      anomalous_flag = True
    map_to_asu(
      self.space_group_info().type(),
      anomalous_flag,
      i)
    return set(self, i, self.anomalous_flag())

  def complete_set(self, d_min_tolerance=1.e-6, d_min=None, d_max=None):
    assert self.anomalous_flag() in (False, True)
    if (self.indices().size() == 0):
      return set(
        crystal_symmetry=self,
        anomalous_flag=self.anomalous_flag(),
        indices=flex.miller_index())
    if (d_min is None): d_min = self.d_min()
    if (d_min_tolerance is not None): d_min *= (1-d_min_tolerance)
    return build_set(
      crystal_symmetry=self,
      anomalous_flag=self.anomalous_flag(),
      d_min=d_min,
      d_max=d_max)

  def completeness(self, use_binning=False, d_min_tolerance=1.e-6,
                   return_fail=None, d_max = None):
    if (not use_binning):
      complete_set = self.complete_set(d_min_tolerance=d_min_tolerance,
                                       d_max = d_max)
      return self.indices().size() / max(1,complete_set.indices().size())
    assert self.binner() is not None
    data = []
    for n_given,n_complete in zip(self.binner().counts_given(),
                                  self.binner().counts_complete()):
      if (n_complete == 0): data.append(return_fail)
      else: data.append(n_given/n_complete)
    return binned_data(binner=self.binner(), data=data, data_fmt="%5.3f")

  def all_selection(self):
    return flex.bool(self.indices().size(), True)

  def select(self, selection, negate=False, anomalous_flag=None):
    assert self.indices() is not None
    if (anomalous_flag is None):
      anomalous_flag = self.anomalous_flag()
    if (negate): selection = ~selection
    i = self.indices().select(selection)
    return set(self, i, anomalous_flag)

  def select_acentric(self):
    return self.select(~self.centric_flags().data())

  def select_centric(self):
    return self.select(self.centric_flags().data())

  def remove_systematic_absences(self, negate=False):
    return self.select(
      selection=self.sys_absent_flags().data(),
      negate=not negate)

  def resolution_filter_selection(self, d_max=0, d_min=0):
    d = self.d_spacings().data()
    result = self.all_selection()
    if (d_max): result &= d <= d_max
    if (d_min): result &= d >= d_min
    return result

  def resolution_filter(self, d_max=0, d_min=0, negate=0):
    return self.select(
      selection=self.resolution_filter_selection(d_max=d_max, d_min=d_min),
      negate=negate)

  def match_indices(self, other, assert_is_similar_symmetry=True):
    if (assert_is_similar_symmetry):
      assert self.is_similar_symmetry(other)
    assert self.anomalous_flag() == other.anomalous_flag()
    return match_indices(self.indices(), other.indices())

  def common_set(self, other, assert_is_similar_symmetry=True):
    pairs = other.match_indices(
      other=self,
      assert_is_similar_symmetry=assert_is_similar_symmetry).pairs()
    return self.select(pairs.column(1))

  def common_sets(self, other, assert_is_similar_symmetry=True):
    pairs = other.match_indices(
      other=self,
      assert_is_similar_symmetry=assert_is_similar_symmetry).pairs()
    return [self.select(pairs.column(1)),
            other.select(pairs.column(0))]

  def lone_set(self, other, assert_is_similar_symmetry=True):
    return self.select(other.match_indices(
      other=self,
      assert_is_similar_symmetry=assert_is_similar_symmetry).singles(1))

  def lone_sets(self, other, assert_is_similar_symmetry=True):
    matches = other.match_indices(
      other=self,
      assert_is_similar_symmetry=assert_is_similar_symmetry)
    return [self.select(matches.singles(1)),
            other.select(matches.singles(0))]

  def match_bijvoet_mates(self):
    assert self.anomalous_flag() in (None, True)
    assert self.indices() is not None
    if (self.space_group_info() is not None):
      asu = self.map_to_asu()
      matches = match_bijvoet_mates(
        asu.space_group_info().type(), asu.indices())
    else:
      asu = self
      matches = match_bijvoet_mates(asu.indices())
    return asu, matches

  def resolution_range(self):
    r = self.unit_cell().min_max_d_star_sq(self.indices())
    return tuple([uctbx.d_star_sq_as_d(x) for x in r])

  def sort_permutation(self, by_value="resolution", reverse=False):
    assert by_value in ["resolution", "packed_indices"]
    assert reverse in [False, True]
    if (by_value == "resolution"):
      return flex.sort_permutation(
        data=self.unit_cell().d_star_sq(self.indices()), reverse=reverse)
    else:
      return flex.sort_permutation(
        data=index_span(self.indices()).pack(self.indices()), reverse=reverse)

  def sort(self, by_value="resolution", reverse=False):
    return self.select(
      self.sort_permutation(by_value=by_value, reverse=reverse))

  def generate_r_free_flags(self, fraction=0.1, max_free=2000, lattice_symmetry_max_delta=5.0, use_lattice_symmetry=False):
    if use_lattice_symmetry:
      assert lattice_symmetry_max_delta>=0

    if not use_lattice_symmetry:
      return self.generate_r_free_flags_basic(fraction, max_free)
    else:
      return self.generate_r_free_flags_on_lattice_symmetry(fraction, max_free, lattice_symmetry_max_delta)

  def crystal_symmetry(self):
    return crystal.symmetry(
      unit_cell = self.unit_cell(),
      space_group_info = self.space_group_info())

  def combine(self, other, scale = True, scale_for_lones = 1):
    assert self.anomalous_flag() == other.anomalous_flag()
    f1_c, f2_c = self.common_sets(other = other)
    f1_l, f2_l = self.lone_sets(other = other)
    scale_k1 = 1
    if(scale):
      den = flex.sum(flex.abs(f2_c.data())*flex.abs(f2_c.data()))
      if(den != 0):
        scale_k1 = flex.sum(flex.abs(f1_c.data())*flex.abs(f2_c.data())) / den
    result_data = f1_c.data() + f2_c.data()*scale_k1
    result_data.extend(f1_l.data()*scale_for_lones)
    result_data.extend(f2_l.data()*scale_k1*scale_for_lones)
    result_indices = f1_c.indices()
    result_indices.extend(f1_l.indices())
    result_indices.extend(f2_l.indices())
    ms = set(self.crystal_symmetry(), result_indices)
    return ms.array(data = result_data)

  def generate_r_free_flags_on_lattice_symmetry(self,
                                                fraction=0.10,
                                                max_free=2000,
                                                max_delta=5.0,
                                                return_integer_array=False,
                                                n_partitions=None):
    # the max_number of reflections is wrst the non anomalous set
    n_original = self.indices().size()
    if n_original<=0:
      raise Sorry("An array of size zero is given for Free R flag generation")
    n_non_ano = n_original
    if self.anomalous_flag():
      matches = self.match_bijvoet_mates()[1]
      n_non_ano = matches.pairs().size() + matches.n_singles()
    # make sure the data is unique
    self.is_unique_set_under_symmetry()
    if fraction is not None:
      assert fraction > 0 and fraction < 0.5
      assert n_partitions is None
      assert return_integer_array is False
    if max_free is not None:
      assert fraction is not None
      fraction = min( n_non_ano*fraction,
                      max_free )/float(n_non_ano)
      assert n_partitions is None
      assert return_integer_array is False
    if return_integer_array:
      assert fraction is None
      assert max_free is None
      assert n_partitions > 1
    #first make a set of temporary flags
    cb_op_to_niggli = self.change_of_basis_op_to_niggli_cell()
    tmp_ma = self.change_basis( cb_op_to_niggli )
    # please get the lattice symmetry of th niggli cell
    lattice_group = lattice_symmetry.group(
      tmp_ma.unit_cell(),
      max_delta=max_delta)
    lattice_xs = crystal.symmetry(unit_cell=tmp_ma.unit_cell(),
                                  space_group=lattice_group,
                                  assert_is_compatible_unit_cell=False)
    # make some flags, and insert lattice symmetry
    tmp_flags = tmp_ma.array().customized_copy(
      crystal_symmetry = lattice_xs,
      data = flex.double( tmp_ma.indices().size(), 0 ) ).map_to_asu()
    # Carry out the merging please
    tmp_flags = tmp_flags.merge_equivalents().array()
    tmp_flags = tmp_flags.average_bijvoet_mates()
    n_non_ano_lat_sym = tmp_flags.indices().size()
    # now we can do the free r assignement in the lattice symmetry
    n = tmp_flags.indices().size()
    result = None
    if not return_integer_array:
      group_size = 1/(fraction)
      assert group_size >= 2
      result = flex.bool(n, False)
      i_start = 0
      for i_group in count(1):
        i_end = min(n, iround(i_group*group_size) )
        if (i_start == i_end):
          break
        if (i_end + 1 == n):
          i_end += 1
        assert i_end - i_start >= 2
        result[random.randrange(i_start, i_end)] = True
        i_start = i_end
    else:
      result = flex.size_t()
      n_times = int(n/n_partitions)+1
      for ii in xrange(n_times):
        tmp = flex.random_double( n_partitions )
        tmp = flex.sort_permutation( tmp )
        result.extend( tmp )
      result = flex.int( list(result[0:n]) )

    # please sort the reflections by resolution
    indices = tmp_flags.indices()
    result = result.select(
      indices=flex.sort_permutation(
        data=tmp_flags.unit_cell().d_star_sq(indices), reverse=True),
        reverse=True)

    tmp_flags = tmp_flags.customized_copy(
      data=result, sigmas=None)
    # now expand to p1 please
    tmp_flags = tmp_flags.expand_to_p1()
    # now make it into the proper symmetry please
    tmp_flags = tmp_flags.customized_copy(
      crystal_symmetry = crystal.symmetry( unit_cell=tmp_ma.unit_cell(),
                                           space_group=tmp_ma.space_group() )
      )
    tmp_flags = tmp_flags.merge_equivalents().array()
    if self.anomalous_flag():
      tmp_flags = tmp_flags.generate_bijvoet_mates()
    tmp_flags = tmp_flags.change_basis( cb_op_to_niggli.inverse() ).map_to_asu()
    tmp_flags = tmp_flags.common_set( self.map_to_asu() )
    tmp_flags = tmp_flags.customized_copy(
      indices = self.indices(),
      data = tmp_flags.data() )
    tmp_flags = tmp_flags.common_set( self )
    assert tmp_flags.indices().all_eq( self.indices() )
    return tmp_flags

  def generate_r_free_flags_basic(self, fraction=0.1, max_free=2000):
    assert fraction > 0 and fraction < 0.5
    assert max_free is None or max_free > 0
    if (self.anomalous_flag()):
      matches = self.match_bijvoet_mates()[1]
      sel_pp = matches.pairs_hemisphere_selection("+")
      sel_pm = matches.pairs_hemisphere_selection("-")
      sel_sp = matches.singles("+")
      sel_sm = matches.singles("-")
      n = matches.pairs().size() + matches.n_singles()
      del matches
    else:
      assert self.is_unique_set_under_symmetry()
      n = self.indices().size()
    if (max_free is not None):
      fraction = min(fraction, max_free/max(1,n))
    group_size = 1/fraction
    assert group_size >= 2
    result = flex.bool(n, False)
    i_start = 0
    for i_group in count(1):
      i_end = min(n, iround(i_group * group_size))
      if (i_start == i_end):
        break
      if (i_end + 1 == n):
        i_end += 1
      assert i_end - i_start >= 2
      result[random.randrange(i_start, i_end)] = True
      i_start = i_end
    if (not self.anomalous_flag()):
      indices = self.indices()
    else:
      indices = self.indices().select(sel_pp)
      indices.extend(self.indices().select(sel_sp))
      indices.extend(self.indices().select(sel_sm))
      assert indices.size() == n
    result = result.select(
      indices=flex.sort_permutation(
        data=self.unit_cell().d_star_sq(indices), reverse=True),
        reverse=True)
    if (not self.anomalous_flag()):
      return self.array(data=result)
    del indices
    result_full = flex.bool(self.indices().size(), False)
    i_pp = sel_pp.size()
    i_pp_sp = i_pp + sel_sp.size()
    r_pp = result[:i_pp]
    result_full.set_selected(sel_pp, r_pp)
    assert result_full.count(True) == r_pp.count(True)
    result_full.set_selected(sel_pm, r_pp)
    assert result_full.count(True) == 2*r_pp.count(True)
    del r_pp
    del sel_pm
    del sel_pp
    result_full.set_selected(sel_sp, result[i_pp:i_pp_sp])
    del sel_sp
    result_full.set_selected(sel_sm, result[i_pp_sp:])
    del sel_sm
    return self.array(data=result_full)

  def random_phases_compatible_with_phase_restrictions(self, deg=False):
    random_phases = flex.random_double(size=self.size())-0.5
    if (deg): random_phases *= 360
    else:     random_phases *= 2*math.pi
    return self.array(data=self.space_group().nearest_valid_phases(
      miller_indices=self.indices(),
      phases=random_phases,
      deg=deg))

  def change_basis(self, cb_op):
    if (isinstance(cb_op, str)): cb_op = sgtbx.change_of_basis_op(cb_op)
    return set.customized_copy(self,
      crystal_symmetry=crystal.symmetry.change_basis(self, cb_op),
      indices=cb_op.apply(self.indices()))

  def expand_to_p1(self):
    assert self.space_group_info() is not None
    assert self.indices() is not None
    assert self.anomalous_flag() is not None
    p1_indices = expand_to_p1_indices(
      space_group=self.space_group(),
      anomalous_flag=self.anomalous_flag(),
      indices=self.indices())
    return set(self.cell_equivalent_p1(), p1_indices, self.anomalous_flag())

  def patterson_symmetry(self):
    assert self.anomalous_flag() == False
    return set.customized_copy(self,
      crystal_symmetry=crystal.symmetry.patterson_symmetry(self))

  def crystal_gridding(self, resolution_factor=1/3,
                             d_min=None,
                             grid_step=None,
                             symmetry_flags=None,
                             mandatory_factors=None,
                             max_prime=5,
                             assert_shannon_sampling=True):
    if (d_min is None and grid_step is None): d_min = self.d_min()
    return maptbx.crystal_gridding(
      unit_cell=self.unit_cell(),
      d_min=d_min,
      resolution_factor=resolution_factor,
      step=grid_step,
      symmetry_flags=symmetry_flags,
      space_group_info=self.space_group_info(),
      mandatory_factors=mandatory_factors,
      max_prime=max_prime,
      assert_shannon_sampling=assert_shannon_sampling)

  def structure_factors_from_map(self, map, in_place_fft=False):
    assert map.focus_size_1d() > 0 and map.nd() == 3 and map.is_0_based()
    assert isinstance(map, flex.double) or isinstance(map, flex.complex_double)
    assert in_place_fft in (False, True)
    if (isinstance(map, flex.double)):
      fft = fftpack.real_to_complex_3d(map.focus())
      if (not map.is_padded()):
        assert not in_place_fft
        assert map.focus() == fft.n_real()
        map = maptbx.copy(map, flex.grid(fft.m_real()).set_focus(fft.n_real()))
      elif (not in_place_fft):
        map = map.deep_copy()
    else:
      if (not in_place_fft):
        map = map.deep_copy()
      fft = fftpack.complex_to_complex_3d(map.focus())
    map = fft.forward(map)
    from_map = maptbx.structure_factors.from_map(
      anomalous_flag=self.anomalous_flag(),
      miller_indices=self.indices(),
      complex_map=map,
      conjugate_flag=True)
    return array(miller_set=self, data=from_map.data())

  def structure_factors_from_scatterers(self, xray_structure,
                                        algorithm=None,
                                        cos_sin_table=False,
                                        grid_resolution_factor=1/3.,
                                        quality_factor=None,
                                        u_base=None,
                                        b_base=None,
                                        wing_cutoff=None,
                                        exp_table_one_over_step_size=None):
    from cctbx import xray
    if (algorithm == "direct"):
      return xray.structure_factors.from_scatterers_direct(
        xray_structure=xray_structure,
        miller_set=self,
        cos_sin_table=cos_sin_table)
    return xray.structure_factors.from_scatterers(
      miller_set=self,
      cos_sin_table=cos_sin_table,
      grid_resolution_factor=grid_resolution_factor,
      quality_factor=quality_factor,
      u_base=u_base,
      b_base=b_base,
      wing_cutoff=wing_cutoff,
      exp_table_one_over_step_size=exp_table_one_over_step_size)(
        xray_structure=xray_structure,
        miller_set=self,
        algorithm=algorithm)

  def f_obs_minus_xray_structure_f_calc(self, f_obs_factor, xray_structure,
        structure_factor_algorithm=None,
        cos_sin_table=False,
        quality_factor=None,
        u_base=None,
        b_base=None,
        wing_cutoff=None,
        exp_table_one_over_step_size=None):
    return self.f_obs_minus_f_calc(
      f_obs_factor=f_obs_factor,
      f_calc=self.structure_factors_from_scatterers(
        xray_structure=xray_structure,
        algorithm=structure_factor_algorithm,
        cos_sin_table=cos_sin_table,
        quality_factor=quality_factor,
        u_base=u_base,
        b_base=b_base,
        wing_cutoff=wing_cutoff,
        exp_table_one_over_step_size=exp_table_one_over_step_size).f_calc())

  def setup_binner(self, d_max=0, d_min=0,
                   auto_binning=False,
                   reflections_per_bin=0,
                   n_bins=0):
    assert auto_binning or reflections_per_bin != 0 or n_bins != 0
    assert auto_binning or (reflections_per_bin == 0 or n_bins == 0)
    if (auto_binning):
      if (reflections_per_bin == 0): reflections_per_bin = 200
      if (n_bins == 0): n_bins = 8
      n_per_bin = int(len(self.indices()) / n_bins + .5)
      if (n_per_bin > reflections_per_bin):
        n_bins = int(len(self.indices()) / reflections_per_bin + .5)
    elif (reflections_per_bin):
      n_bins = int(len(self.indices()) / reflections_per_bin + .5)
    assert n_bins > 0
    assert self.unit_cell() is not None
    assert self.indices().size() > 0 or d_min > 0
    self.use_binning(
      binning=binning(self.unit_cell(), n_bins, self.indices(), d_max, d_min))
    return self.binner()

  def setup_binner_d_star_sq_step(self,
                                  auto_binning=True,
                                  d_max=None,# Low reso limit
                                  d_min=None,# High reso limit
                                  d_star_sq_step=None):
    assert auto_binning or ( d_min is not None )
    assert auto_binning or ( d_max is not None )
    assert d_star_sq_step > 0 or (d_star_sq_step is None)
    ## Either automatic binning (with or without the choice of a d_star_sq
    ## step) or setting everything by hand

    if auto_binning:
      d_spacings = self.d_spacings().data()
      d_max=flex.min(d_spacings)
      d_min=flex.max(d_spacings)
      del d_spacings
      if d_star_sq_step is None:
        d_star_sq_step = 0.004 ## Default of 0.004 seems to be reasonable

    assert (d_star_sq_step>0.0)
    return self.use_binning(binning=binning(self.unit_cell(),
      self.indices(),
      d_min,
      d_max,
      d_star_sq_step))

  def setup_binner_counting_sorted(self,
        d_max=0,
        d_min=0,
        reflections_per_bin=None,
        d_tolerance=1.e-10):
    assert d_max >= 0
    assert d_min >= 0
    assert isinstance(reflections_per_bin, int)
    assert reflections_per_bin > 0
    assert d_tolerance > 0
    assert d_tolerance < 0.5
    d_star_sq = self.d_star_sq().data()
    if (d_max > 0):
      d_star_sq = d_star_sq.select(d_star_sq >= 1./d_max**2)
    if (d_min > 0):
      d_star_sq = d_star_sq.select(d_star_sq < 1./d_min**2)
    assert d_star_sq.size() > 0
    n_bins = max(1, iround(d_star_sq.size() / float(reflections_per_bin)))
    reflections_per_bin = d_star_sq.size() / float(n_bins)
    d_star_sq = d_star_sq.select(flex.sort_permutation(d_star_sq))
    limits = flex.double()
    limits.reserve(n_bins+1)
    if (d_max > 0):
      limits.append(1./d_max**2 * (1-d_tolerance))
    else:
      limits.append(max(0, d_star_sq[0] * (1-d_tolerance)))
    m = d_star_sq.size()-1
    for i_bin in xrange(1, n_bins):
      i = iround(i_bin * reflections_per_bin)
      limits.append(d_star_sq[i] * (1-d_tolerance))
      if (i == m): break
    if (d_min > 0):
      limits.append(1./d_min**2 * (1+d_tolerance))
    else:
      limits.append(d_star_sq[-1] * (1+d_tolerance))
    return self.use_binning(binning=binning(self.unit_cell(), limits))

  def binner(self):
    return self._binner

  def use_binning(self, binning):
    self._binner = binner(binning, self)
    return self._binner

  def use_binning_of(self, other):
    return self.use_binning(binning=other.binner())

  def use_binner_of(self, other):
    assert self.indices().all_eq(other.indices())
    self._binner = other._binner
    return self._binner

  def clear_binner(self):
    self._binner = None

  def concatenate(self, other):
    assert self.is_similar_symmetry(other)
    assert self.anomalous_flag() == other.anomalous_flag()
    return set(
      crystal_symmetry = self,
      indices          = self._indices.concatenate(other.indices()),
      anomalous_flag   = self.anomalous_flag())

def build_set(crystal_symmetry, anomalous_flag, d_min, d_max=None):
  result = set(
    crystal_symmetry,
    index_generator(
      crystal_symmetry.unit_cell(),
      crystal_symmetry.space_group_info().type(),
      anomalous_flag,
      d_min).to_array(),
    anomalous_flag)
  if(d_max is not None): result = result.resolution_filter(d_max = d_max)
  return result

class array_info(object):

  def __init__(self,
        source=None,
        source_type=None,
        history=None,
        labels=None,
        merged=False,
        systematic_absences_eliminated=False,
        crystal_symmetry_from_file=None):
    adopt_init_args(self, locals())

  def customized_copy(self,
        source=Keep,
        source_type=Keep,
        history=Keep,
        labels=Keep,
        merged=Keep,
        systematic_absences_eliminated=Keep,
        crystal_symmetry_from_file=Keep):
    if (source is Keep): source = self.source
    if (source_type is Keep): source_type = self.source_type
    if (history is Keep): history = self.history
    if (labels is Keep): labels = self.labels
    if (merged is Keep): merged = self.merged
    if (systematic_absences_eliminated is Keep):
      systematic_absences_eliminated = self.systematic_absences_eliminated
    if (crystal_symmetry_from_file is Keep):
      crystal_symmetry_from_file = self.crystal_symmetry_from_file
    return array_info(
      source=source,
      source_type=source_type,
      history=history,
      labels=labels,
      merged=merged,
      systematic_absences_eliminated=systematic_absences_eliminated,
      crystal_symmetry_from_file=crystal_symmetry_from_file)

  def as_string_part_2(self):
    part_2 = []
    if (self.labels is not None):
      part_2.extend(self.labels)
    if (self.merged):
      part_2.append("merged")
    if (self.systematic_absences_eliminated):
      part_2.append("systematic_absences_eliminated")
    return part_2

  def label_string(self):
    part_2 = self.as_string_part_2()
    if (len(part_2) > 0): return ",".join(part_2)
    return None

  def __str__(self):
    result = []
    if (self.source is not None):
      result.append(str(self.source))
    elif (self.source_type is not None):
      result.append(str(self.source_type))
    part_2 = self.as_string_part_2()
    if (len(part_2) > 0):
      result.append(",".join(part_2))
    if (len(result) == 0):
      return "None"
    return ":".join(result)

def raw_array_summary(array):
  if (array is None): return str(None)
  try:
    return array.__class__.__name__ + ", size=%d" % (len(array),)
  except:
    return "Unknown"

class array(set):

  def __init__(self, miller_set, data=None, sigmas=None):
    set._copy_constructor(self, miller_set)
    self._data = data
    self._sigmas = sigmas
    self._info = None
    self._observation_type = None

  def _copy_constructor(self, other):
    set._copy_constructor(self, other)
    self._data = other._data
    self._sigmas = other._sigmas
    self._info = other._info
    self._observation_type = other._observation_type

  def set_info(self, info):
    self._info = info
    return self

  def set_observation_type(self, observation_type):
    from cctbx.xray import observation_types
    if (isinstance(observation_type, array)):
      observation_type = observation_type.observation_type()
    assert observation_type is None or isinstance(observation_type, observation_types.any)
    self._observation_type = observation_type
    return self

  def set_observation_type_xray_amplitude(self):
    from cctbx.xray import observation_types
    return self.set_observation_type(observation_types.amplitude())

  def set_observation_type_xray_intensity(self):
    from cctbx.xray import observation_types
    return self.set_observation_type(observation_types.intensity())

  def data(self):
    return self._data

  def sigmas(self):
    return self._sigmas

  def __iter__(self):
    if self.sigmas() is not None:
      for item in izip(self.indices(), self.data(), self.sigmas()):
        yield item
    else:
      for item in izip(self.indices(), self.data()):
        yield item

  def info(self):
    return self._info

  def observation_type(self):
    return self._observation_type

  def size(self):
    assert self.indices() is not None
    assert self.data() is not None
    assert self.data().size() == self.indices().size()
    if (self.sigmas() is not None):
      assert self.sigmas().size() == self.indices().size()
    return set.size(self)

  def is_bool_array(self):
    return isinstance(self.data(), flex.bool)

  def is_integer_array(self):
    return isinstance(self.data(), flex.int) \
        or isinstance(self.data(), flex.long)

  def is_real_array(self):
    return isinstance(self.data(), flex.float) \
        or isinstance(self.data(), flex.double)

  def is_complex_array(self):
    return isinstance(self.data(), flex.complex_double)

  def is_hendrickson_lattman_array(self):
    return isinstance(self.data(), flex.hendrickson_lattman)

  def is_xray_amplitude_array(self):
    from cctbx.xray import observation_types
    return isinstance(self.observation_type(), observation_types.amplitude)

  def is_xray_reconstructed_amplitude_array(self):
    from cctbx.xray import observation_types
    return isinstance(
      self.observation_type(), observation_types.reconstructed_amplitude)

  def is_xray_intensity_array(self):
    from cctbx.xray import observation_types
    return isinstance(self.observation_type(), observation_types.intensity)

  def copy(self):
    return (array(
      miller_set=self,
      data=self.data(),
      sigmas=self.sigmas())
      .set_info(self.info())
      .set_observation_type(self))

  def deep_copy(self):
    d = None
    s = None
    if (self.data() is not None): d = self.data().deep_copy()
    if (self.sigmas() is not None): s = self.sigmas().deep_copy()
    return (array(
      miller_set = set.deep_copy(self),
      data=d,
      sigmas=s)
      .set_info(self.info())
      .set_observation_type(self))

  def customized_copy(self,
        miller_set=Keep,
        data=Keep,
        sigmas=Keep,
        crystal_symmetry=Keep,
        indices=Keep,
        anomalous_flag=Keep,
        unit_cell=Keep,
        space_group_info=Keep,
        observation_type=Keep):
    if (miller_set is Keep): miller_set = self
    if (data is Keep): data = self.data()
    if (sigmas is Keep): sigmas = self.sigmas()
    if observation_type is Keep: observation_type = self.observation_type()
    miller_set = set.customized_copy(miller_set,
      crystal_symmetry=crystal_symmetry,
      indices=indices,
      anomalous_flag=anomalous_flag,
      unit_cell=unit_cell,
      space_group_info=space_group_info)
    return array(miller_set=miller_set, data=data, sigmas=sigmas)\
           .set_observation_type(observation_type)

  def concatenate(self, other):
    if([self.sigmas(), other.sigmas()].count(None) == 0):
      return self.set().concatenate(other = other.set()).array(
        data   = self.data().concatenate(other.data()),
        sigmas = self.sigmas().concatenate(other.sigmas()))
    else:
      return self.set().concatenate(other = other.set()).array(
        data = self.data().concatenate(other.data()))

  def set(self,
        crystal_symmetry=Keep,
        indices=Keep,
        anomalous_flag=Keep,
        unit_cell=Keep,
        space_group_info=Keep):
    return set.customized_copy(self,
      crystal_symmetry=crystal_symmetry,
      indices=indices,
      anomalous_flag=anomalous_flag,
      unit_cell=unit_cell,
      space_group_info=space_group_info)

  def discard_sigmas(self):
    return array.customized_copy(self, sigmas=None)

  def conjugate(self):
    assert self.is_complex_array()
    return array.customized_copy(self, data=flex.conj(self.data()))

  def as_double(self):
    return self.array(data=self.data().as_double())

  def __getitem__(self, slice_object):
    return array(
      miller_set=set.__getitem__(self, slice_object),
      data=_slice_or_none(self.data(), slice_object),
      sigmas=_slice_or_none(self.sigmas(), slice_object))

  def show_summary(self, f=None, prefix=""):
    if (f is None): f = sys.stdout
    print >> f, prefix + "Miller %s info:" % (
      self.__class__.__name__), self.info()
    print >> f, prefix + "Observation type:", self.observation_type()
    print >> f, prefix + "Type of data:", raw_array_summary(self.data())
    print >> f, prefix + "Type of sigmas:", raw_array_summary(self.sigmas())
    set.show_summary(self, f=f, prefix=prefix)
    return self

  def crystal_symmetry_is_compatible_with_symmetry_from_file(self,
        unit_cell_relative_length_tolerance=0.02,
        unit_cell_absolute_angle_tolerance=3.,
        working_point_group=None):
    return crystal_symmetry_is_compatible_with_symmetry_from_file(
      miller_array=self,
      unit_cell_relative_length_tolerance=unit_cell_relative_length_tolerance,
      unit_cell_absolute_angle_tolerance=unit_cell_absolute_angle_tolerance,
      working_point_group=working_point_group)

  def sigmas_are_sensible(self, critical_ratio=0.75, epsilon=1e-6):
    result=None
    if self.sigmas() is not None and self.sigmas().size() != 0:
      result=True
      suspected = ( self.sigmas() <= epsilon ).count(True)
      all = self.sigmas().size()
      ratio = float(suspected)/float(all)
      if ratio>critical_ratio:
        result = False
    return result

  def enforce_positive_amplitudes(self,i_sig_level=-4.0):
    """
    Takes in an intensity array (including negatives) and spits out amplitudes.
    The basic assumption is that
    P(Itrue) \propto exp(-(Itrue-Iobs)**2/(2*s))
    where Itrue>=0 (positivity constraint on error free amplitudes).
    For amplitudes, this results in
    P(Ftrue) \propto 2 Ftrue exp( -(Ftrue**2-Iobs)**2/(2s) )
    A Gaussian approximation is fitted to the Mode of this distribution.
    An analytical solution exists and is implemented below.
    This method does not require any Wilson statistics assumptions.
    """

    assert self.is_xray_intensity_array()
    assert self.sigmas() is not None
    assert self.sigmas_are_sensible()

    self = self.select( self.sigmas() > 0 )
    i_sigi = self.data()/self.sigmas()
    self = self.select( i_sigi > i_sig_level )
    det = flex.sqrt( self.data()*self.data() + 2.0*self.sigmas()*self.sigmas())
    f_saddle = flex.sqrt( (self.data()+det) / 2.0)
    s_saddle = (1.0/(f_saddle*f_saddle)) + (self.data() + 3.0*det) \
             / (self.sigmas()*self.sigmas() )
    s_saddle = flex.sqrt( 1.0/s_saddle )

    result = self.customized_copy(
      data=f_saddle,
      sigmas=s_saddle).set_observation_type( self.as_amplitude_array() )
    return result

  def f_sq_as_f(self, algorithm="xtal_3_7", tolerance=1.e-6):
    from cctbx import xray
    assert self.observation_type() is None or  self.is_xray_intensity_array()
    converters = {
      "xtal_3_7": xray.array_f_sq_as_f_xtal_3_7,
      "crystals": xray.array_f_sq_as_f_crystals}
    converter = converters.get(algorithm)
    if (converter is None):
      raise RuntimeError(
        "Unknown f_sq_as_f algorithm=%s\n" % show_string(algorithm)
        + "  Possible choices are: "
        + ", ".join([show_string(s) for s in converters.keys()]))
    if (self.sigmas() is None):
      result = array(self, converter(self.data()).f)
    else:
      r = converter(self.data(), self.sigmas(), tolerance)
      result = array(self, r.f, r.sigma_f)
    if (self.is_xray_intensity_array()):
      result.set_observation_type_xray_amplitude()
    return result

  def f_as_f_sq(self):
    from cctbx import xray
    assert self.observation_type() is None or self.is_xray_amplitude_array()
    if (self.sigmas() is None):
      result = array(self, xray.array_f_as_f_sq(self.data()).f_sq)
    else:
      r = xray.array_f_as_f_sq(self.data(), self.sigmas())
      result = array(self, r.f_sq, r.sigma_f_sq)
    if (self.is_xray_amplitude_array()):
      result.set_observation_type_xray_intensity()
    return result

  def as_amplitude_array(self):
    if (self.is_xray_intensity_array()):
      return self.f_sq_as_f()
    return self

  def as_intensity_array(self):
    if (not self.is_xray_intensity_array()):
      return self.f_as_f_sq()
    return self

  def map_to_asu(self, deg=None):
    i = self.indices().deep_copy()
    d = self.data().deep_copy()
    if (self.is_complex_array() or self.is_hendrickson_lattman_array()):
      map_to_asu(
        self.space_group_info().type(),
        self.anomalous_flag(),
        i, d)
    elif (deg is None):
      map_to_asu(
        self.space_group_info().type(),
        self.anomalous_flag(),
        i)
    else:
      map_to_asu(
        self.space_group_info().type(),
        self.anomalous_flag(),
        i, d, deg)
    return (array(set(self, i, self.anomalous_flag()), d, self.sigmas())
      .set_observation_type(self))

  def adopt_set(self, other, assert_is_similar_symmetry=True):
    if (assert_is_similar_symmetry):
      assert self.is_similar_symmetry(other)
    assert self.indices().size() == other.indices().size()
    assert self.anomalous_flag() == other.anomalous_flag()
    p = match_indices(other.indices(), self.indices()).permutation()
    assert self.indices().select(p).all_eq(other.indices())
    d = self.data()
    s = self.sigmas()
    if (d is not None): d = d.select(p)
    if (s is not None): s = s.select(p)
    return (array(miller_set=other, data=d, sigmas=s)
      .set_observation_type(self))

  def matching_set(self,
        other,
        data_substitute,
        sigmas_substitute=None,
        assert_is_similar_symmetry=True):
    assert self.data().size() == self.indices().size()
    if (self.sigmas() is not None):
      assert self.sigmas().size() == self.indices().size()
      assert sigmas_substitute is not None
    pairs = other.match_indices(
      other=self,
      assert_is_similar_symmetry=assert_is_similar_symmetry).pairs()
    data = self.data().__class__(
      other.indices().size(), data_substitute)
    data.set_selected(
      pairs.column(0), self.data().select(pairs.column(1)))
    if (self.sigmas() is None):
      sigmas = None
    else:
      sigmas = self.sigmas().__class__(
        other.indices().size(), sigmas_substitute)
      sigmas.set_selected(
        pairs.column(0), self.sigmas().select(pairs.column(1)))
    return other.array(data=data, sigmas=sigmas)

  def complete_array(self,
        d_min_tolerance=1.e-6,
        d_min=None,
        d_max=None,
        new_data_value=-1,
        new_sigmas_value=-1):
    cs = self.complete_set(
      d_min_tolerance=d_min_tolerance, d_min=d_min, d_max=d_max)
    matches = match_indices(self.indices(), cs.indices())
    assert matches.singles(0).size() == 0
    i = self.indices()
    d = self.data()
    if (d is not None): d = d.deep_copy()
    s = self.sigmas()
    if (s is not None): s = s.deep_copy()
    ms = matches.singles(1)
    n = ms.size()
    if (n == 0):
      i = i.deep_copy()
    else:
      i = i.concatenate(cs.indices().select(ms))
      if (d is not None): d.resize(d.size()+n, new_data_value)
      if (s is not None): s.resize(s.size()+n, new_sigmas_value)
    return self.customized_copy(indices=i, data=d, sigmas=s)

  def sort_permutation(self, by_value="resolution", reverse=False):
    assert reverse in (False, True)
    if (by_value in ["resolution", "packed_indices"]):
      result = set.sort_permutation(self,
        by_value=by_value, reverse=reverse)
    elif (by_value == "data"):
      result = flex.sort_permutation(
        data=self.data(), reverse=not reverse)
    elif (by_value == "abs"):
      result = flex.sort_permutation(
        data=flex.abs(self.data()), reverse=not reverse)
    else:
      result = flex.sort_permutation(
        data=by_value, reverse=not reverse)
    return result

  def patterson_symmetry(self):
    data = self.data()
    if (self.is_complex_array()):
      data = flex.abs(self.data())
    return array(
      set.patterson_symmetry(self),
      data,
      self.sigmas())

  def expand_to_p1(self, phase_deg=None):
    assert self.space_group_info() is not None
    assert self.indices() is not None
    assert self.anomalous_flag() is not None
    assert self.data() is not None
    p1_sigmas = None
    expand_type = {
      "bool": expand_to_p1_bool,
      "int": expand_to_p1_int,
      "complex_double": expand_to_p1_complex,
      "hendrickson_lattman": expand_to_p1_hendrickson_lattman,
    }.get(self.data().__class__.__name__, None)
    if (expand_type is not None):
      assert phase_deg is None
      assert self.sigmas() is None
      p1 = expand_type(
        space_group=self.space_group(),
        anomalous_flag=self.anomalous_flag(),
        indices=self.indices(),
        data=self.data())
    elif (isinstance(self.data(), flex.double)):
      assert phase_deg in (None, False, True)
      if (phase_deg is None):
        if (self.sigmas() is None):
          p1 = expand_to_p1_double(
            space_group=self.space_group(),
            anomalous_flag=self.anomalous_flag(),
            indices=self.indices(),
            data=self.data())
        else:
          p1 = expand_to_p1_obs(
            space_group=self.space_group(),
            anomalous_flag=self.anomalous_flag(),
            indices=self.indices(),
            data=self.data(),
            sigmas=self.sigmas())
          p1_sigmas = p1.sigmas
      else:
        p1 = expand_to_p1_phases(
          space_group=self.space_group(),
          anomalous_flag=self.anomalous_flag(),
          indices=self.indices(),
          data=self.data(),
          deg=phase_deg)
    else:
      raise RuntimeError(
        "cctbx.miller.expand_to_p1(): unsupported array type:\n"
        "  data: %s\n"
        "  sigmas: %s" % (
          repr(self.data()), repr(self.sigmas())))
    assert self.sigmas() is None or p1_sigmas is not None
    return array(
      set(self.cell_equivalent_p1(), p1.indices, self.anomalous_flag()),
      data=p1.data,
      sigmas=p1_sigmas).set_observation_type(self)

  def change_basis(self, cb_op, deg=None):
    if (isinstance(cb_op, str)): cb_op = sgtbx.change_of_basis_op(cb_op)
    if (deg is False or deg is True):
      assert self.is_real_array()
      result = change_basis_phases_double(
        cb_op=cb_op,
        indices_in=self.indices(),
        data_in=self.data(),
        deg=deg)
    elif (self.is_complex_array()):
      result = change_basis_complex_double(
        cb_op=cb_op,
        indices_in=self.indices(),
        data_in=self.data())
    elif (   self.is_bool_array()
          or self.is_integer_array()
          or self.is_real_array()):
      result = store(
        indices=cb_op.apply(self.indices()),
        data=self.data().deep_copy())
    elif (self.is_hendrickson_lattman_array()):
      result = change_basis_hendrickson_lattman(
        cb_op=cb_op,
        indices_in=self.indices(),
        data_in=self.data())
    else:
      raise RuntimeError("Unsupported miller.array data type.")
    result_sigmas = None
    if (self.sigmas() is not None):
      assert isinstance(self.sigmas(), flex.double)
      result_sigmas = self.sigmas().deep_copy()
    return array(
      miller_set=set(
        crystal_symmetry=crystal.symmetry.change_basis(self, cb_op),
        indices=result.indices,
        anomalous_flag=self.anomalous_flag()),
      data=result.data,
      sigmas=result_sigmas).set_observation_type(self.observation_type())

  def f_obs_minus_f_calc(self, f_obs_factor, f_calc):
    assert self.is_real_array()
    assert f_calc.is_complex_array()
    assert self.indices().all_eq(f_calc.indices())
    assert self.anomalous_flag() is f_calc.anomalous_flag()
    return array(
      miller_set=self,
      data=f_obs_factor*self.data()-flex.abs(f_calc.data())).phase_transfer(
        phase_source=f_calc)

  def phase_transfer(self, phase_source, epsilon=1.e-10, deg=False,
                           phase_integrator_n_steps=None):
    """\
Combines amplitudes of self with phases of phase_source.
Centric reflections are forced to be compatible with the phase
restrictions.

phase_source can be a miller.array or a plain flex array.

epsilon is only used when phase_source is a complex array. If both the
real and the imaginary part of phase_source[i] < epsilon the phase is
assumed to be 0.

deg is only used if phase_source is an array of doubles.
deg=True indicates that the phases are given in degrees,
deg=False indicates phases are given in radians.

phase_integrator_n_steps is only used if phase_source is an
array of Hendrickson-Lattman coefficients. The centroid
phases are determined on the fly using the given step size.
"""
    assert self.data() is not None
    if (hasattr(phase_source, "data")):
      phase_source = phase_source.data()
    assert isinstance(self.data(), flex.complex_double) or isinstance(self.data(), flex.double)
    assert isinstance(phase_source, flex.complex_double) or isinstance(phase_source, flex.double) or isinstance(phase_source, flex.hendrickson_lattman)
    if (isinstance(phase_source, flex.hendrickson_lattman)):
      if (phase_integrator_n_steps is None):
        integrator = phase_integrator()
      else:
        integrator = phase_integrator(n_steps=phase_integrator_n_steps)
      phase_source = integrator(
        space_group=self.space_group(),
        miller_indices=self.indices(),
        hendrickson_lattman_coefficients=phase_source)
    if (isinstance(phase_source, flex.complex_double)):
      return array(
        miller_set=self,
        data=phase_transfer(
          self.space_group(),
          self.indices(),
          self.data(),
          phase_source,
          epsilon))
    return array(
      miller_set=self,
      data=phase_transfer(
        self.space_group(),
        self.indices(),
        self.data(),
        phase_source,
        deg))

  def randomize_phases(self):
    random_phases = (2*math.pi)*flex.random_double(self.data().size())
    return self.phase_transfer(random_phases)

  def phase_integrals(self, n_steps=None, integrator=None):
    assert self.is_hendrickson_lattman_array()
    assert n_steps is None or integrator is None
    if (integrator is None):
      if (n_steps is None):
        integrator = phase_integrator()
      else:
        integrator = phase_integrator(n_steps=n_steps)
    return array(
      miller_set=self,
      data=integrator(
        space_group=self.space_group(),
        miller_indices=self.indices(),
        hendrickson_lattman_coefficients=self.data()))

  def mean_weighted_phase_error(self, phase_source):
    assert self.data() is not None
    if (isinstance(phase_source, array)):
      assert flex.order(phase_source.indices(), self.indices()) == 0
      phase_source = phase_source.data()
    p1 = flex.arg(self.data())
    assert isinstance(phase_source, flex.complex_double) or isinstance(phase_source, flex.double)
    if (isinstance(phase_source, flex.complex_double)):
      p2 = flex.arg(phase_source)
    else:
      p2 = phase_source
    e = scitbx.math.phase_error(phi1=p1, phi2=p2)
    w = flex.abs(self.data())
    sum_w = flex.sum(w)
    assert sum_w != 0
    sum_we = flex.sum(w * e)
    return sum_we / sum_w * 180/math.pi

  def mean_phase_error(self, phase_source):
    assert self.data() is not None
    if (isinstance(phase_source, array)):
      assert flex.order(phase_source.indices(), self.indices()) == 0
      phase_source = phase_source.data()
    p1 = flex.arg(self.data())
    assert isinstance(phase_source, flex.complex_double) or isinstance(phase_source, flex.double)
    if (isinstance(phase_source, flex.complex_double)):
      p2 = flex.arg(phase_source)
    else:
      p2 = phase_source
    e = flex.mean(scitbx.math.phase_error(phi1=p1, phi2=p2))
    return e * 180/math.pi

  def anomalous_differences(self):
    assert self.data() is not None
    assert self.observation_type() is None or self.is_xray_amplitude_array()
    asu, matches = self.match_bijvoet_mates()
    i = matches.miller_indices_in_hemisphere("+")
    d = matches.minus(asu.data())
    s = None
    if (asu.sigmas() is not None):
      s = matches.additive_sigmas(asu.sigmas())
    return array(set(asu, i, anomalous_flag=False), d, s)

  def hemisphere_acentrics(self, plus_or_minus):
    assert plus_or_minus in ("+", "-")
    assert self.data() is not None
    asu, matches = self.match_bijvoet_mates()
    i_column = "+-".index(plus_or_minus)
    return asu.select(
      selection=matches.pairs().column(i_column),
      anomalous_flag=False)

  def hemispheres_acentrics(self):
    assert self.data() is not None
    asu, matches = self.match_bijvoet_mates()
    return tuple(
      [asu.select(
        selection=matches.pairs().column(i_column),
        anomalous_flag=False)
       for i_column in (0,1)])

  def anomalous_signal(self, use_binning=False):
    "sqrt((<||F(+)|-|F(-)||**2>)/(1/2(<|F(+)|>**2+<|F(-)|>**2)))"
    assert not use_binning or self.binner() is not None
    if (not use_binning):
      obs = self.select(self.data() > 0)
      if (self.is_xray_intensity_array()):
        obs = obs.f_sq_as_f()
      f_plus, f_minus = obs.hemispheres_acentrics()
      assert f_plus.data().size() == f_minus.data().size()
      if (f_plus.data().size() == 0): return 0
      mean_sq_diff = flex.mean(flex.pow2(f_plus.data() - f_minus.data()))
      assert mean_sq_diff >= 0
      mean_sum_sq = flex.mean(  flex.pow2(f_plus.data())
                              + flex.pow2(f_minus.data()))
      assert mean_sum_sq > 0
      return math.sqrt(2 * mean_sq_diff / mean_sum_sq)
    results = []
    for i_bin in self.binner().range_all():
      sel = self.binner().selection(i_bin)
      results.append(self.select(sel).anomalous_signal())
    return binned_data(binner=self.binner(), data=results, data_fmt="%7.4f")

  def measurability(self, use_binning=False, cutoff=3.0, return_fail=None):
    ## Peter Zwart 2005-Mar-04
    """\
Fraction of reflections for which (|delta I|/sigma_dI) > cutoff
            and min(I_plus/sigma_plus,I_min/sigma_min) > cutoff"""
    assert not use_binning or self.binner() is not None
    assert self.sigmas() is not None
    cutoff = float(cutoff)
    if (not use_binning):
      obs = self.select(self.data() > 0 )
      if (self.is_xray_amplitude_array()):
        obs = obs.f_as_f_sq()
      if (obs.data().size() == 0): return return_fail
      i_plus, i_minus = obs.hemispheres_acentrics()
      assert i_plus.data().size() == i_minus.data().size()
      top = flex.fabs(i_plus.data()-i_minus.data())
      bottom = flex.sqrt( (i_plus.sigmas()*i_plus.sigmas()) + (i_minus.sigmas()*i_minus.sigmas()) )
      zeros = flex.bool( bottom <= 0 ).iselection()
      bottom = bottom.set_selected( zeros, 1 )
      ratio = top/bottom
      bottom = i_plus.sigmas().set_selected( flex.bool(i_plus.sigmas()<=0).iselection(), 1 )
      i_plus_sigma = i_plus.data()/bottom
      bottom = i_minus.sigmas().set_selected( flex.bool(i_minus.sigmas()<=0).iselection(), 1 )
      i_minus_sigma = i_minus.data()/bottom
      meas = (  (ratio > cutoff)
              & (i_plus_sigma > cutoff)
              & (i_minus_sigma > cutoff) ).count(True)
      if ratio.size()>0:
        return meas/ratio.size()
      else:
        return return_fail
    results = []
    for i_bin in self.binner().range_all():
      sel = self.binner().selection(i_bin)
      results.append(self.select(sel).measurability(cutoff=cutoff,
                                                    return_fail=return_fail))
    return binned_data(binner=self.binner(), data=results, data_fmt="%7.4f")

  def second_moment(self, use_binning=False):
    "<data^2>/(<data>)^2"
    assert not use_binning or self.binner() is not None
    if (not use_binning):
      if (self.indices().size() == 0): return None
      mean_data_sq = flex.mean(self.data())**2
      if (mean_data_sq == 0): return None
      return flex.mean_sq(self.data()) / mean_data_sq
    result = []
    for i_bin in self.binner().range_all():
      sel = self.binner().selection(i_bin)
      result.append(self.select(sel).second_moment())
    return binned_data(binner=self.binner(), data=result, data_fmt="%7.4f")

  def wilson_plot(self, use_binning=False):
    """<data^2>"""
    assert not use_binning or self.binner() is not None
    if (not use_binning):
      if (self.indices().size() == 0): return None
      mean_data = flex.mean(self.data())
      if (mean_data == 0): return None
      return mean_data
    result = []
    for i_bin in self.binner().range_all():
      sel = self.binner().selection(i_bin)
      result.append(self.select(sel).wilson_plot())
    return binned_data(binner=self.binner(), data=result, data_fmt="%7.4f")

  def i_over_sig_i(self, use_binning=False,return_fail=None):
    """<I/sigma_I>"""
    assert not use_binning or self.binner is not None

    if (not use_binning):
      if (self.indices().size() == 0): return return_fail
      obs = None
      if self.is_real_array():
        if self.is_xray_amplitude_array():
          obs = self.f_as_f_sq()
        if self.is_xray_intensity_array():
          obs = self
      if obs is not None:
        obs = obs.select(obs.sigmas()>0)
        if (obs.indices().size() == 0): return return_fail
        i_sig_i = flex.mean( obs.data()/obs.sigmas() )
        return i_sig_i
      else:
        return 0
    result = []
    for i_bin in self.binner().range_all():
      sel =  self.binner().selection(i_bin)
      result.append(self.select(sel).i_over_sig_i(return_fail=return_fail) )

    return binned_data(binner=self.binner(),
                       data=result,
                       data_fmt="%7.4f")

  def mean_of_intensity_divided_by_epsilon(self,
                                           use_binning=False,
                                           return_fail=None):
    """ <I/epsilon> """
    assert not use_binning or self.binner is not None
    if (not use_binning):
      if (self.indices().size() == 0): return return_fail
      obs = None
      if self.is_real_array():
        if self.is_xray_amplitude_array():
          obs = self.f_as_f_sq()
        if self.is_xray_intensity_array():
          obs = self
      if obs is not None:
        weighted_mean = flex.mean( obs.data() /
                                   obs.epsilons().data().as_double() )
        return weighted_mean
      else:
        return return_fail
    result = []
    for i_bin in self.binner().range_all():
      sel =  self.binner().selection(i_bin)
      result.append(self.select(sel).mean_of_intensity_divided_by_epsilon(
        return_fail=return_fail) )
    return binned_data(binner=self.binner(),
                       data=result,
                       data_fmt="%7.4f")

  def mean_of_squared_sigma_divided_by_epsilon(self,
                                              use_binning=False,
                                              return_fail=None):
    """ <sigma^2/epsilon> """
    assert not use_binning or self.binner is not None
    if (not use_binning):
      if (self.sigmas().size() == 0): return return_fail
      weighted_mean = flex.mean( self.sigmas() /
                                 self.epsilons().data().as_double() )
      return weighted_mean

    result = []
    for i_bin in self.binner().range_all():
      sel =  self.binner().selection(i_bin)
      result.append(self.select(sel).mean_of_squared_sigma_divided_by_epsilon(
        return_fail=return_fail) )
    return binned_data(binner=self.binner(),
                       data=result,
                       data_fmt="%7.4f")


  def second_moment_of_intensities(self, use_binning=False):
    "<I^2>/(<I>)^2 (2.0 for untwinned, 1.5 for twinned data)"
    if (self.is_xray_intensity_array()):
      a = self
    else:
      a = self.f_as_f_sq()
      if (use_binning):
        a.use_binner_of(self)
    return a.second_moment(use_binning=use_binning)

  def wilson_ratio(self, use_binning=False):
    "(<F>)^2/<F^2> (0.785 for untwinned, 0.885 for twinned data)"
    if (not self.is_xray_intensity_array()):
      a = self
    else:
      a = self.f_sq_as_f()
      if (use_binning):
        a.use_binner_of(self)
    second_moment = a.second_moment(use_binning=use_binning)
    if (second_moment is None): return None
    if (not use_binning): return 1/second_moment
    result = []
    for sm in second_moment.data:
      if (sm is None or sm == 0): result.append(None)
      else: result.append(1/sm)
    return binned_data(binner=a.binner(), data=result, data_fmt="%7.4f")

  def show_r_free_flags_info(self,
        n_bins=10,
        binner_range="used",
        out=None,
        prefix=""):
    assert self.is_bool_array()
    assert binner_range in ["used", "all"]
    print >> out, prefix + "Number of work/free reflections by resolution:"
    if (n_bins is not None):
      self.setup_binner(n_bins=n_bins)
    else:
      assert self.binner() is not None
    n_works = []
    n_frees = []
    fmt = None
    for i_bin in getattr(self.binner(), "range_"+binner_range)():
      sel = self.binner().selection(i_bin)
      flags = self.data().select(sel)
      n_free = flags.count(True)
      n_work = flags.size() - n_free
      n_works.append(n_work)
      n_frees.append(n_free)
      legend = self.binner().bin_legend(i_bin)
      if (fmt is None):
        width = max(4, len(str(self.indices().size())))
        fmt = "%%%ds" % width
        print >> out, prefix + " ", " "*len(legend), \
          fmt%"work", fmt%"free", " %free"
        fmt = "%%%dd" % width
      print >> out, prefix + " ", legend, fmt%n_work, fmt%n_free, \
        "%5.1f%%" % (100.*n_free/max(1,n_work+n_free))
    n_free = self.data().count(True)
    n_work = self.data().size() - n_free
    print >> out, prefix + " ", (
      "%%%ds"%len(legend))%"overall", fmt%n_work, fmt%n_free, \
      "%5.1f%%" % (100.*n_free/max(1,n_work+n_free))
    return n_works, n_frees

  def r_free_flags_accumulation(self):
    assert self.is_bool_array()
    rc = flex.size_t(1, 0)
    ff = flex.double(1, 0)
    d = self.data()
    n = d.size()
    c = 0
    for i,f in enumerate(d):
      if (f):
        c += 1
        rc.append(i+1)
        ff.append(c/n)
    return group_args(reflection_counts=rc, free_fractions=ff)

  def r1_factor(self, other, assume_index_matching=False):
    """ sum ||F| - |F'|| / sum |F|
    where F is self.data() and F' is other.data() """
    assert (self.observation_type() is None
            or self.is_complex_array() or self.is_xray_amplitude_array())
    assert (self.observation_type() is None
            or other.is_complex_array() or other.is_xray_amplitude_array())
    if assume_index_matching:
      data0, data = self.data(), other.data()
    else:
      matching = match_indices(self.indices(), other.indices())
      assert not matching.have_singles()
      data0 = self.select(matching.pairs().column(0)).data()
      data = other.select(matching.pairs().column(1)).data()
    data  = flex.abs(data)
    data0 = flex.abs(data0)
    return flex.sum(flex.abs(data - data0)) / flex.sum(data0)

  def select(self, selection, negate=False, anomalous_flag=None):
    assert self.indices() is not None
    if (anomalous_flag is None):
      anomalous_flag = self.anomalous_flag()
    if (negate): selection = ~selection
    i = self.indices().select(selection)
    d = None
    if (self.data() is not None): d = self.data().select(selection)
    s = None
    if (self.sigmas() is not None): s = self.sigmas().select(selection)
    return array(set(self, i, anomalous_flag), d, s).set_observation_type(self)

  def sigma_filter(self, cutoff_factor, negate=False):
    assert self.data() is not None
    assert self.sigmas() is not None
    flags = flex.abs(self.data()) >= self.sigmas() * cutoff_factor
    return self.select(flags, negate)

  def min_f_over_sigma(self):
    result = None
    sigmas = self.sigmas()
    if(sigmas is not None):
      if(flex.min(sigmas) == 0.0):
        result = 0.0
      else:
        result = flex.min(self.data() / sigmas)
    return result

  def apply_scaling(self, target_max=None, factor=None):
    assert [target_max, factor].count(None) == 1
    assert self.data() is not None
    s = None
    if (target_max is not None):
      current_max = flex.max(flex.abs(self.data()))
      if (current_max == 0): return self.deep_copy()
      factor = target_max / current_max
    d = self.data() * factor
    if (self.sigmas() is not None): s = self.sigmas() * factor
    return (array(
      miller_set = set.deep_copy(self),
      data=d,
      sigmas=s)
      .set_info(self.info())
      .set_observation_type(self))

  def mean(self,
        use_binning=False,
        use_multiplicities=False,
        squared=False,
        rms=False):
    assert squared is False or rms is False
    if (not use_binning):
      if (self.data().size() == 0): return None
      if (not squared and not rms):
        if (not use_multiplicities):
          return flex.mean(self.data())
        else:
          return flex.mean_weighted(
            self.data(),
            self.multiplicities().data().as_double())
      if (not use_multiplicities):
        result = flex.mean_sq(self.data())
      else:
        result = flex.mean_sq_weighted(
          self.data(),
          self.multiplicities().data().as_double())
      if (rms): return math.sqrt(result)
      return result
    assert self.binner() is not None
    data = []
    for i_bin in self.binner().range_all():
      sel = self.binner().selection(i_bin)
      data.append(self.select(sel).mean(
        use_multiplicities=use_multiplicities,
        squared=squared,
        rms=rms))
    return binned_data(binner=self.binner(), data=data)

  def mean_sq(self, use_binning=False, use_multiplicities=False):
    return self.mean(
      use_binning=use_binning,
      use_multiplicities=use_multiplicities,
      squared=True)

  def rms(self, use_binning=False, use_multiplicities=False):
    return self.mean(
      use_binning=use_binning,
      use_multiplicities=use_multiplicities,
      rms=True)

  def rms_filter(self,
        cutoff_factor,
        use_binning=False,
        use_multiplicities=False,
        negate=False):
    rms = self.rms(
      use_binning=use_binning,
      use_multiplicities=use_multiplicities)
    abs_data = flex.abs(self.data())
    if (not use_binning):
      keep = abs_data <= cutoff_factor * rms
    else:
      keep = self.all_selection()
      for i_bin in self.binner().range_used():
        keep &= ~self.binner().selection(i_bin) \
             | (abs_data <= cutoff_factor * rms.data[i_bin])
    return self.select(keep, negate)

  def statistical_mean(self, use_binning=0):
    if (not use_binning):
      result = statistical_mean(
        self.space_group(), self.anomalous_flag(), self.indices(), self.data())
    else:
      result = flex.double()
      for i_bin in self.binner().range_used():
        sel = self.binner().selection(i_bin)
        if (sel.count(True) == 0):
          result.append(0)
        else:
          result.append(statistical_mean(
            self.space_group(), self.anomalous_flag(),
            self.indices().select(sel),
            self.data().select(sel)))
    return result

  def count_and_fraction_in_bins(self,
        data_value_to_count,
        count_not_equal=False):
    assert self.binner() is not None
    assert self.data().size() == self.indices().size()
    max_n = 0
    results = []
    for i_bin in self.binner().range_all():
      sel = self.binner().selection(i_bin)
      data_sel = self.data().select(sel)
      n = data_sel.count(data_value_to_count)
      if (count_not_equal): n = data_sel.size() - n
      max_n = max(max_n, n)
      results.append((n, n/(max(1,data_sel.size()))))
    data_fmt = "%%%dd %%6.4f" % len("%d"%max_n)
    return binned_data(binner=self.binner(), data=results, data_fmt=data_fmt)

  def remove_patterson_origin_peak(self):
    assert self.observation_type() is None or self.is_xray_intensity_array()
    s_mean = self.statistical_mean(use_binning=True)
    result_data = self.data().deep_copy()
    for i_bin in self.binner().range_used():
      sel = self.binner().array_indices(i_bin)
      if (sel.size() > 0):
        result_data.set_selected(
          sel, self.data().select(sel) - s_mean[i_bin-1])
    return array(self, result_data)

  def quasi_normalized_as_normalized(self):
    assert self.observation_type() is None or self.is_xray_amplitude_array()
    return array(
      miller_set=self,
      data=self.data()/flex.sqrt(self.epsilons().data().as_double()))

  def quasi_normalize_structure_factors(self, d_star_power=1):
    assert self.binner() is not None
    assert self.binner().n_bin_d_too_large_or_small() == 0
    assert self.data().all_ge(0)
    assert self.observation_type() is None or self.is_xray_amplitude_array()
    epsilons = self.epsilons().data().as_double()
    mean_f_sq_over_epsilon = flex.double()
    for i_bin in self.binner().range_used():
      sel = self.binner().selection(i_bin)
      sel_f_sq = flex.pow2(self.data().select(sel))
      if (sel_f_sq.size() > 0):
        sel_epsilons = epsilons.select(sel)
        sel_f_sq_over_epsilon = sel_f_sq / sel_epsilons
        mean_f_sq_over_epsilon.append(flex.mean(sel_f_sq_over_epsilon))
      else:
        mean_f_sq_over_epsilon.append(0)
    mean_f_sq_over_epsilon_interp = self.binner().interpolate(
      mean_f_sq_over_epsilon, d_star_power)
    assert mean_f_sq_over_epsilon_interp.all_gt(0)
    f_sq = flex.pow2(self.data())
    q = flex.sqrt(f_sq / mean_f_sq_over_epsilon_interp)
    assert q.all_ge(0)
    return array(self, q)

  def phased_translation_function_coeff(self, phase_source, f_calc, fom=None):
    assert self.indices().size() == f_calc.indices().size()
    assert self.indices().size() == phase_source.indices().size()
    assert self.is_real_array()
    assert f_calc.is_complex_array()
    if(fom is not None):
      assert fom.is_real_array()
      assert self.indices().size() == fom.indices().size()
    f1 = self.array(data = self.data()).phase_transfer(
      phase_source = phase_source).data()
    f2 = flex.conj(f_calc.data())
    coeff = f1 * f2
    if(fom is not None):
      coeff = coeff * fom.data()
    if(fom is None):
      f3 = flex.sum(flex.abs(self.data()) * flex.abs(self.data()))
    else:
      f3 = flex.sum(fom.data() * fom.data() * flex.abs(self.data()) *
        flex.abs(self.data()))
    f4 = flex.sum(flex.abs(f_calc.data()) * flex.abs(f_calc.data()))
    den = math.sqrt(f3 * f4)
    assert den != 0
    return self.array(data = coeff/den)

  def __abs__(self):
    return array(self, flex.abs(self.data()), self.sigmas())

  def norm(self):
    assert isinstance(self.data(), flex.complex_double)
    return array(self, flex.norm(self.data()))

  def arg(self, deg=False):
    return array(self, flex.arg(self.data(), deg))

  def amplitudes(self):
    assert isinstance(self.data(), flex.complex_double)
    assert self.sigmas() is None
    return abs(self)

  def phases(self, deg=False):
    assert isinstance(self.data(), flex.complex_double)
    assert self.sigmas() is None
    return self.arg(deg)

  def merge_equivalents(self):
    return merge_equivalents(self)

  def as_non_anomalous_array(self):
    return array(
      miller_set=self.as_non_anomalous_set(),
      data=self.data(),
      sigmas=self.sigmas())

  def average_bijvoet_mates(self):
    assert self.observation_type() is None or self.is_xray_amplitude_array()
    if (self.is_complex_array() or self.is_hendrickson_lattman_array()):
      # centrics need special attention
      # very inefficient but simple implementation
      return self \
        .expand_to_p1() \
        .as_non_anomalous_array() \
        .merge_equivalents().array() \
        .customized_copy(crystal_symmetry=self) \
        .merge_equivalents().array()
    else:
      return self.as_non_anomalous_array().merge_equivalents().array()

  def eliminate_sys_absent(self, integral_only=False, log=None, prefix=""):
    sys_absent_flags = self.sys_absent_flags(
      integral_only=integral_only).data()
    n = sys_absent_flags.count(True)
    if (n == 0): return self
    if (log is not None):
      if (integral_only): q = "integral "
      else: q = ""
      if (   isinstance(self.data(), flex.double)
          or isinstance(self.data(), flex.complex_double)):
        data_abs = flex.abs(self.data())
        c = ":"
      else:
        data_abs = None
        c = "."
      print >> log, prefix + "Removing %d %ssystematic absence%s%s" % (
        n, q, plural_s(n)[1], c)
    result = self.select(selection=~sys_absent_flags)
    if (log is not None):
      if (data_abs is not None):
        print >> log, prefix + "  Average absolute value of:"
        mean_absences = flex.mean(data_abs.select(sys_absent_flags))
        print >> log, prefix + "    Absences: %.6g" % mean_absences
        if (n != data_abs.size()):
          mean_others = flex.mean(data_abs.select(~sys_absent_flags))
          print >> log, prefix + "      Others: %.6g" % mean_others
          if (mean_others != 0 and mean_others > mean_absences * 1.e-20):
            print >> log, prefix + "       Ratio: %.6g" % (
              mean_absences / mean_others)
      print >> log
    return result

  def __add__(self, other):
    assert self.indices() is not None
    assert self.data() is not None
    if (type(other) != type(self)):
      # add a scalar
      return array(self, self.data() + other)
    # add arrays
    assert other.indices() is not None
    assert other.data() is not None
    match = match_indices(self.indices(), other.indices())
    i = match.paired_miller_indices(0)
    d = match.plus(self.data(), other.data())
    s = None
    if (self.sigmas() is not None and other.sigmas() is not None):
      s = match.additive_sigmas(self.sigmas(), other.sigmas())
    return array(set(self, i), d, s)

  def __imul__(self, other):
    assert self.indices() is not None
    assert self.data() is not None
    data = self.data()
    data *= other
    sigmas = self.sigmas()
    if sigmas is not None: sigmas *= other
    return self

  def __mul__(self, other):
    result = self.copy()
    result *= other
    return result

  def generate_bijvoet_mates(self):
    if (self.anomalous_flag()): return self
    sel = ~self.centric_flags().data()
    indices = self.indices().deep_copy()
    indices.extend(-indices.select(sel))
    data = None
    sigmas = None
    if (self.data() is not None):
      data = self.data().deep_copy()
      if (self.is_complex_array()):
        data.extend(flex.conj(data.select(sel)))
      elif (self.is_hendrickson_lattman_array()):
        data.extend(data.select(sel).conj())
      else:
        data.extend(data.select(sel))
    if (self.sigmas() is not None):
      sigmas = self.sigmas().deep_copy()
      sigmas.extend(sigmas.select(sel))
    return array(
      miller_set=set(
        crystal_symmetry=self,
        indices=indices,
        anomalous_flag=True),
      data=data,
      sigmas=sigmas)

  def correlation(self,
        other,
        use_binning=False,
        assert_is_similar_symmetry=True):
    if (assert_is_similar_symmetry):
      assert self.is_similar_symmetry(other)
    assert self.is_real_array()
    assert other.is_real_array()
    assert not use_binning or self.binner() is not None
    lhs = self
    if (lhs.anomalous_flag() and not other.anomalous_flag()):
      other = other.generate_bijvoet_mates()
    elif (not lhs.anomalous_flag() and other.anomalous_flag()):
      lhs = lhs.generate_bijvoet_mates()
    lhs, other = lhs.common_sets(
      other=other, assert_is_similar_symmetry=assert_is_similar_symmetry)
    if (not use_binning):
      return flex.linear_correlation(lhs.data(), other.data())
    lhs.use_binning_of(self)
    data = []
    for i_bin in self.binner().range_all():
      sel = lhs.binner().selection(i_bin)
      correlation = flex.linear_correlation(
        lhs.data().select(sel),
        other.data().select(sel))
      if (not correlation.is_well_defined()): data.append(None)
      else: data.append(correlation.coefficient())
    return binned_data(binner=lhs.binner(), data=data, data_fmt="%6.3f")

  def show_array(self, f=None, prefix="", deg=None):
    "Listing of Miller indices and data"
    if (f is None): f = sys.stdout
    assert self.data().size() == self.indices().size()
    if (self.is_complex_array() and deg is not None):
      for h,d in zip(self.indices(), self.data()):
        print >> f, prefix + str(h), d, complex_math.abs_arg(d, deg=deg)
    elif (self.sigmas() is None):
      for h,d in zip(self.indices(), self.data()):
        print >> f, prefix + str(h), d
    else:
      assert self.sigmas().size() == self.indices().size()
      for h,d,s in zip(self.indices(), self.data(), self.sigmas()):
        print >> f, prefix + str(h), d, s
    return self

  def map_correlation(self, other):
    d1 = flex.abs(self.data())
    d2 = flex.abs(other.data())
    p1 = self.phases().data()
    p2 = other.phases().data()
    factor = math.sqrt( flex.sum_sq(d1) * flex.sum_sq(d2) )
    if (factor > 0):
      return flex.sum( d1 * d2 * flex.cos(p2 - p1) ) / factor
    return None

  def fft_map(self, resolution_factor=1/3,
                    d_min=None,
                    grid_step=None,
                    symmetry_flags=None,
                    mandatory_factors=None,
                    max_prime=5,
                    assert_shannon_sampling=True,
                    f_000=None):
    return fft_map(
      crystal_gridding=self.crystal_gridding(
        d_min=d_min,
        resolution_factor=resolution_factor,
        grid_step=grid_step,
        symmetry_flags=symmetry_flags,
        mandatory_factors=mandatory_factors,
        max_prime=max_prime,
        assert_shannon_sampling=assert_shannon_sampling),
      fourier_coefficients=self,
      f_000=f_000)

  def patterson_map(self, resolution_factor=1/3,
                          d_min=None,
                          symmetry_flags=None,
                          mandatory_factors=None,
                          max_prime=5,
                          assert_shannon_sampling=True,
                          f_000=None,
                          sharpening=False,
                          origin_peak_removal=False):
    f_patt = self.patterson_symmetry()
    return patterson_map(
      crystal_gridding=f_patt.crystal_gridding(
        resolution_factor=resolution_factor,
        d_min=d_min,
        symmetry_flags=symmetry_flags,
        mandatory_factors=mandatory_factors,
        max_prime=max_prime,
        assert_shannon_sampling=assert_shannon_sampling),
      f_patt=f_patt,
      f_000=f_000,
      sharpening=sharpening,
      origin_peak_removal=origin_peak_removal)

  def export_as_cns_hkl(self,
        file_object,
        file_name=None,
        info=[],
        array_names=None,
        r_free_flags=None):
    from iotbx.cns.miller_array import export_as_cns_hkl as implementation
    implementation(self,
      file_object=file_object,
      file_name=file_name,
      info=info,
      array_names=array_names,
      r_free_flags=r_free_flags)

  def as_mtz_dataset(self,
        column_root_label,
        column_types=None,
        label_decorator=None,
        title=None,
        crystal_name="crystal",
        project_name="project",
        dataset_name="dataset",
        wavelength=1.0):
    import iotbx.mtz
    return iotbx.mtz.miller_array_as_mtz_dataset(self,
      column_root_label=column_root_label,
      column_types=column_types,
      label_decorator=label_decorator,
      title=title,
      crystal_name=crystal_name,
      project_name=project_name,
      dataset_name=dataset_name,
      wavelength=wavelength)

  def as_phases_phs(self,
        out,
        scale_amplitudes=True,
        phases=None,
        phases_deg=None,
        figures_of_merit=None):
    import iotbx.phases
    iotbx.phases.miller_array_as_phases_phs(
      self=self,
      out=out,
      scale_amplitudes=scale_amplitudes,
      phases=phases,
      phases_deg=phases_deg,
      figures_of_merit=figures_of_merit)

class crystal_symmetry_is_compatible_with_symmetry_from_file:

  def __init__(self, miller_array,
         unit_cell_relative_length_tolerance=0.02,
         unit_cell_absolute_angle_tolerance=3.,
         working_point_group=None):
    self.miller_array = miller_array
    self.unit_cell_is_compatible = True
    self.space_group_is_compatible = True
    info = miller_array.info()
    if (info is None or info.crystal_symmetry_from_file is None): return
    ucf = info.crystal_symmetry_from_file.unit_cell()
    if (ucf is not None):
      uc = miller_array.unit_cell()
      if (uc is not None
          and not uc.is_similar_to(
            other=ucf,
            relative_length_tolerance=unit_cell_relative_length_tolerance,
            absolute_angle_tolerance=unit_cell_absolute_angle_tolerance)):
        self.unit_cell_is_compatible = False
    sgf = info.crystal_symmetry_from_file.space_group()
    if (sgf is not None):
      if (working_point_group is None):
        sg = miller_array.space_group()
        if (sg is not None):
          working_point_group = sg.build_derived_point_group()
      if (working_point_group is not None):
        point_group_from_file = sgf.build_derived_point_group()
        if (point_group_from_file != working_point_group):
          self.space_group_is_compatible = False

  def format_error_message(self, data_description):
    ma = self.miller_array
    what = []
    msg = ["  %s: %s" % (data_description, str(ma.info()))]
    if (not self.unit_cell_is_compatible):
      what.append("unit cell")
      msg.extend([
        "  Unit cell from file: " + str(
          ma.info().crystal_symmetry_from_file.unit_cell()),
        "    Working unit cell: " + str(ma.unit_cell())])
    if (not self.space_group_is_compatible):
      what.append("space group")
      msg.extend([
        "  Space group from file: " + str(
          ma.info().crystal_symmetry_from_file.space_group_info()),
        "    Working space group: " + str(ma.space_group_info())])
    if (len(what) != 0):
      if (len(what) == 2): what = ["crystal symmetry"]
      return "\n".join([
        "Working %s is not compatible with %s" % (what[0], what[0])
        + " from reflection file:"] + msg)
    return None

class merge_equivalents(object):

  def __init__(self, miller_array):
    self._r_linear = None
    self._r_square = None
    self._r_int = None
    merge_type = {
      "bool": ext.merge_equivalents_exact_bool,
      "int": ext.merge_equivalents_exact_int,
      "complex_double": ext.merge_equivalents_complex,
      "hendrickson_lattman": ext.merge_equivalents_hl,
    }.get(miller_array.data().__class__.__name__, None)
    if (merge_type is not None):
      asu_array = miller_array.map_to_asu()
      perm = asu_array.sort_permutation(by_value="packed_indices")
      merge_ext = merge_type(
        asu_array.indices().select(perm),
        asu_array.data().select(perm))
      sigmas = None
      del asu_array
    elif (isinstance(miller_array.data(), flex.double)):
      asu_set = set.map_to_asu(miller_array)
      perm = asu_set.sort_permutation(by_value="packed_indices")
      if (miller_array.sigmas() is not None):
        merge_ext = ext.merge_equivalents_obs(
          asu_set.indices().select(perm),
          miller_array.data().select(perm),
          miller_array.sigmas().select(perm))
        sigmas = merge_ext.sigmas
      else:
        merge_ext = ext.merge_equivalents_real(
          asu_set.indices().select(perm),
          miller_array.data().select(perm))
        sigmas = None
      del asu_set
      self._r_linear = merge_ext.r_linear
      self._r_square = merge_ext.r_square
      self._r_int = merge_ext.r_int
    else:
      raise RuntimeError(
        "cctbx.miller.merge_equivalents: unsupported array type:\n"
        "  data: %s\n"
        "  sigmas: %s" % (
          repr(miller_array.data()), repr(miller_array.sigmas())))
    self._array = array(
      miller_set=set(
        crystal_symmetry=miller_array,
        indices=merge_ext.indices,
        anomalous_flag=miller_array.anomalous_flag()),
      data=merge_ext.data,
      sigmas=sigmas).set_observation_type(miller_array)
    self._redundancies = merge_ext.redundancies

  def array(self):
    return self._array

  def redundancies(self):
    return self._array.array(data=self._redundancies)

  def r_linear(self):
    "R-linear = sum(abs(data - mean(data))) / sum(abs(data))"
    if (self._r_linear is None): return None
    return self._array.array(data=self._r_linear)

  def r_square(self):
    "R-square = sum((data - mean(data))**2) / sum(data**2)"
    if (self._r_square is None): return None
    return self._array.array(data=self._r_square)

  def r_int(self):
    return self._r_int

  def r_sigma(self):
    return flex.sum(self.array().sigmas()) / flex.sum(self.array().data())

  def show_summary(self, n_bins=10, out=None, prefix=""):
    if (out is None): out = sys.stdout
    redundancies = self.redundancies().as_double()
    redundancies.setup_binner(n_bins=n_bins)
    red_mean = redundancies.mean(use_binning=True)
    selection = self.redundancies().data() > 1
    r_linear = self.r_linear()
    if (r_linear is not None):
      r_linear = r_linear.select(selection)
      r_linear.use_binning_of(redundancies)
      r_l_mean = r_linear.mean(use_binning=True)
    r_square = self.r_square()
    if (r_square is not None):
      r_square = r_square.select(selection)
      r_square.use_binning_of(redundancies)
      r_s_mean = r_square.mean(use_binning=True)
    fields = ["", "Min", "Max", "Mean"]
    if (r_linear is None): fields.append("")
    else: fields.append("R-linear")
    if (r_square is None): fields.append("")
    else: fields.append("R-square")
    lines = [fields]
    max_lengths = [len(field) for field in lines[0]]
    for i_bin in red_mean.binner.range_all():
      fields = [red_mean.binner.bin_legend(i_bin=i_bin, show_counts=False)]
      sel = red_mean.binner.selection(i_bin)
      r = self.redundancies().select(sel).data()
      if (r.size() == 0):
        fields.extend(["", ""])
      else:
        fields.append("%d" % flex.min(r))
        fields.append("%d" % flex.max(r))
      if (red_mean.data[i_bin] is None):
        fields.append("")
      else:
        fields.append("%.3f" % red_mean.data[i_bin])
      if (r_linear is None or r_l_mean.data[i_bin] is None):
        fields.append("")
      else:
        fields.append("%.4f" % r_l_mean.data[i_bin])
      if (r_square is None or r_s_mean.data[i_bin] is None):
        fields.append("")
      else:
        fields.append("%.4f" % r_s_mean.data[i_bin])
      lines.append(fields)
      max_lengths = [max(max_len,len(field))
        for max_len,field in zip(max_lengths, fields)]
    if (r_linear is not None):
      print >> out, prefix+self.r_linear.__doc__
    if (r_square is not None):
      print >> out, prefix+self.r_square.__doc__
    if (r_linear is not None or r_square is not None):
      print >> out, prefix+"In these sums single measurements are excluded."
    n = flex.sum(flex.int(max_lengths[1:4]))+4
    fmt = "%%%ds  %%%ds  %%%ds  %%%ds" % tuple(
      [max_lengths[0], n] + max_lengths[4:])
    fields = ["", "Redundancy"+" "*((n-10+1)//2)]
    for r in [r_linear, r_square]:
      if (r is None): fields.append("")
      else: fields.append("Mean  ")
    print >> out, prefix + (fmt % tuple(fields)).rstrip()
    fmt = "%%%ds  %%%ds  %%%ds  %%%ds  %%%ds  %%%ds" % tuple(max_lengths)
    for fields in lines:
      print >> out, prefix + (fmt % tuple(fields)).rstrip()

class fft_map(maptbx.crystal_gridding):

  def __init__(self, crystal_gridding, fourier_coefficients, f_000=None):
    maptbx.crystal_gridding._copy_constructor(self, crystal_gridding)
    assert fourier_coefficients.anomalous_flag() in (False, True)
    assert fourier_coefficients.unit_cell().is_similar_to(self.unit_cell())
    assert fourier_coefficients.space_group() == self.space_group()
    assert isinstance(fourier_coefficients.data(), flex.complex_double)
    self._anomalous_flag = fourier_coefficients.anomalous_flag()
    if (not self.anomalous_flag()):
      rfft = fftpack.real_to_complex_3d(self.n_real())
      n_complex = rfft.n_complex()
    else:
      cfft = fftpack.complex_to_complex_3d(self.n_real())
      n_complex = cfft.n()
    map = maptbx.structure_factors.to_map(
      space_group=self.space_group(),
      anomalous_flag=self.anomalous_flag(),
      miller_indices=fourier_coefficients.indices(),
      structure_factors=fourier_coefficients.data(),
      n_real=self.n_real(),
      map_grid=flex.grid(n_complex),
      conjugate_flag=True)
    if (f_000 is not None):
      assert map.complex_map()[0] == 0j
      map.complex_map()[0] = complex(f_000)
    if (not self.anomalous_flag()):
      self._real_map = rfft.backward(map.complex_map())
    else:
      self._complex_map = cfft.backward(map.complex_map())

  def anomalous_flag(self):
    return self._anomalous_flag

  def real_map(self):
    if (not self.anomalous_flag()):
      return self._real_map
    else:
      return flex.real(self._complex_map)

  def real_map_unpadded(self):
    result = self.real_map()
    if (not result.is_padded()): return result
    return maptbx.copy(result, flex.grid(result.focus()))

  def complex_map(self):
    assert self.anomalous_flag()
    return self._complex_map

  def statistics(self):
    return maptbx.statistics(self.real_map())

  def apply_volume_scaling(self):
    scale = 1./self.unit_cell().volume()
    if (not self.anomalous_flag()):
      self._real_map *= scale
    else:
      self._complex_map *= scale
    return self

  def apply_sigma_scaling(self):
    statistics = self.statistics()
    if (not self.anomalous_flag()):
      if (statistics.sigma() != 0):
        self._real_map /= statistics.sigma()
    else:
      if (statistics.sigma() != 0):
        self._complex_map /= complex(statistics.sigma())
    return self

  def peak_search(self, parameters=None, verify_symmetry=True):
    return self.tags().peak_search(
      parameters=parameters,
      map=self.real_map(),
      verify_symmetry=verify_symmetry)

def patterson_map(crystal_gridding, f_patt, f_000=None,
                  sharpening=False,
                  origin_peak_removal=False):
  assert f_patt.is_patterson_symmetry()
  if (sharpening):
    f_patt.setup_binner(auto_binning=True)
    f_patt = f_patt.quasi_normalize_structure_factors()
  i_patt = f_patt.f_as_f_sq()
  if (origin_peak_removal):
    i_patt.setup_binner(auto_binning=True)
    i_patt = i_patt.remove_patterson_origin_peak()
  i_patt = array(i_patt, data=flex.polar(i_patt.data(), 0))
  if (f_000 is not None):
    f_000 = f_000 * f_000
  return fft_map(crystal_gridding, i_patt, f_000)
