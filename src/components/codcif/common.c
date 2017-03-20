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


/* FIXME: use exceptions or return NULL pointers and check in
   strclone() and its clones: */
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

ssize_t countchars( char c, char *s )
{
    ssize_t sum = 0;

    if( !s || !*s ) return 0;
    while( *s ) {
        if( *s++ == c ) sum ++;
    }
    return sum;
}

char *cif_unprefix_textfield( char *tf )
{
    int length = strlen(tf);
    char * unprefixed = malloc( (length + 1) * sizeof( char ) );
    char * src = tf;
    char * dest = unprefixed;
    int prefix_length = 0;
    int is_prefix = 0;
    while(  src[0] != '\n' && src[0] != '\0' ) {
        if( src[0] != '\\' ) {
            prefix_length++;
            dest[0] = src[0];
            src++;
            dest++;
        } else {
            if( prefix_length > 0 &&
                ( src[1] == '\n' ||
                    ( src[1] == '\\' && src[2] == '\n' ) ) ) {
                is_prefix = 1;
                dest = unprefixed;
            } else {
                dest[0] = src[0];
                dest++;
            }
            src++;
            break;
        }
    }
    int unprefix_line =  is_prefix;
    int line_offset   = -1;
    while(  src[0] != '\0' ) {
        if( src[0] == '\n' ) {
            line_offset = -1;
            unprefix_line = is_prefix;
        }
        if( line_offset >= 0 && line_offset < prefix_length
            && unprefix_line == 1 ) {
            if( src[0] == tf[line_offset] ) {
                line_offset++;
                src++;
            } else {
                src-=line_offset;
                unprefix_line =  0;
                line_offset   = -1;
            }
        } else {
            dest[0] = src[0];
            src++;
            dest++;
            line_offset++;
        }
    }
    dest[0] = '\0';
    return unprefixed;
}

char *cif_unfold_textfield( char *tf )
{
    int length = strlen(tf);
    char * unfolded = malloc( (length + 1) * sizeof( char ) );
    char * src = tf;
    char * dest = unfolded;
    while(  src[0] != '\0' ) {
        if( src[0] == '\\' && src[1] == '\n' ) {
            src+=2;
        } else {
            dest[0] = src[0];
            src++;
            dest++;
        }
    }
    dest[0] = '\0';
    return unfolded;
}

int is_tag_value_unknown( char *tv )
{
    int question_mark = 0;
    char * iter = tv;
    while(  iter[0] != '\0' ) {
        if( iter[0] ==  '?' ) {
            question_mark = 1;
        } else if( iter[0] != ' '  &&
                   iter[0] != '\t' &&
                   iter[0] != '\r' &&
                   iter[0] != '\n' ) {
            return 0;
        }
        iter++;
    }
    return question_mark;
}

void fprintf_escaped( const char *message,
                      int escape_parenthesis, int escape_space ) {
    const char *p = message;
    while( *p ) {
        switch( *p ) {
            case '&':
                fprintf( stderr, "&amp;" );
                break;
            case ':':
                fprintf( stderr, "&colon;" );
                break;
            default:
                if(        *p == '(' && escape_parenthesis != 0 ) {
                    fprintf( stderr, "&lpar;" );
                } else if( *p == ')' && escape_parenthesis != 0 ) {
                    fprintf( stderr, "&rpar;" );
                } else if( *p == ' '&& escape_space != 0 ) {
                    fprintf( stderr, "&nbsp;" );
                } else {
                    fprintf( stderr, "%c", *p );
                }
        }
        p++;
    }
}
