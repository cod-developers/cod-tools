from glob import glob
from string import find

# CONFIGURATION TEST SUBROUTINES

def CheckCXX( context, src ):
  context.Message( ' Compile: ' )
  ret = context.TryCompile( src, '.cpp' )
  context.Result( ret )
  return ret

def CheckLNK( context, src ):
  context.Message( ' Link:    ' )
  ret = context.TryLink( src, '.cpp' )
  context.Result( ret )
  return ret


# TEST PROGRAMS

checkfftw = """
#include <fftw.h>
int main(int argc, char **argv) {
  fftw_real *fftwp = 0;
  float *fftp = 0;
  fftw_plan plan;
  fftp = fftwp;
  plan = fftw_create_plan(16, FFTW_FORWARD, 0);
  return 0;
}
"""

checkmmdb = """
#include "mmdb_manager.h"
int main(int argc, char **argv) {
  CMMDBManager mmdb;
  mmdb.ReadPDBASCII( argv[1] );
  return 0;
}
"""

checkcctbx = """
#include "cctbx/miller.h"
int main(int argc, char **argv) {
  cctbx::Miller::Index x;
  return 0;
}
"""

checkccp4 = """
#include "cmtzlib.h"
int main(int argc, char **argv) {
  CMtz::MTZ* mtz;
  mtz = CMtz::MtzGet( "dummy.mtz", 0 );
  return 0;
}
"""

checkmccp4 = """
#include "mmtzlib.h"
int main(int argc, char **argv) {
  mmtz_io::mmtzfile mtz;
  mtz = mmtz_io::mmtz_open( "dummy.mtz", "r" );
  return 0;
}
"""


# ---------- MAIN BUILD SECTION STARTS HERE ----------

# Help info
Help( """
Typical usage:
 scons with-fftw=$PWD/fftw-2.1.5 with-ccp4=$PWD/ccp4

Options:

TARGETS:   (omit to build everything)
 clipper   (builds the libraries)
 install   (installs the libraries and headers)
 examples  (builds the examples)

BUILD DIRECTORIES:
 prefix=PATH
   - define path for final lib/ and include/ directories. Defaults to
   current workign directory.
   e.g. prefix=/usr/local/

DEPENDENCIES:
 with-fftw=PATH
 with-ccp4=PATH   (this also provides mmdb)
 with-mmdb=PATH   (only use this option if you don't have CCP4)
 with-mccp4=PATH
 with-cctbx=PATH
 with-boost=PATH
   - define paths for dependencies
   e.g. with-fftw=/usr/local/fftw

PLATFORMS:
 unix-gcc=[PATH/]gcc (use GNU gcc, with optional compiler path)
 sun-CC=[PATH/]CC    (use Sun CC, with optional compiler path)
 sgi-CC=[PATH/]CC    (use SGI CC, with optional compiler path)
 tru-cxx=[PATH/]cxx  (use Tru64 cxx, with optional compiler path)
   - if no platform is specified, unix-gcc is assumed (may work on
   Windows/MinGW too).

OPTIMISATION:
 opt=FLAGS        (use -g for debug, "-O2 -fno-default-inline" on gcc 3.2)

LIBRARIES:
 objs=[static,shared]
   - default is both

PACKAGES:
 pkglist=PACKAGES
   - define a comma-separated list of packages to be built. If this
   option is not specified, then all packages for which dependencies
   are found will be built. The core package is always built. Possible
   packages include:
   core,contrib,phs,mmdb,minimol,mmdbold,cif,ccp4,mccp4,cctbx
   e.g. packages=core,contrib,phs
""" )

# read command line
prefix    = ARGUMENTS.get( 'prefix', '#' )
withfftw  = ARGUMENTS.get( 'with-fftw',  '-' )
withmmdb  = ARGUMENTS.get( 'with-mmdb',  '-' )
withccp4  = ARGUMENTS.get( 'with-ccp4',  '-' )
withmccp4 = ARGUMENTS.get( 'with-mccp4', '-' )
withcctbx = ARGUMENTS.get( 'with-cctbx', '-' )
withboost = ARGUMENTS.get( 'with-boost', '-' )
ccgcc     = ARGUMENTS.get( 'unix-gcc', '-' )
ccsun     = ARGUMENTS.get( 'sun-CC', '-' )
ccsgi     = ARGUMENTS.get( 'sgi-CC', '-' )
cctru     = ARGUMENTS.get( 'tru-cxx', '-' )
objs      = ARGUMENTS.get( 'objs', 'static,shared' )
opt       = ARGUMENTS.get( 'opt', '-' )
debug     = ARGUMENTS.get( 'debug', '-' )
pkglist   = ARGUMENTS.get( 'packages', '-' )
libvers   = '0.0.0'

# basic environment
env = Environment( CPPPATH = [], LIBPATH = [], LIBS = [ 'rfftw', 'fftw', 'm' ] )
if withfftw != '-':
  env.Append( CPPPATH = [ withfftw + '/include' ] )
  env.Append( LIBPATH = [ withfftw + '/lib' ] )
if withmmdb != '-':
  env.Append( CPPPATH = [ withmmdb + '/src' ] )
  env.Append( LIBPATH = [ withmmdb + '' ] )
if withccp4 != '-':
  env.Append( CPPPATH = [ withccp4 + '/lib/src', withccp4 + '/lib/src/mmdb' ] )
  env.Append( LIBPATH = [ withccp4 + '/lib' ] )
if withmccp4 != '-':
  env.Append( CPPPATH = [ withmccp4 + '/include' ] )
  env.Append( LIBPATH = [ withmccp4 + '/lib' ] )
if withcctbx != '-':
  env.Append( CPPPATH = [ withcctbx + ''  ] )
  env.Append( LIBPATH = [ withcctbx + '/lib' ] )
if withboost != '-':
  env.Append( CPPPATH = [ withboost + ''  ] )
  env.Append( LIBPATH = [ withboost + '/lib' ] )

# platform options
if ccgcc != '-':
  env.Replace( CXX = ccgcc )
  env.Replace( SHLINK = ccgcc )
if ccsun != '-':
  env.Replace( CXX = ccsun )
  env.Replace( SHLINK = ccsun )
  env.Replace( LINK = ccsun )
  env.Replace( ARCOM = ccsun + ' -xar -o $TARGET $SOURCES' )
  env.Replace( SHCXXFLAGS = '-KPIC' )
  env.Append( LINKFLAGS = '-G' )
if ccsgi != '-':
  env.Replace( CXX = ccsgi )
  env.Replace( SHLINK = ccsgi )
  env.Replace( LINK = ccsgi )
  env.Append( CXXFLAGS = [ '-LANG:std', '-ptused' ] )
if cctru != '-':
  env.Replace( CXX = cctru )
  env.Replace( SHLINK = cctru )
  env.Replace( LINK = cctru )
  env.Replace( SHCXXFLAGS = [ '-ieee', '-std', 'strict_ansi', '-alternative_tokens', '-timplicit_local', '-no_implicit_include' ] )
  env.Append( CXXFLAGS = [ '-ieee', '-std', 'strict_ansi', '-alternative_tokens', '-timplicit_local', '-no_implicit_include' ] )

# optimisation options
if opt == '-':
  opt = '-O1'
if debug != '-':
  opt = '-g'
env.Append( CXXFLAGS = opt )

# Dependency checks:
cxx_fftw = cxx_mmdb = cxx_ccp4 = cxx_mccp4 = cxx_cctbx = 1
lnk_fftw = lnk_mmdb = lnk_ccp4 = lnk_mccp4 = lnk_cctbx = 1
if not GetOption( 'clean' ):
  conf = Configure( env, custom_tests = { 'CheckCXX' : CheckCXX,
                                          'CheckLNK' : CheckLNK } )
  print "Checking for fftw:"
  cxx_fftw  = conf.CheckCXX( checkfftw )
  lnk_fftw  = conf.CheckLNK( checkfftw )
  print "Checking for mmdb:"
  cxx_mmdb  = conf.CheckCXX( checkmmdb  )
  if cxx_mmdb:
    env.Append( LIBS = [ 'mmdb' ] )
    lnk_mmdb  = conf.CheckLNK( checkmmdb  )
  print "Checking for ccp4:"
  cxx_ccp4  = conf.CheckCXX( checkccp4  )
  if cxx_ccp4:
    env.Append( LIBS = [ 'ccp4c' ] )
    lnk_ccp4  = conf.CheckLNK( checkccp4  )
  print "Checking for mccp4:"
  cxx_mccp4 = conf.CheckCXX( checkmccp4 )
  if cxx_mccp4:
    env.Append( LIBS = [ 'mccp4' ] )
    lnk_mccp4 = conf.CheckLNK( checkmccp4 )
  print "Checking for cctbx:"
  cxx_cctbx = conf.CheckCXX( checkcctbx )
  if cxx_cctbx:
    env.Append( LIBS = [ 'uctbx', 'sgtbx' ] )
    lnk_cctbx = conf.CheckLNK( checkcctbx )
  env = conf.Finish()
  if not cxx_fftw:
    print 'Need fftw compiled with --enable-float'
    Exit(1)

# default package selection
packages = [ 'core', 'contrib', 'phs' ]
if cxx_mmdb:
  packages = packages + [ 'mmdb', 'minimol', 'mmdbold', 'cif' ]
if cxx_ccp4:
  packages = packages + [ 'ccp4' ]
if cxx_mccp4:
  packages = packages + [ 'mtz' ]
if cxx_cctbx:
  packages = packages + [ 'cctbx' ]
# package selection override
if pkglist != '-':
  packages = pkglist.split(',')

# add clipper libraries to link path
clipperlibs = []
for pkg in packages:
  clipperlibs = [ 'clipper-'+pkg ] + clipperlibs

# install
libdir = prefix+'/lib/'
incdir = prefix+'/include/clipper/'
env.Alias( 'install', [ libdir, incdir ] )
env.Install( incdir, glob( 'clipper/*.h' ) )
for pkg in packages:
  env.Alias( 'install', incdir+pkg )
  env.Install( incdir+pkg, glob( 'clipper/'+pkg+'/*.h' ) )
  if find( objs, 'static' ) >= 0:
    env.InstallAs( libdir+'/libclipper-'+pkg+'.a',
                   'clipper/'+pkg+'/libclipper-'+pkg+'.a' )
  if find( objs, 'shared' ) >= 0:
    env.InstallAs( libdir+'/libclipper-'+pkg+'.so.'+libvers,
                   'clipper/'+pkg+'/libclipper-'+pkg+'.so' )
    env.Command( libdir+'/libclipper-'+pkg+'.so.'+libvers.split('.')[0],
	         libdir+'/libclipper-'+pkg+'.so.'+libvers,
	         'ln -s libclipper-'+pkg+'.so.'+libvers+' $TARGET' )
    env.Command( libdir+'/libclipper-'+pkg+'.so',
	         libdir+'/libclipper-'+pkg+'.so.'+libvers,
	         'ln -s libclipper-'+pkg+'.so.'+libvers+' $TARGET' )

# make examples build options
env_examples = env.Copy()
env_examples.Append( CPPPATH = prefix+'/include' )
env_examples.Append( LIBPATH = prefix+'/lib' )
env_examples.Prepend( LIBS = clipperlibs )

# build libs and examples
Export( 'env' )
Export( 'packages' )
Export( 'objs' )
SConscript( 'clipper/SConstruct' )
Export( 'env_examples' )
SConscript( 'examples/SConstruct' )

# set default build order
Default( [ 'clipper', incdir, libdir, 'examples' ] )

# diagnostics
print '------------------------------------------------------------'
print 'CPPPATH: ', env['CPPPATH']
print 'LIBPATH: ', env['LIBPATH']
print 'LIBS:    ', env['LIBS']
print 'NEWLIBS: ', clipperlibs
print '------------------------------------------------------------'
