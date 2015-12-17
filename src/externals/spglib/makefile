MAIN_MAKE = Makefile

all: ${MAIN_MAKE}
	@${MAKE} --file ${MAIN_MAKE} $@

${MAIN_MAKE}:
	./configure

%:
	@${MAKE} --file ${MAIN_MAKE} $@
	
cleanAll: distclean
