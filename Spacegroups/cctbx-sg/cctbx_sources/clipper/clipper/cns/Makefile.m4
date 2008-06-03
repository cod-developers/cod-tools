# clipper makefile

include(config.status)

# these should be OK
IFFTW=${FFTW}/`include'


CPPFLAGS=${XCPPFLAGS} -I${IFFTW}


# library files
obj=include(clipper/cns/Makefile.obj)


# make rules
all:	libclipper-cns.a

libclipper-cns.a:	${obj}
		rm -f $@; ${AR} $@ ${obj}

include(clipper/cns/Makefile.dep)

%.o:		%.cpp
		${CXX} -c $(CFLAGS) $(CPPFLAGS) $<

clean: 
		rm *.a *.o

