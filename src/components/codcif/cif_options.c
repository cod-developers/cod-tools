/*---------------------------------------------------------------------------*\
**$Author$
**$Date$
**$Revision$
**$URL$
\*---------------------------------------------------------------------------*/

/* Implements managements and declarations of CIF options, that can be
   used, for instance, to modify behaviour of a CIF compiler. */

/* exports: */
#include <cif_options.h>

/* uses: */
#include <cif_grammar_flex.h>

cif_option_t cif_option_default( void )
{
    return 0;
}

cif_option_t cif_option_set_fix_errors( cif_option_t copt )
{
    set_lexer_fix_ctrl_z();
    set_lexer_fix_non_ascii_symbols();
    set_lexer_fix_missing_closing_double_quote();
    set_lexer_fix_missing_closing_single_quote();
    set_lexer_allow_uqstring_brackets();
    set_lexer_fix_datablock_names();
    copt |= FIX_ERRORS;
    return copt;
}

cif_option_t cif_option_set( cif_option_t options, cif_option_t opt )
{
    return options | opt;
}

cif_option_t cif_option_set_do_not_unprefix_text( cif_option_t copt )
{
    return copt | DO_NOT_UNPREFIX_TEXT;
}

cif_option_t cif_option_set_do_not_unfold_text( cif_option_t copt )
{
    return copt | DO_NOT_UNFOLD_TEXT;
}

cif_option_t
cif_option_set_fix_duplicate_tags_with_same_values( cif_option_t copt )
{
    return copt | FIX_DUPLICATE_TAGS_WITH_SAME_VALUES;
}

cif_option_t
cif_option_set_fix_duplicate_tags_with_empty_values( cif_option_t copt )
{
    return copt | FIX_DUPLICATE_TAGS_WITH_EMPTY_VALUES;
}

cif_option_t cif_option_set_fix_data_header( cif_option_t copt )
{
    return copt | FIX_DATA_HEADER;
}

cif_option_t cif_option_set_fix_datablock_names( cif_option_t copt )
{
    return copt | FIX_DATABLOCK_NAMES;
}

cif_option_t cif_option_set_fix_string_quotes( cif_option_t copt )
{
    return copt | FIX_STRING_QUOTES;
}

cif_option_t cif_option_suppress_messages( cif_option_t copt )
{
    return copt | CO_SUPPRESS_MESSAGES;
}

cif_option_t cif_option_count_lines_from_2( cif_option_t copt )
{
    return copt | CO_COUNT_LINES_FROM_2;
}
