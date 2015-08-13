SWIG_SOURCE   = ccifparser.c
SWIG_WRAPPER  = ${SWIG_SOURCE:%.c=%_wrap.c}
SWIG_MODULE	  = ${SWIG_SOURCE:%.c=%.py}
SWIG_INP_FILE = ${SWIG_SOURCE:%.c=%.i}

OBJ 			 = ${SWIG_SOURCE:%.c=%.o}
SWIG_WRAPPER_OBJ = ${SWIG_WRAPPER:%.c=%.o}
SWIG_SO_FILE 	 = ${SWIG_SOURCE:%.c=_%.so}

CIF_PARSER_C_DIR = ../../../../../components/codcif
EXTERNALS_C_DIR  = ../../../../../externals
CEXCEPTIONS_DIR  = ${EXTERNALS_C_DIR}/cexceptions
GETOPTIONS_DIR   = ${EXTERNALS_C_DIR}/getoptions
CIF_PARSER_OBJ_SOURCES  = $(wildcard ${CIF_PARSER_C_DIR}/*.c)
CEXCEPTIONS_OBJ_SOURCES = $(wildcard ${CEXCEPTIONS_DIR}/*.c)
GETOPTIONS_OBJ_SOURCES  = $(wildcard ${GETOPTIONS_DIR}/*.c)
CIF_PARSER_OBJS  = ${CIF_PARSER_OBJ_SOURCES:${CIF_PARSER_C_DIR}/%.c=${CIF_PARSER_C_DIR}/obj/%.o} \
                   ${CEXCEPTIONS_OBJ_SOURCES:${CEXCEPTIONS_DIR}/%.c=${CEXCEPTIONS_DIR}/obj/%.o} \
                   ${GETOPTIONS_OBJ_SOURCES:${GETOPTIONS_DIR}/%.c=${GETOPTIONS_DIR}/obj/%.o}

OBJS = ${OBJ} ${SWIG_WRAPPER_OBJ} ${CIF_PARSER_OBJS}

.PHONY: all

all: ${SWIG_MODULE} ${SWIG_SO_FILE}

${SWIG_SO_FILE}: ${OBJS}
	gcc -shared ${OBJS} -o $@

${OBJ} ${SWIG_WRAPPER_OBJ}: ${SWIG_SOURCE} ${SWIG_WRAPPER}
	gcc -Wall -Wno-unused-value \
		-I/usr/local/include \
		-I/usr/include/python2.7 -lpython2.7 \
		-I${CIF_PARSER_C_DIR} \
		-I${CEXCEPTIONS_DIR} \
		-I${GETOPTIONS_DIR} -c \
		-O2 -fPIC \
		$+

${SWIG_WRAPPER} ${SWIG_MODULE}: ${SWIG_INP_FILE} ${SWIG_SOURCE}
	swig -python $<

${CIF_PARSER_C_DIR}/%.tab.o: ${CIF_PARSER_C_DIR}/%.y
	${MAKE} -C ${dir $@} ${notdir $@}

${CIF_PARSER_C_DIR}/obj/%.o: ${CIF_PARSER_C_DIR}/%.c
	${MAKE} -C ${CIF_PARSER_C_DIR} obj/$*.o

${CEXCEPTIONS_DIR}/obj/%.o: ${CEXCEPTIONS_DIR}/%.c
	${MAKE} -C ${CEXCEPTIONS_DIR} obj/$*.o

${GETOPTIONS_DIR}/obj/%.o: ${GETOPTIONS_DIR}/%.c
	${MAKE} -C ${GETOPTIONS_DIR} obj/$*.o

.PHONY: clean cleanAll distclean try

clean:
	rm -f ${SWIG_WRAPPER} ${OBJ} ${SWIG_WRAPPER_OBJ} *~

cleanAll distclean: clean
	rm -f ${SWIG_SO_FILE} ${SWIG_MODULE}

try: ${SWIG_MODULE}
	-python -c 'import ccifparser;print ccifparser.parse( "../../../../../../tests/inputs/1000000.cif", {} )'
