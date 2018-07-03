%module(package="COD::SPGLib") "COD::SPGLib"
%{

#include <SPGLib.h>

SV* get_sym_dataset( SV* lattice_ref, SV* atom_positions_ref, SV* types_ref,
                     SV* symprec );
SV* spglib_version( void );

%}

SV* get_sym_dataset( SV* lattice_ref, SV* atom_positions_ref, SV* types_ref,
                     SV* symprec );
SV* spglib_version( void );

%perlcode %{
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    get_sym_dataset
);

our $spglib_version = spglib_version();

%}
