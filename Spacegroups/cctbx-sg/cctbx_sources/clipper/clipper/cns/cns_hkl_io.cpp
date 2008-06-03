/* cns_hkl_io.cpp: class file for reflection data  cns_hkl importer */
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

#include "cns_hkl_io.h"

extern "C" {
#include <stdio.h>
}


namespace clipper {


clipper::String cnstok( FILE* f ) {
  String s;
  char c = fgetc( f );
  while ( c > '\0' && c < ' ' ) c = fgetc( f );
  while ( c > ' ' && c != '=') {
    s += c;
    c = fgetc( f );
  }
  return s;
}


/*! Constructing an CNS_HKLfile does nothing except flag the object as not
  attached to any file for either input or output */
CNS_HKLfile::CNS_HKLfile()
{
  mode = NONE;
}


/*! Close any files which were left open. This is particularly
  important since to access the CNS_HKL file efficiently, data reads and
  writes are deferred until the file is closed. */
CNS_HKLfile::~CNS_HKLfile()
{
  switch ( mode ) {
  case READ:
    close_read(); break;
  case WRITE:
    close_write(); break;
  }
}


/*! The file is opened for reading. This CNS_HKLfile object will remain
  attached to this file until it is closed. Until that occurs, no
  other file may be opened with this object, however another CNS_HKLfile
  object could be used to access another file.
  \param filename_in The input filename or pathname. */
void CNS_HKLfile::open_read( const String filename_in )
{
  if ( mode != NONE )
    Message::message( Message_fatal( "CNS_HKLfile: open_read - File already open" ) );

  // open the cns_hkl
  f_sigf_i = NULL; phi_wt_i = NULL; f_phi_i = NULL; abcd_i = NULL; flag_i = NULL;
  filename = filename_in;

  FILE* cns_hkl = fopen( filename.c_str(), "r" );
  if ( cns_hkl == NULL )
    Message::message( Message_fatal( "CNS_HKLfile: open_read  - Could not read: "+filename ) );
  fclose( cns_hkl );

  mode = READ;
}


/*! Close the file after reading. This command also actually fills in
  the data in any HKL_data structures which have been marked for
  import. */
void CNS_HKLfile::close_read()
{
  if ( mode != READ )
    Message::message( Message_fatal( "CNS_HKLfile: no file open for read" ) );

  // make sure the data list is sized
  if ( f_sigf_i != NULL ) f_sigf_i->update();
  if ( phi_wt_i != NULL ) phi_wt_i->update();
  if ( f_phi_i  != NULL ) f_phi_i->update();
  if ( abcd_i   != NULL ) abcd_i->update();
  if ( flag_i   != NULL ) flag_i->update();


  int h, k, l;
  xtype fo[8], pw[8], fc[8], hl[8], fl[8];
  h = k = l = 0;
  HKL hkl;

  char line[240];
  FILE* cns_hkl = fopen( filename.c_str(), "r" );
  if ( cns_hkl == NULL )
    Message::message( Message_fatal( "CNS_HKLfile: import_hkl_data  - Could not read: "+filename ) );
  // read the data from the CNS_HKL
  int code = 0;
  String s, t;
  while ( (s=cnstok(cns_hkl)).length() > 0 ) {
    t = (s+"   ").substr(0,4);
    if ( t == "INDE" ) {
      if (h||k||l) {
	hkl = HKL( h, k, l );
	if ( f_sigf_i != NULL ) f_sigf_i->data_import( hkl, fo );
	if ( phi_wt_i != NULL ) phi_wt_i->data_import( hkl, pw );
	if ( f_phi_i  != NULL ) f_phi_i->data_import( hkl, fc );
	if ( abcd_i   != NULL ) abcd_i->data_import( hkl, hl );
	if ( flag_i   != NULL ) flag_i->data_import( hkl, fl );
      }
      h = k = l = 0;
      for ( int i = 0; i < 8; i++ ) fo[i] = pw[i] = fc[i] = hl[i] = fl[i] = 0.0;
    }
    if      ( t == "INDE" ) code = 10;
    else if ( t == "FOBS" ) code = 20;
    else if ( t == "SIGM" ) code = 30;
    else if ( t == "FOM " ) code = 40;
    else if ( t == "FCAL" ) code = 50;
    else if ( t == "ABCD" ) code = 60;
    else if ( t == "TEST" ) code = 70;
    else if ( code == 10 ) { h = s.i(); code++; }
    else if ( code == 11 ) { k = s.i(); code++; }
    else if ( code == 12 ) { l = s.i(); code++; }
    else if ( code == 20 ) { fo[0] = s.f(); code++; }
    else if ( code == 21 ) { pw[0] = s.f(); code++; }
    else if ( code == 30 ) { fo[1] = s.f(); code++; }
    else if ( code == 40 ) { pw[1] = s.f(); code++; }
    else if ( code == 50 ) { fc[0] = s.f(); code++; }
    else if ( code == 51 ) { fc[1] = s.f(); code++; }
    else if ( code == 60 ) { hl[0] = s.f(); code++; }
    else if ( code == 61 ) { hl[1] = s.f(); code++; }
    else if ( code == 62 ) { hl[2] = s.f(); code++; }
    else if ( code == 63 ) { hl[3] = s.f(); code++; }
    else if ( code == 70 ) { fl[0] = s.f(); code++; }
  }
  if (h||k||l) {  // get last rfl
    hkl = HKL( h, k, l );
    if ( f_sigf_i != NULL ) f_sigf_i->data_import( hkl, fo );
    if ( phi_wt_i != NULL ) phi_wt_i->data_import( hkl, pw );
    if ( f_phi_i  != NULL ) f_phi_i->data_import( hkl, fc );
    if ( abcd_i   != NULL ) abcd_i->data_import( hkl, hl );
    if ( flag_i   != NULL ) flag_i->data_import( hkl, fl );
  }
  fclose( cns_hkl );

  mode = NONE;
}


/*! The file is opened for writing. This will be a new file, created
  entirely from data from within the program, rather than by extending
  an existing file. Similar restrictions apply as for open_read().

  \param filename_out The output filename or pathname. */
void CNS_HKLfile::open_write( const String filename_out )
{
  if ( mode != NONE )
    Message::message( Message_fatal( "CNS_HKLfile: open_write - File already open" ) );

  // open the output cns_hkl
  hkl_ptr = NULL;
  f_sigf_o = NULL; phi_wt_o = NULL; f_phi_o = NULL; abcd_o = NULL; flag_o = NULL;
  filename = filename_out;

  FILE* cns_hkl = fopen( filename.c_str(), "w" );
  if ( cns_hkl == NULL )
    Message::message( Message_fatal( "CNS_HKLfile: open_write - Could not write: "+filename ) );
  fclose( cns_hkl );

  mode = WRITE;
}


/*! Close the file after writing. This command also actually writes
  the data reflection list from the HKL_info object and the data from
  any HKL_data objects which have been marked for import. */
void CNS_HKLfile::close_write()
{
  if ( mode != WRITE )
    Message::message( Message_fatal( "CNS_HKLfile: close_write - no file open for write" ) );

  // export the marked list data to an cns_hkl file
  if ( hkl_ptr == NULL )
    Message::message( Message_fatal( "CNS_HKLfile: close_write - no refln list exported" ) );
  const HKL_info& hklinf = *hkl_ptr;

  HKL hkl;
  xtype x[4];
  float f1, f2, f3, f4;

  FILE* cns_hkl = fopen( filename.c_str(), "w" );
  if ( cns_hkl == NULL )
    Message::message( Message_fatal( "CNS_HKLfile: close_write - Could not write: "+filename ) );
  fprintf( cns_hkl, "NREF=%i\n", hklinf.num_reflections() );
  HKL_info::HKL_reference_index ih;
  for ( ih = hklinf.first(); !ih.last(); ih.next() ) {
    f1 = f2 = f3 = f4 = 0.0;  // default sigf to 0 in case missing
    hkl = ih.hkl();
    fprintf( cns_hkl, "INDE %i %i %i", hkl.h(), hkl.k(), hkl.l() );
    if ( f_sigf_o != NULL ) {
      f_sigf_o->data_export( hkl, x );
      for ( int i = 0; i < 4; i++ ) if ( Util::is_nan(x[i]) ) x[i] = 0.0;
      f1 = float( x[0] );
      f2 = float( x[1] );
    }
    if ( phi_wt_o != NULL ) {
      phi_wt_o->data_export( hkl, x );
      for ( int i = 0; i < 4; i++ ) if ( Util::is_nan(x[i]) ) x[i] = 0.0;
      f3 = float( x[0] );
      f4 = float( x[1] );
    }
    fprintf( cns_hkl, " FOBS=%.3f %.3f SIGM=%.3f FOM=%.3f",f1,f3,f2,f4 );
    if ( f_phi_o != NULL ) {
      f_phi_o->data_export( hkl, x );
      for ( int i = 0; i < 4; i++ ) if ( Util::is_nan(x[i]) ) x[i] = 0.0;
      fprintf( cns_hkl, " FCAL=%.3f %.3f",float(x[0]),float(x[1]) );
    }
    if ( abcd_o != NULL ) {
      abcd_o->data_export( hkl, x );
      for ( int i = 0; i < 4; i++ ) if ( Util::is_nan(x[i]) ) x[i] = 0.0;
      fprintf( cns_hkl, " HLA=%.1f HLB=%.1f HLC=%.1f HLD=%.1f",float(x[0]),float(x[1]),float(x[2]),float(x[3]) );
    }
    if ( flag_o != NULL ) {
      abcd_o->data_export( hkl, x );
      for ( int i = 0; i < 4; i++ ) if ( Util::is_nan(x[i]) ) x[i] = 0.0;
      fprintf( cns_hkl, " TEST=",Util::intr(x[0]) );
    }
    fprintf( cns_hkl, "\n" );
  }
  fclose( cns_hkl );

  mode = NONE;
}


/*! Get the resolution limit from the CNS_HKL file.
  Since a CNS_HKL file does not contain cell information, a Cell object
  must be supplied, which will be used to determine the resultion.
  The result is the resolution determined by the most extreme
  reflection in the file.
  \return The resolution. */
Resolution CNS_HKLfile::resolution( const Cell& cell ) const
{
  if ( mode != READ )
    Message::message( Message_fatal( "CNS_HKLfile: resolution - no file open for read" ) );

  HKL hkl;
  int h, k, l;
  char line[240];
  FILE* cns_hkl = fopen( filename.c_str(), "r" );
  if ( cns_hkl == NULL )
    Message::message( Message_fatal( "CNS_HKLfile: resolution - Could not read: "+filename ) );
  // read the reflections from the cns_hkl
  ftype slim = 0.0;
  String s, t;
  while ( (s=cnstok(cns_hkl)).length() > 0 ) {
    t = (s+"   ").substr(0,4);
    if ( t == "INDE" ) {
      h = cnstok(cns_hkl).i();
      k = cnstok(cns_hkl).i();
      l = cnstok(cns_hkl).i();
      hkl = HKL( h, k, l );
      slim = Util::max( slim, hkl.invresolsq(cell) );
    }
  }
  fclose( cns_hkl );

  return Resolution( 1.0/sqrt(slim) );
}


/*! Import the list of reflection HKLs from an CNS_HKL file into an
  HKL_info object. If the resolution limit of the HKL_info object is
  lower than the limit of the file, any excess reflections will be
  rejected, as will any systematic absences or duplicates.
  \param target The HKL_info object to be initialised. */
void CNS_HKLfile::import_hkl_info( HKL_info& target )
{
  if ( mode != READ )
    Message::message( Message_fatal( "CNS_HKLfile: import_hkl_info - no file open for read" ) );

  std::vector<HKL> hkls;
  HKL hkl;
  int h, k, l;
  char line[240];
  FILE* cns_hkl = fopen( filename.c_str(), "r" );
  if ( cns_hkl == NULL )
    Message::message( Message_fatal( "CNS_HKLfile: import_hkl_info - Could not read: "+filename ) );
  // read the reflections from the cns_hkl
  ftype slim = target.resolution().invresolsq_limit();
  String s, t;
  while ( (s=cnstok(cns_hkl)).length() > 0 ) {
    t = (s+"   ").substr(0,4);
    if ( t == "INDE" ) {
      h = cnstok(cns_hkl).i();
      k = cnstok(cns_hkl).i();
      l = cnstok(cns_hkl).i();
      hkl = HKL( h, k, l );
      if ( hkl.invresolsq(target.cell()) < slim ) hkls.push_back( hkl );
    }
  }
  fclose( cns_hkl );

  target.add_hkl_list( hkls );
}


/*! Import data from an CNS_HKL file into an HKL_data object.

  This routine does not actually read any data, but rather marks the
  data to be read when the file is closed.

  The data to be read (F_sigF or Phi_fom) will be selected based on
  the type of the HKL_data object.

  \param cdata The HKL_data object into which data is to be imported. */
void CNS_HKLfile::import_hkl_data( HKL_data_base& cdata )
{
  if ( mode != READ )
    Message::message( Message_fatal( "CNS_HKLfile: import_hkl_data - no file open for read" ) );

  if      ( cdata.type() == data32::F_sigF::type()  ) f_sigf_i = &cdata;
  else if ( cdata.type() == data32::Phi_fom::type() ) phi_wt_i = &cdata;
  else if ( cdata.type() == data32::F_phi::type() )   f_phi_i  = &cdata;
  else if ( cdata.type() == data32::ABCD::type() )    abcd_i   = &cdata;
  else if ( cdata.type() == data32::Flag::type() )    flag_i   = &cdata;
  else
    Message::message( Message_fatal( "CNS_HKLfile: import_hkl_data - data must be F_sigF/Phi_fom/F_phi/ABCD/Flag" ) );
}


/*! Export the list of reflection HKLs to an CNS_HKL file from an
  HKL_info object. */
void CNS_HKLfile::export_hkl_info( const HKL_info& target )
{
  if ( mode != WRITE )
    Message::message( Message_fatal( "CNS_HKLfile: export_hkl_info - no file open for write" ) );
  hkl_ptr = &target;
}


/*! Export data from an HKL_data object into an CNS_HKL file.

  This routine does not actually write any data, but rather marks the
  data to be written when the file is closed.

  The data to be read (F_sigF or Phi_fom) will be selected based on
  the type of the HKL_data object.

  \param cdata The HKL_data object from which data is to be exported. */
void CNS_HKLfile::export_hkl_data( const HKL_data_base& cdata )
{
  if ( mode != WRITE )
    Message::message( Message_fatal( "CNS_HKLfile: export_hkl_data - no file open for write" ) );

  if      ( cdata.type() == data32::F_sigF::type()  ) f_sigf_o = &cdata;
  else if ( cdata.type() == data32::Phi_fom::type() ) phi_wt_o = &cdata;
  else if ( cdata.type() == data32::F_phi::type() )   f_phi_o  = &cdata;
  else if ( cdata.type() == data32::ABCD::type() )    abcd_o   = &cdata;
  else if ( cdata.type() == data32::Flag::type() )    flag_o   = &cdata;
  else
    Message::message( Message_fatal( "CNS_HKLfile: export_hkl_data - data must be F_sigF/Phi_fom/F_phi/ABCD/Flag" ) );
}


} // namespace clipper
