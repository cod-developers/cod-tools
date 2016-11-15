MAIN_MAKE = Makefile

all: ${MAIN_MAKE}
	@${MAKE} --file ${MAIN_MAKE} $@

${MAIN_MAKE}:
	CFLAGS=-fPIC ./configure
	touch config.h.in

%:
	@${MAKE} --file ${MAIN_MAKE} $@
	
cleanAll: distclean
