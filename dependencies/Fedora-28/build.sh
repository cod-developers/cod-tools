#! /bin/sh

sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y cmake
sudo dnf install -y perl-Module-ScanDeps
sudo dnf install -y perl-Parse-Yapp bison
sudo dnf install -y python2-devel
sudo dnf install -y redhat-rpm-config
sudo dnf install -y swig
