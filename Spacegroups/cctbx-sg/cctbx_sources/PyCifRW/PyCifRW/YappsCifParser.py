from CifFile import CifError
from types import *
# An alternative specification for the Cif Parser, based on Yapps2
# by Amit Patel (http://theory.stanford.edu/~amitp/Yapps)
#
# helper code: we define our match tokens
lastval = ''
def monitor(location,value):
    global lastval
    # print 'At %s: %s' % (location,`value`)
    lastval = `value`
    return value

def stripextras(value):
    # we get rid of semicolons and leading/trailing terminators etc.
     import re
     jj = re.compile("[\n\r\f \t\v]*")
     semis = re.compile("[\n\r\f \t\v]*[\n\r\f]\n*;")
     cut = semis.match(value)
     if cut:
          nv = value[cut.end():len(value)-2]
          try:
             if nv[-1]=='\r': nv = nv[:-1]
          except IndexError:    #empty data value
             pass
     else: nv = value
     cut = jj.match(nv)
     if cut:
          return stripstring(nv[cut.end():])
     return nv

# helper function to get rid of inverted commas etc.

def stripstring(value):
     if value:
         if value[0]== '\'' and value[-1]=='\'':
           return value[1:-1]
         if value[0]=='"' and value[-1]=='"':
           return value[1:-1]
     return value

# helper function to create a dictionary given a set of
# looped datanames and data values

def makeloop(namelist,itemlist,context):
    noitems = len(namelist)
    nopoints = divmod(len(itemlist),noitems)
    if nopoints[1]!=0:    #mismatch
        raise CifError, "loop item mismatch"
    nopoints = nopoints[0]
    # check no overlap between separate loops!
    new_lower = map(lambda a:a.lower(),namelist)
    for loop in context:
        for key in loop.keys():
            if key.lower() in new_lower:
                raise CifError, "Duplicate item name %s" % key
    newdict = {}
    for i in range(0,noitems):
        templist = []
        for j in range(0,nopoints):
            templist.append(itemlist[j*noitems + i])
        lower_keys = map(lambda a:a.lower(),newdict.keys())
        if namelist[i].lower() in lower_keys:
            raise CifError, "%s occurs twice in same loop" % namelist[i]
        newdict.update({namelist[i]:templist})
    context.append(newdict)
    #print 'Constructed loop with items: '+`newdict`
    return {}    # to keep things easy

# this function updates a dictionary first checking for name collisions,
# which imply that the CIF is invalid.  We need case insensitivity for
# names. 

# Unfortunately we cannot check loop item contents against non-loop contents
# in a non-messy way during parsing, as we may not have easy access to previous
# key value pairs in the context of our call (unlike our built-in access to all 
# previous loops).
# For this reason, we don't waste time checking looped items against non-looped
# names during parsing of a data block.  This would only match a subset of the
# final items.   We do check against ordinary items, however.
#
# Note the following situations:
# (1) new_dict is empty -> we have just added a loop; do no checking
# (2) new_dict is not empty -> we have some new key-value pairs
#
def cif_update(old_dict,new_dict,loops):
    old_keys = map(lambda a:a.lower(),old_dict.keys())
    if new_dict != {}:    # otherwise we have a new loop
        #print 'Comparing %s to %s' % (`old_keys`,`new_dict.keys()`)
        for new_key in new_dict.keys():
            if new_key.lower() in old_keys:
                raise CifError, "Duplicate dataname or blockname %s in input file" % new_key
            old_dict[new_key] = new_dict[new_key]
#

from string import *
import re
from yappsrt import *

class CifParserScanner(Scanner):
    patterns = [
        ('([ \t\n\r](?!;))|[ \t]', re.compile('([ \t\n\r](?!;))|[ \t]')),
        ('#.*[\n\r](?!;)', re.compile('#.*[\n\r](?!;)')),
        ('#.*', re.compile('#.*')),
        ('LBLOCK', re.compile('(L|l)(O|o)(O|o)(P|p)_')),
        ('save_heading', re.compile('(S|s)(A|a)(V|v)(E|e)_[][!%&\\(\\)*+,./:<=>?@0-9A-Za-z\\\\^`{}\\|~"#$\';_-]+')),
        ('save_end', re.compile('(S|s)(A|a)(V|v)(E|e)_')),
        ('RESERVED', re.compile('((G|g)(L|l)(O|o)(B|b)(A|a)(L|l)_)|((S|s)(T|t)(O|o)(P|p)_)')),
        ('data_name', re.compile('_[][!%&\\(\\)*+,./:<=>?@0-9A-Za-z\\\\^`{}\\|~"#$\';_-]+')),
        ('data_heading', re.compile('(D|d)(A|a)(T|t)(A|a)_[][!%&\\(\\)*+,./:<=>?@0-9A-Za-z\\\\^`{}\\|~"#$\';_-]+')),
        ('start_sc_line', re.compile('(\n|\r\n);([^\n\r])*(\r\n|\r|\n)+')),
        ('sc_line_of_text', re.compile('[^;\r\n]([^\r\n])*(\r\n|\r|\n)+')),
        ('end_sc_line', re.compile(';')),
        ('data_value_1', re.compile('((?!(((S|s)(A|a)(V|v)(E|e)_[^\\s]*)|((G|g)(L|l)(O|o)(B|b)(A|a)(L|l)_[^\\s]*)|((S|s)(T|t)(O|o)(P|p)_[^\\s]*)|((D|d)(A|a)(T|t)(A|a)_[^\\s]*)))[^\\s"#$\'_\\[\\]][^\\s]*)|\'((\'(?=\\S))|([^\n\r\x0c\']))*\'+|"(("(?=\\S))|([^\n\r"]))*"+')),
        ('END', re.compile('$')),
    ]
    def __init__(self, str):
        Scanner.__init__(self,None,['([ \t\n\r](?!;))|[ \t]', '#.*[\n\r](?!;)', '#.*'],str)

class CifParser(Parser):
    def input(self):
        _token_ = self._peek('END', 'data_heading')
        if _token_ == 'data_heading':
            dblock = self.dblock()
            maindict = dblock
            while self._peek('END', 'data_heading') == 'data_heading':
                dblock = self.dblock()
                cif_update(maindict,monitor('input',dblock),[])
            END = self._scan('END')
        else: # == 'END'
            END = self._scan('END')
            maindict = {}
        return maindict

    def dblock(self):
        data_heading = self._scan('data_heading')
        dict={data_heading[5:]:{"loops":[],"saves":{} } }
        while self._peek('save_heading', 'LBLOCK', 'data_name', 'END', 'data_heading') not in ['END', 'data_heading']:
            _token_ = self._peek('save_heading', 'LBLOCK', 'data_name')
            if _token_ != 'save_heading':
                dataseq = self.dataseq(dict[data_heading[5:]]["loops"])
                cif_update(dict[data_heading[5:]],dataseq,[])
            else: # == 'save_heading'
                save_frame = self.save_frame()
                dict[data_heading[5:]]["saves"].update(save_frame)
        return monitor('dblock',dict)

    def dataseq(self, loop_array):
        data = self.data(loop_array)
        datadict=data
        while self._peek('LBLOCK', 'data_name', 'save_end', 'save_heading', 'END', 'data_heading') in ['LBLOCK', 'data_name']:
            data = self.data(loop_array)
            cif_update(datadict,data,loop_array)
        return monitor('dataseq',datadict)

    def data(self, loop_array):
        _token_ = self._peek('LBLOCK', 'data_name')
        if _token_ == 'LBLOCK':
            data_loop = self.data_loop(loop_array)
            return data_loop
        else: # == 'data_name'
            datakvpair = self.datakvpair()
            return datakvpair

    def datakvpair(self):
        data_name = self._scan('data_name')
        data_value = self.data_value()
        return {data_name:data_value}

    def data_value(self):
        _token_ = self._peek('data_value_1', 'start_sc_line')
        if _token_ == 'data_value_1':
            data_value_1 = self._scan('data_value_1')
            thisval = stripstring(data_value_1)
        else: # == 'start_sc_line'
            sc_lines_of_text = self.sc_lines_of_text()
            thisval = stripextras(sc_lines_of_text)
        return monitor('data_value',thisval)

    def sc_lines_of_text(self):
        start_sc_line = self._scan('start_sc_line')
        lines = start_sc_line
        while self._peek('sc_line_of_text', 'end_sc_line') == 'sc_line_of_text':
            sc_line_of_text = self._scan('sc_line_of_text')
            lines = lines+sc_line_of_text
        end_sc_line = self._scan('end_sc_line')
        return monitor('sc_line_of_text',lines+end_sc_line)

    def data_loop(self, loop_array):
        LBLOCK = self._scan('LBLOCK')
        loopfield = self.loopfield()
        loopvalues = self.loopvalues()
        return makeloop(loopfield,loopvalues,loop_array)

    def loopfield(self):
        data_name = self._scan('data_name')
        loop=[data_name]
        while self._peek('data_name', 'data_value_1', 'start_sc_line') == 'data_name':
            data_name = self._scan('data_name')
            loop.append(data_name)
        return loop

    def loopvalues(self):
        data_value = self.data_value()
        loop=[data_value]
        while self._peek('data_value_1', 'start_sc_line', 'LBLOCK', 'data_name', 'save_end', 'save_heading', 'END', 'data_heading') in ['data_value_1', 'start_sc_line']:
            data_value = self.data_value()
            loop.append(monitor('loopval',data_value))
        return loop

    def save_frame(self):
        save_heading = self._scan('save_heading')
        savedict = {save_heading[5:]:{"loops":[] } }
        while self._peek('save_end', 'LBLOCK', 'data_name') != 'save_end':
            dataseq = self.dataseq(savedict[save_heading[5:]]["loops"])
            savedict[save_heading[5:]].update(dataseq)
        save_end = self._scan('save_end')
        return monitor('save_frame',savedict)


def parse(rule, text):
    P = CifParser(CifParserScanner(text))
    return wrap_error_reporter(P, rule)



