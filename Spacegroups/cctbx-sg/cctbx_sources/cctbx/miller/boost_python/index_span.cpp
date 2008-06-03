#include <cctbx/boost_python/flex_fwd.h>

#include <cctbx/miller/index_span.h>
#include <boost/python/class.hpp>

namespace cctbx { namespace miller { namespace boost_python {

namespace {

  struct index_span_wrappers
  {
    typedef index_span w_t;

    static void
    wrap()
    {
      using namespace boost::python;
      class_<w_t>("index_span", no_init)
        .def(init<af::const_ref<index<> > const&>())
        .def("min", &w_t::min)
        .def("max", &w_t::max)
        .def("abs_range", &w_t::abs_range)
        .def("map_grid", &w_t::map_grid)
        .def("is_in_domain", &w_t::is_in_domain)
        .def("pack",
          (af::shared<std::size_t>(w_t::*)
           (af::const_ref<index<> > const& miller_indices) const) &w_t::pack)
      ;
    }
  };

} // namespace <anoymous>

  void wrap_index_span()
  {
    index_span_wrappers::wrap();
  }

}}} // namespace cctbx::miller::boost_python
