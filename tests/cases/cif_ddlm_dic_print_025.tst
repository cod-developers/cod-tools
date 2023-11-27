Tests the handling of a complex import situation. In this particular case, a
HEAD category from the same dictionary is imported several times by two
different dictionaries in the import tree (A imports B and C; C imports B).
Since importing a HEAD category changes the parent category of the imported
categories, it is important to deep clone these category definitions.
This test is not expected to output a full merged dictionary, but rather to
raise an error message about the inability to import the BASE_HEAD_CATEGORY
into the EXTENSION_DIC dictionary.
