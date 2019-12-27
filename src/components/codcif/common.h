/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#ifndef __COMMON_H
#define __COMMON_H

#include <unistd.h>
#include <math.h>
#include <cexceptions.h>
#include <cif_compiler.h>

ssize_t countchars( char c, char *s );

int starts_with_keyword( char *keyword, char *string );
int is_integer( char *s );
int is_real( char *s );
int is_cif_space( char c );

char *cif_unprefix_textfield( char *tf );
char *cif_unfold_textfield( char *tf );
char *clean_string( char *src, int is_textfield, CIF_COMPILER *cif_cc, cexception_t *ex );
int is_tag_value_unknown( char *tv );

void fprintf_escaped( const char *message,
                      int escape_parenthesis, int escape_space );

double unpack_precision( char * value, double precision );

#endif
