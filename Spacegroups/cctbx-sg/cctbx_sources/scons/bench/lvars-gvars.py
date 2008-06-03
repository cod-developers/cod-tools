# __COPYRIGHT__
#
# Functions and data for timing different idioms for fetching a keyword
# value from a pair of dictionaries for localand global values.  This was
# used to select how to most efficiently expand single $KEYWORD strings
# in src/engine/SCons/Subst.py.

def Func1(var, gvars, lvars):
    """lvars try:-except:, gvars try:-except:"""
    for i in IterationList:
        try:
            x = lvars[var]
        except KeyError:
            try:
                x = gvars[var]
            except KeyError:
                x = ''

def Func2(var, gvars, lvars):
    """lvars has_key(), gvars try:-except:"""
    for i in IterationList:
        if lvars.has_key(var):
            x = lvars[var]
        else:
            try:
                x = gvars[var]
            except KeyError:
                x = ''

def Func3(var, gvars, lvars):
    """lvars has_key(), gvars has_key()"""
    for i in IterationList:
        if lvars.has_key(var):
            x = lvars[var]
        elif gvars.has_key(var):
            x = gvars[var]
        else:
            x = ''

def Func4(var, gvars, lvars):
    """eval()"""
    for i in IterationList:
        try:
            x = eval(var, gvars, lvars)
        except NameError:
            x = ''

# Data to pass to the functions on each run.  Each entry is a
# three-element tuple:
#
#   (
#       "Label to print describing this data run",
#       ('positional', 'arguments'),
#       {'keyword' : 'arguments'},
#   ),

Data = [
    (
        "Neither in gvars or lvars",
        ('x', {}, {}),
        {},
    ),
    (
        "Missing from lvars, found in gvars",
        ('x', {'x':1}, {}),
        {},
    ),
    (
        "Found in lvars",
        ('x', {'x':1}, {'x':2}),
        {},
    ),
]

