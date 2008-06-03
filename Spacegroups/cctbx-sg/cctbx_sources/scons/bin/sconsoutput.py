#!/usr/bin/env python2

#
# Copyright (c) 2003 Steven Knight
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
# KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

__revision__ = "/home/scons/sconsoutput/branch.0/baseline/src/sconsoutput.py 0.4.D001 2004/11/27 18:44:37 knight"

#
# sconsoutput.py -   an SGML preprocessor for capturing SCons output
#                    and inserting it into examples in our DocBook
#                    documentation
#
# This script looks for some SGML tags that describe SCons example
# configurations and commands to execute in those configurations, and
# uses TestCmd.py to execute the commands and insert the output from
# those commands into the SGML that we output.  This way, we can run a
# script and update all of our example documentation output without
# a lot of laborious by-hand checking.
#
# An "SCons example" looks like this, and essentially describes a set of
# input files (program source files as well as SConscript files):
#
#       <scons_example name="ex1">
#         <file name="SConstruct" printme="1">
#           env = Environment()
#           env.Program('foo')
#         </file>
#         <file name="foo.c">
#           int main() { printf("foo.c\n"); }
#         </file>
#       </scons_example>
#
# The <file> contents within the <scons_example> tag will get written
# into a temporary directory whenever example output needs to be
# generated.  By default, the <file> contents are not inserted into text
# directly, unless you set the "printme" attribute on one or more files,
# in which case they will get inserted within a <programlisting> tag.
# This makes it easy to define the example at the appropriate
# point in the text where you intend to show the SConstruct file.
#
# Note that you should usually give the <scons_example> a "name"
# attribute so that you can refer to the example configuration later to
# run SCons and generate output.
#
# If you just want to show a file's contents without worry about running
# SCons, there's a shorter <sconstruct> tag:
#
#       <sconstruct>
#         env = Environment()
#         env.Program('foo')
#       </sconstruct>
#
# This is essentially equivalent to <scons_example><file printme="1">,
# but it's more straightforward.
#
# SCons output is generated from the following sort of tag:
#
#       <scons_output example="ex1" os="posix">
#         <scons_output_command>scons -Q foo</scons_output_command>
#         <scons_output_command>scons -Q foo</scons_output_command>
#       </scons_output>
#
# You tell it which example to use with the "example" attribute, and then
# give it a list of <scons_output_command> tags to execute.  You can also
# supply an "os" tag, which specifies the type of operating system this
# example is intended to show; if you omit this, default value is "posix".
#
# The generated SGML will show the command line (with the appropriate
# command-line prompt for the operating system), execute the command in
# a temporary directory with the example files, capture the standard
# output from SCons, and insert it into the text as appropriate.
# Error output gets passed through to your error output so you
# can see if there are any problems executing the command.
#

import os
import os.path
import re
import sgmllib
import string
import sys
import time

sys.path.append(os.path.join(os.getcwd(), 'QMTest'))
sys.path.append(os.path.join(os.getcwd(), 'build', 'QMTest'))

scons_py = os.path.join('bootstrap', 'src', 'script', 'scons.py')
if not os.path.exists(scons_py):
    scons_py = os.path.join('src', 'script', 'scons.py')

scons_lib_dir = os.path.join(os.getcwd(), 'bootstrap', 'src', 'engine')
if not os.path.exists(scons_lib_dir):
    scons_lib_dir = os.path.join(os.getcwd(), 'src', 'engine')

os.environ['SCONS_LIB_DIR'] = scons_lib_dir

import TestCmd

# The regular expression that identifies entity references in the
# standard sgmllib omits the underscore from the legal characters.
# Override it with our own regular expression that adds underscore.
sgmllib.entityref = re.compile('&([a-zA-Z][-_.a-zA-Z0-9]*)[^-_a-zA-Z0-9]')

# Classes for collecting different types of data we're interested in.
class DataCollector:
    """Generic class for collecting data between a start tag and end
    tag.  We subclass for various types of tags we care about."""
    def __init__(self):
        self.data = ""
    def afunc(self, data):
        self.data = self.data + data

class Example(DataCollector):
    """An SCons example.  This is essentially a list of files that
    will get written to a temporary directory to collect output
    from one or more SCons runs."""
    def __init__(self):
        DataCollector.__init__(self)
        self.files = []
        self.dirs = []

class File(DataCollector):
    """A file, that will get written out to a temporary directory
    for one or more SCons runs."""
    def __init__(self, name):
        DataCollector.__init__(self)
        self.name = name

class Directory(DataCollector):
    """A directory, that will get created in a temporary directory
    for one or more SCons runs."""
    def __init__(self, name):
        DataCollector.__init__(self)
        self.name = name

class Output(DataCollector):
    """Where the command output goes.  This is essentially
    a list of commands that will get executed."""
    def __init__(self):
        DataCollector.__init__(self)
        self.commandlist = []

class Command(DataCollector):
    """A tag for where the command output goes.  This is essentially
    a list of commands that will get executed."""
    def __init__(self):
        DataCollector.__init__(self)
        self.output = None

Prompt = {
    'posix' : '% ',
    'win32' : 'C:\\>'
}

# The magick SCons hackery that makes this work.
#
# So that our examples can still use the default SConstruct file, we
# actually feed the following into SCons via stdin and then have it
# SConscript() the SConstruct file.  This stdin wrapper creates a set
# of ToolSurrogates for the tools for the appropriate platform.  These
# Surrogates print output like the real tools and behave like them
# without actually having to be on the right platform or have the right
# tool installed.
#
# The upshot:  The wrapper transparently changes the world out from
# under the top-level SConstruct file in an example just so we can get
# the command output.

Stdin = """\
import os
import re
import string
import SCons.Action
import SCons.Defaults
import SCons.Node.FS

platform = '%(osname)s'

Sep = {
    'posix' : '/',
    'win32' : '\\\\',
}[platform]


#  Slip our own __str__() method into the EntryProxy class used to expand
#  $TARGET{S} and $SOURCE{S} to translate the path-name separators from
#  what's appropriate for the system we're running on to what's appropriate
#  for the example system.
orig = SCons.Node.FS.EntryProxy
class MyEntryProxy(orig):
    def __str__(self):
        return string.replace(str(self._Proxy__subject), os.sep, Sep)
SCons.Node.FS.EntryProxy = MyEntryProxy

# Slip our own RDirs() method into the Node.FS.File class so that the
# expansions of $_{CPPINC,F77INC,LIBDIR}FLAGS will have the path-name
# separators translated from what's appropriate for the system we're
# running on to what's appropriate for the example system.
orig_RDirs = SCons.Node.FS.File.RDirs
def my_RDirs(self, pathlist, orig_RDirs=orig_RDirs):
    return map(lambda x: string.replace(str(x), os.sep, Sep),
               orig_RDirs(self, pathlist))
SCons.Node.FS.File.RDirs = my_RDirs

class Curry:
    def __init__(self, fun, *args, **kwargs):
        self.fun = fun
        self.pending = args[:]
        self.kwargs = kwargs.copy()

    def __call__(self, *args, **kwargs):
        if kwargs and self.kwargs:
            kw = self.kwargs.copy()
            kw.update(kwargs)
        else:
            kw = kwargs or self.kwargs

        return apply(self.fun, self.pending + args, kw)

def Str(target, source, env, cmd=""):
    return env.subst(cmd, target=target, source=source)

class ToolSurrogate:
    def __init__(self, tool, variable, func, varlist):
        self.tool = tool
        if not type(variable) is type([]):
            variable = [variable]
        self.variable = variable
        self.func = func
        self.varlist = varlist
    def __call__(self, env):
        t = Tool(self.tool)
        t.generate(env)
        for v in self.variable:
            orig = env[v]
            try:
                strfunction = orig.strfunction
            except AttributeError:
                strfunction = Curry(Str, cmd=orig)
            # Don't call Action() through its global function name, because
            # that leads to infinite recursion in trying to initialize the
            # Default Environment.
            env[v] = SCons.Action.Action(self.func,
                                         strfunction=strfunction,
                                         varlist=self.varlist)
    def __repr__(self):
        # This is for the benefit of printing the 'TOOLS'
        # variable through env.Dump().
        return repr(self.tool)

def Null(target, source, env):
    pass

def Cat(target, source, env):
    target = str(target[0])
    f = open(target, "wb")
    for src in map(str, source):
        f.write(open(src, "rb").read())
    f.close()

def CCCom(target, source, env):
    target = str(target[0])
    fp = open(target, "wb")
    def process(source_file, fp=fp):
        for line in open(source_file, "rb").readlines():
            m = re.match(r'#include\s[<"]([^<"]+)[>"]', line)
            if m:
                include = m.group(1)
                for d in [str(env.Dir('$CPPPATH')), '.']:
                    f = os.path.join(d, include)
                    if os.path.exists(f):
                        process(f)
                        break
            elif line[:11] != "STRIP CCCOM":
                fp.write(line)
    for src in map(str, source):
        process(src)
        fp.write('debug = ' + ARGUMENTS.get('debug', '0') + '\\n')
    fp.close()

public_class_re = re.compile('^public class (\S+)', re.MULTILINE)

def JavaCCom(target, source, env):
    # This is a fake Java compiler that just looks for
    #   public class FooBar
    # lines in the source file(s) and spits those out
    # to .class files named after the class.
    tlist = map(str, target)
    not_copied = {}
    for t in tlist:
       not_copied[t] = 1
    for src in map(str, source):
        contents = open(src, "rb").read()
        classes = public_class_re.findall(contents)
        for c in classes:
            for t in filter(lambda x: string.find(x, c) != -1, tlist):
                open(t, "wb").write(contents)
                del not_copied[t]
    for t in not_copied.keys():
        open(t, "wb").write("\\n")

def JavaHCom(target, source, env):
    tlist = map(str, target)
    slist = map(str, source)
    for t, s in zip(tlist, slist):
        open(t, "wb").write(open(s, "rb").read())

def find_class_files(arg, dirname, names):
    class_files = filter(lambda n: n[-6:] == '.class', names)
    paths = map(lambda n, d=dirname: os.path.join(d, n), class_files)
    arg.extend(paths)

def JarCom(target, source, env):
    target = str(target[0])
    class_files = []
    for src in map(str, source):
        os.path.walk(src, find_class_files, class_files)
    f = open(target, "wb")
    for cf in class_files:
        f.write(open(cf, "rb").read())
    f.close()

# XXX Adding COLOR, COLORS and PACKAGE to the 'cc' varlist(s) by hand
# here is bogus.  It's for the benefit of doc/user/command-line.in, which
# uses examples that want  to rebuild based on changes to these variables.
# It would be better to figure out a way to do it based on the content of
# the generated command-line, or else find a way to let the example markup
# language in doc/user/command-line.in tell this script what variables to
# add, but that's more difficult than I want to figure out how to do right
# now, so let's just use the simple brute force approach for the moment.

ToolList = {
    'posix' :   [('cc', ['CCCOM', 'SHCCCOM'], CCCom, ['CCFLAGS', 'CPPDEFINES', 'COLOR', 'COLORS', 'PACKAGE']),
                 ('link', ['LINKCOM', 'SHLINKCOM'], Cat, []),
                 ('ar', ['ARCOM', 'RANLIBCOM'], Cat, []),
                 ('tar', 'TARCOM', Null, []),
                 ('zip', 'ZIPCOM', Null, []),
                 ('BitKeeper', 'BITKEEPERCOM', Cat, []),
                 ('CVS', 'CVSCOM', Cat, []),
                 ('RCS', 'RCS_COCOM', Cat, []),
                 ('SCCS', 'SCCSCOM', Cat, []),
                 ('javac', 'JAVACCOM', JavaCCom, []),
                 ('javah', 'JAVAHCOM', JavaHCom, []),
                 ('jar', 'JARCOM', JarCom, []),
                 ('rmic', 'RMICCOM', Cat, []),
                ],
    'win32' :   [('msvc', ['CCCOM', 'SHCCCOM'], CCCom, ['CCFLAGS', 'CPPDEFINES', 'COLOR', 'COLORS', 'PACKAGE']),
                 ('mslink', ['LINKCOM', 'SHLINKCOM'], Cat, []),
                 ('mslib', 'ARCOM', Cat, []),
                 ('tar', 'TARCOM', Null, []),
                 ('zip', 'ZIPCOM', Null, []),
                 ('BitKeeper', 'BITKEEPERCOM', Cat, []),
                 ('CVS', 'CVSCOM', Cat, []),
                 ('RCS', 'RCS_COCOM', Cat, []),
                 ('SCCS', 'SCCSCOM', Cat, []),
                 ('javac', 'JAVACCOM', JavaCCom, []),
                 ('javah', 'JAVAHCOM', JavaHCom, []),
                 ('jar', 'JARCOM', JarCom, []),
                 ('rmic', 'RMICCOM', Cat, []),
                ],
}

toollist = ToolList[platform]
filter_tools = string.split('%(tools)s')
if filter_tools:
    toollist = filter(lambda x, ft=filter_tools: x[0] in ft, toollist)

toollist = map(lambda t: apply(ToolSurrogate, t), toollist)

toollist.append('install')

def surrogate_spawn(sh, escape, cmd, args, env):
    pass

def surrogate_pspawn(sh, escape, cmd, args, env, stdout, stderr):
    pass

SCons.Defaults.ConstructionEnvironment.update({
    'PLATFORM' : platform,
    'TOOLS'    : toollist,
    'SPAWN'    : surrogate_spawn,
    'PSPAWN'   : surrogate_pspawn,
})

SConscript('SConstruct')
"""

# "Commands" that we will execute in our examples.
def command_scons(args, c, test, dict):
    save_vals = {}
    delete_keys = []
    try:
        ce = c.environment
    except AttributeError:
        pass
    else:
        for arg in string.split(c.environment):
            key, val = string.split(arg, '=')
            try:
                save_vals[key] = os.environ[key]
            except KeyError:
                delete_keys.append(key)
            os.environ[key] = val
    test.run(interpreter = sys.executable,
             program = scons_py,
             arguments = '-f - ' + string.join(args),
             chdir = test.workpath('WORK'),
             stdin = Stdin % dict)
    os.environ.update(save_vals)
    for key in delete_keys:
        del(os.environ[key])
    out = test.stdout()
    out = string.replace(out, test.workpath('ROOT'), '')
    out = string.replace(out, test.workpath('WORK/SConstruct'),
                              '/home/my/project/SConstruct')
    lines = string.split(out, '\n')
    if lines:
        while lines[-1] == '':
            lines = lines[:-1]
    #err = test.stderr()
    #if err:
    #    sys.stderr.write(err)
    return lines

def command_touch(args, c, test, dict):
    if args[0] == '-t':
        t = int(time.mktime(time.strptime(args[1], '%Y%m%d%H%M')))
        times = (t, t)
        args = args[2:]
    else:
        time.sleep(1)
        times = None
    for file in args:
        if not os.path.isabs(file):
            file = os.path.join(test.workpath('WORK'), file)
        if not os.path.exists(file):
            open(file, 'wb')
        os.utime(file, times)
    return []

def command_edit(args, c, test, dict):
    try:
        add_string = c.edit[:]
    except AttributeError:
        add_string = 'void edit(void) { ; }\n'
    if add_string[-1] != '\n':
        add_string = add_string + '\n'
    for file in args:
        if not os.path.isabs(file):
            file = os.path.join(test.workpath('WORK'), file)
        contents = open(file, 'rb').read()
        open(file, 'wb').write(contents + add_string)
    return []

def command_ls(args, c, test, dict):
    def ls(a):
        files = os.listdir(a)
        files = filter(lambda x: x[0] != '.', files)
        files.sort()
        return [string.join(files, '  ')]
    if args:
        l = []
        for a in args:
            l.extend(ls(test.workpath('WORK', a)))
        return l
    else:
        return ls(test.workpath('WORK'))

CommandDict = {
    'scons' : command_scons,
    'touch' : command_touch,
    'edit'  : command_edit,
    'ls'    : command_ls,
}

def ExecuteCommand(args, c, t, dict):
    try:
        func = CommandDict[args[0]]
    except KeyError:
        func = lambda args, c, t, dict: []
    return func(args[1:], c, t, dict)

class MySGML(sgmllib.SGMLParser):
    """A subclass of the standard Python 2.2 sgmllib SGML parser.

    This extends the standard sgmllib parser to recognize, and do cool
    stuff with, the added tags that describe our SCons examples,
    commands, and other stuff.

    Note that this doesn't work with the 1.5.2 sgmllib module, because
    that didn't have the ability to work with ENTITY declarations.
    """
    def __init__(self):
        sgmllib.SGMLParser.__init__(self)
        self.examples = {}
        self.afunclist = []

    # The first set of methods here essentially implement pass-through
    # handling of most of the stuff in an SGML file.  We're really
    # only concerned with the tags specific to SCons example processing,
    # the methods for which get defined below.

    def handle_data(self, data):
        try:
            f = self.afunclist[-1]
        except IndexError:
            sys.stdout.write(data)
        else:
            f(data)

    def handle_comment(self, data):
        sys.stdout.write('<!--' + data + '-->')

    def handle_decl(self, data):
        sys.stdout.write('<!' + data + '>')

    def unknown_starttag(self, tag, attrs):
        try:
            f = self.example.afunc
        except AttributeError:
            f = sys.stdout.write
        if not attrs:
            f('<' + tag + '>')
        else:
            f('<' + tag)
            for name, value in attrs:
                f(' ' + name + '=' + '"' + value + '"')
            f('>')

    def unknown_endtag(self, tag):
        sys.stdout.write('</' + tag + '>')

    def unknown_entityref(self, ref):
        sys.stdout.write('&' + ref + ';')

    def unknown_charref(self, ref):
        sys.stdout.write('&#' + ref + ';')

    # Here is where the heavy lifting begins.  The following methods
    # handle the begin-end tags of our SCons examples.

    def start_scons_example(self, attrs):
        t = filter(lambda t: t[0] == 'name', attrs)
        if t:
            name = t[0][1]
            try:
               e = self.examples[name]
            except KeyError:
               e = self.examples[name] = Example()
        else:
            e = Example()
        for name, value in attrs:
            setattr(e, name, value)
        self.e = e
        self.afunclist.append(e.afunc)

    def end_scons_example(self):
        e = self.e
        files = filter(lambda f: f.printme, e.files)
        if files:
            sys.stdout.write('<programlisting>')
            for f in files:
                if f.printme:
                    i = len(f.data) - 1
                    while f.data[i] == ' ':
                        i = i - 1
                    output = string.replace(f.data[:i+1], '__ROOT__', '')
                    output = string.replace(output, '<', '&lt;')
                    output = string.replace(output, '>', '&gt;')
                    sys.stdout.write(output)
            if e.data and e.data[0] == '\n':
                e.data = e.data[1:]
            sys.stdout.write(e.data + '</programlisting>')
        delattr(self, 'e')
        self.afunclist = self.afunclist[:-1]

    def start_file(self, attrs):
        try:
            e = self.e
        except AttributeError:
            self.error("<file> tag outside of <scons_example>")
        t = filter(lambda t: t[0] == 'name', attrs)
        if not t:
            self.error("no <file> name attribute found")
        try:
            e.prefix
        except AttributeError:
            e.prefix = e.data
            e.data = ""
        f = File(t[0][1])
        f.printme = None
        for name, value in attrs:
            setattr(f, name, value)
        e.files.append(f)
        self.afunclist.append(f.afunc)

    def end_file(self):
        self.e.data = ""
        self.afunclist = self.afunclist[:-1]

    def start_directory(self, attrs):
        try:
            e = self.e
        except AttributeError:
            self.error("<directory> tag outside of <scons_example>")
        t = filter(lambda t: t[0] == 'name', attrs)
        if not t:
            self.error("no <directory> name attribute found")
        try:
            e.prefix
        except AttributeError:
            e.prefix = e.data
            e.data = ""
        d = Directory(t[0][1])
        for name, value in attrs:
            setattr(d, name, value)
        e.dirs.append(d)
        self.afunclist.append(d.afunc)

    def end_directory(self):
        self.e.data = ""
        self.afunclist = self.afunclist[:-1]

    def start_scons_example_file(self, attrs):
        t = filter(lambda t: t[0] == 'example', attrs)
        if not t:
            self.error("no <scons_example_file> example attribute found")
        exname = t[0][1]
        try:
            e = self.examples[exname]
        except KeyError:
            self.error("unknown example name '%s'" % exname)
        fattrs = filter(lambda t: t[0] == 'name', attrs)
        if not fattrs:
            self.error("no <scons_example_file> name attribute found")
        fname = fattrs[0][1]
        f = filter(lambda f, fname=fname: f.name == fname, e.files)
        if not f:
            self.error("example '%s' does not have a file named '%s'" % (exname, fname))
        self.f = f[0]

    def end_scons_example_file(self):
        f = self.f
        sys.stdout.write('<programlisting>')
        sys.stdout.write(f.data + '</programlisting>')
        delattr(self, 'f')

    def start_scons_output(self, attrs):
        t = filter(lambda t: t[0] == 'example', attrs)
        if not t:
            self.error("no <scons_output> example attribute found")
        exname = t[0][1]
        try:
            e = self.examples[exname]
        except KeyError:
            self.error("unknown example name '%s'" % exname)
        # Default values for an example.
        o = Output()
        o.preserve = None
        o.os = 'posix'
        o.tools = ''
        o.e = e
        # Locally-set.
        for name, value in attrs:
            setattr(o, name, value)
        self.o = o
        self.afunclist.append(o.afunc)

    def end_scons_output(self):
        # The real raison d'etre for this script, this is where we
        # actually execute SCons to fetch the output.
        o = self.o
        e = o.e
        t = TestCmd.TestCmd(workdir='', combine=1)
        if o.preserve:
            t.preserve()
        t.subdir('ROOT', 'WORK')
        t.rootpath = string.replace(t.workpath('ROOT'), '\\', '\\\\')

        for d in e.dirs:
            dir = t.workpath('WORK', d.name)
            if not os.path.exists(dir):
                os.makedirs(dir)

        for f in e.files:
            i = 0
            while f.data[i] == '\n':
                i = i + 1
            lines = string.split(f.data[i:], '\n')
            i = 0
            while lines[0][i] == ' ':
                i = i + 1
            lines = map(lambda l, i=i: l[i:], lines)
            path = string.replace(f.name, '__ROOT__', t.rootpath)
            if not os.path.isabs(path):
                path = t.workpath('WORK', path)
            dir, name = os.path.split(path)
            if dir and not os.path.exists(dir):
                os.makedirs(dir)
            content = string.join(lines, '\n')
            content = string.replace(content, '__ROOT__', t.rootpath)
            path = t.workpath('WORK', path)
            t.write(path, content)
            if hasattr(f, 'chmod'):
                os.chmod(path, int(f.chmod, 0))

        i = len(o.prefix)
        while o.prefix[i-1] != '\n':
            i = i - 1

        sys.stdout.write('<screen>' + o.prefix[:i])
        p = o.prefix[i:]

        for c in o.commandlist:
            sys.stdout.write(p + Prompt[o.os])
            d = string.replace(c.data, '__ROOT__', '')
            sys.stdout.write('<userinput>' + d + '</userinput>\n')

            e = string.replace(c.data, '__ROOT__', t.workpath('ROOT'))
            args = string.split(e)
            lines = ExecuteCommand(args, c, t, {'osname':o.os, 'tools':o.tools})
            content = None
            if c.output:
                content = c.output
            elif lines:
                content = string.join(lines, '\n' + p)
            if content:
                content = re.sub(' at 0x[0-9a-fA-F]*\>', ' at 0x700000&gt;', content)
                content = string.replace(content, '<', '&lt;')
                content = string.replace(content, '>', '&gt;')
                sys.stdout.write(p + content + '\n')

        if o.data[0] == '\n':
            o.data = o.data[1:]
        sys.stdout.write(o.data + '</screen>')
        delattr(self, 'o')
        self.afunclist = self.afunclist[:-1]

    def start_scons_output_command(self, attrs):
        try:
            o = self.o
        except AttributeError:
            self.error("<scons_output_command> tag outside of <scons_output>")
        try:
            o.prefix
        except AttributeError:
            o.prefix = o.data
            o.data = ""
        c = Command()
        for name, value in attrs:
            setattr(c, name, value)
        o.commandlist.append(c)
        self.afunclist.append(c.afunc)

    def end_scons_output_command(self):
        self.o.data = ""
        self.afunclist = self.afunclist[:-1]

    def start_sconstruct(self, attrs):
        f = File('')
        self.f = f
        self.afunclist.append(f.afunc)

    def end_sconstruct(self):
        f = self.f
        sys.stdout.write('<programlisting>')
        output = string.replace(f.data, '__ROOT__', '')
        sys.stdout.write(output + '</programlisting>')
        delattr(self, 'f')
        self.afunclist = self.afunclist[:-1]

# The main portion of the program itself, short and simple.
try:
    file = sys.argv[1]
except IndexError:
    file = '-'

if file == '-':
    f = sys.stdin
else:
    try:
        f = open(file, 'r')
    except IOError, msg:
        print file, ":", msg
        sys.exit(1)

data = f.read()
if f is not sys.stdin:
    f.close()

if data.startswith('<?xml '):
    first_line, data = data.split('\n', 1)
    sys.stdout.write(first_line + '\n')

x = MySGML()
for c in data:
    x.feed(c)
x.close()
