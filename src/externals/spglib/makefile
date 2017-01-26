MAIN_MAKE = Makefile

all: ${MAIN_MAKE}
	@${MAKE} --file ${MAIN_MAKE} $@

${MAIN_MAKE}:
	touch configure.ac
	touch aclocal.m4
	touch config.h.in
	touch Makefile.am
	touch configure
	touch Makefile.in
	CFLAGS=-fPIC ./configure

%:
	@${MAKE} --file ${MAIN_MAKE} $@
	
cleanAll: distclean
