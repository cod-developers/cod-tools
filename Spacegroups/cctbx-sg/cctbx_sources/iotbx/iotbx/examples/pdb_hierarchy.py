import iotbx.pdb
import random
import sys

def run(args):
  for file_name in args:
    pdb_inp = iotbx.pdb.input(file_name=file_name)
    #
    hierarchy = pdb_inp.construct_hierarchy()
    #
    hierarchy.overall_counts().show()
    #
    # Primary "view" of hierarchy:
    #   model, chain, residue_group, atom_group, atom
    for model in hierarchy.models():
      print 'model: "%s"' % model.id
      for chain in model.chains():
        print 'chain: "%s"' % chain.id
        for residue_group in chain.residue_groups():
          print '  residue_group: resseq="%s" icode="%s"' % (
            residue_group.resseq, residue_group.icode)
          for atom_group in residue_group.atom_groups():
            print '    atom_group: altloc="%s" resname="%s"' % (
              atom_group.altloc, atom_group.resname)
            for atom in atom_group.atoms():
              print '     ', atom.format_atom_record()
              print "        atom.xyz:  ", atom.xyz
              print "        atom.occ:  ", atom.occ
              print "        atom.b:    ", atom.b
              print '        atom.segid: "%s"' % atom.segid
    #
    # Secondary (read-only) "view" of hierarchy:
    #   model, chain, conformer, residue, atom
    for model in hierarchy.models():
      print 'model: "%s"' % model.id
      for chain in model.chains():
        print 'chain: "%s"' % chain.id
        for conformer in chain.conformers():
          print '  conformer: "%s"' % conformer.altloc
          for residue in conformer.residues():
            print '    residue: resname="%s" resseq="%s" icode="%s"' % (
              residue.resname, residue.resseq, residue.icode)
            for atom in residue.atoms():
              print '     ', atom.format_atom_record()
    #
    # Special case: if there are not alt. conf. you can eliminate one
    # level of the hierarchy (which may be more intuitive at first).
    for model in hierarchy.models():
      print 'model: "%s"' % model.id
      for chain in model.chains():
        print 'chain: "%s"' % chain.id
        # The next line will fail (AssertionError) if there are alt. conf.
        for residue in chain.only_conformer().residues():
          print '    residue: resname="%s" resseq="%s" icode="%s"' % (
            residue.resname, residue.resseq, residue.icode)
          for atom in residue.atoms():
            print '     ', atom.format_atom_record()
    #
    # Pick a random atom and trace back to its parents.
    # (each time you run the script the result is different!)
    pdb_atoms = hierarchy.atoms()
    atom = random.choice(pdb_atoms)
    atom_group = atom.parent()
    residue_group = atom_group.parent()
    chain = residue_group.parent()
    model = chain.parent()
    root = model.parent()
    #
    # To expose a bit how it works internally:
    #   - root is a reference to the original hierarchy:
    assert root.is_similar_hierarchy(other=hierarchy)
    #   - it actually is a reference pointing to the same piece of memory
    assert root.memory_id() == hierarchy.memory_id()
    #
    # Modify arbitrarily.
    atom.name = "XY"
    atom_group.altloc = "Z"
    atom_group.resname = "NOP"
    residue_group.resseq = "9999"
    residue_group.icode = "I"
    chain.id = "Q"
    model.id = "9"
    #
    # Add an atom to the atom_group
    atom = iotbx.pdb.hierarchy.atom()
    atom.name = "NEW"
    atom_group.append_atom(atom=atom)
    #
    # Format entire hierarchy as pdb string and pdb file.
    print hierarchy.as_pdb_string(append_end=True)
    hierarchy.write_pdb_file(file_name="junk.pdb")

if (__name__ == "__main__"):
  run(sys.argv[1:])
