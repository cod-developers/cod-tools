#include <cctbx/boost_python/flex_fwd.h>

#include <cctbx/dmtbx/triplet_generator.h>
#include <boost/python/class.hpp>

namespace cctbx { namespace dmtbx { namespace boost_python {
namespace {

  struct triplet_generator_wrappers
  {
    typedef triplet_generator<> w_t;

    static void
    wrap()
    {
      using namespace boost::python;
      class_<w_t>("triplet_generator", no_init)
        .def(init<sgtbx::space_group const&,
                  af::const_ref<miller::index<> > const&,
                  af::const_ref<double> const&,
                  std::size_t,
                  bool,
                  bool>())
        .def("t_den", &w_t::t_den)
        .def("max_relations_per_reflection",&w_t::max_relations_per_reflection)
        .def("sigma_2_only", &w_t::sigma_2_only)
        .def("discard_weights", &w_t::discard_weights)
        .def("n_relations", &w_t::n_relations)
        .def("relations_for", &w_t::relations_for)
        .def("sums_of_amplitude_products", &w_t::sums_of_amplitude_products)
        .def("raw_apply_tangent_formula", &w_t::apply_tangent_formula)
      ;
    }
  };

} // namespace <anonymous>

  void wrap_triplet_generator()
  {
    triplet_generator_wrappers::wrap();
  }

}}} // namespace cctbx::dmtbx::boost_python
