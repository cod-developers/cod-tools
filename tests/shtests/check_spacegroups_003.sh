#!/bin/sh

# Test definition of the newly introduced nonstandard 'B 1 21/m 1'
# spacegroup setting:

set -ue

./scripts/symop_build_spacegroup <<EOF
x,y,z
-x,y+1/2,-z
-x,-y,-z
x,-y-1/2,z
x+1/2,y,z+1/2
-x+1/2,y+1/2,-z+1/2
-x+1/2,-y,-z+1/2
x+1/2,-y-1/2,z+1/2
EOF
