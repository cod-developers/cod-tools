#!/bin/bash

./cif_filter --bibliography <(echo '<year>2000</year>') \
             inputs/pdCIF_struct-complete-bipartite.cif
