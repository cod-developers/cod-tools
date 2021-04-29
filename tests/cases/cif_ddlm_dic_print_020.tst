Tests the way import errors are detected and reported during a complex
import operation. The import situation:
- Dictionary A imports the entire dictionary B;
- Dictionary A imports the contents of save frame c from template dictionary C;
- Dictionary B imports the contents of save frame c from template dictionary C;
- Dictionary A contains duplicate data items that should prevent the contents
  of save frame c from being imported.
