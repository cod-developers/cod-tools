/*---------------------------------------------------------------------------*\
**$Author$
**$Date$ 
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

#ifndef __CIF_GRAMMAR_Y_H
#define __CIF_GRAMMAR_Y_H

#include <cif.h>
#include <cif_options.h>
#include <cexceptions.h>

CIF *new_cif_from_cif_file( char *filename, cif_option_t co,
                            cexception_t *ex );

void cif_printf( cexception_t *ex, char *format, ... );
char * cif_unprefix_textfield( char * tf );
char * cif_unfold_textfield( char * tf );

void print_message( const char *errlevel, const char *message, 
                    const char *suffix, int line,
                    int position, cexception_t *ex );
void print_current_text_field( char *text, cexception_t *ex );
void print_trace( char *line, int position, cexception_t *ex );
void yyincrease_error_counter( void );

int is_tag_value_unknown( char * tv );

int cif_yy_error_number( void );
void cif_yy_reset_error_count( void );

void cif_yy_debug_on( void );
void cif_yy_debug_off( void );

typedef struct typed_value typed_value;
typedef struct typed_value {
    char *vstr;
    cif_value_type_t vtype;
    int vline;
    int vpos;
    char *vcont;
    typed_value *vnext;
    typed_value *vinner;
    ssize_t vlength;
    ssize_t vcapacity;
    char **vkeys;
    typed_value **vvalues;
} typed_value;

#endif
