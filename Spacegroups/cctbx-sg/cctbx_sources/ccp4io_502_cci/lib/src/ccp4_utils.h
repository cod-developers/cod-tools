/*
     ccp4_utils.h: headers for utility functions.
     Copyright (C) 2001  CCLRC, Charles Ballard

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

/** @file ccp4_utils.h
 *  @brief   Utility functions.
 *  @author  Charles Ballard
 */

#ifndef __CCP4_UTILS
#define __CCP4_UTILS

#include <string.h>
#include "ccp4_types.h"
#include "library_file.h"

#ifdef __cplusplus
namespace CCP4 {
extern "C" {
#endif

/****************************************************************************
 * Function prototypes                                                      *
 ****************************************************************************/

size_t ccp4_utils_flength (char *, int);

int ccp4_utils_translate_mode_float(float *, const void *, int, int);

void ccp4_utils_fatal (const char *);

void ccp4_utils_print (const char *message);

int ccp4_utils_setenv (char *);

/* turn on line buffering for stdout */
int ccp4_utils_outbuf (void);

/* turn off any buffering on stdin */
int ccp4_utils_noinpbuf (void);

union float_uint_uchar ccp4_nan ();

int ccp4_utils_isnan (const union float_uint_uchar *);

void ccp4_utils_bml (int, union float_uint_uchar *);

void ccp4_utils_wrg (int, union float_uint_uchar *, float *);

void ccp4_utils_hgetlimits (int *, float *);

int ccp4_utils_mkdir (const char *, const char *);

int ccp4_utils_chmod (const char *, const char *);

void *ccp4_utils_malloc(size_t);

void *ccp4_utils_realloc(void *, size_t);

void *ccp4_utils_calloc(size_t, size_t);

int ccp4_file_size(const char *);

char *ccp4_utils_username(void);

char *ccp4_utils_basename(char *filename);

char *ccp4_utils_pathname(char *filename);

char *ccp4_utils_extension(char *filename);

char *ccp4_utils_joinfilenames(char *dir, char *file);

void ccp4_utils_idate (int *);

char *ccp4_utils_date(char *);

void ccp4_utils_itime (int *);

char *ccp4_utils_time(char *);

float ccp4_utils_etime (float *);

#if defined (_MSC_VER)
double ccp4_erfc( double x );
#endif

/****************************************************************************
*  End of prototypes                                                        *
*****************************************************************************/
#ifdef __cplusplus
}
}
#endif

#endif  /* __CCP4_UTILS */
