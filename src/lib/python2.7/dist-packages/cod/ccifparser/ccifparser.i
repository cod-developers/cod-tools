%module ccifparser
%{
    #include <Python.h>
    #include <cif_grammar_y.h>
    #include <cif_grammar_flex.h>
    #include <allocx.h>
    #include <cxprintf.h>
    #include <getoptions.h>
    #include <cexceptions.h>
    #include <stdiox.h>
    #include <stringx.h>
    #include <yy.h>
    #include <cif.h>
    #include <datablock.h>

    PyObject * parse_cif( char * fname, char * prog, PyObject * options );
%}

%pythoncode %{
def parse(filename,options):
    import re

    prog = '-'
    try:
        import sys
        prog = sys.argv[0]
    except IndexError:
        pass

    if not options:
        options = {}
    parse_results = parse_cif(filename,prog,options)
    data = parse_results['datablocks']
    nerrors = parse_results['nerrors']

    for datablock in data:
        datablock['precisions'] = {}
        for tag in datablock['types'].keys():
            prec = []
            has_numeric_values = False
            for i,type in enumerate(datablock['types'][tag]):
                this_prec = None
                if type in ('INT','FLOAT'):
                    has_numeric_values = True
                    match = re.search('^(.*)(\(([0-9]+)\))$',
                                      datablock['values'][tag][i])
                    if match:
                        if type == 'FLOAT':
                            this_prec = unpack_precision(match.group(1),
                                                         match.group(3))
                        elif type == 'INT':
                            this_prec = match.group(3)

                prec.append(this_prec)
            if any([x is not None for x in prec]) or \
                (tag in datablock['inloop'].keys() and has_numeric_values):
                if len(prec) < len(datablock['types'][tag]):
                    prec[len(datablock['types'][tag])-1] = None
                datablock['precisions'][tag] = prec

    return data,nerrors

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
%}

#include <Python.h>
#include <cif_grammar_y.h>
#include <cif_grammar_flex.h>
#include <allocx.h>
#include <cxprintf.h>
#include <getoptions.h>
#include <cexceptions.h>
#include <stdiox.h>
#include <stringx.h>
#include <yy.h>
#include <cif.h>
#include <datablock.h>

PyObject * parse_cif( char * fname, char * prog, PyObject * options );
