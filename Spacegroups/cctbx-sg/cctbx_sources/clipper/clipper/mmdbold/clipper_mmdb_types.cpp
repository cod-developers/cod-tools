/* clipper_mmdb_types.cpp: model types wrapper */
//C Copyright (C) 2000-2004 Kevin Cowtan and University of York
//C Copyright (C) 2000-2005 Kevin Cowtan and University of York
//L
//L  This library is free software and is distributed under the terms
//L  and conditions of version 2.1 of the GNU Lesser General Public
//L  Licence (LGPL) with the following additional clause:
//L
//L     `You may also combine or link a "work that uses the Library" to
//L     produce a work containing portions of the Library, and distribute
//L     that work under terms of your choice, provided that you give
//L     prominent notice with each copy of the work that the specified
//L     version of the Library is used in it, and that you include or
//L     provide public access to the complete corresponding
//L     machine-readable source code for the Library including whatever
//L     changes were used in the work. (i.e. If you make changes to the
//L     Library you must distribute those, but you do not need to
//L     distribute source or object code to those portions of the work
//L     not covered by this licence.)'
//L
//L  Note that this clause grants an additional right and does not impose
//L  any additional restriction, and so does not affect compatibility
//L  with the GNU General Public Licence (GPL). If you wish to negotiate
//L  other terms, please contact the maintainer.
//L
//L  You can redistribute it and/or modify the library under the terms of
//L  the GNU Lesser General Public License as published by the Free Software
//L  Foundation; either version 2.1 of the License, or (at your option) any
//L  later version.
//L
//L  This library is distributed in the hope that it will be useful, but
//L  WITHOUT ANY WARRANTY; without even the implied warranty of
//L  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//L  Lesser General Public License for more details.
//L
//L  You should have received a copy of the CCP4 licence and/or GNU
//L  Lesser General Public License along with this library; if not, write
//L  to the CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
//L  The GNU Lesser General Public can also be obtained by writing to the
//L  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
//L  MA 02111-1307 USA

#include "clipper_mmdb_types.h"


namespace clipper {


/*! The coordinates and U_aniso_orth are transformed. The sigmas are not,
  since without the full variance-covariance matrix this transformation
  is impossible.
  \param rt The operator to apply.
  \untested
*/
void DBAtom_base::transform( const RTop_orth rt ) {
  set_coord_orth( coord_orth().transform( rt ) );
  set_u_aniso_orth( u_aniso_orth().transform( rt ) );
}


NDBAtom::NDBAtom( const DBAtom_base& a )
{
  set_type( a.type() );
  set_element( a.element() );
  set_altconf( a.altconf() );
  set_coord_orth( a.coord_orth() );
  set_occupancy( a.occupancy() );
  set_u_iso( a.u_iso() );
  set_u_aniso_orth( a.u_aniso_orth() );
}

String NDBAtom::type() const
{ return type_; }

String NDBAtom::element() const
{ return element_; }

String NDBAtom::altconf() const
{ return altconf_; }

Coord_orth NDBAtom::coord_orth() const
{ return xyz; }

ftype NDBAtom::occupancy() const
{ return occ; }

ftype NDBAtom::u_iso() const
{ return u; }

U_aniso_orth NDBAtom::u_aniso_orth() const
{ return uij; }

void NDBAtom::set_type( const String& n )
{ type_ = n; }

void NDBAtom::set_element( const String& n )
{ element_ = n; }

void NDBAtom::set_altconf( const String& n )
{ altconf_ = n; }

void NDBAtom::set_coord_orth( const Coord_orth& v )
{ xyz = v; }

void NDBAtom::set_occupancy( const ftype& v )
{ occ = v; }

void NDBAtom::set_u_iso( const ftype& v )
{ u = v; }

void NDBAtom::set_u_aniso_orth( const U_aniso_orth& v )
{ uij = v; }

NDBAtom NDBAtom::null()
{
  NDBAtom a;
  a.set_coord_orth( Coord_orth( Coord_orth::null() ) );
  a.set_occupancy( Util::nan() );
  a.set_u_iso( Util::nan() );
  a.set_u_aniso_orth( U_aniso_orth( U_aniso_orth::null() ) );
  return a;
}

// Residue

NDBResidue::NDBResidue( const DBResidue_base& r )
{ set_type( r.type() ); }

String NDBResidue::type() const
{ return type_; }

void NDBResidue::set_type( const String& n )
{ type_ = n; }

int NDBResidue::seqnum() const
{ return seqnum_; }

void NDBResidue::set_seqnum( const int& n )
{ seqnum_ = n; }

String NDBResidue::inscode() const
{ return inscode_; }

void NDBResidue::set_inscode( const String& n )
{ inscode_ = n; }


// Chain

NDBChain::NDBChain( const DBChain_base& c )
{ set_id( c.id() ); }

String NDBChain::id() const
{ return id_; }

void NDBChain::set_id( const String& n )
{ id_ = n; }


// Model

NDBModel::NDBModel( const DBModel_base& m )
{ set_id( m.id() ); }

String NDBModel::id() const
{ return id_; }

void NDBModel::set_id( const String& n )
{ id_ = n; }


} // namespace clipper
