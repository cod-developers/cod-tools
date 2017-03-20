/*-------------------------------------------------------------------------*\
* $Author$
* $Date$ 
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

/* exports: */
#include <cif_compiler.h>

/* uses: */
#include <string.h>
#include <common.h>
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

static
void output_message( CIF_COMPILER *cif_cc, const char *errlevel,
                     const char *message, const char *suffix,
                     int line, int position )
{
    extern char *progname;

    char *datablock = NULL;
    if( cif_compiler_cif( cif_cc ) &&
        cif_last_datablock( cif_compiler_cif( cif_cc ) ) && 
        strlen( datablock_name( cif_last_datablock( cif_compiler_cif( cif_cc ) ) ) ) > 0 ) {
        datablock = datablock_name( cif_last_datablock( cif_compiler_cif( cif_cc ) ) );
    }

    fflush(NULL);
    if( progname && strlen( progname ) > 0 ) {
        fprintf_escaped( progname, 0, 1 );
        fprintf( stderr, ": " );
        fprintf_escaped( cif_compiler_filename( cif_cc ) ?
                         cif_compiler_filename( cif_cc ) : "-", 1, 1 );
    }
    if( line != -1 ) {
        fprintf( stderr, "(%d", line );
        if( position != -1 ) {
            fprintf( stderr, ",%d", position );
        }
        fprintf( stderr, ")" );
    }
    if( datablock ) {
        fprintf( stderr, " data_" );
        fprintf_escaped( datablock, 0, 1 );
    }
    fprintf( stderr, ": %s, ", errlevel );
    fprintf_escaped( message, 0, 0 );
    fprintf( stderr, "%s\n", suffix );
    fflush(NULL);
}

void print_message( CIF_COMPILER *cif_cc, const char *errlevel,
                    const char *message,
                    const char *suffix, /* ":" or "", depending on the
                                           subsequent citation or not of the
                                           code line. S.G. */
                    int line, int position, cexception_t *ex )
{
    if( !isset_suppress_messages( cif_cc ) ) {
        output_message( cif_cc, errlevel, message, suffix, line, position );
    }
    if( cif_compiler_cif( cif_cc ) ) {
        char *datablock = NULL;
        if( cif_compiler_cif( cif_cc ) && cif_last_datablock( cif_compiler_cif( cif_cc ) ) && 
            strlen( datablock_name( cif_last_datablock( cif_compiler_cif( cif_cc ) ))) > 0 ) {
            datablock = datablock_name( cif_last_datablock( cif_compiler_cif( cif_cc ) ) );
        }
        cif_insert_message
            ( cif_compiler_cif( cif_cc ),
              new_cifmessage_from_data
              ( /* next = */ cif_messages( cif_compiler_cif( cif_cc ) ),
                /* progname = */ NULL,
                /* filename = */ cif_compiler_filename( cif_cc ) ?
                                 cif_compiler_filename( cif_cc ) : "-",
                line, position,
                /* addPos = */ datablock,
                /* status = */ (char*)errlevel,
                /* message = */ (char*)message,
                /* explanation = */ NULL,
                /* separator = */ NULL,
                ex )
            );
    }
}

void print_current_text_field( CIF_COMPILER *cif_cc, char *text, cexception_t *ex )
{
    if( !isset_suppress_messages( cif_cc ) ) {
        ssize_t length = strlen( text ) + countchars( '\n', text ) + 1;
        char *prefixed = length > 0 ? mallocx( length, ex ) : NULL;
        char *p = prefixed, *t = text;
        if( p ) {
            while( t && *t ) {
                if( *t == '\n' ) {
                    *p++ = '\n';
                    *p = ' ';
                } else {
                    *p = *t;
                }
                t++; p++;
            }
            *p = '\0';
        }
        fflush(NULL);
        fprintf( stderr, " ;%s\n ;\n\n", prefixed );
        fflush(NULL);
        if( prefixed ) freex( prefixed );
    }
    if( cif_compiler_cif( cif_cc ) ) {
        CIFMESSAGE *current_message = cif_messages( cif_compiler_cif( cif_cc ) );
        assert( current_message );

        char *buf = mallocx( strlen(text) + 5, ex );
        sprintf( buf, ";%s\n;\n", text );
        cifmessage_set_line( current_message, buf, ex );
        if( buf ) freex( buf );
    }
}

void print_trace( CIF_COMPILER *cif_cc, char *line, int position, cexception_t *ex )
{
    if( !isset_suppress_messages( cif_cc ) ) {
        fflush(NULL);
        fprintf( stderr, " %s\n %*s\n",
                 line, position, "^" );
        fflush(NULL);
    }
    if( cif_compiler_cif( cif_cc ) ) {
        CIFMESSAGE *current_message = cif_messages( cif_compiler_cif( cif_cc ) );
        assert( current_message );
        cifmessage_set_line( current_message, line, ex );
    }
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
