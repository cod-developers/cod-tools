pycodcif
========

A COD parser for CIF v1.1 and CIF v2.0 formats

Usage
-----

    datablocks, error_count, error_messages = parse( file, options )

Options
-------

The COD CIF parser is designed to detect and report the most common CIF syntax errors.
This is implemented using the extended grammar.
The behaviour of the COD CIF parser is controlled by the following options:

- **fix_all**: turns on all the following options;
- **fix_data_header**: ignores stray CIF values before the first data block and missing ``data_`` header;
- **fix_datablock_names**: appends stray CIF values after the data block name to the data block name;
- **fix_duplicate_tags_with_same_values**: ignores two or more data items having the same value in the same data block;
- **fix_duplicate_tags_with_empty_values**: retains the value of the data item with a known value (not '?' or '.') if more than one data item is found in the same data block, and the rest of the values of the data item are unknown;
- **fix_string_quotes**: puts more than one unquoted values following a non-loop data item in quotes;
- **allow_uqstring_brackets**: puts unquoted strings starting with opening square bracket ([) in single quotes;
- **fix_ctrl_z**: removes DOS EOF (^Z, Ctrl-Z) characters that are not part of a quoted value or a text field;
- **fix_non_ascii_symbols**: encodes non-ASCII symbols using numeric character references;
- **fix_missing_closing_double_quote**: inserts an appropriate quote where a missing single or double closing quote is detected.

Usage example:

    parse( file, { 'fix_data_header' : 1 } )

All other options are turned on/off likewise.

Data structure
--------------

The data blocks of parsed CIF files are stored in associative arrays with the following keys:

- **name** (string): name of a CIF data block;
- **tags** (array): data names present in the CIF data block (in lowercase);
- **values** (associative array): keys are the values of the ``tags`` array, values are arrays containing values of each data item;
- **types** (associative array): keys are the values of the ``tags`` array, values are arrays containing lexically derived data types of each data value;
- **precisions** (associative array): keys are the values of the ``tags`` array, values are arrays containing standard uncertainties for each data item;
- **loops** (array of arrays): each inner array corresponds to a loop from the CIF data block and contains a list of data items present in the loop;
- **inloop** (associative array): keys are the values of the ``tags`` array, values correspond to indices of the outer ``loops`` array. It is used as an index to optimize data item-in-loop related searches;
- **save_blocks** (array of associative arrays): list of CIF save frames, where every frame is represented using a data structure identical to a CIF data block;
- **cifversion** (associative array): has keys ``major`` and ``minor``, corresponding to the major and minor versions of CIF format, currently 1.1 or 2.0.

Further reading
---------------

- Merkys, A., Vaitkus, A., Butkus, J., Okulič-Kazarinas, M., Kairys, V. & Gražulis, S. (2016)
  "COD::CIF::Parser: an error-correcting CIF parser for the Perl language".
  *Journal of Applied Crystallography* **49**.
  doi:10.1107/S1600576715022396
