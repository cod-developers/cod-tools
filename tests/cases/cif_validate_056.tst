Tests the way the script treats a slightly invalid DDL1 dictionary file when
it is passed using the --add-ddl1-dictionary option. Since the file is not
recognised as a proper DDL dictionary of any kind (i.e. DDL1, DDL2 or DDLm),
but was explicitly provided as a DDL1 dictionary, it should be reported as
being of unrecognised DDL type and still treated as a DDL1 dictionary in
further validation tasks.
