#include <cctbx/boost_python/flex_fwd.h>

#include <boost/python/class.hpp>
#include <boost/python/args.hpp>
#include <boost/python/return_value_policy.hpp>
#include <boost/python/copy_const_reference.hpp>
#include <cctbx/geometry_restraints/nonbonded_sorted.h>

namespace cctbx { namespace geometry_restraints {
namespace {

  struct nonbonded_sorted_asu_proxies_base_wrappers
  {
    typedef nonbonded_sorted_asu_proxies_base w_t;

    static void
    wrap()
    {
      using namespace boost::python;
      typedef return_value_policy<copy_const_reference> ccr;
      class_<w_t>("nonbonded_sorted_asu_proxies_base", no_init)
        .def(init<
          boost::shared_ptr<asu_mappings> const&>(
            (arg_("asu_mappings"))))
        .def("asu_mappings", &w_t::asu_mappings, ccr())
        .def("process",
          (bool(w_t::*)(nonbonded_simple_proxy const&)) &w_t::process,
            (arg_("proxy")))
        .def("process",
          (void(w_t::*)(af::const_ref<nonbonded_simple_proxy> const&))
            &w_t::process,
          (arg_("proxies")))
        .def("process",
          (bool(w_t::*)(nonbonded_asu_proxy const&)) &w_t::process,
            (arg_("proxy")))
        .def("process",
          (void(w_t::*)(af::const_ref<nonbonded_asu_proxy> const&))
            &w_t::process,
          (arg_("proxies")))
        .def("n_total", &w_t::n_total)
        .def_readonly("simple", &w_t::simple)
        .def_readonly("asu", &w_t::asu)
      ;
    }
  };

  struct nonbonded_sorted_asu_proxies_wrappers
  {
    typedef nonbonded_sorted_asu_proxies w_t;

    static void
    wrap()
    {
      using namespace boost::python;
      class_<w_t, bases<nonbonded_sorted_asu_proxies_base> >(
        "nonbonded_sorted_asu_proxies", no_init)
        .def(init<
          boost::shared_ptr<asu_mappings> const&>(
            (arg_("asu_mappings"))))
        .def(init<
          af::const_ref<std::size_t> const&,
          af::const_ref<std::size_t> const&,
          nonbonded_params const&,
          af::const_ref<std::string> const&,
          double,
          std::vector<crystal::pair_asu_table<> > const&>((
            arg_("model_indices"),
            arg_("conformer_indices"),
            arg_("nonbonded_params"),
            arg_("nonbonded_types"),
            arg_("nonbonded_distance_cutoff_plus_buffer"),
            arg_("shell_asu_tables"))))
        .def_readonly("n_1_3", &w_t::n_1_3)
        .def_readonly("n_1_4", &w_t::n_1_4)
        .def_readonly("n_nonbonded", &w_t::n_nonbonded)
        .def_readonly("n_unknown_nonbonded_type_pairs",
          &w_t::n_unknown_nonbonded_type_pairs)
        .def_readonly("min_vdw_distance", &w_t::min_vdw_distance)
        .def_readonly("max_vdw_distance", &w_t::max_vdw_distance)
      ;
    }
  };

  void
  wrap_all()
  {
    nonbonded_sorted_asu_proxies_base_wrappers::wrap();
    nonbonded_sorted_asu_proxies_wrappers::wrap();
  }

} // namespace <anonymous>

namespace boost_python {

  void
  wrap_nonbonded_sorted() { wrap_all(); }

}}} // namespace cctbx::geometry_restraints::boost_python
