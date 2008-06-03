# Comments by Phil Evans, MRC-LMB, Cambridge, U.K.

from libtbx import adopt_init_args
from cctbx import crystal
from cctbx import sgtbx
from cctbx.sgtbx import subgroups
from cctbx.sgtbx import lattice_symmetry
from cctbx.sgtbx import bravais_types
from iotbx.option_parser import option_parser
from scitbx.array_family import flex
import sys

def run(args):
  command_line = (option_parser(
    usage="iotbx.lattice_symmetry [options] [centring_type_symbol]",
    description="Example: iotbx.lattice_symmetry"
               +" --unit_cell=12,12,12.1,89,90,92 F")
    .enable_symmetry_comprehensive()
    .option(None, "--delta",
      action="store",
      type="float",
      default=3.,
      help="angular tolerance in degrees")
  ).process(args=args, max_nargs=1)
  # Pick up symmetry object
  input_symmetry = command_line.symmetry
  # Check that we have what we need
  if (input_symmetry.unit_cell() is None):
    print
    print "***********************************"
    print "Please specify unit cell parameters"
    print "***********************************"
    print
    command_line.parser.show_help()
    return
  if (len(command_line.args) > 0):
    input_symmetry = crystal.symmetry(
      unit_cell=input_symmetry.unit_cell(),
      space_group_symbol="Hall: %s 1" % command_line.args[0])
  elif (input_symmetry.space_group_info() is None):
    input_symmetry = crystal.symmetry(
      unit_cell=input_symmetry.unit_cell(),
      space_group_symbol="P 1")
  # Do it
  groups = metric_subgroups(input_symmetry, command_line.options.delta,
    enforce_max_delta_for_generated_two_folds=True)
  groups.show()

def metric_supergroup(group):
  return sgtbx.space_group_info(group=group).type(
    ).expand_addl_generators_of_euclidean_normalizer(True,True
    ).build_derived_acentric_group()

class metric_subgroups:

  def __init__(self,
        input_symmetry,
        max_delta,
        enforce_max_delta_for_generated_two_folds=True,
        bravais_types_only=True):
    adopt_init_args(self,locals())
    self.result_groups = []

    self.change_input_to_minimum_cell()
    self.derive_result_group_list()

  def change_input_to_minimum_cell(self):
    # Get cell reduction operator
    self.cb_op_inp_minimum = self.input_symmetry.change_of_basis_op_to_minimum_cell()

    # New symmetry object with changed basis
    self.minimum_symmetry = self.input_symmetry.change_basis(self.cb_op_inp_minimum)

  def derive_result_group_list(self):
    # Get highest symmetry compatible with lattice
    lattice_group = lattice_symmetry.group(
      self.minimum_symmetry.unit_cell(),
      max_delta=self.max_delta,
      enforce_max_delta_for_generated_two_folds
        =self.enforce_max_delta_for_generated_two_folds)
    lattice_group_info = sgtbx.space_group_info(group=lattice_group)

    # Get list of sub-spacegroups
    subgrs = subgroups.subgroups(lattice_group_info).groups_parent_setting()

    # Order sub-groups
    sort_values = flex.double()
    for group in subgrs:
      order_z = group.order_z()
      space_group_number = sgtbx.space_group_type(group, False).number()
      assert 1 <= space_group_number <= 230
      sort_values.append(order_z*1000+space_group_number)
    perm = flex.sort_permutation(sort_values, True)

    for i_subgr in perm:
      acentric_subgroup = subgrs[i_subgr]
      acentric_supergroup = metric_supergroup(acentric_subgroup)
      # Add centre of inversion to acentric lattice symmetry
      centric_group = sgtbx.space_group(acentric_subgroup)
      centric_group.expand_inv(sgtbx.tr_vec((0,0,0)))
      # Make symmetry object: unit-cell + space-group
      # The unit cell is potentially modified to be exactly compatible
      # with the space group symmetry.
      subsym = crystal.symmetry(
        unit_cell=self.minimum_symmetry.unit_cell(),
        space_group=centric_group,
        assert_is_compatible_unit_cell=False)
      supersym = crystal.symmetry(
        unit_cell=self.minimum_symmetry.unit_cell(),
        space_group=acentric_supergroup,
        assert_is_compatible_unit_cell=False)
      # Convert subgroup to reference setting
      cb_op_minimum_ref = subsym.space_group_info().type().cb_op()
      ref_subsym = subsym.change_basis(cb_op_minimum_ref)
      # Ignore unwanted groups
      if (self.bravais_types_only and
          not str(ref_subsym.space_group_info()) in bravais_types.centric):
        continue
      # Choose best setting for monoclinic and orthorhombic systems
      cb_op_best_cell = self.change_of_basis_op_to_best_cell(ref_subsym)
      best_subsym = ref_subsym.change_basis(cb_op_best_cell)
      # Total basis transformation
      cb_op_inp_best = cb_op_best_cell * cb_op_minimum_ref * self.cb_op_inp_minimum
      # Use identity change-of-basis operator if possible
      if (best_subsym.unit_cell().is_similar_to(self.input_symmetry.unit_cell())):
        cb_op_corr = cb_op_inp_best.inverse()
        try:
          best_subsym_corr = best_subsym.change_basis(cb_op_corr)
        except RuntimeError, e:
          if (str(e).find("Unsuitable value for rational rotation matrix.") < 0):
            raise
        else:
          if (best_subsym_corr.space_group() == best_subsym.space_group()):
            cb_op_inp_best = cb_op_corr * cb_op_inp_best
      self.result_groups.append({'subsym':subsym,
                                 'supersym':supersym,
                                 'ref_subsym':ref_subsym,
                                 'best_subsym':best_subsym,
                                 'cb_op_inp_best':cb_op_inp_best,
                                 'max_angular_difference':
                                  lattice_symmetry.find_max_delta(
                                  reduced_cell=self.minimum_symmetry.unit_cell(),
                                  space_group=acentric_supergroup)
                               })
  def change_of_basis_op_to_best_cell(self,ref_subsym):
    return ref_subsym.change_of_basis_op_to_best_cell()

  def show_input(self):
    print
    print "Input"
    print "====="
    print
    self.input_symmetry.show_summary()
    print
    print "Angular tolerance: %.3f degrees" % self.max_delta
    print
    print "Similar symmetries"
    print "=================="
    print

  def show_groups(self):
    # Loop sub-groups in sorted order
    for item in self.result_groups:
      item['subsym'].space_group_info().show_summary(
        prefix="Symmetry in minimum-lengths cell: ")
      print "      Input minimum-lengths cell:", self.minimum_symmetry.unit_cell()
      print "           Symmetry-adapted cell:", item['subsym'].unit_cell()
      item['best_subsym'].space_group_info().show_summary(
        prefix="            Conventional setting: ")
      print "                       Unit cell:", item['best_subsym'].unit_cell()
      print "                 Change of basis:", item['cb_op_inp_best'].c()
      print "                         Inverse:", item['cb_op_inp_best'].c_inv()
      print "      Maximal angular difference: %.3f degrees" % (
        item['max_angular_difference'])
      print

  def show(self):
    self.show_input()
    self.show_groups()

if (__name__ == "__main__"):
  run(sys.argv[1:])
