#!/bin/sh

set -ue

sed \
    's,10.1107/S1600536813014992,10.1107/S1600536813014XXX,' \
    tests/inputs/2238212.cif \
| ./scripts/cif_cod_numbers
