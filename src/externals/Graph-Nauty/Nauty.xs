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
sparsenauty(sg, lab, ptn, options)
        sparsegraph &sg
        int * lab
        int * ptn
        int * orbits = NO_INIT
        optionblk &options
        statsblk &stats = NO_INIT
        sparsegraph &sg2 = NO_INIT
    CODE:
        if( options.getcanon ) {
            SG_INIT( sg2 );
            SG_ALLOC( sg2, sg.nv, sg.nde, "malloc" );
        }
        orbits = malloc( sizeof(int) * sg.nv );

        /* Increasing workspace to handle larger or more intricate
           graphs */
        size_t worksize = 2000;
        setword workspace[worksize];
        nauty( (graph*)&sg, lab, ptn, NULL, orbits, &options, &stats,
               workspace, worksize, SETWORDSNEEDED(sg.nv), sg.nv, (graph*)&sg2 );

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
        hv_store( statsblk, "orbits", 6, newRV_noinc( (SV*)orbits_return ), 0 );
        free( orbits );
        if( options.getcanon ) {
            HV *canon = newHV();
            hv_store( canon, "nde", 3, newSViv( sg2.nde ), 0 );
            hv_store( canon, "nv",  2, newSViv( sg2.nv ),  0 );

            AV *v = newAV();
            AV *d = newAV();
            AV *e = newAV();
            for( i = 0; i < sg2.vlen; i++ ) {
                av_store( v, i, newSViv( sg2.v[i] ) );
            }
            for( i = 0; i < sg2.dlen; i++ ) {
                av_store( d, i, newSViv( sg2.d[i] ) );
            }
            for( i = 0; i < sg2.elen; i++ ) {
                av_store( e, i, newSViv( sg2.e[i] ) );
            }
            SG_FREE( sg2 );
            hv_store( canon, "v", 1, newRV_noinc( (SV*)v ), 0 );
            hv_store( canon, "d", 1, newRV_noinc( (SV*)d ), 0 );
            hv_store( canon, "e", 1, newRV_noinc( (SV*)e ), 0 );

            hv_store( statsblk, "canon", 5, newRV_noinc( (SV*)canon ), 0 );

            AV *lab_return = newAV();
            for( i = 0; i < sg.nv; i++ ) {
                av_store( lab_return, i, newSViv( lab[i] ) );
            }

            hv_store( statsblk, "lab", 3, newRV_noinc( (SV*)lab_return ), 0 );
        }
        free( lab );
        free( ptn );
        SG_FREE( sg );
        RETVAL = newRV_noinc( (SV*)statsblk );
    OUTPUT:
        RETVAL

bool
aresame_sg(sg1, sg2)
        sparsegraph &sg1
        sparsegraph &sg2
    CLEANUP:
        SG_FREE( sg1 );
        SG_FREE( sg2 );
