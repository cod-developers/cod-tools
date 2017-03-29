#!/bin/bash

set -u

diff \
    <(./cifparse --print inputs/DDLm_3.11.09.dic) \
    <(./cifparse --print inputs/DDLm_3.11.09.dic | ./cifparse --print) 
