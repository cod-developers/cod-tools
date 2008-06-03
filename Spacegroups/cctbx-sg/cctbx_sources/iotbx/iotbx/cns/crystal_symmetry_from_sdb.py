from iotbx.cns import sdb_reader

def extract_from(file_name=None, file=None):
  assert [file_name, file].count(None) == 1
  if (file is None):
    file = open(file_name)
  sdb_files = sdb_reader.multi_sdb_parser(file)
  assert len(sdb_files) > 0
  crystal_symmetry = sdb_files[0].crystal_symmetry()
  assert [crystal_symmetry.unit_cell(),
          crystal_symmetry.space_group_info()].count(None) < 2
  return crystal_symmetry
