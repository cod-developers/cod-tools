/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#ifndef __CIF_COMPILER_H
#define __CIF_COMPILER_H

#include <assert.h>
#include <allocx.h>
#include <stringx.h>
#include <cexceptions.h>
#include <cif_options.h>
#include <cif.h>
#include <cifvalue.h>

typedef struct CIF_COMPILER CIF_COMPILER;

CIF_COMPILER *new_cif_compiler( char *filename,
                                       cif_option_t co,
                                       cexception_t *ex );

void delete_cif_compiler( CIF_COMPILER *c );

char *cif_compiler_filename( CIF_COMPILER *ccc );
CIF *cif_compiler_cif( CIF_COMPILER *ccc );
FILE *cif_compiler_file( CIF_COMPILER *ccc );
int cif_compiler_nerrors( CIF_COMPILER *ccc );
int cif_compiler_loop_tag_count( CIF_COMPILER *ccc );
int cif_compiler_loop_value_count( CIF_COMPILER *ccc );
int cif_compiler_loop_start_line( CIF_COMPILER *ccc );

void cif_compiler_set_file( CIF_COMPILER *ccc, FILE *file );
void cif_compiler_detach_cif( CIF_COMPILER *ccc );
void cif_compiler_increase_nerrors( CIF_COMPILER *ccc );
void cif_compiler_increase_nwarnings( CIF_COMPILER *ccc );
void cif_compiler_increase_nnotes( CIF_COMPILER *ccc );
void cif_compiler_increase_loop_tags( CIF_COMPILER *ccc );
void cif_compiler_increase_loop_values( CIF_COMPILER *ccc );

void cif_compiler_start_loop( CIF_COMPILER *ccc, int line );

void assert_datablock_exists( CIF_COMPILER *ccc, cexception_t *ex );

int isset_do_not_unprefix_text( CIF_COMPILER *co );
int isset_do_not_unfold_text( CIF_COMPILER *co );
int isset_fix_errors( CIF_COMPILER *co );
int isset_fix_duplicate_tags_with_same_values( CIF_COMPILER *co );
int isset_fix_duplicate_tags_with_empty_values( CIF_COMPILER *co );
int isset_fix_data_header( CIF_COMPILER *co );
int isset_fix_datablock_names( CIF_COMPILER *co );
int isset_fix_string_quotes( CIF_COMPILER *co );
int isset_suppress_messages( CIF_COMPILER *co );

void print_message( CIF_COMPILER *cif_cc, const char *errlevel, const char *message,
                    const char *suffix, /* ":" or "", depending on the
                                           subsequent citation or not of the
                                           code line. S.G. */
                    int line, int position, cexception_t *ex );
void print_current_text_field( CIF_COMPILER *cif_cc, char *text, cexception_t *ex );
void print_trace( CIF_COMPILER *cif_cc, char *line, int position, cexception_t *ex );

int yyerror_token( CIF_COMPILER *cif_cc, const char *message,
                   int line, int pos, char *cont, cexception_t *ex );
int yywarning_token( CIF_COMPILER *cif_cc, const char *message,
                     int line, int pos, cexception_t *ex );
int yynote_token( CIF_COMPILER *cif_cc, const char *message,
                  int line, int pos, cexception_t *ex );

typedef struct typed_value typed_value;

typed_value *new_typed_value( int vline, int vpos, char *vcont, CIFVALUE *v );

void delete_typed_value( typed_value *t );

void typed_value_detach_value( typed_value *t );
void typed_value_detach_content( typed_value *t );

int typed_value_line( typed_value *t );
int typed_value_pos( typed_value *t );
char *typed_value_content( typed_value *t );
CIFVALUE *typed_value_value( typed_value *t );

void typed_value_set_value( typed_value *t, CIFVALUE *v );

void add_tag_value( CIF_COMPILER *cif_cc, char *tag,
                    typed_value *tv, cexception_t *ex );

CIF *new_cif_from_cif_file( char *filename, cif_option_t co, cexception_t *ex );
CIF *new_cif_from_cif_string( char *buffer, cif_option_t co, cexception_t *ex );

#endif
