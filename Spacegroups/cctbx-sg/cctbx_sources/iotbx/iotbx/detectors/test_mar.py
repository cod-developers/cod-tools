import sys
import Image # dependency on Python Image Library

class ImageWorker(object):
  def __init__(self,relpath):
    from iotbx.detectors import mar
    from labelit.detectors import FlexImage
    m = mar.MARImage(relpath)
    m.read()
    self.fi = FlexImage(m.linearintdata,2) #binning parameter (1 or 2)
    self.fi.setWindow(1.0) #fraction of original image dimension written to graphics display
    self.fi.adjust()

  def output(self,outputfile):
    im = Image.new("RGB",(self.fi.ex_size1(), self.fi.ex_size2())) # 'L' is grayscale
    r,g,b = im.split()
    r.putdata(self.fi.channel(0))
    g.putdata(self.fi.channel(1))
    b.putdata(self.fi.channel(2))
    imageout = Image.merge("RGB",(r,g,b))
    imageout.save(outputfile,"PNG")

if __name__=='__main__':
  infile = sys.argv[1]
  outfile = "/net/racer/scratch1/ttleese/test2.png"
  I = ImageWorker(infile)
  print "Finished read"
  I.output(outfile)
  print "Finished write"
