#include <cctbx/boost_python/flex_fwd.h>

#include <boost/python/def.hpp>
#include <boost/python/class.hpp>
#include <boost/python/args.hpp>
#include <boost/python/overloads.hpp>
#include <boost/python/return_value_policy.hpp>
#include <boost/python/copy_const_reference.hpp>
#include <boost/python/return_internal_reference.hpp>
#include <boost/python/return_by_value.hpp>
#include <scitbx/array_family/boost_python/shared_wrapper.h>
#include <cctbx/geometry_restraints/dihedral.h>
#include <cctbx/geometry_restraints/proxy_select.h>

namespace cctbx { namespace geometry_restraints {
namespace {

  struct dihedral_proxy_wrappers
  {
    typedef dihedral_proxy w_t;

    static void
    wrap()
    {
      using namespace boost::python;
      typedef return_value_policy<return_by_value> rbv;
      class_<w_t>("dihedral_proxy", no_init)
        .def(init<af::tiny<unsigned, 4> const&, double, double,
                  optional<int> >(
          (arg_("i_seqs"), arg_("angle_ideal"), arg_("weight"),
           arg_("periodicity")=0)))
        .def("sort_i_seqs", &w_t::sort_i_seqs)
        .add_property("i_seqs", make_getter(&w_t::i_seqs, rbv()))
        .def_readwrite("angle_ideal", &w_t::angle_ideal)
        .def_readwrite("weight", &w_t::weight)
        .def_readwrite("periodicity", &w_t::periodicity)
      ;
      {
        typedef return_internal_reference<> rir;
        scitbx::af::boost_python::shared_wrapper<w_t, rir>::wrap(
          "shared_dihedral_proxy")
          .def("proxy_select",
            (af::shared<w_t>(*)(
              af::const_ref<w_t> const&,
              std::size_t,
              af::const_ref<std::size_t> const&))
                shared_proxy_select, (
            arg_("n_seq"), arg_("iselection")))
          .def("proxy_remove",
            (af::shared<w_t>(*)(
              af::const_ref<w_t> const&,
              af::const_ref<bool> const&))
                shared_proxy_remove, (
            arg_("selection")))
        ;
      }
    }
  };

  struct dihedral_wrappers
  {
    typedef dihedral w_t;

    BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(
      gradients_overloads, gradients, 0, 1)

    static void
    wrap()
    {
      using namespace boost::python;
      typedef return_value_policy<return_by_value> rbv;
      class_<w_t>("dihedral", no_init)
        .def(init<af::tiny<scitbx::vec3<double>, 4> const&, double, double,
                  optional<int> >(
          (arg_("sites"), arg_("angle_ideal"), arg_("weight"),
           arg_("periodicity")=0)))
        .def(init<af::const_ref<scitbx::vec3<double> > const&,
                  dihedral_proxy const&>(
          (arg_("sites_cart"), arg_("proxy"))))
        .add_property("sites", make_getter(&w_t::sites, rbv()))
        .def_readonly("angle_ideal", &w_t::angle_ideal)
        .def_readonly("weight", &w_t::weight)
        .def_readonly("periodicity", &w_t::periodicity)
        .def_readonly("have_angle_model", &w_t::have_angle_model)
        .def_readonly("angle_model", &w_t::angle_model)
        .def_readonly("delta", &w_t::delta)
        .def("residual", &w_t::residual)
        .def("gradients", &w_t::gradients, gradients_overloads(
          (arg_("epsilon"))))
      ;
    }
  };

  void
  wrap_all()
  {
    using namespace boost::python;
    dihedral_proxy_wrappers::wrap();
    dihedral_wrappers::wrap();
    def("dihedral_deltas", dihedral_deltas,
      (arg_("sites_cart"), arg_("proxies")));
    def("dihedral_residuals", dihedral_residuals,
      (arg_("sites_cart"), arg_("proxies")));
    def("dihedral_residual_sum", dihedral_residual_sum,
      (arg_("sites_cart"), arg_("proxies"), arg_("gradient_array")));
  }

} // namespace <anonymous>

namespace boost_python {

  void
  wrap_dihedral() { wrap_all(); }

}}} // namespace cctbx::geometry_restraints::boost_python
