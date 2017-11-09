%module pycodcif
%{
    #include <Python.h>

    PyObject * parse_cif( char * fname, char * prog, PyObject * options );

    // from cif_options.h:
    #include <cif_options.h>

    typedef enum cif_option_t cif_option_t;

    cif_option_t cif_option_default();

    // from cifvalue.h:
    #include <cifvalue.h>

    CIFVALUE *new_value_from_scalar( char *s, cif_value_type_t type, cexception_t *ex );
    void value_dump( CIFVALUE *value );

    // from datablock.h:
    #include <datablock.h>

    DATABLOCK *new_datablock( const char *name, DATABLOCK *next,
                              cexception_t *ex );
    DATABLOCK *datablock_next( DATABLOCK *datablock );
    CIFVALUE *datablock_cifvalue( DATABLOCK *datablock, int tag_nr, int val_nr );
    ssize_t datablock_tag_index( DATABLOCK *datablock, char *tag );
    void datablock_overwrite_cifvalue( DATABLOCK * datablock, ssize_t tag_nr,
        ssize_t val_nr, CIFVALUE *value, cexception_t *ex );
    void datablock_insert_cifvalue( DATABLOCK * datablock, char *tag,
                                    CIFVALUE *value, cexception_t *ex );

    // from cif.h:
    #include <cif.h>

    CIF *new_cif( cexception_t *ex );
    void cif_start_datablock( CIF *cif, const char *name,
                              cexception_t *ex );
    void cif_print( CIF *cif );
    DATABLOCK * cif_datablock_list( CIF *cif );

    // from cif_compiler.h:
    #include <cif_compiler.h>

    CIF *new_cif_from_cif_file( char *filename, cif_option_t co, cexception_t *ex );

    PyObject *extract_value( CIFVALUE * cifvalue );
%}

%pythoncode %{
import warnings
warnings.filterwarnings('ignore', category=UnicodeWarning)

def parse(filename,*args):
    import re

    if isinstance(filename,unicode):
        filename = filename.encode('utf-8')

    prog = '-'
    try:
        import sys
        prog = sys.argv[0]
    except IndexError:
        pass

    options = {}
    if len(args) > 0:
        options = args[0]

    parse_results = parse_cif(filename,prog,options)
    data = parse_results['datablocks']
    messages = parse_results['messages']
    nerrors = parse_results['nerrors']

    for datablock in data:
        datablock['precisions'] = {}
        for tag in datablock['types'].keys():
            precisions, _ = extract_precision(datablock['values'][tag],
                                              datablock['types'][tag])
            if precisions is not None:
                datablock['precisions'][tag] = precisions
        for saveblock in datablock['save_blocks']:
            saveblock['precisions'] = {}
            for tag in saveblock['types'].keys():
                precisions, _ = extract_precision(saveblock['values'][tag],
                                                  saveblock['types'][tag])
                if precisions is not None:
                    saveblock['precisions'][tag] = precisions

    data = [ decode_utf8_frame( _ ) for _ in data ]

    errors = []
    warnings = []

    for message in messages:
        datablock = message['addpos']
        if datablock is not None:
            datablock = "data_{0}".format(datablock)
        explanation = message['explanation']
        if explanation is not None:
            explanation = explanation[0].lower() + explanation[1:]
        lineno = None
        if 'lineno' in message:
            lineno = message['lineno']
        columnno = None
        if 'columnno' in message:
            columnno = message['columnno']
        msg = sprint_message(message['program'],
                             message['filename'],
                             datablock,
                             message['status'],
                             message['message'],
                             explanation,
                             lineno,
                             columnno,
                             message['line'])

        if message['status'] == 'ERROR':
            errors.append(msg)
        else:
            warnings.append(msg)

    if 'no_print' not in options.keys() or options['no_print'] == 0:
        for warning in warnings:
            sys.stdout.write(warning)
        for error in errors:
            sys.stdout.write(error)
        if errors:
            raise CifParserException(errors.pop())

    return data, nerrors, [warnings + errors]

def unpack_precision(value,precision):
    """
    Adapted from:

    URL: svn://www.crystallography.net/cod-tools/branches/andrius-inline-to-swig/src/lib/perl5/Precision.pm
    Relative URL: ^/branches/andrius-inline-to-swig/src/lib/perl5/Precision.pm
    Repository Root: svn://www.crystallography.net/cod-tools
    Repository UUID: 04be6746-3802-0410-999d-98508da1e98c
    Revision: 3228
    """
    import re
    match = re.search('([-+]?[0-9]*)?(\.)?([0-9]+)?(?:e([+-]?[0-9]+))?',
                      value)
    
    int_part = 0
    if match.group(1):
        if match.group(1) == '+':
            int_part = 1
        elif match.group(1) == '-':
            int_part = -1
        else:
            int_part = int(match.group(1))
    dec_dot = match.group(2)
    mantissa = match.group(3)
    exponent = 0
    if match.group(4):
        exponent = int(match.group(4))
    if dec_dot and mantissa:
        precision = float(precision) / (10**len(mantissa))
    precision = float(precision) * (10**exponent)
    return precision

def extract_precision(values,types):
    import re
    if isinstance(types,list):
        precisions = []
        important = []
        for i in range(0,len(values)):
            precision, is_important = \
                extract_precision(values[i],types[i])
            precisions.append(precision)
            important.append(is_important)
        if any([x == 1 for x in important]):
            return precisions, 1
        else:
            return None, 0
    elif isinstance(types,dict):
        precisions = {}
        for i in values.keys():
            precision, is_important = \
                extract_precision(values[i],types[i])
            if is_important:
                precisions[i] = precision
        if precisions.keys():
            return precisions, 1
        else:
            return None, 0
    elif types == 'FLOAT':
        match = re.search('^(.*)(\(([0-9]+)\))$',values)
        if match is not None and match.group(1):
            return unpack_precision(match.group(1),match.group(3)), 1
        else:
            return None, 1
    elif types == 'INT':
        match = re.search('^(.*)(\(([0-9]+)\))$',values)
        if match is not None and match.group(1):
            return match.group(3), 1
        else:
            return None, 1
    else:
        return None, 0

def decode_utf8_frame(frame):
    for _ in [ 'name', 'tags', 'loops' ]:
        if _ in frame.keys():
            frame[_] = decode_utf8_values(frame[_])

    for _ in [ 'precisions', 'inloop', 'values', 'types' ]:
        if _ in frame.keys():
            frame[_] = decode_utf8_hash_keys(frame[_])

    if 'values' in frame.keys() and 'types' in frame.keys():
        frame['values'] = decode_utf8_typed_values(frame['values'],
                                                   frame['types'])

    if 'save_blocks' in frame.keys():
        frame['save_blocks'] = [ decode_utf8_frame(_) for _ in
                                        frame['save_blocks'] ]

    return frame

def decode_utf8_hash_keys(values):
    if isinstance(values,list):
        for i in range(0,len(values)):
            values[i] = decode_utf8_hash_keys(values[i])
    elif isinstance(values,dict):
        for key in values.keys():
            values[key] = decode_utf8_hash_keys(values[key])
            new_key = decode_utf8_values(key)
            if new_key != key:
                values[new_key] = values[key]
                del values[key]

    return values

def decode_utf8_values(values):
    if isinstance(values,list):
        for i in range(0,len(values)):
            values[i] = decode_utf8_values(values[i])
    elif isinstance(values,dict):
        for key in values.keys():
            values[key] = decode_utf8_hash_keys(values[key])
    else:
        values = values.decode('utf-8','replace')

    return values

def decode_utf8_typed_values(values,types):
    if isinstance(values,list):
        for i in range(0,len(values)):
            values[i] = decode_utf8_typed_values(values[i], types[i])
    elif isinstance(values,dict):
        for key in values.keys():
            values[key] = decode_utf8_typed_values(values[key], types[key])
    elif types not in [ 'INT', 'FLOAT' ]:
        values = decode_utf8_values(values)

    return values

program_escape = {
    '&': '&amp;',
    ':': '&colon;',
}
filename_escape = {
    '&': '&amp;',
    ':': '&colon;',
    ' ': '&nbsp;',
    '(': '&lpar;',
    ')': '&rpar;',
}
datablock_escape = {
    '&': '&amp;',
    ':': '&colon;',
    ' ': '&nbsp;',
}
message_escape = {
    '&': '&amp;',
    ':': '&colon;'
}

def sprint_message(program, filename, datablock, errlevel, message,
                   explanation, line, column, line_contents):
    """
    Adapted from:
    URL: svn://www.crystallography.net/cod-tools/trunk/src/lib/perl5/COD/UserMessage.pm
    Relative URL: ^/trunk/src/lib/perl5/COD/UserMessage.pm
    Repository Root: svn://www.crystallography.net/cod-tools
    Repository UUID: 04be6746-3802-0410-999d-98508da1e98c
    Revision: 3813
    """
    import re
    message = re.sub('\.?\n?$', '', message)
    if explanation is not None:
        explanation = re.sub('\.?\n?$', '', explanation)
    if line_contents is not None:
        line_contents = re.sub('\n+$', '', line_contents)

    if program == '-c':
        program = "python -c '...'"

    program     = escape_meta(program,     program_escape)
    filename    = escape_meta(filename,    filename_escape)
    datablock   = escape_meta(datablock,   datablock_escape)
    message     = escape_meta(message,     message_escape)
    explanation = escape_meta(explanation, message_escape)

    if line_contents is not None:
        line_contents = '\n'.join([ " {0}".format(x) for x in line_contents.split('\n') ])

    msg = "{0}: ".format(program)
    if filename is not None:
        msg = "{0}{1}".format(msg, filename)
        if line is not None:
            msg = "{0}({1}".format(msg, line)
            if column is not None:
                msg = "{0},{1}".format(msg, column)
            msg = "{0})".format(msg)
        if datablock is not None:
            msg = "{0} {1}".format(msg, datablock)
        msg = "{0}: ".format(msg)
    if errlevel is not None:
        msg = "{0}{1}, ".format(msg, errlevel)
    msg = "{0}{1}".format(msg, message)
    if explanation is not None:
        msg = "{0} -- {1}".format(msg, explanation)
    if line_contents is not None:
        msg = "{0}:\n{1}\n".format(msg, line_contents)
        if column is not None:
            msg = "{0} {1}^\n".format(msg, " "*(column-1))
    else:
        msg = "{0}.\n".format(msg)

    return msg

def escape_meta(text, escaped_symbols):
    """
    Adapted from:
    URL: svn://www.crystallography.net/cod-tools/trunk/src/lib/perl5/COD/UserMessage.pm
    Relative URL: ^/trunk/src/lib/perl5/COD/UserMessage.pm
    Repository Root: svn://www.crystallography.net/cod-tools
    Repository UUID: 04be6746-3802-0410-999d-98508da1e98c
    Revision: 3813
    """
    import re

    if text is None:
        return None

    symbols = "|".join(["\\{0}".format(x) for x in escaped_symbols.keys()])

    def escape_internal(matchobj):
        return escaped_symbols[matchobj.group(0)]

    return re.sub("({0})".format(symbols), escape_internal, text)

class CifParserException(Exception):
    pass

class CifFile(object):
    def __init__(self):
        self._cif = new_cif( None )

    def __getitem__(self, key):
        datablock = cif_datablock_list( self._cif )
        for i in range(0,key):
            if datablock is None:
                raise IndexError('list index out of range')
            datablock = datablock_next( datablock )
        if datablock is None:
            raise IndexError('list index out of range')
        return datablock

class CifDatablock(object):
    def __init__(self, name):
        self._datablock = new_datablock( name, None, None )

    def __getitem__(self, key):
        tag_index = datablock_tag_index( self._datablock, key )
        if tag_index == -1:
            raise KeyError(key)
        return extract_value( datablock_cifvalue( self._datablock, tag_index, 0 ) )

    def __setitem__(self, key, value):
        tag_index = datablock_tag_index( self._datablock, key )
        cifvalue = new_value_from_scalar( value, "CIF_UQSTRING", None )
        if tag_index == -1:
            datablock_insert_cifvalue( self._datablock, key, cifvalue, None )

%}

%typemap(out) ssize_t {
    $result = PyInt_FromLong( $1 );
}

%typemap(in) cif_value_type_t {
    cif_value_type_t type;
    if(        strcmp( PyString_AsString($input), "CIF_INT" ) == 0 ) {
        type = CIF_INT;
    } else if( strcmp( PyString_AsString($input), "CIF_FLOAT" ) == 0 ) {
        type = CIF_FLOAT;
    } else if( strcmp( PyString_AsString($input), "CIF_UQSTRING" ) == 0 ) {
        type = CIF_UQSTRING;
    } else if( strcmp( PyString_AsString($input), "CIF_SQSTRING" ) == 0 ) {
        type = CIF_SQSTRING;
    } else if( strcmp( PyString_AsString($input), "CIF_SQ3STRING" ) == 0 ) {
        type = CIF_SQ3STRING;
    } else if( strcmp( PyString_AsString($input), "CIF_DQ3STRING" ) == 0 ) {
        type = CIF_DQ3STRING;
    } else if( strcmp( PyString_AsString($input), "CIF_TEXT" ) == 0 ) {
        type = CIF_TEXT;
    } else if( strcmp( PyString_AsString($input), "CIF_LIST" ) == 0 ) {
        type = CIF_LIST;
    } else if( strcmp( PyString_AsString($input), "CIF_TABLE" ) == 0 ) {
        type = CIF_TABLE;
    } else {
        type = CIF_NON_EXISTANT;
    }
    $1 = type;
}

%typemap(in) ssize_t {
    $1 = PyInt_AsLong( $input );
}

#include <Python.h>

PyObject * parse_cif( char * fname, char * prog, PyObject * options );

// from cif_options.h:
#include <cif_options.h>

typedef enum cif_option_t cif_option_t;

cif_option_t cif_option_default();

// from cifvalue.h:
#include <cifvalue.h>

CIFVALUE *new_value_from_scalar( char *s, cif_value_type_t type, cexception_t *ex );
void value_dump( CIFVALUE *value );

// from datablock.h:
#include <datablock.h>

DATABLOCK *new_datablock( const char *name, DATABLOCK *next,
                          cexception_t *ex );
DATABLOCK *datablock_next( DATABLOCK *datablock );
CIFVALUE *datablock_cifvalue( DATABLOCK *datablock, int tag_nr, int val_nr );
ssize_t datablock_tag_index( DATABLOCK *datablock, char *tag );
void datablock_overwrite_cifvalue( DATABLOCK * datablock, ssize_t tag_nr,
    ssize_t val_nr, CIFVALUE *value, cexception_t *ex );
void datablock_insert_cifvalue( DATABLOCK * datablock, char *tag,
                                CIFVALUE *value, cexception_t *ex );

// from cif.h:
#include <cif.h>

CIF *new_cif( cexception_t *ex );
void cif_start_datablock( CIF *cif, const char *name,
                          cexception_t *ex );
void cif_print( CIF *cif );
DATABLOCK * cif_datablock_list( CIF *cif );

// from cif_compiler.h:
#include <cif_compiler.h>

CIF *new_cif_from_cif_file( char *filename, cif_option_t co, cexception_t *ex );

PyObject *extract_value( CIFVALUE * cifvalue );
