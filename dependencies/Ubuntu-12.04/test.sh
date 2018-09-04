#!/bin/sh

# The following packages are necessary to run tests for some
# components of the 'cod-tools' source tree:

sudo apt-get install -y \
    libdevel-cover-perl \
    libtext-diff-perl \
    mysql-client
