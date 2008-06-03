/*
     ccp4_types.h: CCP4 library.c macro definitions etc
     Copyright (C) 2001  CCLRC

     This library is free software and is distributed under the terms and
     conditions of the CCP4 licence agreement as `Part 0' (Annex 2)
     software, which is version 2.1 of the GNU Lesser General Public
     Licence (LGPL) with the following additional clause:

        `You may also combine or link a "work that uses the Library" to
        produce a work containing portions of the Library, and distribute
        that work under terms of your choice, provided that you give
        prominent notice with each copy of the work that the specified
        version of the Library is used in it, and that you include or
        provide public access to the complete corresponding
        machine-readable source code for the Library including whatever
        changes were used in the work. (i.e. If you make changes to the
        Library you must distribute those, but you do not need to
        distribute source or object code to those portions of the work
        not covered by this licence.)'

     Note that this clause grants an additional right and does not impose
     any additional restriction, and so does not affect compatibility
     with the GNU General Public Licence (GPL). If you wish to negotiate
     other terms, please contact the maintainer.

     You can redistribute it and/or modify the library under the terms of
     the GNU Lesser General Public License as published by the Free Software
     Foundation; either version 2.1 of the License, or (at your option) any
     later version.

     This library is distributed in the hope that it will be useful, but
     WITHOUT ANY WARRANTY; without even the implied warranty of
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
     Lesser General Public License for more details.

     You should have received a copy of the CCP4 licence and/or GNU
     Lesser General Public License along with this library; if not, write
     to the CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
     The GNU Lesser General Public can also be obtained by writing to the
     Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
     MA 02111-1307 USA
*/
#ifndef __CCP4_TYPES
#define __CCP4_TYPES

#include "ccp4_sysdep.h"

typedef unsigned short uint16;
#ifdef SIXTEENBIT
typedef unsigned long uint32;
#else
typedef unsigned int uint32;
#endif
typedef float float32;
typedef unsigned char uint8;
union float_uint_uchar {
    float32 f;
    uint32 i;
    uint8 c[4];
  };

typedef   char     *        pstr;

/* CCP4 library.c macro definitions */

#ifndef FALSE
#define FALSE 0
#define TRUE 1
#endif

typedef struct { double r;             /* real component and */
                 double i;             /* imaginary component of */
               } COMPLEX;              /* a complex number */

typedef struct { double r;             /* radial and */
                 double phi;           /* angular component of */
               } POLAR;                /* a complex number */

/* some simple macros, which may exist anyway */
#ifndef SQR
#define SQR(x) ((x)*(x))
#endif
#ifndef DEGREE
#define DEGREE(x) ((((x < 0)?(x)+2*M_PI:(x))*360)/(2*M_PI))
#endif
#ifndef RADIAN
#define RADIAN(x) ((((x<0)?(x)+360:(x))*2*M_PI)/360)
#endif
#ifndef MAX
#define MAX(x, y) (((x)>(y))?(x):(y))
#endif
#ifndef MIN
#define MIN(x, y) (((x)<(y))?(x):(y))
#endif
#ifndef ABS
#define ABS(x) (((x)<0)?-(x):(x))
#endif
#ifndef SIGN
#define SIGN(x) (((x)<0)?-1:1)
#endif

#endif   /* __CCP4_TYPES */
