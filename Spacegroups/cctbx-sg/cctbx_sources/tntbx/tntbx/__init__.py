import boost.python
ext = boost.python.import_ext("tntbx_ext")
from tntbx_ext import *

from scitbx.array_family import flex

class svd(object):

  def __init__(self, m):
    self.n_rows, self.n_columns = m.focus()
    assert self.n_rows > 0
    assert self.n_columns > 0
    if (self.n_rows < self.n_columns):
      m = m.matrix_transpose()
    self.svd_m_ge_n = svd_m_ge_n_double(m=m)

  def singular_values(self):
    result = self.svd_m_ge_n.singular_values()
    if (self.n_rows < self.n_columns):
      result.resize(self.n_columns, 0)
    return result

  def s(self):
    s = self.svd_m_ge_n.s()
    if (self.n_rows < self.n_columns):
      result = flex.double(flex.grid(self.n_columns, self.n_columns), 0)
      result.matrix_paste_block_in_place(block=s, i_row=0, i_column=0)
    return s

  def u(self):
    if (self.n_rows < self.n_columns): return self.svd_m_ge_n.v()
    return self.svd_m_ge_n.u()

  def v(self):
    if (self.n_rows < self.n_columns): return self.svd_m_ge_n.u()
    return self.svd_m_ge_n.v()

  def norm2(self): return self.svd_m_ge_n.norm2()

  def cond(self): return self.svd_m_ge_n.cond()

  def rank(self): return self.svd_m_ge_n.rank()
