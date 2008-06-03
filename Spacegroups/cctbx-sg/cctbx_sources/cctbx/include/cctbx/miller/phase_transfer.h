#ifndef CCTBX_MILLER_PHASE_TRANSFER_H
#define CCTBX_MILLER_PHASE_TRANSFER_H

#include <cctbx/sgtbx/space_group.h>

namespace cctbx { namespace miller {

#if defined(BOOST_MSVC) && BOOST_MSVC <= 1300 // VC++ 7.0
  namespace {
    inline double
    abs_wrapper(double const& x) { return scitbx::fn::absolute(x); }

    inline double
    abs_wrapper(std::complex<double> const& x) { return std::abs(x); }
  }
#endif

  template <typename AmplitudeType,
            typename FloatType>
  af::shared<std::complex<FloatType> >
  phase_transfer(
    sgtbx::space_group const& space_group,
    af::const_ref<index<> > const& miller_indices,
    af::const_ref<AmplitudeType> const& amplitude_source,
    af::const_ref<std::complex<FloatType> > const& phase_source,
    FloatType const& epsilon=1.e-10)
  {
    CCTBX_ASSERT(amplitude_source.size() == miller_indices.size());
    CCTBX_ASSERT(phase_source.size() == miller_indices.size());
    af::shared<std::complex<FloatType> >
      result(af::reserve(miller_indices.size()));
    for(std::size_t i=0;i<miller_indices.size();i++) {
      std::complex<FloatType> p = phase_source[i];
      if (   scitbx::fn::absolute(p.real()) < epsilon
          && scitbx::fn::absolute(p.imag()) < epsilon) {
        result.push_back(0); // no phase information
      }
      else {
        result.push_back(std::polar(
#if defined(BOOST_MSVC) && BOOST_MSVC <= 1300 // VC++ 7.0
          FloatType(abs_wrapper(amplitude_source[i])),
#else
          FloatType(std::abs(amplitude_source[i])),
#endif
          space_group.phase_restriction(miller_indices[i])
            .nearest_valid_phase(std::arg(p))));
      }
    }
    return result;
  }

  template <typename AmplitudeType,
            typename FloatType>
  af::shared<std::complex<FloatType> >
  phase_transfer(
    sgtbx::space_group const& space_group,
    af::const_ref<index<> > const& miller_indices,
    af::const_ref<AmplitudeType> const& amplitude_source,
    af::const_ref<FloatType> const& phase_source,
    bool deg=false)
  {
    CCTBX_ASSERT(amplitude_source.size() == miller_indices.size());
    CCTBX_ASSERT(phase_source.size() == miller_indices.size());
    af::shared<std::complex<FloatType> >
      result(af::reserve(miller_indices.size()));
    for(std::size_t i=0;i<miller_indices.size();i++) {
      FloatType p = phase_source[i];
      if (deg) p *= scitbx::constants::pi_180;
      result.push_back(std::polar(
#if defined(BOOST_MSVC) && BOOST_MSVC <= 1300 // VC++ 7.0
        FloatType(abs_wrapper(amplitude_source[i])),
#else
        FloatType(std::abs(amplitude_source[i])),
#endif
        space_group.phase_restriction(miller_indices[i])
          .nearest_valid_phase(p)));
    }
    return result;
  }

}} // namespace cctbx::miller

#endif // CCTBX_MILLER_PHASE_TRANSFER_H
