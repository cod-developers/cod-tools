#!/bin/sh

set -ue

grep -v '^_journal_paper_doi' \
    tests/inputs/2238212.cif \
| ./scripts/cif_cod_numbers
