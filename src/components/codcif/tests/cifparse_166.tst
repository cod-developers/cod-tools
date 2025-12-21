Prior to r10704, buffer position with negative offset was attempted to
access here (cif_lexer.c, line 245):

    prevchar = cif_flex_token()[pos-1];
