#!/bin/sh

set -u

./cifparse nonexistent.cif --suppress --quiet --dump
