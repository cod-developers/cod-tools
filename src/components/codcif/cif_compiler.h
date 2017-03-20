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

typedef struct CIF_COMPILER CIF_COMPILER;

static CIF_COMPILER *new_cif_compiler( char *filename,
                                       cif_option_t co,
                                       cexception_t *ex );

static void delete_cif_compiler( CIF_COMPILER *c );

int isset_do_not_unprefix_text( CIF_COMPILER *co );
int isset_do_not_unfold_text( CIF_COMPILER *co );
int isset_fix_errors( CIF_COMPILER *co );
int isset_fix_duplicate_tags_with_same_values( CIF_COMPILER *co );
int isset_fix_duplicate_tags_with_empty_values( CIF_COMPILER *co );
int isset_fix_data_header( CIF_COMPILER *co );
int isset_fix_datablock_names( CIF_COMPILER *co );
int isset_fix_string_quotes( CIF_COMPILER *co );

#endif
