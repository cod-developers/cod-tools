"Official" CIF errors that are not recognised by our parser -- they
should be output as errors and fixable with the --fix option, or output
as warnings with an option to convert them to errors:

longtext.cif:
- too long data lines

ciftest8.cif:
- too long data names (> 32 chars, etc)

longcomments.cif:
- too long comment lines

ciftest6.cif:
- duplicate data block names are not reported;
- empty block names are not reported and not fixed;

ciftest1.cif:
- A block with a (null) name is printed out when 'cifparse -p' is
  invoked: probably, printing out an empty file or a single comment
  line stating that the input was empty is a better behaviour.

ciftest10.cif:
- DOS eof-character ^Z is displayed very ugly in the error messages,
  as a non-printable ASCII character...

========================================================================

Problems with error reporting:

ciftest8.cif:
- inaccurate line information is reported and inaccurate line with an
  error text is printed out;

-- Error messages containing "incorrect CIF syntax" should probably be revised
   and changed into more informative ones.
