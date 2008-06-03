"""
TestSCons.py:  a testing framework for the SCons software construction
tool.

A TestSCons environment object is created via the usual invocation:

    test = TestSCons()

TestScons is a subclass of TestCommon, which is in turn is a subclass
of TestCmd), and hence has available all of the methods and attributes
from those classes, as well as any overridden or additional methods or
attributes defined in this subclass.
"""

# __COPYRIGHT__

__revision__ = "__FILE__ __REVISION__ __DATE__ __DEVELOPER__"

import os
import os.path
import re
import string
import sys
import time

import __builtin__
try:
    __builtin__.zip
except AttributeError:
    def zip(*lists):
        result = []
        for i in xrange(len(lists[0])):
            result.append(tuple(map(lambda l, i=i: l[i], lists)))
        return result
    __builtin__.zip = zip

from TestCommon import *
from TestCommon import __all__

# Some tests which verify that SCons has been packaged properly need to
# look for specific version file names.  Replicating the version number
# here provides some independent verification that what we packaged
# conforms to what we expect.

default_version = '0.98.4'

copyright_years = '2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008'

# In the checked-in source, the value of SConsVersion in the following
# line must remain "__ VERSION __" (without the spaces) so the built
# version in build/QMTest/TestSCons.py contains the actual version
# string of the packages that have been built.
SConsVersion = '__VERSION__'
if SConsVersion == '__' + 'VERSION' + '__':
    SConsVersion = default_version

__all__.extend([ 'TestSCons',
                 'machine',
                 'python',
                 '_exe',
                 '_obj',
                 '_shobj',
                 'shobj_',
                 'lib_',
                 '_lib',
                 'dll_',
                 '_dll'
               ])

machine_map = {
    'i686'  : 'i386',
    'i586'  : 'i386',
    'i486'  : 'i386',
}

try:
    uname = os.uname
except AttributeError:
    # Windows doesn't have a uname() function.  We could use something like
    # sys.platform as a fallback, but that's not really a "machine," so
    # just leave it as None.
    machine = None
else:
    machine = uname()[4]
    machine = machine_map.get(machine, machine)

python = python_executable
_python_ = '"' + python_executable + '"'
_exe = exe_suffix
_obj = obj_suffix
_shobj = shobj_suffix
shobj_ = shobj_prefix
_lib = lib_suffix
lib_ = lib_prefix
_dll = dll_suffix
dll_ = dll_prefix

def gccFortranLibs():
    """Test whether -lfrtbegin is required.  This can probably be done in
    a more reliable way, but using popen3 is relatively efficient."""

    libs = ['g2c']

    try:
        import popen2
        stderr = popen2.popen3('gcc -v')[2]
    except OSError:
        return libs

    for l in stderr.readlines():
        list = string.split(l)
        if len(list) > 3 and list[:2] == ['gcc', 'version']:
            if list[2][:2] in ('3.', '4.'):
                libs = ['frtbegin'] + libs
                break
    return libs


if sys.platform == 'cygwin':
    # On Cygwin, os.path.normcase() lies, so just report back the
    # fact that the underlying Win32 OS is case-insensitive.
    def case_sensitive_suffixes(s1, s2):
        return 0
else:
    def case_sensitive_suffixes(s1, s2):
        return (os.path.normcase(s1) != os.path.normcase(s2))


if sys.platform == 'win32':
    fortran_lib = gccFortranLibs()
elif sys.platform == 'cygwin':
    fortran_lib = gccFortranLibs()
elif string.find(sys.platform, 'irix') != -1:
    fortran_lib = ['ftn']
else:
    fortran_lib = gccFortranLibs()



file_expr = r"""File "[^"]*", line \d+, in .+
"""

# re.escape escapes too much.
def re_escape(str):
    for c in ['.', '[', ']', '(', ')', '*', '+', '?']:  # Not an exhaustive list.
        str = string.replace(str, c, '\\' + c)
    return str



try:
    sys.version_info
except AttributeError:
    # Pre-1.6 Python has no sys.version_info
    version_string = string.split(sys.version)[0]
    version_ints = map(int, string.split(version_string, '.'))
    sys.version_info = tuple(version_ints + ['final', 0])

def python_version_string():
    return string.split(sys.version)[0]

def python_minor_version_string():
    return sys.version[:3]

def unsupported_python_version(version=sys.version_info):
    return version < (1, 5, 2)

def deprecated_python_version(version=sys.version_info):
    return version < (2, 2, 0)

if deprecated_python_version():
    msg = r"""
scons: warning: Support for pre-2.2 Python (%s) is deprecated.
    If this will cause hardship, contact dev@scons.tigris.org.
"""

    deprecated_python_expr = re_escape(msg % python_version_string()) + file_expr
    del msg
else:
    deprecated_python_expr = ""



class TestSCons(TestCommon):
    """Class for testing SCons.

    This provides a common place for initializing SCons tests,
    eliminating the need to begin every test with the same repeated
    initializations.
    """

    scons_version = SConsVersion

    def __init__(self, **kw):
        """Initialize an SCons testing object.

        If they're not overridden by keyword arguments, this
        initializes the object with the following default values:

                program = 'scons' if it exists,
                          else 'scons.py'
                interpreter = 'python'
                match = match_exact
                workdir = ''

        The workdir value means that, by default, a temporary workspace
        directory is created for a TestSCons environment.  In addition,
        this method changes directory (chdir) to the workspace directory,
        so an explicit "chdir = '.'" on all of the run() method calls
        is not necessary.
        """
        self.orig_cwd = os.getcwd()
        try:
            script_dir = os.environ['SCONS_SCRIPT_DIR']
        except KeyError:
            pass
        else:
            os.chdir(script_dir)
        if not kw.has_key('program'):
            kw['program'] = os.environ.get('SCONS')
            if not kw['program']:
                if os.path.exists('scons'):
                    kw['program'] = 'scons'
                else:
                    kw['program'] = 'scons.py'
        if not kw.has_key('interpreter') and not os.environ.get('SCONS_EXEC'):
            kw['interpreter'] = [python, '-tt']
        if not kw.has_key('match'):
            kw['match'] = match_exact
        if not kw.has_key('workdir'):
            kw['workdir'] = ''

	# Term causing test failures due to bogus readline init
	# control character output on FC8
        # TERM can cause test failures due to control chars in prompts etc.
        os.environ['TERM'] = 'dumb'

        if deprecated_python_version():
            sconsflags = os.environ.get('SCONSFLAGS')
            if sconsflags:
                sconsflags = [sconsflags]
            else:
                sconsflags = []
            sconsflags = sconsflags + ['--warn=no-python-version']
            os.environ['SCONSFLAGS'] = string.join(sconsflags)

        apply(TestCommon.__init__, [self], kw)

        import SCons.Node.FS
        if SCons.Node.FS.default_fs is None:
            SCons.Node.FS.default_fs = SCons.Node.FS.FS()

    def Environment(self, ENV=None, *args, **kw):
        """
        Return a construction Environment that optionally overrides
        the default external environment with the specified ENV.
        """
        import SCons.Environment
        import SCons.Errors
        if not ENV is None:
            kw['ENV'] = ENV
        try:
            return apply(SCons.Environment.Environment, args, kw)
        except (SCons.Errors.UserError, SCons.Errors.InternalError):
            return None

    def detect(self, var, prog=None, ENV=None, norm=None):
        """
        Detect a program named 'prog' by first checking the construction
        variable named 'var' and finally searching the path used by
        SCons. If either method fails to detect the program, then false
        is returned, otherwise the full path to prog is returned. If
        prog is None, then the value of the environment variable will be
        used as prog.
        """
        env = self.Environment(ENV)
        v = env.subst('$'+var)
        if not v:
            return None
        if prog is None:
            prog = v
        if v != prog:
            return None
        result = env.WhereIs(prog)
        if norm and os.sep != '/':
            result = string.replace(result, os.sep, '/')
        return result

    def detect_tool(self, tool, prog=None, ENV=None):
        """
        Given a tool (i.e., tool specification that would be passed
        to the "tools=" parameter of Environment()) and a program that
        corresponds to that tool, return true if and only if we can find
        that tool using Environment.Detect().

        By default, prog is set to the value passed into the tools parameter.
        """

        if not prog:
            prog = tool
        env = self.Environment(ENV, tools=[tool])
        if env is None:
            return None
        return env.Detect([prog])

    def where_is(self, prog, path=None):
        """
        Given a program, search for it in the specified external PATH,
        or in the actual external PATH is none is specified.
        """
        import SCons.Environment
        env = SCons.Environment.Environment()
        if path is None:
            path = os.environ['PATH']
        return env.WhereIs(prog, path)

    def wrap_stdout(self, build_str = "", read_str = "", error = 0, cleaning = 0):
        """Wraps standard output string(s) in the normal
        "Reading ... done" and "Building ... done" strings
        """
        cap,lc = [ ('Build','build'),
                   ('Clean','clean') ][cleaning]
        if error:
            term = "scons: %sing terminated because of errors.\n" % lc
        else:
            term = "scons: done %sing targets.\n" % lc
        return "scons: Reading SConscript files ...\n" + \
               read_str + \
               "scons: done reading SConscript files.\n" + \
               "scons: %sing targets ...\n" % cap + \
               build_str + \
               term

    def up_to_date(self, options = None, arguments = None, read_str = "", **kw):
        s = ""
        for arg in string.split(arguments):
            s = s + "scons: `%s' is up to date.\n" % arg
            if options:
                arguments = options + " " + arguments
        kw['arguments'] = arguments
        stdout = self.wrap_stdout(read_str = read_str, build_str = s)
        kw['stdout'] = re.escape(stdout)
        kw['match'] = self.match_re_dotall
        apply(self.run, [], kw)

    def not_up_to_date(self, options = None, arguments = None, **kw):
        """Asserts that none of the targets listed in arguments is
        up to date, but does not make any assumptions on other targets.
        This function is most useful in conjunction with the -n option.
        """
        s = ""
        for arg in string.split(arguments):
            s = s + "(?!scons: `%s' is up to date.)" % re.escape(arg)
            if options:
                arguments = options + " " + arguments
        s = '('+s+'[^\n]*\n)*'
        kw['arguments'] = arguments
        stdout = re.escape(self.wrap_stdout(build_str='ARGUMENTSGOHERE'))
        kw['stdout'] = string.replace(stdout, 'ARGUMENTSGOHERE', s)
        kw['match'] = self.match_re_dotall
        apply(self.run, [], kw)

    def diff_substr(self, expect, actual, prelen=20, postlen=40):
        i = 0
        for x, y in zip(expect, actual):
            if x != y:
                return "Actual did not match expect at char %d:\n" \
                       "    Expect:  %s\n" \
                       "    Actual:  %s\n" \
                       % (i, repr(expect[i-prelen:i+postlen]),
                             repr(actual[i-prelen:i+postlen]))
            i = i + 1
        return "Actual matched the expected output???"

    def python_file_line(self, file, line):
        """
        Returns a Python error line for output comparisons.

        The exec of the traceback line gives us the correct format for
        this version of Python.  Before 2.5, this yielded:

            File "<string>", line 1, ?

        Python 2.5 changed this to:

            File "<string>", line 1, <module>

        We stick the requested file name and line number in the right
        places, abstracting out the version difference.
        """
        exec 'import traceback; x = traceback.format_stack()[-1]'
        x = string.lstrip(x)
        x = string.replace(x, '<string>', file)
        x = string.replace(x, 'line 1,', 'line %s,' % line)
        return x

    def normalize_pdf(self, s):
        s = re.sub(r'/(Creation|Mod)Date \(D:[^)]*\)',
                   r'/\1Date (D:XXXX)', s)
        s = re.sub(r'/ID \[<[0-9a-fA-F]*> <[0-9a-fA-F]*>\]',
                   r'/ID [<XXXX> <XXXX>]', s)
        s = re.sub(r'/(BaseFont|FontName) /[A-Z]{6}',
                   r'/\1 /XXXXXX', s)
        s = re.sub(r'/Length \d+ *\n/Filter /FlateDecode\n',
                   r'/Length XXXX\n/Filter /FlateDecode\n', s)


        try:
            import zlib
        except ImportError:
            pass
        else:
            begin_marker = '/FlateDecode\n>>\nstream\n'
            end_marker = 'endstream\nendobj'

            encoded = []
            b = string.find(s, begin_marker, 0)
            while b != -1:
                b = b + len(begin_marker)
                e = string.find(s, end_marker, b)
                encoded.append((b, e))
                b = string.find(s, begin_marker, e + len(end_marker))

            x = 0
            r = []
            for b, e in encoded:
                r.append(s[x:b])
                d = zlib.decompress(s[b:e])
                d = re.sub(r'%%CreationDate: [^\n]*\n',
                           r'%%CreationDate: 1970 Jan 01 00:00:00\n', d)
                d = re.sub(r'%DVIPSSource:  TeX output \d\d\d\d\.\d\d\.\d\d:\d\d\d\d',
                           r'%DVIPSSource:  TeX output 1970.01.01:0000', d)
                d = re.sub(r'/(BaseFont|FontName) /[A-Z]{6}',
                           r'/\1 /XXXXXX', d)
                r.append(d)
                x = e
            r.append(s[x:])
            s = string.join(r, '')

        return s

    def paths(self,patterns):
        import glob
        result = []
        for p in patterns:
            paths = glob.glob(p)
            paths.sort()
            result.extend(paths)
        return result


    def java_ENV(self, version=None):
        """
        Initialize with a default external environment that uses a local
        Java SDK in preference to whatever's found in the default PATH.
        """
        try:
            return self._java_env[version]['ENV']
        except AttributeError:
            self._java_env = {}
        except KeyError:
            pass

        import SCons.Environment
        env = SCons.Environment.Environment()
        self._java_env[version] = env


        if version:
            patterns = [
                '/usr/java/jdk%s*/bin'    % version,
                '/usr/lib/jvm/*-%s*/bin' % version,
                '/usr/local/j2sdk%s*/bin' % version,
            ]
            java_path = self.paths(patterns) + [env['ENV']['PATH']]
        else:
            patterns = [
                '/usr/java/latest/bin',
                '/usr/lib/jvm/*/bin',
                '/usr/local/j2sdk*/bin',
            ]
            java_path = self.paths(patterns) + [env['ENV']['PATH']]

        env['ENV']['PATH'] = string.join(java_path, os.pathsep)
        return env['ENV']

    def java_where_includes(self,version=None):
        """
        Return java include paths compiling java jni code
        """
        import glob
        import sys
        if not version:
            version=''
        jni_dirs = ['/usr/lib/jvm/java-*-sun-%s*/include/jni.h'%version,
                    '/usr/java/jdk%s*/include/jni.h'%version,
                    ]
        dirs = self.paths(jni_dirs)
        if not dirs:
            return None
        d=os.path.dirname(self.paths(jni_dirs)[0])
        result=[d]

        if sys.platform == 'win32':
            result.append(os.path.join(d,'win32'))
        elif sys.platform == 'linux2':
            result.append(os.path.join(d,'linux'))
        return result


    def java_where_java_home(self,version=None):
        import os.path
        jar=self.java_where_jar(version)
        home=os.path.normpath('%s/..'%jar)
        return home

    def java_where_jar(self, version=None):
        ENV = self.java_ENV(version)
        if self.detect_tool('jar', ENV=ENV):
            where_jar = self.detect('JAR', 'jar', ENV=ENV)
        else:
            where_jar = self.where_is('jar', ENV['PATH'])
        if not where_jar:
            self.skip_test("Could not find Java jar, skipping test(s).\n")
        return where_jar

    def java_where_java(self, version=None):
        """
        Return a path to the java executable.
        """
        ENV = self.java_ENV(version)
        where_java = self.where_is('java', ENV['PATH'])
        if not where_java:
            self.skip_test("Could not find Java java, skipping test(s).\n")
        return where_java

    def java_where_javac(self, version=None):
        """
        Return a path to the javac compiler.
        """
        ENV = self.java_ENV(version)
        if self.detect_tool('javac'):
            where_javac = self.detect('JAVAC', 'javac', ENV=ENV)
        else:
            where_javac = self.where_is('javac', ENV['PATH'])
        if not where_javac:
            self.skip_test("Could not find Java javac, skipping test(s).\n")
        self.run(program = where_javac,
                 arguments = '-version',
                 stderr=None,
                 status=None)
        if version:
            if string.find(self.stderr(), 'javac %s' % version) == -1:
                fmt = "Could not find javac for Java version %s, skipping test(s).\n"
                self.skip_test(fmt % version)
        else:
            m = re.search(r'javac (\d\.\d)', self.stderr())
            if m:
                version = m.group(1)
            else:
                version = None
        return where_javac, version

    def java_where_javah(self, version=None):
        ENV = self.java_ENV(version)
        if self.detect_tool('javah'):
            where_javah = self.detect('JAVAH', 'javah', ENV=ENV)
        else:
            where_javah = self.where_is('javah', ENV['PATH'])
        if not where_javah:
            self.skip_test("Could not find Java javah, skipping test(s).\n")
        return where_javah

    def java_where_rmic(self, version=None):
        ENV = self.java_ENV(version)
        if self.detect_tool('rmic'):
            where_rmic = self.detect('RMIC', 'rmic', ENV=ENV)
        else:
            where_rmic = self.where_is('rmic', ENV['PATH'])
        if not where_rmic:
            self.skip_test("Could not find Java rmic, skipping non-simulated test(s).\n")
        return where_rmic

    def Qt_dummy_installation(self, dir='qt'):
        # create a dummy qt installation

        self.subdir( dir, [dir, 'bin'], [dir, 'include'], [dir, 'lib'] )

        self.write([dir, 'bin', 'mymoc.py'], """\
import getopt
import sys
import string
import re
cmd_opts, args = getopt.getopt(sys.argv[1:], 'io:', [])
output = None
impl = 0
opt_string = ''
for opt, arg in cmd_opts:
    if opt == '-o': output = open(arg, 'wb')
    elif opt == '-i': impl = 1
    else: opt_string = opt_string + ' ' + opt
for a in args:
    contents = open(a, 'rb').read()
    a = string.replace(a, '\\\\', '\\\\\\\\')
    subst = r'{ my_qt_symbol( "' + a + '\\\\n" ); }'
    if impl:
        contents = re.sub( r'#include.*', '', contents )
    output.write(string.replace(contents, 'Q_OBJECT', subst))
output.close()
sys.exit(0)
""")

        self.write([dir, 'bin', 'myuic.py'], """\
import os.path
import re
import sys
import string
output_arg = 0
impl_arg = 0
impl = None
source = None
for arg in sys.argv[1:]:
    if output_arg:
        output = open(arg, 'wb')
        output_arg = 0
    elif impl_arg:
        impl = arg
        impl_arg = 0
    elif arg == "-o":
        output_arg = 1
    elif arg == "-impl":
        impl_arg = 1
    else:
        if source:
            sys.exit(1)
        source = open(arg, 'rb')
        sourceFile = arg
if impl:
    output.write( '#include "' + impl + '"\\n' )
    includes = re.findall('<include.*?>(.*?)</include>', source.read())
    for incFile in includes:
        # this is valid for ui.h files, at least
        if os.path.exists(incFile):
            output.write('#include "' + incFile + '"\\n')
else:
    output.write( '#include "my_qobject.h"\\n' + source.read() + " Q_OBJECT \\n" )
output.close()
sys.exit(0)
""" )

        self.write([dir, 'include', 'my_qobject.h'], r"""
#define Q_OBJECT ;
void my_qt_symbol(const char *arg);
""")

        self.write([dir, 'lib', 'my_qobject.cpp'], r"""
#include "../include/my_qobject.h"
#include <stdio.h>
void my_qt_symbol(const char *arg) {
  printf( arg );
}
""")

        self.write([dir, 'lib', 'SConstruct'], r"""
env = Environment()
import sys
if sys.platform == 'win32':
    env.StaticLibrary( 'myqt', 'my_qobject.cpp' )
else:
    env.SharedLibrary( 'myqt', 'my_qobject.cpp' )
""")

        self.run(chdir = self.workpath(dir, 'lib'),
                 arguments = '.',
                 stderr = noisy_ar,
                 match = self.match_re_dotall)

        self.QT = self.workpath(dir)
        self.QT_LIB = 'myqt'
        self.QT_MOC = '%s %s' % (_python_, self.workpath(dir, 'bin', 'mymoc.py'))
        self.QT_UIC = '%s %s' % (_python_, self.workpath(dir, 'bin', 'myuic.py'))
        self.QT_LIB_DIR = self.workpath(dir, 'lib')

    def Qt_create_SConstruct(self, place):
        if type(place) is type([]):
            place = apply(test.workpath, place)
        self.write(place, """\
if ARGUMENTS.get('noqtdir', 0): QTDIR=None
else: QTDIR=r'%s'
env = Environment(QTDIR = QTDIR,
                  QT_LIB = r'%s',
                  QT_MOC = r'%s',
                  QT_UIC = r'%s',
                  tools=['default','qt'])
dup = 1
if ARGUMENTS.get('variant_dir', 0):
    if ARGUMENTS.get('chdir', 0):
        SConscriptChdir(1)
    else:
        SConscriptChdir(0)
    dup=int(ARGUMENTS.get('dup', 1))
    if dup == 0:
        builddir = 'build_dup0'
        env['QT_DEBUG'] = 1
    else:
        builddir = 'build'
    VariantDir(builddir, '.', duplicate=dup)
    print builddir, dup
    sconscript = Dir(builddir).File('SConscript')
else:
    sconscript = File('SConscript')
Export("env dup")
SConscript( sconscript )
""" % (self.QT, self.QT_LIB, self.QT_MOC, self.QT_UIC))

    def msvs_versions(self):
        if not hasattr(self, '_msvs_versions'):

            # Determine the SCons version and the versions of the MSVS
            # environments installed on the test machine.
            #
            # We do this by executing SCons with an SConstruct file
            # (piped on stdin) that spits out Python assignments that
            # we can just exec().  We construct the SCons.__"version"__
            # string in the input here so that the SCons build itself
            # doesn't fill it in when packaging SCons.
            input = """\
import SCons
print "self._scons_version =", repr(SCons.__%s__)
env = Environment();
print "self._msvs_versions =", str(env['MSVS']['VERSIONS'])
""" % 'version'
        
            self.run(arguments = '-n -q -Q -f -', stdin = input)
            exec(self.stdout())

        return self._msvs_versions

    def vcproj_sys_path(self, fname):
        """
        """
        orig = 'sys.path = [ join(sys'

        enginepath = repr(os.path.join(self._cwd, '..', 'engine'))
        replace = 'sys.path = [ %s, join(sys' % enginepath

        contents = self.read(fname)
        contents = string.replace(contents, orig, replace)
        self.write(fname, contents)

    def msvs_substitute(self, input, msvs_ver,
                        subdir=None, sconscript=None,
                        python=sys.executable,
                        project_guid=None):
        if not hasattr(self, '_msvs_versions'):
            self.msvs_versions()

        if subdir:
            workpath = self.workpath(subdir)
        else:
            workpath = self.workpath()

        if sconscript is None:
            sconscript = self.workpath('SConstruct')

        if project_guid is None:
            project_guid = "{E5466E26-0003-F18B-8F8A-BCD76C86388D}"

        if os.environ.has_key('SCONS_LIB_DIR'):
            exec_script_main = "from os.path import join; import sys; sys.path = [ r'%s' ] + sys.path; import SCons.Script; SCons.Script.main()" % os.environ['SCONS_LIB_DIR']
        else:
            exec_script_main = "from os.path import join; import sys; sys.path = [ join(sys.prefix, 'Lib', 'site-packages', 'scons-%s'), join(sys.prefix, 'scons-%s'), join(sys.prefix, 'Lib', 'site-packages', 'scons'), join(sys.prefix, 'scons') ] + sys.path; import SCons.Script; SCons.Script.main()" % (self._scons_version, self._scons_version)
        exec_script_main_xml = string.replace(exec_script_main, "'", "&apos;")

        result = string.replace(input, r'<WORKPATH>', workpath)
        result = string.replace(result, r'<PYTHON>', python)
        result = string.replace(result, r'<SCONSCRIPT>', sconscript)
        result = string.replace(result, r'<SCONS_SCRIPT_MAIN>', exec_script_main)
        result = string.replace(result, r'<SCONS_SCRIPT_MAIN_XML>', exec_script_main_xml)
        result = string.replace(result, r'<PROJECT_GUID>', project_guid)
        return result

    def get_msvs_executable(self, version):
        """Returns a full path to the executable (MSDEV or devenv)
        for the specified version of Visual Studio.
        """
        common_msdev98_bin_msdev_com = ['Common', 'MSDev98', 'Bin', 'MSDEV.COM']
        common7_ide_devenv_com       = ['Common7', 'IDE', 'devenv.com']
        common7_ide_vcexpress_exe    = ['Common7', 'IDE', 'VCExpress.exe']
        sub_paths = {
            '6.0' : [
                common_msdev98_bin_msdev_com,
            ],
            '7.0' : [
                common7_ide_devenv_com,
            ],
            '7.1' : [
                common7_ide_devenv_com,
            ],
            '8.0' : [
                common7_ide_devenv_com,
                common7_ide_vcexpress_exe,
            ],
        }
        from SCons.Tool.msvs import get_msvs_install_dirs
        vs_path = get_msvs_install_dirs(version)['VSINSTALLDIR']
        for sp in sub_paths[version]:
            p = apply(os.path.join, [vs_path] + sp)
            if os.path.exists(p):
                return p
        return apply(os.path.join, [vs_path] + sub_paths[version][0])


    NCR = 0 # non-cached rebuild
    CR  = 1 # cached rebuild (up to date)
    NCF = 2 # non-cached build failure
    CF  = 3 # cached build failure

    if sys.platform == 'win32':
        Configure_lib = 'msvcrt'
    else:
        Configure_lib = 'm'

    # to use cygwin compilers on cmd.exe -> uncomment following line
    #Configure_lib = 'm'

    def checkLogAndStdout(self, checks, results, cached,
                          logfile, sconf_dir, sconstruct,
                          doCheckLog=1, doCheckStdout=1):

        class NoMatch:
            def __init__(self, p):
                self.pos = p

        def matchPart(log, logfile, lastEnd, NoMatch=NoMatch):
            m = re.match(log, logfile[lastEnd:])
            if not m:
                raise NoMatch, lastEnd
            return m.end() + lastEnd
        try:
            #print len(os.linesep)
            ls = os.linesep
            nols = "("
            for i in range(len(ls)):
                nols = nols + "("
                for j in range(i):
                    nols = nols + ls[j]
                nols = nols + "[^" + ls[i] + "])"
                if i < len(ls)-1:
                    nols = nols + "|"
            nols = nols + ")"
            lastEnd = 0
            logfile = self.read(self.workpath(logfile))
            if (doCheckLog and
                string.find( logfile, "scons: warning: The stored build "
                             "information has an unexpected class." ) >= 0):
                self.fail_test()
            sconf_dir = sconf_dir
            sconstruct = sconstruct

            log = r'file\ \S*%s\,line \d+:' % re.escape(sconstruct) + ls
            if doCheckLog: lastEnd = matchPart(log, logfile, lastEnd)
            log = "\t" + re.escape("Configure(confdir = %s)" % sconf_dir) + ls
            if doCheckLog: lastEnd = matchPart(log, logfile, lastEnd)
            rdstr = ""
            cnt = 0
            for check,result,cache_desc in zip(checks, results, cached):
                log   = re.escape("scons: Configure: " + check) + ls
                if doCheckLog: lastEnd = matchPart(log, logfile, lastEnd)
                log = ""
                result_cached = 1
                for bld_desc in cache_desc: # each TryXXX
                    for ext, flag in bld_desc: # each file in TryBuild
                        file = os.path.join(sconf_dir,"conftest_%d%s" % (cnt, ext))
                        if flag == self.NCR:
                            # rebuild will pass
                            if ext in ['.c', '.cpp']:
                                log=log + re.escape(file + " <-") + ls
                                log=log + r"(  \|" + nols + "*" + ls + ")+?"
                            else:
                                log=log + "(" + nols + "*" + ls +")*?"
                            result_cached = 0
                        if flag == self.CR:
                            # up to date
                            log=log + \
                                 re.escape("scons: Configure: \"%s\" is up to date." 
                                           % file) + ls
                            log=log+re.escape("scons: Configure: The original builder "
                                              "output was:") + ls
                            log=log+r"(  \|.*"+ls+")+"
                        if flag == self.NCF:
                            # non-cached rebuild failure
                            log=log + "(" + nols + "*" + ls + ")*?"
                            result_cached = 0
                        if flag == self.CF:
                            # cached rebuild failure
                            log=log + \
                                 re.escape("scons: Configure: Building \"%s\" failed "
                                           "in a previous run and all its sources are"
                                           " up to date." % file) + ls
                            log=log+re.escape("scons: Configure: The original builder "
                                              "output was:") + ls
                            log=log+r"(  \|.*"+ls+")+"
                    cnt = cnt + 1
                if result_cached:
                    result = "(cached) " + result
                rdstr = rdstr + re.escape(check) + re.escape(result) + "\n"
                log=log + re.escape("scons: Configure: " + result) + ls + ls
                if doCheckLog: lastEnd = matchPart(log, logfile, lastEnd)
                log = ""
            if doCheckLog: lastEnd = matchPart(ls, logfile, lastEnd)
            if doCheckLog and lastEnd != len(logfile):
                raise NoMatch, lastEnd
            
        except NoMatch, m:
            print "Cannot match log file against log regexp."
            print "log file: "
            print "------------------------------------------------------"
            print logfile[m.pos:]
            print "------------------------------------------------------"
            print "log regexp: "
            print "------------------------------------------------------"
            print log
            print "------------------------------------------------------"
            self.fail_test()

        if doCheckStdout:
            exp_stdout = self.wrap_stdout(".*", rdstr)
            if not self.match_re_dotall(self.stdout(), exp_stdout):
                print "Unexpected stdout: "
                print "-----------------------------------------------------"
                print repr(self.stdout())
                print "-----------------------------------------------------"
                print repr(exp_stdout)
                print "-----------------------------------------------------"
                self.fail_test()

    def get_python_version(self):
        """
        Returns the Python version (just so everyone doesn't have to
        hand-code slicing the right number of characters).
        """
        # see also sys.prefix documentation
        return python_minor_version_string()

    def get_platform_python(self):
        """
        Returns a path to a Python executable suitable for testing on
        this platform.

        Mac OS X has no static libpython for SWIG to link against,
        so we have to link against Apple's framwork version.  However,
        testing must use the executable version that corresponds to the
        framework we link against, or else we get interpreter errors.
        """
        if sys.platform == 'darwin':
            return '/System/Library/Frameworks/Python.framework/Versions/Current/bin/python'
        else:
            global python
            return python

    def get_quoted_platform_python(self):
        """
        Returns a quoted path to a Python executable suitable for testing on
        this platform.

        Mac OS X has no static libpython for SWIG to link against,
        so we have to link against Apple's framwork version.  However,
        testing must use the executable version that corresponds to the
        framework we link against, or else we get interpreter errors.
        """
        if sys.platform == 'darwin':
            return '"' + self.get_platform_python() + '"'
        else:
            global _python_
            return _python_

    def get_platform_sys_prefix(self):
        """
        Returns a "sys.prefix" value suitable for linking on this platform.

        Mac OS X has a built-in Python but no static libpython,
        so we must link to it using Apple's 'framework' scheme.
        """
        if sys.platform == 'darwin':
            fmt = '/System/Library/Frameworks/Python.framework/Versions/%s/'
            return fmt % self.get_python_version()
        else:
            return sys.prefix

    def get_python_frameworks_flags(self):
        """
        Returns a FRAMEWORKSFLAGS value for linking with Python.

        Mac OS X has a built-in Python but no static libpython,
        so we must link to it using Apple's 'framework' scheme.
        """
        if sys.platform == 'darwin':
            return '-framework Python'
        else:
            return ''

    def get_python_inc(self):
        """
        Returns a path to the Python include directory.
        """
        try:
            import distutils.sysconfig
        except ImportError:
            return os.path.join(self.get_platform_sys_prefix(),
                                'include',
                                'python' + self.get_python_version())
        else:
            return distutils.sysconfig.get_python_inc()

    def wait_for(self, fname, timeout=10.0, popen=None):
        """
        Waits for the specified file name to exist.
        """
        waited = 0.0
        while not os.path.exists(fname):
            if timeout and waited >= timeout:
                sys.stderr.write('timed out waiting for %s to exist\n' % fname)
                if popen:
                    popen.stdin.close()
                    self.status = 1
                    self.finish(popen)
                self.fail_test()
            time.sleep(1.0)
            waited = waited + 1.0

    def get_alt_cpp_suffix(self):
        """
        Many CXX tests have this same logic.
        They all needed to determine if the current os supports
        files with .C and .c as different files or not
        in which case they are instructed to use .cpp instead of .C
        """
        if not case_sensitive_suffixes('.c','.C'):
            alt_cpp_suffix = '.cpp'
        else:
            alt_cpp_suffix = '.C'
        return alt_cpp_suffix
    

# In some environments, $AR will generate a warning message to stderr
# if the library doesn't previously exist and is being created.  One
# way to fix this is to tell AR to be quiet (sometimes the 'c' flag),
# but this is difficult to do in a platform-/implementation-specific
# method.  Instead, we will use the following as a stderr match for
# tests that use AR so that we will view zero or more "ar: creating
# <file>" messages to be successful executions of the test (see
# test/AR.py for sample usage).

noisy_ar=r'(ar: creating( archive)? \S+\n?)*'
