MAKEFILE = Makefile

all: ${MAKEFILE}
	${MAKE} -f ${MAKEFILE} all

%: ${MAKEFILE}
	${MAKE} -f ${MAKEFILE} $@

${MAKEFILE}:
	perl Makefile.PL
