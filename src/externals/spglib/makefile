MAIN_MAKE = Makefile

all: ${MAIN_MAKE}
	@${MAKE} --file ${MAIN_MAKE} $@

${MAIN_MAKE}:
	aclocal
	autoheader
	libtoolize
	touch INSTALL NEWS README AUTHORS
	automake -acf
	autoconf
	CFLAGS=-fPIC ./configure

%:
	@${MAKE} --file ${MAIN_MAKE} $@

distclean:
	@${MAKE} --file ${MAIN_MAKE} $@
	rm -rf config.guess config.sub config.h.in configure
	rm -rf AUTHORS NEWS README INSTALL
	rm -rf depcomp compile ltmain.sh autom4te.cache missing aclocal.m4
	rm -rf install-sh m4 Makefile.in src/Makefile.in

cleanAll: distclean
