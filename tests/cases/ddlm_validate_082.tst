Tests the way data item names are normalised in validation messages.
The current approach is to use the canonical capitalisation form
(i.e. '_geom_hbond_atom_site_label_A' for '_geom_hbond_atom_site_label_a')
or to default to an all-lowercase tag name form if no canonical name can be
located. In the future this might be changed to always use the lowercased
data name.
