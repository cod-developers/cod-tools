#!/bin/bash

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=scripts/cif_guess_AMCSD_atom_types

#END DEPEND--------------------------------------------------------------------

# Check atom type assignment to the new cases

${INPUT_SCRIPT} \
    tests/inputs/AMCSD/2023-11-12/00599.cif \
    tests/inputs/AMCSD/2023-11-12/01785.cif \
    tests/inputs/AMCSD/2023-11-12/01786.cif \
    tests/inputs/AMCSD/2023-11-12/01787.cif \
    tests/inputs/AMCSD/2023-11-12/01788.cif \
    tests/inputs/AMCSD/2023-11-12/01789.cif \
    tests/inputs/AMCSD/2023-11-12/01790.cif \
    tests/inputs/AMCSD/2023-11-12/01791.cif \
    tests/inputs/AMCSD/2023-11-12/01792.cif \
    tests/inputs/AMCSD/2023-11-12/03769.cif \
    tests/inputs/AMCSD/2023-11-12/04685.cif \
    tests/inputs/AMCSD/2023-11-12/04686.cif \
    tests/inputs/AMCSD/2023-11-12/04687.cif \
    tests/inputs/AMCSD/2023-11-12/04688.cif \
    tests/inputs/AMCSD/2023-11-12/04689.cif \
    tests/inputs/AMCSD/2023-11-12/04690.cif \
    tests/inputs/AMCSD/2023-11-12/04691.cif \
    tests/inputs/AMCSD/2023-11-12/06528.cif \
    tests/inputs/AMCSD/2023-11-12/06681.cif \
    tests/inputs/AMCSD/2023-11-12/06878.cif \
    tests/inputs/AMCSD/2023-11-12/08253.cif \
    tests/inputs/AMCSD/2023-11-12/08254.cif \
    tests/inputs/AMCSD/2023-11-12/08340.cif \
    tests/inputs/AMCSD/2023-11-12/08346.cif \
    tests/inputs/AMCSD/2023-11-12/10926.cif \
    tests/inputs/AMCSD/2023-11-12/10938.cif \
    tests/inputs/AMCSD/2023-11-12/11892.cif \
    tests/inputs/AMCSD/2023-11-12/13164.cif \
    tests/inputs/AMCSD/2023-11-12/14335.cif \
    tests/inputs/AMCSD/2023-11-12/19907.cif \
#
