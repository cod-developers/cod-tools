Tests the way the --add-dictionary and --ddl1-add-dictionary options
affect the DDL1 dictionary merging order. Dictionaries provided using
the --ddl1-add-dictionary should be placed at the start of the dictionary
list resulting in the final dictionary merging order of
['ddl1_merge_update.dic', 'ddl1_merge_base.dic'].
