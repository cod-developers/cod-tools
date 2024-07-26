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
#include <allocx.h>
#include <cif_grammar_flex.h>
#include <cif_lex_buffer.h>

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
    if( !string )
        return 0;

    size_t length = strlen( keyword );
    while( length-- > 0 ) {
        if( *keyword++ != tolower(*string++) )
            return 0;
    }

    return 1;
}

int is_integer( char *s )
{
    if( !s ) return 0;
    if( !isdigit(*s) && *s != '+' && *s != '-' ) {
        return 0;
    }

    if( *s == '+' || *s == '-' ) s++;

    if( !isdigit(*s) ) return 0;
    s++;

    while( isdigit(*s) ) s++;
    if( *s == '\0' ) return 1;

    // Detect the optional trailing standard uncertainty value "(\d+)"
    if( *s != '(' ) return 0;
    s++;
    if( !isdigit(*s) ) { return 0; };
    s++;
    while( isdigit(*s) ) s++;
    if( *s != ')' ) return 0;
    s++;
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
       decimal point so that integers are not counted as reals, but
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

int is_cif_space( char c ) {
    if( c ==  ' ' ) return 1;
    if( c == '\t' ) return 1;
    if( c == '\n' ) return 1;
    if( c == '\r' ) return 1;

    return 0;
}

char *cif_unprefix_textfield( char *tf )
{
    size_t length = strlen( tf );
    char * next_backslash = strchr( tf, '\\' );
    char * next_newline   = strchr( tf, '\n' );
    int is_prefix = 0;
    size_t prefix_length = 0;
    if( next_backslash != NULL &&
        next_newline   != NULL &&
        next_backslash != tf &&
        next_backslash < next_newline ) {
        is_prefix = 1;
        prefix_length = next_backslash - tf;
    }

    // Ensure the prefix is followed by in-line whitespace characters
    if( is_prefix ) {
        char *i = next_backslash + 1;
        if( *i == '\\' ) i++;
        while( i < next_newline ) {
            if( !is_cif_space( *i ) ) {
                is_prefix = 0;
                break;
            }
            i++;
        }
    }

    if( !is_prefix ) {
        // No unprefixing needed, return plain copy
        char * unprefixed = malloc( (length + 1) * sizeof( char ) );
        strcpy( unprefixed, tf );
        return unprefixed;
    }

    char prefix[prefix_length+1];
    strncpy( prefix, tf, prefix_length );
    char * unprefixed = malloc( (length + 1) * sizeof( char ) );
    unprefixed[0] = '\0';

    // Transfer the remainder of the first line in the textfield if
    // double backslash is seen:
    if( next_backslash[1] == '\\' ) {
        strncat( unprefixed, next_backslash + 1, next_newline - next_backslash );
    } else {
        unprefixed[0] = '\n';
        unprefixed[1] = '\0';
    }

    // Ensure every line starts with the same prefix. At the same time
    // perform unprefixing until an unprefixed line appears.
    while( next_newline != NULL ) {
        char * line_start = next_newline + 1;
        if( strncmp( line_start, prefix, prefix_length ) ) {
            is_prefix = 0;
            break;
        }
        next_newline = strchr( line_start, '\n' );
        strncat( unprefixed,
                 line_start + prefix_length,
                 next_newline - line_start - prefix_length + 1 );
    }

    // Unprefixed line found, copied textfield should be returned instead
    if( !is_prefix ) {
        strcpy( unprefixed, tf );
    }

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

char *clean_string( char *src, int is_textfield, CIF_COMPILER *cif_cc, cexception_t *ex )
{
    int DELTA = 8;
    ssize_t length = strlen( src );
    char *volatile new = mallocx( length + 1, ex );
    char *dest = new;
    char *start = src;
    int non_ascii_explained = 0;

    cexception_t inner;
    cexception_guard( inner ) {
        while( *src != '\0' ) {
            if( ( (*src & 255 ) < 32 || (*src & 255 ) == 127 ||
                ( !cif_lexer_has_flags(CIF_FLEX_LEXER_ALLOW_HIGH_CHARS) &&
                  (*src & 255 ) > 127 ) )
                && (*src & 255 ) != '\n'
                && (*src & 255 ) != '\t'
                && (*src & 255 ) != '\r' ) {
                if( cif_lexer_has_flags
                (CIF_FLEX_LEXER_FIX_NON_ASCII_SYMBOLS)) {
                    /* Do magic with non-ASCII symbols */
                    *dest = '\0';
                    length += DELTA;
                    new = reallocx( new, length + 1, &inner );
                    dest = new + strlen( new );
                    sprintf( dest, "&#x%04X;", *src & 255 );
                    dest += DELTA - 1;
                    if( non_ascii_explained == 0 ) {
                        if( is_textfield == 0 ) {
                            print_message( cif_cc, "WARNING", "non-ASCII symbols "
                                           "encountered in the text", ":",
                                           cif_flex_current_line_number(),
                                           cif_flex_current_position()+1,
                                           ex );
                            print_trace( cif_cc, (char*)cif_flex_current_line(),
                                         cif_flex_current_position()+1, ex );
                        } else {
                            print_message( cif_cc, "WARNING", "non-ASCII symbols "
                                           "encountered in the text field -- "
                                           "replaced with XML entities", ":",
                                           cif_flex_current_line_number(),
                                           -1, ex );
                            print_current_text_field( cif_cc, start, ex );
                        }
                        non_ascii_explained = 1;
                    }
                } else {
                    if( non_ascii_explained == 0 ) {
                        if( is_textfield == 0 ) {
                            print_message( cif_cc, "ERROR", "incorrect CIF syntax", ":",
                                           cif_flex_current_line_number(),
                                           cif_flex_current_position()+1, ex );
                            print_trace( cif_cc, (char*)cif_flex_current_line(),
                                         cif_flex_current_position()+1, ex );
                            cif_compiler_increase_nerrors( cif_cc );
                        } else {
                            print_message( cif_cc, "ERROR", "non-ASCII symbols "
                                           "encountered "
                                           "in the text field", ":",
                                           cif_flex_current_line_number(),
                                           -1, ex );
                            print_current_text_field( cif_cc, start, ex );
                            cif_compiler_increase_nerrors( cif_cc );
                        }
                        non_ascii_explained = 1;
                    }
                    dest--; /* Omit non-ASCII symbols */
                }
            } else if( (*src & 255) == '\r' ) {
                dest--; /* Skip carriage return symbols */
            } else {
                *dest = *src;
            }
            src++;
            dest++;
        }
    }
    cexception_catch {
        freex( new );
        cexception_reraise( inner, ex );
    }
    *dest = '\0';
    return new;
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

    /* Skip everything until the decimal dot: */
    while( *p && *p != '.' ) { p++; }
    if( *p == '.' ) { p++; }

    /* Collect mantissa, if any: */
    int mantissa_length = 0;
    while( *p && *p >= 48 && *p <= 57 ) {
        mantissa_length ++;
        p++;
    }
    precision /= pow( 10, mantissa_length );

    /* Collect exponent part, if any: */
    if( *p == 'e' || *p == 'E' ) {
        p++;

        int sign = 1;
        if( *p == '-' ) { sign = -1; }
        if( *p == '-' || *p == '+' ) { p++; }

        int exponent = 1;
        if( *p && *p >= 48 && *p <= 57 ) {
            exponent *= *p - 48;
            p++;
            while( *p && *p >= 48 && *p <= 57 ) {
                exponent = exponent * 10 + ( *p - 48 );
                p++;
            }
        }
        precision *= pow( 10, sign * exponent );
    }

    return precision;
}
