# clipper makefile

include(config.status)

# these should be OK
IFFTW=${FFTW}/`include'
IMMDB=${MMDB}/mmdb


CPPFLAGS=${XCPPFLAGS} -I${IFFTW} -I${IMMDB}


# library files
obj=include(clipper/contrib/Makefile.obj)


# make rules
all:	libclipper-contrib.a

libclipper-contrib.a:	${obj}
		rm -f $@; ${AR} $@ ${obj}

include(clipper/contrib/Makefile.dep)

%.o:		%.cpp
		${CXX} -c $(CFLAGS) $(CPPFLAGS) $<

clean: 
		rm *.a *.o

