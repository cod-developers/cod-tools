from libtbx.utils import Sorry
import copy
import sys, os

from optik import *

def check_bool(option, opt, value):
  v = value.strip().lower()
  if (v in ["false", "no", "off", "0"]): return False
  if (v in ["true", "yes", "on", "1"]): return True
  raise OptionValueError(
    "option %s: invalid bool value: %r" % (opt, value))

DefaultOption = Option
assert not "bool" in DefaultOption.TYPE_CHECKER

class Option(DefaultOption):
  TYPES = Option.TYPES + ("bool",)
  TYPE_CHECKER = copy.copy(Option.TYPE_CHECKER)
  TYPE_CHECKER["bool"] = check_bool

make_option = Option

class option_parser(OptionParser):

  def __init__(self, usage=None, description=None, more_help=None):
    OptionParser.__init__(self, usage=usage, description=description)
    self.more_help = more_help
    self.show_defaults_callback = show_defaults_callback()
    self.chunk_callback = chunk_callback()

  def call_with_self_as_first_argument(self, callable, **kw):
    callable(option_parser=self, **kw)
    return self

  def option(self, *args, **kw):
    self.add_option(make_option(*args, **kw))
    return self

  def format_help(self, formatter=None):
    if formatter is None:
      formatter = self.formatter
    result = []
    if self.usage:
      result.append(self.get_usage() + "\n")
    result.append(self.format_option_help(formatter))
    if self.description:
      result.append("\n")
      result.append(self.format_description(formatter) + "\n")
      result.append("\n")
    if (self.more_help is not None):
      for line in self.more_help:
        result.append(line + "\n")
    return "".join(result)

  def show_help(self, f=None):
    if (f is None): f = sys.stdout
    f.write(self.format_help())

  def enable_show_defaults(self):
    self.add_option(make_option(None, "--show_defaults",
      action="callback",
      type="string",
      callback=self.show_defaults_callback,
      help='Print parameters visible at the given expert level'
           ' (integer value or "all") and exit. Optionally,'
           ' append .help, .more, or .all to the expert level, for example:\n'
           ' --show-defaults=all.help',
      metavar="EXPERT_LEVEL"))
    self.show_defaults_callback.is_enabled = True
    return self

  def enable_chunk(self):
    self.add_option(make_option(None, "--chunk",
      action="callback",
      type="string",
      callback=self.chunk_callback,
      help="Number of chunks for parallel execution and index for one process",
      metavar="n,i"))
    self.chunk_callback.is_enabled = True
    return self

  def process(self, args=None, nargs=None, min_nargs=None, max_nargs=None):
    if (self.show_defaults_callback.is_enabled
        and args is not None
        and len(args) > 0
        and args[-1] == "--show_defaults"):
      args = args + ["0"]
    assert nargs is None or (min_nargs is None and max_nargs is None)
    (options, args) = self.parse_args(args)
    if (min_nargs is None): min_nargs = nargs
    if (min_nargs is not None):
      if (len(args) < min_nargs):
        if (len(args) == 0):
          self.show_help()
          sys.exit(1)
        self.error("Not enough arguments (at least %d required, %d given)." % (
          min_nargs, len(args)))
    if (max_nargs is None): max_nargs = nargs
    if (max_nargs is not None):
      if (len(args) > max_nargs):
        self.error("Too many arguments (at most %d allowed, %d given)." % (
          max_nargs, len(args)))
    return processed_options(self, options, args,
      show_defaults_callback=self.show_defaults_callback,
      chunk_callback=self.chunk_callback)

libtbx_option_parser = option_parser

class processed_options(object):

  def __init__(self, parser, options, args,
        show_defaults_callback,
        chunk_callback):
    self.parser = parser
    self.options = options
    self.args = args
    self.expert_level = show_defaults_callback.expert_level
    self.attributes_level = show_defaults_callback.attributes_level
    self.chunk_n = chunk_callback.n
    self.chunk_i = chunk_callback.i

class show_defaults_callback(object):

  def __init__(self):
    self.is_enabled = False
    self.expert_level = None
    self.attributes_level = 0

  def raise_sorry(self, value):
        raise Sorry("""\
Invalid option value: --show-defaults="%s"
  Please specify an integer value or the word "all"
  Examples:
    --show_defaults=0   # novice
    --show_defaults=1   # slightly advanced
    --show_defaults=2   # more advanced
    etc.
    --show_defaults=all # everything
  Optionally, append
    .help   to display the parameter help, or
    .more   to display all parameter attributes which are not None
    .all    to display all parameter attributes
  Examples:
    --show_defaults=all.help
    --show_defaults=all.all""" % value)

  def __call__(self, option, opt, value, parser):
    flds = value.strip().lower().split(".")
    if (1 > len(flds) > 2): self.raise_sorry(value=value)
    if (flds[0] == "all"):
      self.expert_level = -1
    else:
      try: expert_level = int(flds[0])
      except ValueError: self.raise_sorry(value=value)
      self.expert_level = expert_level
    if (len(flds) > 1):
      if (flds[1] == "help"):
        self.attributes_level = 1
      elif (flds[1] == "more"):
        self.attributes_level = 2
      elif (flds[1] == "all"):
        self.attributes_level = 3
      else:
        self.raise_sorry(value=value)

class chunk_callback(object):

  def __init__(self):
    self.is_enabled = False
    self.n = 1
    self.i = 0

  def __call__(self, option, opt, value, parser):
    assert opt == "--chunk"
    try:
      self.n, self.i = [int(i) for i in value.split(",")]
    except:
      raise OptionError(
        "Two comma-separated positive integers required.",
        opt)
    if (self.n < 1):
      raise OptionError(
        "First integer (number of chunks) must be greater than 0 (%d given)."
        % self.n, opt)
    if (self.i < 0):
      raise OptionError(
        "Second integer (index of chunks) must be positive (%d given)."
        % self.i, opt)
    if (self.n < self.i):
      raise OptionError(
        ("First integer (number of chunks, %d given) must be greater"
        + " than second integer (index of chunks, %d given).")%(self.n,self.i),
        opt)
