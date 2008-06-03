# clipper makefile

include(config.status)

# these should be OK
IFFTW=${FFTW}/`include'
IMMDB=${MMDB}/mmdb


CPPFLAGS=${XCPPFLAGS} -I${IFFTW} -I${IMMDB}


# library files
obj=include(clipper/minimol/Makefile.obj)


# make rules
all:	libclipper-minimol.a

libclipper-minimol.a:	${obj}
		rm -f $@; ${AR} $@ ${obj}

include(clipper/minimol/Makefile.dep)

%.o:		%.cpp
		${CXX} -c $(CFLAGS) $(CPPFLAGS) $<

clean: 
		rm *.a *.o

