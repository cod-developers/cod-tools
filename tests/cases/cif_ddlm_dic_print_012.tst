Tests the way a dictionary import statement of a single save frame is handled
when a save frame with the same frame code already exists in the importing
file. The import statement uses the 'Full' import mode and the default on
duplicate mode. The current implementation defaults to the 'Exit' on duplicate
mode. The import operation should generate a terminal error message.
