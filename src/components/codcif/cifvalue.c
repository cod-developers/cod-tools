/*-------------------------------------------------------------------------*\
* $Author$
* $Date$
* $Revision$
* $URL$
\*-------------------------------------------------------------------------*/

#include <cexceptions.h>
#include <assert.h>
#include <string.h>
#include <allocx.h>
#include <cifvalue.h>
#include <ciflist.h>
#include <ciftable.h>
#include <common.h>

struct CIFVALUE {
    union {
        char *str;
        struct CIFLIST *l;
        struct CIFTABLE *t;
    } v;
    cif_value_type_t type;
};

void delete_value( CIFVALUE *value ) {
    assert( value );

    if( value->type == CIF_LIST ) {
        delete_list( value_list( value ) );
    } else if( value->type == CIF_TABLE ) {
        delete_table( value_table( value ) );
    } else {
        freex( value->v.str );
    }
    freex( value );
}

CIFVALUE *new_value_from_scalar( char *s, cif_value_type_t type,
                              cexception_t *ex )
{
    CIFVALUE *value = callocx( 1, sizeof(CIFVALUE), ex );
    value->v.str = s;
    value->type = type;
    return value;
}

CIFVALUE *new_value_from_list( CIFLIST *list, cexception_t *ex )
{
    CIFVALUE *value = callocx( 1, sizeof(CIFVALUE), ex );
    value->v.l = list;
    value->type = CIF_LIST;
    return value;
}

CIFVALUE *new_value_from_table( CIFTABLE *table, cexception_t *ex )
{
    CIFVALUE *value = callocx( 1, sizeof(CIFVALUE), ex );
    value->v.t = table;
    value->type = CIF_TABLE;
    return value;
}

void value_dump( CIFVALUE *value ) {
    assert( value );
    switch( value->type ) {
        case CIF_LIST:
            list_dump( value_list( value ) );
            break;
        case CIF_TABLE:
            table_dump( value_table( value ) );
            break;
        case CIF_SQSTRING:
            printf( " '%s'", value_scalar( value ) );
            break;
        case CIF_DQSTRING:
            printf( " \"%s\"", value_scalar( value ) );
            break;
        case CIF_SQ3STRING:
            printf( " '''%s'''", value_scalar( value ) );
            break;
        case CIF_DQ3STRING:
            printf( " \"\"\"%s\"\"\"", value_scalar( value ) );
            break;
        case CIF_TEXT:
            printf( "\n;%s\n;\n", value_scalar( value ) );
            break;
        default:
            printf( " %s", value_scalar( value ) );
    }
}

cif_value_type_t value_type( CIFVALUE *value ) {
    return value->type;
}

char *value_scalar( CIFVALUE *value ) {
    return value->v.str;
}

CIFLIST *value_list( CIFVALUE *value ) {
    return value->v.l;
}

CIFTABLE *value_table( CIFVALUE *value ) {
    return value->v.t;
}

cif_value_type_t value_type_from_string_1_1( char *str ) {
    if( is_integer( str ) ) { return CIF_INT; }
    if( is_real( str ) ) { return CIF_FLOAT; }
    if( strchr( str, '\n' ) != NULL || strchr( str, '\r' ) != NULL ) {
        return CIF_TEXT;
    }
    if( *str == '\0' ) { return CIF_SQSTRING; }

    int has_space_after_squote = 0;
    int has_space_after_dquote = 0;
    char *pos;
    for( pos = str; *pos != '\0'; pos++ ) {
        if( pos != str && *pos == ' ' ) {
            if( *(pos-1) == '\'' ) { has_space_after_squote = 1; }
            if( *(pos-1) == '"'  ) { has_space_after_dquote = 1; }
        }
    }
    if( has_space_after_squote && has_space_after_dquote ) {
        return CIF_TEXT;
    }
    if( has_space_after_squote || *str == '\'' ) {
        return CIF_DQSTRING;
    }
    if( has_space_after_dquote || strchr( str, ' ' ) || strchr( str, '\t' ) ||
        *str == '_' || *str == '[' || *str == ']' || *str == '$' ||
        starts_with_keyword( "data_",   str ) ||
        starts_with_keyword( "loop_",   str ) ||
        starts_with_keyword( "global_", str ) ||
        starts_with_keyword( "save_",   str ) ) {
        return CIF_SQSTRING;
    }
    return CIF_UQSTRING;
}

cif_value_type_t value_type_from_string_2_0( char *str ) {
    if( is_integer( str ) ) { return CIF_INT; }
    if( is_real( str ) ) { return CIF_FLOAT; }
    if( strchr( str, '\n' ) != NULL || strchr( str, '\r' ) != NULL ) {
        return CIF_TEXT;
    }
    if( *str == '\0' ) { return CIF_SQSTRING; }
    size_t len = strlen( str );
    int consecutive_squotes = 0;
    int consecutive_dquotes = 0;
    int max_consecutive_squotes = 0;
    int max_consecutive_dquotes = 0;
    char *pos;
    for( pos = str; *pos != '\0'; pos++ ) {
        if( *pos != '\'' ) {
            if( max_consecutive_squotes < consecutive_squotes ) {
                max_consecutive_squotes = consecutive_squotes;
            }
            consecutive_squotes = 0;
        }
        if( *pos != '"' ) {
            if( max_consecutive_dquotes < consecutive_dquotes ) {
                max_consecutive_dquotes = consecutive_dquotes;
            }
            consecutive_dquotes = 0;
        }
        switch( *pos ) {
            case '\'': consecutive_squotes++; break;
            case '"':  consecutive_dquotes++; break;
        }
    }
    if( max_consecutive_squotes >= 3 || max_consecutive_dquotes >= 3 ) {
        return CIF_TEXT;
    }
    char last = '\0';
    if( len > 0 ) {
        last = str[len-1];
    }
    if( max_consecutive_squotes && max_consecutive_dquotes ) {
        if( last != '\'' ) { return CIF_SQ3STRING; }
        if( last != '"'  ) { return CIF_DQ3STRING; }
        return CIF_TEXT;
    }
    if( max_consecutive_squotes ) { return CIF_DQSTRING; }
    if( max_consecutive_dquotes ) { return CIF_SQSTRING; }
    if( last == '#' || last == '$' || last == '_' || last == '\0' ||
        strchr( str, ' ' ) || strchr( str, '\t' ) ||
        strchr( str, '[' ) || strchr( str,  ']' ) ||
        strchr( str, '{' ) || strchr( str,  '}' ) ||
        starts_with_keyword( "data_",   str ) ||
        starts_with_keyword( "loop_",   str ) ||
        starts_with_keyword( "global_", str ) ||
        starts_with_keyword( "save_",   str ) ||
        starts_with_keyword( "stop_",   str ) ) {
        return CIF_SQSTRING;
    }
    return CIF_UQSTRING;
}
