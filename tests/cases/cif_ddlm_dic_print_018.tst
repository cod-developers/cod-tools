Tests the way a category import statement is handled when some of
the imported save frames have the same frame codes as save frames
that already exists in the importing file. The import statement
uses the 'Full' import mode and the default on duplicate mode.
The current implementation defaults to the 'Exit' on duplicate
mode. The import operation should generate a terminal error message.

