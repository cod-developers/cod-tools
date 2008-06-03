/*
     ccp4_spg.h: Data structure for symmetry information
     Copyright (C) 2001  CCLRC, Martyn Winn

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

/** @file ccp4_spg.h
 *
 *  @brief Data structure for symmetry information.
 *
 *  A data structure for spacegroup information and related
 *  quantities. Some items are loaded from syminfo.lib while
 *  others are calculated on the fly.
 *
 *  @author Martyn Winn
 */

#ifndef __CCP4_SPG__
#define __CCP4_SPG__

#ifdef  __cplusplus
namespace CSym {
extern "C" {
#endif

/* Kevin's symmetry operator */

typedef struct ccp4_symop_
{
  float rot[3][3];
  float trn[3];
} ccp4_symop;

typedef struct ccp4_spacegroup_
{
  int spg_num;            /* true spacegroup number */
  int spg_ccp4_num;       /* CCP4 spacegroup number */
  char symbol_Hall[40];   /* Hall symbol */
  char symbol_xHM[20];    /* Extended Hermann Mauguin symbol  */
  char symbol_old[20];    /* old spacegroup name */

  char point_group[20];   /* point group name */
  char crystal[20];       /* crystal system */

  int nlaue;              /* CCP4 Laue class number, inferred from asu_descr */
  char laue_name[20];     /* Laue class name */
  int laue_sampling[3];   /* sampling factors for FFT */

  int npatt;              /* Patterson spacegroup number, inferred from asu_descr */
  char patt_name[40];     /* Patterson spacegroup name */

  int nsymop;             /* total number of symmetry operations */
  int nsymop_prim;        /* number of primitive symmetry operations */
  ccp4_symop *symop;      /* symmetry matrices */
  ccp4_symop *invsymop;   /* inverse symmetry matrices */

  float chb[3][3];        /* change of basis matrix from file */

  char asu_descr[80];     /* asu description from file */
  int (*asufn)(const int, const int, const int); /* pointer to ASU function */

  int centrics[12];       /* symop which generates centric zone, 0 if none */
  int epsilon[13];        /* flag which epsilon zones are applicable */

  char mapasu_zero_descr[80];  /* origin-based map asu: description from file */
  float mapasu_zero[3];   /* origin-based map asu: upper limits */

  char mapasu_ccp4_descr[80];  /* CCP4 map asu: defaults to mapasu_zero */
  float mapasu_ccp4[3];   /* CCP4 map asu: upper limits */

} CCP4SPG;

#ifdef __cplusplus
} }
#endif

#endif  /*!__CCP4_SPG__ */

