BUILD_DIR = build
LIB       = ${BUILD_DIR}/libsymspg.a

.PHONY: all check cleanAll distclean

all: ${LIB}

${LIB}:
	mkdir ${BUILD_DIR}
	cd ${BUILD_DIR} && CFLAGS=-fPIC cmake .. -DSPGLIB_WITH_TESTS=OFF
	$(MAKE) -C ${BUILD_DIR}

check:
	@true

cleanAll distclean:
	rm -rf ${BUILD_DIR}
