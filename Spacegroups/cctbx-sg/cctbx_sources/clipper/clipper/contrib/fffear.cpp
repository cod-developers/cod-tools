/* fffear.cpp: FFFear implementation */
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

#include "fffear.h"

#include "../core/map_interp.h"


namespace clipper {


// deprecated forms

bool FFFear_slow_basic::operator() ( Xmap<float>& result, const NXmap<float>& srchval, const NXmap<float>& srchwgt ) const
{
  const Xmap<float>& xmap = *xmp;
  Xmap<float>::Map_reference_index pos;
  Xmap<float>::Map_reference_coord i0, iu, iv, iw;
  NXmap<float>::Map_reference_index in( srchval );
  Coord_grid g0, g1, off0, off1, nx;
  float s;

  off0 = Coord_grid( srchval.grid().nu()/2,
		     srchval.grid().nv()/2,
		     srchval.grid().nw()/2 );
  off1 = Coord_grid( srchval.grid().nu() - off0.u() - 1,
		     srchval.grid().nv() - off0.w() - 1,
		     srchval.grid().nw() - off0.w() - 1 );

  for ( pos = result.first(); !pos.last(); pos.next() ) {
    g0 = pos.coord() - off0;
    g1 = pos.coord() + off1;
    i0 = Xmap_base::Map_reference_coord( *xmp, g0 );
    s = 0.0;
    for ( iu = i0; iu.coord().u() <= g1.u(); iu.next_u() )
      for ( iv = iu; iv.coord().v() <= g1.v(); iv.next_v() )
	for ( iw = iv; iw.coord().w() <= g1.w(); iw.next_w() ) {
	  in.set_coord( iw.coord() - g0 );
	  s += srchwgt[in] * pow( xmap[iw] - srchval[in], 2 );
	}
    result[pos] = s;
  }
  return true;
}


void FFFear_fft_basic::init( const Xmap<float>& xmap )
{
  vol = xmap.cell().volume();
  rho1.init( xmap.grid_sampling() );
  rho2.init( xmap.grid_sampling() );

  const Grid_sampling& g = xmap.grid_sampling();
  float r;
  Xmap<float>::Map_reference_coord i0( xmap, Coord_grid(0,0,0) );
  Xmap<float>::Map_reference_coord iu, iv, iw;
  for ( iu = i0; iu.coord().u() < g.nu(); iu.next_u() )
    for ( iv = iu; iv.coord().v() < g.nv(); iv.next_v() )
      for ( iw = iv; iw.coord().w() < g.nw(); iw.next_w() ) {
	r = xmap[iw];
	rho1.real_data( iw.coord() ) = r;
	rho2.real_data( iw.coord() ) = r*r;
      }
  rho1.fft_x_to_h( vol );
  rho2.fft_x_to_h( vol );
}

bool FFFear_fft_basic::operator() ( Xmap<float>& result, const NXmap<float>& srchval, const NXmap<float>& srchwgt ) const
{
  const Grid_sampling& g = rho1.grid_real();
  FFTmap_p1 map1( g );
  FFTmap_p1 map2( g );

  // copy mask into grid, with offset
  Coord_grid c0, c1, c;
  c0 = Coord_grid( srchval.grid().nu()/2,
		   srchval.grid().nv()/2,
		   srchval.grid().nw()/2 );
  ftype f, w;
  ftype swff = 0.0;
  const Grid& gx = srchval.grid();
  for ( c.u() = 0; c.u() < gx.nu(); c.u()++ )
    for ( c.v() = 0; c.v() < gx.nv(); c.v()++ )
      for ( c.w() = 0; c.w() < gx.nw(); c.w()++ ) {
	c1 = (c - c0).unit(g);
	f = srchval.get_data(c);
	w = srchwgt.get_data(c);
	map1.real_data( c1 ) = w;
	map2.real_data( c1 ) = w*f;
	swff += w*f*f;
      }

  // fft
  map1.fft_x_to_h( vol );
  map2.fft_x_to_h( vol );

  // calculate
  const Grid& gh = map1.grid_reci();
  const ftype32 two = 2.0;
  std::complex<ftype32> ww, wf, r1, r2;
  for ( c.u() = 0; c.u() < gh.nu(); c.u()++ )
    for ( c.v() = 0; c.v() < gh.nv(); c.v()++ )
      for ( c.w() = 0; c.w() < gh.nw(); c.w()++ ) {
	r1 = rho1.cplx_data( c );
	r2 = rho2.cplx_data( c );
	ww = map1.cplx_data( c );
	wf = map2.cplx_data( c );
	map1.cplx_data( c ) = std::conj(ww)*r2 - two*std::conj(wf)*r1;
      }
  // invert
  map1.fft_h_to_x( 1.0 / vol );

  // store
  ftype s = map1.grid_real().size() / vol;
  for ( Xmap<ftype32>::Map_reference_index ix = result.first();
	!ix.last(); ix.next() )
    result[ix] = swff + s * map1.real_data( ix.coord() );

  return true;
}


// general forms
// slow fffear

template<class T> bool FFFear_slow<T>::operator() ( Xmap<T>& result, const NXmap<T>& srchval, const NXmap<T>& srchwgt ) const
{
  NX_operator nxop( result, srchval, RTop_orth::identity() );
  return (*this)( result, srchval, srchwgt, nxop );
}

template<class T> bool FFFear_slow<T>::operator() ( Xmap<T>& result, const NXmap<T>& srchval, const NXmap<T>& srchwgt, const NX_operator& nxop ) const
{
  const Grid_sampling& g = result.grid_sampling();

  // calculate extent of mask function in Xmap space
  Coord_frac cf;
  Range<ftype> urange, vrange, wrange;
  typename NXmap<T>::Map_reference_index inx;
  for ( inx = srchwgt.first(); !inx.last(); inx.next() )
    if ( srchwgt[inx] > 0.0 ) {
      cf = nxop.coord_frac( inx.coord().coord_map() );
      urange.include( cf.u() );
      vrange.include( cf.v() );
      wrange.include( cf.w() );
    }
  cf = Coord_frac( urange.min(), vrange.min(), wrange.min() );
  Coord_grid g0 = cf.coord_map( g ).floor();
  cf = Coord_frac( urange.max(), vrange.max(), wrange.max() );
  Coord_grid g1 = cf.coord_map( g ).ceil();
  Grid_range gm( g0, g1 );

  // copy provided NXmap in new NXmap shadowing the xtal grid
  NXmap<T> target( result.cell(), g, gm );
  NXmap<T> weight( result.cell(), g, gm );
  target = weight = 0.0;
  typename NXmap<T>::Map_reference_index in;
  Coord_map cm;
  for ( in = target.first(); !in.last(); in.next() ) {
    cm = nxop.coord_map( in.coord_orth().coord_frac( result.cell() ) );
    if ( Interp_linear::can_interp( srchval, cm ) &&
	 Interp_linear::can_interp( srchval, cm ) ) {
	  Interp_linear::interp( srchval, cm, target[in] );
	  Interp_linear::interp( srchwgt, cm, weight[in] );
    }
  }

  // now calculate the search function
  const Xmap<T>& xmap = *xmp;
  typename Xmap<T>::Map_reference_index pos;
  typename Xmap<T>::Map_reference_coord i0, iu, iv, iw;
  T s;
  for ( pos = result.first(); !pos.last(); pos.next() ) {
    g0 = pos.coord() + gm.min();
    g1 = pos.coord() + gm.max();
    i0 = Xmap_base::Map_reference_coord( xmap, g0 );
    s = 0.0;
    for ( iu = i0; iu.coord().u() <= g1.u(); iu.next_u() )
      for ( iv = iu; iv.coord().v() <= g1.v(); iv.next_v() )
	for ( iw = iv; iw.coord().w() <= g1.w(); iw.next_w() ) {
	  in.set_coord( iw.coord() - g0 );
	  s += weight[in] * pow( xmap[iw] - target[in], 2 );
	}
    result[pos] = s;
  }

  return true;
}


// fast fffear

template<class T> void FFFear_fft<T>::init( const Xmap<T>& xmap )
{
  vol = xmap.cell().volume();
  rho1.init( xmap.grid_sampling() );
  rho2.init( xmap.grid_sampling() );

  const Grid_sampling& g = xmap.grid_sampling();
  T r;
  typename Xmap<T>::Map_reference_coord i0( xmap, Coord_grid(0,0,0) );
  typename Xmap<T>::Map_reference_coord iu, iv, iw;
  for ( iu = i0; iu.coord().u() < g.nu(); iu.next_u() )
    for ( iv = iu; iv.coord().v() < g.nv(); iv.next_v() )
      for ( iw = iv; iw.coord().w() < g.nw(); iw.next_w() ) {
	r = xmap[iw];
	rho1.real_data( iw.coord() ) = r;
	rho2.real_data( iw.coord() ) = r*r;
      }
  rho1.fft_x_to_h( vol );
  rho2.fft_x_to_h( vol );
}

template<class T> bool FFFear_fft<T>::operator() ( Xmap<T>& result, const NXmap<T>& srchval, const NXmap<T>& srchwgt ) const
{
  NX_operator nxop( result, srchval, RTop_orth::identity() );
  return (*this)( result, srchval, srchwgt, nxop );
}

template<class T> bool FFFear_fft<T>::operator() ( Xmap<T>& result, const NXmap<T>& srchval, const NXmap<T>& srchwgt, const NX_operator& nxop ) const
{
  const Grid_sampling& g = rho1.grid_real();
  FFTmap_p1 map1( g );
  FFTmap_p1 map2( g );

  // calculate extent of mask function in Xmap space
  Coord_frac cf;
  Range<ftype> urange, vrange, wrange;
  typename NXmap<T>::Map_reference_index inx;
  for ( inx = srchwgt.first(); !inx.last(); inx.next() )
    if ( srchwgt[inx] > 0.0 ) {
      cf = nxop.coord_frac( inx.coord().coord_map() );
      urange.include( cf.u() );
      vrange.include( cf.v() );
      wrange.include( cf.w() );
    }
  cf = Coord_frac( urange.min(), vrange.min(), wrange.min() );
  Coord_grid g0 = cf.coord_map( g ).floor();
  cf = Coord_frac( urange.max(), vrange.max(), wrange.max() );
  Coord_grid g1 = cf.coord_map( g ).ceil();

  // copy mask into grid, with offset
  Coord_grid c, cu;
  Coord_map cm;
  T f, w;
  ftype64 swff = 0.0;
  for ( c.u() = g0.u(); c.u() <= g1.u(); c.u()++ )
    for ( c.v() = g0.v(); c.v() <= g1.v(); c.v()++ )
      for ( c.w() = g0.w(); c.w() <= g1.w(); c.w()++ ) {
	cm = nxop.coord_map( c.coord_frac( g ) );
	if ( Interp_linear::can_interp( srchval, cm ) &&
	     Interp_linear::can_interp( srchval, cm ) ) {
	  Interp_linear::interp( srchval, cm, f );
	  Interp_linear::interp( srchwgt, cm, w );
	  cu = c.unit(g);
	  map1.real_data( cu ) = w;
	  map2.real_data( cu ) = w*f;
	  swff += w*f*f;
	}
      }

  // fft
  map1.fft_x_to_h( vol );
  map2.fft_x_to_h( vol );

  // calculate
  const Grid& gh = map1.grid_reci();
  const ftype32 two = 2.0;
  std::complex<ftype32> ww, wf, r1, r2;
  for ( c.u() = 0; c.u() < gh.nu(); c.u()++ )
    for ( c.v() = 0; c.v() < gh.nv(); c.v()++ )
      for ( c.w() = 0; c.w() < gh.nw(); c.w()++ ) {
	r1 = rho1.cplx_data( c );
	r2 = rho2.cplx_data( c );
	ww = map1.cplx_data( c );
	wf = map2.cplx_data( c );
	map1.cplx_data( c ) = std::conj(ww)*r2 - two*std::conj(wf)*r1;
      }
  // invert
  map1.fft_h_to_x( map1.grid_real().size() / pow( vol, 2 ) );

  // store
  for ( typename Xmap<T>::Map_reference_index ix = result.first();
	!ix.last(); ix.next() )
    result[ix] = swff + map1.real_data( ix.coord() );

  return true;
}


// compile templates

template class FFFear_slow<ftype32>;
template class FFFear_slow<ftype64>;
template class FFFear_fft<ftype32>;
template class FFFear_fft<ftype64>;


} // namespace clipper
