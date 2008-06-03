/*
     library_utils.c: CCP4 Library Utilities
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

/** @page utilities_page CCP4 Library Utilities
 *
 *  @section utilities_list File list

<ul>
<li>library_utils.c
<li>ccp4_general.c
<li>ccp4_parser.c
<li>ccp4_program.c
</ul>

 *  @section utilities_overview Overview

The CCP4 C-library provides many utility functions which either give
specific CCP4 functionality (e.g. traditional keyword parsing) or
are just generally useful (platform independent date).

 */

/** @file library_utils.c
 *  @brief   Utility functions.
 *  @author  Charles Ballard
 */

#include "ccp4_sysdep.h"
#include <time.h>
#include <math.h>
#include "ccp4_utils.h"
#include "ccp4_errno.h"

#if defined (_MSC_VER)
#include <tchar.h>
#include <wchar.h>
#include <direct.h>
#include <io.h>
#endif

#if !defined (_MSC_VER)
#include <pwd.h>
#endif

#define CCP4_ERRNO(y) (CCP4_ERR_UTILS | (y))

/* static uint16 nativeIT = NATIVEIT; */ /* machine integer type - currently unused here */
static uint16 nativeFT = NATIVEFT; /* machine float type */

/** .
 *
 * @return
 */
int ccp4_utils_translate_mode_float(float *out, const void *buffer, int dim, int mode)
{
  unsigned char *ucp;
  unsigned short *usp;
  float *fp = out, *ufp, tmp1, tmp2;
  register int ctr;

  switch(mode) {
  case 0:
    ucp = (unsigned char *)buffer;
    for(ctr = 0; ctr < dim ; ++ctr)
      *fp++ = (float) *ucp++;
    break;
  case 1:
    usp = (unsigned short *)buffer;
    for(ctr = 0; ctr < dim ; ++ctr)
      *fp++ = (float) *usp++;
    break;
  case 3:
    /* complex short (define type ?) */
    usp = (unsigned short *)buffer;
    for(ctr = 0; ctr < dim ; ++ctr) {
      tmp1 = (float) *usp++;
      tmp2 = (float) *usp++;
      *fp++ = (float) sqrt(tmp1*tmp1 + tmp2*tmp2);
    }
    break;
  case 4:
    /* complex real (define type ?) */
    ufp = (float *)buffer;
    for(ctr = 0; ctr < dim ; ++ctr) {
      tmp1 = *ufp++;
      tmp2 = *ufp++;
      *fp++ = (float) sqrt(tmp1*tmp1 + tmp2*tmp2);
    }
    break;
  case 2:
  default:
    break;
  }

  return (ctr);
}

/** Gets the length of a Fortran string with trailing blanks removed.
 *
 * @return length of string
 */
size_t ccp4_utils_flength (char *s, int len)
{
  while (s[--len] == ' ')
    if (len == 0) return 0;
  return (++len);
}

/** .
 *
 * @return
 */
void ccp4_utils_print (const char *message)
{
  printf ("%s\n",message);
 }

#if ! defined (VMS)
/** .
 *
 * @return
 */
int ccp4_utils_setenv (char *str)
{
#if defined (sgi) || defined (sun) || defined (__hpux) || \
    defined(_AIX) || defined (__OSF1__) || \
    defined (__osf__) || defined (__FreeBSD__) || defined (linux) || \
    defined (_WIN32)
  /* putenv is the POSIX.1, draft 3 proposed mechanism */
#if !(defined(__hpux) && defined(__HP_cc))
  int putenv ();
#endif
  char *param;

  if ( (param = (char *) ccp4_utils_malloc( (strlen(str)+1)*sizeof(char) )) == NULL) {
    ccp4_errno = CCP4_ERRNO(errno);
    return -1; }
  strcpy(param,str);
  return (putenv (param));
  /* note the necessary lack of free() */
#else
  /* setenv is not POSIX, BSD might have to use `index' */
  int setenv ();
  char *param1,*param2;

  if ( (param1 = (char *) ccp4_utils_malloc( (strlen(str)+1)*sizeof(char) )) == NULL) {
    ccp4_errno = CCP4_ERRNO(errno);
    return -1; }
  strcpy(param1,str);
  if ((param2 = (char *) strchr(param1, '=')) == NULL) {
    ccp4_errno = CCP4_ERRNO(errno);
    return -1; }
  *param2++ = '\0';
  return (setenv (param1, param2, 1));
#endif
}
#endif

#if ! defined (VMS)
/** .
 *
 * @return
 */
int ccp4_utils_outbuf(void)
{
#if defined (sgi) || defined (sun) || \
    defined (__OSF1__) || \
    defined (__FreeBSD__)
  return setlinebuf(stdout);
#else
#if defined (_MSC_VER)
  return setvbuf(stdout, NULL, _IONBF, 80);
#else
#  if defined (_AIX)
  return -1;
#  else
  /* Windows requires size argument, though 0 works on unix */
  return setvbuf(stdout, NULL, _IOLBF, 80);
#  endif
#endif
#endif
}

/** .
 *
 * @return
 */
int ccp4_utils_noinpbuf(void)
{
  return setvbuf(stdin, NULL, _IONBF, 0);
}
#endif

union float_uint_uchar ccp4_nan ()

#if NATIVEFT == DFNTF_BEIEEE || NATIVEFT == DFNTF_LEIEEE
#  define CCP4_NAN 0xfffa5a5a
#endif
/* For \idx{Convex} native mode and \idx{VAX} use a \idx{Rop} value:        */
/*                                                                          */
/* <magic numbers>=                                                         */
#if NATIVEFT == DFNTF_CONVEXNATIVE
#  define CCP4_NAN 0x80000000
#endif
#if NATIVEFT == DFNTF_VAX
#  define CCP4_NAN 0x00008000
#endif
#ifndef CCP4_NAN
#  error "CCP4_NAN isn't defined (needs NATIVEFT)"
#endif
{
  union float_uint_uchar realnum;

  realnum.i = CCP4_NAN;
  return (realnum);
}

/** .
 *
 * @return
 */
int ccp4_utils_isnan (const union float_uint_uchar *realnum)
{
    switch (nativeFT) {
    case DFNTF_BEIEEE :
    case DFNTF_LEIEEE :
      return ((realnum->i & 0x7f800000) == 0x7f800000); /* exponent all 1s */
    case DFNTF_CONVEXNATIVE :
      return ((realnum->i & 0xff800000) == 0x80000000);
    case DFNTF_VAX :
      return ((realnum->i & 0x0000ff80) == 0x00008000);
    default :
      ccp4_fatal("CCP4_UTILS_ISNAN: bad nativeFT");
      return 0;                   /* avoid compiler warning */
    }
}

#define MDFBIG -1.0E10          /* BIOMOL absence flag value */
/** .
 *
 * @return
 */
void ccp4_utils_bml (int ncols, union float_uint_uchar cols[])
{
  int i;
  for (i=0; i<ncols; i++)
    if (cols[i].i != CCP4_NAN)
      if (cols[i].f <= MDFBIG) cols[i].f = 0.0;
}

/** .
 *
 * @return
 */
void ccp4_utils_wrg (int ncols, union float_uint_uchar cols[], float wminmax[])
{
  int i;
  for (i=0; i<ncols; i++)
    if (cols[i].i != CCP4_NAN)
       if (cols[i].f > MDFBIG) {
         if (cols[i].f < wminmax[2*i]) wminmax[2*i] = cols[i].f;
         if (cols[i].f > wminmax[1+2*i]) wminmax[1+2*i] = cols[i].f; }
}

/** .
 *
 * @return
 */
void ccp4_utils_hgetlimits (int *IValueNotDet, float *ValueNotDet)
{
  *IValueNotDet = INT_MAX;
  *ValueNotDet  = FLT_MAX;
}

/** .
 *
 * @return
 */
int ccp4_utils_mkdir (const char *path, const char *cmode)
#if !defined (_MSC_VER) && !defined(_WIN32)
{
  unsigned mode = 0;
  int result;
#if defined (__APPLE__)
  static const unsigned TBM = 0x07;

  switch (strlen(cmode)) {
  case 4:
    mode |= (*cmode & TBM) << 9 ;
    mode |= (*(cmode+1) & TBM) << 6 ;
    mode |= (*(cmode+2) & TBM) << 3 ;
    mode |= (*(cmode+3) & TBM) ;
    break;
  case 3:
    mode |= (*cmode & TBM) << 6 ;
    mode |= (*(cmode+1) & TBM) << 3 ;
    mode |= (*(cmode+2) & TBM) ;
    break;
  case 2:
    mode |= (*cmode & TBM) << 3 ;
    mode |= (*(cmode+1) & TBM) ;
    break;
  case 1:
    mode |= (*cmode & TBM) ;
    break;
  default:
    mode = 0x0fff ;
  }
#else
/* Possible modes (see stat.h)
  Currently pass 3-character string and interpret as octal.
  Try also S_IRWXU, S_IRWXG, etc. */
  sscanf(cmode,"%o",&mode);
#endif
  result = mkdir(path, (mode_t) mode);

  if (result == -1) {
    if (errno == EEXIST) {
      result = 1;
    }
  }
  return (result);
}
#else
   {
     /*printf("No harvesting on NT.");
       return (-1);*/
     int result;
     result = mkdir(path);

     if (result == -1) {
       if (errno == EEXIST) {
         result = 1;
       }
     }
     return (result);
   }
#endif

/** .
 *
 * @return
 */
int ccp4_utils_chmod (const char *path, const char *cmode)
#if !defined (_MSC_VER) || !defined(_WIN32)
{
  unsigned mode = 0;
#if defined (__APPLE__)
  static const unsigned TBM = 0x07;

  switch (strlen(cmode)) {
  case 4:
    mode |= (*cmode & TBM) << 9 ;
    mode |= (*(cmode+1) & TBM) << 6 ;
    mode |= (*(cmode+2) & TBM) << 3 ;
    mode |= (*(cmode+3) & TBM) ;
    break;
  case 3:
    mode |= (*cmode & TBM) << 6 ;
    mode |= (*(cmode+1) & TBM) << 3 ;
    mode |= (*(cmode+2) & TBM) ;
    break;
  case 2:
    mode |= (*cmode & TBM) << 3 ;
    mode |= (*(cmode+1) & TBM) ;
    break;
  case 1:
    mode |= (*cmode & TBM) ;
    break;
  default:
    mode = 0x0fff ;
  }
#else
/* Possible modes (see stat.h)
  Currently pass 3-character string and interpret as octal.
  Try also S_IRWXU, S_IRWXG, etc. */
  sscanf(cmode,"%o",&mode);
#endif
  return (chmod(path, (mode_t) mode));
}
#else
   {
     /*printf("No harvesting on NT.");
       return (-1);*/
     return (chmod(path,0x0fff));
   }
#endif

/** This is a wrapper for the malloc function, which adds some
 * error trapping.
 *
 * @return void
 */
void *ccp4_utils_malloc(size_t size)

{ void *val;

  val = malloc (size);
  if (!val && size)
    {
      perror ("Failure in ccp4_utils_malloc");
      abort ();
    }
  return val;}

/** This is a wrapper for the realloc function, which adds some
 * error trapping.
 *
 * @return
 */
void *ccp4_utils_realloc(void *ptr, size_t size)
{ void *val;

  val = realloc (ptr, size);
  if (!val && size)
    {
      perror ("Failure in ccp4_utils_realloc");
      abort ();
    }
  return val;}

/** This is a wrapper for the calloc function, which adds some
 * error trapping.
 *
 * @return
 */
void *ccp4_utils_calloc(size_t nelem , size_t elsize)
{ void *val;

  val = calloc (nelem, elsize);
  if (!val && elsize)
    {
      perror ("Failure in ccp4_utils_calloc");
      abort ();
    }
  return val;}


/** Return the user's login name.
 * (MVisualStudio version in w32mvs.c)
 * Note that getlogin only works for processes attached to
 * a terminal (and hence won't work from the GUI).
 * In these instances use getpwuid instead.
 * @return pointer to character string containing login name.
 */
#if ! defined (_MSC_VER)
char *ccp4_utils_username(void)
{
  struct passwd *passwd_struct=NULL;
  char *userid=NULL;
  if (!(userid = getlogin())) {
    passwd_struct = getpwuid(getuid());
    userid = passwd_struct->pw_name;
  }
  return(userid);
}
#endif

/** Extracts the basename from a full file name.
 * Separators for directories and extensions are OS-specific.
 * @param filename full file name string.
 * @return pointer to basename
 */
char *ccp4_utils_basename(char *filename)
{
  int i, indx1=-1, length;
  char *basename;

  for ( i = strlen(filename)-1; i >= 0; i-- ) {
    if (filename[i] == PATH_SEPARATOR) {
      indx1 = i;
      break;
    }
  }
  length = strlen(filename) - indx1;
  /* Search for extension separators must be performed backwards
     in case filename has multiple extension separators */
  for ( i = strlen(filename)-1; i >= (indx1 < 0 ? 0 : indx1) ; i-- ) {
    if (filename[i] == EXT_SEPARATOR) {
      length = i - indx1;
      break;
    }
  }
  basename = ccp4_utils_malloc(length*sizeof(char));
  strncpy(basename,filename+indx1+1,length-1);
  basename[length-1]='\0';
  return basename;
}

/** Extracts the pathname from a full file name.
 * Separators for directories and extensions are OS-specific.
 * @param filename full file name string.
 * @return pointer to pathname with trailing separator.
 */
char *ccp4_utils_pathname(char *filename)
{
  int i, indx1=-1, length;
  char *pathname;

  for ( i = strlen(filename)-1; i >= 0; i-- ) {
    if (filename[i] == PATH_SEPARATOR) {
      indx1 = i;
      break;
    }
  }
  length = indx1+2;
  pathname = ccp4_utils_malloc(length*sizeof(char));
  strncpy(pathname,filename,length-1);
  pathname[length-1]='\0';
  return pathname;
}

/** Extracts the extension from a full file name.
 * Separators for directories and extensions are OS-specific.
 * @param filename full file name string.
 * @return pointer to extension
 */
char *ccp4_utils_extension(char *filename)
{
  int i, indx1=-1, length=1;
  char *extension;

  for ( i = strlen(filename)-1; i >= 0; i-- ) {
    if (filename[i] == EXT_SEPARATOR) {
      indx1 = i;
      length = strlen(filename) - indx1;
      break;
    } else if (filename[i] == PATH_SEPARATOR) {
      indx1 = i;
      length = 1;
      break;
    }
  }
  extension = ccp4_utils_malloc(length*sizeof(char));
  strncpy(extension,filename+indx1+1,length-1);
  extension[length-1]='\0';
  return extension;
}

/** Joins a leading directory with a filename.
 * Separators for directories and extensions are OS-specific.
 * @param dir  directory path.
 * @param file file name string.
 * @return pointer to joined directory-filename path.
 */
char *ccp4_utils_joinfilenames(char *dir, char *file)
{
  char *join=NULL;
  int  lendir,lenfile,lenjoin;

  lendir = strlen(dir);
  lenfile = strlen(file);
  lenjoin = lendir + lenfile + 2;

  join = (char *) ccp4_utils_malloc(sizeof(char)*lenjoin);
  if (!join) {
    return NULL;
  }

  strncpy(join,dir,lendir);
  join[lendir] = PATH_SEPARATOR;
  join[lendir+1] = '\0';
  strncat(join,file,lenfile);
  join[lenjoin-1] = '\0';

  return join;
}

/** .
 *
 * @return
 */
void ccp4_utils_idate (int iarray[3])
{
     struct tm *lt=NULL;
     time_t tim;
     tim = time(NULL);
     lt = localtime(&tim);
     iarray[0] = lt->tm_mday;
     iarray[1] = lt->tm_mon+1;  /* need range 1-12 */
     iarray[2] = lt->tm_year + 1900;
}

/** .
 *
 * @return
 */
char *ccp4_utils_date(char *date)
{
  int iarray[3];

  ccp4_utils_idate(iarray);
  sprintf(date,"%2d/%2d/%4d",iarray[0],iarray[1],iarray[2]);
  date[10] = '\0';

  return (date);
}

/** Function to obtain current time.
 * @param iarray Array containing hours, minutes and seconds.
 * @return void.
 */
void ccp4_utils_itime (int iarray[3])
{
     struct tm *lt;
     time_t tim;
     tim = time(NULL);
     lt = localtime(&tim);
     iarray[0] = lt->tm_hour;
     iarray[1] = lt->tm_min;
     iarray[2] = lt->tm_sec;
}

/** Alternative to ccp4_utils_itime with time as character string.
 * @param time Character string of form HH:MM:SS
 * @return pointer to character string.
 */
char *ccp4_utils_time(char *time)
{
  int iarray[3];

  ccp4_utils_itime(iarray);
  sprintf(time,"%2.2d:%2.2d:%2.2d",iarray[0],iarray[1],iarray[2]);
  time[8] = '\0';

  return (time);
}

/** Function to obtain User and System times.
 * @param tarray Array containing User and System times.
 * @return Sum of User and System times.
 */
#if ! defined (_MSC_VER)
float ccp4_utils_etime (float tarray[2])
{
  static long clk_tck = 0;

  struct tms buffer;
  if (! clk_tck) clk_tck = sysconf(_SC_CLK_TCK);
  (void) times(&buffer);
  tarray[0] = (float) buffer.tms_utime / (float)clk_tck;
  tarray[1] = (float) buffer.tms_stime / (float)clk_tck;
  return (tarray[0]+tarray[1]);
}
#endif

#if defined (_MSC_VER)
double ccp4_erfc( double x )
{
  double t,z,ans;

  z=fabs(x);
  t=1.0/(1.0+0.5*z);
  ans=t*exp(-z*z-1.26551223+t*(1.00002368+t*(0.37409196+t*(0.09678418+
      t*(-0.18628806+t*(0.27886807+t*(-1.13520398+t*(1.48851587+
      t*(-0.82215223+t*0.17087277)))))))));
  return  x >= 0.0 ? ans : 2.0-ans;
}
#endif

#if defined (__APPLE__) && defined (__GNUC__) && ( __GNUC__ < 3 )
void _carbon_init(int argc, char **argv) {}
void _objcInit(void) {}
#endif

#if defined (__APPLE__) && defined (__GNUC__) && ( __GNUC__ == 3 ) && (__GNUC_MINOR__ == 1)
float acosf(float x) {
  return (float) acos( (double) x);
}

float atanf(float x) {
  return (float) atan( (double) x);
}

float asinf(float x) {
  return (float) asin( (double) x);
}

#endif

#  if (defined _MSC_VER)
double rint(double x) {
  if (x >= 0.) {
   return (double)(int)(x+.5);
  }
  return (double)(int)(x-.5);
}
#endif
