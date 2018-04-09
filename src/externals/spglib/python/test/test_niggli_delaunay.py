import unittest
try:
    from StringIO import StringIO
except ImportError:
    from io import StringIO
import numpy as np
from spglib import niggli_reduce, delaunay_reduce
from vasp import read_vasp

def get_lattice_parameters(lattice):
    return np.sqrt(np.dot(lattice, lattice.T).diagonal())

def get_angles(lattice):
    a, b, c = get_lattice_parameters(lattice)
    alpha = np.arccos(np.vdot(lattice[1,:], lattice[2,:]) / b / c)
    beta  = np.arccos(np.vdot(lattice[2,:], lattice[0,:]) / c / a)
    gamma = np.arccos(np.vdot(lattice[0,:], lattice[1,:]) / a / b)
    return np.array([alpha, beta, gamma]) / np.pi * 180

class TestNiggliDelaunay(unittest.TestCase):
    def setUp(self):
        self._input_lattices = self._read_file("lattices.dat")
        self._niggli_lattices = self._read_file("niggli_lattices.dat")
        self._delaunay_lattices = self._read_file("delaunay_lattices.dat")
    
    def tearDown(self):
        pass

    def test_niggli_angles(self):
        for i, reference_lattice in enumerate(self._niggli_lattices):
            angles = np.array(get_angles(reference_lattice))
            self.assertTrue((angles > 90 - 1e-3).all() or
                            (angles < 90 + 1e-3).all(),
                            msg=("%d %s" % (i + 1, angles)))
    
    def test_niggli_reduce(self):
        self._reduce(niggli_reduce, self._niggli_lattices)

    def test_delaunay_reduce(self):
        self._reduce(delaunay_reduce, self._delaunay_lattices)

    def _reduce(self, func, ref_data):
        for i, (input_lattice, reference_lattice) in enumerate(
                zip(self._input_lattices, ref_data)):
            reduced_lattice = func(input_lattice)
            # self._show_lattice(i, reduced_lattice)
            self.assertTrue(np.allclose([np.linalg.det(input_lattice)],
                                        [np.linalg.det(reduced_lattice)]))
            T = np.dot(np.linalg.inv(reference_lattice.T), input_lattice.T)
            self.assertTrue(np.allclose(T, np.rint(T)))
            self.assertTrue(
                np.allclose(reduced_lattice, reference_lattice),
                msg="\n".join(
                    ["# %d" % (i + 1),
                     "Input lattice",
                     "%s" % input_lattice,
                     " angles: %s" % np.array(get_angles(input_lattice)),
                     "Reduced lattice in reference data",
                     "%s" % reference_lattice,
                     " angles: %s" % np.array(get_angles(reference_lattice)),
                     "Reduced lattice",
                     "%s" % reduced_lattice,
                     " angles: %s" % np.array(get_angles(reduced_lattice))]))

    def _read_file(self, filename):
        all_lattices = []
        with open(filename) as f:
            lattice = []
            for line in f:
                if line[0] == '#':
                    continue
                lattice.append([float(x) for x in line.split()])
                if len(lattice) == 3:
                    all_lattices.append(lattice)
                    lattice = []
        return np.array(all_lattices)

    def _show_lattice(self, i, lattice):
        print("# %d" % (i + 1))
        for v in lattice:
            print(" ".join(["%20.16f" % x for x in v]))        


if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(TestNiggliDelaunay)
    unittest.TextTestRunner(verbosity=2).run(suite)
    # unittest.main()
