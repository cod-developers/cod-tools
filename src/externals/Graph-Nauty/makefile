MAKEFILE = Makefile

.PHONY: all check

all: ${MAKEFILE}
	${MAKE} -f ${MAKEFILE} all

check: test
	@true

%: ${MAKEFILE}
	${MAKE} -f ${MAKEFILE} $@

${MAKEFILE}:
	perl Makefile.PL
