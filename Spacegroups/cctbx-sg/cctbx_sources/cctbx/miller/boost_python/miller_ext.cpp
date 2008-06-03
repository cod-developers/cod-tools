#include <cctbx/boost_python/flex_fwd.h>

#include <cctbx/miller/sym_equiv.h>
#include <cctbx/miller/math.h>
#include <boost/python/module.hpp>
#include <boost/python/def.hpp>
#include <boost/python/class.hpp>
#include <boost/python/args.hpp>
#include <scitbx/boost_python/container_conversions.h>

namespace cctbx { namespace miller { namespace boost_python {

  void wrap_asu();
  void wrap_bins();
  void wrap_change_basis();
  void wrap_expand_to_p1();
  void wrap_index_generator();
  void wrap_index_span();
  void wrap_match_bijvoet_mates();
  void wrap_match_indices();
  void wrap_merge_equivalents();
  void wrap_phase_transfer();
  void wrap_phase_integrator();
  void wrap_sym_equiv();
  // miller_lookup_utils
  void wrap_lookup_tensor();
  void wrap_local_neighbourhood();
  void wrap_local_area();


namespace {

  hendrickson_lattman<>
  as_hendrickson_lattman(
    bool centric_flag,
    std::complex<double> const& phase_integral,
    double const& max_figure_of_merit)
  {
    return hendrickson_lattman<>(
      centric_flag, phase_integral, max_figure_of_merit);
  }

  void register_tuple_mappings()
  {
    using namespace scitbx::boost_python::container_conversions;

    tuple_mapping_variable_capacity<af::shared<sym_equiv_index> >();
  }

  void init_module()
  {
    using namespace boost::python;

    register_tuple_mappings();

    wrap_sym_equiv(); // must be wrapped first to enable use of bases<>
    wrap_asu();
    wrap_bins();
    wrap_change_basis();
    wrap_expand_to_p1();
    wrap_index_generator();
    wrap_index_span();
    wrap_match_bijvoet_mates();
    wrap_match_indices();
    wrap_merge_equivalents();
    wrap_phase_integrator();
    wrap_phase_transfer();

    wrap_lookup_tensor();
    wrap_local_neighbourhood();
    wrap_local_area();


    def("statistical_mean",
      (double(*)(sgtbx::space_group const&,
                 bool,
                 af::const_ref<index<> > const&,
                 af::const_ref<double> const&)) statistical_mean);

    def("as_hendrickson_lattman", as_hendrickson_lattman, (
      arg_("centric_flag"),
      arg_("phase_integral"),
      arg_("max_figure_of_merit")));
  }

} // namespace <anonymous>
}}} // namespace cctbx::miller::boost_python

BOOST_PYTHON_MODULE(cctbx_miller_ext)
{
  cctbx::miller::boost_python::init_module();
}
