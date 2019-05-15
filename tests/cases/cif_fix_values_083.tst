Checks the way looped dictionary provenance values are handled. When this
test was originally created an incorrect assumption seems to have been made
that dictionary name, version or update date can appear in a loop, however,
this is not allowed in DDL1 dictionaries. This test should be removed if
the tests are ever optimised.
