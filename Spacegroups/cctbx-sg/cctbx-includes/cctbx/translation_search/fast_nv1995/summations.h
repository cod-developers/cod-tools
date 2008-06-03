#ifndef CCTBX_TRANSLATION_SEARCH_FAST_NV1995_SUMMATIONS_H
#define CCTBX_TRANSLATION_SEARCH_FAST_NV1995_SUMMATIONS_H

// Navaza, J. & Vernoslova, E. (1995). Acta Cryst. A51, 445-449.

#include <cctbx/sgtbx/space_group.h>
#include <cctbx/sgtbx/miller_ops.h>
#include <cctbx/maptbx/utils.h>
#include <scitbx/array_family/versa_plain.h>
#include <boost/scoped_array.hpp>

namespace cctbx { namespace translation_search { namespace fast_nv1995_detail {

  class hermitian_accessor
  {
    public:
      typedef miller::index<> index_type;
      typedef miller::index<>::value_type index_value_type;

      struct index_1d_flag_conj
      {
        long index_1d;
        bool is_conj;
      };

      hermitian_accessor() {}

      hermitian_accessor(bool anomalous_flag,
                         miller::index<> const& n,
                         bool two_n_minus_one_flag)
      :
        anomalous_flag_(anomalous_flag),
        range_(two_n_minus_one_flag ? miller::index<>(2*n-1) : n)
      {
        if (!anomalous_flag_) range_[2] = n[2];
      }

      std::size_t
      size_1d() const { return range_.product(); }

      index_value_type
      operator[](std::size_t i) const { return range_[i]; }

      bool
      anomalous_flag() const { return anomalous_flag_; }

      index_1d_flag_conj
      operator()(miller::index<> h) const
      {
        miller::index<> i3d;
        index_1d_flag_conj result;
        result.index_1d = -1;
        result.is_conj = false;
        if (!anomalous_flag_) {
          if (h[2] < 0) {
            h = -h;
            result.is_conj = true;
          }
          for(std::size_t i=0;i<2;i++) {
            i3d[i] = maptbx::h_as_ih_exact(h[i], range_[i], false);
          }
          i3d[2] = maptbx::h_as_ih_exact(h[2], range_[2], true);
        }
        else {
          for(std::size_t i=0;i<3;i++) {
            i3d[i] = maptbx::h_as_ih_exact(h[i], range_[i], false);
          }
        }
        if (i3d.min() < 0) return result;
        // Manually optimized for best performance.
        result.index_1d = (i3d[0] * range_[1] + i3d[1]) * range_[2] + i3d[2];
        return result;
      }

    protected:
      bool anomalous_flag_;
      miller::index<> range_;
  };

  // Class for accessing the 3d array of f_calc.
  template <typename FloatType>
  class f_calc_map
  {
    public:
      typedef std::complex<FloatType> complex_type;
      typedef af::versa_plain<complex_type, hermitian_accessor>
                data_array_type;

      f_calc_map() {}

      f_calc_map(bool anomalous_flag,
                 miller::index<> const& abs_range)
      :
        data_(hermitian_accessor(anomalous_flag, abs_range, true))
      {}

      bool
      anomalous_flag() const { return data_.accessor().anomalous_flag(); }

      void import(af::const_ref<miller::index<> > const& miller_indices,
                  af::const_ref<complex_type> const& f_calc)
      {
        CCTBX_ASSERT(miller_indices.size() == f_calc.size());
        for(std::size_t i=0;i<f_calc.size();i++) {
          set(miller_indices[i], f_calc[i]);
        }
      }

      complex_type
      operator()(miller::index<> const& h) const
      {
        hermitian_accessor::index_1d_flag_conj ic = data_.accessor()(h);
        if (ic.index_1d < 0) return complex_type(0);
        if (ic.is_conj) return std::conj(data_[ic.index_1d]);
        return data_[ic.index_1d];
      }

    protected:
      void
      set(miller::index<> const& h, complex_type const& val)
      {
        hermitian_accessor::index_1d_flag_conj ic = data_.accessor()(h);
        CCTBX_ASSERT(ic.index_1d >= 0);
        if (ic.is_conj) data_[ic.index_1d] = std::conj(val);
        else            data_[ic.index_1d] =           val;
        if (anomalous_flag() || h[2] != 0) return;
        ic = data_.accessor()(-h);
        CCTBX_ASSERT(ic.index_1d >= 0);
        if (ic.is_conj) data_[ic.index_1d] =           val;
        else            data_[ic.index_1d] = std::conj(val);
      }

      data_array_type data_;
  };

  // Class for accumulating the results of the summations.
  template <typename FloatType>
  class summation_accumulator
  {
    private:
      typedef std::complex<FloatType> complex_type;
      typedef typename miller::index<>::value_type mi_v_t;

    public:
      summation_accumulator() {}

      summation_accumulator(complex_type* begin,
                            miller::index<> const& n_real,
                            miller::index<> const& n_complex)
      :
        begin_(begin),
        n_0_(n_real[0]),
        n_1_(n_real[1]),
        n_real_2_(n_real[2]),
        n_complex_2_(n_complex[2])
      {
        CCTBX_ASSERT(n_complex[0] == n_real[0]);
        CCTBX_ASSERT(n_complex[1] == n_real[1]);
        CCTBX_ASSERT(n_complex[2] == n_real[2]/2+1);
      }

      void
      plus_000(FloatType const& cf)
      {
        begin_[0] += cf;
      }

      // Adds cf if -h is in the positive halfspace.
      // Ignores cf otherwise.
      // Manually optimized for best performance.
      void
      minus(miller::index<> const& h, complex_type const& cf)
      {
        mi_v_t
        h2 = (-h[2]) % n_real_2_;
        if (h2 < 0) h2 += n_real_2_;
        if (h2 < n_complex_2_) {
          mi_v_t h1 = (-h[1]) % n_1_;
          if (h1 < 0) h1 += n_1_;
          mi_v_t h0 = (-h[0]) % n_0_;
          if (h0 < 0) h0 += n_0_;
          begin_[(h0 * n_1_ + h1) * n_complex_2_ + h2] += cf;
        }
      }

      // Adds conj(cf) if +h is in the positive halfspace.
      // Adds      cf  if -h is in the positive halfspace.
      // Manually optimized for best performance.
      void
      plus_minus(miller::index<> const& h, complex_type const& cf)
      {
        mi_v_t
        h2 = h[2] % n_real_2_;
        if (h2 < 0) h2 += n_real_2_;
        if (h2 < n_complex_2_) {
          mi_v_t h1 = h[1] % n_1_;
          if (h1 < 0) h1 += n_1_;
          mi_v_t h0 = h[0] % n_0_;
          if (h0 < 0) h0 += n_0_;
          begin_[(h0 * n_1_ + h1) * n_complex_2_ + h2] += std::conj(cf);
        }
        h2 = (-h[2]) % n_real_2_;
        if (h2 < 0) h2 += n_real_2_;
        if (h2 < n_complex_2_) {
          mi_v_t h1 = (-h[1]) % n_1_;
          if (h1 < 0) h1 += n_1_;
          mi_v_t h0 = (-h[0]) % n_0_;
          if (h0 < 0) h0 += n_0_;
          begin_[(h0 * n_1_ + h1) * n_complex_2_ + h2] += cf;
        }
      }

    protected:
      complex_type* begin_;
      mi_v_t n_0_, n_1_, n_real_2_, n_complex_2_;
  };

  // Precomputes f~(hs) (Navaza & Vernoslova (1995), p.447, following Eq. (14))
  // ftil = f_calc(hr) * exp(2*pi*i*ht)
  template <typename FloatType>
  void set_ftilde(sgtbx::space_group const& space_group,
                  f_calc_map<FloatType> const& fc_map,
                  miller::index<> const& h,
                  miller::index<>* hs,
                  std::complex<FloatType>* fts)
  {
    for(std::size_t i=0;i<space_group.order_p();i++) {
      sgtbx::rt_mx s = space_group(i);
      hs[i] = h * s.r();
      fts[i] = fc_map(hs[i]) * std::polar(1.,
        2 * (h * s.t()) * scitbx::constants::pi / s.t().den());
    }
  }

  // lhs * conj(rhs)
  // With some compilers much faster than lhs * std::conj(rhs).
  template <typename T>
  inline
  std::complex<T>
  mul_conj(std::complex<T> const& lhs, std::complex<T> const& rhs)
  {
    return std::complex<T>(
      lhs.real() * rhs.real() + lhs.imag() * rhs.imag(),
      lhs.imag() * rhs.real() - lhs.real() * rhs.imag());
  }

  // Sum according to Eq. (15) of Navaza & Vernoslova (1995), p. 447.
  // Manually optimized for best performance.
  template <typename FloatType>
  void
  summation_eq15(
    sgtbx::space_group const& space_group,
    af::const_ref<miller::index<> > const& miller_indices,
    af::const_ref<FloatType> const& m,
    af::const_ref<std::complex<FloatType> > const& f_part,
    f_calc_map<FloatType> const& p1_f_calc,
    summation_accumulator<FloatType>& sum)
  {
    CCTBX_ASSERT(m.size() == miller_indices.size());
    CCTBX_ASSERT(   f_part.size() == 0
                 || f_part.size() == miller_indices.size());
    typedef miller::index<> mi_t;
    typedef std::complex<FloatType> cx_t;
    std::size_t order_p = space_group.order_p();
    FloatType n_ltr = static_cast<FloatType>(space_group.n_ltr());
    bool have_f_part = f_part.size();
    boost::scoped_array<mi_t> hs_buffer(new mi_t[order_p]);
    mi_t* hs = hs_buffer.get();
    boost::scoped_array<cx_t> fts_buffer(new cx_t[order_p]);
    cx_t* fts = fts_buffer.get();
    cx_t fpi(0);
    cx_t fpi_sq(0);
    cx_t two_fpi_sq_conj_fpi(0);
    cx_t four_conj_fpi_fpi(0);
    cx_t two_fpi(0);
    for (std::size_t ih = 0; ih < miller_indices.size(); ih++) {
      mi_t h = miller_indices[ih];
      FloatType mh = m[ih];
      set_ftilde(space_group, p1_f_calc, h, hs, fts);
      if (have_f_part) {
        fpi = f_part[ih] / n_ltr;
        fpi_sq = fpi * fpi;
        sum.plus_000(mh * std::norm(fpi_sq));
        two_fpi_sq_conj_fpi = 2. * fpi_sq * std::conj(fpi);
        four_conj_fpi_fpi = 4. * std::conj(fpi) * fpi;
        two_fpi = 2. * fpi;
      }
      for (std::size_t is0 = 0; is0 < order_p; is0++) {
        const mi_t& hm0 = hs[is0];
        cx_t mh_ftil0c = mh * std::conj(fts[is0]);
        if (have_f_part) {
          cx_t cf = mh_ftil0c * two_fpi_sq_conj_fpi;
          sum.plus_minus(hm0, cf);
        }
        for (std::size_t is1 = 0; is1 < order_p; is1++) {
          mi_t hm01(hm0 - hs[is1]);
          cx_t mh_ftil0c_ftil1(mh_ftil0c * fts[is1]);
          if (have_f_part) {
            cx_t cf = mh_ftil0c_ftil1 * four_conj_fpi_fpi;
            sum.minus(hm01, cf);
            mi_t hm0p1(hm0 + hs[is1]);
            cf = mul_conj(mh_ftil0c, fts[is1]) * fpi_sq;
            sum.plus_minus(hm0p1, cf);
          }
          for (std::size_t is2 = 0; is2 < order_p; is2++) {
            mi_t hm01p2(hm01 + hs[is2]);
            cx_t mh_ftil0c_ftil1_ftil2c(
              mul_conj(mh_ftil0c_ftil1, fts[is2]));
            if (have_f_part) {
              cx_t cf = mh_ftil0c_ftil1_ftil2c * two_fpi;
              sum.plus_minus(hm01p2, cf);
            }
            for (std::size_t is3 = 0; is3 < order_p; is3++) {
              mi_t hm01p23(hm01p2 - hs[is3]);
              cx_t cf = mh_ftil0c_ftil1_ftil2c * fts[is3];
              sum.minus(hm01p23, cf);
            }
          }
        }
      }
    }
  }

  // Sum according to Eq. (14) of Navaza & Vernoslova (1995), p. 447.
  template <typename FloatType>
  void
  summation_eq14(
    sgtbx::space_group const& space_group,
    af::const_ref<miller::index<> > const& miller_indices,
    af::const_ref<FloatType> const& m,
    af::const_ref<std::complex<FloatType> > const& f_part,
    f_calc_map<FloatType> const& p1_f_calc,
    summation_accumulator<FloatType>& sum)
  {
    CCTBX_ASSERT(m.size() == miller_indices.size());
    CCTBX_ASSERT(   f_part.size() == 0
                 || f_part.size() == miller_indices.size());
    typedef miller::index<> mi_t;
    typedef std::complex<FloatType> cx_t;
    std::size_t order_p = space_group.order_p();
    FloatType n_ltr = static_cast<FloatType>(space_group.n_ltr());
    bool have_f_part = f_part.size();
    boost::scoped_array<mi_t> hs_buffer(new mi_t[order_p]);
    mi_t* hs = hs_buffer.get();
    boost::scoped_array<cx_t> fts_buffer(new cx_t[order_p]);
    cx_t* fts = fts_buffer.get();
    cx_t fpi(0);
    for (std::size_t ih = 0; ih < miller_indices.size(); ih++) {
      mi_t h = miller_indices[ih];
      FloatType mh = m[ih];
      set_ftilde(space_group, p1_f_calc, h, hs, fts);
      if (have_f_part) {
        fpi = f_part[ih] / n_ltr;
        sum.plus_000(mh * std::norm(fpi));
      }
      for (std::size_t is0 = 0; is0 < order_p; is0++) {
        const mi_t& hm0 = hs[is0];
        cx_t mh_ftil0c = mh * std::conj(fts[is0]);
        if (have_f_part) {
          cx_t cf = mh_ftil0c * fpi;
          sum.plus_minus(hm0, cf);
        }
        for (std::size_t is1 = 0; is1 < order_p; is1++) {
          mi_t hm01(hm0 - hs[is1]);
          cx_t cf = mh_ftil0c * fts[is1];
          sum.minus(hm01, cf);
        }
      }
    }
  }

}}} // namespace cctbx::translation_search::fast_nv1995_detail

#endif // CCTBX_TRANSLATION_SEARCH_FAST_NV1995_SUMMATIONS_H
