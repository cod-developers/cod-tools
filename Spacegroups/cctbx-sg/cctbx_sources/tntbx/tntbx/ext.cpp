#include <scitbx/array_family/boost_python/flex_fwd.h>
#include <boost/python.hpp>

#include <tntbx/svd.h>
#include <tntbx/generalized_inverse.h>

namespace tntbx { namespace {

  template <typename FloatType>
  struct svd_m_ge_n_wrapper
  {
    typedef svd_m_ge_n<FloatType> w_t;

    static void
    wrap(const char* python_name)
    {
      using namespace boost::python;
      class_<w_t>(python_name, no_init)
        .def(init<af::const_ref<FloatType, af::c_grid<2> > const&>((
          arg_("m"))))
        .def("singular_values", &w_t::singular_values)
        .def("s", &w_t::s)
        .def("u", &w_t::u)
        .def("v", &w_t::v)
        .def("norm2", &w_t::norm2)
        .def("cond", &w_t::cond)
        .def("rank", &w_t::rank)
      ;
    };
  };

}} // namespace tntbx::<anonymous>

BOOST_PYTHON_MODULE(tntbx_ext)
{
  using namespace boost::python;
  tntbx::svd_m_ge_n_wrapper<double>::wrap("svd_m_ge_n_double");
  def("generalized_inverse", tntbx::generalized_inverse, (
    arg_("square_matrix")));
}
