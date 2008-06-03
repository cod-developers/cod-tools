from __future__ import division
from __future__ import generators
from libtbx import sge_utils
from libtbx.str_utils import show_string
try: import gzip
except ImportError: gzip = None
try:
  import hashlib
  hashlib_md5 = hashlib.md5
except ImportError:
  import md5
  hashlib_md5 = md5.new
import glob
import time
import atexit
import traceback
import sys, os

windows_device_names = """\
CON PRN AUX NUL COM1 COM2 COM3 COM4 COM5 COM6 COM7 COM8 COM9
LPT1 LPT2 LPT3 LPT4 LPT5 LPT6 LPT7 LPT8 LPT9""".split()

def escape_sh_double_quoted(s):
  "the result is supposed to be double-quoted when passed to sh"
  if (s is None): return None
  return s.replace('\\','\\\\').replace('"','\\"')

def gzip_open(file_name, mode):
  assert mode in ["r", "rb", "w", "wb", "a", "ab"]
  if (gzip is None):
    un = ""
    if (mode[0] == "r"): un = "un"
    raise RuntimeError(
      "gzip module not available: cannot %scompress file %s"
        % (un, show_string(file_name)))
  return gzip.open(file_name, mode)

def warn_if_unexpected_md5_hexdigest(
      path,
      expected_md5_hexdigests,
      hints=[],
      out=None):
  m = hashlib_md5()
  m.update("\n".join(open(path).read().splitlines()))
  current_md5_hexdigest = m.hexdigest()
  if (m.hexdigest() in expected_md5_hexdigests): return False
  warning = "Warning: unexpected md5 hexdigest:"
  file_name = "  File: %s" % show_string(path)
  new_hexdigest = "  New md5 hexdigest: %s" % m.hexdigest()
  width = max([len(s) for s in [warning, file_name, new_hexdigest]])
  if (out is None): out = sys.stdout
  print >> out, "*"*width
  print >> out, warning
  print >> out, file_name
  print >> out, new_hexdigest
  for hint in hints:
    print >> out, hint
  print >> out, "*"*width
  return True

def get_memory_from_string(mem_str):
  if type(mem_str)==type(1): return mem_str
  if type(mem_str)==type(1.): return mem_str
  mem_str = mem_str.replace(" ","").strip().upper()
  if mem_str == "": return 0
  factor=1024
  for i, greek in enumerate(["K","M","G","T","E","Z","Y"]):
    num_str=None
    if mem_str[-1]==greek:
      num_str = mem_str[:-1]
    if mem_str.find("%sB" % greek)==len(mem_str)-2:
      num_str = mem_str[:-2]
    if num_str is not None:
      try:
        num = float(num_str)
      except ValueError, e:
        raise RuntimeError("""
   The numerical portion of %s is not a valid float
""" % mem_str)
      break
    factor*=1024
  else:
    try:
      num = int(mem_str)
    except ValueError, e:
      raise RuntimeError("""
   There is no memory unit or valid float in %s
""" % mem_str)
    factor=1
  return num*factor

def getenv_bool(variable_name, default=False):
  value = os.environ.get(variable_name, None)
  if (value is None): return default
  value_lower = value.lower()
  if (value_lower not in ["false", "true"]):
    raise Sorry(
      'Environment variable %s must be "True" or "False"'
      ' (current value: "%s").' % (variable_name, value))
  return (value_lower == "true")

def file_size(file_name):
  return os.stat(file_name).st_size

def copy_file(source, target, compress=None):
  assert os.path.isfile(source)
  if (os.path.isdir(target)):
    target = os.path.join(target, os.path.basename(source))
  if (compress is None):
    t = open(target, "wb")
  else:
    assert compress == ".gz"
    t = gzip_open(file_name=target+compress, mode="wb")
  t.write(open(source, "rb").read())
  del t

def remove_files(pattern):
  for path in glob.glob(pattern):
    if (os.path.isfile(path)):
      os.remove(path)

def tupleize(x):
  try:
    return tuple(x)
  except KeyboardInterrupt: raise
  except:
    return (x,)

def plural_s(n):
  if (n == 1): return n, ""
  return n, "s"

def flat_list(nested_list):
  result = []
  if (hasattr(nested_list, "__len__")):
    for sub_list in nested_list:
      result.extend(flat_list(sub_list))
  else:
    result.append(nested_list)
  return result

class Keep: pass

disable_tracebacklimit = False

class Sorry(Exception):
  # trick to get just "Sorry" instead of "libtbx.utils.Sorry"
  __module__ = "exceptions"

  def __init__(self, *args, **keyword_args):
    if (not disable_tracebacklimit):
      self.previous_tracebacklimit = getattr(sys, "tracebacklimit", None)
      sys.tracebacklimit = 0
    Exception.__init__(self, *args, **keyword_args)

  def __str__(self):
    self.reset_tracebacklimit()
    return Exception.__str__(self)

  def __del__(self):
    self.reset_tracebacklimit()

  def reset_tracebacklimit(self):
    if (not disable_tracebacklimit and hasattr(sys, "tracebacklimit")):
      if (self.previous_tracebacklimit is None):
        del sys.tracebacklimit
      else:
        sys.tracebacklimit = self.previous_tracebacklimit

disable_tracebacklimit = "LIBTBX_DISABLE_TRACEBACKLIMIT" in os.environ

class Usage(Sorry):
  __module__ = "exceptions"

def if_none(value, default):
  if (value is None): return default
  return value

def format_exception():
  ei = sys.exc_info()
  type_ = ei[0].__name__
  value = str(ei[1])
  if (value != ""):
    value = value.replace(" (<string>, line ", " (line ")
  else:
    file_name, line = traceback.extract_tb(sys.exc_info()[2], 1)[0][:2]
    if (file_name is not None):
      value = file_name+" "
    if (line is not None):
      value += "line %d" % line
  return ("%s: %s" % (type_, value)).rstrip()

def date_and_time():
  seconds_since_epoch = time.time()
  localtime = time.localtime(seconds_since_epoch)
  if (time.daylight and localtime[8] != 0):
    tzname = time.tzname[1]
    offs = -time.altzone
  else:
    tzname = time.tzname[0]
    offs = -time.timezone
  return time.strftime("Date %Y-%m-%d Time %H:%M:%S", localtime) \
       + " %s %+03d%02d (%.2f s)" % (
           tzname, offs//3600, offs//60%60, seconds_since_epoch)


class timer_base(object):

  def __init__(self):
    self.t = self.get()

  def elapsed(self):
    t = self.get()
    d = t - self.t
    return d

  def delta(self):
    t = self.get()
    d = t - self.t
    self.t = t
    return d

  def show_elapsed(self, prefix="", out=None):
    if (out == None): out = sys.stdout
    print >> out, prefix+"%.2f s" % self.elapsed()

  def show_delta(self, prefix="", out=None):
    if (out == None): out = sys.stdout
    print >> out, prefix+"%.2f s" % self.delta()


class user_plus_sys_time(timer_base):

  def get(self):
    t = os.times()
    return t[0] + t[1]


class wall_clock_time(timer_base):
  """ motivation: when running multithreaded code, user_plus_sys_time
  would report the cumulated times for all threads: not very useful
  to analyse the scaling with the number of threads! Wall clock time, although
  it is less reliable is the only solution in that case """

  def get(self):
    t = os.times()
    return t[-1]


class time_log(object):

  def __init__(self, label):
    self.label = label
    self.accumulation = 0
    self.n = 0
    self.delta = 0
    self.timer = None

  def start(self):
    self.timer = user_plus_sys_time()
    return self

  def stop(self):
    self.delta = self.timer.delta()
    self.timer = None
    self.accumulation += self.delta
    self.n += 1

  def average(self):
    return self.accumulation / max(1,self.n)

  def log(self):
    self.stop()
    return self.report()

  def log_elapsed(self, local_label):
    return "time_log: %s: %.2f elapsed %s" % (
      self.label, self.timer.elapsed(), local_label)

  legend = "time_log: label: n accumulation delta average"

  def report(self):
    assert self.timer is None
    return "time_log: %s: %d %.2f %.3g %.3g" % (
      self.label, self.n, self.accumulation,
      self.delta, self.average())

def human_readable_time(time_in_seconds):
  time_units = time_in_seconds
  time_unit = "seconds"
  if (time_units > 120):
    time_units /= 60
    time_unit = "minutes"
    if (time_units > 120):
      time_units /= 60
      time_unit = "hours"
      if (time_units > 48):
        time_units /= 24
        time_unit = "days"
  return time_units, time_unit

def human_readable_time_as_seconds(time_units, time_unit):
  if (isinstance(time_units, str)): time_units = float(time_units)
  if (time_unit == "seconds"): return time_units
  if (time_unit == "minutes"): return time_units*60
  if (time_unit == "hours"): return time_units*60*60
  if (time_unit == "days"): return time_units*60*60*24
  raise RuntimeError("Unknown time_unit: %s" % time_unit)

def format_cpu_times(show_micro_seconds_per_tick=True):
  t = os.times()
  result = "u+s,u,s: %.2f %.2f %.2f" % (t[0] + t[1], t[0], t[1])
  if (show_micro_seconds_per_tick):
    try: python_ticker = sys.gettickeraccumulation()
    except AttributeError: pass
    else:
      result += " micro-seconds/tick: %.3f" % ((t[0]+t[1])/python_ticker*1.e6)
  return result

def show_total_time(
      out=None,
      show_micro_seconds_per_bytecode_instruction=True):
  if (out == None): out = sys.stdout
  total_time = user_plus_sys_time().get()
  try: python_ticker = sys.gettickeraccumulation()
  except AttributeError: pass
  else:
    print >> out, "Time per interpreted Python bytecode instruction:",
    print >> out, "%.3f micro seconds" % (total_time / python_ticker * 1.e6)
  print >> out, "Total CPU time: %.2f %s" % human_readable_time(total_time)

class show_times:

  def __init__(self, time_start=None, out=None):
    if (time_start is None):
      t = os.times()
      self.time_start = time.time() - (t[0] + t[1])
    elif (time_start == "now"):
      self.time_start = time.time()
    else:
      self.time_start = -(0-time_start) # be sure time_start is a number
    self.out = out

  def __call__(self):
    out = self.out
    if (out is None): out = sys.stdout
    t = os.times()
    usr_plus_sys = t[0] + t[1]
    try: ticks = sys.gettickeraccumulation()
    except AttributeError: ticks = None
    s = "usr+sys time: %.2f seconds" % usr_plus_sys
    if (ticks is not None):
      s += ", ticks: %d" % ticks
      if (ticks != 0):
        s += ", micro-seconds/tick: %.3f" % (usr_plus_sys*1.e6/ticks)
    print >> out, s
    wall_clock_time = time.time() - self.time_start
    print >> out, "wall clock time:",
    if (wall_clock_time < 120):
      print >> out, "%.2f seconds" % wall_clock_time
    else:
      m = int(wall_clock_time / 60 + 1.e-6)
      s = wall_clock_time - m * 60
      print >> out, "%d minutes %.2f seconds (%.2f seconds total)" % (
        m, s, wall_clock_time)
    out_flush = getattr(out, "flush", None)
    if (out_flush is not None):
      out_flush()

def show_times_at_exit(time_start=None, out=None):
  atexit.register(show_times(time_start=time_start, out=out))

class host_and_user:

  def __init__(self):
    self.host = os.environ.get("HOST")
    self.hostname = os.environ.get("HOSTNAME")
    self.computername = os.environ.get("COMPUTERNAME")
    self.hosttype = os.environ.get("HOSTTYPE")
    self.processor_architecture = os.environ.get("PROCESSOR_ARCHITECTURE")
    self.machtype = os.environ.get("MACHTYPE")
    self.ostype = os.environ.get("OSTYPE")
    self.vendor = os.environ.get("VENDOR")
    self.user = os.environ.get("USER")
    self.username = os.environ.get("USERNAME")
    getpid = getattr(os, "getpid", None)
    if (getpid is None):
      self.pid = None
    else:
      self.pid = getpid()
    self.sge_info = sge_utils.info()

  def show(self, out=None, prefix=""):
    if (out is None): out = sys.stdout
    if (self.host is not None):
      print >> out, prefix + "HOST =", self.host
    if (    self.hostname is not None
        and self.hostname != self.host):
      print >> out, prefix + "HOSTNAME =", self.hostname
    if (    self.computername is not None
        and self.computername != self.host):
      print >> out, prefix + "COMPUTERNAME =", self.computername
    if (self.hosttype is not None):
      print >> out, prefix + "HOSTTYPE =", self.hosttype
    if (self.processor_architecture is not None):
      print >> out, prefix + "PROCESSOR_ARCHITECTURE =", \
        self.processor_architecture
    if (   self.hosttype is None
        or self.machtype is None
        or self.ostype is None
        or "-".join([self.machtype, self.ostype]) != self.hosttype):
      if (self.machtype is not None):
        print >> out, prefix + "MACHTYPE =", \
          self.machtype
      if (self.ostype is not None):
        print >> out, prefix + "OSTYPE =", \
          self.ostype
    if (self.vendor is not None and self.vendor != "unknown"):
      print >> out, prefix + "VENDOR =", \
        self.vendor
    if (self.user is not None):
      print >> out, prefix + "USER =", self.user
    if (    self.username is not None
        and self.username != self.user):
      print >> out, prefix + "USERNAME =", self.username
    if (self.pid is not None):
      print >> out, prefix + "PID =", self.pid
    self.sge_info.show(out=out, prefix=prefix)

def _indentor_write_loop(write_method, indent, incomplete_line, lines):
  for line in lines:
    if (len(line) == 0):
      incomplete_line = False
    elif (incomplete_line):
      write_method(line)
      incomplete_line = False
    else:
      write_method(indent)
      write_method(line)
    write_method("\n")

class indentor(object):

  def __init__(self, file_object=None, indent="", parent=None):
    if (file_object is None):
      if (parent is None):
        file_object = sys.stdout
      else:
        file_object = parent.file_object
    self.file_object = file_object
    if (hasattr(self.file_object, "flush")):
      self.flush = self._flush
    self.indent = indent
    self.parent = parent
    self.incomplete_line = False

  def write(self, block):
    if (len(block) == 0): return
    if (block.endswith("\n")):
      _indentor_write_loop(
        write_method=self.file_object.write,
        indent=self.indent,
        incomplete_line=self.incomplete_line,
        lines=block.splitlines())
      self.incomplete_line = False
    else:
      lines = block.splitlines()
      if (len(lines) == 1):
        if (self.incomplete_line):
          self.file_object.write(lines[-1])
        else:
          self.file_object.write(self.indent + lines[-1])
      else:
        _indentor_write_loop(
          write_method=self.file_object.write,
          indent=self.indent,
          incomplete_line=self.incomplete_line,
          lines=lines[:-1])
        self.file_object.write(self.indent + lines[-1])
      self.incomplete_line = True

  def _flush(self):
    self.file_object.flush()

  def shift_right(self, indent="  "):
    return self.__class__(indent=self.indent+indent, parent=self)

class buffered_indentor(indentor):

  def __init__(self, file_object=None, indent="", parent=None):
    indentor.__init__(self, file_object, indent, parent)
    self.buffer = []

  def write(self, block):
    self.buffer.append(block)

  def write_buffer(self):
    if (self.parent is not None):
      self.parent.write_buffer()
    for block in self.buffer:
      indentor.write(self, block)
    self.buffer = []

class null_out(object):

  def isatty(self): return False
  def close(self): pass
  def flush(self): pass
  def write(self, str): pass
  def writelines(self, sequence): pass

class multi_out(object):

  def __init__(self):
    self.labels = []
    self.file_objects = []
    self.atexit_send_to = []
    self.closed = False
    self.softspace = 0
    atexit.register(self._atexit)

  def _atexit(self):
    if (not self.closed):
      for f,a in zip(self.file_objects, self.atexit_send_to):
        if (a is not None): a.write(f.getvalue())

  def register(self, label, file_object, atexit_send_to=None):
    assert not self.closed
    self.labels.append(label)
    self.file_objects.append(file_object)
    self.atexit_send_to.append(atexit_send_to)
    return self

  def replace_stringio(self,
        old_label,
        new_label,
        new_file_object,
        new_atexit_send_to=None):
    i = self.labels.index(old_label)
    old_file_object = self.file_objects[i]
    new_file_object.write(old_file_object.getvalue())
    old_file_object.close()
    self.labels[i] = new_label
    self.file_objects[i] = new_file_object
    self.atexit_send_to[i] = new_atexit_send_to

  def isatty(self):
    return False

  def close(self):
    for file_object in self.file_objects:
      if (file_object is sys.__stdout__): continue
      if (file_object is sys.__stderr__): continue
      file_object.close()
    self.closed = True

  def flush(self):
    for file_object in self.file_objects:
      flush = getattr(file_object, "flush", None)
      if (flush is not None): flush()

  def write(self, str):
    for file_object in self.file_objects:
      file_object.write(str)

  def writelines(self, sequence):
    for file_object in self.file_objects:
      file_object.writelines(sequence)

def write_this_is_auto_generated(f, file_name_generator):
  print >> f, """\
/* *****************************************************
   THIS IS AN AUTOMATICALLY GENERATED FILE. DO NOT EDIT.
   *****************************************************

   Generated by:
     %s
 */
""" % file_name_generator

class import_python_object:

  def __init__(self, import_path, error_prefix, target_must_be, where_str):
    path_elements = import_path.split(".")
    if (len(path_elements) < 2):
      raise ValueError(
        '%simport path "%s" is too short%s%s' % (
          error_prefix, import_path, target_must_be, where_str))
    module_path = ".".join(path_elements[:-1])
    try: module = __import__(module_path)
    except ImportError:
      raise ImportError("%sno module %s%s" % (
        error_prefix, module_path, where_str))
    for attr in path_elements[1:-1]:
      module = getattr(module, attr)
    try: self.object = getattr(module, path_elements[-1])
    except AttributeError:
      raise AttributeError(
        '%sobject "%s" not found in module "%s"%s' % (
          error_prefix, path_elements[-1], module_path, where_str))
    self.path_elements = path_elements
    self.module_path = module_path
    self.module = module

class input_with_prompt(object):

  def __init__(self, prompt, tracebacklimit=0):
    try: import readline
    except: pass
    try: self.previous_tracebacklimit = sys.tracebacklimit
    except: self.previous_tracebacklimit = None
    if (tracebacklimit is not None):
      sys.tracebacklimit = tracebacklimit
    self.input = raw_input(prompt)

  def __del__(self):
    if (self.previous_tracebacklimit is None):
      del sys.tracebacklimit
    else:
      sys.tracebacklimit = self.previous_tracebacklimit

def count_max(assert_less_than):
  i = 0
  while True:
    yield None
    i += 1
    assert i < assert_less_than

class detect_binary_file(object):

  def __init__(self, monitor_initial=None, max_fraction_non_ascii=None):
    if (monitor_initial is None):
      self.monitor_initial = 1000
    else:
      self.monitor_initial = monitor_initial
    if (max_fraction_non_ascii is None):
      self.max_fraction_non_ascii = 0.05
    else:
      self.max_fraction_non_ascii = max_fraction_non_ascii
    self.n_ascii_characters = 0
    self.n_non_ascii_characters = 0
    self.status = None

  def is_binary_file(self, block):
    if (self.monitor_initial > 0):
      for c in block:
        if (1 < ord(c) < 128):
          self.n_ascii_characters += 1
        else:
          self.n_non_ascii_characters += 1
        self.monitor_initial -= 1
        if (self.monitor_initial == 0):
          if (  self.n_non_ascii_characters
              > self.n_ascii_characters * self.max_fraction_non_ascii):
            self.status = True
          else:
            self.status = False
          break
    return self.status

  def from_initial_block(
        file_name,
        monitor_initial=None,
        max_fraction_non_ascii=None):
    detector = detect_binary_file(
      monitor_initial=monitor_initial,
      max_fraction_non_ascii=max_fraction_non_ascii)
    block = open(file_name, "rb").read(detector.monitor_initial)
    if (len(block) == 0): return False
    detector.monitor_initial = min(len(block), detector.monitor_initial)
    return detector.is_binary_file(block=block)
  from_initial_block = staticmethod(from_initial_block)

def search_for(
      pattern,
      mode,
      re_flags=0,
      lines=None,
      file_name=None):
  assert mode in ["==", "find", "startswith", "endswith", "re.search", "re.match"]
  assert [lines, file_name].count(None) == 1
  if (lines is None):
    lines = open(file_name).read().splitlines()
  result = []
  a = result.append
  if (mode == "=="):
    for l in lines:
      if (l == pattern): a(l)
  elif (mode == "startswith"):
    for l in lines:
      if (l.startswith(pattern)): a(l)
  elif (mode == "endswith"):
    for l in lines:
      if (l.endswith(pattern)): a(l)
  elif (mode == "find"):
    for l in lines:
      if (l.find(pattern) >= 0): a(l)
  elif (mode == "re.search"):
    import re
    for l in lines:
      if (re.search(pattern=pattern, string=l, flags=re_flags) is not None):
        a(l)
  else:
    import re
    for l in lines:
      if (re.match(pattern=pattern, string=l, flags=re_flags) is not None):
        a(l)
  return result

def exercise():
  from libtbx.test_utils import approx_equal
  host_and_user().show(prefix="### ")
  time_in_seconds = 1.1
  for i_trial in xrange(55):
    time_in_seconds = time_in_seconds**1.1
    time_units, time_unit = human_readable_time(
      time_in_seconds=time_in_seconds)
    assert approx_equal(
      human_readable_time_as_seconds(time_units, time_unit), time_in_seconds)
  #
  for s,i in {"2000000" : 2000000,
              "2k" : 2048,
              "2Kb" : 2048,
              "2 Kb" : 2048,
              "5Mb" : 5*1024*1024,
              "2.5Gb" : 2.5*1024*1024*1024,
              "1T": 1024*1024*1024*1024,
              10000 : 10000,
              5.5 : 5.5,
              #"ten mb" : 0,
              #"ralf" : 0,
              }.items():
    assert get_memory_from_string(s) == i
  #
  assert tupleize(1) == (1,)
  assert tupleize("abcde") == ('a', 'b', 'c', 'd', 'e')
  assert tupleize([1,2,3]) == (1,2,3)
  #
  assert search_for(pattern="fox", mode="==", lines=["fox", "foxes"]) \
      == ["fox"]
  assert search_for(pattern="o", mode="find", lines=["fox", "bird", "mouse"]) \
      == ["fox", "mouse"]
  assert search_for(pattern="fox", mode="startswith", lines=["fox", "foxes"]) \
      == ["fox", "foxes"]
  assert search_for(pattern="xes", mode="endswith", lines=["fox", "foxes"]) \
      == ["foxes"]
  assert search_for(pattern="es$", mode="re.search", lines=["geese", "foxes"]) \
      == ["foxes"]
  assert search_for(pattern="ge", mode="re.match", lines=["geese", "angel"]) \
      == ["geese"]
  #
  print "OK"

if (__name__ == "__main__"):
  exercise()
