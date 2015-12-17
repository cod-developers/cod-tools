MAIN_MAKE = Makefile

all: ${MAIN_MAKE}
	@${MAKE} --file ${MAIN_MAKE} $@

${MAIN_MAKE}:
	./configure
	touch aclocal.m4 Makefile.in

%:
	@${MAKE} --file ${MAIN_MAKE} $@
	
cleanAll: distclean
