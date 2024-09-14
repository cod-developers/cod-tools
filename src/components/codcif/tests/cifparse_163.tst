Tests the way various CIF values that involve only the question mark symbol
('?') and the whitespace symbols are recognised as unknown and thus discarded
when the '--fix-syntax' option is in effect.

Note, that the current behaviour of the parser seems to deviate from the one
described in CIF parser publication since all values that consist of the
aforementioned symbols are treated as unknown.
