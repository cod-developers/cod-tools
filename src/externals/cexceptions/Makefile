#---*- Makefile -*-------------------------------------------------------------
#$Author$
#$Revision$
#$Date$
#$URL$
#------------------------------------------------------------------------------

MAKECONF_FILES = $(sort \
	$(filter-out %.example, $(filter-out %~, $(wildcard Makeconf*))) \
	$(patsubst %.example, %, $(wildcard Makeconf*.example)))

ifneq ("${MAKECONF_FILES}","")
include ${MAKECONF_FILES}
endif

#------------------------------------------------------------------------------
# The following variables, assigned with the '?=' assignment, can be
# overriden in Makeconfig* files:

SO_MAJOR ?= 0
SO_MINOR ?= 01

SO_VERSION ?= ${SO_MAJOR}.${SO_MINOR}

#------------------------------------------------------------------------------

PWD         ?= ${shell pwd}
PACKAGE     ?= ${notdir ${PWD}}
LIBNAME     ?= ${addprefix lib, ${PACKAGE}}

DATE        ?= ${shell date +%Y.%m.%d}
PREFIX      ?= ${HOME}/install/${PACKAGE}/${PACKAGE}-${SO_VERSION}-${DATE}
INCLUDE_DIR ?= ${PREFIX}/include
LIB_DIR     ?= ${PREFIX}/lib

#------------------------------------------------------------------------------

## EXTRA_INC_DIRS = ${HOME}/include
## EXTRA_LIB_DIRS = ${HOME}/lib

EXTRA_INC_DIRS ?= ../cexceptions
EXTRA_LIB_DIRS ?= ../cexceptions/lib

EXTRA_INC_CFLAGS  ?= ${addprefix -I, ${EXTRA_INC_DIRS}}
EXTRA_LIB_LDFLAGS ?= ${addprefix -L, ${EXTRA_LIB_DIRS}}

EXTRA_CFLAGS ?= -DHAS_VSNPRINTF

# End of Makeconfig variables.
#------------------------------------------------------------------------------

OBJ_DIR = obj

LIB_PRG = ${wildcard programs/*.c}
LIB_SRC = ${wildcard *.c}
LIB_OBJ = ${LIB_SRC:%.c=${OBJ_DIR}/%.o}
LIB_DEP = ${LIB_PRG:programs/%.c=programs/.%.d} \
          ${LIB_SRC:%.c=.%.d} 

TEST_PRG = ${wildcard tests/programs/*.c}
TEST_SRC = ${wildcard tests/*.c}
TEST_OBJ = ${TEST_SRC:tests/%.c=${OBJ_DIR}/%.o}
TEST_DEP = ${TEST_PRG:tests/programs/%.c=tests/programs/.%.d} \
           ${TEST_SRC:tests/%.c=tests/.%.d}
TEST_DIF = ${TEST_PRG:tests/programs/%.c=outputs/%.diff}

DEPEND = ${LIB_DEP} ${TEST_DEP}

LIBS  = lib/${LIBNAME}.a lib/${LIBNAME}.so.${SO_VERSION}
PROGS = ${LIB_PRG:programs/%.c=bin/%} \
        ${TEST_PRG:tests/programs/%.c=bin/%}

TARGETS = ${LIBS} ${PROGS}

CFLAGS  = -g -Wall -I. -I./tests ${EXTRA_CFLAGS} ${EXTRA_INC_CFLAGS} -fPIC
LFLAGS  = -lm -lcexceptions
LDFLAGS =  ${EXTRA_LIB_LDFLAGS}

#------------------------------------------------------------------------------

.PHONY: all build install test tests check clean cleanAll distclean

.PRECIOUS: ${OBJ_DIR}/%.o

#------------------------------------------------------------------------------

all: build

build: ${TARGETS}

# The 'Makeconfig' file will be produced automatically if it is absent
# from the 'Makeconfig.example' in the repository, and is ment to be
# edited by hand to suite the local build environment. When the
# 'Makeconfig.example' is changed, the rule below will attempt to
# transfer the changes to the edited 'Makeconfig' file with the help
# of the 'patch' command. It assumes that the 'Makeconfig.example' is
# maintained using Subversion; for other version control systems the
# rule will have to be changed:

Makeconfig: Makeconfig.example
	if [ -f $@ ]; then \
		cp $@ $@~; \
		svn diff -c$$(svnversion|sed 's/[^0-9]//g') $< \
		| patch -p0 $@; \
		touch $@; \
	else \
		cp -v $< $@; \
	fi

MAKELOCAL_FILES = ${filter-out %~, ${wildcard Makelocal*}}

ifneq ("${MAKELOCAL_FILES}","")
include ${MAKELOCAL_FILES}
endif

include ${DEPEND}

#------------------------------------------------------------------------------

${OBJ_DIR}/%.o: %.c
	${CC} ${CFLAGS} -c $< -o $@

${OBJ_DIR}/%.o: tests/%.c
	${CC} ${CFLAGS} -c $< -o $@

bin/%: programs/%.c ${filter %.a, ${LIBS}}
	${CC} ${CFLAGS} ${LDFLAGS} $^ -o $@ ${LFLAGS}

bin/%: tests/programs/%.c ${TEST_OBJ} ${filter %.a, ${LIBS}}
	${CC} ${CFLAGS} ${LDFLAGS} $^ -o $@ ${LFLAGS}

lib/%.a: ${LIB_OBJ}
	${AR} cr $@ $^

lib/%.so.${SO_VERSION}: ${LIB_OBJ}
	${CC} -shared -Xlinker -soname=$*.so.${SO_MAJOR} -o $@ $^

.%.d: %.c
	${CC} ${CFLAGS} -M -MG  $< > $@

#------------------------------------------------------------------------------

check test tests: ${TEST_DIF}

outputs/%.diff: bin/% outputs/%.out
	-@printf "%-30s " "$*:" ; \
	./$< 2>&1 | diff outputs/$*.out - > $@; \
	if [ $$? = 0 ]; then echo "OK"; else echo "FAILED:"; cat $@; fi

.PHONY: listdiff

listdiff:
	@find outputs -name '*.diff' -size +0 \
	| sort -u | xargs --no-run-if-empty ls -l

#------------------------------------------------------------------------------

install: ${LIBS}
	mkdir -p ${INCLUDE_DIR}
	mkdir -p ${LIB_DIR}
	cp *.h ${INCLUDE_DIR}
	cp ${LIBS} ${LIB_DIR}
	ln -fs ${LIBNAME}.so.${SO_VERSION} ${LIB_DIR}/${LIBNAME}.so.${SO_MAJOR}
	ln -fs ${LIBNAME}.so.${SO_MAJOR}   ${LIB_DIR}/${LIBNAME}.so

#------------------------------------------------------------------------------

clean:
	rm -f *~
	rm -f ${LIB_OBJ}
	rm -f ${TEST_OBJ}

distclean cleanAll: clean
	rm -f ${TARGETS}
	rm -f ${DEPEND}
	rm -f ${TEST_DIF}
