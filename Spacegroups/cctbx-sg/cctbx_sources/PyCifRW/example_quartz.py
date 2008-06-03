def run():
  # ftp://ftp.geo.arizona.edu/pub/xtal/data/CIFfiles/04238.cif
  file("quartz.cif", "w").write("""
    data_global
    _chemical_name Quartz
    _cell_length_a 4.9965
    _cell_length_b 4.9965
    _cell_length_c 5.4570
    _cell_angle_alpha 90
    _cell_angle_beta 90
    _cell_angle_gamma 120
    _symmetry_space_group_name_H-M 'P 62 2 2'
    loop_
    _atom_site_label
    _atom_site_fract_x
    _atom_site_fract_y
    _atom_site_fract_z
    Si   0.50000   0.00000   0.00000
    O   0.41520   0.20760   0.16667
    """)

  from PyCifRW.CifFile import CifFile

  cif_file = CifFile("quartz.cif")
  cif_global = cif_file["global"]
  print cif_global["_chemical_name"]

  from cctbx import uctbx, sgtbx, crystal

  unit_cell = uctbx.unit_cell([float(cif_global[param])
    for param in [
      "_cell_length_a","_cell_length_b","_cell_length_c",
      "_cell_angle_alpha","_cell_angle_beta","_cell_angle_gamma"]])
  space_group_info = sgtbx.space_group_info(
    symbol=cif_global["_symmetry_space_group_name_H-M"])
  crystal_symmetry = crystal.symmetry(
    unit_cell=unit_cell,
    space_group_info=space_group_info)
  crystal_symmetry.show_summary()

  from cctbx import xray

  structure = xray.structure(crystal_symmetry=crystal_symmetry)
  for label,x,y,z in zip(cif_global["_atom_site_label"],
                         cif_global["_atom_site_fract_x"],
                         cif_global["_atom_site_fract_y"],
                         cif_global["_atom_site_fract_z"]):
    scatterer = xray.scatterer(
      label=label,
      site=[float(s) for s in [x,y,z]])
    structure.add_scatterer(scatterer)
  structure.show_summary().show_scatterers()

  f_calc = structure.structure_factors(d_min=2).f_calc()
  abs(f_calc).show_summary().show_array()

if (__name__ == "__main__"):
  run()
  print "OK"
