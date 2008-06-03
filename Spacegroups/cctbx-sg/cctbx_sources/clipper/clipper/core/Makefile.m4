# clipper makefile

include(config.status)

# these should be OK
IFFTW=${FFTW}/`include'


CPPFLAGS=${XCPPFLAGS} -I${IFFTW}


# library files
obj=include(clipper/core/Makefile.obj)


# make rules
all:	libclipper-core.a

libclipper-core.a:	${obj}
		rm -f $@; ${AR} $@ ${obj}

include(clipper/core/Makefile.dep)

%.o:		%.cpp
		${CXX} -c $(CFLAGS) $(CPPFLAGS) $<

clean: 
		rm *.a *.o

