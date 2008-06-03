from __future__ import generators

import cctbx.sgtbx

import boost.python
ext = boost.python.import_ext("cctbx_maptbx_ext")
from cctbx_maptbx_ext import *

from cctbx import crystal
from cctbx import sgtbx
from cctbx.array_family import flex
from scitbx import matrix
from scitbx.python_utils import dicts
from libtbx import adopt_init_args
import sys, os

debug_peak_cluster_analysis = os.environ.get(
  "CCTBX_MAPTBX_DEBUG_PEAK_CLUSTER_ANALYSIS", "")

def value_at_closest_grid_point(map, x_frac):
  return map[closest_grid_point(map.accessor(), x_frac)]

flex.int.value_at_closest_grid_point = value_at_closest_grid_point
flex.double.value_at_closest_grid_point = value_at_closest_grid_point
flex.double.eight_point_interpolation = eight_point_interpolation

class statistics(ext.statistics):

  def __init__(self, map):
    ext.statistics.__init__(self, map)

class _statistics(boost.python.injector, ext.statistics):

  def show_summary(self, f=None, prefix=""):
    if (f is None): f = sys.stdout
    print >> f, prefix + "max %.6g" % (self.max())
    print >> f, prefix + "min %.6g" % (self.min())
    print >> f, prefix + "mean %.6g" % (self.mean())
    print >> f, prefix + "sigma %.6g" % (self.sigma())

use_space_group_symmetry = sgtbx.search_symmetry_flags(
  use_space_group_symmetry=True)

class peak_list(ext.peak_list):

  def __init__(self, data,
                     tags,
                     peak_search_level=1,
                     max_peaks=0,
                     peak_cutoff=None,
                     interpolate=True):
    if (peak_cutoff is None):
      ext.peak_list.__init__(self,
        data, tags, peak_search_level, max_peaks, interpolate)
    else:
      ext.peak_list.__init__(self,
        data, tags, peak_search_level, peak_cutoff, max_peaks, interpolate)

def as_CObjectZYX(map_unit_cell, first, last, apply_sigma_scaling=True):
  return ext.as_CObjectZYX(map_unit_cell, first, last, apply_sigma_scaling)

structure_factors = dicts.easy(
  to_map=structure_factors_to_map,
  from_map=structure_factors_from_map)

class crystal_gridding(object):

  def __init__(self, unit_cell,
                     d_min=None,
                     resolution_factor=None,
                     step=None,
                     symmetry_flags=None,
                     space_group_info=None,
                     mandatory_factors=None,
                     max_prime=5,
                     assert_shannon_sampling=True):
    assert [d_min, step].count(None) == 1
    if (step is not None):
      d_min = step*2
      resolution_factor = 0.5
    elif (resolution_factor is None):
      resolution_factor = 1/3.
    if (symmetry_flags is not None): assert space_group_info is not None
    if (mandatory_factors is None): mandatory_factors = (1,1,1)
    assert len(mandatory_factors) == 3
    adopt_init_args(self, locals(), hide=True)
    if (symmetry_flags is not None):
      self._n_real = determine_gridding(
        unit_cell, d_min, resolution_factor,
        symmetry_flags, space_group_info.type(),
        mandatory_factors, max_prime, assert_shannon_sampling)
    else:
      self._n_real = determine_gridding(
        unit_cell, d_min, resolution_factor,
        mandatory_factors, max_prime, assert_shannon_sampling)

  def _copy_constructor(self, other):
    self._unit_cell = other._unit_cell
    self._d_min = other._d_min
    self._resolution_factor = other._resolution_factor
    self._symmetry_flags = other._symmetry_flags
    self._space_group_info = other._space_group_info
    self._mandatory_factors = other._mandatory_factors
    self._max_prime = other._max_prime
    self._n_real = other._n_real

  def unit_cell(self):
    return self._unit_cell

  def d_min(self):
    return self._d_min

  def resolution_factor(self):
    return self._resolution_factor

  def symmetry_flags(self):
    return self._symmetry_flags

  def space_group_info(self):
    return self._space_group_info

  def change_space_group(self, space_group_info):
    assert (space_group_info.group().refine_gridding(self.n_real())
            == self.n_real())
    self._space_group_info = space_group_info

  def mandatory_factors(self):
    return self._mandatory_factors

  def max_prime(self):
    return self._max_prime

  def n_real(self):
    return self._n_real

  def space_group(self):
    assert self.space_group_info() is not None
    return self.space_group_info().group()

  def crystal_symmetry(self):
    assert self.space_group_info() is not None
    return crystal.symmetry(
      unit_cell=self.unit_cell(),
      space_group_info=self.space_group_info())

  def n_grid_points(self):
    result = 1
    for n in self.n_real():
      result *= n
    return result

  def tags(self):
    return crystal_gridding_tags(self)

class crystal_gridding_tags(crystal_gridding):

  def __init__(self, gridding):
    crystal_gridding._copy_constructor(self, gridding)
    assert gridding.symmetry_flags() is not None
    self._tags = grid_tags(dim=self.n_real())
    self._tags.build(
      space_group_type=self.space_group_info().type(),
      symmetry_flags=self.symmetry_flags())
    assert self._tags.n_grid_misses() == 0

  def tags(self):
    return self._tags

  def peak_search(self, parameters, map, verify_symmetry=True):
    if (parameters is None):
      parameters = peak_search_parameters()
    if (verify_symmetry):
      assert self._tags.verify(map)
    if (map.accessor().is_padded()):
      map = copy(map, flex.grid(map.focus()))
    grid_peaks = peak_list(
      data=map,
      tags=self._tags.tag_array(),
      peak_search_level=parameters.peak_search_level(),
      max_peaks=parameters.max_peaks(),
      peak_cutoff=parameters.peak_cutoff(),
      interpolate=parameters.interpolate())
    if (parameters.min_distance_sym_equiv() is None):
      return grid_peaks
    return peak_cluster_analysis(
      peak_list=grid_peaks,
      special_position_settings=crystal.special_position_settings(
        crystal_symmetry=self.crystal_symmetry(),
        min_distance_sym_equiv=parameters.min_distance_sym_equiv()),
      general_positions_only=parameters.general_positions_only(),
      effective_resolution=parameters.effective_resolution(),
      significant_height_fraction=parameters.significant_height_fraction(),
      cluster_height_fraction=parameters.cluster_height_fraction(),
      min_cross_distance=parameters.min_cross_distance(),
      max_clusters=parameters.max_clusters())

class peak_search_parameters(object):

  def __init__(self, peak_search_level=1,
                     max_peaks=0,
                     peak_cutoff=None,
                     interpolate=True,
                     min_distance_sym_equiv=None,
                     general_positions_only=False,
                     effective_resolution=None,
                     significant_height_fraction=None,
                     cluster_height_fraction=None,
                     min_cross_distance=None,
                     max_clusters=None):
    adopt_init_args(self, locals(), hide=True)

  def _copy_constructor(self, other):
    self._peak_search_level = other._peak_search_level
    self._max_peaks = other._max_peaks
    self._peak_cutoff = other._peak_cutoff
    self._interpolate = other._interpolate
    self._min_distance_sym_equiv = other._min_distance_sym_equiv
    self._general_positions_only = other._general_positions_only
    self._effective_resolution = other._effective_resolution
    self._significant_height_fraction = other._significant_height_fraction
    self._cluster_height_fraction = other._cluster_height_fraction
    self._min_cross_distance = other._min_cross_distance
    self._max_clusters = other._max_clusters

  def peak_search_level(self):
    return self._peak_search_level

  def max_peaks(self):
    return self._max_peaks

  def peak_cutoff(self):
    return self._peak_cutoff

  def interpolate(self):
    return self._interpolate

  def min_distance_sym_equiv(self):
    return self._min_distance_sym_equiv

  def general_positions_only(self):
    return self._general_positions_only

  def effective_resolution(self):
    return self._effective_resolution

  def significant_height_fraction(self):
    return self._significant_height_fraction

  def cluster_height_fraction(self):
    return self._cluster_height_fraction

  def min_cross_distance(self):
    return self._min_cross_distance

  def max_clusters(self):
    return self._max_clusters

class cluster_site_info(object):

  def __init__(self, peak_list_index, grid_index, grid_height, site, height):
    self.peak_list_index = peak_list_index
    self.grid_index = grid_index
    self.grid_height = grid_height
    self.site = site
    self.height = height

class peak_cluster_analysis(object):

  def __init__(self, peak_list,
                     special_position_settings,
                     general_positions_only=False,
                     effective_resolution=None,
                     significant_height_fraction=None,
                     cluster_height_fraction=None,
                     min_cross_distance=None,
                     max_clusters=None):
    if (effective_resolution is not None):
      if (significant_height_fraction is None):
          significant_height_fraction = 1/5.
      if (cluster_height_fraction is None):
          cluster_height_fraction = 1/3.
    if (min_cross_distance is None):
        min_cross_distance = special_position_settings.min_distance_sym_equiv()
    adopt_init_args(self, locals(), hide=True)
    assert self._min_cross_distance is not None
    self._gridding = peak_list.gridding()
    if (effective_resolution is not None):
      self._is_processed = flex.bool(peak_list.size(), False)
    else:
      self._is_processed = None
    if (   effective_resolution is not None
        or debug_peak_cluster_analysis == "use_old"):
      self._site_cluster_analysis = None
      self.next = self.next_with_effective_resolution
      self.all = self.all_with_effective_resolution
    else:
      self._site_cluster_analysis = \
        self._special_position_settings.site_cluster_analysis(
          min_cross_distance=self._min_cross_distance,
          min_self_distance
            =self._special_position_settings.min_distance_sym_equiv(),
          general_positions_only=self._general_positions_only)
      self.next = self.next_site_cluster_analysis
      self.all = self.all_site_cluster_analysis
    self._peak_list_indices = flex.size_t()
    self._peak_list_index = 0
    self._sites = flex.vec3_double()
    self._heights = flex.double()
    self._fixed_site_indices = flex.size_t()

  def __iter__(self):
    while 1:
      site_info = self.next()
      if site_info is None: break
      yield site_info

  def peak_list(self):
    return self._peak_list

  def special_position_settings(self):
    return self._special_position_settings

  def general_positions_only(self):
    return self._general_positions_only

  def effective_resolution(self):
    return self._effective_resolution

  def significant_height_fraction(self):
    return self._significant_height_fraction

  def cluster_height_fraction(self):
    return self._cluster_height_fraction

  def min_cross_distance(self):
    return self._min_cross_distance

  def max_clusters(self):
    return self._max_clusters

  def site_cluster_analysis(self):
    return self._site_cluster_analysis

  def peak_list_indices(self):
    return self._peak_list_indices

  def fixed_site_indices(self):
    return self._fixed_site_indices

  def sites(self):
    return self._sites

  def heights(self):
    return self._heights

  def max_grid_height(self):
    if (self._peak_list.size() == 0):
      return None
    return self._peak_list.heights()[0]

  def append_fixed_site(self, site, height=0):
    if (self._site_cluster_analysis is not None):
      self._site_cluster_analysis.insert_fixed_site_frac(original_site=site)
    self._fixed_site_indices.append(self._sites.size())
    self._sites.append(site)
    self._heights.append(height)
    self._peak_list_indices.append(self._peak_list.size())

  def discard_last(self):
    assert self._peak_list_indices.size() > 0
    if (self._site_cluster_analysis is not None):
      self._site_cluster_analysis.discard_last()
    self._peak_list_indices.pop_back()
    self._sites.pop_back()
    self._heights.pop_back()

  def next_site_cluster_analysis(self):
    while 1:
      peak_list_index = self._peak_list_index
      if (peak_list_index >= self._peak_list.size()): return None
      self._peak_list_index += 1
      site_symmetry = self._special_position_settings.site_symmetry(
        site=self._peak_list.sites()[peak_list_index])
      site = site_symmetry.exact_site()
      if (not self._site_cluster_analysis.process_site_frac(
                original_site=site,
                site_symmetry_ops=site_symmetry)): continue
      height = self._peak_list.heights()[peak_list_index]
      self._peak_list_indices.append(peak_list_index)
      self._sites.append(site)
      self._heights.append(height)
      return cluster_site_info(
        peak_list_index=peak_list_index,
        grid_index=self._peak_list.grid_indices(peak_list_index),
        grid_height=self._peak_list.grid_heights()[peak_list_index],
        site=site,
        height=height)

  def all_site_cluster_analysis(self, max_clusters=None):
    if (max_clusters is None):
      max_clusters = self._max_clusters
    assert max_clusters is not None
    while 1:
      if (self._sites.size() >= max_clusters): break
      if (self.next_site_cluster_analysis() is None): break
    return self

  def next_with_effective_resolution(self):
    while 1:
      peak_list_index = self._peak_list_index
      if (peak_list_index >= self._peak_list.size()): return None
      self._peak_list_index += 1
      if (self._is_processed is not None):
        if (self._is_processed[peak_list_index]): continue
        self._is_processed[peak_list_index] = True
      grid_index = self._peak_list.grid_indices(peak_list_index)
      grid_height = self._peak_list.grid_heights()[peak_list_index]
      site = self._peak_list.sites()[peak_list_index]
      height = self._peak_list.heights()[peak_list_index]
      site_symmetry = self._special_position_settings.site_symmetry(site)
      if (    self._general_positions_only
          and not site_symmetry.is_point_group_1()):
        continue
      site = site_symmetry.exact_site()
      equiv_sites = sgtbx.sym_equiv_sites(site_symmetry)
      keep = True
      if (self._sites.size() > 250):
        import warnings
        warnings.warn(
          message="This function should not be used for"
                  " processing a large number of peaks.",
          category=RuntimeWarning)
      for s in self._sites:
        dist = sgtbx.min_sym_equiv_distance_info(equiv_sites, s).dist()
        if (dist < self._min_cross_distance):
          keep = False
          break
      if (keep == True):
        if (    self._effective_resolution is not None
            and (   self._heights.size() == 0
                 or height <   self._heights[0]
                             * self._significant_height_fraction)):
            site, height = self._accumulate_significant(
              site, height, site_symmetry, equiv_sites)
        self._peak_list_indices.append(peak_list_index)
        self._sites.append(site)
        self._heights.append(height)
        return cluster_site_info(
          peak_list_index=peak_list_index,
          grid_index=grid_index,
          grid_height=grid_height,
          site=site,
          height=height)

  def _accumulate_significant(self, site, height, site_symmetry, equiv_sites):
    unit_cell = self.special_position_settings().unit_cell()
    orth = unit_cell.orthogonalize
    frac = unit_cell.fractionalize
    sum_w_sites = matrix.col(orth(site)) * height
    sum_w = height
    height_cutoff = height * self._cluster_height_fraction
    for i in xrange(self._peak_list_index, self._peak_list.size()):
      if (self._is_processed[i]): continue
      other_height = self._peak_list.heights()[i]
      if (other_height < height_cutoff): break
      other_site = self._peak_list.sites()[i]
      other_site_symmetry = self._special_position_settings.site_symmetry(
        other_site)
      if (    self._general_positions_only
          and not other_site_symmetry.is_point_group_1()):
        self._is_processed[i] = True
        continue
      other_site = other_site_symmetry.exact_site()
      dist_info = sgtbx.min_sym_equiv_distance_info(equiv_sites, other_site)
      dist = dist_info.dist()
      if (dist < self._min_cross_distance):
        self._is_processed[i] = True
        close_site = dist_info.apply(flex.vec3_double([other_site]))[0]
        close_site = site_symmetry.special_op() * close_site
        sum_w_sites += matrix.col(orth(close_site)) * other_height
        sum_w += other_height
    return frac(sum_w_sites / sum_w), height

  def all_with_effective_resolution(self, max_clusters=None):
    if (max_clusters is None):
      max_clusters = self._max_clusters
    assert max_clusters is not None
    while 1:
      if (self._sites.size() >= max_clusters): break
      if (self.next_with_effective_resolution() is None): break
    return self
