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
#include <cxprintf.h>
#include <stdiox.h>
#include <common.h>
#include <cif_lexer.h>
#include <cif_grammar_y.h>
#include <cif2_grammar_y.h>

typedef struct CIF_COMPILER {
    char *filename;
    CIF *cif;
    cif_option_t options;

    int errcount;
    int warncount;
    int notecount;
    
    int loop_tag_count;
    int loop_value_count;
    int loop_start;
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

int cif_compiler_nerrors( CIF_COMPILER *ccc )
{
    return ccc->errcount;
}

int cif_compiler_loop_tag_count( CIF_COMPILER *ccc )
{
    return ccc->loop_tag_count;
}

int cif_compiler_loop_value_count( CIF_COMPILER *ccc )
{
    return ccc->loop_value_count;
}

int cif_compiler_loop_start_line( CIF_COMPILER *ccc )
{
    return ccc->loop_start;
}

void cif_compiler_detach_cif( CIF_COMPILER *ccc )
{
    ccc->cif = NULL;
}

void cif_compiler_increase_nerrors( CIF_COMPILER *ccc )
{
    ccc->errcount++;
}

void cif_compiler_increase_nwarnings( CIF_COMPILER *ccc )
{
    ccc->warncount++;
}

void cif_compiler_increase_nnotes( CIF_COMPILER *ccc )
{
    ccc->notecount++;
}

void cif_compiler_increase_loop_tags( CIF_COMPILER *ccc )
{
    ccc->loop_tag_count++;
}

void cif_compiler_increase_loop_values( CIF_COMPILER *ccc )
{
    ccc->loop_value_count++;
}

void cif_compiler_start_loop( CIF_COMPILER *ccc, int line )
{
    ccc->loop_tag_count = 0;
    ccc->loop_value_count = 0;
    ccc->loop_start = line;
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

int yyerror_token( CIF_COMPILER *cif_cc, const char *message,
                   int line, int pos, char *cont, cexception_t *ex )
{
    print_message( cif_cc, "ERROR", message, ( cont == NULL ? "" : ":"),
                   line, pos, ex );
    if( cont != NULL ) {
        print_trace( cif_cc, cont, pos, ex );
    }
    cif_compiler_increase_nerrors( cif_cc );
    return 0;
}

int yywarning_token( CIF_COMPILER *cif_cc, const char *message,
                     int line, int pos, cexception_t *ex )
{
    print_message( cif_cc, "WARNING", message, "", line, pos,
                   ex );
    cif_compiler_increase_nwarnings( cif_cc );
    return 0;
}

int yynote( CIF_COMPILER *cif_cc, const char *message, cexception_t *ex )
{
    print_message( cif_cc, "NOTE", message, "", cif_flex_previous_line_number(), -1,
                   ex );
    cif_compiler_increase_nnotes( cif_cc );
    return 0;
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

typed_value *new_typed_value( int vline, int vpos, char *vcont, VALUE *v )
{
    typed_value *tv = malloc( sizeof( typed_value ) );
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

void add_tag_value( CIF_COMPILER *cif_cc, char *tag, typed_value *tv, cexception_t *ex )
{
    VALUE *value = typed_value_value( tv );
    if( cif_tag_index( cif_compiler_cif( cif_cc ), tag ) == -1 ) {
        cif_insert_value( cif_compiler_cif( cif_cc ), tag, value, ex );
    } else if( value_get_type( value ) != CIF_LIST &&
               value_get_type( value ) != CIF_TABLE ) {
        ssize_t tag_nr = cif_tag_index( cif_compiler_cif( cif_cc ), tag );
        ssize_t * value_lengths = 
            datablock_value_lengths(cif_last_datablock(cif_compiler_cif( cif_cc )));
        if( value_lengths[tag_nr] == 1) {
            if( strcmp
                (value_get_scalar(datablock_value
                 (cif_last_datablock(cif_compiler_cif( cif_cc )), tag_nr, 0)),
                  value_get_scalar(value)) == 0 &&
                (isset_fix_errors(cif_cc) == 1 ||
                 isset_fix_duplicate_tags_with_same_values
                 (cif_cc) == 1)) {
                yywarning_token( cif_cc, cxprintf( "tag %s appears more than once "
                                           "with the same value '%s'", tag,
                                            value_get_scalar(value) ),
                                 typed_value_line( tv ), -1, ex );
            } else {
                if( isset_fix_errors(cif_cc) == 1 ||
                    isset_fix_duplicate_tags_with_empty_values
                    (cif_cc) == 1 ) {
                    if( is_tag_value_unknown( value_get_scalar(value) ) ) {
                        yywarning_token( cif_cc, cxprintf( "tag %s appears more than once, "
                                                   "the second occurrence '%s' is "
                                                   "ignored", tag,
                                                   value_get_scalar(value) ),
                                         typed_value_line( tv ), -1, ex );
                    } else if( is_tag_value_unknown
                               (value_get_scalar
                                (datablock_value
                                 (cif_last_datablock(cif_compiler_cif( cif_cc )),
                                  tag_nr, 0)))) {
                        yywarning_token( cif_cc, cxprintf( "tag %s appears more than once, "
                                                   "the previous value '%s' is "
                                                   "overwritten", tag,
                                                   datablock_value
                                                   (cif_last_datablock(cif_compiler_cif( cif_cc )),
                                                   tag_nr, 0)),
                                         typed_value_line( tv ), -1, ex );
                        cif_overwrite_value( cif_compiler_cif( cif_cc ), tag_nr, 0,
                                             value, ex );
                    } else {
                        yyerror_token( cif_cc, cxprintf( "tag %s appears more than once", tag ),
                                       typed_value_line( tv ), -1, NULL, ex );
                    }
                } else {
                    yyerror_token( cif_cc, cxprintf( "tag %s appears more than once", tag ),
                                   typed_value_line( tv ), -1, NULL, ex );
                }
            }
        } else {
            yyerror_token( cif_cc, cxprintf( "tag %s appears more than once", tag ),
                           typed_value_line( tv ), -1, NULL, ex );
        }
    } else {
        yyerror_token( cif_cc, cxprintf( "tag %s appears more than once", tag ),
                       typed_value_line( tv ), -1, NULL, ex );
    }
}

CIF *new_cif_from_cif_file( char *filename, cif_option_t co, cexception_t *ex )
{
    cexception_t inner;
    FILE *in;

    cexception_guard( inner ) {
        if( filename ) {
            in = fopenx( filename, "r", ex );
        } else {
            in = stdin;
        }
    }
    cexception_catch {
        if( in ) {
            fclosex( in, ex );
            in = NULL;
        }
        cexception_reraise( inner, ex );
    }

    // Determining the version of CIF
    int is_cif2 = 1;

    int ch = getc( in );
    CIF *cif;
    if( ch != '#' ) { // CIF2 must start with a magic code
        ungetc( ch, in );
        is_cif2 = 0;
    } else {
        char header[10];
        int i;
        for( i = 0; i < 9; i++ ) {
            ch = getc( in );
            if( ch == EOF || ch == '\r' || ch == '\n' ) {
                is_cif2 = 0;
                break;
            }
            header[i] = ch;
        }

        if( is_cif2 ) {
            header[9] = '\0';
            if( strcmp( header, "\\#CIF_2.0" ) ) {
                is_cif2 = 0;
            } else {
                /* The magic code may be followed by tabs and spaces,
                 * but anything else is not allowed */
                while( ch != EOF && ch != '\r' && ch != '\n' ) {
                    ch = getc( in );
                    if( ch != ' ' && ch != '\t' && ch != EOF &&
                        ch != '\r' && ch != '\n' ) {
                        is_cif2 = 0;
                    }
                }
                
            }
        }

        /* Eat up the rest of the comment line */
        while( ch != EOF && ch != '\t' && ch != '\n' ) {
            ch = getc( in );
        }
        
        /* If last read character is CR, it must be checked whether it
         * is CR or CR + NL type end-of-line. In any case the
         * end-of-line symbol must be discarded */
        if( ch == '\r' ) {
            ch = getc( in );
            if( ch != '\n' ) {
                ungetc( ch, in );
            }
        }
    }

    if( !is_cif2 ) {
        cif = new_cif_from_cif1_file( in, filename, co, ex );
    } else {
        cif = new_cif_from_cif2_file( in, filename, co, ex );
    }

    fclosex( in, ex );
    return cif;
}
