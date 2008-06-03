#ifndef CCTBX_GEOMETRY_RESTRAINTS_PLANARITY_H
#define CCTBX_GEOMETRY_RESTRAINTS_PLANARITY_H

#include <cctbx/geometry_restraints/utils.h>
#include <scitbx/math/eigensystem.h>
#include <scitbx/array_family/sort.h>
#include <scitbx/sym_mat3.h>

namespace cctbx { namespace geometry_restraints {

  //! Grouping of indices into array of sites (i_seqs) and weights.
  struct planarity_proxy
  {
    //! Support for shared_proxy_select.
    typedef af::shared<std::size_t> i_seqs_type;

    //! Default constructor. Some data members are not initialized!
    planarity_proxy() {}

    //! Constructor.
    planarity_proxy(
      i_seqs_type const& i_seqs_,
      af::shared<double> const& weights_)
    :
      i_seqs(i_seqs_),
      weights(weights_)
    {
      CCTBX_ASSERT(weights.size() == i_seqs.size());
    }

    //! Constructor.
    planarity_proxy(
      i_seqs_type const& i_seqs_,
      planarity_proxy const& other)
    :
      i_seqs(i_seqs_),
      weights(other.weights.begin(), other.weights.end())
    {
      CCTBX_ASSERT(weights.size() == i_seqs.size());
    }

    //! Sorts i_seqs such that i_seq[0] < i_seq[2].
    planarity_proxy
    sort_i_seqs() const
    {
      af::const_ref<std::size_t> i_seqs_cr = i_seqs.const_ref();
      af::const_ref<double> weights_cr = weights.const_ref();
      CCTBX_ASSERT(i_seqs_cr.size() == weights_cr.size());
      planarity_proxy result;
      result.i_seqs.reserve(i_seqs_cr.size());
      result.weights.reserve(i_seqs_cr.size());
      i_seqs_type perm = af::sort_permutation(i_seqs_cr);
      af::const_ref<std::size_t> perm_cr = perm.const_ref();
      for(std::size_t i=0;i<perm_cr.size();i++) {
        result.i_seqs.push_back(i_seqs_cr[perm_cr[i]]);
      }
      for(std::size_t i=0;i<perm_cr.size();i++) {
        result.weights.push_back(weights_cr[perm_cr[i]]);
      }
      return result;
    }

    //! Indices into array of sites.
    i_seqs_type i_seqs;
    //! Array of weights.
    af::shared<double> weights;
  };

  //! Residual and gradient calculations for planarity restraint.
  /*! See also:

        Hendrickson, W.A. (1985). Meth. Enzym. 115, 252-270.

        Urzhumtsev, A.G. (1991). Acta Cryst. A47, 723-727.

        Blanc, E. & Paciorek, W. (2001). J. Appl. Cryst. 34, 480-483.

      This implementation uses the procedure of Blanc & Paciorek.
      The results are identical to those produced by Urzhumtsev's
      procedure.
   */
  class planarity
  {
    public:
      //! Default constructor. Some data members are not initialized!
      planarity() {}

      //! Constructor.
      planarity(
        af::shared<scitbx::vec3<double> > const& sites_,
        af::shared<double> const& weights_)
      :
        sites(sites_),
        weights(weights_)
      {
        init_deltas();
      }

      /*! \brief Coordinates are copied from sites_cart according to
          proxy.i_seqs, weights are copied from proxy.
       */
      planarity(
        af::const_ref<scitbx::vec3<double> > const& sites_cart,
        planarity_proxy const& proxy)
      :
        weights(proxy.weights)
      {
        af::const_ref<std::size_t> i_seqs_ref = proxy.i_seqs.const_ref();
        sites.reserve(i_seqs_ref.size());
        for(std::size_t i=0;i<i_seqs_ref.size();i++) {
          std::size_t i_seq = i_seqs_ref[i];
          CCTBX_ASSERT(i_seq < sites_cart.size());
          sites.push_back(sites_cart[i_seq]);
        }
        init_deltas();
      }

      //! Cartesian coordinates of the sites defining the plane.
      af::shared<scitbx::vec3<double> > sites;
      //! Array of weights for each site.
      af::shared<double> weights;

      //! Array of distances from plane for each site.
      af::shared<double> const&
      deltas() const { return deltas_; }

      //! sqrt(mean_sq(deltas))
      double
      rms_deltas() const { return std::sqrt(af::mean_sq(deltas_.const_ref())); }

      //! Sum of weight * delta**2 over all sites.
      double
      residual() const
      {
        double result = 0;
        af::const_ref<double> weights_ref = weights.const_ref();
        af::const_ref<double> deltas_ref = deltas_.const_ref();
        for(std::size_t i_site=0;i_site<deltas_ref.size();i_site++) {
          result += weights_ref[i_site]
                  * scitbx::fn::pow2(deltas_ref[i_site]);
        }
        return result;
      }

      //! Gradients with respect to the sites.
      af::shared<scitbx::vec3<double> >
      gradients() const
      {
        af::shared<scitbx::vec3<double> > result;
        af::const_ref<double> weights_ref = weights.const_ref();
        af::const_ref<double> deltas_ref = deltas_.const_ref();
        result.reserve(deltas_ref.size());
        scitbx::vec3<double> n_min = normal();
        for(std::size_t i_site=0;i_site<deltas_ref.size();i_site++) {
          result.push_back(
            n_min * (2 * weights_ref[i_site] * deltas_ref[i_site]));
        }
        return result;
      }

      //! Support for planarity_residual_sum.
      /*! Not available in Python.
       */
      void
      add_gradients(
        af::ref<scitbx::vec3<double> > const& gradient_array,
        planarity_proxy::i_seqs_type const& i_seqs) const
      {
        af::const_ref<std::size_t> i_seqs_ref = i_seqs.const_ref();
        af::shared<scitbx::vec3<double> > grads = gradients();
        af::const_ref<scitbx::vec3<double> > grads_ref = grads.const_ref();
        for(std::size_t i=0;i<grads_ref.size();i++) {
          gradient_array[i_seqs_ref[i]] += grads_ref[i];
        }
      }

      /*! The plane normal is identical to the eigenvector corresponding
          to the smallest eigenvalue of the residual_tensor().
       */
      scitbx::vec3<double>
      normal() const
      {
        return scitbx::vec3<double>(eigensystem_.vectors().begin()+2*3);
      }

      /*! Smallest eigenvalue of the residual_tensor().
       */
      double
      lambda_min() const { return eigensystem_.values()[2]; }

      //! Center of mass.
      /*! The weighted average of the coordinates of the sites as passed
          to the constructor.
       */
      scitbx::vec3<double> const&
      center_of_mass() const { return center_of_mass_; }

      //! Real-symmetric 3x3 residual tensor.
      /*! Blanc, E. & Paciorek, W. (2001). J. Appl. Cryst. 34, 480-483.
       */
      scitbx::sym_mat3<double> const&
      residual_tensor() const { return residual_tensor_; }

      //! Eigenvectors and eigenvalues of residual_tensor().
      scitbx::math::eigensystem::real_symmetric<double> const&
      eigensystem() const { return eigensystem_; }

    protected:
      scitbx::vec3<double> center_of_mass_;
      scitbx::sym_mat3<double> residual_tensor_;
      scitbx::math::eigensystem::real_symmetric<double> eigensystem_;
      af::shared<double> deltas_;

      void
      init_deltas()
      {
        CCTBX_ASSERT(weights.size() == sites.size());
        af::const_ref<scitbx::vec3<double> > sites_ref = sites.const_ref();
        af::const_ref<double> weights_ref = weights.const_ref();
        center_of_mass_.fill(0);
        double sum_weights = 0;
        for(std::size_t i_site=0;i_site<sites_ref.size();i_site++) {
          double w = weights_ref[i_site];
          center_of_mass_ += w * sites_ref[i_site];
          sum_weights += w;
        }
        CCTBX_ASSERT(sum_weights > 0);
        center_of_mass_ /= sum_weights;
        residual_tensor_.fill(0);
        for(std::size_t i_site=0;i_site<sites_ref.size();i_site++) {
          double w = weights_ref[i_site];
          scitbx::vec3<double> x = sites_ref[i_site] - center_of_mass_;
          residual_tensor_(0,0) += w*x[0]*x[0];
          residual_tensor_(1,1) += w*x[1]*x[1];
          residual_tensor_(2,2) += w*x[2]*x[2];
          residual_tensor_(0,1) += w*x[0]*x[1];
          residual_tensor_(0,2) += w*x[0]*x[2];
          residual_tensor_(1,2) += w*x[1]*x[2];
        }
        eigensystem_ = scitbx::math::eigensystem::real_symmetric<double>(
          residual_tensor_);
        scitbx::vec3<double> n_min = normal();
        deltas_.reserve(sites_ref.size());
        for(std::size_t i_site=0;i_site<sites_ref.size();i_site++) {
          deltas_.push_back(n_min * (sites_ref[i_site] - center_of_mass_));
        }
      }
  };

  /*! \brief Fast computation of planarity::rms_deltas() given an array
      of planarity proxies.
   */
  inline
  af::shared<double>
  planarity_deltas_rms(
    af::const_ref<scitbx::vec3<double> > const& sites_cart,
    af::const_ref<planarity_proxy> const& proxies)
  {
    af::shared<double> result((af::reserve(proxies.size())));
    for(std::size_t i=0;i<proxies.size();i++) {
      result.push_back(planarity(sites_cart, proxies[i]).rms_deltas());
    }
    return result;
  }

  /*! \brief Fast computation of planarity::residual() given an array
      of planarity proxies.
   */
  inline
  af::shared<double>
  planarity_residuals(
    af::const_ref<scitbx::vec3<double> > const& sites_cart,
    af::const_ref<planarity_proxy> const& proxies)
  {
    return detail::generic_residuals<planarity_proxy, planarity>::get(
      sites_cart, proxies);
  }

  /*! Fast computation of sum of planarity::residual() and gradients
      given an array of planarity proxies.
   */
  /*! The planarity::gradients() are added to the gradient_array if
      gradient_array.size() == sites_cart.size().
      gradient_array must be initialized before this function
      is called.
      No gradient calculations are performed if gradient_array.size() == 0.
   */
  inline
  double
  planarity_residual_sum(
    af::const_ref<scitbx::vec3<double> > const& sites_cart,
    af::const_ref<planarity_proxy> const& proxies,
    af::ref<scitbx::vec3<double> > const& gradient_array)
  {
    return detail::generic_residual_sum<planarity_proxy, planarity>::get(
      sites_cart, proxies, gradient_array);
  }

}} // namespace cctbx::geometry_restraints

#endif // CCTBX_GEOMETRY_RESTRAINTS_PLANARITY_H
