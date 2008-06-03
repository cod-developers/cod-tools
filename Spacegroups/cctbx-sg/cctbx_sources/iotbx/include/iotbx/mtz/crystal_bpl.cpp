#include <cctbx/boost_python/flex_fwd.h>

#include <boost/python/class.hpp>
#include <boost/python/args.hpp>
#include <boost/python/return_arg.hpp>
#include <iotbx/mtz/dataset.h>
#include <scitbx/array_family/boost_python/shared_wrapper.h>

namespace iotbx { namespace mtz {
namespace {

  struct crystal_wrappers
  {
    typedef crystal w_t;

    static void
    wrap()
    {
      using namespace boost::python;
      class_<w_t>("crystal", no_init)
        .def(init<object const&, int>((arg_("mtz_object"), arg_("i_crystal"))))
        .def("mtz_object", &w_t::mtz_object)
        .def("i_crystal", &w_t::i_crystal)
        .def("id", &w_t::id)
        .def("set_id", &w_t::set_id, (arg_("id")), return_self<>())
        .def("name", &w_t::name)
        .def("set_name", &w_t::set_name, (arg_("new_name")), return_self<>())
        .def("project_name", &w_t::project_name)
        .def("set_project_name", &w_t::set_project_name, (
          arg_("new_project_name")), return_self<>())
        .def("unit_cell_parameters", &w_t::unit_cell_parameters)
        .def("unit_cell", &w_t::unit_cell)
        .def("set_unit_cell_parameters", &w_t::set_unit_cell_parameters, (
          arg_("parameters")), return_self<>())
        .def("n_datasets", &w_t::n_datasets)
        .def("datasets", &w_t::datasets)
        .def("add_dataset", &w_t::add_dataset, (
          arg_("name"), arg_("wavelength")))
        .def("has_dataset", &w_t::has_dataset, (arg_("name")))
      ;
      {
        scitbx::af::boost_python::shared_wrapper<w_t>::wrap(
          "shared_crystal");
      }
    }
  };

  void
  wrap_all()
  {
    crystal_wrappers::wrap();
  }

} // namespace <anonymous>

namespace boost_python {

  void
  wrap_crystal() { wrap_all(); }

}}} // namespace iotbx::mtz::boost_python
