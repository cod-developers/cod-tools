from cctbx import statistics
from cctbx import miller
from cctbx import adptbx
from cctbx.development import random_structure
from cctbx.development import debug_utils
from cctbx.array_family import flex
from scitbx.python_utils import dicts
from libtbx.test_utils import show_diff
import sys

def exercise(space_group_info, anomalous_flag,
             d_min=1.0, reflections_per_bin=200, n_bins=10, verbose=0):
  elements = ("N", "C", "C", "O") * 5
  structure_factors = random_structure.xray_structure(
    space_group_info,
    elements=elements,
    volume_per_atom=50.,
    min_distance=1.5,
    general_positions_only=True,
    use_u_aniso=False,
    u_iso=adptbx.b_as_u(10)
    ).structure_factors(
        anomalous_flag=anomalous_flag, d_min=d_min, algorithm="direct")
  if (0 or verbose):
    structure_factors.xray_structure().show_summary()
  asu_contents = dicts.with_default_value(0)
  for elem in elements: asu_contents[elem] += 1
  f_calc = abs(structure_factors.f_calc())
  f_calc.setup_binner(
    auto_binning=True,
    reflections_per_bin=reflections_per_bin,
    n_bins=n_bins)
  if (0 or verbose):
    f_calc.binner().show_summary()
  for k_given in [1,0.1,0.01,10,100]:
    f_obs = miller.array(
      miller_set=f_calc,
      data=f_calc.data()*k_given)
    f_obs.use_binner_of(f_calc)
    wp = statistics.wilson_plot(f_obs, asu_contents)
    if (0 or verbose):
      print "wilson_k, wilson_b:", wp.wilson_k, wp.wilson_b
    assert 0.8 < wp.wilson_k/k_given < 1.2
    assert 9 < wp.wilson_b < 11
    assert wp.xy_plot_info().fit_correlation == wp.fit_correlation
  f_obs = f_calc.array(data=flex.double(f_calc.indices().size(), 0))
  f_obs.use_binner_of(f_calc)
  n_bins = f_obs.binner().n_bins_used()
  try:
    statistics.wilson_plot(f_obs, asu_contents)
  except RuntimeError, e:
    assert not show_diff(str(e), """\
wilson_plot error: %d empty bins:
  Number of bins: %d
  Number of f_obs > 0: 0
  Number of f_obs <= 0: %d""" % (n_bins, n_bins, f_obs.indices().size()))

def run_call_back(flags, space_group_info):
  for anomalous_flag in (False, True):
    exercise(space_group_info, anomalous_flag, verbose=flags.Verbose)

def run():
  debug_utils.parse_options_loop_space_groups(sys.argv[1:], run_call_back)

if (__name__ == "__main__"):
  run()
