"Sun Grid Engine utilities"

from __future__ import generators
import sys, os

def int_or_none(v):
  if (v is None or v == "undefined"): return None
  return int(v)

def job_id():
  return int_or_none(os.environ.get("JOB_ID"))

def arch():
  return os.environ.get("SGE_ARCH")

class task_info(object):

  def __init__(self):
    self.first = int_or_none(os.environ.get("SGE_TASK_FIRST"))
    self.last = int_or_none(os.environ.get("SGE_TASK_LAST"))
    self.id = int_or_none(os.environ.get("SGE_TASK_ID"))
    assert [self.first, self.last, self.id].count(None) in [0, 3]

  def show(self, out=None, prefix="", even_if_none=False):
    if (out is None): out = sys.stdout
    if (self.first is not None or even_if_none):
      print >> out, prefix+"SGE_TASK_FIRST =", self.first
    if (self.last is not None or even_if_none):
      print >> out, prefix+"SGE_TASK_LAST =", self.last
    if (self.id is not None or even_if_none):
      print >> out, prefix+"SGE_TASK_ID =", self.id
    return self

  def as_n_i_pair(self):
    if (self.first is None): return 1, 0
    assert self.first == 1
    return self.last, self.id-1

  def skip_loop_iteration(self):
    return skip_loop_iteration(*self.as_n_i_pair())

def skip_loop_iteration(n, i):
  j = 0
  while True:
    yield (j % n != i)
    j += 1

class info(task_info):

  def __init__(self):
    task_info.__init__(self)
    self.job_id = job_id()
    self.arch = arch()

  def show(self, out=None, prefix="", even_if_none=False):
    if (out is None): out = sys.stdout
    if (self.job_id is not None or even_if_none):
      print >> out, prefix+"JOB_ID =", self.job_id
    if (self.arch is not None or even_if_none):
      print >> out, prefix+"SGE_ARCH =", self.arch
    task_info.show(self, out=out, prefix=prefix, even_if_none=even_if_none)

class qstat_items(object):

  def __init__(self, job_id, prior, name, user, state,
                     submit, queue, slots, ja_task_id):
    self.job_id = job_id
    self.prior = prior
    self.name = name
    self.user = user
    self.state = state
    self.submit = submit
    self.queue = queue
    self.slots = slots
    self.ja_task_id = ja_task_id

  def counts(self):
    ja_task_id = self.ja_task_id
    if (len(ja_task_id) == 0): return 1
    m = ja_task_id.find("-")
    c = ja_task_id.find(":")
    if (m < 0):
      assert c < 0
      assert str(int(ja_task_id)) == ja_task_id
      return 1
    assert c > 0
    assert c > m
    f = int(ja_task_id[:m])
    l = int(ja_task_id[m+1:c])
    s = int(ja_task_id[c+1:])
    return len(xrange(f,l+1,s))

  def oe_name(self, oe):
    ja_task_id = self.ja_task_id
    if (len(ja_task_id) == 0):
      return "%s.%s%s" % (self.name, oe, self.job_id)
    if (ja_task_id.find("-") >= 0): return None
    if (ja_task_id.find(":") >= 0): return None
    return "%s.%s%s.%s" % (self.name, oe, self.job_id, ja_task_id)

  def o_name(self):
    return self.oe_name(oe="o")

  def e_name(self):
    return self.oe_name(oe="e")

def qstat_parse():
  from libtbx import easy_run
  qstat_out = easy_run.fully_buffered(
    command="qstat").raise_if_errors().stdout_lines
  result = []
  if (len(qstat_out) == 0):
    return result
  qstat = iter(qstat_out)
  try: header = qstat.next()
  except StopIteration: header = ""
  expected_header = \
    "job-ID prior name user state submit/start at queue slots ja-task-ID"
  if (" ".join(header.split()) != expected_header):
    raise RuntimeError("Unexpected qstat header: %s" % header)
  line = qstat.next()
  if (len(line.strip().replace("-","")) != 0):
    raise RuntimeError("Unexpected qstat header seperator line: %s" % line)
  i_job_id = 0
  i_prior = header.index(" prior ") + 1
  i_name = header.index(" name ") + 1
  i_user = header.index(" user ") + 1
  i_state = header.index(" state ") + 1
  i_submit = header.index(" submit/start at ") + 1
  i_queue = header.index(" queue ") + 1
  i_slots = header.index(" slots ") + 1
  i_ja_task_id = header.index(" ja-task-ID") + 1
  for line in qstat:
    result.append(qstat_items(
      job_id=line[i_job_id:i_prior].strip(),
      prior=line[i_prior:i_name].strip(),
      name=line[i_name:i_user].strip(),
      user=line[i_user:i_state].strip(),
      state=line[i_state:i_submit].strip(),
      submit=line[i_submit:i_queue].strip(),
      queue=line[i_queue:i_slots].strip(),
      slots=line[i_slots:i_ja_task_id].strip(),
      ja_task_id=line[i_ja_task_id:].strip()))
  return result

if (__name__ == "__main__"):
  info().show(prefix="*** ", even_if_none=True)
  print "OK"
