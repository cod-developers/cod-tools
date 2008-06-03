#include <cctbx/boost_python/flex_fwd.h>

#include <boost/python/class.hpp>
#include <boost/python/def.hpp>
#include <boost/python/args.hpp>
#include <boost/python/return_value_policy.hpp>
#include <boost/python/copy_const_reference.hpp>
#include <boost/python/with_custodian_and_ward.hpp>
#include <scitbx/boost_python/iterator_wrappers.h>
#include <scitbx/boost_python/is_polymorphic_workaround.h>
#include <cctbx/crystal/neighbors_fast.h>
#include <cctbx/crystal/workarounds_bpl.h>

SCITBX_BOOST_IS_POLYMORPHIC_WORKAROUND(
  cctbx::crystal::neighbors::fast_pair_generator<>)

namespace cctbx { namespace crystal { namespace neighbors {

namespace {

  template <typename PairGeneratorType>
  struct helper
  {
    static boost::python::object
    next(PairGeneratorType& o)
    {
      if (o.at_end()) {
        PyErr_SetString(PyExc_StopIteration, "asu_mappings are exhausted.");
        boost::python::throw_error_already_set();
      }
      return boost::python::object(o.next());
    }
  };

  struct simple_pair_generator_wrappers
  {
    typedef simple_pair_generator<> w_t;

    static void
    wrap()
    {
      using namespace boost::python;
      class_<w_t>("neighbors_simple_pair_generator", no_init)
        .def(init<boost::shared_ptr<direct_space_asu::asu_mappings<> >&,
                  optional<double const&, bool> >(
          (arg_("asu_mappings"), arg_("distance_cutoff"), arg_("minimal"))))
        .def("asu_mappings", &w_t::asu_mappings)
        .def("distance_cutoff_sq", &w_t::distance_cutoff_sq)
        .def("minimal", &w_t::minimal)
        .def("at_end", &w_t::at_end)
        .def("next", helper<w_t>::next)
        .def("__iter__", scitbx::boost_python::pass_through)
        .def("restart", &w_t::restart)
        .def("count_pairs", &w_t::count_pairs)
        .def("max_distance_sq", &w_t::max_distance_sq)
        .def("neighbors_of", &w_t::neighbors_of, (arg_("primary_selection")))
        .def("is_simple_interaction", &w_t::is_simple_interaction)
      ;
    }
  };

  struct fast_pair_generator_wrappers
  {
    typedef fast_pair_generator<> w_t;

    static void
    wrap()
    {
      using namespace boost::python;
      typedef return_value_policy<copy_const_reference> ccr;
      class_<w_t, bases<simple_pair_generator<> > >(
        "neighbors_fast_pair_generator", no_init)
        .def(init<boost::shared_ptr<direct_space_asu::asu_mappings<> >&,
                  double const&,
                  optional<bool, double const&> >(
          (arg_("asu_mappings"),
           arg_("distance_cutoff"),
           arg_("minimal"),
           arg_("epsilon"))))
        .def("epsilon", &w_t::epsilon)
        .def("n_boxes", &w_t::n_boxes, ccr())
        .def("next", helper<w_t>::next)
        .def("restart", &w_t::restart)
        .def("count_pairs", &w_t::count_pairs)
        .def("max_distance_sq", &w_t::max_distance_sq)
        .def("neighbors_of", &w_t::neighbors_of, (arg_("primary_selection")))
      ;
    }
  };

}} // namespace neighbors::<anoymous>

namespace boost_python {

  void wrap_neighbors()
  {
    using namespace boost::python;
    def("neighbors_max_memory_allocation_set",
      neighbors::max_memory_allocation_set, (arg_("number_of_bytes")));
    def("neighbors_max_memory_allocation_get",
      neighbors::max_memory_allocation_get);
    neighbors::simple_pair_generator_wrappers::wrap();
    neighbors::fast_pair_generator_wrappers::wrap();
  }

}}} // namespace cctbx::crystal::boost_python
