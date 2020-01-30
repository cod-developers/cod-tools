Test the way the script behaves when the input CIF file contains
'_cod_entry_issue_severity' data item with at least on data value
that is not supported by the SQL database schema. Such unsuported
values should be recognised, reported and treated as undef values.
