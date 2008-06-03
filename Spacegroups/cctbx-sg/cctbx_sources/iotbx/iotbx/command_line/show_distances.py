from cctbx.crystal import coordination_sequences
from cctbx import xray
from cctbx import crystal
from iotbx.kriber import strudat
import iotbx.pdb
from iotbx.option_parser import option_parser
import sys

def display(
      distance_cutoff,
      show_cartesian,
      max_shell,
      coseq_dict,
      xray_structure):
  xray_structure.show_summary().show_scatterers()
  print
  pairs = xray_structure.show_distances(
    distance_cutoff=distance_cutoff,
    show_cartesian=show_cartesian,
    keep_pair_asu_table=True)
  print
  if (pairs.pair_counts.size() <= 15):
    print "Pair counts:", list(pairs.pair_counts)
    print
  if (max_shell is None):
    term_table = None
  else:
    term_table = crystal.coordination_sequences.simple(
      pair_asu_table=pairs.pair_asu_table,
      max_shell=max_shell)
    coordination_sequences.show_terms(
      structure=xray_structure,
      term_table=term_table,
      coseq_dict=coseq_dict)
    print
  return pairs, term_table

def run(args):
  command_line = (option_parser(
    usage="iotbx.show_distances [options] studat_file [...]",
    description="Example: iotbx.show_distances strudat --tag=SOD")
    .option(None, "--tag",
      action="store",
      type="string",
      help="tag as it appears in the strudat file")
    .option(None, "--distance_cutoff",
      action="store",
      type="float",
      default=5,
      help="Maximum distance to be considered",
      metavar="FLOAT")
    .option(None, "--show_cartesian",
      action="store_true",
      help="Show Cartesian coordinates (instead of fractional)")
    .option(None, "--cs",
      action="store",
      type="int",
      help="Compute N terms of the coordination sequences",
      metavar="N")
    .option(None, "--coseq",
      action="store",
      type="string",
      help="name of file with known coordination sequences",
      metavar="FILE")
  ).process(args=args)
  if (len(command_line.args) == 0):
    command_line.parser.show_help()
    return
  max_shell = command_line.options.cs
  if (command_line.options.coseq is not None):
    coseq_dict = coordination_sequences.get_kriber_coseq_file(
      file_name=command_line.options.coseq)
    if (max_shell is None): max_shell = 10
  else:
    coseq_dict = None
  for file_name in command_line.args:
    if (iotbx.pdb.is_pdb_file(file_name=file_name)):
      xray_structure = iotbx.pdb.input(
        file_name=file_name).xray_structure_simple(
          enable_scattering_type_unknown=True)
      display(
        distance_cutoff=command_line.options.distance_cutoff,
        show_cartesian=command_line.options.show_cartesian,
        max_shell=max_shell,
        coseq_dict=coseq_dict,
        xray_structure=xray_structure)
    else:
      strudat_entries = strudat.read_all_entries(open(file_name))
      for entry in strudat_entries.entries:
        if (    command_line.options.tag is not None
            and command_line.options.tag != entry.tag):
          continue
        print "strudat tag:", entry.tag
        print
        xray_structure = entry.as_xray_structure()
        display(
          distance_cutoff=command_line.options.distance_cutoff,
          show_cartesian=command_line.options.show_cartesian,
          max_shell=max_shell,
          coseq_dict=coseq_dict,
          xray_structure=xray_structure)

if (__name__ == "__main__"):
  run(sys.argv[1:])
