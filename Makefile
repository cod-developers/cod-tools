DEBIAN    = debian
CHANGELOG = ${DEBIAN}/changelog
CONTROL   = ${DEBIAN}/control
COPYRIGHT = ${DEBIAN}/copyright
REVISION  = $(shell svnversion)
DATE      = $(shell date --rfc-2822)

DEPENDENCY_LIST = dependencies/Ubuntu-12.04/install.sh
DEPENDENCIES = $(shell grep install ${DEPENDENCY_LIST} \
                 | awk '{print $$NF}' \
                 | xargs perl -e 'print join ", ", ( "debhelper (>=9)", @ARGV )')
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

PKGNAME = cod-tools

AUTHOR_NAME  = Saulius Gražulis
AUTHOR_EMAIL = grazulis@ibt.lt

PREFIX = /usr/local

BIN_DIR       = ${PREFIX}/bin
PERL5_LIB_DIR = ${PREFIX}/lib/perl/5.14.2
COD_LIB_DIR   = ${PERL5_LIB_DIR}/COD
STAR_LIB_DIR  = ${PERL5_LIB_DIR}/STAR
DATA_LIB_DIR  = ${PERL5_LIB_DIR}/CIFData
TAGS_LIB_DIR  = ${PERL5_LIB_DIR}/CIFTags
SG_LIB_DIR    = ${PERL5_LIB_DIR}/Spacegroups
FRML_LIB_DIR  = ${PERL5_LIB_DIR}/Formulae

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
Build-Depends: ${DEPENDENCIES}

Package: ${PKGNAME}
Architecture: any
Depends: ${DEPENDENCIES}
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
	# $(MAKE) -C perl-scripts
	$(MAKE) -C CIFParser
	$(MAKE) -C CIFParser-c

deb: build ${CHANGELOG} ${CONTROL} ${COPYRIGHT}
	fakeroot debian/rules binary

install: build installdirs
	install ${PERL5_BINS} ${BIN_DIR}
	install --mode 644 ${PERL5_LIBS} ${PERL5_LIB_DIR}
	install --mode 644 ${COD_LIBS} ${COD_LIB_DIR}
	install --mode 644 ${STAR_LIBS} ${STAR_LIB_DIR}
	install --mode 644 ${DATA_LIBS} ${DATA_LIB_DIR}
	install --mode 644 ${TAGS_LIBS} ${TAGS_LIB_DIR}
	install --mode 644 ${SG_LIBS} ${SG_LIB_DIR}
	install --mode 644 ${FRML_LIBS} ${FRML_LIB_DIR}

installdirs:
	test -d ${BIN_DIR} || mkdir -p ${BIN_DIR}
	test -d ${PERL5_LIB_DIR} || mkdir -p ${PERL5_LIB_DIR}
	test -d ${COD_LIB_DIR} || mkdir -p ${COD_LIB_DIR}
	test -d ${STAR_LIB_DIR} || mkdir -p ${STAR_LIB_DIR}
	test -d ${DATA_LIB_DIR} || mkdir -p ${DATA_LIB_DIR}
	test -d ${TAGS_LIB_DIR} || mkdir -p ${TAGS_LIB_DIR}
	test -d ${SG_LIB_DIR} || mkdir -p ${SG_LIB_DIR}
	test -d ${FRML_LIB_DIR} || mkdir -p ${FRML_LIB_DIR}

testinstall:
	$(MAKE) -C perl-scripts tests TEST_INSTALL=1
