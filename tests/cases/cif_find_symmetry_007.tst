The input for the test is restored P 1 structure of COD entry 1010003
(rev. 35911). Generation command:

cif_p1 -1 --max-polymer-span 0 /home/andrius/struct/cod/cif/1/01/00/1010003.cif > tests/inputs/1010003-P1.cif

Symmetry search on original (non-P 1) structure fails, since spglib
requires all atomic sites in the unit cell to determine the symmetry.
