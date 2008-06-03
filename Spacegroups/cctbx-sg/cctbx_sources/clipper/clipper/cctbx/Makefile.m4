# clipper makefile

include(config.status)

# these should be OK
ICCTBX0=${CCTBX}/cctbx_build/include/
ICCTBX1=${CCTBX}/cctbx_sources/cctbx/include/
ICCTBX2=${CCTBX}/cctbx_sources/scitbx/include/
ICCTBX3=${CCTBX}/cctbx_sources/boost/


CPPFLAGS=${XCPPFLAGS}  -I${ICCTBX0} -I${ICCTBX1} -I${ICCTBX2} -I${ICCTBX3}


# library files
obj=include(clipper/cctbx/Makefile.obj)


# make rules
all:	libclipper-cctbx.a

libclipper-cctbx.a:	${obj}
		rm -f $@; ${AR} $@ ${obj}

include(clipper/cctbx/Makefile.dep)

%.o:		%.cpp
		${CXX} -c $(CFLAGS) $(CPPFLAGS) $<

clean: 
		rm *.a *.o

