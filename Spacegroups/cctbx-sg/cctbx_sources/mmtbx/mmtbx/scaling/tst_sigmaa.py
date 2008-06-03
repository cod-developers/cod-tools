from __future__ import division
from cctbx import maptbx
from cctbx import miller
from cctbx import crystal
from cctbx import sgtbx
from cctbx import adptbx
from mmtbx import scaling
import cctbx.sgtbx.lattice_symmetry
import cctbx.sgtbx.cosets
from cctbx.array_family import flex
from libtbx.utils import Sorry, date_and_time, multi_out
from iotbx import reflection_file_reader
from iotbx import reflection_file_utils
from iotbx import crystal_symmetry_from_any
from iotbx import data_plots
import mmtbx.scaling
from mmtbx.scaling import absolute_scaling, outlier_plots
from scitbx.math import chebyshev_lsq
from scitbx.math import chebyshev_polynome
from scitbx.math import chebyshev_lsq_fit
from scitbx.math import erf
import libtbx.phil.command_line
from libtbx import table_utils
from scitbx.python_utils import easy_pickle
import scitbx.lbfgs
import sys, os
import math, time
import string
from cStringIO import StringIO
import mmtbx.f_model
from libtbx.test_utils import approx_equal

def tst_sigmaa():
  eo = flex.double([1])
  ec = flex.double([1.2])
  dsc = flex.double([0.5])
  centric = flex.bool( [False] )

  tmp_a = scaling.sigmaa_estimator(
    e_obs     = eo,
    e_calc    = ec,
    centric   = centric,
    d_star_cubed = dsc,
    width=0.1)
  assert approx_equal(tmp_a.sum_weights(d_star_cubed=0.5), 1)
  # number obtained from mathematica
  assert approx_equal(tmp_a.target(0.5, 0.5), -0.272899, eps=1e-4 )

  assert approx_equal(tmp_a.target_and_gradient(0.5,0.5)[0], tmp_a.target(0.5, 0.5) )
  assert approx_equal(tmp_a.target_and_gradient(0.5,0.5)[1], tmp_a.dtarget(0.5, 0.5) )

  N=100000
  start = time.time()
  for ii in xrange(N):
    tmp_a.target(0.5, 0.5)
    tmp_a.dtarget(0.5, 0.5)

  end = time.time()
  print end-start

  start = time.time()
  for ii in xrange(N):
    tmp_a.target_and_gradient(0.5, 0.5)
  end = time.time()
  print end-start

  tmp_c = scaling.sigmaa_estimator(
    e_obs     = eo,
    e_calc    = ec,
    centric   = ~centric,
    d_star_cubed = dsc,
    width=0.1)
  assert approx_equal(tmp_a.sum_weights(d_star_cubed=0.5), 1)
  # number obtained from mathematica
  assert approx_equal(tmp_c.target(0.5, 0.5), -0.697863,  eps=1e-4 )

  assert approx_equal(tmp_c.target_and_gradient(0.5,0.5)[0], tmp_c.target(0.5, 0.5) )
  assert approx_equal(tmp_c.target_and_gradient(0.5,0.5)[1], tmp_c.dtarget(0.5, 0.5) )


  # timings for large arrays
  N=100000
  eo = flex.double([1]*N)
  ec = flex.double([1.2]*N)
  dsc = flex.double([0.5]*N)
  centric = flex.bool( [False]*N )
  tmp_large = scaling.sigmaa_estimator(
    e_obs     = eo,
    e_calc    = ec,
    centric   = centric,
    d_star_cubed = dsc,
    width=0.1)

  start = time.time()
  for trial in xrange(100):
    a = tmp_large.target(0.5,0.5)
    a = tmp_large.dtarget(0.5,0.5)
  end = time.time()
  print  end-start

  tmp_large = scaling.sigmaa_estimator(
    e_obs     = eo,
    e_calc    = ec,
    centric   = centric,
    d_star_cubed = dsc,
    width=0.1)


  start = time.time()
  for trial in xrange(100):
    a = tmp_large.target_and_gradient(0.5,0.5)
  end = time.time()
  print  end-start







  h=0.5
  d=0.000001
  for a in flex.double(range(20))/20.0:
    fa  = tmp_a.target(h,a)
    fa1 = tmp_a.target(h,a+d)
    ga  = tmp_a.dtarget(h,a)
    ga1 = (fa1-fa)/d

    fc  = tmp_c.target(h,a)
    fc1 = tmp_c.target(h,a+d)
    gc  = tmp_c.dtarget(h,a)
    gc1 = (fc1-fc)/d

    assert approx_equal(ga,ga1, eps=1e-3)
    assert approx_equal(gc,gc1, eps=1e-3)

def run():
  tst_sigmaa()
  print "OK"

if __name__=="__main__":
  run()
