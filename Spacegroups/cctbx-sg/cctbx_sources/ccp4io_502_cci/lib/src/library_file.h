/*
     library_file.h: header file for library_file.c
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

/** @file library_file.h
 *  Functions for file i/o.
 *  Charles Ballard
 */

#ifndef __CCP4_LIB_FILE
#define __CCP4_LIB_FILE

#include "ccp4_sysdep.h"
#include "ccp4_types.h"

#ifdef __cplusplus
namespace CCP4 {
extern "C" {
#endif

/** Generic CCP4 file. */
typedef struct _CFileStruct CCP4File;

struct _CFileStruct {
  char *name;
  FILE *stream;
  int fd;
  unsigned int read : 1;
  unsigned int write : 1;
  unsigned int append : 1;
  unsigned int binary : 1;
  unsigned int scratch : 1 , : 3;
  unsigned int buffered : 1;
  unsigned int sync : 1, : 6;
  unsigned int direct : 1, : 7;
  unsigned int open : 1;
  unsigned int own : 1;
  unsigned int last_op : 2;
  unsigned int getbuff : 1, : 4;
  int iostat;
  unsigned int mode : 8;
  unsigned int itemsize : 8;
  unsigned int iconvert : 8;
  unsigned int fconvert: 8;
  off_t length;
  off_t loc;
  size_t stamp_loc;
  int (*_read) (CCP4File *, uint8 *, size_t);
  int (*_write) (CCP4File *, const uint8 *, size_t);
  char buff[8];
  void *priv;
};


CCP4File *ccp4_file_open (const char *, const int);

CCP4File *ccp4_file_open_file (const FILE *, const int);

CCP4File *ccp4_file_open_fd (const int, const int);

int ccp4_file_rarch ( CCP4File*);

int ccp4_file_warch ( CCP4File*);

int ccp4_file_close ( CCP4File*);

int ccp4_file_mode ( const CCP4File*);

int ccp4_file_setmode ( CCP4File*, const int);

int ccp4_file_setstamp( CCP4File *, const size_t);

int ccp4_file_itemsize( const CCP4File*);

int ccp4_file_setbyte( CCP4File *, const int);

int ccp4_file_byteorder( CCP4File *);

int ccp4_file_is_write(const CCP4File *);

int ccp4_file_is_read(const CCP4File *);

int ccp4_file_is_append(const CCP4File *);

int ccp4_file_is_scratch(const CCP4File *);

int ccp4_file_is_buffered(const CCP4File *);

int ccp4_file_status(const CCP4File *);

const char *ccp4_file_name( CCP4File *);

int ccp4_file_read ( CCP4File*, uint8 *, size_t);

int ccp4_file_readcomp ( CCP4File*, uint8 *, size_t);

int ccp4_file_readshortcomp ( CCP4File*, uint8 *, size_t);

int ccp4_file_readfloat ( CCP4File*, uint8 *, size_t);

int ccp4_file_readint ( CCP4File*, uint8 *, size_t);

int ccp4_file_readshort ( CCP4File*, uint8 *, size_t);

int ccp4_file_readchar ( CCP4File*, uint8 *, size_t);

int ccp4_file_write ( CCP4File*, const uint8 *, size_t);

int ccp4_file_writecomp ( CCP4File*, const uint8 *, size_t);

int ccp4_file_writeshortcomp ( CCP4File*, const uint8 *, size_t);

int ccp4_file_writefloat ( CCP4File*, const uint8 *, size_t);

int ccp4_file_writeint ( CCP4File*, const uint8 *, size_t);

int ccp4_file_writeshort ( CCP4File*, const uint8 *, size_t);

int ccp4_file_writechar ( CCP4File*, const uint8 *, size_t);

int ccp4_file_seek ( CCP4File*, long, int);

void ccp4_file_rewind ( CCP4File*);

void ccp4_file_flush (CCP4File *);

long ccp4_file_length ( CCP4File*);

long ccp4_file_tell ( CCP4File*);

int ccp4_file_feof(CCP4File *);

void ccp4_file_clearerr(CCP4File *);

void ccp4_file_fatal (CCP4File *, char *);

char *ccp4_file_print(CCP4File *, char *, char *);

int ccp4_file_raw_seek( CCP4File *, long, int);
int ccp4_file_raw_read ( CCP4File*, char *, size_t);
int ccp4_file_raw_write ( CCP4File*, const char *, size_t);
int ccp4_file_raw_setstamp( CCP4File *, const size_t);
#ifdef __cplusplus
}
}
#endif

#endif  /* __CCP4_LIB_FILE */
