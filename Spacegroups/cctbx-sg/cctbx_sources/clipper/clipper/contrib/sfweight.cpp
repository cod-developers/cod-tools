/* sfweight.cpp: structure factor weighting implementation */
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


#include "sfweight.h"
#include "../core/hkl_operators.h"
#include "../core/resol_targetfn.h"


namespace clipper {


template<class T> bool SFweight_spline<T>::operator() ( HKL_data<datatypes::F_phi<T> >& fb, HKL_data<datatypes::F_phi<T> >& fd, HKL_data<datatypes::Phi_fom<T> >& phiw, const HKL_data<datatypes::F_sigF<T> >& fo0, const HKL_data<datatypes::F_phi<T> >& fc0, const HKL_data<datatypes::Flag>& usage )
{
  HKL_data<datatypes::F_sigF<T> > fo = fo0;
  HKL_data<datatypes::F_phi<T> >  fc = fc0;
  const HKL_info& hkls = fo.base_hkl_info();
  clipper::HKL_info::HKL_reference_index ih;

  // count reflections and determine number of params
  HKL_data<datatypes::Flag_bool> flag(hkls);
  for ( ih = flag.first(); !ih.last(); ih.next() )
    flag[ih].flag() = (!fo[ih].missing()) && (!fc[ih].missing()) &&
      (usage[ih].flag()!=SFweight_base<T>::NONE);
  int npar_sig, npar_scl;
  int n_use = flag.num_obs();
  if ( nparams == 0 ) {
    npar_sig = Util::max( n_use / nreflns, 2 );
  } else if ( nreflns == 0 ) {
    npar_sig = nparams;
  } else {
    double np1 = double(nparams+0.499);
    double np2 = double(n_use) / double(nreflns);
    double np = sqrt( np1*np1*np2*np2 / ( np1*np1+np2*np2 ) );
    npar_sig = Util::max( int(np), 2 );
  }
  npar_scl = npar_sig;
  while ( npar_scl < 12 ) npar_scl *= 2;

  // prepare function
  BasisFn_spline basisfn( flag, npar_sig, 1.0 );
  BasisFn_base::Fderiv dsdp, dwdp;
  TargetResult fn;

  // create E's for scaling
  HKL_data<datatypes::E_sigE<T> > eo( hkls ), ec( hkls );
  for ( ih = hkls.first(); !ih.last(); ih.next() ) {
    eo[ih].E() = fo[ih].f() / sqrt( ih.hkl_class().epsilon() );
    ec[ih].E() = fc[ih].f() / sqrt( ih.hkl_class().epsilon() );
    eo[ih].sigE() = ec[ih].sigE() = 1.0;
  }
  // calc scale
  std::vector<double> param_fo( npar_scl, 1.0 );
  BasisFn_spline bfn_fo( eo, npar_scl, 1.0 );
  TargetFn_scaleEsq<datatypes::E_sigE<T> > tfn_fo( eo );
  ResolutionFn rfn_fo( hkls, bfn_fo, tfn_fo, param_fo );
  std::vector<double> param_fc( npar_scl, 1.0 );
  BasisFn_spline bfn_fc( ec, npar_scl, 1.0 );
  TargetFn_scaleEsq<datatypes::E_sigE<T> > tfn_fc( ec );
  ResolutionFn rfn_fc( hkls, bfn_fc, tfn_fc, param_fc );
  // prescale Fo, Fc
  for ( ih = hkls.first(); !ih.last(); ih.next() ) {
    fo[ih].scale( sqrt( rfn_fo.f(ih) ) );
    fc[ih].scale( sqrt( rfn_fc.f(ih) ) );
  }

  // make first estimate of s
  param_s = std::vector<ftype>( npar_sig, 1.0 );

  // make first estimate of w
  HKL_data<datatypes::F_sigF<T> > ftmp( hkls );
  for ( ih = flag.first_data(); !ih.last(); flag.next_data(ih) )
    ftmp[ih].f() = ftmp[ih].sigf() =
      pow( fo[ih].f() - sqrt(basisfn.f_s(ih.invresolsq(),param_s))*fc[ih].f(), 2.0 ) / ih.hkl_class().epsilonc();
  TargetFn_meanFnth<datatypes::F_sigF<T> > target_w( ftmp, 1.0 );
  ResolutionFn rfn2( hkls, basisfn, target_w, param_w );
  param_w = rfn2.params();

  //for ( int i = 0; i < npar_sig; i++ ) std::cout << i << " " << param_s[i] << "    \t" << param_w[i] << "\n";
  for ( int i = 0; i < npar_sig-1; i++ )  // smooth the error term
    param_w[i] = Util::max( param_w[i], 0.5*param_w[i+1] );
  //for ( int i = 0; i < npar_sig; i++ ) std::cout << i << " " << param_s[i] << "    \t" << param_w[i] << "\n";

  ftype r_old = 1.0e30;
  // now 10 cycles to refine s and w
  int c = 0, clim = 25;
  for ( c = 0; c < clim; c++ ) {
    std::vector<ftype> grad_s( npar_sig, 0.0 ), shft_s( npar_sig, 0.0 );
    std::vector<ftype> grad_w( npar_sig, 0.0 ), shft_w( npar_sig, 0.0 );
    Matrix<ftype> curv_s( npar_sig, npar_sig, 0.0 );
    Matrix<ftype> curv_w( npar_sig, npar_sig, 0.0 );
    ftype r = 0.0;

    // build matrices
    for ( ih = flag.first_data(); !ih.last(); flag.next_data(ih) ) {
      dsdp = basisfn.fderiv_s( ih.invresolsq(), param_s );
      dwdp = basisfn.fderiv_s( ih.invresolsq(), param_w );
      fn = targetfn( ih.hkl_class(), fo[ih], fc[ih], dsdp.f, dwdp.f );
      //if ( Util::isnan(fn.r) ) std::cout << ih.hkl().format() << fo[ih].f() << " " << fo[ih].sigf() << " " << fc[ih].f() << " " << fc[ih].missing() << flag[ih].missing() << " \tFo,SIGo,Fc,missing\n";
      r += fn.r;
      for ( int i = 0; i < npar_sig; i++ ) {
	grad_s[i] += fn.ds * dsdp.df[i];
	grad_w[i] += fn.dw * dwdp.df[i];
	for ( int j = 0; j < npar_sig; j++ ) {
	  curv_s(i,j) += dsdp.df2(i,j)*fn.ds + dsdp.df[i]*dsdp.df[j]*fn.dss;
	  curv_w(i,j) += dwdp.df2(i,j)*fn.dw + dwdp.df[i]*dwdp.df[j]*fn.dww;
	}
      }
    }

    if ( r > r_old ) break;  // break on divergence

    //std::cout << c << "\t" << r << "\n";
    shft_s = curv_s.solve( grad_s );
    shft_w = curv_w.solve( grad_w );
    for ( int i = 0; i < npar_sig; i++ ) {
      //std::cout << i << "   \t" << param_s[i] << "   \t" << param_w[i] << "   \t" << shft_s[i] << "   \t" << shft_w[i] << "\n";
      // soft buffers to prevent negatives
      param_s[i] -= Util::min( shft_s[i], 0.25*param_s[i] );
      param_w[i] -= Util::min( shft_w[i], 0.25*param_w[i] );
    }

    if ( r / r_old > 0.999999 ) break;  // break on convergence
    r_old = r;
  }

  // stop if we didn't converge
  if ( c == clim ) return false;

  // now make new FOMs
  for ( ih = fc.first_data(); !ih.last(); fc.next_data(ih) ) {
    HKL_class cls = ih.hkl_class();
    const ftype sfo = fo[ih].sigf();
    const ftype epc = cls.epsilonc();
    const ftype s = basisfn.f_s( ih.invresolsq(), param_s );
    const ftype w = basisfn.f_s( ih.invresolsq(), param_w );
    const ftype x = ( 2.0 * fo[ih].f() * fc[ih].f() * s )
                  / ( 2.0*sfo*sfo + epc*w );
    fb[ih].phi() = fd[ih].phi() = phiw[ih].phi() = fc[ih].phi();
    if ( cls.centric() ) phiw[ih].fom() = tanh(x);
    else                 phiw[ih].fom() = Util::sim(x);
    if ( !fo[ih].missing() ) {
      fb[ih].f() = 2.0*phiw[ih].fom()*fo[ih].f() - s*fc[ih].f();
      fd[ih].f() = 1.0*phiw[ih].fom()*fo[ih].f() - s*fc[ih].f();
    } else {
      fb[ih].f() = s*fc[ih].f();
      fd[ih].f() = 0.0;
    }
  }

  // undo scaling on fb, fd
  for ( ih = hkls.first(); !ih.last(); ih.next() ) {
    const ftype s = 1.0 / sqrt( rfn_fo.f(ih) );
    fb[ih].scale( s );
    fd[ih].scale( s );
  }

  return true;
}


template<class T> typename SFweight_spline<T>::TargetResult SFweight_spline<T>::targetfn( const HKL_class cls, const datatypes::F_sigF<T>& fo0, const datatypes::F_phi<T>& fc0, const ftype& s, const ftype& w ) const
{
  const ftype s2 = s*s;
  const ftype fo = fo0.f();
  const ftype fc = fc0.f();
  const ftype sfo = fo0.sigf();
  const ftype epc = cls.epsilonc();
  const ftype fo2 = fo*fo;
  const ftype fc2 = fc*fc;
  const ftype d = 2.0*sfo*sfo + epc*w;
  const ftype d2 = d*d;
  const ftype d3 = d*d2;
  const ftype d4 = d*d3;
  ftype i0, di0, ddi0, cf;
  TargetResult r;
  if ( cls.centric() ) {
    i0 = log(cosh(2.0*fo*fc*s/d));
    di0 = tanh(2.0*fo*fc*s/d);
    ddi0 = 1.0-pow(tanh(2.0*fo*fc*s/d),2);
    cf = 0.5;
  } else {
    i0 = Util::sim_integ(2.0*fo*fc*s/d);
    di0 = Util::sim(2.0*fo*fc*s/d);
    ddi0 = Util::sim_deriv(2.0*fo*fc*s/d);
    cf = 1.0;
  }
  r.r = cf*log(d) + (fo2+s2*fc2)/d - i0;
  r.ds = 2.0*s*fc2/d - (2.0*fo*fc/d)*di0;
  r.dw = epc*( cf/d - (fo2+s2*fc2)/d2 + (2.0*fo*fc*s/d2)*di0 );
  r.dss = 2.0*fc2/d - (4.0*fo2*fc2/d2)*ddi0;
  r.dww = epc*epc*( -cf/d2 + 2.0*(fo2+s2*fc2)/d3
      	      - (4.0*fo*fc*s/d3)*di0 - (4.0*fo2*fc2*s2/d4)*ddi0 );
  r.dsw = epc*( -2.0*s*fc2/d2 + (2.0*fo*fc/d2)*di0
      	  + (4.0*fo2*fc2*s/d3)*ddi0 );
  return r;
}


template<class T> void SFweight_spline<T>::debug() const
{
  TargetResult r00, r01, r10, r11;
  Spacegroup p1( Spacegroup::P1 );
  HKL_class cls;
  cls = HKL_class( p1, HKL( 1, 0, 0 ) );
  datatypes::F_sigF<T> fo;
  datatypes::F_phi<T>  fc;
  fo.f() = 10.0; fo.sigf() = 2.0;
  fc.f() = 15.0; fc.phi() = 0.0;
  ftype ds = 0.000001;
  ftype dw = 0.000001;
  for ( int h = 0; h < 2; h++ ) {
    cls = HKL_class( p1, HKL( h, 0, 0 ) );
    std::cout << "\nCentric? " << cls.centric() << " epsc " << cls.epsilonc() << "\n";
    for ( ftype w = 10.0; w < 1000.0; w *= 3.0 )
      for ( ftype s = 0.4; s < 2.0; s *= 2.0 ) {

        r00 = targetfn( cls, fo, fc, s, w );
        r01 = targetfn( cls, fo, fc, s, w+dw );
        r10 = targetfn( cls, fo, fc, s+ds, w );
        r11 = targetfn( cls, fo, fc, s+ds, w+dw );

        std::cout << w << " " << s << "\t" << r00.r << " " << r01.r << " " << r10.r << " " << r11.r << "\n";
        std::cout << (r10.r-r00.r)/ds << "\t" << r00.ds << "\n";
        std::cout << (r01.r-r00.r)/dw << "\t" << r00.dw << "\n";
        std::cout << (r10.ds-r00.ds)/ds << "\t" << r00.dss << "\n";
        std::cout << (r01.dw-r00.dw)/dw << "\t" << r00.dww << "\n";
        std::cout << (r01.ds-r00.ds)/dw << "\t" << r00.dsw << "\n";
        std::cout << (r10.dw-r00.dw)/ds << "\t" << r00.dsw << "\n";
      }
  }
}


// compile templates

template class SFweight_spline<ftype32>;

template class SFweight_spline<ftype64>;


} // namespace clipper
