SWIG_SOURCE   = CCIFParserSWIG.c
SWIG_WRAPPER  = ${SWIG_SOURCE:%.c=%_wrap.c}
SWIG_MODULE	  = ${SWIG_SOURCE:%.c=%.pm}
SWIG_INP_FILE = ${SWIG_SOURCE:%.c=%.i}

OBJ 			 = ${SWIG_SOURCE:%.c=%.o}
SWIG_WRAPPER_OBJ = ${SWIG_WRAPPER:%.c=%.o}
SWIG_SO_FILE 	 = ${SWIG_SOURCE:%.c=%.so}

CIF_PARSER_C_DIR = ../CIFParser-c
CIF_PARSER_OBJS  = $(wildcard ${CIF_PARSER_C_DIR}/obj/*.o) \
                   $(wildcard ${CIF_PARSER_C_DIR}/libs/cexceptions/obj/*.o) \
                   $(wildcard ${CIF_PARSER_C_DIR}/libs/getoptions/obj/*.o) \
                   ${CIF_PARSER_C_DIR}/cif_grammar.tab.o

OBJS = ${OBJ} ${SWIG_WRAPPER_OBJ} ${CIF_PARSER_OBJS}

all: so

so: ${SWIG_SO_FILE}

${SWIG_SO_FILE}: ${OBJS}
	gcc `perl -MConfig -e 'print $$Config{lddlflags}'` ${OBJS} -o $@

${OBJ} ${SWIG_WRAPPER_OBJ}: ${SWIG_SOURCE} ${SWIG_WRAPPER}
	gcc \
		-I${CIF_PARSER_C_DIR} \
		-I${CIF_PARSER_C_DIR}/libs/cexceptions \
		-I${CIF_PARSER_C_DIR}/libs/getoptions -c \
		`perl -MConfig -e 'print join(" ", @Config{qw(ccflags optimize cccdlflags)}, "-I$$Config{archlib}/CORE")'` \
		$+

${SWIG_WRAPPER} ${SWIG_MODULE}: ${SWIG_INP_FILE} ${SWIG_SOURCE}
	swig -perl5 $<

clean:
	rm -f ${SWIG_WRAPPER} ${OBJ} ${SWIG_WRAPPER_OBJ} *~

cleanAll: clean
	rm -f ${SWIG_SO_FILE} ${SWIG_MODULE}

try: so
	-perl -mCCIFParserSWIG -e 'my $$c = CCIFParserSWIG::parse_cif( "../perl-scripts/tests/cif_filter_147.inp" ); print CCIFParserSWIG::CIF::swig_nerrors_get($$c) . "\n"'
	-perl -mCCIFParserSWIG -e 'my $$c = CCIFParserSWIG::parse_cif( "../perl-scripts/tests/cif_filter_148.inp" ); print CCIFParserSWIG::CIF::swig_nerrors_get($$c) . "\n"'
