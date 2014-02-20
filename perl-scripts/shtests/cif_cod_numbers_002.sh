#!/bin/sh

set -ue

grep -v '^_journal_paper_doi' \
    inputs/2238212.cif \
| ./cif_cod_numbers
