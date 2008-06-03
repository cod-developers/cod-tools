# clipper makefike

include(config.status)

library:        $(MKLIBS)

lib-core:
		cd clipper/core; $(MAKE); cd ../..

lib-mmdb:
		cd clipper/mmdb; $(MAKE); cd ../..

lib-contrib:
		cd clipper/contrib; $(MAKE); cd ../..

lib-minimol:
		cd clipper/minimol; $(MAKE); cd ../..

lib-phs:
		cd clipper/phs; $(MAKE); cd ../..

lib-cif:
		cd clipper/cif; $(MAKE); cd ../..

lib-ccp4:
		cd clipper/ccp4; $(MAKE); cd ../..

lib-cctbx:
		cd clipper/cctbx; $(MAKE); cd ../..

lib-mmdbold:
		cd clipper/mmdbold; $(MAKE); cd ../..

install:	library
		-mkdir ${CLPR}/lib;
		-mkdir ${CLPR}/`include';
		-mkdir ${CLPR}/`include'/clipper;
		-mkdir ${CLPR}/`include'/clipper/core;
		-mkdir ${CLPR}/`include'/clipper/mmdb;
		-mkdir ${CLPR}/`include'/clipper/contrib;
		-mkdir ${CLPR}/`include'/clipper/minimol;
		-mkdir ${CLPR}/`include'/clipper/phs;
		-mkdir ${CLPR}/`include'/clipper/cif;
		-mkdir ${CLPR}/`include'/clipper/ccp4;
		-mkdir ${CLPR}/`include'/clipper/cctbx;
		-mkdir ${CLPR}/`include'/clipper/mmdbold;
		cp clipper/*/*.a       ${CLPR}/lib/;
		cp clipper/*.h         ${CLPR}/`include'/clipper/;
		cp clipper/core/*.h    ${CLPR}/`include'/clipper/core/;
		cp clipper/mmdb/*.h    ${CLPR}/`include'/clipper/mmdb/;
		cp clipper/contrib/*.h ${CLPR}/`include'/clipper/contrib/;
		cp clipper/minimol/*.h ${CLPR}/`include'/clipper/minimol/;
		cp clipper/phs/*.h     ${CLPR}/`include'/clipper/phs/;
		cp clipper/cif/*.h     ${CLPR}/`include'/clipper/cif/;
		cp clipper/ccp4/*.h    ${CLPR}/`include'/clipper/ccp4/;
		cp clipper/cctbx/*.h   ${CLPR}/`include'/clipper/cctbx/;
		cp clipper/mmdbold/*.h ${CLPR}/`include'/clipper/mmdbold/;

examples:	install
		cd examples; $(MAKE); cd ..

clean:
		cd clipper; cd core; $(MAKE) clean; cd ../mmdb; $(MAKE) clean; cd ../contrib; $(MAKE) clean; cd ../minimol; $(MAKE) clean; cd ../phs; $(MAKE) clean; cd ../cif; $(MAKE) clean; cd ../ccp4; $(MAKE) clean; cd ../cctbx; $(MAKE) clean; cd ../mmdbold; $(MAKE) clean; cd ../../examples; $(MAKE) clean; cd ..

realclean:	clean
		rm clipper/*/Makefile examples/Makefile Makefile
