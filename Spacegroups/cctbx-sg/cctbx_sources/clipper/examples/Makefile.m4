# clipper makefile

include(config.status)

# these should be OK
IFFTW=${FFTW}/`include'
LFFTW=${FFTW}/lib
IMMDB=${MMDB}/mmdb
LMMDB=${MMDB}
ICCTBX=${CCTBX}
LCCTBX=${CCTBX}/lib
IMCCP4=${MCCP4}
LMCCP4=${MCCP4}
IBOOST=${BOOST}
LBOOST=${CCTBX}/lib

ICLPR=${CLPR}/`include'
LCLPR=${CLPR}/lib


CPPFLAGS=${XCPPFLAGS} -I${IFFTW} -I${IMMDB} -I${ICCTBX} -I${ICLPR}
LDFLAGS=-L${LFFTW} -L${MMDB} -L${LCCTBX} -L${LCLPR}


# targets
TARGETS= cfft cinvfft csigmaa csfcalc chltofom cmaplocal cphasematch cphasecombine cpatterson cecalc cmakereference sftest ffttest mtztest phstest rfltest symtest maptest sgtest sktest ftndemo cctbxtest


# make rules
all:	${TARGETS}


# generic rule
%:		%.cpp ccp4-extras.cpp ../lib/*.a
		${CXX} $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) -o $@ $< ccp4-extras.cpp ${LDLIBS}

# special rule for cmakereference
ftplib.o:	ftplib.c
		${CC} $(CFLAGS) -c ftplib.c

compress42.o:	compress42.c
		${CC} $(CFLAGS) -c compress42.c

cmakereference:	cmakereference.cpp ccp4-extras.cpp ftplib.o compress42.o ../lib/*.a
		${CXX} $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) -o cmakereference cmakereference.cpp ccp4-extras.cpp ftplib.o compress42.o ../lib/*.a ${LDLIBS}

# special rule for ftndemo
ftndemo_lib.o:	ftndemo_lib.cpp
		${CXX} $(CFLAGS) $(CPPFLAGS) -c -o ftndemo_lib.o ftndemo_lib.cpp

ftndemo:	ftndemo.f ftndemo_lib.o ../lib/*.a
		${F77} $(LDFLAGS) -o ftndemo ftndemo.f ftndemo_lib.o ${LDLIBS} -lstdc++

# special rule for cctbxtest
cctbxtest:	cctbxtest.cpp ../lib/*.a
		echo;echo "NOTE: NEXT STEP WILL FAIL IF CCTBX NOT PRESENT. OTHER EXAMPLES WILL WORK.";${CXX} $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) -o $@ $< ${LDLIBS}

clean: 
		rm *.o ${TARGETS}
