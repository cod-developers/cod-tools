
PROGRAM_DIR   = programs
CCTBX_SRC_DIR = cctbx_sources
OBJ_DIR       = .obj

LIB_C_FILES   = $(shell find ${CCTBX_SRC_DIR} -name '*.cpp')
LIB_OBJ_NAMES = ${notdir ${LIB_C_FILES:%.cpp=%.o}}
LIB_OBJ_DIRS  = ${notdir ${patsubst %/,%,${dir ${LIB_C_FILES}}}}
LIB_OBJ_FILES = ${addprefix ${OBJ_DIR}/, \
	${join ${LIB_OBJ_DIRS}, ${addprefix /,${LIB_OBJ_NAMES}}}}

PWD      = ${shell pwd}
LIBNAME  = ${notdir ${PWD}}
LIB      = lib${LIBNAME}.a

CFILES   = ${wildcard *.c}
CPPFILES = ${wildcard *.cpp}
OFILES   = ${CFILES:%.c=%.o} ${CPPFILES:%.cpp=%.o}
PRGFILES = ${wildcard ${PROGRAM_DIR}/*.c}  ${wildcard ${PROGRAM_DIR}/*.cpp}
EFILES   = ${patsubst ${PROGRAM_DIR}/%.cpp,%,${PRGFILES:${PROGRAM_DIR}/%.c=%}}

VPATH = ${dir ${patsubst %/,%,${dir ${LIB_C_FILES}}}}

.PHONY: all clean distclean cleanAll static test

.PRECIOUS: %.o ${OBJ_DIR}/%.o %.a

all: ${LIB} ${EFILES}

test: ${EFILES}
	set -x; for i in $^; do ./$$i; done

CFLAGS += -g

CFLAGS += \
-I./cctbx-includes \
-I./cctbx_sources \
-I/usr/include/python2.5 \
-I./cctbx_sources/ccp4io_502_cci/lib/src \
-I./cctbx_sources/tntbx \
-I./cctbx_sources/tntbx/include \
-I./cctbx_sources/clipper \
-I${CCP4}/include \
-I${CCP4}/include/ccp4 \
-I${CCP4}/include/mmdb

EXTRA_INCLUDES = \
-I./cctbx_sources/cctbx/include/cctbx

static:
	${MAKE} CFLAGS=-static

%.o: %.c
	${CC} -c ${CFLAGS} -o $@ $<

%.o: %.cpp
	${CXX} -c ${CFLAGS} -o $@ $<

${OBJ_DIR}/%.o: %.cpp
	@mkdir -p ${dir $@}
	${CXX} -c ${CFLAGS} -o $@ $<

%.a: ${LIB_OBJ_FILES}
	${AR} cr $@ $^

%: ${PROGRAM_DIR}/%.c ${OFILES} ${LIB}
	${CXX} ${CFLAGS} ${EXTRA_INCLUDES} -L. $^ -o $@ -l${LIBNAME}

%: ${PROGRAM_DIR}/%.cpp ${OFILES} ${LIB}
	${CXX} ${CFLAGS} ${EXTRA_INCLUDES} -L. $^ -o $@ -l${LIBNAME}

clean:
	rm -f ${OFILES}

distclean cleanAll: clean
	rm -f ${LIB_OBJ_FILES}
	rm -f ${EFILES}
	rm -f ${LIB}
