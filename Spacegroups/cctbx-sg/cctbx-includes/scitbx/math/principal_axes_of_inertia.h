#ifndef SCITBX_MATH_PRINCIPAL_AXES_OF_INERTIA_H
#define SCITBX_MATH_PRINCIPAL_AXES_OF_INERTIA_H

#include <scitbx/math/eigensystem.h>
#include <cstdio>

namespace scitbx { namespace math {

  namespace detail {

    inline
    std::string
    report_negative_weight(
      double weight,
      const char* where_file_name,
      long where_line_number)
    {
      char buf[256];
      std::sprintf(buf,
        "weight=%.6g is negative (must be >=0) (%s, line %ld)",
        weight, where_file_name, where_line_number);
      return std::string(buf);
    }

  } // namespace detail

  /*! Principal axes of inertia given discrete points in 3-dimensional
      space and optionally weights.
   */
  template <typename FloatType=double>
  class principal_axes_of_inertia
  {
    private:
      vec3<FloatType> center_of_mass_;
      sym_mat3<FloatType> inertia_tensor_;
      eigensystem::real_symmetric<FloatType> eigensystem_;

    public:
      //! Default constructor. Some data members are not initialized!
      principal_axes_of_inertia() {}

      //! Intitialization given discrete points with unit weights.
      principal_axes_of_inertia(
        af::const_ref<vec3<FloatType> > const& points)
      :
        center_of_mass_(0,0,0),
        inertia_tensor_(0,0,0,0,0,0)
      {
        if (points.size() != 0) {
          for(std::size_t i_p=0;i_p<points.size();i_p++) {
            center_of_mass_ += points[i_p];
          }
          center_of_mass_ /= static_cast<FloatType>(points.size());
          for(std::size_t i_p=0;i_p<points.size();i_p++) {
            vec3<FloatType> p = points[i_p] - center_of_mass_;
            vec3<FloatType> pp(p[0]*p[0], p[1]*p[1], p[2]*p[2]);
            inertia_tensor_(0,0) += pp[1] + pp[2];
            inertia_tensor_(1,1) += pp[0] + pp[2];
            inertia_tensor_(2,2) += pp[0] + pp[1];
            inertia_tensor_(0,1) -= p[0] * p[1];
            inertia_tensor_(0,2) -= p[0] * p[2];
            inertia_tensor_(1,2) -= p[1] * p[2];
          }
        }
        eigensystem_ = math::eigensystem::real_symmetric<FloatType>(
          inertia_tensor_);
      }

      //! Intitialization given discrete points and weights.
      principal_axes_of_inertia(
        af::const_ref<vec3<FloatType> > const& points,
        af::const_ref<FloatType> const& weights)
      :
        center_of_mass_(0,0,0),
        inertia_tensor_(0,0,0,0,0,0)
      {
        SCITBX_ASSERT(weights.size() == points.size());
        FloatType sum_weights = 0;
        for(std::size_t i_p=0;i_p<points.size();i_p++) {
          FloatType w = weights[i_p];
          if (w < 0) {
            throw std::runtime_error(detail::report_negative_weight(
              static_cast<double>(w), __FILE__, __LINE__));
          }
          center_of_mass_ += w * points[i_p];
          sum_weights += w;
        }
        if (sum_weights != 0) {
          center_of_mass_ /= sum_weights;
          for(std::size_t i_p=0;i_p<points.size();i_p++) {
            vec3<FloatType> p = points[i_p] - center_of_mass_;
            vec3<FloatType> pp(p[0]*p[0], p[1]*p[1], p[2]*p[2]);
            FloatType w = weights[i_p];
            inertia_tensor_(0,0) += w * (pp[1] + pp[2]);
            inertia_tensor_(1,1) += w * (pp[0] + pp[2]);
            inertia_tensor_(2,2) += w * (pp[0] + pp[1]);
            inertia_tensor_(0,1) -= w * p[0] * p[1];
            inertia_tensor_(0,2) -= w * p[0] * p[2];
            inertia_tensor_(1,2) -= w * p[1] * p[2];
          }
        }
        eigensystem_ = math::eigensystem::real_symmetric<FloatType>(
          inertia_tensor_);
      }

      //! Center of mass.
      /*! The weighted average of the coordinates of the points as passed
          to the constructor.
       */
      vec3<FloatType> const&
      center_of_mass() const { return center_of_mass_; }

      //! Real-symmetric 3x3 inertia tensor.
      /*! See e.g. http://kwon3d.com/theory/moi/iten.html or
          search for "inertia tensor" at http://www.google.com/
          or another search engine.
       */
      sym_mat3<FloatType> const&
      inertia_tensor() const { return inertia_tensor_; }

      //! Eigenvectors and eigenvalues of inertia_tensor().
      math::eigensystem::real_symmetric<FloatType> const&
      eigensystem() const { return eigensystem_; }

      //! Distance from center of inertia tensor ellipsoid to its surface.
      /*! unit_direction must be a vector of length 1. This is not checked
          to minimize the runtime overhead.
          If the inertia tensor is degenerate the result is 0.
       */
      FloatType
      distance_to_inertia_ellipsoid_surface(
        vec3<FloatType> const& unit_direction) const
      {
        FloatType d = inertia_tensor_.determinant();
        if (d == static_cast<FloatType>(0)) return 0;
        FloatType denom = (  inertia_tensor_.co_factor_matrix_transposed()
                           * unit_direction).length();
        if (denom == static_cast<FloatType>(0)) return 0;
        return d / denom;
      }
  };

  /*! Principal axes of inertia given discrete points in 2-dimensional
      space and optionally weights.
   */
  template <typename FloatType=double>
  class principal_axes_of_inertia_2d
  {
    private:
      vec2<FloatType> center_of_mass_;
      sym_mat2<FloatType> inertia_tensor_;
      eigensystem::real_symmetric<FloatType> eigensystem_;

    public:
      //! Default constructor. Some data members are not initialized!
      principal_axes_of_inertia_2d() {}

      //! Intitialization given discrete points with unit weights.
      principal_axes_of_inertia_2d(
        af::const_ref<vec2<FloatType> > const& points)
      :
        center_of_mass_(0,0),
        inertia_tensor_(0,0,0)
      {
        if (points.size() != 0) {
          for(std::size_t i_p=0;i_p<points.size();i_p++) {
            center_of_mass_ += points[i_p];
          }
          center_of_mass_ /= static_cast<FloatType>(points.size());
          for(std::size_t i_p=0;i_p<points.size();i_p++) {
            vec2<FloatType> p = points[i_p] - center_of_mass_;
            vec2<FloatType> pp(p[0]*p[0], p[1]*p[1]);
            inertia_tensor_(0,0) += pp[1];
            inertia_tensor_(1,1) += pp[0];
            inertia_tensor_(0,1) -= p[0] * p[1];
          }
        }
        eigensystem_ = math::eigensystem::real_symmetric<FloatType>(
          inertia_tensor_);
      }

      //! Intitialization given discrete points and weights.
      principal_axes_of_inertia_2d(
        af::const_ref<vec2<FloatType> > const& points,
        af::const_ref<FloatType> const& weights)
      :
        center_of_mass_(0,0),
        inertia_tensor_(0,0,0)
      {
        SCITBX_ASSERT(weights.size() == points.size());
        FloatType sum_weights = 0;
        for(std::size_t i_p=0;i_p<points.size();i_p++) {
          FloatType w = weights[i_p];
          if (w < 0) {
            throw std::runtime_error(detail::report_negative_weight(
              static_cast<double>(w), __FILE__, __LINE__));
          }
          center_of_mass_ += w * points[i_p];
          sum_weights += w;
        }
        if (sum_weights != 0) {
          center_of_mass_ /= sum_weights;
          for(std::size_t i_p=0;i_p<points.size();i_p++) {
            vec2<FloatType> p = points[i_p] - center_of_mass_;
            vec2<FloatType> pp(p[0]*p[0], p[1]*p[1]);
            FloatType w = weights[i_p];
            inertia_tensor_(0,0) += w * pp[1];
            inertia_tensor_(1,1) += w * pp[0];
            inertia_tensor_(0,1) -= w * p[0] * p[1];

          }
        }
        eigensystem_ = math::eigensystem::real_symmetric<FloatType>(
          inertia_tensor_);
      }

      //! Center of mass.
      /*! The weighted average of the coordinates of the points as passed
          to the constructor.
       */
      vec2<FloatType> const&
      center_of_mass() const { return center_of_mass_; }

      //! Real-symmetric 2x2 inertia tensor.
      /*! See e.g. http://kwon3d.com/theory/moi/iten.html or
          search for "inertia tensor" at http://www.google.com/
          or another search engine.
       */
      sym_mat2<FloatType> const&
      inertia_tensor() const { return inertia_tensor_; }

      //! Eigenvectors and eigenvalues of inertia_tensor().
      math::eigensystem::real_symmetric<FloatType> const&
      eigensystem() const { return eigensystem_; }

      //! Distance from center of inertia tensor ellipsoid to its surface.
      /*! unit_direction must be a vector of length 1. This is not checked
          to minimize the runtime overhead.
          If the inertia tensor is degenerate the result is 0.
       */
      FloatType
      distance_to_inertia_ellipsoid_surface(
        vec2<FloatType> const& unit_direction) const
      {
        FloatType d = inertia_tensor_.determinant();
        if (d == static_cast<FloatType>(0)) return 0;
        FloatType denom = (  inertia_tensor_.co_factor_matrix_transposed()
                           * unit_direction).length();
        if (denom == static_cast<FloatType>(0)) return 0;
        return d / denom;
      }
  };

}} // namespace scitbx::math

#endif // SCITBX_MATH_PRINCIPAL_AXES_OF_INERTIA_H
