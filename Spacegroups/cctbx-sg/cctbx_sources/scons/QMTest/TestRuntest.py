"""
TestRuntest.py:  a testing framework for the runtest.py command used to
invoke SCons tests.

A TestRuntest environment object is created via the usual invocation:

    test = TestRuntest()

TestRuntest is a subclass of TestCommon, which is in turn is a subclass
of TestCmd), and hence has available all of the methods and attributes
from those classes, as well as any overridden or additional methods or
attributes defined in this subclass.
"""

# __COPYRIGHT__

__revision__ = "__FILE__ __REVISION__ __DATE__ __DEVELOPER__"

import os
import os.path
import string
import shutil
import sys

from TestCommon import *
from TestCommon import __all__

__all__.extend([ 'TestRuntest',
                 'python',
                 '_python_',
               ])

python = python_executable
_python_ = '"' + python_executable + '"'


failing_test_template = """\
import sys
sys.stdout.write('FAILING TEST STDOUT\\n')
sys.stderr.write('FAILING TEST STDERR\\n')
sys.exit(1)
"""

no_result_test_template = """\
import sys
sys.stdout.write('NO RESULT TEST STDOUT\\n')
sys.stderr.write('NO RESULT TEST STDERR\\n')
sys.exit(2)
"""

passing_test_template = """\
import sys
sys.stdout.write('PASSING TEST STDOUT\\n')
sys.stderr.write('PASSING TEST STDERR\\n')
sys.exit(0)
"""

fake_scons_py = """
__version__ = '1.2.3'
__build__ = 'D123'
__buildsys__ = 'fake_system'
__date__ = 'Jan 1 1970'
__developer__ = 'Anonymous'
"""

fake___init___py = """
__version__ = '4.5.6'
__build__ = 'D456'
__buildsys__ = 'another_fake_system'
__date__ = 'Dec 31 1999'
__developer__ = 'John Doe'
"""

class TestRuntest(TestCommon):
    """Class for testing the runtest.py script.

    This provides a common place for initializing Runtest tests,
    eliminating the need to begin every test with the same repeated
    initializations.
    """

    def __init__(self, **kw):
        """Initialize a Runtest testing object.

        If they're not overridden by keyword arguments, this
        initializes the object with the following default values:

                program = 'runtest.py'
                interpreter = ['python', '-tt']
                match = match_exact
                workdir = ''

        The workdir value means that, by default, a temporary
        workspace directory is created for a TestRuntest environment.
        The superclass TestCommon.__init__() will change directory (chdir)
        to the workspace directory, so an explicit "chdir = '.'" on all
        of the run() method calls is not necessary.  This initialization
        also copies the runtest.py and QMTest/ subdirectory tree to the
        temporary directory, duplicating how this test infrastructure
        appears in a normal workspace.
        """
        set_workpath_runtest = None
        if not kw.has_key('program'):
            kw['program'] = 'runtest.py'
            set_workpath_runtest = 1
        if not kw.has_key('interpreter'):
            kw['interpreter'] = [python, '-tt']
        if not kw.has_key('match'):
            kw['match'] = match_exact
        if not kw.has_key('workdir'):
            kw['workdir'] = ''

        try:
            noqmtest = kw['noqmtest']
        except KeyError:
            noqmtest = 0
        else:
            del kw['noqmtest']

        orig_cwd = os.getcwd()
        apply(TestCommon.__init__, [self], kw)
  
        if not noqmtest:
            qmtest = self.where_is('qmtest')
            if not qmtest:
                self.skip_test("Could not find 'qmtest'; skipping test(s).\n")

        things_to_copy = [
            'runtest.py',
            'QMTest',
        ]

        dirs = [os.environ.get('SCONS_RUNTEST_DIR', orig_cwd)]
        
        spe = os.environ.get('SCONS_SOURCE_PATH_EXECUTABLE', orig_cwd)
        for d in string.split(spe, os.pathsep):
            dirs.append(os.path.join(d, 'build'))
            dirs.append(d)

        for thing in things_to_copy:
            for dir in dirs:
                t = os.path.join(dir, thing)
                if os.path.exists(t):
                    if os.path.isdir(t):
                        copy_func = shutil.copytree
                    else:
                        copy_func = shutil.copyfile
                    copy_func(t, self.workpath(thing))
                    break

        if set_workpath_runtest:
            self.program_set(self.workpath('runtest.py'))

        for key in os.environ.keys():
            if key[:5] == 'AEGIS':
                os.environ[key] = ''

        os.environ['PYTHONPATH'] = ''
        os.environ['SCONS_SOURCE_PATH_EXECUTABLE'] = ''

    def write_fake_scons_source_tree(self):
        os.mkdir('src')
        os.mkdir('src/script')
        self.write('src/script/scons.py', fake_scons_py)

        os.mkdir('src/engine')
        os.mkdir('src/engine/SCons')
        self.write('src/engine/SCons/__init__.py', fake___init___py)
        os.mkdir('src/engine/SCons/Script')
        self.write('src/engine/SCons/Script/__init__.py', fake___init___py)

    def write_failing_test(self, name):
        self.write(name, failing_test_template)

    def write_no_result_test(self, name):
        self.write(name, no_result_test_template)

    def write_passing_test(self, name):
        self.write(name, passing_test_template)
