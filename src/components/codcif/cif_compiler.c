/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

/* exports: */
#include <cif_compiler.h>

/* uses: */
#include <cif_lexer.h>

typedef struct CIF_COMPILER {
    char *filename;
    CIF *cif;
    cif_option_t options;
} CIF_COMPILER;

void delete_cif_compiler( CIF_COMPILER *c )
{
    if( c ) {
        if( c->filename ) free( c->filename );
        if( c->cif ) delete_cif( c->cif );
        free( c );
    }
}

CIF_COMPILER *new_cif_compiler( char *filename,
                                       cif_option_t co,
                                       cexception_t *ex )
{
    cexception_t inner;
    CIF_COMPILER *cc = callocx( 1, sizeof(CIF_COMPILER), ex );

    cexception_guard( inner ) {
        cc->options  = co;
        if( filename ) {
            cc->filename = strdupx( filename, &inner );
        }
        cc->cif = new_cif( &inner );
    }
    cexception_catch {
        delete_cif_compiler( cc );
        cexception_reraise( inner, ex );
    }
    return cc;
}

char *cif_compiler_filename( CIF_COMPILER *ccc )
{
    return ccc->filename;
}

CIF *cif_compiler_cif( CIF_COMPILER *ccc )
{
    return ccc->cif;
}

void cif_compiler_detach_cif( CIF_COMPILER *ccc )
{
    ccc->cif = NULL;
}

void assert_datablock_exists( CIF_COMPILER *ccc, cexception_t *ex )
{
    if( cif_last_datablock( ccc->cif ) == NULL ) {
        cif_start_datablock( ccc->cif, "", ex );
    }
}

int isset_do_not_unprefix_text( CIF_COMPILER *ccc )
{
    cif_option_t copt = DO_NOT_UNPREFIX_TEXT;
    assert( ccc ); return ( ( ccc->options & copt ) != 0 );
}

int isset_do_not_unfold_text( CIF_COMPILER *ccc )
{
    cif_option_t copt = DO_NOT_UNFOLD_TEXT;
    assert( ccc ); return ( ( ccc->options & copt ) != 0 );
}

int isset_fix_errors( CIF_COMPILER *ccc )
{
    cif_option_t copt = FIX_ERRORS;
    assert( ccc ); return ( ( ccc->options & copt ) != 0 );
}

int isset_fix_duplicate_tags_with_same_values( CIF_COMPILER *ccc )
{
    cif_option_t copt = FIX_DUPLICATE_TAGS_WITH_SAME_VALUES;
    assert( ccc ); return ( ( ccc->options & copt ) != 0 );
}

int isset_fix_duplicate_tags_with_empty_values( CIF_COMPILER *ccc )
{
    cif_option_t copt = FIX_DUPLICATE_TAGS_WITH_EMPTY_VALUES;
    assert( ccc ); return ( ( ccc->options & copt ) != 0 );
}

int isset_fix_data_header( CIF_COMPILER *ccc )
{
    cif_option_t copt = FIX_DATA_HEADER;
    assert( ccc ); return ( ( ccc->options & copt ) != 0 );
}

int isset_fix_datablock_names( CIF_COMPILER *ccc )
{
    cif_option_t copt = FIX_DATABLOCK_NAMES;
    assert( ccc ); return ( ( ccc->options & copt ) != 0 );
}

int isset_fix_string_quotes( CIF_COMPILER *ccc )
{
    cif_option_t copt = FIX_STRING_QUOTES;
    assert( ccc ); return ( ( ccc->options & copt ) != 0 );
}

int isset_suppress_messages( CIF_COMPILER *ccc )
{
    cif_option_t copt = CO_SUPPRESS_MESSAGES;
    assert( ccc ); return ( ( ccc->options & copt ) != 0 );
}

typedef struct typed_value {
    int vline;
    int vpos;
    char *vcont;
    VALUE *v;
} typed_value;

void delete_typed_value( typed_value *t )
{
    if( t->vcont != NULL ) {
        freex( t->vcont );
    }
    if( t->v != NULL ) {
        delete_value( t->v );
    }
    freex( t );
}

typed_value *new_typed_value( int vline, int vpos, char *vcont, VALUE *v ) {
    typed_value *tv = malloc( sizeof( typed_value ) );
    if( vline == -1 )
        vline = cif_flex_current_line_number();
    if( vpos == -1 )
        vpos = cif_flex_current_position();
    tv->vline = vline;
    tv->vpos = vpos;
    tv->vcont = vcont;
    tv->v = v;
    return tv;
}

int typed_value_line( typed_value *t )
{
    return t->vline;
}

int typed_value_pos( typed_value *t )
{
    return t->vpos;
}

char *typed_value_content( typed_value *t )
{
    return t->vcont;
}

VALUE *typed_value_value( typed_value *t )
{
    return t->v;
}

void typed_value_detach_value( typed_value *t )
{
    t->v = NULL;
}

void typed_value_detach_content( typed_value *t )
{
    t->vcont = NULL;
}

void typed_value_set_value( typed_value *t, VALUE *v )
{
    t->v = v;
}
