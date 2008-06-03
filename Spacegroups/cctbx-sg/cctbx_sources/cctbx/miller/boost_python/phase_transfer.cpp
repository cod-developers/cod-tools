#include <cctbx/boost_python/flex_fwd.h>

#include <cctbx/miller/phase_transfer.h>
#include <boost/python/def.hpp>

namespace cctbx { namespace miller { namespace boost_python {

  void wrap_phase_transfer()
  {
    using namespace boost::python;

    def("phase_transfer",
      (af::shared<std::complex<double> >(*)
        (sgtbx::space_group const&,
         af::const_ref<index<> > const&,
         af::const_ref<std::complex<double> > const&,
         af::const_ref<std::complex<double> > const&,
         double const&))
           phase_transfer);

    def("phase_transfer",
      (af::shared<std::complex<double> >(*)
        (sgtbx::space_group const&,
         af::const_ref<index<> > const&,
         af::const_ref<double> const&,
         af::const_ref<std::complex<double> > const&,
         double const&))
           phase_transfer);

    def("phase_transfer",
      (af::shared<std::complex<double> >(*)
        (sgtbx::space_group const&,
         af::const_ref<index<> > const&,
         af::const_ref<std::complex<double> > const&,
         af::const_ref<double> const&,
         bool))
           phase_transfer);

    def("phase_transfer",
      (af::shared<std::complex<double> >(*)
        (sgtbx::space_group const&,
         af::const_ref<index<> > const&,
         af::const_ref<double> const&,
         af::const_ref<double> const&,
         bool))
           phase_transfer);
  }

}}} // namespace cctbx::miller::boost_python
