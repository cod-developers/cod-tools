#! /bin/sh

sudo yum groupinstall -y "Development Tools"
sudo yum install -y perl-Module-ScanDeps
sudo yum install -y perl-Parse-Yapp bison flex
