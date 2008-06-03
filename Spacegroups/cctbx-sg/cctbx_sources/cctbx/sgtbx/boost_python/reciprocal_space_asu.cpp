#include <boost/python/class.hpp>
#include <boost/python/args.hpp>
#include <boost/python/return_internal_reference.hpp>
#include <cctbx/sgtbx/reciprocal_space_asu.h>

namespace cctbx { namespace sgtbx { namespace boost_python {

namespace {

  struct reciprocal_space_asu_wrappers
  {
    typedef reciprocal_space::asu w_t;

    static void
    wrap()
    {
      using namespace boost::python;
      typedef return_internal_reference<> rir;
      class_<w_t>("reciprocal_space_asu", no_init)
        .def(init<space_group_type const&>((arg_("space_group_type"))))
        .def("cb_op", &w_t::cb_op, rir())
        .def("is_reference", &w_t::is_reference)
        .def("reference_as_string", &w_t::reference_as_string)
        .def("is_inside", &w_t::is_inside, (arg_("miller_index")))
        .def("which",
          (int(w_t::*)(miller::index<> const&) const) &w_t::which, (
            arg_("miller_index")))
      ;
    }
  };

} // namespace <anoymous>

  void wrap_reciprocal_space_asu()
  {
    reciprocal_space_asu_wrappers::wrap();
  }

}}} // namespace cctbx::sgtbx::boost_python
