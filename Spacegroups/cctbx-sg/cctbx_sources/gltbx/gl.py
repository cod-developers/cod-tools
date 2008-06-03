import boost.python
ext = boost.python.import_ext("gltbx_gl_ext")
from gltbx_gl_ext import *

def __function_taking_transposed_matrix(f):
  def wrapper(m):
    mt = m[0:13:4] + m[1:14:4] + m[2:15:4] + m[3:16:4]
    f(mt)
  return wrapper

glLoadTransposeMatrixf = __function_taking_transposed_matrix(glLoadMatrixf)
glLoadTransposeMatrixd = __function_taking_transposed_matrix(glLoadMatrixd)
glMultTransposeMatrixf = __function_taking_transposed_matrix(glMultMatrixf)
glMultTransposeMatrixd = __function_taking_transposed_matrix(glMultMatrixd)
