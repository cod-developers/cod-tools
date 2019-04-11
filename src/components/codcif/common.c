/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

/* exports: */
#include <common.h>

/* uses: */
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

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

int starts_with_keyword( char *keyword, char *string )
{
    size_t length1 = strlen( keyword );
    size_t length2 = strlen( string );
    size_t length = length1 < length2 ? length1 : length2;

    if( length < length1 )
        return 0;

    while( length-- > 0 ) {
        if( *keyword++ != tolower(*string++) ) {
            return 0;
        }
    }
    return 1;
}

int is_integer( char *s )
{
    int has_opening_brace = 0;

    if( !s ) return 0;

    if( !isdigit(*s) && *s != '+' && *s != '-' ) {
        return 0;
    }

    if( *s == '+' || *s == '-' ) s++;

    if( !isdigit(*s) ) return 0;

    while( *s && *s != '(' ) {
        if( !isdigit(*s++) ) {
            return 0;
        }
    }

    if( *s && *s != '(' ) return 0;
    if( *s && *s == '(' ) {
        s++;
        has_opening_brace = 1;
    }

    while( *s && *s != ')' ) {
        if( !isdigit(*s++) ) {
            return 0;
        }        
    }

    if( *s != ')' && has_opening_brace ) return 0;
    if( *s == ')' ) s++;

    if( *s != '\0' ) return 0;

    return 1;
}

int is_real( char *s )
{
    int has_decimal = 0, has_digits = 0;

    if( !s || !*s ) return 0;

    if( !isdigit(*s) && *s != '+' && *s != '-' && *s != '.' ) {
        return 0;
    }

    if( *s == '+' || *s == '-' ) s++;

    /* decimal point may follow the sign, as in +.0123 */
    if( *s == '.' ) {
        s ++;
        has_decimal = 1;
    }

    if( !isdigit(*s) ) return 0;

    while( isdigit(*s) ) {
        s++;
        has_digits = 1;
    }

    if( *s == '.' ) {
        if( has_decimal ) {
            return 0;
        } else {
            has_decimal = 1;
            s ++;
        }
    }

    while( isdigit(*s) ) {
        s++;
        has_digits = 1;
    }

    if( !has_digits ) return 0;

    /* By now, of we have seen digits and the string has ended, we
       accept reg real number. We could insist here that we have a
       decimal point so that integers are not counte das reals, but
       since integer will be checked before reals we can happily
       accept integers as reals as well (which is mathematically more
       correct ;): */
    if( *s == '\0' ) return 1;

    if( *s != '(' &&
        *s != 'E' && *s != 'e' ) {
        return 0;
    }

    if( *s == 'E' || *s == 'e' ) {
        s ++;
        if( *s == '+' || *s == '-' ) s++;
        if( !isdigit(*s) ) {
            return 0;
        }
        while( isdigit(*s) ) s++;
    }

    if( *s == '\0' ) return 1;
    if( *s != '(' )
        return 0;
    else
        s++;
    if( !isdigit(*s) ) return 0;
    while( isdigit(*s) ) s++;
    if( *s != ')' ) return 0;
    s++;
    if( *s != '\0' ) return 0;

    return 1;
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

char * cif_unfold_textfield( char * tf )
{
    int length = strlen(tf);
    char * unfolded = malloc( (length + 1) * sizeof( char ) );
    char * src = tf;
    char * dest = unfolded;
    char * backslash = NULL;
    while(  src[0] != '\0' ) {
        if( src[0] == '\\' ) {
            /* memorize the position of the last backslash in the
             * field */
            if( backslash ) {
                dest[0] = '\\';
                dest++;
            }
            backslash = src;
            src++;
        } else if( backslash && ( src[0] == ' ' || src[0] == '\t' ) ) {
            /* if a backslash is seen, trailing space has to be
             * skipped */
            src++;
        } else if( backslash && src[0] == '\n' ) {
            /* if no non-space symbols are found after the backslash,
             * line ending is ignored */
            backslash = NULL;
            src++;
        } else {
            if( backslash ) {
                /* if a non-space symbol is found after the backslash,
                 * the backslash is forgotten and old position is
                 * restored */
                src = backslash;
                backslash = NULL;
            }
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

double unpack_precision( char * value, double precision ) {
    const char *p = value;

    /* Skipping everything until the decimal dot: */
    while( *p && *p != '.' ) { p++; }
    if( *p == '.' ) { p++; }

    /* Collecting mantissa, if any: */
    int mantissa_length = 0;
    while( *p && *p >= 48 && *p <= 57 ) {
        mantissa_length ++;
        p++;
    }
    precision /= pow( 10, mantissa_length );

    /* Collecting exponent part, if any: */
    if( *p == 'e' || *p == 'E' ) {
        int exponent = 1;
        p++;

        if( *p == '-' ) { exponent = -1; }
        if( *p == '-' || *p == '+' ) { p++; }

        while( *p && *p >= 48 && *p <= 57 ) {
            exponent *= *p - 48;
            p++;
        }
        precision *= pow( 10, exponent );
    }

    return precision;
}
