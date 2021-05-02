#------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------
#*
#  A list of DFT CIF dictionary tags. Compiled from version 0.020 of
#  cif_dft.dic:
#
#  URL: svn://www.crystallography.net/tcod/cif/dictionaries/cif_dft.dic
#  Repository Root: svn://www.crystallography.net/tcod
#  Repository UUID: f3fa9230-7ed6-4b69-bb24-8fd292b8517b
#  Revision: 1657
#**

package COD::CIF::Tags::DFT;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    @tag_list
);

our @tag_list = qw (
_dft_1e_energy
_dft_2e_energy
_dft_alloy_method
_dft_alloy_method_other_name
_dft_alloy_supercell
_dft_atom_basisset
_dft_atom_basisset_citation_id
_dft_atom_basisset_energy_conv
_dft_atom_basisset_type
_dft_atom_relax_energy_conv
_dft_atom_relax_force_conv
_dft_atom_type_coulomb_J
_dft_atom_type_coulomb_U
_dft_atom_type_DMFT_solver
_dft_atom_type_double_count
_dft_atom_type_magn_moment
_dft_atom_type_magn_orbital_moment
_dft_atom_type_magn_spin_moment
_dft_atom_type_nuclear_charge
_dft_atom_type_occupation
_dft_atom_type_radius
_dft_atom_type_valence_configuration
_dft_atom_type_valence_electrons
_dft_band_gap
_dft_basisset_[]
_dft_basisset_citation_id
_dft_basisset_database_abbrev
_dft_basisset_database_citation_id
_dft_basisset_database_code
_dft_basisset_database_name
_dft_basisset_database_URI
_dft_basisset_energy_conv
_dft_basisset_type
_dft_basisset_URI
_dft_bulk_modulus
_dft_BZ_integration_citation_id
_dft_BZ_integration_energy_conv
_dft_BZ_integration_Froyen_map
_dft_BZ_integration_grid_dens_X
_dft_BZ_integration_grid_dens_Y
_dft_BZ_integration_grid_dens_Z
_dft_BZ_integration_grid_IBZ_point_[]
_dft_BZ_integration_grid_IBZ_point_id
_dft_BZ_integration_grid_IBZ_points
_dft_BZ_integration_grid_IBZ_point_weight
_dft_BZ_integration_grid_IBZ_point_X
_dft_BZ_integration_grid_IBZ_point_Y
_dft_BZ_integration_grid_IBZ_point_Z
_dft_BZ_integration_grid_shift_X
_dft_BZ_integration_grid_shift_Y
_dft_BZ_integration_grid_shift_Z
_dft_BZ_integration_grid_type
_dft_BZ_integration_grid_X
_dft_BZ_integration_grid_Y
_dft_BZ_integration_grid_Z
_dft_BZ_integration_method
_dft_BZ_integration_method_other
_dft_BZ_integration_MP_order
_dft_BZ_integration_smearing_method
_dft_BZ_integration_smearing_method_other
_dft_BZ_integration_smearing_width
_dft_cell_density_conv
_dft_cell_energy
_dft_cell_energy_conv
_dft_cell_magn_moment
_dft_cell_magn_orbital_moment
_dft_cell_magn_spin_moment
_dft_cell_periodic_BC_X
_dft_cell_periodic_BC_Y
_dft_cell_periodic_BC_Z
_dft_cell_potential_conv
_dft_cell_pressure
_dft_cell_valence_electrons
_dft_core_electrons
_dft_correlation_energy
_dft_Coulomb_energy
_dft_dielectric_constant
_dft_ewald_energy
_dft_fermi_energy
_dft_hartree_energy
_dft_kinetic_energy
_dft_kinetic_energy_cutoff_charge_density
_dft_kinetic_energy_cutoff_EEX
_dft_kinetic_energy_cutoff_wavefunctions
_dft_lattice_energy
_dft_nuclear_repulsion_energy
_dft_pseudopotential_[]
_dft_pseudopotential_atom_type
_dft_pseudopotential_citation_id
_dft_pseudopotential_type
_dft_pseudopotential_type_other_name
_dft_stiffness_tensor_11
_dft_stiffness_tensor_12
_dft_stiffness_tensor_13
_dft_stiffness_tensor_14
_dft_stiffness_tensor_15
_dft_stiffness_tensor_16
_dft_stiffness_tensor_22
_dft_stiffness_tensor_23
_dft_stiffness_tensor_24
_dft_stiffness_tensor_25
_dft_stiffness_tensor_26
_dft_stiffness_tensor_33
_dft_stiffness_tensor_34
_dft_stiffness_tensor_35
_dft_stiffness_tensor_36
_dft_stiffness_tensor_44
_dft_stiffness_tensor_45
_dft_stiffness_tensor_46
_dft_stiffness_tensor_55
_dft_stiffness_tensor_56
_dft_stiffness_tensor_66
_dft_XC_correlation_functional_name
_dft_XC_correlation_functional_weight
_dft_XC_exchange_functional_name
_dft_XC_exchange_functional_weight
_dft_XC_functional
_dft_XC_functional_citation_id
_dft_XC_functional_id
_dft_XC_functional_type
_dft_XC_functional_type_other_name
);

1;
