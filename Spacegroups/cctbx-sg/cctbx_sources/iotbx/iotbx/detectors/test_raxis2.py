# basic test reading an Raxis II image & producing a png file
# requires LABELIT and Python Image Library
# future: remove the LABELIT dependency

import StringIO,sys
from labelit.command_line.overlay_distl import OverlayDriverClass

filnm = sys.argv[1] # raxis-2 *.osc file
out = sys.argv[2] # *.png file for graphical output

ODC = OverlayDriverClass(filnm)
ODC.pd={'xbeam':ODC.I.a.parameters['BEAM_CENTER_X'],
        'ybeam':ODC.I.a.parameters['BEAM_CENTER_Y'],
        'pixel_size':ODC.I.a.parameters['PIXEL_SIZE']}
ODC.beam_overlay()
ioout = StringIO.StringIO()
ODC.I.output(ioout)
g = open(out,"wb")
g.write(ioout.getvalue())
g.close()
