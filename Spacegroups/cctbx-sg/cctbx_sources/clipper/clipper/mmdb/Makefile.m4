# clipper makefile

include(config.status)

# these should be OK
IFFTW=${FFTW}/`include'
IMMDB=${MMDB}/mmdb


CPPFLAGS=${XCPPFLAGS} -I${IFFTW} -I${IMMDB}


# library files
obj=include(clipper/mmdb/Makefile.obj)


# make rules
all:	libclipper-mmdb.a

libclipper-mmdb.a:	${obj}
		rm -f $@; ${AR} $@ ${obj}

include(clipper/mmdb/Makefile.dep)

%.o:		%.cpp
		${CXX} -c $(CFLAGS) $(CPPFLAGS) $<

clean: 
		rm *.a *.o

