#ifndef CCTBX_MATH_COS_SIN_TABLE_H
#define CCTBX_MATH_COS_SIN_TABLE_H

#include <cctbx/error.h>
#include <scitbx/constants.h>
#include <boost/shared_array.hpp>
#include <complex>

namespace cctbx { namespace math {

  template <typename FloatType=double>
  class cos_sin_exact
  {
    public:
      static
      std::complex<FloatType>
      get(FloatType const& unary_angle)
      {
        FloatType x = scitbx::constants::two_pi * unary_angle;
        return std::complex<FloatType>(std::cos(x), std::sin(x));
      }
  };

  template <typename FloatType=double>
  class cos_sin_table
  {
    public:
      cos_sin_table() {}

      cos_sin_table(int n_points)
      :
        n_points_(n_points),
        n_points_4_(n_points/4),
        values_memory_(new FloatType[n_points_+n_points_4_]),
        values_(values_memory_.get())
      {
        CCTBX_ASSERT(n_points % 4 == 0);
        using scitbx::constants::two_pi;
        for(int i=0;i<n_points_+n_points_4_;i++) {
          values_[i] = std::sin(i*two_pi/n_points_);
        }
      }

      int
      n_points() const { return n_points_; }

      std::complex<FloatType>
      get(FloatType const& unary_angle) const
      {
        int i = static_cast<int>(unary_angle*n_points_) % n_points_;
        if (i < 0) i += n_points_;
        return std::complex<FloatType>(values_[i+n_points_4_], values_[i]);
      }

    private:
      int n_points_;
      int n_points_4_;
      boost::shared_array<FloatType> values_memory_;
      FloatType* values_;
  };

  template <typename FloatType=double>
  class cos_sin_lin_interp_table
  {
    public:
      cos_sin_lin_interp_table() {}

      cos_sin_lin_interp_table(int n_points)
      :
        n_points_(n_points),
        n_points_4_(n_points/4),
        values_memory_(new FloatType[n_points_+n_points_4_+1]),
        values_(values_memory_.get()),
        diffvalues_memory_(new FloatType[n_points_+n_points_4_+1]),
        diffvalues_(diffvalues_memory_.get())
      {
        CCTBX_ASSERT(n_points % 4 == 0);
        using scitbx::constants::two_pi;
        for(int i=0;i<=n_points_+n_points_4_;i++)
        {
          values_[i] = std::sin(i*two_pi/n_points_);
          diffvalues_[i] = std::sin((i+1)*two_pi/n_points_)
                         - std::sin(i*two_pi/n_points_);
        }
      }

      int
      n_points() const { return n_points_; }

      std::complex<FloatType>
      get(FloatType const& unary_angle) const
      {
        FloatType dec = unary_angle*n_points_;
        if (dec<0.0)
        {
          dec = -dec;
          int i = static_cast<int>(dec); // floor it to an integer
          // get fraction between the ceiling and the floor of fval
          FloatType frac = dec - i;
          // return interpolated value between the i-th and the (i+1)th entry
          i = i % n_points_;

          return std::complex<FloatType>(
              values_[i+n_points_4_] + frac*diffvalues_[i+n_points_4_],
              - values_[i] -frac*diffvalues_[i]);
        }
        else
        {
          int i = static_cast<int>(dec); // floor it to an integer
          FloatType frac = dec - i;
          // return interpolated value between the i-th and the (i+1)th entry
          i = i % n_points_;

          return std::complex<FloatType>(
              values_[i+n_points_4_] + frac*diffvalues_[i+n_points_4_],
              values_[i] + frac*diffvalues_[i]);
        }
      }
    private:
      int n_points_;
      int n_points_4_;
      boost::shared_array<FloatType> values_memory_;
      FloatType* values_;
      boost::shared_array<FloatType> diffvalues_memory_;
      FloatType* diffvalues_;
  };


#if defined(__sgi) && !defined(__GNUC__)
  namespace work_around_edg_typename_handling {
    typedef cos_sin_exact<double> cos_sin_exact_double;
    typedef cos_sin_table<double> cos_sin_table_double;
    typedef cos_sin_lin_interp_table<double> cos_sin_lin_interp_table_double;
  }
#endif

}} // namespace cctbx::math

#endif // CCTBX_MATH_COS_SIN_TABLE_H
