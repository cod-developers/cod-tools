Tests the way definitions of looped data items that belong to categories from
external dictionaries and that specify category keys from the same external
dictionary are handled. Currently the _category_key.name attribute is incorrectly
left as part of individual data item definitions instead of removing them.
