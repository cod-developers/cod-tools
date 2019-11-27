#! /bin/sh

sudo yum groupinstall -y "Development Tools"
sudo yum install -y cmake
sudo yum install -y perl-Module-ScanDeps
sudo yum install -y perl-Parse-Yapp bison
