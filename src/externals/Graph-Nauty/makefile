MAKEFILE    = Makefile
BS_FILE     = Nauty.bs
TEST_OUTPUT = test.log

.PHONY: all check

all: $(BS_FILE)

$(BS_FILE): $(MAKEFILE)
	$(MAKE) -f $(MAKEFILE) all

check test tests: $(TEST_OUTPUT)

$(TEST_OUTPUT): $(MAKEFILE)
	@echo RUNNING TEST
	-$(MAKE) -f $(MAKEFILE) test | tee $@

distclean: $(MAKEFILE)
	$(MAKE) -f $(MAKEFILE) $@
	rm -f $(TEST_OUTPUT)

$(MAKEFILE):
	perl Makefile.PL
