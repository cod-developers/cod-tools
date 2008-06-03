# clipper makefile

include(config.status)

# these should be OK
IFFTW=${FFTW}/`include'


CPPFLAGS=${XCPPFLAGS} -I${IFFTW}


# library files
obj=include(clipper/ccp4/Makefile.obj)


# make rules
all:	libclipper-ccp4.a

libclipper-ccp4.a:	${obj}
		rm -f $@; ${AR} $@ ${obj}

include(clipper/ccp4/Makefile.dep)

%.o:		%.cpp
		${CXX} -c $(CFLAGS) $(CPPFLAGS) $<

clean: 
		rm *.a *.o

