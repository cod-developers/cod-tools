# LIBTBX_SET_DISPATCHER_NAME phenix.pdb.hierarchy

from iotbx import pdb
from iotbx.option_parser import option_parser
from libtbx.str_utils import show_string
from libtbx.utils import Sorry
import sys, os

def run(args, command_name="phenix.pdb.hierarchy"):
  if (len(args) == 0): args = ["--help"]
  command_line = (option_parser(
    usage="%s file..." % command_name)
    .option(None, "--details",
      action="store",
      type="string",
      default=None,
      help="level of detail",
      metavar="|".join(pdb.hierarchy.level_ids))
    .option(None, "--residue_groups_max_show",
      action="store",
      type="int",
      default=10,
      help="maximum number of residue groups to be listed along with"
           " errors or warnings",
      metavar="INT")
    .option(None, "--duplicate_atom_labels_max_show",
      action="store",
      type="int",
      default=10,
      help="maximum number of groups of duplicate atom labels to be listed",
      metavar="INT")
    .option(None, "--prefix",
      action="store",
      type="string",
      default="",
      help="prefix for all output lines",
      metavar="STRING")
    .option(None, "--write_pdb_file",
      action="store",
      type="string",
      default=None,
      help="write hierarchy as PDB coordinate section to file",
      metavar="FILE")
    .option(None, "--reset_serial_first_value",
      action="store",
      type="int",
      default=None,
      help="resets atom serial numbers before writing PDB file",
      metavar="INT")
    .option(None, "--interleaved_conf",
      action="store",
      type="int",
      default=0,
      help="interleave alt. conf. when writing PDB file; possible choices are:"
        " 0 (not interleaved),"
        " 1 (interleaved atom names but not resnames),"
        " 2 (fully interleaved)",
      metavar="INT")
    .option(None, "--no_anisou",
      action="store_true",
      default=False,
      help="suppress ANISOU records when writing PDB file")
    .option(None, "--no_sigatm",
      action="store_true",
      default=False,
      help="suppress SIGATM records when writing PDB file")
    .option(None, "--no_cryst",
      action="store_true",
      default=False,
      help="suppress crystallographic records (e.g. CRYST1 and SCALEn)"
           " when writing PDB file")
  ).process(args=args)
  co = command_line.options
  for file_name in command_line.args:
    if (not os.path.isfile(file_name)): continue
    pdb_objs = execute(
      file_name=file_name,
      prefix=co.prefix,
      residue_groups_max_show=co.residue_groups_max_show,
      duplicate_atom_labels_max_show=co.duplicate_atom_labels_max_show,
      level_id=co.details)
    if (co.write_pdb_file is not None):
      if (not co.no_cryst):
        print >> open(co.write_pdb_file, "wb"), \
          "\n".join(pdb_objs.input.crystallographic_section())
      pdb_objs.hierarchy.write_pdb_file(
        file_name=co.write_pdb_file,
        open_append=(not co.no_cryst),
        append_end=True,
        interleaved_conf=co.interleaved_conf,
        atoms_reset_serial_first_value=co.reset_serial_first_value,
        sigatm=not co.no_sigatm,
        anisou=not co.no_anisou,
        siguij=not co.no_anisou)
    print co.prefix.rstrip()

def execute(
      file_name,
      prefix="",
      residue_groups_max_show=10,
      duplicate_atom_labels_max_show=10,
      level_id=None):
  try:
    return pdb.hierarchy.show_summary(
      file_name=file_name,
      prefix=prefix,
      residue_groups_max_show=residue_groups_max_show,
      duplicate_atom_labels_max_show=duplicate_atom_labels_max_show,
      level_id=level_id)
  except KeyboardInterrupt: raise
  except Exception, e:
    print "Exception: file %s: %s: %s" % (
      show_string(file_name), e.__class__.__name__, str(e))

if (__name__ == "__main__"):
  run(args=sys.argv[1:])
