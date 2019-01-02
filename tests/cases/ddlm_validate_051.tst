Check the way the validator handles faulty data item definitions that have
the 'byReference' content type. Definition of one of the data items is faulty
since it does not contain the _type.contents_referenced_id data item;
definition of the other data item is faulty since it links to a data item
that is not defined in the dictionary.
