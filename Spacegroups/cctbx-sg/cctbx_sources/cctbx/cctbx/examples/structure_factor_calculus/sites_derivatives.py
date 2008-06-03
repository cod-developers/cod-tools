from scitbx import matrix
from scitbx.array_family import flex
from libtbx.test_utils import approx_equal
import math
from cStringIO import StringIO
import sys

flex.set_random_seed(0)

class cos_alpha:

  def __init__(self, sites, ops, hkl):
    self.sites = sites
    self.ops = ops
    self.hkl = hkl

  def f(self):
    result = 0
    for site in self.sites:
      for op in self.ops:
        op_site = op * site
        result += math.cos(self.hkl.dot(op_site))
    return result

  def d_sites(self):
    result = flex.double()
    for site in self.sites:
      d_site = flex.double(3, 0)
      for op in self.ops:
        op_site = op * site
        hkl_op_site = self.hkl.dot(op_site)
        d_op_site = -math.sin(hkl_op_site) * self.hkl
        gtmx = op.transpose()
        d_site += flex.double(gtmx * d_op_site.transpose())
      result.extend(d_site)
    return result

  def d2_sites(self):
    n = len(self.sites) * 3
    result = flex.double(flex.grid(n,n), 0)
    d_alpha_d_site = self.hkl.outer_product()
    for js,site in enumerate(self.sites):
      d2_site = flex.double(flex.grid(3,3), 0)
      for op in self.ops:
        op_site = op * site
        hkl_op_site = self.hkl.dot(op_site)
        d2_op_site = -math.cos(hkl_op_site) * d_alpha_d_site
        d2_site += flex.double(op.transpose() * d2_op_site * op)
      result.matrix_paste_block_in_place(d2_site, js*3, js*3)
    return result

def d_cos_alpha_d_sites_finite(sites, ops, hkl, eps=1.e-8):
  result = flex.double()
  sites_eps = list(sites)
  for js,site in enumerate(sites):
    site_eps = list(site)
    for jp in xrange(3):
      vs = []
      for signed_eps in [eps, -eps]:
        site_eps[jp] = site[jp] + signed_eps
        sites_eps[js] = matrix.col(site_eps)
        ca = cos_alpha(sites=sites_eps, ops=ops, hkl=hkl)
        vs.append(ca.f())
      result.append((vs[0]-vs[1])/(2*eps))
    sites_eps[js] = sites[js]
  return result

def d2_cos_alpha_d_sites_finite(sites, ops, hkl, eps=1.e-8):
  result = flex.double()
  sites_eps = list(sites)
  for js,site in enumerate(sites):
    site_eps = list(site)
    for jp in xrange(3):
      vs = []
      for signed_eps in [eps, -eps]:
        site_eps[jp] = site[jp] + signed_eps
        sites_eps[js] = matrix.col(site_eps)
        ca = cos_alpha(sites=sites_eps, ops=ops, hkl=hkl)
        vs.append(ca.d_sites())
      result.extend((vs[0]-vs[1])/(2*eps))
    sites_eps[js] = sites[js]
  return result

def exercise(args):
  verbose =  "--verbose" in args
  if (not verbose):
    out = StringIO()
  else:
    out = sys.stdout
  for i_trial in xrange(100):
    ops = []
    for i in xrange(3):
      ops.append(matrix.sqr(flex.random_double(size=9, factor=4)-2))
    sites = []
    for i in xrange(2):
      sites.append(matrix.col(flex.random_double(size=3, factor=4)-2))
    hkl = matrix.row(flex.random_double(size=3, factor=4)-2)
    ca = cos_alpha(sites=sites, ops=ops, hkl=hkl)
    grads_fin = d_cos_alpha_d_sites_finite(sites=sites, ops=ops, hkl=hkl)
    print >> out, "grads_fin:", list(grads_fin)
    grads_ana = ca.d_sites()
    print >> out, "grads_ana:", list(grads_ana)
    assert approx_equal(grads_ana, grads_fin)
    curvs_fin = d2_cos_alpha_d_sites_finite(sites=sites, ops=ops, hkl=hkl)
    print >> out, "curvs_fin:", list(curvs_fin)
    curvs_ana = ca.d2_sites()
    print >> out, "curvs_ana:", list(curvs_ana)
    assert approx_equal(curvs_ana, curvs_fin, 1.e-5)
    print >> out
  print "OK"

if (__name__ == "__main__"):
  exercise(sys.argv[1:])
