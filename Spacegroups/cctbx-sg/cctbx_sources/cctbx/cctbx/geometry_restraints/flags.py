from libtbx import adopt_init_args
import sys

class flags(object):

  def __init__(self,
        bond=None,
        nonbonded=None,
        angle=None,
        dihedral=None,
        chirality=None,
        planarity=None,
        default=False):
    if (bond is None): bond = default
    if (nonbonded is None): nonbonded = default
    if (angle is None): angle = default
    if (dihedral is None): dihedral = default
    if (chirality is None): chirality = default
    if (planarity is None): planarity = default
    adopt_init_args(self, locals())

  def show(self, f=None):
    if (f is None): f = sys.stdout
    print >> f, "geometry_restraints.manager.flags:"
    print >> f, "  bond:", self.bond
    print >> f, "  nonbonded:", self.nonbonded
    print >> f, "  angle:", self.angle
    print >> f, "  dihedral:", self.dihedral
    print >> f, "  chirality:", self.chirality
    print >> f, "  planarity:", self.planarity
