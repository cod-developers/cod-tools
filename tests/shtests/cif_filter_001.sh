#!/bin/bash

./scripts/cif_filter --bibliography <(echo '<year>2000</year>') \
    tests/inputs/pdCIF_struct-complete-bipartite.cif
