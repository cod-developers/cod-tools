/* minimol.cpp: atomic model types */
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

#include "minimol.h"


namespace clipper {


Message_ctor message_ctor_mmodel( " [MModel: constructed]" );


// Atom

MAtom::MAtom( const clipper::Atom& atom )
{
  set_element( atom.element() );
  set_coord_orth( atom.coord_orth() );
  set_occupancy( atom.occupancy() );
  set_u_iso( atom.u_iso() );
  set_u_aniso_orth( atom.u_aniso_orth() );
}

void MAtom::set_id( const String& s ) { id_ = id_tidy( s ); }

void MAtom::set_name( const String s, const String altconf )
{
  if ( altconf != "" ) set_id( s + ":" + altconf );
  else                 set_id( s );
}

String MAtom::id_tidy( const String& id )
{
  int pos = id.find( ":" );
  if ( pos == String::npos ) pos = id.length();
  String name( id.substr( 0, pos ) );
  String altc( id.substr( pos ) );
  if ( name.length() < 4 ) {
    name = name + "   ";
    if ( islower( name[1] ) )
      name[1] = toupper( name[1] );
    else
      name = " " + name;
  }
  return name.substr(0,4) + altc;
}

/*! copy from other atom. mode can be MM::COPY_M, COPY_P, COPY_MP,
  COPY_C, COPY_MC, COPY_PC, COPY_MPC, where M means copy members, P
  means copy PropertyMananger properties, and C means copy
  children. Children are copied with the same option. The values
  'MEMBERS', 'PROPERTIES', 'CHILDREN' can also be used. */
MAtom& MAtom::copy( const MAtom& other, const MM::COPY& mode )
{
  if ( mode & MM::COPY_M ) atom() = other.atom();
  if ( mode & MM::COPY_M ) id_ = other.id_;
  if ( mode & MM::COPY_P ) PropertyManager::copy( other );
  return *this;
}

bool MAtom::id_match( const String& id1, const String& id2, const MM::MODE& mode )
{ if ( mode == MM::UNIQUE ) return ( id1 == id2 );
  else return ( id1.substr(0,4) == id2.substr(0,4) ); }


// Monomer

void MMonomer::set_id( const String& s )
{
  id_ = id_tidy( s );
}

void MMonomer::set_type( const String& s )
{ type_ = s; }

void MMonomer::set_seqnum( const int s, const String inscode )
{
  if ( inscode != "" ) set_id( String( s, 4 ) + ":" + inscode );
  else                 set_id( String( s, 4 ) );
}

Atom_list MMonomer::atom_list() const
{
  Atom_list list;
  for ( int a = 0; a < children.size(); a++ )
    list.push_back( Atom( children[a] ) );
  return list;
}

void MMonomer::transform( const RTop_orth rt )
{ for ( int i = 0; i < children.size(); i++ ) children[i].transform( rt ); }

/*! Creates a copy of this monomer containing only the atoms described
  by the selection string. '*' copies all atoms.

  The atom selection must contain an atom ID or a comma separated list
  of atom IDs, or '*' to select all atom. Atom IDs are described in
  s_mm_atom_id.

  The selection string must contain an atom ID or a comma separated
  list of atom IDs. Atom IDs are described in s_mm_atom_id.

  \param sel The selection string.
  \param mode MM::UNIQUE forces an exact match, including alternate conformation code. MM::ANY matches every atom with the right name, ignoring alternate conformation codes.
  \return The selection as a new monomer. */
MMonomer MMonomer::select( const String& sel, const MM::MODE mode ) const
{
  std::vector<String> path = sel.split( "/" );
  while ( path.size() < 1 ) path.push_back( "*" );
  MMonomer result;
  result.copy( *this, MM::COPY_MP );
  if ( path[0].trim() == "*" ) {
    for ( int i = 0; i < children.size(); i++ ) result.insert( children[i] );
    return result;
  } else {
    std::vector<String> list = path[0].split( "," );
    for ( int j = 0; j < list.size(); j++ ) {
      String sid = CHILDTYPE::id_tidy( list[j] );
      for ( int i = 0; i < children.size(); i++ )
	if ( CHILDTYPE::id_match( sid, children[i].id(), mode ) )
	  result.insert( children[i] );
    }
  }
  return result;
}

/*! Lookup atom by ID. If mode=UNIQUE, the alternate conformation code
  must match, otherwise the first atom with the same name is returned.
  \param n The atom ID.  \param mode The search mode.
  \return The atom. */
const MAtom& MMonomer::find( const String& n, const MM::MODE mode ) const
{
  int i = lookup( n, mode );
  if ( i < 0 ) Message::message(Message_fatal("MMonomer: no such atom"));
  return children[i];
}

/*! See MMonomer::find() */
MAtom& MMonomer::find( const String& n, const MM::MODE mode )
{
  int i = lookup( n, mode );
  if ( i < 0 ) Message::message(Message_fatal("MMonomer: no such atom"));
  return children[i];
}

int MMonomer::lookup( const String& str, const MM::MODE& mode ) const
{
  String sid = CHILDTYPE::id_tidy( str );
  for ( int i = 0; i < children.size(); i++ )
    if ( CHILDTYPE::id_match( sid, children[i].id(), mode ) ) return i;
  return -1;
}

void MMonomer::insert( const MAtom& add, int pos )
{
  if ( pos < 0 ) children.push_back( add );
  else children.insert( children.begin() + pos, add );
}

/*! \return atoms which are in both monomers. */
MMonomer operator& ( const MMonomer& m1, const MMonomer& m2 )
{
  MMonomer result;
  result.copy( m1, MM::COPY_MP );
  for ( int i1 = 0; i1 < m1.size(); i1++ )
    for ( int i2 = 0; i2 < m2.size(); i2++ )
      if ( m1[i1].id() == m2[i2].id() ) {
	result.insert( m1[i1] );
	break;
      }
  return result;
}

/*! \return atoms which are in either monomer. */
MMonomer operator| ( const MMonomer& m1, const MMonomer& m2 )
{
  MMonomer result;
  result.copy( m1, MM::COPY_MP );
  int i, j;
  for ( i = 0; i < m1.size(); i++ ) {
    for ( j = 0; j < result.size(); j++ )
      if ( m1[i].id() == result[j].id() ) break;
    if ( j == result.size() )
      result.insert( m1[i] );
  }
  for ( i = 0; i < m2.size(); i++ ) {
    for ( j = 0; j < result.size(); j++ )
      if ( m2[i].id() == result[j].id() ) break;
    if ( j == result.size() )
      result.insert( m2[i] );
  }
  return result;
}

/*! copy from other atom. mode can be MM::COPY_M, COPY_P, COPY_MP,
  COPY_C, COPY_MC, COPY_PC, COPY_MPC, where M means copy members, P
  means copy PropertyMananger properties, and C means copy
  children. Children are copied with the same option. The values
  'MEMBERS', 'PROPERTIES', 'CHILDREN' can also be used. */
MMonomer& MMonomer::copy( const MMonomer& other, const MM::COPY& mode )
{
  if ( mode & MM::COPY_M ) id_ = other.id_;
  if ( mode & MM::COPY_M ) type_ = other.type_;
  if ( mode & MM::COPY_P ) PropertyManager::copy( other );
  if ( mode & MM::COPY_C ) {
    children.resize( other.size() );
    for ( int i = 0; i < size(); i++ ) children[i].copy( other[i], mode );
  }
  return *this;
}

String MMonomer::id_tidy( const String& id )
{
  int pos = id.find( ":" );
  if ( pos == String::npos )
    return String( id.i(), 4 );
  else
    return String( id.i(), 4 ) + id.substr( pos );
}

bool MMonomer::id_match( const String& id1, const String& id2, const MM::MODE& mode )
{ if ( mode == MM::UNIQUE ) return ( id1 == id2 );
  else return ( id1.substr(0,4) == id2.substr(0,4) ); }


// Polymer

void MPolymer::set_id( const String& s ) { id_ = id_tidy( s ); }

Atom_list MPolymer::atom_list() const
{
  Atom_list list;
  for ( int m = 0; m < children.size(); m++ )
    for ( int a = 0; a < children[m].size(); a++ )
      list.push_back( Atom( children[m][a] ) );
  return list;
}

void MPolymer::transform( const RTop_orth rt )
{ for ( int i = 0; i < children.size(); i++ ) children[i].transform( rt ); }

/*! Creates a copy of this polymer containing only the monomers and
  atoms described by the selection string.

  The selection string must be of the form 'X/Y' where X is a monomer
  selection and Y is an atom selection, described under
  MAtom::select(). The monomer selection must contain a monomer ID or
  a comma separated list of monomer IDs, or '*' to select all
  monomers. Monomer IDs are described in s_mm_monomer_id.

  \param sel The selection string.
  \param mode MM::UNIQUE forces an exact match, including insertion code.
              MM::ANY matches any monomer with the right sequence number,
	      ignoring insertion code.
  \return The selection as a new polymer. */
MPolymer MPolymer::select( const String& sel, const MM::MODE mode ) const
{
  std::vector<String> path = sel.split( "/" );
  while ( path.size() < 2 ) path.push_back( "*" );
  MPolymer result;
  result.copy( *this, MM::COPY_MP );
  if ( path[0].trim() == "*" ) {
    for ( int i = 0; i < children.size(); i++ )
      result.insert( children[i].select( path[1], mode ) );
    return result;
  } else {
    std::vector<String> list = path[0].split( "," );
    for ( int j = 0; j < list.size(); j++ ) {
      String sid = CHILDTYPE::id_tidy( list[j] );
      for ( int i = 0; i < children.size(); i++ )
	if ( CHILDTYPE::id_match( sid, children[i].id(), mode ) )
	  result.insert( children[i].select( path[1], mode ) );
    }
  }
  return result;
}

/*! Lookup monomer by ID. If mode=UNIQUE, the insertion code must match,
  otherwise the first monomer with the same sequence number is returned.
  \param n The monomer ID.  \param mode The search mode.
  \return The monomer. */
const MMonomer& MPolymer::find( const String& n, const MM::MODE mode ) const
{
  int i = lookup( n, mode );
  if ( i < 0 ) Message::message(Message_fatal("MPolymer: no such monomer"));
  return children[i];
}

/*! See MPolymer::find() */
MMonomer& MPolymer::find( const String& n, const MM::MODE mode )
{
  int i = lookup( n, mode );
  if ( i < 0 ) Message::message(Message_fatal("MPolymer: no such monomer"));
  return children[i];
}

int MPolymer::lookup( const String& str, const MM::MODE& mode ) const
{
  String sid = CHILDTYPE::id_tidy( str );
  for ( int i = 0; i < children.size(); i++ )
    if ( CHILDTYPE::id_match( sid, children[i].id(), mode ) ) return i;
  return -1;
}

void MPolymer::insert( const MMonomer& add, int pos )
{
  if ( pos < 0 ) children.push_back( add );
  else children.insert( children.begin() + pos, add );
}

/*! \return monomers and atoms which are in both polymers. */
MPolymer operator& ( const MPolymer& m1, const MPolymer& m2 )
{
  MPolymer result;
  result.copy( m1, MM::COPY_MP );
  for ( int i1 = 0; i1 < m1.size(); i1++ )
    for ( int i2 = 0; i2 < m2.size(); i2++ )
      if ( m1[i1].id() == m2[i2].id() ) {
	result.insert( m1[i1] & m2[i2] );
	break;
      }
  return result;
}

/*! \return monomers and atoms which are in either polymer. */
MPolymer operator| ( const MPolymer& m1, const MPolymer& m2 )
{
  MPolymer result;
  result.copy( m1, MM::COPY_MP );
  int i, j;
  for ( i = 0; i < m1.size(); i++ ) {
    for ( j = 0; j < result.size(); j++ )
      if ( m1[i].id() == result[j].id() ) break;
    if ( j == result.size() )
      result.insert( m1[i] );
    else
      result[j] = result[j] | m1[i];
  }
  for ( i = 0; i < m2.size(); i++ ) {
    for ( j = 0; j < result.size(); j++ )
      if ( m2[i].id() == result[j].id() ) break;
    if ( j == result.size() )
      result.insert( m2[i] );
    else
      result[j] = result[j] | m2[i];
  }
  return result;
}

/*! copy from other atom. mode can be MM::COPY_M, COPY_P, COPY_MP,
  COPY_C, COPY_MC, COPY_PC, COPY_MPC, where M means copy members, P
  means copy PropertyMananger properties, and C means copy
  children. Children are copied with the same option. The values
  'MEMBERS', 'PROPERTIES', 'CHILDREN' can also be used. */
MPolymer& MPolymer::copy( const MPolymer& other, const MM::COPY& mode )
{
  if ( mode & MM::COPY_M ) id_ = other.id_;
  if ( mode & MM::COPY_P ) PropertyManager::copy( other );
  if ( mode & MM::COPY_C ) {
    children.resize( other.size() );
    for ( int i = 0; i < size(); i++ ) children[i].copy( other[i], mode );
  }
  return *this;
}

String MPolymer::id_tidy( const String& id ) { return id; }
bool MPolymer::id_match( const String& id1, const String& id2, const MM::MODE& mode ) { return ( id1 == id2 ); }


// Model

Atom_list MModel::atom_list() const
{
  Atom_list list;
  for ( int p = 0; p < children.size(); p++ )
    for ( int m = 0; m < children[p].size(); m++ )
      for ( int a = 0; a < children[p][m].size(); a++ )
        list.push_back( Atom( children[p][m][a] ) );
  return list;
}

void MModel::transform( const RTop_orth rt )
{ for ( int i = 0; i < children.size(); i++ ) children[i].transform( rt ); }

/*! Creates a copy of this model containing only the polymers,
  monomers and atoms described by the selection string.

  The selection string must be of the form 'X/Y/Z' where X is a
  polymer selection, Y is a monomer selection described under
  MMonomer::select(), and Z is an atom selection described under
  MAtom::select(). The polymer selection must contain a polymer ID or
  a comma separated list of polymer IDs, or '*' to select all
  polymers. Polymer IDs are described in s_mm_monomer_id.

  See s_mm_selections for examples.

  \param sel The selection string.
  \param mode No effect.
  \return The selection as a new model. */
MModel MModel::select( const String& sel, const MM::MODE mode ) const
{
  std::vector<String> path = sel.split( "/" );
  while ( path.size() < 3 ) path.push_back( "*" );
  MModel result;
  result.copy( *this, MM::COPY_MP );
  if ( path[0].trim() == "*" ) {
    for ( int i = 0; i < children.size(); i++ )
      result.insert( children[i].select( path[1]+"/"+path[2], mode ) );
    return result;
  } else {
    std::vector<String> list = path[0].split( "," );
    for ( int j = 0; j < list.size(); j++ ) {
      String sid = CHILDTYPE::id_tidy( list[j] );
      for ( int i = 0; i < children.size(); i++ )
	if ( CHILDTYPE::id_match( sid, children[i].id(), mode ) )
	  result.insert( children[i].select( path[1]+"/"+path[2], mode ) );
    }
  }
  return result;
}

/*! Lookup polymer by ID. Currently, mode is ignored.
  \param n The monomer ID.  \param mode The search mode.
  \return The polymer. */
const MPolymer& MModel::find( const String& n, const MM::MODE mode ) const
{
  int i = lookup( n, mode );
  if ( i < 0 ) Message::message(Message_fatal("MModel: no such polymer"));
  return children[i];
}

/*! See MModel::find() */
MPolymer& MModel::find( const String& n, const MM::MODE mode )
{
  int i = lookup( n, mode );
  if ( i < 0 ) Message::message(Message_fatal("MModel: no such polymer"));
  return children[i];
}

int MModel::lookup( const String& str, const MM::MODE& mode ) const
{
  String sid = CHILDTYPE::id_tidy( str );
  for ( int i = 0; i < children.size(); i++ )
    if ( CHILDTYPE::id_match( sid, children[i].id(), mode ) ) return i;
  return -1;
}

void MModel::insert( const MPolymer& add, int pos )
{
  if ( pos < 0 ) children.push_back( add );
  else children.insert( children.begin() + pos, add );
}

/*! \return polymers, monomers and atoms which are in both models. */
MModel operator& ( const MModel& m1, const MModel& m2 )
{
  MModel result;
  result.copy( m1, MM::COPY_MP );
  for ( int i1 = 0; i1 < m1.size(); i1++ )
    for ( int i2 = 0; i2 < m2.size(); i2++ )
      if ( m1[i1].id() == m2[i2].id() ) {
	result.insert( m1[i1] & m2[i2] );
	break;
      }
  return result;
}

/*! \return polymers, monomers and atoms which are in either model. */
MModel operator| ( const MModel& m1, const MModel& m2 )
{
  MModel result;
  result.copy( m1, MM::COPY_MP );
  int i, j;
  for ( i = 0; i < m1.size(); i++ ) {
    for ( j = 0; j < result.size(); j++ )
      if ( m1[i].id() == result[j].id() ) break;
    if ( j == result.size() )
      result.insert( m1[i] );
    else
      result[j] = result[j] | m1[i];
  }
  for ( i = 0; i < m2.size(); i++ ) {
    for ( j = 0; j < result.size(); j++ )
      if ( m2[i].id() == result[j].id() ) break;
    if ( j == result.size() )
      result.insert( m2[i] );
    else
      result[j] = result[j] | m2[i];
  }
  return result;
}

/*! copy from other atom. mode can be MM::COPY_M, COPY_P, COPY_MP,
  COPY_C, COPY_MC, COPY_PC, COPY_MPC, where M means copy members, P
  means copy PropertyMananger properties, and C means copy
  children. Children are copied with the same option. The values
  'MEMBERS', 'PROPERTIES', 'CHILDREN' can also be used. */
MModel& MModel::copy( const MModel& other, const MM::COPY& mode )
{
  if ( mode & MM::COPY_P ) PropertyManager::copy( other );
  if ( mode & MM::COPY_C ) {
    children.resize( other.size() );
    for ( int i = 0; i < size(); i++ ) children[i].copy( other[i], mode );
  }
  return *this;
}


// MiniMol

MiniMol::MiniMol()
{ Message::message( message_ctor_mmodel ); }

/*! The object is constructed with no atoms.
  \param spacegroup the spacegroup.
  \param cell the cell. */
MiniMol::MiniMol( const Spacegroup& spacegroup, const Cell& cell )
{
  init( spacegroup, cell );
  Message::message( message_ctor_mmodel );
}

/*! The object is initialised with no atoms.
  \param spacegroup the spacegroup.
  \param cell the cell. */
void MiniMol::init( const Spacegroup& spacegroup, const Cell& cell )
{
  spacegroup_ = spacegroup;
  cell_ = cell;
}

bool MiniMol::is_null() const
{ return ( spacegroup_.is_null() || cell_.is_null() ); }


} // namespace clipper
