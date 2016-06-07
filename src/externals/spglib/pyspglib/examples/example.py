#!/usr/bin/evn python

import sys
from pyspglib import spglib
import numpy as np

#######################################
# Uncomment to use Atoms class in ASE #
#######################################
# from ase import Atoms

##################################################################
# Using the local Atoms class (BSE license) where a small set of #
# ASE Atoms features is comaptible but enough for this example.  #
##################################################################
from atoms import Atoms

def show_symmetry(symmetry):
    for i in range(symmetry['rotations'].shape[0]):
        print "  --------------- %4d ---------------" % (i+1)
        rot = symmetry['rotations'][i]
        trans = symmetry['translations'][i]
        print "  rotation:"
        for x in rot:
            print "     [%2d %2d %2d]" % (x[0], x[1], x[2])
        print "  translation:"
        print "     (%8.5f %8.5f %8.5f)" % (trans[0], trans[1], trans[2])


def show_cell(lattice, positions, numbers):
    print "Basis vectors:"
    for vec, axis in zip(lattice, ("a", "b", "c")):
        print "%s %10.5f %10.5f %10.5f" % (tuple(axis,) + tuple(vec))
    print "Atomic points:"
    for p, s in zip(positions, numbers):
        print "%2d %10.5f %10.5f %10.5f" % ((s,) + tuple(p))

silicon = Atoms(symbols=['Si'] * 8,
                cell=[(4, 0, 0),
                      (0, 4, 0),
                      (0, 0, 4)],
                scaled_positions=[(0, 0, 0),
                                  (0, 0.5, 0.5),
                                  (0.5, 0, 0.5),
                                  (0.5, 0.5, 0),
                                  (0.25, 0.25, 0.25),
                                  (0.25, 0.75, 0.75),
                                  (0.75, 0.25, 0.75),
                                  (0.75, 0.75, 0.25)],
                pbc=True)

silicon_dist = Atoms(symbols=['Si'] * 8,
                cell=[(4.01, 0, 0),
                      (0, 4, 0),
                      (0, 0, 3.99)],
                scaled_positions=[(0.001, 0, 0),
                                  (0, 0.5, 0.5),
                                  (0.5, 0, 0.5),
                                  (0.5, 0.5, 0),
                                  (0.25, 0.25, 0.251),
                                  (0.25, 0.75, 0.75),
                                  (0.75, 0.25, 0.75),
                                  (0.75, 0.75, 0.25)],
                pbc=True)

silicon_prim = Atoms(symbols=['Si'] * 2,
                     cell=[(0, 2, 2),
                           (2, 0, 2),
                           (2, 2, 0)],
                     scaled_positions=[(0, 0, 0),
                                       (0.25, 0.25, 0.25)],
                     pbc=True)

rutile = Atoms(symbols=['Si'] * 2 + ['O'] * 4,
               cell=[(4, 0, 0),
                     (0, 4, 0),
                     (0, 0, 3)],
               scaled_positions=[(0, 0, 0),
                                 (0.5, 0.5, 0.5),
                                 (0.3, 0.3, 0.0),
                                 (0.7, 0.7, 0.0),
                                 (0.2, 0.8, 0.5),
                                 (0.8, 0.2, 0.5)],
               pbc=True)

rutile_dist = Atoms(symbols=['Si'] * 2 + ['O'] * 4,
                    cell=[(3.97, 0, 0),
                          (0, 4.03, 0),
                          (0, 0, 3.0)],
                    scaled_positions=[(0, 0, 0),
                                      (0.5001, 0.5, 0.5),
                                      (0.3, 0.3, 0.0),
                                      (0.7, 0.7, 0.002),
                                      (0.2, 0.8, 0.5),
                                      (0.8, 0.2, 0.5)],
                    pbc=True)



a = 3.07
c = 3.52
MgB2 = Atoms( symbols=['Mg']+['B']*2,
              cell=[ ( a, 0, 0 ),
                     ( -a/2, a/2*np.sqrt(3), 0 ),
                     ( 0, 0, c ) ],
              scaled_positions=[ ( 0, 0, 0 ),
                                 ( 1.0/3, 2.0/3, 0.5 ),
                                 ( 2.0/3, 1.0/3, 0.5 ) ],
              pbc=True )

# For VASP case
# import vasp
# bulk = vasp.read_vasp(sys.argv[1])

print "[get_spacegroup]"
print "  Spacegroup of Silicon is ", spglib.get_spacegroup(silicon)
print
print "[get_spacegroup]"
print "  Spacegroup of Rutile is ", spglib.get_spacegroup(rutile)
print
print "[get_spacegroup]"
print "  Spacegroup of MgB2 is ", spglib.get_spacegroup(MgB2)
print
print "[get_symmetry]"
print "  Symmetry operations of Rutile unitcell are:"
print
symmetry = spglib.get_symmetry( rutile )
show_symmetry(symmetry)

print
print "[get_pointgroup]"
print "  Pointgroup of Rutile is", spglib.get_pointgroup(symmetry['rotations'])[0]
print

dataset = spglib.get_symmetry_dataset( rutile )
print "[get_symmetry_dataset] ['international']"
print "  Spacegroup of Rutile is %s (%d) " % (dataset['international'],
                                              dataset['number'])
print
print "[get_symmetry_dataset] ['pointgroup']"
print "  Pointgroup of Rutile is %s (%d)" % (dataset['pointgroup'], 
                                             dataset['pointgroup_number'])
print
print "[get_symmetry_dataset] ['hall']"
print "  Hall symbol of Rutile is %s (%d)" % (dataset['hall'],
                                              dataset['hall_number'])
print
print "[get_symmetry_dataset] ['wyckoffs']"
alphabet = "abcdefghijklmnopqrstuvwxyz"
print "  Wyckoff letters of Rutile are: ", dataset['wyckoffs']
print
print "[get_symmetry_dataset] ['equivalent_atoms']"
print "  Mapping to equivalent atoms of Rutile are: "
for i, x in enumerate( dataset['equivalent_atoms'] ):
  print "  %d -> %d" % ( i+1, x+1 )
print
print "[get_symmetry_dataset] ['rotations'], ['translations']"
print "  Symmetry operations of Rutile unitcell are:"
for i, (rot,trans) in enumerate( zip( dataset['rotations'], dataset['translations'] ) ):
    print "  --------------- %4d ---------------" % (i+1)
    print "  rotation:"
    for x in rot:
        print "     [%2d %2d %2d]" % (x[0], x[1], x[2])
    print "  translation:"
    print "     (%8.5f %8.5f %8.5f)" % (trans[0], trans[1], trans[2])
print

print "[refine_cell]"
print " Refine distorted rutile structure"
lattice, positions, numbers = spglib.refine_cell(rutile_dist, symprec=1e-1)
show_cell(lattice, positions, numbers)
print

print "[standardize_cell]"
print " Standardize distorted rutile structure:"
print " (to_primitive=0 and no_idealize=0)"
lattice, positions, numbers = spglib.standardize_cell(rutile_dist,
                                                      to_primitive=0,
                                                      no_idealize=0,
                                                      symprec=1e-1)
show_cell(lattice, positions, numbers)
print

print "[standardize_cell]"
print " Standardize distorted rutile structure:"
print " (to_primitive=0 and no_idealize=1)"
lattice, positions, numbers = spglib.standardize_cell(rutile_dist,
                                                      to_primitive=0,
                                                      no_idealize=1,
                                                      symprec=1e-1)
show_cell(lattice, positions, numbers)
print

print "[standardize_cell]"
print " Standardize distorted silicon structure:"
print " (to_primitive=1 and no_idealize=0)"
lattice, positions, numbers = spglib.standardize_cell(silicon_dist,
                                                      to_primitive=1,
                                                      no_idealize=0,
                                                      symprec=1e-1)
show_cell(lattice, positions, numbers)
print

print "[standardize_cell]"
print " Standardize distorted silicon structure:"
print " (to_primitive=1 and no_idealize=1)"
lattice, positions, numbers = spglib.standardize_cell(silicon_dist,
                                                      to_primitive=1,
                                                      no_idealize=1,
                                                      symprec=1e-1)
show_cell(lattice, positions, numbers)
print

symmetry = spglib.get_symmetry(silicon)
print "[get_symmetry]"
print "  Number of symmetry operations of silicon conventional"
print "  unit cell is ", len( symmetry['rotations'] ), "(192)."
show_symmetry(symmetry)
print

symmetry = spglib.get_symmetry_from_database(525)
print "[get_symmetry_from_database]"
print "  Number of symmetry operations of silicon conventional"
print "  unit cell is ", len( symmetry['rotations'] ), "(192)."
show_symmetry(symmetry)
print



mapping, grid = spglib.get_ir_reciprocal_mesh( [ 11, 11, 11 ],
                                               silicon_prim,
                                               is_shift=[ 0, 0, 0 ] )
num_ir_kpt = len( np.unique( mapping ) )
print "[get_ir_reciprocal_mesh]"
print "  Number of irreducible k-points of primitive silicon with"
print "  11x11x11 Monkhorst-Pack mesh is ", num_ir_kpt, "(56)."
print

mapping, grid = spglib.get_ir_reciprocal_mesh( [ 8, 8, 8 ],
                                               rutile,
                                               is_shift=[ 1, 1, 1 ] )
num_ir_kpt = len( np.unique( mapping ) )
print "[get_ir_reciprocal_mesh]"
print "  Number of irreducible k-points of Rutile with"
print "  8x8x8 Monkhorst-Pack mesh is ", num_ir_kpt, "(40)."
print

mapping, grid = spglib.get_ir_reciprocal_mesh( [ 9, 9, 8 ],
                                               MgB2,
                                               is_shift=[ 0, 0, 1 ] )
num_ir_kpt = len( np.unique( mapping ) )
print "[get_ir_reciprocal_mesh]"
print "  Number of irreducible k-points of MgB2 with"
print "  9x9x8 Monkhorst-Pack mesh is ", num_ir_kpt, "(48)."
print
