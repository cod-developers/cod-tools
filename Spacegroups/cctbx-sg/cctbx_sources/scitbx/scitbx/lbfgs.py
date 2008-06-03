from scitbx.array_family import flex

import boost.python
ext = boost.python.import_ext("scitbx_lbfgs_ext")
from scitbx_lbfgs_ext import *

from libtbx import adopt_init_args

class core_parameters(object):

  def __init__(self, m=5,
                     maxfev=20,
                     gtol=0.9,
                     xtol=1.e-16,
                     stpmin=1.e-20,
                     stpmax=1.e20):
    adopt_init_args(self, locals())

class termination_parameters(object):

  def __init__(self, traditional_convergence_test=True,
                     traditional_convergence_test_eps=1.e-5,
                     drop_convergence_test_n_test_points=5,
                     drop_convergence_test_max_drop_eps=1.e-5,
                     drop_convergence_test_iteration_coefficient=2,
                     min_iterations=0,
                     max_iterations=None,
                     max_calls=None):
    drop_convergence_test_n_test_points = max(
      drop_convergence_test_n_test_points,
      min_iterations)
    adopt_init_args(self, locals())

class exception_handling_parameters(object):

  def __init__(self, ignore_line_search_failed_rounding_errors=True,
                     ignore_line_search_failed_step_at_lower_bound=False,
                     ignore_line_search_failed_step_at_upper_bound=False,
                     ignore_line_search_failed_maxfev=False,
                     ignore_line_search_failed_xtol=False,
                     ignore_search_direction_not_descent=False):
    adopt_init_args(self, locals())

  def filter(self, msg, n, x, g):
    if (not msg.startswith("lbfgs error")):
      return 1
    if (msg.find("Rounding errors prevent further progress.") >= 0):
      if (self.ignore_line_search_failed_rounding_errors):
        return 0
    elif (msg.find("The step is at the lower bound stpmin().") >= 0):
      if (x is not None and g is not None
          and ext.traditional_convergence_test(n)(x, g)):
        return 0
      if (self.ignore_line_search_failed_step_at_lower_bound):
        return -1
    elif (msg.find("The step is at the upper bound stpmax().") >= 0):
      if (self.ignore_line_search_failed_step_at_upper_bound):
        return -1
    elif (msg.find("Number of function evaluations has reached"
                 + " maxfev().") >= 0):
      if (self.ignore_line_search_failed_maxfev):
        return -1
    elif (msg.find("Relative width of the interval of uncertainty"
                 + " is at most xtol().") >= 0):
      if (self.ignore_line_search_failed_xtol):
        return -1
    elif (msg.find("The search direction is not a descent direction.") >= 0):
      if (x is not None and g is not None
          and ext.traditional_convergence_test(n)(x, g)):
        return 0
      if (self.ignore_search_direction_not_descent):
        return -1
    return 1

def run_c_plus_plus(target_evaluator,
                    termination_params=None,
                    core_params=None,
                    exception_handling_params=None,
                    log=None):
  if (termination_params is None):
    termination_params = termination_parameters()
  if (core_params is None):
    core_params = core_parameters()
  if (exception_handling_params is None):
    exception_handling_params = exception_handling_parameters()
  x = target_evaluator.x
  if (log is not None):
    print >> log, "lbfgs minimizer():"
    print >> log, "  x.size():", x.size()
    print >> log, "  m:", core_params.m
    print >> log, "  maxfev:", core_params.maxfev
    print >> log, "  gtol:", core_params.gtol
    print >> log, "  xtol:", core_params.xtol
    print >> log, "  stpmin:", core_params.stpmin
    print >> log, "  stpmax:", core_params.stpmax
    print >> log, "lbfgs traditional_convergence_test:", \
      termination_params.traditional_convergence_test
  minimizer = ext.minimizer(
    x.size(),
    core_params.m,
    core_params.maxfev,
    core_params.gtol,
    core_params.xtol,
    core_params.stpmin,
    core_params.stpmax)
  if (termination_params.traditional_convergence_test):
    is_converged = ext.traditional_convergence_test(
      x.size(),
      termination_params.traditional_convergence_test_eps)
  else:
    is_converged = ext.drop_convergence_test(
      n_test_points=termination_params.drop_convergence_test_n_test_points,
      max_drop_eps=termination_params.drop_convergence_test_max_drop_eps,
      iteration_coefficient
        =termination_params.drop_convergence_test_iteration_coefficient)
  callback_after_step = getattr(target_evaluator, "callback_after_step", None)
  f_min, x_min = None, None
  f, g = None, None
  try:
    while 1:
      f, g = target_evaluator.compute_functional_and_gradients()
      if (f_min is None):
        if (not termination_params.traditional_convergence_test):
          is_converged(f)
        f_min, x_min = f, x.deep_copy()
      elif (f_min > f):
        f_min, x_min = f, x.deep_copy()
      if (log is not None):
        print >> log, "lbfgs minimizer.run():" \
          " f=%.6g, |g|=%.6g, x_min=%.6g, x_mean=%.6g, x_max=%.6g" % (
          f, g.norm(), flex.min(x), flex.mean(x), flex.max(x))
      if (minimizer.run(x, f, g)): continue
      if (log is not None):
        print >> log, "lbfgs minimizer step"
      if (callback_after_step is not None):
        if (callback_after_step(minimizer) is True):
          if (log is not None):
            print >> log, "lbfgs minimizer stop: callback_after_step is True"
          break
      if (termination_params.traditional_convergence_test):
        if (    minimizer.iter() >= termination_params.min_iterations
            and is_converged(x, g)):
          if (log is not None):
            print >> log, "lbfgs minimizer stop: traditional_convergence_test"
          break
      else:
        if (is_converged(f)):
          if (log is not None):
            print >> log, "lbfgs minimizer stop: drop_convergence_test"
          break
      if (    termination_params.max_iterations is not None
          and minimizer.iter() >= termination_params.max_iterations):
        if (log is not None):
          print >> log, "lbfgs minimizer stop: max_iterations"
        break
      if (    termination_params.max_calls is not None
          and minimizer.nfun() > termination_params.max_calls):
        if (log is not None):
          print >> log, "lbfgs minimizer stop: max_calls"
        break
      if (not minimizer.run(x, f, g)): break
  except RuntimeError, e:
    minimizer.error = str(e)
    if (log is not None):
      print >> log, "lbfgs minimizer exception:", str(e)
    if (x_min is not None):
      x.clear()
      x.extend(x_min)
    error_classification = exception_handling_params.filter(
      minimizer.error, x.size(), x, g)
    if (error_classification > 0):
      raise
    elif (error_classification < 0):
      minimizer.is_unusual_error = True
    else:
      minimizer.is_unusual_error = False
  else:
    minimizer.error = None
    minimizer.is_unusual_error = None
  if (log is not None):
    print >> log, "lbfgs minimizer done."
  return minimizer

def run_fortran(target_evaluator,
                termination_params=None,
                core_params=None):
  "For debugging only!"
  from scitbx.python_utils.misc import store
  from fortran_lbfgs import lbfgs as fortran_lbfgs
  import Numeric
  if (termination_params is None):
    termination_params = termination_parameters()
  if (core_params is None):
    core_params = core_parameters()
  assert termination_params.traditional_convergence_test
  assert core_params.maxfev == 20
  x = target_evaluator.x
  n = x.size()
  m = core_params.m
  gtol = core_params.gtol
  xtol = core_params.xtol
  stpmin = core_params.stpmin
  stpmax = core_params.stpmax
  eps = termination_params.traditional_convergence_test_eps
  x_numeric = Numeric.array(Numeric.arange(n), Numeric.Float64)
  g_numeric = Numeric.array(Numeric.arange(n), Numeric.Float64)
  size_w = n*(2*m+1)+2*m
  w = Numeric.array(Numeric.arange(size_w), Numeric.Float64)
  diag = Numeric.array(Numeric.arange(n), Numeric.Float64)
  iprint = [1, 0]
  diagco = 0
  iflag = Numeric.array([0], Numeric.Int32)
  minimizer = store(error=None)
  while 1:
    f, g = target_evaluator.compute_functional_and_gradients()
    for i,xi in enumerate(x): x_numeric[i] = xi
    for i,gi in enumerate(g): g_numeric[i] = gi
    fortran_lbfgs(n, m, x_numeric, f, g_numeric, diagco, diag,
      iprint, eps, xtol, w, iflag)
    for i,xi in enumerate(x_numeric): x[i] = xi
    if (iflag[0] == 0):
      break
    if (iflag[0] < 0):
      minimizer.error = "fortran lbfgs error"
      break
  return minimizer

def run(target_evaluator,
        termination_params=None,
        core_params=None,
        exception_handling_params=None,
        use_fortran=False,
        log=None):
  if (use_fortran):
    return run_fortran(target_evaluator, termination_params, core_params)
  else:
    return run_c_plus_plus(
      target_evaluator,
      termination_params,
      core_params,
      exception_handling_params,
      log)
