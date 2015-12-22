MAIN_MAKE = Makefile

all: ${MAIN_MAKE}
	@${MAKE} --file ${MAIN_MAKE} $@

${MAIN_MAKE}:
	CFLAGS=-fPIC ./configure
	touch aclocal.m4 Makefile.in configure

%:
	@${MAKE} --file ${MAIN_MAKE} $@
	
cleanAll: distclean
