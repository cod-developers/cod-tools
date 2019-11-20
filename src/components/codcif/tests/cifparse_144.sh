#!/bin/bash

bzcat inputs/HETCOR_Ampicillin_1.25ms.txt.bz2 | timeout 15 ./cifparse
