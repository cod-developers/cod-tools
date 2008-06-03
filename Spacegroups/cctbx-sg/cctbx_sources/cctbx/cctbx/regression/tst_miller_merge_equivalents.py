from cctbx import miller
from cctbx.development import random_structure
from cctbx.development import debug_utils
from cctbx.array_family import flex
from cStringIO import StringIO
import random
import sys

def exercise(space_group_info, anomalous_flag,
             n_scatterers=8, d_min=2, verbose=0):
  structure = random_structure.xray_structure(
    space_group_info,
    elements=["const"]*n_scatterers)
  f_calc = structure.structure_factors(
    d_min=d_min, anomalous_flag=anomalous_flag).f_calc()
  f = abs(f_calc)
  fs = miller.array(miller_set=f, data=f.data(), sigmas=flex.sqrt(f.data()))
  assert fs.is_unique_set_under_symmetry()
  for a in (f, fs):
    m = a.merge_equivalents()
    m.show_summary(out=StringIO())
    j = m.array().adopt_set(a)
    assert flex.linear_correlation(j.data(),
                                   a.data()).coefficient() > 1-1.e-6
    if (a.sigmas() is not None):
      assert flex.linear_correlation(j.sigmas(),
                                     a.sigmas()).coefficient() > 1-1.e-6
  redundancies = flex.size_t()
  for i in xrange(fs.indices().size()):
    redundancies.append(random.randrange(5)+1)
  space_group = space_group_info.group()
  r_indices = flex.miller_index()
  r_data = flex.double()
  r_sigmas = flex.double()
  for i,n in enumerate(redundancies):
    h = fs.indices()[i]
    h_eq = miller.sym_equiv_indices(space_group, h).indices()
    for j in xrange(n):
      r_indices.append(h_eq[random.randrange(len(h_eq))].h())
      r_data.append(fs.data()[i])
      r_sigmas.append(fs.sigmas()[i])
  r = miller.array(
    miller_set=miller.set(
      crystal_symmetry=fs,
      indices=r_indices,
      anomalous_flag=fs.anomalous_flag()),
    data=r_data,
    sigmas=r_sigmas)
  assert not r.is_unique_set_under_symmetry()
  noise = flex.random_double(size=r.indices().size())
  r = r.sort(by_value=noise)
  m = r.merge_equivalents()
  m.show_summary(out=StringIO())
  j = m.array().adopt_set(fs)
  assert j.is_unique_set_under_symmetry()
  assert flex.linear_correlation(
    j.data(),
    fs.data()).coefficient() > 1-1.e-6
  fssr = fs.sigmas() / flex.sqrt(redundancies.as_double())
  assert flex.linear_correlation(j.sigmas(), fssr).coefficient() > 1-1.e-6
  #
  if (anomalous_flag):
    f_calc_ave = f_calc.average_bijvoet_mates() # uses merge_equivalents
    f_calc_com = f_calc.as_non_anomalous_array().common_set(f_calc_ave)
    assert f_calc_com.indices().all_eq(f_calc_ave.indices())
    for part in [flex.real, flex.imag]:
      assert flex.linear_correlation(
        part(f_calc_com.data()),
        part(f_calc_ave.data())).coefficient() > 1-1.e-6

def run_call_back(flags, space_group_info):
  for anomalous_flag in (False, True):
    exercise(space_group_info, anomalous_flag)

def run():
  debug_utils.parse_options_loop_space_groups(sys.argv[1:], run_call_back)
  print "OK"

if (__name__ == "__main__"):
  run()
