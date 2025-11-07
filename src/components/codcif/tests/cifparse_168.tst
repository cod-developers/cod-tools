Prior to r10711, buffer position with negative offset was attempted to
access here (cif2_lexer.c, line 338):

    prevchar = cif_flex_token()[pos-1];
