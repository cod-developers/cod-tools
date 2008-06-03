from mmtbx import dynamics
from mmtbx.refinement import print_statistics
from cctbx import geometry_restraints
from cctbx import xray
from cctbx import crystal
from cctbx.array_family import flex
import scitbx.lbfgs
from libtbx.utils import Sorry
from libtbx import adopt_init_args
import random
import time
import math
import sys

class interleaved_lbfgs_minimization(object):

  def __init__(self,
        conservative_pair_proxies,
        sites_cart,
        max_iterations):
    self.conservative_pair_proxies = conservative_pair_proxies
    self.x = sites_cart.as_double()
    self.minimizer = scitbx.lbfgs.run(
      target_evaluator=self,
      termination_params=scitbx.lbfgs.termination_parameters(
        max_iterations=max_iterations),
      exception_handling_params=scitbx.lbfgs.exception_handling_parameters(
        ignore_line_search_failed_rounding_errors=True,
        ignore_line_search_failed_step_at_lower_bound=True,
        ignore_line_search_failed_maxfev=True))
    sites_cart.clear()
    sites_cart.extend(flex.vec3_double(self.x))

  def compute_functional_and_gradients(self):
    sites_cart = flex.vec3_double(self.x)
    f = 0
    g = flex.vec3_double(sites_cart.size(), (0,0,0))
    for sorted_asu_proxies in [self.conservative_pair_proxies.bond,
                               self.conservative_pair_proxies.angle]:
      if (sorted_asu_proxies is None): continue
      f += geometry_restraints.bond_residual_sum(
        sites_cart=sites_cart,
        sorted_asu_proxies=sorted_asu_proxies,
        gradient_array=g)
    return f, g.as_double()

class cartesian_dynamics(object):
  def __init__(self,
               structure,
               restraints_manager,
               temperature                 = 300,
               n_steps                     = 200,
               time_step                   = 0.0005,
               initial_velocities_zero_fraction = 0,
               interleaved_minimization_params = None,
               n_print                     = 20,
               fmodel                      = None,
               xray_target_weight          = None,
               chem_target_weight          = None,
               shift_update                = None,
               xray_structure_last_updated = None,
               xray_gradient               = None,
               reset_velocities            = True,
               log=None,
               verbose=-1):
    adopt_init_args(self, locals())
    assert self.n_print > 0
    assert self.temperature >= 0.0
    assert self.n_steps >= 0
    assert self.time_step >= 0.0
    assert self.log is not None or self.verbose < 1
    xray.set_scatterer_grad_flags(scatterers = self.structure.scatterers(),
                                  site       = True)
    self.structure_start = self.structure.deep_copy_scatterers()
    self.k_boltz = 1.380662e-03
    self.current_temperature = 0.0
    self.ekin = 0.0
    self.ekcm = 0.0
    self.timfac = 0.04888821
    self.weights = self.structure.atomic_weights()
    self.vxyz = flex.vec3_double(self.weights.size(),(0,0,0))
    if(self.fmodel is not None):
      self.fmodel_copy = self.fmodel.deep_copy()
      self.target_functor = self.fmodel_copy.target_functor()
      assert self.chem_target_weight is not None
      assert self.xray_target_weight is not None
      if(self.xray_gradient is None):
        self.xray_gradient = self.xray_grads()
    #
    imp = self.interleaved_minimization_params
    self.interleaved_minimization_flag = (
      imp is not None and imp.number_of_iterations > 0)
    if (self.interleaved_minimization_flag):
      assert imp.time_step_factor > 0
      self.time_step *= imp.time_step_factor
      if ("bonds" not in imp.restraints):
        raise Sorry(
          'Invalid choice: %s.restraints: "bonds" must always be included.'
            % imp.__phil_path__())
      self.interleaved_minimization_angles = "angles" in imp.restraints
    else:
      self.interleaved_minimization_angles = False
    #
    self.tstep = self.time_step / self.timfac
    #
    self()

  def __call__(self):
    self.center_of_mass_info()
    kt = dynamics.kinetic_energy_and_temperature(self.vxyz,self.weights)
    self.current_temperature = kt.temperature()
    self.ekin = kt.kinetic_energy()
    if(self.verbose >= 1):
      print_dynamics_stat(self.log,self.temperature,self.current_temperature,
                          self.time_step,self.n_steps,self.rcm,self.vcm,
                          self.ekcm,self.acm,self.ekin,
                          "restrained dynamics start")
    if(self.reset_velocities):
       self.set_velocities()
       self.center_of_mass_info()
       kt = dynamics.kinetic_energy_and_temperature(self.vxyz,self.weights)
       self.current_temperature = kt.temperature()
       self.ekin = kt.kinetic_energy()
       if(self.verbose >= 1):
         print_dynamics_stat(self.log,self.temperature,self.current_temperature,
                             self.time_step,self.n_steps,self.rcm,self.vcm,
                             self.ekcm,self.acm,self.ekin,
                             "set velocities")
    self.stop_global_motion()
    self.center_of_mass_info()
    kt = dynamics.kinetic_energy_and_temperature(self.vxyz,self.weights)
    self.current_temperature = kt.temperature()
    self.ekin = kt.kinetic_energy()
    if(self.verbose >= 1):
      print_dynamics_stat(self.log,self.temperature,self.current_temperature,
                          self.time_step,self.n_steps,self.rcm,self.vcm,
                          self.ekcm,self.acm,self.ekin,
                          "center of mass motion removed")

    self.velocity_rescaling()
    self.center_of_mass_info()
    kt = dynamics.kinetic_energy_and_temperature(self.vxyz,self.weights)
    self.current_temperature = kt.temperature()
    self.ekin = kt.kinetic_energy()
    if(self.verbose >= 1):
      print_dynamics_stat(self.log,self.temperature,self.current_temperature,
                          self.time_step,self.n_steps,self.rcm,self.vcm,
                          self.ekcm,self.acm,self.ekin,
                          "velocities rescaled")
    if(self.verbose >= 1):
      print >> self.log, "integration starts"
    self.verlet_leapfrog_integration()

    self.center_of_mass_info()
    kt = dynamics.kinetic_energy_and_temperature(self.vxyz,self.weights)
    self.current_temperature = kt.temperature()
    self.ekin = kt.kinetic_energy()
    if(self.verbose >= 1):
      print_dynamics_stat(self.log,self.temperature,self.current_temperature,
                          self.time_step,self.n_steps,self.rcm,self.vcm,
                          self.ekcm,self.acm,self.ekin,
                          "after final integration step")

  def set_velocities(self):
    ivzf = self.initial_velocities_zero_fraction
    rg = random.gauss
    rr = random.random
    mean = 0.0
    for j,atom_weight in enumerate(self.weights):
      if (ivzf == 0 or rr() >= ivzf):
        factor = math.sqrt(self.k_boltz / atom_weight)
        sigma = factor * math.sqrt(self.temperature)
        self.vxyz[j] = [rg(mean,sigma) for i in (1,2,3)]
      else:
        self.vxyz[j] = [0, 0, 0]

  def residuals(self):
    obj = self.restraints_manager.energies_sites(
                               sites_cart        = self.structure.sites_cart(),
                               compute_gradients = True)
    chem_grads = obj.gradients
    gradient = chem_grads
    if(self.fmodel is not None):
      array_of_distances_between_each_atom = \
        flex.sqrt(self.structure.difference_vectors_cart(self.xray_structure_last_updated).dot())
      d_max = flex.max(array_of_distances_between_each_atom)
      if(d_max > self.shift_update):
        self.xray_structure_last_updated = self.structure.deep_copy_scatterers()
        self.xray_gradient = self.xray_grads()
      gradient = self.xray_gradient * self.xray_target_weight + \
                 chem_grads * self.chem_target_weight
    return gradient * obj.number_of_restraints # XXX BIGGEST MYSTERY !!!

  def xray_grads(self):
    self.fmodel_copy.update_xray_structure(xray_structure = self.structure,
                                           update_f_calc            = True,
                                           update_f_mask            = False,
                                           update_f_ordered_solvent = False)
    sf = self.target_functor(
      compute_gradients=True).gradients_wrt_atomic_parameters(site=True)
    return flex.vec3_double(sf.packed())

  def center_of_mass_info(self):
    self.rcm = self.structure.center_of_mass()
    timfac = 0.04888821
    vxcm = 0.0
    vycm = 0.0
    vzcm = 0.0
    axcm = 0.0
    aycm = 0.0
    azcm = 0.0
    xcm = 0.0
    ycm = 0.0
    zcm = 0.0
    tmass = 0
    sites = self.structure.sites_cart()
    for site,velocity,weight in zip(sites,self.vxyz,self.weights):
      tmass += weight
      vxcm += velocity[0] * weight
      vycm += velocity[1] * weight
      vzcm += velocity[2] * weight
      xcm += site[0] * weight
      ycm += site[1] * weight
      zcm += site[2] * weight
      axcm += (site[1] * velocity[2] - site[2] * velocity[1]) * weight
      aycm += (site[2] * velocity[0] - site[0] * velocity[2]) * weight
      azcm += (site[0] * velocity[1] - site[1] * velocity[0]) * weight
    axcm -= (ycm * vzcm - zcm * vycm) / tmass
    aycm -= (zcm * vxcm - xcm * vzcm) / tmass
    azcm -= (xcm * vycm - ycm * vxcm) / tmass
    vxcm /= tmass
    vycm /= tmass
    vzcm /= tmass
    self.vcm = flex.vec3_double()
    self.acm = flex.vec3_double()
    self.vcm.append((vxcm,vycm,vzcm))
    self.acm.append((axcm,aycm,azcm))
    self.ekcm = (vxcm**2 + vycm**2 + vzcm**2) * tmass * 0.5

  def stop_global_motion(self):
    self.rcm = self.structure.center_of_mass()
    xx = 0.0
    xy = 0.0
    xz = 0.0
    yy = 0.0
    yz = 0.0
    zz = 0.0
    sites = self.structure.sites_cart()
    for site, weight in zip(sites, self.weights):
      ri = flex.double(site) - flex.double(self.rcm)
      xx += ri[0]*ri[0] * weight
      xy += ri[0]*ri[1] * weight
      xz += ri[0]*ri[2] * weight
      yy += ri[1]*ri[1] * weight
      yz += ri[1]*ri[2] * weight
      zz += ri[2]*ri[2] * weight
    tcm_inv = flex.double([yy+zz,-xy,-xz,  -xy,xx+zz,-yz,  -xz,-yz,xx+yy])
    tcm_inv.resize(flex.grid(3,3))
    if(tcm_inv.matrix_determinant_via_lu() > 1.e-4):
       tcm_inv.matrix_inversion_in_place()
       # get angular velocity OXCM, OYCM, OZCM
       acm = self.acm[0]
       oxcm = acm[0]*tcm_inv[0] + acm[1]*tcm_inv[3] + acm[2]*tcm_inv[6]
       oycm = acm[0]*tcm_inv[1] + acm[1]*tcm_inv[4] + acm[2]*tcm_inv[7]
       ozcm = acm[0]*tcm_inv[2] + acm[1]*tcm_inv[5] + acm[2]*tcm_inv[8]
       # remove CM translational and rotational motion from velocities
       sites = self.structure.sites_cart()
       i=0
       for site in sites:
         ri = flex.double(site) - flex.double(self.rcm)
         vx = self.vxyz[i][0]
         vx += -self.vcm[0][0] - oycm*ri[2] + ozcm*ri[1]
         vy = self.vxyz[i][1]
         vy += -self.vcm[0][1] - ozcm*ri[0] + oxcm*ri[2]
         vz = self.vxyz[i][2]
         vz += -self.vcm[0][2] - oxcm*ri[1] + oycm*ri[0]
         self.vxyz[i] = (vx,vy,vz)
         i += 1

  def velocity_rescaling(self):
    if (self.current_temperature <= 1.e-10):
      factor = 1.0
    else:
      factor = math.sqrt(self.temperature/self.current_temperature)
    self.vxyz = self.vxyz * factor

  def interleaved_minimization(self):
    geo_manager = self.restraints_manager.geometry
    assert geo_manager.shell_sym_tables is not None
    assert len(geo_manager.shell_sym_tables) > 0
    conservative_pair_proxies = self.structure.conservative_pair_proxies(
      bond_sym_table=geo_manager.shell_sym_tables[0],
      conserve_angles=self.interleaved_minimization_angles)
    sites_cart = self.structure.sites_cart()
    interleaved_lbfgs_minimization(
      sites_cart=sites_cart,
      conservative_pair_proxies=conservative_pair_proxies,
      max_iterations=self.interleaved_minimization_params.number_of_iterations)
    self.structure.set_sites_cart(sites_cart=sites_cart)
    self.structure.apply_symmetry_sites()

  def verlet_leapfrog_integration(self):
    # start verlet_leapfrog_integration loop
    for cycle in range(1,self.n_steps+1,1):
      residuals = self.residuals()
      print_flag = 0
      switch = math.modf(float(cycle)/self.n_print)[0]
      if((switch==0 or cycle==1 or cycle==self.n_steps) and self.verbose >= 1):
        print_flag = 1
      if(print_flag == 1):
        text = "integration step number = %5d"%cycle
        self.center_of_mass_info()
        kt = dynamics.kinetic_energy_and_temperature(self.vxyz, self.weights)
        self.current_temperature = kt.temperature()
        self.ekin = kt.kinetic_energy()
        print_dynamics_stat(self.log,self.temperature,self.current_temperature,
                            self.time_step,self.n_steps,self.rcm,self.vcm,
                            self.ekcm,self.acm,self.ekin,
                            text)
      if(0):
        self.center_of_mass_info()
        self.stop_global_motion()
      # calculate velocities at t+dt/2
      grad = residuals#.gradients
      dynamics.vxyz_at_t_plus_dt_over_2(self.vxyz, self.weights, grad, self.tstep)
      # calculate the temperature and kinetic energy from new velocities
      kt = dynamics.kinetic_energy_and_temperature(self.vxyz, self.weights)
      self.current_temperature = kt.temperature()
      self.ekin = kt.kinetic_energy()
      self.velocity_rescaling()
      if(print_flag == 1 and 0):
        self.center_of_mass_info()
        print_dynamics_stat(self.log,self.temperature,self.current_temperature,
                            self.time_step,self.n_steps,self.rcm,self.vcm,
                            self.ekcm,self.acm,self.ekin,
                            text)
      # do the verlet_leapfrog_integration to get coordinates at t+dt
      self.structure.set_sites_cart(
        sites_cart=self.structure.sites_cart() + self.vxyz * self.tstep)
      self.structure.apply_symmetry_sites()
      if (self.interleaved_minimization_flag):
        self.interleaved_minimization()
      kt = dynamics.kinetic_energy_and_temperature(self.vxyz, self.weights)
      self.current_temperature = kt.temperature()
      self.ekin = kt.kinetic_energy()
      if(print_flag == 1 and 0):
        self.center_of_mass_info()
        print_dynamics_stat(self.log,self.temperature,self.current_temperature,
                            self.time_step,self.n_steps,self.rcm,self.vcm,
                            self.ekcm,self.acm,self.ekin,
                            text)
    self.residuals()

def print_dynamics_stat(log,temp,ctemp,time_step,nsteps,r,v,ekcm,am,ek,text):
  timfac = 0.04888821
  line_len = len("| "+text+"|")
  fill_len = 80 - line_len-1
  print >> log, "| "+text+"-"*(fill_len)+"|"
  print >> log, "| kin.energy = %10.3f            " \
                "| information about center of free masses|"%(ek)
  print >> log, "| start temperature = %7.3f        " \
                "| position=%8.3f%8.3f%8.3f      |"% (temp,r[0],r[1],r[2])
  print >> log, "| curr. temperature = %7.3f        " \
                "| velocity=%8.4f%8.4f%8.4f      |"% (
    ctemp,v[0][0]/timfac,v[0][1]/timfac,v[0][2]/timfac)
  print >> log, "| number of integration steps = %4d " \
                "| ang.mom.=%10.2f%10.2f%10.2f|"% (
      nsteps,am[0][0]/timfac,am[0][1]/timfac,am[0][2]/timfac)
  print >> log, "| time step = %6.4f                 | kin.ener.=%8.3f                     |"% (time_step,ekcm)
  print >> log, "|"+"-"*77+"|"
