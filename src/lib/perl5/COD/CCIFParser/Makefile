SWIG_SOURCE   = CCIFParser.c
SWIG_WRAPPER  = ${SWIG_SOURCE:%.c=%_wrap.c}
SWIG_MODULE	  = ${SWIG_SOURCE:%.c=%.pm}
SWIG_INP_FILE = ${SWIG_SOURCE:%.c=%.i}

OBJ 			 = ${SWIG_SOURCE:%.c=%.o}
SWIG_WRAPPER_OBJ = ${SWIG_WRAPPER:%.c=%.o}
SWIG_SO_FILE 	 = ../../auto/COD/CCIFParser/${SWIG_SOURCE:%.c=%.so}

CIF_PARSER_C_DIR = ../../../../components/codcif
EXTERNALS_C_DIR  = ../../../../externals
CEXCEPTIONS_DIR  = ${EXTERNALS_C_DIR}/cexceptions
GETOPTIONS_DIR   = ${EXTERNALS_C_DIR}/getoptions
CIF_PARSER_OBJ_SOURCES  = $(wildcard ${CIF_PARSER_C_DIR}/*.c)
CEXCEPTIONS_OBJ_SOURCES = $(wildcard ${CEXCEPTIONS_DIR}/*.c)
GETOPTIONS_OBJ_SOURCES  = $(wildcard ${GETOPTIONS_DIR}/*.c)
CIF_PARSER_OBJS  = ${CIF_PARSER_OBJ_SOURCES:${CIF_PARSER_C_DIR}/%.c=${CIF_PARSER_C_DIR}/obj/%.o} \
                   ${CEXCEPTIONS_OBJ_SOURCES:${CEXCEPTIONS_DIR}/%.c=${CEXCEPTIONS_DIR}/obj/%.o} \
                   ${GETOPTIONS_OBJ_SOURCES:${GETOPTIONS_DIR}/%.c=${GETOPTIONS_DIR}/obj/%.o}

OBJS = ${OBJ} ${SWIG_WRAPPER_OBJ} ${CIF_PARSER_OBJS}

PERL5LIB := ../../COD:../..
export PERL5LIB

all: ${SWIG_MODULE} ${SWIG_SO_FILE}

${SWIG_SO_FILE}: ${OBJS}
	gcc `perl -MConfig -e 'print $$Config{lddlflags}'` ${OBJS} -o $@

${OBJ} ${SWIG_WRAPPER_OBJ}: ${SWIG_SOURCE} ${SWIG_WRAPPER}
	gcc \
		-I${CIF_PARSER_C_DIR} \
		-I${CEXCEPTIONS_DIR} \
		-I${GETOPTIONS_DIR} -c \
		`perl -MConfig -e 'print join(" ", @Config{qw(ccflags optimize cccdlflags)}, "-I$$Config{archlib}/CORE")'` \
		$+

${SWIG_WRAPPER} ${SWIG_MODULE}: ${SWIG_INP_FILE} ${SWIG_SOURCE}
	swig -perl5 -Wall $<

${CIF_PARSER_C_DIR}/%.tab.o: ${CIF_PARSER_C_DIR}/%.y
	${MAKE} -C ${dir $@} ${notdir $@}

${CIF_PARSER_C_DIR}/obj/%.o: ${CIF_PARSER_C_DIR}/%.c
	${MAKE} -C ${CIF_PARSER_C_DIR} obj/$*.o

${CEXCEPTIONS_DIR}/obj/%.o: ${CEXCEPTIONS_DIR}/%.c
	${MAKE} -C ${CEXCEPTIONS_DIR} obj/$*.o

${GETOPTIONS_DIR}/obj/%.o: ${GETOPTIONS_DIR}/%.c
	${MAKE} -C ${GETOPTIONS_DIR} obj/$*.o

clean:
	rm -f ${SWIG_WRAPPER} ${OBJ} ${SWIG_WRAPPER_OBJ} *~

cleanAll: clean
	rm -f ${SWIG_SO_FILE} ${SWIG_MODULE}

try: ${SWIG_MODULE}
	-perl -mCCIFParser -le 'my $$c = COD::CCIFParser::CCIFParser::parse_cif( "../../../../../perl-scripts/tests/cif_filter_147.inp", $$0, {} )'
	-perl -mCCIFParser -le 'my $$c = COD::CCIFParser::CCIFParser::parse_cif( "../../../../../perl-scripts/tests/cif_filter_148.inp", $$0, {} )'
