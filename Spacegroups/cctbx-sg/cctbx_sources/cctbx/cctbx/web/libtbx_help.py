from cctbx.web import cgi_utils
import pydoc
import cgi
from cStringIO import StringIO
import sys

def interpret_form_data(form):
  inp = cgi_utils.inp_from_form(form,
     (("query", ""),))
  return inp

def run(server_info, inp, status):
  print "<pre>"
  sys.argv = ["libtbx.help"] + inp.query.split()
  s = StringIO()
  sys.stdout = s
  pydoc.cli()
  sys.stdout = sys.__stdout__
  s = s.getvalue()
  sys.stdout.write(cgi.escape(s))
  print "</pre>"
