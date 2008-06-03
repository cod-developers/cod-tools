from cctbx.eltbx.development.format_gaussian_fits import read_pickled_fits
from cctbx.eltbx import xray_scattering
import cctbx.eltbx.gaussian_fit
import scitbx.math.gaussian_fit
import md5
import time
import sys, os

def write_module_info(f, module_object):
  file_name = module_object.__file__
  if (file_name.endswith(".pyc")):
    file_name = file_name[:-1]
  assert file_name.endswith(".py")
  file_content = open(file_name, "rb").read()
  m = md5.new()
  m.update(file_content)
  print >> f, "// Module:", module_object.__name__
  print >> f, "//   size:", len(file_content)
  print >> f, "//   MD5 hexdigest:", m.hexdigest()
  print >> f

def write_header(f):
  print >> f, """\
#include <cctbx/eltbx/xray_scattering/n_gaussian_raw.h>
#include <cstring>

namespace {

#undef D
#define D static const double
"""

def identifier(label):
  return (label.lower()
    .replace("'", "prime")
    .replace("+", "plus")
    .replace("-", "minus"))

def write_fit_group(f, label, group):
  id = identifier(label)
  s = "D %s_s[] = {" % id
  for fit in group:
    s += " " + str(fit.stol) + ","
  s = s[:-1] + " };"
  print >> f, s
  print >> f, "D %s_e[] = {" % id
  for fit in group:
    s = str(fit.max_error)
    if (fit is not group[-1]): s += ","
    print >> f, s
  print >> f, "};"
  labels = []
  for fit_unsorted in group:
    fit = fit_unsorted.sort()
    lbl = "%s_%d" % (id, fit.n_terms())
    if (fit.use_c()): lbl += "c"
    print >> f, "D %s[] = {" % lbl
    labels.append(lbl)
    buf = []
    for a,b in zip(fit.array_of_a(), fit.array_of_b()):
      buf.append("%s, %s," % (str(a), str(b)))
    if (fit.use_c()):
      buf.append(str(fit.c()))
    else:
      buf[-1] = buf[-1][:-1]
    for s in buf: print >> f, s
    print >> f, "};"
  print >> f, "D* %s_c[] = { %s };" % (id, ", ".join(labels))
  print >> f
  return
  print >> f, """\
"""

def write_labels(f, labels):
  print >> f, """\
static const char*
labels[] = {"""
  last_label = labels[-1]
  for label in labels:
    assert not '"' in label
    c = ","
    if (label == last_label): c = ""
    print >> f, '"%s"%s' % (label, c)
  print >> f, "};"

def write_table(f, labels):
  print >> f, """\
static const cctbx::eltbx::xray_scattering::n_gaussian::raw::entry
table[] = {"""
  last_label = labels[-1]
  for label in labels:
    id = identifier(label)
    c = ","
    if (label == last_label): c = ""
    print >> f, '%s_s, %s_e, %s_c%s' % (id, id, id, c)
  print >> f, "};"

def write_tail(f, localtime, table_size):
  print >> f, """\
} // namespace <anonymous>

namespace cctbx { namespace eltbx { namespace xray_scattering {
namespace n_gaussian { namespace raw {

  const char*
  get_tag() { return "%s"; }

  const char**
  get_labels() { return labels; }

  unsigned int
  get_table_size() { return %dU; }

  const entry*
  get_table() { return table; }

}}}}} // namespace cctbx::eltbx::xray_scattering::n_gaussian::raw""" % (
  "%04d_%02d_%02d_%02d%02d" % localtime[:5], table_size)

def run(gaussian_fit_pickle_file_names):
  localtime = time.localtime()
  fits = read_pickled_fits(gaussian_fit_pickle_file_names)
  f = sys.stdout
  print >> f, "// This is an automatically generated file. DO NOT EDIT!"
  print >> f
  print >> f, "// Time %04d/%02d/%02d %02d:%02d:%02d" % localtime[:6]
  print >> f, "// Time zone:", time.tzname
  print >> f
  write_module_info(f, cctbx.eltbx.gaussian_fit)
  write_module_info(f, scitbx.math.gaussian_fit)
  print >> f, "// Parameters:"
  for k,v in fits.parameters.items():
    print >> f, "//   %s:" % k, v
  print >> f
  present = []
  missing = []
  for wk in xray_scattering.wk1995_iterator():
    try:
      fit_group = fits.all[wk.label()]
    except:
      missing.append(wk.label())
    else:
      present.append(wk.label())
  if (len(missing) > 0):
    print >> f, "// Warning: Missing scattering labels:"
    for label in missing:
      print >> f, "// ", label
    print >> f
  write_header(f)
  for label in present:
    write_fit_group(f, label, fits.all[label])
  write_labels(f, present)
  write_table(f, present)
  write_tail(f, localtime, len(present))

if (__name__ == "__main__"):
  run(sys.argv[1:])
