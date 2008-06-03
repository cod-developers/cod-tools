import tntbx
import tntbx.eigensystem

from scitbx.array_family import flex
from libtbx.test_utils import approx_equal
import random
import time

def matrix_mul(a, ar, ac, b, br, bc):
  assert br == ac
  result = []
  for i in xrange(ar):
    for k in xrange(bc):
      s = 0
      for j in xrange(ac):
        s += a[i * ac + j] * b[j * bc + k]
      result.append(s)
  return result

def exercise_eigensystem():
  #random.seed(0)
  for n in xrange(1,10):
    m = flex.double(flex.grid(n,n))
    s = tntbx.eigensystem.real(m)
    assert approx_equal(tuple(s.values()), [0]*n)
    v = s.vectors()
    for i in xrange(n):
      for j in xrange(n):
        x = 0
        if (i == j): x = 1
        #assert approx_equal(v[(i,j)], x)
    v = []
    for i in xrange(n):
      j = (i*13+17) % n
      v.append(j)
      m[i*(n+1)] = j
    s = tntbx.eigensystem.real(m)
    if (n == 3):
      ss = tntbx.eigensystem.real((m[0],m[4],m[8],m[1],m[2],m[5]))
      assert approx_equal(s.values(), ss.values())
      assert approx_equal(s.vectors(), ss.vectors())
    v.sort()
    v.reverse()
    assert approx_equal(s.values(), v)
    if (n > 1):
      assert approx_equal(flex.min(s.vectors()), 0)
    assert approx_equal(flex.max(s.vectors()), 1)
    assert approx_equal(flex.sum(s.vectors()), n)
    for t in xrange(10):
      for i in xrange(n):
        for j in xrange(i,n):
          m[i*n+j] = random.random() - 0.5
          if (i != j):
            m[j*n+i] = m[i*n+j]
      s = tntbx.eigensystem.real(m)
      if (n == 3):
        ss = tntbx.eigensystem.real((m[0],m[4],m[8],m[1],m[2],m[5]))
        assert approx_equal(s.values(), ss.values())
        assert approx_equal(s.vectors(), ss.vectors())
      v = list(s.values())
      v.sort()
      v.reverse()
      assert list(s.values()) == v
      for i in xrange(n):
        l = s.values()[i]
        x = s.vectors()[i*n:i*n+n]
        mx = matrix_mul(m, n, n, x, n, 1)
        lx = [e*l for e in x]
        assert approx_equal(mx, lx)
  m = (1.4573362052597449, 1.7361052947659894, 2.8065584999742659,
       -0.5387293498219814, -0.018204949672480729, 0.44956507395617257)
  #n_repetitions = 100000
  #t0 = time.time()
  #v = time_eigensystem_real(m, n_repetitions)
  #assert v == (0,0,0)
  #print "time_eigensystem_real: %.3f micro seconds" % (
  #  (time.time() - t0)/n_repetitions*1.e6)

def exercise_generalized_inverse_numpy():
  #print 'Numeric'
  from Numeric import asarray
  from LinearAlgebra import generalized_inverse
  m = asarray([[1,1],[0,0]])
  n = generalized_inverse(m)
  #print 'matrix \n',m
  #print 'inverse\n', n
  m = asarray([[1,1,1],[0,0,0],[0,0,0]])
  n = generalized_inverse(m)
  #print 'matrix \n',m
  #print 'inverse\n', n

def svd_checked(m):
  svd = tntbx.svd(m=m)
  s = svd.s()
  u = svd.u()
  v = svd.v()
  usvt = u.matrix_multiply(s).matrix_multiply(v.matrix_transpose())
  assert approx_equal(usvt, m)
  return svd

def exercise_svd_and_generalized_inverse():
  m = flex.double([[1,1],[0,0]])
  svd = svd_checked(m=m)
  assert svd.rank() == 1
  m_inverse = tntbx.generalized_inverse(m)
  n = flex.double([[1./2,0],[1./2,0]])
  assert approx_equal(m_inverse, n)
  m = flex.double([[1,1,1],[0,0,0],[0,0,0]])
  svd = svd_checked(m=m)
  assert svd.rank() == 1
  m_inverse = tntbx.generalized_inverse(m)
  n = flex.double([[1./3,0,0],[1./3,0,0],[1./3,0,0]])
  assert approx_equal(m_inverse, n)
  #
  m = flex.double([[0,0],[0,0]])
  svd = svd_checked(m=m)
  assert approx_equal(svd.singular_values(), [0,0])
  assert approx_equal(svd.norm2(), 0)
  assert svd.cond() is None
  assert svd.rank() == 0
  m = flex.double([[1,0],[0,1]])
  svd = svd_checked(m=m)
  assert approx_equal(svd.singular_values(), [1,1])
  assert approx_equal(svd.norm2(), 1)
  assert approx_equal(svd.cond(), 1)
  assert svd.rank() == 2
  m = flex.double([
    [1,0,0,0],
    [0,0,0,4],
    [0,3,0,0],
    [0,0,0,0],
    [2,0,0,0]])
  svd = svd_checked(m=m)
  assert approx_equal(svd.singular_values(), [4,3,2.236068,0])
  assert approx_equal(svd.norm2(), 4)
  assert svd.cond() is None
  assert svd.rank() == 3
  m = m.matrix_transpose()
  svd = svd_checked(m=m)
  assert approx_equal(svd.singular_values(), [4,3,2.236068,0,0])
  assert approx_equal(svd.norm2(), 4)
  assert svd.cond() is None
  assert svd.rank() == 3
  #
  for n_rows in xrange(1,6):
    for n_columns in xrange(1,6):
      m = flex.random_double(size=n_rows*n_columns)*2-1
      m.reshape(flex.grid(n_rows, n_columns))
      r0 = svd_checked(m=m).rank()
      m0 = m
      m = m0.deep_copy().as_1d()
      m.extend(m[:n_columns])
      m.reshape(flex.grid(n_rows+1, n_columns))
      r = svd_checked(m=m).rank()
      assert r == r0
      m = m0.matrix_transpose().as_1d()
      m.extend(m[:n_rows])
      m.reshape(flex.grid(n_columns+1, n_rows))
      m = m.matrix_transpose()
      r = svd_checked(m=m).rank()
      assert r == r0

def run():
  try:
    import platform
  except ImportError:
    release = ""
  else:
    release = platform.release()
  if (   release.endswith("_FC4")
      or release.endswith("_FC4smp")):
    pass # LinearAlgebra.generalized_inverse is broken
  else:
    try:
      exercise_generalized_inverse_numpy()
    except ImportError:
      pass
  exercise_svd_and_generalized_inverse()
  exercise_eigensystem()
  print "OK"

if (__name__ == "__main__"):
  run()
