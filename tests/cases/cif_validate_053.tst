Tests the way the script behaves when a non-DDL1 dictionary is provided
using the --ddl1-dictionaries option. A warning message should be issued
about the mismatching DDL generation, but the file should still be forcefully
treated as a DDL1 dictionary.
