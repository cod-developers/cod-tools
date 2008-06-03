#include <cctbx/boost_python/flex_fwd.h>

#include <cctbx/xray/fast_gradients.h>
#include <scitbx/boost_python/is_polymorphic_workaround.h>
#include <boost/python/class.hpp>
#include <boost/python/args.hpp>

SCITBX_BOOST_IS_POLYMORPHIC_WORKAROUND(cctbx::xray::fast_gradients<>)

namespace cctbx { namespace xray { namespace boost_python {

namespace {

  struct fast_gradients_wrappers
  {
    typedef fast_gradients<> w_t;

    static void
    wrap()
    {
      using namespace boost::python;
      class_<w_t, bases<w_t::base_t> >("fast_gradients", no_init)
        .def(init<uctbx::unit_cell const&,
                  af::const_ref<scatterer<> > const&,
                  scattering_type_registry const&,
                  optional<double const&,
                           double const&,
                           double const&,
                           double const&> >(
          (arg_("unit_cell"),
           arg_("scatterers"),
           arg_("scattering_type_registry"),
           arg_("u_base"),
           arg_("wing_cutoff"),
           arg_("exp_table_one_over_step_size"),
           arg_("tolerance_positive_definite"))))
        .def("sampling",
          (void(w_t::*)(
            af::const_ref<scatterer<> > const&,
            af::const_ref<double> const&,
            scattering_type_registry const&,
            sgtbx::site_symmetry_table const&,
            af::const_ref<double, w_t::accessor_type> const&,
            std::size_t,
            bool)) &w_t::sampling,
          (arg_("scatterers"),
           arg_("u_iso_refinable_params"),
           arg_("scattering_type_registry"),
           arg_("site_symmetry_table"),
           arg_("ft_d_target_d_f_calc"),
           arg_("n_parameters"),
           arg_("sampled_density_must_be_positive")))
        .def("sampling",
          (void(w_t::*)(
            af::const_ref<scatterer<> > const&,
            af::const_ref<double> const&,
            scattering_type_registry const&,
            sgtbx::site_symmetry_table const&,
            af::const_ref<std::complex<double>, w_t::accessor_type> const&,
            std::size_t,
            bool)) &w_t::sampling,
          (arg_("scatterers"),
           arg_("u_iso_refinable_params"),
           arg_("scattering_type_registry"),
           arg_("site_symmetry_table"),
           arg_("ft_d_target_d_f_calc"),
           arg_("n_parameters"),
           arg_("sampled_density_must_be_positive")))
        .def("packed", &w_t::packed)
        .def("d_target_d_site_cart", &w_t::d_target_d_site_cart)
        .def("d_target_d_u_iso", &w_t::d_target_d_u_iso)
        .def("d_target_d_u_cart", &w_t::d_target_d_u_cart)
        .def("d_target_d_occupancy", &w_t::d_target_d_occupancy)
        .def("d_target_d_fp", &w_t::d_target_d_fp)
        .def("d_target_d_fdp", &w_t::d_target_d_fdp)
      ;
    }
  };

} // namespace <anoymous>

  void wrap_fast_gradients()
  {
    fast_gradients_wrappers::wrap();
  }

}}} // namespace cctbx::xray::boost_python
