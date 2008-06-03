#include <boost/python/class.hpp>
#include <boost/python/args.hpp>
#include <boost/python/overloads.hpp>
#include <boost/python/return_value_policy.hpp>
#include <boost/python/copy_const_reference.hpp>
#include <boost/python/return_internal_reference.hpp>
#include <boost/python/with_custodian_and_ward.hpp>
#include <cctbx/sgtbx/wyckoff.h>
#include <scitbx/boost_python/is_polymorphic_workaround.h>

SCITBX_BOOST_IS_POLYMORPHIC_WORKAROUND(cctbx::sgtbx::wyckoff::mapping)

namespace cctbx { namespace sgtbx { namespace boost_python {

namespace {

  struct wyckoff_position_wrappers
  {
    typedef wyckoff::position w_t;

    static void
    wrap()
    {
      using namespace boost::python;
      typedef return_value_policy<copy_const_reference> ccr;
      class_<w_t>("wyckoff_position", no_init)
        .def("multiplicity", &w_t::multiplicity)
        .def("letter", &w_t::letter)
        .def("special_op", &w_t::special_op, ccr())
        .def("point_group_type", &w_t::point_group_type)
        .def("unique_ops", &w_t::unique_ops, (arg_("space_group")))
      ;
    }
  };

  struct wyckoff_mapping_wrappers
  {
    typedef wyckoff::mapping w_t;

    static void
    wrap()
    {
      using namespace boost::python;
      typedef return_value_policy<copy_const_reference> ccr;
      typedef return_internal_reference<> rir;
      class_<w_t>("wyckoff_mapping", no_init)
        .def("unit_cell", &w_t::unit_cell, rir())
        .def("original_site", &w_t::original_site)
        .def("position", &w_t::position, rir())
        .def("sym_op", &w_t::sym_op, ccr())
        .def("representative_site", &w_t::representative_site)
        .def("exact_site", &w_t::exact_site)
        .def("distance_moved", &w_t::distance_moved)
        .def("special_op", &w_t::special_op)
      ;
    }
  };

  struct wyckoff_table_wrappers
  {
    typedef wyckoff::table w_t;

    BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(
      mapping_overloads, mapping, 2, 3)

    static void
    wrap()
    {
      using namespace boost::python;
      typedef return_value_policy<copy_const_reference> ccr;
      typedef return_internal_reference<> rir;
      class_<w_t>("wyckoff_table", no_init)
        .def(init<space_group_type const&>((arg_("space_group_type"))))
        .def("space_group_type", &w_t::space_group_type, rir())
        .def("size", &w_t::size)
        .def("position",
           (wyckoff::position const&(w_t::*)(std::size_t) const)
           &w_t::position, rir())
        .def("position",
           (wyckoff::position const&(w_t::*)(char) const)
           &w_t::position, (arg_("letter")), rir())
        .def("lookup_index", &w_t::lookup_index, (arg_("letter")))
        .def("mapping",
           (wyckoff::mapping(w_t::*)(site_symmetry const&) const)
           &w_t::mapping, (arg_("site_symmetry")),
           with_custodian_and_ward_postcall<0,1>())
        .def("mapping",
           (wyckoff::mapping(w_t::*)(
              uctbx::unit_cell const&,
              fractional<> const&,
              double) const) 0,
           mapping_overloads((
             arg_("unit_cell"),
             arg_("original_site"),
             arg_("special_position_radius")=0.5)
           )[with_custodian_and_ward_postcall<0,1>()])
      ;
    }
  };

} // namespace <anoymous>

  void wrap_wyckoff()
  {
    wyckoff_position_wrappers::wrap();
    wyckoff_mapping_wrappers::wrap();
    wyckoff_table_wrappers::wrap();
  }

}}} // namespace cctbx::sgtbx::boost_python
