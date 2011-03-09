/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

/* exports: */
#include <common.h>

/* uses: */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define merror( s ) \
if( (s) == NULL ) \
   { \
     printf("Out of memory in file %s at line %d\n", __FILE__, __LINE__); \
     exit(99); \
   }

char *strclone( const char *s )
{
   char *new;
   merror( new = strdup(s) );
   return new;
}

char *strnclone( const char *s, size_t length )
{
   char *new;
   merror( new = malloc(length + 1) );
   strncpy( new, s, length );
   new[length] = '\0';
   return new;
}

char *strappend( char *s, const char *suffix )
{
   ssize_t s_length = strlen(s);
   ssize_t suffix_length = strlen(suffix);
   char *new;
   merror( new = realloc(s, s_length + suffix_length + 1) );
   strcpy( new + s_length, suffix );
   new[s_length+suffix_length] = '\0';
   return new;
}

char translate_escape( char **s )
{
    switch( *(++(*s)) ) {
        case '0': return (char)strtol(*s, s, 0); break;
        case 'b': return '\b';
        case 'n': return '\n';
        case 'r': return '\r';
        case 't': return '\t';
        default : return **s;
    }
    return '\0';
}

char *process_escapes( char *str )
{
   char *s, *d;

   /* s scans the string, d points to the destination where we write 
      decoded escape sequences */
   for( d = s = str; *s != '\0'; s++, d++ ) {
      if( *s == '\\' ) {
          switch( *(++s) ) {
	      case '0': *d = (char)strtol(s, &s, 0); s--; break;
              case 'b': *d = '\b'; break;
              case 'n': *d = '\n'; break;
              case 'r': *d = '\r'; break;
              case 't': *d = '\t'; break;
	      default : *d = *s; break;
          }
      } else {
          *d = *s;
      }
   }
   *d = *s;
   return str;
}
