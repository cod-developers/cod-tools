Before bugfix in rev. 4690, one of hydrogens, attached to O2W atom, was
trimmed as polymer tail outside the unit cell. Now, with --one-datablock
option in action, polymer tails outside unit cell are cropped before
merging all moieties together, resulting in "full" non-polymer moieties.
