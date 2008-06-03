from cctbx import miller
from cctbx import adptbx
from cctbx.development import debug_utils
from cctbx.array_family import flex
from scitbx import matrix
from libtbx.test_utils import approx_equal
import random
import math
from cStringIO import StringIO
import sys

random.seed(0)
flex.set_random_seed(0)

def d_dw_d_u_star_analytical(h, u_star):
  dw = adptbx.debye_waller_factor_u_star(h, u_star)
  gc = flex.double(adptbx.debye_waller_factor_u_star_gradient_coefficients(h))
  return -2*math.pi**2 * gc * dw

def d2_dw_d_u_star_d_u_star_analytical(h, u_star):
  dw = adptbx.debye_waller_factor_u_star(h, u_star)
  cc = flex.double(adptbx.debye_waller_factor_u_star_curvature_coefficients(h))
  return 4*math.pi**4 * cc * dw

def d_dw_d_u_star_finite(h, u_star, eps=1.e-6):
  result = flex.double()
  for ip in xrange(len(u_star)):
    vs = []
    for signed_eps in [eps,-eps]:
      u_star_eps = list(u_star)
      u_star_eps[ip] += signed_eps
      vs.append(adptbx.debye_waller_factor_u_star(h, u_star_eps))
    result.append((vs[0]-vs[1])/(2*eps))
  return result

def d2_dw_d_u_star_d_u_star_finite(h, u_star, eps=1.e-6):
  result = flex.double()
  for ip in xrange(len(u_star)):
    vs = []
    for signed_eps in [eps,-eps]:
      u_star_eps = list(u_star)
      u_star_eps[ip] += signed_eps
      vs.append(d_dw_d_u_star_analytical(h, u_star_eps))
    result.extend((vs[0]-vs[1])/(2*eps))
  result.reshape(flex.grid(6,6))
  return result.matrix_symmetric_as_packed_u(relative_epsilon=1.e-5)

def d_dw_d_u_indep_finite(adp_constraints, h, u_indep, eps=1.e-6):
  result = flex.double()
  for i_indep in xrange(len(u_indep)):
    vs = []
    for signed_eps in [eps,-eps]:
      u_indep_eps = list(u_indep)
      u_indep_eps[i_indep] += signed_eps
      u_eps = adp_constraints.all_params(u_indep_eps)
      vs.append(adptbx.debye_waller_factor_u_star(h, u_eps))
    result.append((vs[0]-vs[1])/(2*eps))
  return result

def d2_dw_d_u_indep_d_u_indep_finite(adp_constraints, h, u_indep, eps=1.e-6):
  result = flex.double()
  for i_indep in xrange(len(u_indep)):
    vs = []
    for signed_eps in [eps,-eps]:
      u_indep_eps = list(u_indep)
      u_indep_eps[i_indep] += signed_eps
      vs.append(d_dw_d_u_indep_finite(adp_constraints, h, u_indep_eps))
    result.extend((vs[0]-vs[1])/(2*eps))
  np = len(u_indep)
  result.reshape(flex.grid(np,np))
  return result.matrix_symmetric_as_packed_u(relative_epsilon=1.e-5)

def p2_curv(h, u_star):
  """\
h = {h0,h1,h2}
u = {{u00,0,u02},{0,u11,0},{u02,0,u22}}
dw=Exp[mtps*h.u.h]
FortranForm[D[dw,u00,u00]/dw]
FortranForm[D[dw,u00,u11]/dw]
FortranForm[D[dw,u00,u22]/dw]
FortranForm[D[dw,u00,u02]/dw]
FortranForm[D[dw,u11,u00]/dw]
FortranForm[D[dw,u11,u11]/dw]
FortranForm[D[dw,u11,u22]/dw]
FortranForm[D[dw,u11,u02]/dw]
FortranForm[D[dw,u22,u00]/dw]
FortranForm[D[dw,u22,u11]/dw]
FortranForm[D[dw,u22,u22]/dw]
FortranForm[D[dw,u22,u02]/dw]
FortranForm[D[dw,u02,u00]/dw]
FortranForm[D[dw,u02,u11]/dw]
FortranForm[D[dw,u02,u22]/dw]
FortranForm[D[dw,u02,u02]/dw]
"""
  dw = adptbx.debye_waller_factor_u_star(h, u_star)
  h0, h1, h2 = h
  u00 = u_star[0]
  u11 = u_star[1]
  u22 = u_star[2]
  u02 = u_star[4]
  mtps = -2*math.pi**2
  return [
    [dw * (h0**4*mtps**2),
     dw * (h0**2*h1**2*mtps**2),
     dw * (h0**2*h2**2*mtps**2),
     dw * (2*h0**3*h2*mtps**2)],
    [dw * (h0**2*h1**2*mtps**2),
     dw * (h1**4*mtps**2),
     dw * (h1**2*h2**2*mtps**2),
     dw * (2*h0*h1**2*h2*mtps**2)],
    [dw * (h0**2*h2**2*mtps**2),
     dw * (h1**2*h2**2*mtps**2),
     dw * (h2**4*mtps**2),
     dw * (2*h0*h2**3*mtps**2)],
    [dw * (2*h0**3*h2*mtps**2),
     dw * (2*h0*h1**2*h2*mtps**2),
     dw * (2*h0*h2**3*mtps**2),
     dw * (4*h0**2*h2**2*mtps**2)]]

def p4_curv(h, u_star):
  """\
h = {h0,h1,h2}
u = {{u11,0,0},{0,u11,0},{0,0,u22}}
dw=Exp[mtps*h.u.h]
FortranForm[D[dw,u11,u11]/dw]
FortranForm[D[dw,u11,u22]/dw]
FortranForm[D[dw,u22,u11]/dw]
FortranForm[D[dw,u22,u22]/dw]
"""
  dw = adptbx.debye_waller_factor_u_star(h, u_star)
  h0, h1, h2 = h
  u11 = u_star[1]
  u22 = u_star[2]
  mtps = -2*math.pi**2
  return [
    [dw * ((h0**2 + h1**2)**2*mtps**2),
     dw * ((h0**2 + h1**2)*h2**2*mtps**2)],
    [dw * ((h0**2 + h1**2)*h2**2*mtps**2),
     dw * (h2**4*mtps**2)]]

def p3_curv(h, u_star):
  """\
h = {h0,h1,h2}
u = {{2*u01,u01,0},{u01,2*u01,0},{0,0,u22}}
dw=Exp[mtps*h.u.h]
FortranForm[D[dw,u22,u22]/dw]
FortranForm[D[dw,u22,u01]/dw]
FortranForm[D[dw,u01,u22]/dw]
FortranForm[D[dw,u01,u01]/dw]
"""
  dw = adptbx.debye_waller_factor_u_star(h, u_star)
  h0, h1, h2 = h
  u22 = u_star[2]
  u01 = u_star[3]
  mtps = -2*math.pi**2
  return [
    [dw * (h2**4*mtps**2),
     dw * ((h0*(2*h0 + h1) + h1*(h0 + 2*h1))*h2**2*mtps**2)],
    [dw * ((h0*(2*h0 + h1) + h1*(h0 + 2*h1))*h2**2*mtps**2),
     dw * ((h0*(2*h0 + h1) + h1*(h0 + 2*h1))**2*mtps**2)]]

def p23_curv(h, u_star):
  """\
h = {h0,h1,h2}
u = {{u22,0,0},{0,u22,0},{0,0,u22}}
dw=Exp[mtps*h.u.h]
FortranForm[D[dw,u22,u22]/dw]
"""
  dw = adptbx.debye_waller_factor_u_star(h, u_star)
  h0, h1, h2 = h
  u22 = u_star[2]
  mtps = -2*math.pi**2
  return [
    [dw * ((h0**2 + h1**2 + h2**2)**2*mtps**2)]]

def compare_derivatives(ana, fin, eps=1.e-6):
  s = max(1, flex.max(flex.abs(ana)))
  assert approx_equal(ana/s, fin/s, eps=eps)

def exercise(space_group_info, out):
  crystal_symmetry = space_group_info.any_compatible_crystal_symmetry(
    volume=1000)
  space_group = space_group_info.group()
  adp_constraints = space_group.adp_constraints()
  m = adp_constraints.row_echelon_form()
  print >> out, matrix.rec(m, (m.size()/6, 6)).mathematica_form(
    one_row_per_line=True)
  print >> out, list(adp_constraints.independent_indices)
  u_cart_p1 = adptbx.random_u_cart()
  u_star_p1 = adptbx.u_cart_as_u_star(crystal_symmetry.unit_cell(), u_cart_p1)
  u_star = space_group.average_u_star(u_star_p1)
  miller_set = miller.build_set(
    crystal_symmetry=crystal_symmetry, d_min=3, anomalous_flag=False)
  for h in miller_set.indices():
    grads_fin = d_dw_d_u_star_finite(h=h, u_star=u_star)
    print >> out, "grads_fin:", list(grads_fin)
    grads_ana = d_dw_d_u_star_analytical(h=h, u_star=u_star)
    print >> out, "grads_ana:", list(grads_ana)
    compare_derivatives(grads_ana, grads_fin)
    curvs_fin = d2_dw_d_u_star_d_u_star_finite(h=h, u_star=u_star)
    print >> out, "curvs_fin:", list(curvs_fin)
    curvs_ana = d2_dw_d_u_star_d_u_star_analytical(h=h, u_star=u_star)
    print >> out, "curvs_ana:", list(curvs_ana)
    compare_derivatives(curvs_ana, curvs_fin)
    #
    u_indep = adp_constraints.independent_params(u_star)
    grads_indep_fin = d_dw_d_u_indep_finite(
      adp_constraints=adp_constraints, h=h, u_indep=u_indep)
    print >> out, "grads_indep_fin:", list(grads_indep_fin)
    grads_indep_ana = flex.double(adp_constraints.independent_gradients(
      all_gradients=list(grads_ana)))
    print >> out, "grads_indep_ana:", list(grads_indep_ana)
    compare_derivatives(grads_indep_ana, grads_indep_fin)
    curvs_indep_fin = d2_dw_d_u_indep_d_u_indep_finite(
      adp_constraints=adp_constraints, h=h, u_indep=u_indep)
    print >> out, "curvs_indep_fin:", list(curvs_indep_fin)
    curvs_indep_ana = adp_constraints.independent_curvatures(
      all_curvatures=curvs_ana)
    print >> out, "curvs_indep_ana:", list(curvs_indep_ana)
    compare_derivatives(curvs_indep_ana, curvs_indep_fin)
    #
    curvs_indep_mm = None
    if (str(space_group_info) == "P 1 2 1"):
      assert list(adp_constraints.independent_indices) == [0,1,2,4]
      curvs_indep_mm = p2_curv(h, u_star)
    elif (str(space_group_info) == "P 4"):
      assert list(adp_constraints.independent_indices) == [1,2]
      curvs_indep_mm = p4_curv(h, u_star)
    elif (str(space_group_info) in ["P 3", "P 6"]):
      assert list(adp_constraints.independent_indices) == [2,3]
      curvs_indep_mm = p3_curv(h, u_star)
    elif (str(space_group_info) == "P 2 3"):
      assert list(adp_constraints.independent_indices) == [2]
      curvs_indep_mm = p23_curv(h, u_star)
    if (curvs_indep_mm is not None):
      curvs_indep_mm = flex.double(
        curvs_indep_mm).matrix_symmetric_as_packed_u()
      print >> out, "curvs_indep_mm:", list(curvs_indep_mm)
      compare_derivatives(curvs_indep_ana, curvs_indep_mm)

def run_call_back(flags, space_group_info):
  if (flags.Verbose):
    out = sys.stdout
  else:
    out = StringIO()
  exercise(space_group_info, out=out)
  if (space_group_info.group().n_ltr() != 1):
    exercise(space_group_info.primitive_setting(), out=out)

def run():
  debug_utils.parse_options_loop_space_groups(sys.argv[1:], run_call_back)

if (__name__ == "__main__"):
  run()
