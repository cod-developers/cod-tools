# clipper makefile

include(config.status)

# these should be OK


CPPFLAGS=${XCPPFLAGS}


# library files
obj=include(clipper/phs/Makefile.obj)


# make rules
all:	libclipper-phs.a

libclipper-phs.a:	${obj}
		rm -f $@; ${AR} $@ ${obj}

include(clipper/phs/Makefile.dep)

%.o:		%.cpp
		${CXX} -c $(CFLAGS) $(CPPFLAGS) $<

clean: 
		rm *.a *.o

