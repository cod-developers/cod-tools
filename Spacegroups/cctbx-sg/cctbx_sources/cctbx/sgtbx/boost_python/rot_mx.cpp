#include <boost/python/class.hpp>
#include <boost/python/overloads.hpp>
#include <boost/python/args.hpp>
#include <boost/python/return_value_policy.hpp>
#include <boost/python/copy_const_reference.hpp>
#include <cctbx/sgtbx/rot_mx_info.h>

namespace cctbx { namespace sgtbx { namespace boost_python {

namespace {

  struct rot_mx_wrappers
  {
    typedef rot_mx w_t;

    BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(
      order_overloads, order, 0, 1)
    BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(
      accumulate_overloads, accumulate, 0, 1)
    BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(
      as_xyz_overloads, as_xyz, 0, 3)
    BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(
      as_hkl_overloads, as_hkl, 0, 3)

    static
    scitbx::vec3<double>
    rmul_vec3_double(
      w_t const& rhs,
      scitbx::vec3<double> const& lhs)
    {
      return lhs * rhs;
    }

    static void
    wrap()
    {
      using namespace boost::python;
      typedef return_value_policy<copy_const_reference> ccr;
      class_<w_t>("rot_mx", no_init)
        .def(init<optional<int, int> >((
          arg_("denominator")=1,
          arg_("diagonal")=1)))
        .def(init<sg_mat3 const&, optional<int> >((
          arg_("m")=1,
          arg_("denominator")=1)))
        .def("num", (sg_mat3 const&(w_t::*)() const) &w_t::num, ccr())
        .def("den", (int const&(w_t::*)() const) &w_t::den, ccr())
        .def("__eq__", &w_t::operator==)
        .def("__ne__", &w_t::operator!=)
        .def("is_valid", &w_t::is_valid)
        .def("is_unit_mx", &w_t::is_unit_mx)
        .def("minus_unit_mx", &w_t::minus_unit_mx)
        .def("new_denominator", &w_t::new_denominator, (arg_("new_den")))
        .def("scale", &w_t::scale, (arg_("factor")))
        .def("determinant", &w_t::determinant)
        .def("transpose", &w_t::transpose)
        .def("inverse", &w_t::inverse)
        .def("cancel", &w_t::cancel)
        .def("inverse_cancel", &w_t::inverse_cancel)
        .def("multiply",
          (rot_mx (w_t::*)(rot_mx const&) const) &w_t::multiply, (
            arg_("rhs")))
        .def("multiply",
          (tr_vec (w_t::*)(tr_vec const&) const) &w_t::multiply, (
            arg_("rhs")))
        .def("divide", &w_t::divide, (arg_("rhs")))
        .def("type", &w_t::type)
        .def("order", &w_t::order, order_overloads())
        .def("accumulate", &w_t::accumulate, accumulate_overloads((
          arg_("type")=0)))
        .def("info", &w_t::info)
        .def("as_double", &w_t::as_double)
        .def("as_xyz", &w_t::as_xyz, as_xyz_overloads((
           arg_("decimal")=false,
           arg_("symbol_letters")="xyz",
           arg_("separator")=",")))
        .def("as_hkl", &w_t::as_hkl, as_hkl_overloads((
           arg_("decimal")=false,
           arg_("letters_hkl")="hkl",
           arg_("separator")=",")))
        .def("__mul__",
          (scitbx::vec3<double>(*)(
            rot_mx const&, scitbx::vec3<double> const&)) operator*)
        .def("__rmul__", rmul_vec3_double)
      ;
    }
  };

  struct rot_mx_info_wrappers
  {
    typedef rot_mx_info w_t;

    static void
    wrap()
    {
      using namespace boost::python;
      typedef return_value_policy<copy_const_reference> ccr;
      class_<w_t>("rot_mx_info", no_init)
        .def(init<rot_mx const&>())
        .def("type", &w_t::type)
        .def("ev", &w_t::ev, ccr())
        .def("sense", &w_t::sense)
      ;
    }
  };

} // namespace <anoymous>

  void wrap_rot_mx()
  {
    rot_mx_wrappers::wrap();
    rot_mx_info_wrappers::wrap();
  }

}}} // namespace cctbx::sgtbx::boost_python
