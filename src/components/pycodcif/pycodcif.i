%module pycodcif
%{
    #include <Python.h>

    PyObject * parse_cif( char * fname, char * prog, PyObject * options );

    // from cif_options.h:
    #include <cif_options.h>

    cif_option_t cif_option_default( void );

    // from cifvalue.h:
    #include <cifvalue.h>

    CIFVALUE *new_value_from_scalar( char *s, cif_value_type_t type, cexception_t *ex );
    void value_dump( CIFVALUE *value );

    // from datablock.h:
    #include <datablock.h>

    DATABLOCK *new_datablock( const char *name, DATABLOCK *next,
                              cexception_t *ex );
    DATABLOCK *datablock_next( DATABLOCK *datablock );
    size_t datablock_length( DATABLOCK *datablock );
    ssize_t *datablock_value_lengths( DATABLOCK *datablock );
    CIFVALUE *datablock_cifvalue( DATABLOCK *datablock, int tag_nr, int val_nr );
    ssize_t datablock_tag_index( DATABLOCK *datablock, char *tag );
    void datablock_overwrite_cifvalue( DATABLOCK * datablock, ssize_t tag_nr,
        ssize_t val_nr, CIFVALUE *value, cexception_t *ex );
    void datablock_insert_cifvalue( DATABLOCK * datablock, char *tag,
                                    CIFVALUE *value, cexception_t *ex );
    void datablock_start_loop( DATABLOCK *datablock );
    void datablock_finish_loop( DATABLOCK *datablock, cexception_t *ex );
    void datablock_push_loop_cifvalue( DATABLOCK * datablock, CIFVALUE *value,
                                       cexception_t *ex );
    char * datablock_name( DATABLOCK * datablock );

    // from cif.h:
    #include <cif.h>

    CIF *new_cif( cexception_t *ex );
    void cif_start_datablock( CIF *cif, const char *name,
                              cexception_t *ex );
    void cif_append_datablock( CIF * cif, DATABLOCK *datablock );
    void cif_print( CIF *cif );
    DATABLOCK * cif_datablock_list( CIF *cif );

    // from cif_compiler.h:
    #include <cif_compiler.h>

    CIF *new_cif_from_cif_file( char *filename, cif_option_t co, cexception_t *ex );

    // from common.h:
    double unpack_precision( char * value, double precision );

    PyObject *extract_value( CIFVALUE * cifvalue );
    cif_option_t extract_parser_options( PyObject * options );
    ssize_t datablock_value_length( DATABLOCK *datablock, size_t tag_index );
    char *datablock_tag( DATABLOCK *datablock, size_t tag_index );
    int datablock_tag_in_loop( DATABLOCK *datablock, size_t tag_index );
%}

%pythoncode %{
import warnings
warnings.filterwarnings('ignore', category=UnicodeWarning)

def parse(filename,*args):
    import re

    try:
        if isinstance(filename,unicode):
            filename = filename.encode('utf-8')
    except NameError:
        pass

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
            return unpack_precision(match.group(1), \
                                    float(match.group(3))), 1
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
        try:
            values = values.decode('utf-8','replace')
        except AttributeError:
            pass

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

class CifUnknownValue(object):
    pass

class CifInapplicableValue(object):
    pass

class CifFile(object):
    def __init__(self, file = None, parser_options = {}):
        if file is None:
            # Create an empty CifFile object
            self._cif = new_cif( None )
        else:
            # Parse CIF file
            self._cif = new_cif_from_cif_file( file, parser_options, None )

    def __getitem__(self, key):
        datablock = cif_datablock_list( self._cif )
        if isinstance(key, int):
            for i in range(0,key):
                if datablock is None:
                    raise IndexError('list index out of range')
                datablock = datablock_next( datablock )
            if datablock is None:
                raise IndexError('list index out of range')
            return CifDatablock(datablock = datablock)
        else:
            while datablock_name( datablock ) != key:
                datablock = datablock_next( datablock )
                if datablock is None:
                    raise KeyError(key)
            return CifDatablock(datablock = datablock)

    def __str__(self):
        with capture() as output:
            cif_print( self._cif )
        return output[0]

    def keys(self):
        keys = list()
        datablock = cif_datablock_list( self._cif )
        while datablock is not None:
            keys.append( datablock_name( datablock ) )
            datablock = datablock_next( datablock )
        return keys

    def append(self, datablock):
        # must be a datablock!
        cif_append_datablock( self._cif, datablock._datablock )

class CifDatablock(object):
    def __init__(self, name = None, datablock = None):
        if datablock is None:
            self._datablock = new_datablock( name, None, None )
        else:
            self._datablock = datablock

    def __getitem__(self, key):
        tag_index = datablock_tag_index( self._datablock, key )
        if tag_index == -1:
            raise KeyError(key)
        values = []
        for i in range(0, datablock_value_length( self._datablock,
                                                  tag_index )):
            values.append( extract_value( datablock_cifvalue( self._datablock,
                                                              tag_index, i ) ) )
        return values

    def __setitem__(self, key, value):
        if not isinstance(value, list):
            value = [ value ]
        tag_index = datablock_tag_index( self._datablock, key )
        if tag_index == -1:
            if len(value) == 1:
                datablock_insert_cifvalue( self._datablock, key, value[0], None )
            else:
                self.add_loop( [ key ], [ [x] for x in value ] )
        elif len(value) > 1:
            raise ValueError( "can not overwrite data item with a loop" )
        elif datablock_tag_in_loop( self._datablock, tag_index ) != -1:
            raise ValueError( "can not overwrite a loop" )
        else:
            datablock_overwrite_cifvalue( self._datablock, tag_index, 0, value[0], None )

    def keys(self):
        length = datablock_length( self._datablock )
        return [ datablock_tag( self._datablock, x) for x in range(0, length) ]

    def add_loop(self, keys, values):
        for key in keys:
            if key in self.keys():
                raise KeyError( "data item '{}' already exists".format(key) )
        datablock_start_loop( self._datablock )
        for i in range(0,len(values)):
            for j, key in enumerate(keys):
                if i == 0:
                    datablock_insert_cifvalue( self._datablock, key,
                                               values[i][j], None )
                else:
                    datablock_push_loop_cifvalue( self._datablock,
                                                  values[i][j], None )
        datablock_finish_loop( self._datablock, None )

import contextlib

@contextlib.contextmanager
def capture():
    import sys
    from cStringIO import StringIO
    oldout,olderr = sys.stdout, sys.stderr
    try:
        out=[StringIO(), StringIO()]
        sys.stdout,sys.stderr = out
        yield out
    finally:
        sys.stdout,sys.stderr = oldout, olderr
        out[0] = out[0].getvalue()
        out[1] = out[1].getvalue()

%}

%typemap(out) CIFVALUE * {
    $result = extract_value( $1 );
}

%typemap(out) ssize_t {
    $result = PyInt_FromLong( $1 );
}

%typemap(in) cif_option_t {
    $1 = extract_parser_options( $input );
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

%typemap(in) CIFVALUE * (PyObject *) {
    cif_value_type_t type = CIF_UNKNOWN;

    PyObject * module = PyImport_ImportModule( "pycodcif" );
    PyObject * module_dict  = PyModule_GetDict( module );
    PyObject * unknown      = PyMapping_GetItemString( module_dict,
                                                       "CifUnknownValue" );
    PyObject * inapplicable = PyMapping_GetItemString( module_dict,
                                                       "CifInapplicableValue" );

    char * value = strdupx( PyString_AsString( PyObject_Str( $input ) ),
                            NULL );
    if(        PyInt_Check( $input ) || PyLong_Check( $input ) ) {
        type = CIF_INT;
    } else if( PyFloat_Check( $input ) ) {
        type = CIF_FLOAT;
    } else if( PyString_Check( $input ) ) {
        type = CIF_SQSTRING; // conditions exist here
    } else if( $input == Py_None || PyObject_IsInstance( $input, unknown ) ) {
        value = "?";
        type = CIF_UQSTRING;
    } else if( PyObject_IsInstance( $input, inapplicable ) ) {
        value = ".";
        type = CIF_UQSTRING;
    }
    $1 = new_value_from_scalar( value, type, NULL );
}

%typemap(in) ssize_t {
    $1 = PyInt_AsLong( $input );
}

#include <Python.h>

PyObject * parse_cif( char * fname, char * prog, PyObject * options );

// from cif_options.h:
#include <cif_options.h>

typedef enum cif_option_t cif_option_t;

cif_option_t cif_option_default( void );

// from cifvalue.h:
#include <cifvalue.h>

CIFVALUE *new_value_from_scalar( char *s, cif_value_type_t type, cexception_t *ex );
void value_dump( CIFVALUE *value );

// from datablock.h:
#include <datablock.h>

DATABLOCK *new_datablock( const char *name, DATABLOCK *next,
                          cexception_t *ex );
DATABLOCK *datablock_next( DATABLOCK *datablock );
size_t datablock_length( DATABLOCK *datablock );
ssize_t *datablock_value_lengths( DATABLOCK *datablock );
CIFVALUE *datablock_cifvalue( DATABLOCK *datablock, int tag_nr, int val_nr );
ssize_t datablock_tag_index( DATABLOCK *datablock, char *tag );
void datablock_overwrite_cifvalue( DATABLOCK * datablock, ssize_t tag_nr,
    ssize_t val_nr, CIFVALUE *value, cexception_t *ex );
void datablock_insert_cifvalue( DATABLOCK * datablock, char *tag,
                                CIFVALUE *value, cexception_t *ex );
void datablock_start_loop( DATABLOCK *datablock );
void datablock_finish_loop( DATABLOCK *datablock, cexception_t *ex );
void datablock_push_loop_cifvalue( DATABLOCK * datablock, CIFVALUE *value,
                                   cexception_t *ex );
char * datablock_name( DATABLOCK * datablock );

// from cif.h:
#include <cif.h>

CIF *new_cif( cexception_t *ex );
void cif_start_datablock( CIF *cif, const char *name,
                          cexception_t *ex );
void cif_append_datablock( CIF * cif, DATABLOCK *datablock );
void cif_print( CIF *cif );
DATABLOCK * cif_datablock_list( CIF *cif );

// from cif_compiler.h:
#include <cif_compiler.h>

CIF *new_cif_from_cif_file( char *filename, cif_option_t co, cexception_t *ex );

// from common.h:
double unpack_precision( char * value, double precision );

PyObject *extract_value( CIFVALUE * cifvalue );
cif_option_t extract_parser_options( PyObject * options );
ssize_t datablock_value_length( DATABLOCK *datablock, size_t tag_index );
char *datablock_tag( DATABLOCK *datablock, size_t tag_index );
int datablock_tag_in_loop( DATABLOCK *datablock, size_t tag_index );
