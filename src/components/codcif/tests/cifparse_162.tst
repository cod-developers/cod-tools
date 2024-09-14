Tests the way data files that have an incorrect CIF 2.0 comment on the first
line are handled. In this case the start of the CIF 2.0 comment string contains
additional text after the '#\#CIF_2.0' part at the start. The file should be
treated as a CIF 1.1 file.
