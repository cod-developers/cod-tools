#include <scitbx/array_family/boost_python/flex_fwd.h>
#include <boost/python.hpp>

#include <tntbx/eigensystem.h>

BOOST_PYTHON_MODULE(tntbx_eigensystem_ext)
{
  namespace af = scitbx::af;
  using namespace boost::python;
  def("get_eigenvectors",tntbx::get_eigenvectors,(
    arg_("square_matrix")
    )
      );
  // classes
  class_<tntbx::real<> >("real", no_init)
    .def(init<af::const_ref<double, af::c_grid<2> > const&
         >(
           (
            arg_("m")
            )
           )
         )
    .def(init<scitbx::sym_mat3<double> const&
         >(
           (
            arg_("m")
            )
           )
         )
    .def("values", &tntbx::real<>::values)
    .def("vectors", &tntbx::real<>::vectors)
    ;
}
