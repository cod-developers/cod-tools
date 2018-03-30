from setuptools import setup, Command, Extension

version = '2.2'
svnrevision = '5781'

setup(
    name="pycodcif",
    version=version,
    author="COD development team",
    description="COD CIF parser",
    long_description="COD parser for CIF1.1 and CIF2.0 formats",
    author_email="grazulis@ibt.lt",
    maintainer="Andrius Merkys",
    maintainer_email="andrius.merkys@gmail.com",
    packages=['pycodcif'],
    package_dir={'pycodcif': '.'},
    url="http://wiki.crystallography.net/cod-tools/CIF-parser",
    license="GPLv2",
    ext_modules=[
        Extension('pycodcif._pycodcif',
                  ['/home/andrius/src/cod-tools/trunk/src/externals/cexceptions/cxprintf.c',
                   '/home/andrius/src/cod-tools/trunk/src/externals/cexceptions/stringx.c',
                   '/home/andrius/src/cod-tools/trunk/src/externals/cexceptions/allocx.c',
                   '/home/andrius/src/cod-tools/trunk/src/externals/cexceptions/stdiox.c',
                   '/home/andrius/src/cod-tools/trunk/src/externals/cexceptions/cexceptions.c',

                   '/home/andrius/src/cod-tools/trunk/src/components/codcif/cif_options.c',
                   '/home/andrius/src/cod-tools/trunk/src/components/codcif/common.c',
                   '/home/andrius/src/cod-tools/trunk/src/components/codcif/ciftable.c',
                   '/home/andrius/src/cod-tools/trunk/src/components/codcif/cif2_lexer.c',
                   '/home/andrius/src/cod-tools/trunk/src/components/codcif/cifvalue.c',
                   '/home/andrius/src/cod-tools/trunk/src/components/codcif/cifmessage.c',
                   '/home/andrius/src/cod-tools/trunk/src/components/codcif/cif_grammar_flex.c',
                   '/home/andrius/src/cod-tools/trunk/src/components/codcif/cif_lexer.c',
                   '/home/andrius/src/cod-tools/trunk/src/components/codcif/cif.c',
                   '/home/andrius/src/cod-tools/trunk/src/components/codcif/datablock.c',
                   '/home/andrius/src/cod-tools/trunk/src/components/codcif/cif_compiler.c',
                   '/home/andrius/src/cod-tools/trunk/src/components/codcif/ciflist.c',
                   '/home/andrius/src/cod-tools/trunk/src/components/codcif/cif_grammar.tab.c',
                   '/home/andrius/src/cod-tools/trunk/src/components/codcif/cif2_grammar.tab.c',

                   'pycodcif.i',
                   'pycodcif.c',
                   # 'pycodcif_wrap.c'],
                   ],
                  define_macros=[
                    ('_YACC_',None),
                    ('YYDEBUG','1'),
                    ('SVN_VERSION',svnrevision),
                  ],
                  include_dirs=['/home/andrius/src/cod-tools/trunk/src/externals/cexceptions',
                                '/home/andrius/src/cod-tools/trunk/src/components/codcif']),
                ],
    # test_suite='nose.collector',
    # tests_require=['nose'],
)
