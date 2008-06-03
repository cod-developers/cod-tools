from iotbx.scalepack import merge
from iotbx.scalepack import no_merge_original_index
from cctbx import crystal

def extract_from_merge(file):
  scalepack_file = merge.reader(file, header_only=True)
  return crystal.symmetry(
    unit_cell=scalepack_file.unit_cell,
    space_group_info=scalepack_file.space_group_info)

def extract_from_no_merge_original_index(file_name):
  scalepack_file = no_merge_original_index.reader(file_name, header_only=True)
  return crystal.symmetry(
    unit_cell=None,
    space_group_info=scalepack_file.space_group_info())

def extract_from(file_name):
  try: return extract_from_merge(open(file_name))
  except merge.FormatError: pass
  return extract_from_no_merge_original_index(file_name)
