Tests the way a category import statement is handled when some of
the imported save frames have the same frame codes as save frames
that already exists in the importing file. The import statement
uses the 'Full' import mode and the 'Replace' on duplicate mode.
The import operation should add all of the save frames with unique
frame codes and replace dictionary save frames that have non-unique
frame codes with their equivalents from the imported file.
