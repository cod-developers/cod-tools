from cctbx.array_family import flex
from cctbx import uctbx
from cctbx import crystal
from cctbx import xray
from cctbx import maptbx
from cctbx.development import random_structure
from cctbx import eltbx
import cctbx.eltbx.xray_scattering
from cctbx import miller
import mmtbx.real_space
from libtbx.test_utils import approx_equal
from cctbx import sgtbx
from libtbx.utils import format_cpu_times


def xray_structure_of_one_atom(site_cart,
                               buffer_layer,
                               a,
                               b,
                               scatterer_chemical_type = "C"):
  custom_dict = \
             {scatterer_chemical_type: eltbx.xray_scattering.gaussian([a],[b])}

  box = uctbx.non_crystallographic_unit_cell_with_the_sites_in_its_center(
                                                   sites_cart   = site_cart,
                                                   buffer_layer = buffer_layer)
  crystal_symmetry = crystal.symmetry(unit_cell          = box.unit_cell,
                                      space_group_symbol = "p 1")
  site_frac =crystal_symmetry.unit_cell().fractionalization_matrix()*site_cart
  scatterer = flex.xray_scatterer((
    [xray.scatterer(scatterer_chemical_type, site = site_frac[0], u = 0.0)]))
  xray_structure = xray.structure(special_position_settings = None,
                                  scatterers                = scatterer,
                                  crystal_symmetry          = crystal_symmetry)
  xray_structure.scattering_type_registry(custom_dict = custom_dict)
  return xray_structure

def exercise_1(grid_step,
               radius,
               shell,
               a,
               b,
               buffer_layer,
               site_cart):
  xray_structure = xray_structure_of_one_atom(site_cart    = site_cart,
                                              buffer_layer = buffer_layer,
                                              a            = a,
                                              b            = b)
  sampled_density = mmtbx.real_space.sampled_model_density(
                                            xray_structure = xray_structure,
                                            grid_step      = grid_step)
  site_frac = xray_structure.unit_cell().fractionalization_matrix()*site_cart
  assert approx_equal(flex.max(sampled_density.data()),
              sampled_density.data().value_at_closest_grid_point(site_frac[0]))

  around_atom_obj = mmtbx.real_space.around_atom(
                           unit_cell = xray_structure.unit_cell(),
                           map_data  = sampled_density.data(),
                           radius    = radius,
                           shell     = shell,
                           site_frac = list(xray_structure.sites_frac())[0])
  data_exact = around_atom_obj.data()
  dist_exact = around_atom_obj.distances()
  approx_obj = maptbx.one_gaussian_peak_approximation(
                                           data_at_grid_points    = data_exact,
                                           distances              = dist_exact,
                                           use_weights            = False,
                                           optimize_cutoff_radius = True)
  assert approx_equal(approx_obj.a_reciprocal_space(), 6.0, 1.e-3)
  assert approx_equal(approx_obj.b_reciprocal_space(), 3.0, 1.e-3)
  assert approx_obj.gof() < 0.3
  assert approx_obj.cutoff_radius() < radius

def exercise_2(grid_step,
               radius,
               shell,
               a,
               b,
               volume_per_atom,
               scatterer_chemical_type = "C"):
  xray_structure = random_structure.xray_structure(
                        space_group_info       = sgtbx.space_group_info("P 1"),
                        elements               = ((scatterer_chemical_type)*1),
                        volume_per_atom        = volume_per_atom,
                        min_distance           = 1.5,
                        general_positions_only = True)
  custom_dict = \
             {scatterer_chemical_type: eltbx.xray_scattering.gaussian([a],[b])}
  xray_structure.scattering_type_registry(custom_dict = custom_dict)
  sampled_density = mmtbx.real_space.sampled_model_density(
                                            xray_structure = xray_structure,
                                            grid_step      = grid_step)
  site_frac = xray_structure.sites_frac()
  r = abs(abs(flex.max(sampled_density.data()))-\
      abs(sampled_density.data().value_at_closest_grid_point(site_frac[0])))/\
      abs(flex.max(sampled_density.data())) * 100.0
  assert r < 10.

  around_atom_obj = mmtbx.real_space.around_atom(
                           unit_cell = xray_structure.unit_cell(),
                           map_data  = sampled_density.data(),
                           radius    = radius,
                           shell     = shell,
                           site_frac = list(xray_structure.sites_frac())[0])
  data_exact = around_atom_obj.data()
  dist_exact = around_atom_obj.distances()
  approx_obj = maptbx.one_gaussian_peak_approximation(
                                           data_at_grid_points    = data_exact,
                                           distances              = dist_exact,
                                           use_weights            = False,
                                           optimize_cutoff_radius = True)
  assert approx_equal(approx_obj.a_reciprocal_space(), 6.0, 1.e-2)
  assert approx_equal(approx_obj.b_reciprocal_space(), 3.0, 1.e-2)
  assert approx_obj.gof() < 0.3
  assert approx_obj.cutoff_radius() < radius

def exercise_3(grid_step,
               radius,
               shell,
               a,
               b,
               d_min,
               site_cart,
               buffer_layer):
  xray_structure = xray_structure_of_one_atom(site_cart    = site_cart,
                                              buffer_layer = buffer_layer,
                                              a            = a,
                                              b            = b)
  miller_set = miller.build_set(
                          crystal_symmetry = xray_structure.crystal_symmetry(),
                          anomalous_flag   = False,
                          d_min            = d_min,
                          d_max            = None)
  f_calc = miller_set.structure_factors_from_scatterers(
                                 xray_structure               = xray_structure,
                                 algorithm                    = "direct",
                                 cos_sin_table                = False,
                                 exp_table_one_over_step_size = False).f_calc()
  fft_map = f_calc.fft_map(grid_step = grid_step, symmetry_flags = None)
  fft_map = fft_map.apply_volume_scaling()
  site_frac = xray_structure.sites_frac()
  r = abs(abs(flex.max(fft_map.real_map_unpadded()))-\
    abs(fft_map.real_map_unpadded().value_at_closest_grid_point(site_frac[0])))/\
    abs(flex.max(fft_map.real_map_unpadded())) * 100.0
  assert approx_equal(r, 0.0)
  around_atom_obj_ = mmtbx.real_space.around_atom(
                            unit_cell = xray_structure.unit_cell(),
                            map_data  = fft_map.real_map_unpadded(),
                            radius    = radius,
                            shell     = shell,
                            site_frac = list(xray_structure.sites_frac())[0])
  data = around_atom_obj_.data()
  dist = around_atom_obj_.distances()
  approx_obj_ = maptbx.one_gaussian_peak_approximation(
                                                data_at_grid_points    = data,
                                                distances              = dist,
                                                use_weights            = False,
                                                optimize_cutoff_radius = True)
  assert approx_equal(approx_obj_.a_reciprocal_space(), 6.0, 0.1)
  assert approx_equal(approx_obj_.b_reciprocal_space(), 3.0, 0.01)
  assert approx_obj_.gof() < 0.6
  assert approx_obj_.cutoff_radius() < radius

def exercise_4(grid_step,
               radius,
               shell,
               a,
               b,
               d_min,
               volume_per_atom,
               use_weights,
               optimize_cutoff_radius,
               scatterer_chemical_type = "C"):
  xray_structure = random_structure.xray_structure(
                        space_group_info       = sgtbx.space_group_info("P 1"),
                        elements               = ((scatterer_chemical_type)*1),
                        volume_per_atom        = volume_per_atom,
                        min_distance           = 1.5,
                        general_positions_only = True)
  custom_dict = \
             {scatterer_chemical_type: eltbx.xray_scattering.gaussian([a],[b])}
  xray_structure.scattering_type_registry(custom_dict = custom_dict)
  miller_set = miller.build_set(
                          crystal_symmetry = xray_structure.crystal_symmetry(),
                          anomalous_flag   = False,
                          d_min            = d_min,
                          d_max            = None)
  f_calc = miller_set.structure_factors_from_scatterers(
                                 xray_structure               = xray_structure,
                                 algorithm                    = "direct",
                                 cos_sin_table                = False,
                                 exp_table_one_over_step_size = False).f_calc()
  fft_map = f_calc.fft_map(grid_step = grid_step, symmetry_flags = None)
  fft_map = fft_map.apply_volume_scaling()
  site_frac = xray_structure.sites_frac()
  m = fft_map.real_map_unpadded()
  amm = abs(flex.max(m))
  r = abs(amm-abs(m.value_at_closest_grid_point(site_frac[0]))) / amm
  assert r < 0.15, r
  around_atom_obj_ = mmtbx.real_space.around_atom(
                            unit_cell = xray_structure.unit_cell(),
                            map_data  = fft_map.real_map_unpadded(),
                            radius    = radius,
                            shell     = shell,
                            site_frac = list(xray_structure.sites_frac())[0])
  data = around_atom_obj_.data()
  dist = around_atom_obj_.distances()
  approx_obj_ = maptbx.one_gaussian_peak_approximation(
                               data_at_grid_points    = data,
                               distances              = dist,
                               use_weights            = use_weights,
                               optimize_cutoff_radius = optimize_cutoff_radius)
  assert approx_equal(approx_obj_.a_reciprocal_space(), 6.0, 0.1)
  assert approx_equal(approx_obj_.b_reciprocal_space(), 3.0, 0.1)
  assert approx_obj_.gof() < 1.0
  assert approx_obj_.cutoff_radius() < radius

def run():
  for site in ([0,0,0], [0.1,0.1,0.1], [6,6,6], [3,3,3], [-0.1,0.1,-0.1],
                                                           [6,-6,6], [3,-3,3]):
      exercise_1(grid_step    = 0.1,
                 radius       = 1.0,
                 shell        = 0.0,
                 a            = 6.0,
                 b            = 3.0,
                 site_cart    = flex.vec3_double([site]),
                 buffer_layer = 3.)
  for volume_per_atom in range(100,550,100)*10:
      exercise_2(grid_step    = 0.08,
                 radius       = 1.0,
                 shell        = 0.0,
                 a            = 6.0,
                 b            = 3.0,
                 volume_per_atom    = volume_per_atom)
  for site in ([0,0,0], [0.1,0.1,0.1], [6,6,6], [3,3,3], [-0.1,0.1,-0.1],
                                                           [6,-6,6], [3,-3,3]):
      exercise_3(grid_step    = 0.1,
                 radius       = 0.9,
                 shell        = 0.0,
                 a            = 6.0,
                 b            = 3.0,
                 d_min        = 0.08,
                 site_cart    = flex.vec3_double([site]),
                 buffer_layer = 3.)
  for volume_per_atom in range(100,550,100)*5:
      exercise_4(grid_step    = 0.1,
                 radius       = 0.9,
                 shell        = 0.0,
                 a            = 6.0,
                 b            = 3.0,
                 d_min        = 0.08,
                 volume_per_atom = volume_per_atom,
                 use_weights            = False,
                 optimize_cutoff_radius = True)
  for use_weights, optimize_cutoff_radius in zip([True,False], [True,True]):
      exercise_4(grid_step    = 0.1,
                 radius       = 0.9,
                 shell        = 0.0,
                 a            = 6.0,
                 b            = 3.0,
                 d_min        = 0.08,
                 volume_per_atom = 300,
                 use_weights            = use_weights,
                 optimize_cutoff_radius = optimize_cutoff_radius)

if (__name__ == "__main__"):
    run()
    print "OK: real_space: ",format_cpu_times()
