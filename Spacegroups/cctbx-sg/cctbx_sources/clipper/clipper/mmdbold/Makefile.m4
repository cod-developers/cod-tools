# clipper makefile

include(config.status)

# these should be OK
IFFTW=${FFTW}/`include'
IMMDB=${MMDB}/mmdb


CPPFLAGS=${XCPPFLAGS} -I${IFFTW} -I${IMMDB}


# library files
obj=include(clipper/mmdbold/Makefile.obj)


# make rules
all:	libclipper-mmdbold.a

libclipper-mmdbold.a:	${obj}
		rm -f $@; ${AR} $@ ${obj}

include(clipper/mmdbold/Makefile.dep)

%.o:		%.cpp
		${CXX} -c $(CFLAGS) $(CPPFLAGS) $<

clean: 
		rm *.a *.o

