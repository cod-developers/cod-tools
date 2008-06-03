from cctbx import geometry_restraints
from cctbx.array_family import flex
import scitbx.restraints
from stdlib import math
import sys

class energies(scitbx.restraints.energies):

  def __init__(self, sites_cart,
                     bond_proxies=None,
                     nonbonded_proxies=None,
                     nonbonded_function=None,
                     angle_proxies=None,
                     dihedral_proxies=None,
                     chirality_proxies=None,
                     planarity_proxies=None,
                     compute_gradients=True,
                     gradients=None,
                     disable_asu_cache=False,
                     normalization=False):
    self.sites_cart = sites_cart
    self.bond_proxies = bond_proxies
    self.nonbonded_proxies = nonbonded_proxies
    self.nonbonded_function = nonbonded_function
    self.angle_proxies = angle_proxies
    self.dihedral_proxies = dihedral_proxies
    self.chirality_proxies = chirality_proxies
    self.planarity_proxies = planarity_proxies
    self.compute_gradients = compute_gradients
    self.gradients = gradients
    self.disable_asu_cache = disable_asu_cache
    self.normalization = normalization
    scitbx.restraints.energies.__init__(self,
      compute_gradients=compute_gradients,
      gradients=gradients,
      gradients_size=sites_cart.size(),
      gradients_factory=flex.vec3_double,
      normalization=normalization)
    if (nonbonded_proxies is not None): assert nonbonded_function is not None
    if (compute_gradients):
      if (self.gradients is None):
        self.gradients = flex.vec3_double(sites_cart.size(), [0,0,0])
      else:
        assert self.gradients.size() == sites_cart.size()
    if (bond_proxies is None):
      self.n_bond_proxies = None
      self.bond_residual_sum = 0
    else:
      self.n_bond_proxies = bond_proxies.n_total()
      self.bond_residual_sum = geometry_restraints.bond_residual_sum(
        sites_cart=sites_cart,
        sorted_asu_proxies=bond_proxies,
        gradient_array=self.gradients,
        disable_cache=disable_asu_cache)
      self.number_of_restraints += self.n_bond_proxies
      self.residual_sum += self.bond_residual_sum
    if (nonbonded_proxies is None):
      self.n_nonbonded_proxies = None
      self.nonbonded_residual_sum = 0
    else:
      self.n_nonbonded_proxies = nonbonded_proxies.n_total()
      self.nonbonded_residual_sum = geometry_restraints.nonbonded_residual_sum(
        sites_cart=sites_cart,
        sorted_asu_proxies=nonbonded_proxies,
        gradient_array=self.gradients,
        function=nonbonded_function,
        disable_cache=False)
      self.number_of_restraints += self.n_nonbonded_proxies
      self.residual_sum += self.nonbonded_residual_sum
    if (angle_proxies is None):
      self.n_angle_proxies = None
      self.angle_residual_sum = 0
    else:
      self.n_angle_proxies = len(angle_proxies)
      self.angle_residual_sum = geometry_restraints.angle_residual_sum(
        sites_cart=sites_cart,
        proxies=angle_proxies,
        gradient_array=self.gradients)
      self.number_of_restraints += self.n_angle_proxies
      self.residual_sum += self.angle_residual_sum
    if (dihedral_proxies is None):
      self.n_dihedral_proxies = None
      self.dihedral_residual_sum = 0
    else:
      self.n_dihedral_proxies = len(dihedral_proxies)
      self.dihedral_residual_sum = geometry_restraints.dihedral_residual_sum(
          sites_cart=sites_cart,
          proxies=dihedral_proxies,
          gradient_array=self.gradients)
      self.number_of_restraints += self.n_dihedral_proxies
      self.residual_sum += self.dihedral_residual_sum
    if (chirality_proxies is None):
      self.n_chirality_proxies = None
      self.chirality_residual_sum = 0
    else:
      self.n_chirality_proxies = len(chirality_proxies)
      self.chirality_residual_sum = geometry_restraints.chirality_residual_sum(
          sites_cart=sites_cart,
          proxies=chirality_proxies,
          gradient_array=self.gradients)
      self.number_of_restraints += self.n_chirality_proxies
      self.residual_sum += self.chirality_residual_sum
    if (planarity_proxies is None):
      self.n_planarity_proxies = None
      self.planarity_residual_sum = 0
    else:
      self.n_planarity_proxies = len(planarity_proxies)
      self.planarity_residual_sum = geometry_restraints.planarity_residual_sum(
          sites_cart=sites_cart,
          proxies=planarity_proxies,
          gradient_array=self.gradients)
      self.number_of_restraints += self.n_planarity_proxies
      self.residual_sum += self.planarity_residual_sum
    self.finalize_target_and_gradients()

  def bond_deviations(self):
    if(self.n_bond_proxies is not None):
       bond_deltas = geometry_restraints.bond_deltas(
                                        sites_cart         = self.sites_cart,
                                        sorted_asu_proxies = self.bond_proxies)
       b_sq  = bond_deltas * bond_deltas
       b_ave = math.sqrt(flex.mean_default(b_sq, 0))
       b_max = math.sqrt(flex.max_default(b_sq, 0))
       b_min = math.sqrt(flex.min_default(b_sq, 0))
       return b_min, b_max, b_ave

  def angle_deviations(self):
    if(self.n_angle_proxies is not None):
       angle_deltas = geometry_restraints.angle_deltas(
                                               sites_cart = self.sites_cart,
                                               proxies    = self.angle_proxies)
       a_sq  = angle_deltas * angle_deltas
       a_ave = math.sqrt(flex.mean_default(a_sq, 0))
       a_max = math.sqrt(flex.max_default(a_sq, 0))
       a_min = math.sqrt(flex.min_default(a_sq, 0))
       return a_min, a_max, a_ave

  def nonbonded_distances(self):
    return geometry_restraints.nonbonded_deltas(
                                  sites_cart         = self.sites_cart,
                                  sorted_asu_proxies = self.nonbonded_proxies)

  def nonbonded_deviations(self):
    if(self.n_nonbonded_proxies is not None):
       nonbonded_deltas = self.nonbonded_distances()
       r_sq  = nonbonded_deltas * nonbonded_deltas
       r_ave = math.sqrt(flex.mean_default(r_sq, 0))
       r_max = math.sqrt(flex.max_default(r_sq, 0))
       r_min = math.sqrt(flex.min_default(r_sq, 0))
       return r_min, r_max, r_ave

  def dihedral_deviations(self):
    if(self.n_dihedral_proxies is not None):
       dihedral_deltas = geometry_restraints.dihedral_deltas(
                                            sites_cart = self.sites_cart,
                                            proxies    = self.dihedral_proxies)
       d_sq  = dihedral_deltas * dihedral_deltas
       d_ave = math.sqrt(flex.mean_default(d_sq, 0))
       d_max = math.sqrt(flex.max_default(d_sq, 0))
       d_min = math.sqrt(flex.min_default(d_sq, 0))
       return d_min, d_max, d_ave

  def chirality_deviations(self):
    if(self.n_chirality_proxies is not None):
       chirality_deltas = geometry_restraints.chirality_deltas(
                                           sites_cart = self.sites_cart,
                                           proxies    = self.chirality_proxies)
       c_sq  = chirality_deltas * chirality_deltas
       c_ave = math.sqrt(flex.mean_default(c_sq, 0))
       c_max = math.sqrt(flex.max_default(c_sq, 0))
       c_min = math.sqrt(flex.min_default(c_sq, 0))
       return c_min, c_max, c_ave

  def planarity_deviations(self):
    if(self.n_planarity_proxies is not None):
       planarity_deltas = geometry_restraints.planarity_deltas_rms(
                                           sites_cart = self.sites_cart,
                                           proxies    = self.planarity_proxies)
       p_sq  = planarity_deltas * planarity_deltas
       p_ave = math.sqrt(flex.mean_default(p_sq, 0))
       p_max = math.sqrt(flex.max_default(p_sq, 0))
       p_min = math.sqrt(flex.min_default(p_sq, 0))
       return p_min, p_max, p_ave

  def show(self, f=None, prefix=""):
    if (f is None): f = sys.stdout
    print >> f, prefix+"target: %.6g" % self.target
    if (self.n_bond_proxies is not None):
      print >> f, prefix+"  bond_residual_sum (n=%d): %.6g" % (
        self.n_bond_proxies, self.bond_residual_sum)
    if (self.n_nonbonded_proxies is not None):
      print >> f, prefix+"  nonbonded_residual_sum (n=%d): %.6g" % (
        self.n_nonbonded_proxies, self.nonbonded_residual_sum)
    if (self.n_angle_proxies is not None):
      print >> f, prefix+"  angle_residual_sum (n=%d): %.6g" % (
        self.n_angle_proxies, self.angle_residual_sum)
    if (self.n_dihedral_proxies is not None):
      print >> f, prefix+"  dihedral_residual_sum (n=%d): %.6g" % (
        self.n_dihedral_proxies, self.dihedral_residual_sum)
    if (self.n_chirality_proxies is not None):
      print >> f, prefix+"  chirality_residual_sum (n=%d): %.6g" % (
        self.n_chirality_proxies, self.chirality_residual_sum)
    if (self.n_planarity_proxies is not None):
      print >> f, prefix+"  planarity_residual_sum (n=%d): %.6g" % (
        self.n_planarity_proxies, self.planarity_residual_sum)
    if (self.gradients is not None):
      print >> f, prefix+"  norm of gradients: %.6g" % self.gradients.norm()
