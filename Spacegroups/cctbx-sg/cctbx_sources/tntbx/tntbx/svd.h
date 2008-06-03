#ifndef TNTBX_SVD_H
#define TNTBX_SVD_H

#include <tntbx/import_scitbx_af.h>
#include <scitbx/array_family/versa.h>
#include <scitbx/array_family/shared.h>
#include <scitbx/array_family/accessors/c_grid.h>
#include <jama_svd.h>

namespace tntbx {

  template <typename FloatType>
  class svd_m_ge_n
  {
    protected:
      int n_rows_;
      int n_columns_;
      mutable JAMA::SVD<FloatType> jama_svd_;

    public:
      svd_m_ge_n(af::const_ref<FloatType, af::c_grid<2> > const& m)
      :
        n_rows_(m.accessor()[0]),
        n_columns_(m.accessor()[1]),
        jama_svd_(TNT::Array2D<double>(
          n_rows_, n_columns_, const_cast<FloatType*>(m.begin())))
      {
        if (n_rows_ == 0) {
          throw std::runtime_error("number of rows must be > 0");
        }
        if (n_columns_ == 0) {
          throw std::runtime_error("number of columns must be > 0");
        }
        if (n_rows_ < n_columns_) {
          throw std::runtime_error(
            "number of rows must be >= number of columns");
        }
      }

      af::shared<FloatType>
      singular_values() const
      {
        TNT::Array1D<FloatType> x;
        jama_svd_.getSingularValues(x);
        return af::shared<FloatType>(&x[0], &x[x.dim()]);
      }

      af::versa<FloatType, af::c_grid<2> >
      s() const { return get_s_u_v(0); }

      af::versa<FloatType, af::c_grid<2> >
      u() const { return get_s_u_v(1); }

      af::versa<FloatType, af::c_grid<2> >
      v() const { return get_s_u_v(2); }

      FloatType
      norm2() const { return jama_svd_.norm2(); }

      boost::optional<FloatType>
      cond() const
      {
        TNT::Array1D<FloatType> s;
        jama_svd_.getSingularValues(s);
        FloatType min_s = s[std::min(n_rows_,n_columns_)-1];
        if (min_s == 0) return boost::optional<FloatType>();
        return boost::optional<FloatType>(s[0] / min_s);
      }

      int
      rank() const { return jama_svd_.rank(); }

    protected:
      af::versa<FloatType, af::c_grid<2> >
      get_s_u_v(int which) const
      {
        Array2D<FloatType> x;
        if      (which == 0) jama_svd_.getS(x);
        else if (which == 1) jama_svd_.getU(x);
        else                 jama_svd_.getV(x);
        af::versa<FloatType, af::c_grid<2> > result(
          af::c_grid<2>(x.dim1(), x.dim2()),
          af::init_functor_null<FloatType>());
        std::copy(&x[0][0], &x[x.dim1()-1][x.dim2()], result.begin());
        return result;
      }
  };

} // namespace tntbx

#endif // TNTBX_SVD_H
