#------------------------------------------------------------------------------
#$Author: saulius $
#$Revision$
#$Date$
#$URL: svn+ssh://kolibris.ibt.lt/home/saulius/svn-repositories/compilers/MasterMakefile $
#------------------------------------------------------------------------------

MAKECONF_FILES = ${filter-out %~, ${wildcard Makeconf*}}

ifneq ("${MAKECONF_FILES}","")
include ${MAKECONF_FILES}
endif

CWD := ${shell pwd}
PERL5LIB := ${PERL5LIB}:${CWD}/lib/perl5
export PERL5LIB

#
# TEST variable should be defined in the Makeconf file, or on the
# command line, and specifies the main executable (target). This
# executable will be run for every file in ./inputs when 'make test'
# is invoked.
#

.PHONY: tests

all: tests

#------------------------------------------------------------------------------

MAKELOCAL_FILES = ${filter-out %~, ${wildcard Makelocal*}}

ifneq ("${MAKELOCAL_FILES}","")
include ${MAKELOCAL_FILES}
endif

#------------------------------------------------------------------------------

# When 'make test' is invoked, a TARGET executable will be run for
# every file in inputs that has extension ${EXT}. The outputs will be
# compared with the sample outputs files in ./outputs/*.out, and any
# differences will be recorded in ./outputs/*.diff #

TEST_DIR = ./inputs
OUTPUT_DIR = ./outputs

TEST_FILES = ${wildcard ${TEST_DIR}/*${EXT}}
RES_FILES  = ${patsubst ${TEST_DIR}/%${EXT},${OUTPUT_DIR}/%.out,${TEST_FILES}}
DIFF_FILES = ${patsubst ${TEST_DIR}/%${EXT},${OUTPUT_DIR}/%.diff,${TEST_FILES}}

#
# Outputs and tests from the shell-driven tests
#

SHELL_TSTDIR = ./shtests
SHELL_OUTDIR = ./shoutputs

SHELL_TESTS   = ${wildcard ${SHELL_TSTDIR}/*.sh}
SHELL_BASES   = ${notdir ${SHELL_TESTS}}
SHELL_OUTPUTS = ${addprefix ${SHELL_OUTDIR}/, ${SHELL_BASES:%.sh=%.out}}
SHELL_DIFFS   = ${addprefix ${SHELL_OUTDIR}/, ${SHELL_BASES:%.sh=%.diff}}

#------------------------------------------------------------------------------

.PHONY: outputs test

outputs: ${RES_FILES} ${TST_OUTPUTS}

test: ${DIFF_FILES} ${TST_DIFFS}

${OUTPUT_DIR}/%.diff: ${TARGET} ${TEST_DIR}/%${EXT}
	-@printf "%-30s " "$*:" ; \
	./$^ ${TEST_OPTIONS} 2>&1 | diff ${OUTPUT_DIR}/$*.out - > $@ ; \
	if [ $$? = 0 ]; then echo "OK"; else echo "FAILED:"; cat $@; fi

${OUTPUT_DIR}/%.out: ${TARGET} ${TEST_DIR}/%${EXT}
	-@test -f $@ || echo "$@:"
	-@test -f $@ || ./$^ ${TEST_OPTIONS} 2>&1 | tee $@
	-@touch $@

${TST_OUT_DIR}/%.out: ${TST_EXE_DIR}/%
	-@test -f $@ || echo "$@:"
	-@test -f $@ || $< 2>&1 | tee $@
	-@touch $@

${TST_OUT_DIR}/%.diff: ${TST_EXE_DIR}/%
	-@printf "%-30s " "$*:" ; \
	./$< 2>&1 | diff ${TST_OUT_DIR}/$*.out - > $@ ; \
	if [ $$? = 0 ]; then echo "OK"; else echo "FAILED:"; cat $@; fi

.PHONY: shoutpus shout shtests shtest

shoutputs shout: ${SHELL_OUTPUTS}

shtest shtests: ${SHELL_DIFFS}

${SHELL_OUTDIR}/%.out: ${SHELL_TSTDIR}/%.sh ${TARGET}
	-@test -f $@ || echo "$@:"
	-@test -f $@ || $< ./${TARGET} 2>&1 | tee $@
	-@touch $@

${SHELL_OUTDIR}/%.diff: ${SHELL_TSTDIR}/%.sh ${TARGET}
	-@printf "%-30s " "$*:" ; \
	$< ./${TARGET} 2>&1 | diff ${SHELL_OUTDIR}/$*.out - > $@ ; \
	if [ $$? = 0 ]; then echo "OK"; else echo "FAILED:"; cat $@; fi

.PHONY: tests alltests

tests alltests: test shtests

.PHONY: listdiff

listdiff: # test
	@-( test -d ${OUTPUT_DIR} && \
	    ls -l ${OUTPUT_DIR}/*.diff | awk '{if( $$5 > 0 ) print}' ) || \
	    true
	@-( test -d ${SHELL_OUTDIR} && \
	    ls -l ${SHELL_OUTDIR}/*.diff | awk '{if( $$5 > 0 ) print}' ) || \
	    true

#------------------------------------------------------------------------------

clean:
	rm -f *~
	rm -f ${DIFF_FILES} ${TST_DIFFS}
	rm -f ${SHELL_DIFFS}

cleanAll: clean ${LOCAL_CLEAN_TARGETS}
