# clipper makefile

include(config.status)

# these should be OK
IFFTW=${FFTW}/`include'
IMMDB=${MMDB}/mmdb


CPPFLAGS=${XCPPFLAGS} -I${IFFTW} -I${IMMDB}


# library files
obj=include(clipper/cif/Makefile.obj)


# make rules
all:	libclipper-cif.a

libclipper-cif.a:	${obj}
		rm -f $@; ${AR} $@ ${obj}

include(clipper/cif/Makefile.dep)

%.o:		%.cpp
		${CXX} -c $(CFLAGS) $(CPPFLAGS) $<

clean: 
		rm *.a *.o

