from iotbx import pdb
import iotbx.pdb.cryst1_interpretation
import iotbx.pdb.remark_290_interpretation
from cctbx import crystal
from cctbx import sgtbx
from cctbx.development import random_structure
from cctbx.array_family import flex
import scitbx.math
from libtbx.test_utils import approx_equal, show_diff
from libtbx.utils import format_cpu_times
import libtbx.load_env
from cStringIO import StringIO
import sys, os

def exercise_records():
  r = pdb.records.header(pdb_str="""\
HEADER    PLANT SEED PROTEIN                      31-JAN-97   1AB1""")
  assert r.classification == "PLANT SEED PROTEIN                      "
  assert r.depdate == "31-JAN-97"
  assert r.idcode == "1AB1"
  #
  r = pdb.records.expdta(pdb_str="""\
EXPDTA    X-RAY DIFFRACTION""")
  assert r.continuation == "  "
  assert r.technique == "X-RAY DIFFRACTION" + " " * 43
  assert r.keywords == ["X-RAY DIFFRACTION"]
  #
  r = pdb.records.remark_002(pdb_str="""\
REMARK   2 RESOLUTION. 0.89 ANGSTROMS.""")
  assert r.text == "RESOLUTION. 0.89 ANGSTROMS." + " " * 32
  assert r.resolution == 0.89
  r = pdb.records.remark_002(pdb_str="""\
REMARK   2""")
  assert r.text == " " * 59
  assert r.resolution is None
  #
  r = pdb.records.cryst1(pdb_str="""\
CRYST1   40.759   18.404   22.273  90.00  90.70  90.00 P 1 21 1      2""")
  assert r.ucparams == [40.759, 18.404, 22.273, 90.00, 90.70, 90.00]
  assert r.sgroup == "P 1 21 1"
  assert r.z == 2
  #
  r = pdb.records.scalen(pdb_str="""\
SCALE1      0.024534  0.000000  0.000300        0.00000""")
  assert r.n == 1
  assert r.sn1 == 0.024534
  assert r.sn2 == 0.000000
  assert r.sn3 == 0.000300
  assert r.un == 0.000000
  #
  r = pdb.records.conect(pdb_str="""\
CONECT 1021  544 1017 1020 1022 1211 1222 5424 1311""")
  assert r.serial == " 1021"
  assert r.serial_numbers_bonded_atoms == ["  544", " 1017", " 1020", " 1022"]
  assert r.serial_numbers_hydrogen_bonded_atoms == [" 1211", " 1222", " 1311"]
  assert r.serial_numbers_salt_bridged_atoms == [" 5424"]
  #
  for i,pdb_str in enumerate("""\
LINK         O1  DDA     1                 C3  DDL     2
LINK        MN    MN   391                 OE2 GLU   217            2565
LINK         NZ  LYS A 680        1.260    C4A PLP D   1                LYS-PLP
""".splitlines()):
    r = pdb.records.link(pdb_str=pdb_str)
    _1 = [r.name1,r.altloc1,r.resname1,r.chain_id1,r.resseq1,r.icode1,r.sym1]
    _2 = [r.name2,r.altloc2,r.resname2,r.chain_id2,r.resseq2,r.icode2,r.sym2]
    if (i == 0):
      assert _1 == [" O1 ", " ", "DDA", " ", "   1", " ", "      "]
      assert _2 == [" C3 ", " ", "DDL", " ", "   2", " ", "      "]
      assert r.distance is None
      assert r.margin == "        "
    elif (i == 1):
      assert _1 == ["MN  ", " ", " MN", " ", " 391", " ", "      "]
      assert _2 == [" OE2", " ", "GLU", " ", " 217", " ", "  2565"]
      assert r.distance is None
      assert r.margin == "        "
    else:
      assert _1 == [" NZ ", " ", "LYS", "A", " 680", " ", "      "]
      assert _2 == [" C4A", " ", "PLP", "D", "   1", " ", "      "]
      assert r.distance == 1.260
      assert r.margin == "LYS-PLP "
  #
  r = pdb.records.sltbrg(pdb_str="""\
SLTBRG       OE1 GLU B 695                 NZ  LYS B 822""")
  assert r.margin == "        "
  #
  r = pdb.records.ssbond(pdb_str="""\
SSBOND 123 CYScB  250i   CYScB  277j                         1555   1555""")
  assert r.sernum == "123"
  assert r.resname1 == "CYS"
  assert r.chain_id1 == "cB"
  assert r.resseq1 == " 250"
  assert r.icode1 == "i"
  assert r.resname2 == "CYS"
  assert r.chain_id2 == "cB"
  assert r.resseq2 == " 277"
  assert r.icode2 == "j"
  assert r.sym1 == "  1555"
  assert r.sym2 == "  1555"
  assert r.margin == "        "

def exercise_make_atom_with_labels():
  awl = pdb.make_atom_with_labels()
  assert not show_diff(awl.format_atom_record_group(siguij=False), """\
ATOM                             0.000   0.000   0.000  0.00  0.00""")
  awl = pdb.make_atom_with_labels(
    xyz=(1,2,3),
    sigxyz=(4,5,6),
    occ=7,
    sigocc=8,
    b=9,
    sigb=10,
    uij=(11,12,13,14,15,16),
    siguij=(17,18,19,20,21,22),
    hetero=True,
    serial="ABCDE",
    name="FGHI",
    segid="JKLM",
    element="NO",
    charge="PQ",
    model_id="RSTU",
    chain_id="VW",
    resseq="XYZa",
    icode="b",
    altloc="c",
    resname="def")
  expected = """\
HETATMABCDE FGHIcdefVWXYZab      1.000   2.000   3.000  7.00  9.00      JKLMNOPQ
SIGATMABCDE FGHIcdefVWXYZab      4.000   5.000   6.000  8.00 10.00      JKLMNOPQ
ANISOUABCDE FGHIcdefVWXYZab  110000 120000 130000 140000 150000 160000  JKLMNOPQ
"""[:-1]
  assert not show_diff(
    awl.format_atom_record_group(siguij=False), expected)
  if (pdb.hierarchy.atom.has_siguij()):
    assert not show_diff(awl.format_atom_record_group(), expected + """
SIGUIJABCDE FGHIcdefVWXYZab  170000 180000 190000 200000 210000 220000  JKLMNOPQ
"""[:-1])

def exercise_combine_unique_pdb_files():
  for file_name,s in [("tmp1", "1"),
                      ("tmp2", "        2"),
                      ("tmp3", "1\t"),
                      ("tmp4", " \t2"),
                      ("tmp5", "1  ")]:
    open(file_name, "w").write(s)
  for file_names in [[], ["tmp1"], ["tmp1", "tmp2"]]:
    c = pdb.combine_unique_pdb_files(file_names=file_names)
    assert len(c.file_name_registry) == len(file_names)
    assert len(c.md5_registry) == len(file_names)
    assert len(c.unique_file_names) == len(file_names)
    assert len(c.raw_records) == len(file_names)
    s = StringIO()
    c.report_non_unique(out=s)
    assert len(s.getvalue()) == 0
  c = pdb.combine_unique_pdb_files(file_names=["tmp1", "tmp1"])
  assert len(c.file_name_registry) == 1
  assert len(c.md5_registry) == 1
  assert len(c.unique_file_names) == 1
  assert len(c.raw_records) == 1
  s = StringIO()
  c.report_non_unique(out=s)
  assert not show_diff(s.getvalue(), """\
INFO: PDB file name appears 2 times: "tmp1"
  1 repeated file name ignored.

""")
  c = pdb.combine_unique_pdb_files(file_names=["tmp1", "tmp1", "tmp2", "tmp1"])
  assert len(c.file_name_registry) == 2
  assert len(c.md5_registry) == 2
  assert len(c.unique_file_names) == 2
  assert len(c.raw_records) == 2
  s = StringIO()
  c.report_non_unique(out=s, prefix="^")
  assert not show_diff(s.getvalue(), """\
^INFO: PDB file name appears 3 times: "tmp1"
^  2 repeated file names ignored.
^
""")
  c = pdb.combine_unique_pdb_files(file_names=["tmp1", "tmp2", "tmp3"])
  assert len(c.file_name_registry) == 3
  assert len(c.md5_registry) == 2
  assert len(c.unique_file_names) == 2
  assert len(c.raw_records) == 2
  s = StringIO()
  c.report_non_unique(out=s)
  assert not show_diff(s.getvalue(), """\
INFO: PDB files with identical content:
  "tmp1"
  "tmp3"
1 file with repeated content ignored.

""")
  c = pdb.combine_unique_pdb_files(file_names=["tmp1", "tmp2", "tmp3", "tmp5"])
  assert len(c.file_name_registry) == 4
  assert len(c.md5_registry) == 2
  assert len(c.unique_file_names) == 2
  assert len(c.raw_records) == 2
  s = StringIO()
  c.report_non_unique(out=s, prefix=": ")
  assert not show_diff(s.getvalue(), """\
: INFO: PDB files with identical content:
:   "tmp1"
:   "tmp3"
:   "tmp5"
: 2 files with repeated content ignored.
:
""")
  c = pdb.combine_unique_pdb_files(file_names=[
    "tmp1", "tmp2", "tmp3", "tmp4", "tmp5", "tmp4", "tmp5"])
  assert len(c.file_name_registry) == 5
  assert len(c.md5_registry) == 2
  assert len(c.unique_file_names) == 2
  assert len(c.raw_records) == 2
  s = StringIO()
  c.report_non_unique(out=s)
  assert not show_diff(s.getvalue(), """\
INFO: PDB file name appears 2 times: "tmp4"
INFO: PDB file name appears 2 times: "tmp5"
  2 repeated file names ignored.
INFO: PDB files with identical content:
  "tmp2"
  "tmp4"
INFO: PDB files with identical content:
  "tmp1"
  "tmp3"
  "tmp5"
3 files with repeated content ignored.

""")

def exercise_pdb_codes_fragment_files():
  all_codes = {} # FUTURE: set
  first_codes = []
  lines = pdb.pdb_codes_fragment_files.splitlines()
  for line in lines:
    codes = line.split()
    for code in codes:
      assert len(code) == 4
      assert not code in all_codes
      all_codes[code] = None
    assert len(codes) >= 2
    assert sorted(codes) == codes
    first_codes.append(codes[0])
  assert sorted(first_codes) == first_codes

def exercise_format_records():
  crystal_symmetry = crystal.symmetry(
    unit_cell=(10,10,13,90,90,120),
    space_group_symbol="R 3").primitive_setting()
  assert iotbx.pdb.format_cryst1_record(crystal_symmetry=crystal_symmetry) \
    == "CRYST1    7.219    7.219    7.219  87.68  87.68  87.68 R 3"
  assert iotbx.pdb.format_scale_records(
    unit_cell=crystal_symmetry.unit_cell()).splitlines() \
      == ["SCALE1      0.138527 -0.005617 -0.005402        0.00000",
          "SCALE2      0.000000  0.138641 -0.005402        0.00000",
          "SCALE3      0.000000  0.000000  0.138746        0.00000"]
  assert iotbx.pdb.format_scale_records(
    fractionalization_matrix=crystal_symmetry.unit_cell()
      .fractionalization_matrix(),
    u=[-1,2,-3]).splitlines() \
      == ["SCALE1      0.138527 -0.005617 -0.005402       -1.00000",
          "SCALE2      0.000000  0.138641 -0.005402        2.00000",
          "SCALE3      0.000000  0.000000  0.138746       -3.00000"]
  #
  f = iotbx.pdb.format_cryst1_and_scale_records
  assert not show_diff(f(), """\
CRYST1    1.000    1.000    1.000  90.00  90.00  90.00 P 1
SCALE1      1.000000  0.000000  0.000000        0.00000
SCALE2      0.000000  1.000000  0.000000        0.00000
SCALE3      0.000000  0.000000  1.000000        0.00000""")
  assert not show_diff(f(crystal_symmetry=crystal_symmetry), """\
CRYST1    7.219    7.219    7.219  87.68  87.68  87.68 R 3
SCALE1      0.138527 -0.005617 -0.005402        0.00000
SCALE2      0.000000  0.138641 -0.005402        0.00000
SCALE3      0.000000  0.000000  0.138746        0.00000""")
  for s in [f(crystal_symmetry=crystal_symmetry.unit_cell()),
            f(crystal_symmetry=crystal_symmetry.unit_cell().parameters()),
            f(scale_fractionalization_matrix=crystal_symmetry.unit_cell()
              .fractionalization_matrix())]:
    assert not show_diff(s, """\
CRYST1    7.219    7.219    7.219  87.68  87.68  87.68 P 1
SCALE1      0.138527 -0.005617 -0.005402        0.00000
SCALE2      0.000000  0.138641 -0.005402        0.00000
SCALE3      0.000000  0.000000  0.138746        0.00000""")
  assert not show_diff(f(cryst1_z=3), """\
CRYST1    1.000    1.000    1.000  90.00  90.00  90.00 P 1           3
SCALE1      1.000000  0.000000  0.000000        0.00000
SCALE2      0.000000  1.000000  0.000000        0.00000
SCALE3      0.000000  0.000000  1.000000        0.00000""")
  assert not show_diff(f(write_scale_records=False), """\
CRYST1    1.000    1.000    1.000  90.00  90.00  90.00 P 1""")
  assert not show_diff(f(scale_u=(1,2,3)), """\
CRYST1    1.000    1.000    1.000  90.00  90.00  90.00 P 1
SCALE1      1.000000  0.000000  0.000000        1.00000
SCALE2      0.000000  1.000000  0.000000        2.00000
SCALE3      0.000000  0.000000  1.000000        3.00000""")

def exercise_format_and_interpret_cryst1():
  for symbols in sgtbx.space_group_symbol_iterator():
    sgi = sgtbx.space_group_info(group=sgtbx.space_group(
      space_group_symbols=symbols))
    cs = sgi.any_compatible_crystal_symmetry(volume=1000)
    pdb_str = iotbx.pdb.format_cryst1_record(crystal_symmetry=cs)
    cs2 = pdb.cryst1_interpretation.crystal_symmetry(cryst1_record=pdb_str)
    assert cs2.is_similar_symmetry(other=cs)

def exercise_remark_290_interpretation():
  symmetry_operators=pdb.remark_290_interpretation.extract_symmetry_operators(
    remark_290_records=pdb.remark_290_interpretation.example.splitlines())
  assert symmetry_operators is not None
  assert len(symmetry_operators) == 4
  assert symmetry_operators[0] == sgtbx.rt_mx("X,Y,Z")
  assert symmetry_operators[1] == sgtbx.rt_mx("1/2-X,-Y,1/2+Z")
  assert symmetry_operators[2] == sgtbx.rt_mx("-X,1/2+Y,1/2-Z")
  assert symmetry_operators[3] == sgtbx.rt_mx("1/2+X,1/2-Y,-Z")
  for link_sym,expected_sym_op in [("1555", "x,y,z"),
                                   ("1381", "x-2,y+3,z-4"),
                                   ("3729", "-x+2,1/2+y-3,1/2-z+4"),
                                   (" 3_729 ", "-x+2,1/2+y-3,1/2-z+4"),
                                   (" 3 729 ", "-x+2,1/2+y-3,1/2-z+4"),
                                   ("_3729", None),
                                   ("37_29", None)]:
    sym_op = pdb.remark_290_interpretation.get_link_symmetry_operator(
      symmetry_operators=symmetry_operators,
      link_sym=link_sym)
    if (sym_op is None):
      assert expected_sym_op is None
    else:
      assert sym_op == sgtbx.rt_mx(expected_sym_op)

def exercise_residue_name_plus_atom_names_interpreter():
  rnpani = iotbx.pdb.residue_name_plus_atom_names_interpreter
  i = rnpani(residue_name="", atom_names=[])
  assert i.work_residue_name is None
  assert i.atom_name_interpretation is None
  i = rnpani(residue_name="TD", atom_names=["X"])
  assert i.work_residue_name is None
  assert i.atom_name_interpretation is None
  i = rnpani(
    residue_name="thr",
    atom_names=[
      "N", "CA", "C", "O", "CB", "OG1", "CG2",
      "H", "HA", "HB", "HE", "HG1", "1HG2", "2HG2", "3HG2"])
  assert i.work_residue_name == "THR"
  assert i.atom_name_interpretation.unexpected == ["HE"]
  for residue_name in ["c", "dc", "cd", "cyt"]:
    i = rnpani(
      residue_name=residue_name,
      atom_names=[
        "P", "OP1", "OP2", "O5'", "C5'", "C4'", "O4'", "C3'", "O3'",
        "C2'", "C1'", "N1", "C2", "O2", "N3", "C4", "N4", "C5", "C6",
        "H5'", "H5''", "H4'", "H3'", "H2'", "H2''", "H1'", "H41", "H42",
        "H5", "H6"])
    assert i.work_residue_name == "DC"
    assert i.atom_name_interpretation.unexpected_atom_names() == []

def exercise_format_fasta():
  regression_pdb = libtbx.env.find_in_repositories(
    relative_path="phenix_regression/pdb",
    test=os.path.isdir)
  if (regression_pdb is None):
    print "Skipping exercise_format_fasta(): input files not available"
    return
  looking_for = ["1ee3_stripped.pdb", "jcm.pdb", "pdb1zff.ent"]
  for node in os.listdir(regression_pdb):
    if (not (node.endswith(".pdb") or node.endswith(".ent"))): continue
    file_name = os.path.join(regression_pdb, node)
    assert pdb.is_pdb_file(file_name=file_name)
    pdb_inp = pdb.input(file_name=file_name)
    hierarchy = pdb_inp.construct_hierarchy()
    fasta = []
    for model in hierarchy.models():
      for chain in model.chains():
        for conformer in chain.conformers():
          fasta.append(conformer.format_fasta())
    if (node == "pdb1zff.ent"):
      assert fasta == [
        ['> chain " A" conformer ""', "CCGAATTCGG"]]
      looking_for.remove(node)
    elif (node == "1ee3_stripped.pdb"):
      assert fasta == [
        ['> chain " P" conformer "A"', 'IMEHTV'],
        ['> chain " P" conformer "B"', 'IMEHTV'],
        None,
        None]
      looking_for.remove(node)
    elif (node == "jcm.pdb"):
      assert fasta == [
        ['> chain " A" conformer ""',
         'MSSIFINREYLLPDYIPDELPHREDQIRKIASILAPLYREEKPNNIFIY'
         'GLTGTGKTAVVKFVLSKLHKKFLGKFKHVY',
         'INTRQIDTPYRVLADLLESLDVKVPFTGLSIAELYRRLVKAVRDYGSQV'
         'VIVLDEIDAFVKKYNDDILYKLSRINSISF',
         'IGITNDVKFVDLLDPRVKSSLSEEEIIFPPYNAEELEDILTKRAQMAFK'
         'PGVLPDNVIKLCAALAAREHGDARRALDLL',
         'RVSGEIAERMKDTKVKEEYVYMAKEEIERDRVRDIILTLPFHSKLVLMA'
         'VVSISSEENVVSTTGAVYETYLNICKKLGV',
         'EAVTQRRVSDIINELDMVGILTVVNRGRYGKTKEIGLAVDKNIIVRSLIESDS'],
        ['> chain " B" conformer ""',
         'KNPKVFIDPLSVFKEIPFREDILRDAAIAIRYFVKNEVKFSNLFLGLTG'
         'TGKTFVSKYIFNEIEEVKKEDEEYKDVKQA',
         'YVNCREVGGTPQAVLSSLAGKLAGFSVPKHGINLGEYIDKIKNGTRNIR'
         'AIIYLDEVDTLVKRRGGDIVLYQLLRSDAN',
         'ISVIMISNDINVRDYMEPRVLSSLGPSVIFKPYDAEQLKFILSKYAEYG'
         'LIKGTYDDEILSYIAAISAKEHGDARKAVN',
         'LLFRAAQLASGGGIIRKEHVDKAIVDYEQERLIEAVKALPFHYKLALRS'
         'LIESEDVMSAHKMYTDLCNKFKQKPLSYRR',
         'FSDIISELDMFGIVKIRIINRGRAGGVKKYALVEDKEKVLRALNET'],
        ['> chain " C" conformer ""',
         'TGTAAATTTCCTACGTTTCATCTGAAAATCTAGAGATTTTCAGATGAAACGTAGGAAATTTACATC'],
         None]
      looking_for.remove(node)
  if (len(looking_for) != 0):
    print "WARNING: exercise_format_fasta(): some input files missing:", \
      looking_for

def exercise_xray_structure(use_u_aniso, verbose=0):
  structure = random_structure.xray_structure(
    space_group_info=sgtbx.space_group_info("P 31"),
    elements=["N","C","C","O","Si"]*2,
    volume_per_atom=500,
    min_distance=2.,
    general_positions_only=False,
    random_u_iso=True,
    use_u_aniso=use_u_aniso)
  f_abs = abs(structure.structure_factors(
    anomalous_flag=False, d_min=2, algorithm="direct").f_calc())
  for resname in (None, "res"):
    for fractional_coordinates in (False, True):
      pdb_file = structure.as_pdb_file(
        remark="Title", remarks=["Any", "Thing"],
        fractional_coordinates=fractional_coordinates,
        resname=resname)
      if (0 or verbose):
        sys.stdout.write(pdb_file)
      structure_read = iotbx.pdb.input(
        source_info=None,
        lines=flex.std_string(pdb_file.splitlines())).xray_structure_simple(
          fractional_coordinates=fractional_coordinates,
          use_scale_matrix_if_available=False)
      f_read = abs(f_abs.structure_factors_from_scatterers(
        xray_structure=structure_read, algorithm="direct").f_calc())
      regression = flex.linear_regression(f_abs.data(), f_read.data())
      assert regression.is_well_defined()
      if (0 or verbose):
        regression.show_summary()
      assert approx_equal(regression.slope(), 1, eps=1.e-2)
      assert approx_equal(
        regression.y_intercept(), 0, eps=flex.max(f_abs.data())*0.01)

def dump_pdb(file_name, sites_cart, crystal_symmetry=None):
  f = open(file_name, "w")
  if (crystal_symmetry is not None):
    print >> f, iotbx.pdb.format_cryst1_record(
      crystal_symmetry=crystal_symmetry)
  for i,site in enumerate(sites_cart):
    a = iotbx.pdb.hierarchy.atom_with_labels()
    a.serial = i+1
    a.name = " C  "
    a.resname = "DUM"
    a.resseq = 1
    a.xyz = site
    a.occ = 1
    print >> f, a.format_atom_record_group()
  print >> f, "END"
  f.close()

def write_icosahedron():
  for level in xrange(3):
    icosahedron = scitbx.math.icosahedron(level=level)
    scale = 1.5/icosahedron.next_neighbors_distance()
    dump_pdb(
      file_name="icosahedron_%d.pdb"%level,
      sites_cart=icosahedron.sites*scale)

def run():
  verbose = "--verbose" in sys.argv[1:]
  exercise_records()
  exercise_make_atom_with_labels()
  exercise_combine_unique_pdb_files()
  exercise_pdb_codes_fragment_files()
  exercise_format_records()
  exercise_format_and_interpret_cryst1()
  exercise_remark_290_interpretation()
  exercise_residue_name_plus_atom_names_interpreter()
  exercise_format_fasta()
  for use_u_aniso in (False, True):
    exercise_xray_structure(use_u_aniso, verbose=verbose)
  write_icosahedron()
  print format_cpu_times()

if (__name__ == "__main__"):
  run()
