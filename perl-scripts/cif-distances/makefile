SCRIPT_DIR = bin
TEST_DIR = tests
OUTP_DIR = outputs
TEST_EXT = tst
OPT_EXT = opt
OUTP_EXT = out
DIFF_EXT = diff

TEST_SCRIPT = ${wildcard ${SCRIPT_DIR}/*}

CWD := ${shell pwd}
TOP := ${dir ${CWD}}
PERL5LIB := ${CWD}/lib/perl5:${PERL5LIB}
PERL5LIB := ${TOP}/lib/perl5:${PERL5LIB}
export PERL5LIB

TEST_FILES = ${wildcard ${TEST_DIR}/*.${TEST_EXT}}
OPT_FILES =  ${TEST_FILES:${TEST_DIR}/%.${TEST_EXT}=${TEST_DIR}/%.${OPT_EXT}}
DIFF_FILES = ${TEST_FILES:${TEST_DIR}/%.${TEST_EXT}=${OUTP_DIR}/%.${DIFF_EXT}}
OUTP_FILES = ${TEST_FILES:${TEST_DIR}/%.${TEST_EXT}=${OUTP_DIR}/%.${OUTP_EXT}}

.PRECIOUS: %.pm
.PHONY: all clean cleanAll distclean test tests out outputs

all: tests

test tests: ${DIFF_FILES}

out outputs: ${OUTP_FILES}

#------------------------------------------------------------------------------
#$@ - target
#$< - first prerequisite
#$^ - prerequisites

${OUTP_DIR}/%.${DIFF_EXT}: ${TEST_SCRIPT} ${TEST_DIR}/%.${OPT_EXT} ${TEST_DIR}/%.${TEST_EXT}
	-@printf "%-30s " "$*:" ; \
	perl $< $(shell grep -v '^#' ${word 2, $^}) < ${word 3, $^} 2>&1 \
	| diff ${OUTP_DIR}/$*.${OUTP_EXT} - > $@ ; \
	if [ $$? = 0 ]; then echo "OK"; else echo "FAILED:"; cat $@; fi

${OUTP_DIR}/%.${DIFF_EXT}: ${TEST_SCRIPT} ${TEST_DIR}/%.${TEST_EXT}
	-@printf "%-30s " "$*:" ; \
	perl $< < ${word 2, $^} 2>&1 | diff ${OUTP_DIR}/$*.${OUTP_EXT} - > $@ ; \
	if [ $$? = 0 ]; then echo "OK"; else echo "FAILED:"; cat $@; fi

${OUTP_DIR}/%.${OUTP_EXT}: ${TEST_SCRIPT} ${TEST_DIR}/%.${OPT_EXT} ${TEST_DIR}/%.${TEST_EXT}
	-@test -f $@ || echo "$@:"
	-@test -f $@ || perl $< $(shell grep -v '^#' ${word 2, $^}) < ${word 3, $^} 2>&1 | tee $@
	-@touch $@

${OUTP_DIR}/%.${OUTP_EXT}: ${TEST_SCRIPT} ${TEST_DIR}/%.${TEST_EXT}
	-@test -f $@ || echo "$@:"
	-@test -f $@ || perl $< < ${word 2, $^} 2>&1 | tee $@
	-@touch $@
#------------------------------------------------------------------------------

.PHONY: listdiff

listdiff: # test
	@-( test -d ${OUTP_DIR} && \
	    ls -l ${OUTP_DIR}/*.${DIFF_EXT} | awk '{if( $$5 > 0 ) print}' ) || \
	    true

#------------------------------------------------------------------------------

clean:
	rm -f ${DIFF_FILES}

distclean cleanAll: clean
