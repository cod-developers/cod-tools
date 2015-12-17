%module(package="COD::SPGLib") "COD::SPGLib"
%{

#include <spacegroup.h>
#include <spglib.h>
#include <SPGLib.h>

%} 

SV* get_spacegroup( SV* cell_constant_ref, SV* atom_position_ref );
SV* get_sym_dataset( SV* lattice_ref, SV* atom_positions_ref, SV* types_ref,
                     SV* symprec );

%perlcode %{
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    get_sym_dataset
);

sub extra_function
{
    print "This is an extra Perl function\n"
}

%}
