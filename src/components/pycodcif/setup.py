from os.path import dirname, realpath
from setuptools import setup, Command, Extension
from setuptools.command.build_py import build_py

# svnrevision = '5781'

src_dir = dirname(dirname(dirname(realpath(__file__)))) + '/'

version = None
with open( '.version', 'r' ) as f:
    for line in f:
        if not line.startswith('#'):
            version = line.rstrip('\n')

class build_ext_first(build_py):
    def run(self):
        self.run_command('build_ext')
        return build_py.run(self)

setup(
    name="pycodcif",
    version=version,
    author="COD development team",
    description="COD CIF parser",
    long_description="COD parser for CIF v1.1 and CIF v2.0 formats",
    author_email="grazulis@ibt.lt",
    maintainer="Andrius Merkys",
    maintainer_email="andrius.merkys@gmail.com",
    packages=['pycodcif'],
    package_dir={'pycodcif': '.'},
    url="http://wiki.crystallography.net/cod-tools/CIF-parser",
    license="GPLv2",
    ext_modules=[
        Extension('pycodcif._pycodcif',
                  [src_dir + 'externals/cexceptions/cxprintf.c',
                   src_dir + 'externals/cexceptions/stringx.c',
                   src_dir + 'externals/cexceptions/allocx.c',
                   src_dir + 'externals/cexceptions/stdiox.c',
                   src_dir + 'externals/cexceptions/cexceptions.c',

                   src_dir + 'components/codcif/cif_options.c',
                   src_dir + 'components/codcif/common.c',
                   src_dir + 'components/codcif/ciftable.c',
                   src_dir + 'components/codcif/cif2_lexer.c',
                   src_dir + 'components/codcif/cifvalue.c',
                   src_dir + 'components/codcif/cifmessage.c',
                   src_dir + 'components/codcif/cif_grammar_flex.c',
                   src_dir + 'components/codcif/cif_lexer.c',
                   src_dir + 'components/codcif/cif.c',
                   src_dir + 'components/codcif/datablock.c',
                   src_dir + 'components/codcif/cif_compiler.c',
                   src_dir + 'components/codcif/ciflist.c',
                   src_dir + 'components/codcif/cif_grammar.tab.c',
                   src_dir + 'components/codcif/cif2_grammar.tab.c',

                   'pycodcif.i',
                   'pycodcif.c',
                  ],
                  define_macros=[
                    ('_YACC_',None),
                    ('YYDEBUG','1'),
                    # ('SVN_VERSION',svnrevision),
                  ],
                  include_dirs=[src_dir + 'externals/cexceptions',
                                src_dir + 'components/codcif']),
                ],
    cmdclass={'build_py':build_ext_first},
    # test_suite='nose.collector',
    # tests_require=['nose'],
)
