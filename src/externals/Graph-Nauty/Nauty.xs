#include <nauty/nausparse.h>
/* doref is defined both in perl.h and nauty.h.
   As it is not used, it is undefined to avoid the clash. */
#undef doref

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Graph::Nauty		PACKAGE = Graph::Nauty

SV *
sparsenauty(sg, lab, ptn, orbits, options, sg2)
        sparsegraph &sg
        int * lab
        int * ptn
        int * orbits
        optionblk &options
        statsblk &stats = NO_INIT
        sparsegraph &sg2
    CODE:
        sparsenauty(&sg, lab, ptn, orbits, &options, &stats, &sg2);
        HV *statsblk = newHV();
        hv_store( statsblk, "errstatus",      9, newSViv( stats.errstatus ),     0 );
        hv_store( statsblk, "grpsize1",       8, newSViv( stats.grpsize1 ),      0 );
        hv_store( statsblk, "grpsize2",       8, newSViv( stats.grpsize2 ),      0 );
        hv_store( statsblk, "numgenerators", 13, newSViv( stats.numgenerators ), 0 );
        hv_store( statsblk, "numorbits",      9, newSViv( stats.numorbits ),     0 );
        AV *orbits_return = newAV();
        int i;
        for( i = 0; i < sg.nv; i++ ) {
            av_store( orbits_return, i, newSViv( orbits[i] ) );
        }
        hv_store( statsblk, "orbits", 6, newRV( (SV*)orbits_return ), 0 );
        RETVAL = newRV( (SV*)statsblk );
    OUTPUT:
        RETVAL
