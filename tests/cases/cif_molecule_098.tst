Test the way input files with atoms properties split over different data loops
are handled. Current approach is to ignore data values that do not appear in
the same loop as the atom loop key, i.e. _atom_site_label or
_atom_site_type_symbol.
