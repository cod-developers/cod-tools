#!/bin/bash

set -ue

./cifvalues \
    --filename \
    --header \
    --csv-output \
    --tag _cod_depositor_comments \
    inputs/2000000.cif \
    inputs/1004001-disorder.cif \
    inputs/1508696-long-text-field.cif \
    inputs/2000000.cif \
    inputs/4067640.cif \
    inputs/4318422.cif \
    inputs/4319975.cif \
    inputs/7052868.cif \
    inputs/9007991.cif \
    #
