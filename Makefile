PKGNAME = cod-tools
AUTHOR_NAME  = Saulius Gražulis
AUTHOR_EMAIL = grazulis@ibt.lt
REVISION  = $(shell svnversion)
DATE      = $(shell date --rfc-2822)

PREFIX = /usr/local

DEBIAN    = debian
CHANGELOG = ${DEBIAN}/changelog
CONTROL   = ${DEBIAN}/control
COPYRIGHT = ${DEBIAN}/copyright

# Taking the dependencies from {build,run}.sh:

BUILD_DEPS_LIST = dependencies/Ubuntu-12.04/build.sh
RUN_DEPS_LIST   = dependencies/Ubuntu-12.04/run.sh

BUILD_DEPS = $(shell grep install ${BUILD_DEPS_LIST} \
                 | awk '{print $$NF}' \
                 | xargs perl -e 'print join ", ", ( "debhelper (>=9)", @ARGV )')
RUN_DEPS = $(shell grep install ${RUN_DEPS_LIST} \
                 | awk '{print $$NF}' \
                 | xargs perl -e 'print join ", ", @ARGV')

# Collecting Perl binaries and libraries:

C_BINS     = $(shell find CIFParser-c/ -maxdepth 1 -type f -a -executable)
PERL5_BINS = $(shell find perl-scripts/ -maxdepth 1 -type f -a -executable)
PERL5_LIBS = $(shell find . -name .svn -prune \
                 -o -name COD -prune \
                 -o -name STAR -prune \
                 -o -name Formulae -prune \
                 -o -name \*.pm -print)
COD_LIBS   = $(shell find lib/perl5/COD -name .svn -prune -o -name \*.pm -print)
STAR_LIBS  = $(shell find lib/perl5/STAR -name .svn -prune -o -name \*.pm -print)
DATA_LIBS  = $(shell find CIFData -name .svn -prune -o -name \*.pm -print)
TAGS_LIBS  = $(shell find CIFTags -name .svn -prune -o -name \*.pm -print)
SG_LIBS    = $(shell find Spacegroups -name .svn -prune -o -name \*.pm -print)
FRML_LIBS  = $(shell find Formulae -name .svn -prune -o -name \*.pm -print)

REL_INLINE_DIR     = lib/cod-tools
REL_INLINE_LIB_DIR = ${REL_INLINE_DIR}/lib/auto/CCIFParser
INLINE_FILES = $(shell find ${REL_INLINE_DIR} -name .svn -prune -o -type f -print)

# Listing the paths to be installed

BIN_DIR       = ${PREFIX}/bin
LIB_DIR       = ${PREFIX}/lib
PERL5_LIB_DIR = ${LIB_DIR}/perl5
COD_LIB_DIR   = ${PERL5_LIB_DIR}/COD
STAR_LIB_DIR  = ${PERL5_LIB_DIR}/STAR
DATA_LIB_DIR  = ${PERL5_LIB_DIR}/CIFData
TAGS_LIB_DIR  = ${PERL5_LIB_DIR}/CIFTags
SG_LIB_DIR    = ${PERL5_LIB_DIR}/Spacegroups
FRML_LIB_DIR  = ${PERL5_LIB_DIR}/Formulae

INLINE_DIR     = ${PREFIX}/${REL_INLINE_DIR}
INLINE_LIB_DIR = ${PREFIX}/${REL_INLINE_LIB_DIR}

INSTALLED_DIRS = ${BIN_DIR} ${PERL5_LIB_DIR} ${COD_LIB_DIR} \
                 ${STAR_LIB_DIR} ${DATA_LIB_DIR} ${TAGS_LIB_DIR} \
                 ${SG_LIB_DIR} ${FRML_LIB_DIR} ${INLINE_DIR} \
                 ${INLINE_LIB_DIR}

define newline


endef

define changelog_body
${PKGNAME} (${REVISION}-1) UNRELEASED; urgency=low

  * Initial release. (Closes: #XXXXXX)

 -- ${AUTHOR_NAME} <${AUTHOR_EMAIL}>  ${DATE}
endef

define control_body
Source: ${PKGNAME}
Maintainer: ${AUTHOR_NAME} <${AUTHOR_EMAIL}>
Section: misc
Priority: optional
Standards-Version: 3.9.3
Build-Depends: ${BUILD_DEPS}

Package: ${PKGNAME}
Architecture: any
Depends: ${RUN_DEPS}
Description: tools for Crystallography Open Database
 CIF management tools
endef

${CHANGELOG}:
	echo '$(subst $(newline),\n,${changelog_body})' > $@

${CONTROL}:
	echo '$(subst $(newline),\n,${control_body})' > $@

${COPYRIGHT}:
	cat README-COPYING COPYING > $@

all build:
	$(MAKE) -C perl-scripts
	$(MAKE) -C CIFParser
	$(MAKE) -C CIFParser-c

deb: build ${CHANGELOG} ${CONTROL} ${COPYRIGHT}
	fakeroot debian/rules binary

install: build installdirs
	install ${C_BINS} ${PERL5_BINS} ${BIN_DIR}
	install --mode 644 ${PERL5_LIBS} ${PERL5_LIB_DIR}
	install --mode 644 ${COD_LIBS} ${COD_LIB_DIR}
	install --mode 644 ${STAR_LIBS} ${STAR_LIB_DIR}
	install --mode 644 ${DATA_LIBS} ${DATA_LIB_DIR}
	install --mode 644 ${TAGS_LIBS} ${TAGS_LIB_DIR}
	install --mode 644 ${SG_LIBS} ${SG_LIB_DIR}
	install --mode 644 ${FRML_LIBS} ${FRML_LIB_DIR}
	install --mode 644 ${REL_INLINE_LIB_DIR}/CCIFParser.bs \
	                   ${REL_INLINE_LIB_DIR}/CCIFParser.so \
	                   ${REL_INLINE_LIB_DIR}/CCIFParser.inl \
	                   ${INLINE_LIB_DIR}
	install --mode 644 ${REL_INLINE_DIR}/config-* ${INLINE_DIR}

installdirs:
	for i in ${INSTALLED_DIRS}; \
	do \
	    test -d $$i || mkdir -p $$i; \
	done

testinstall:
	$(MAKE) -C perl-scripts tests TEST_INSTALL=1
