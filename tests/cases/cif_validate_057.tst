Tests the way the script treats a slightly invalid DDL1 dictionary file when
it is passed using the --add-dictionary option. Since the file is not
recognised as a proper DDL dictionary of any kind (i.e. DDL1, DDL2 or DDLm),
it should be reported as such and excluded from further validation tasks.
