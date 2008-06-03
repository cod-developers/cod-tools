#include <scitbx/array_family/boost_python/flex_fwd.h>

#include <scitbx/math/floating_point_epsilon.h>
#include <scitbx/math/erf.h>
#include <scitbx/math/bessel.h>
#include <scitbx/math/gamma.h>
#include <scitbx/math/chebyshev.h>
#include <scitbx/math/lambertw.h>
#include <scitbx/math/eigensystem.h>
#include <scitbx/math/superpose.h>
#include <scitbx/math/phase_error.h>
#include <scitbx/math/resample.h>
#include <scitbx/math/halton.h>
#include <scitbx/math/utils.h>
#include <scitbx/math/euler_angles.h>

#include <boost/python/module.hpp>
#include <boost/python/def.hpp>
#include <boost/python/class.hpp>
#include <boost/python/args.hpp>
#include <boost/python/overloads.hpp>

namespace scitbx { namespace math {
namespace boost_python {

  void wrap_basic_statistics();
  void wrap_gaussian();
  void wrap_golay();
  void wrap_minimum_covering_sphere();
  void wrap_principal_axes_of_inertia();
  void wrap_row_echelon();
  void wrap_tensor_rank_2();
  void wrap_icosahedron();
  void wrap_chebyshev_base();
  void wrap_chebyshev_polynome();
  void wrap_chebyshev_fitter();
  void wrap_chebyshev_lsq();
  void wrap_slatec();
  void wrap_line_search();
  void wrap_r3_rotation();
  void wrap_resample();
  void wrap_quadrature();
  void wrap_unimodular_generator();
  void wrap_halton();

namespace {

  struct eigensystem_real_symmetric_wrappers
  {
    typedef eigensystem::real_symmetric<> w_t;

    static void
    wrap()
    {
      using namespace boost::python;
      class_<w_t>("eigensystem_real_symmetric", no_init)
        .def(init<af::const_ref<double, af::c_grid<2> > const&,
                  optional<double> >())
        .def(init<scitbx::sym_mat3<double> const&,
                  optional<double> >())
        .def("vectors", &w_t::vectors)
        .def("values", &w_t::values)
      ;
    }
  };

  vec3<double>
  time_eigensystem_real_symmetric(
    sym_mat3<double> const& m, std::size_t n_repetitions)
  {
    SCITBX_ASSERT(n_repetitions % 2 == 0);
    vec3<double> result(0,0,0);
    for(std::size_t i=0;i<n_repetitions/2;i++) {
      result += vec3<double>(
        eigensystem::real_symmetric<>(m).values().begin());
      result -= vec3<double>(
        eigensystem::real_symmetric<>(m).values().begin());
    }
    return result / static_cast<double>(n_repetitions);
  }

  mat3<double>
  superpose_kearsley_rotation(
    af::const_ref<vec3<double> > const& reference_sites,
    af::const_ref<vec3<double> > const& other_sites)
  {
    return superpose::superposition<>::kearsley_rotation(
      reference_sites, other_sites);
  }

  mat3< double >
  euler_angles_xyz_matrix(
      const double& ax,
      const double& ay,
      const double& az )
  {
    return euler_angles::xyz_matrix( ax, ay, az );
  }

  vec3< double >
  euler_angles_xyz_angles(
      const mat3< double >& m,
      const double& eps = 1.0e-12 )
  {
    return euler_angles::xyz_angles( m, eps );
  }

  mat3< double >
  euler_angles_yzx_matrix(
      const double& ay,
      const double& az,
      const double& ax )
  {
    return euler_angles::yzx_matrix( ay, az, ax );
  }

  vec3< double >
  euler_angles_yzx_angles(
      const mat3< double >& m,
      const double& eps = 1.0e-12 )
  {
    return euler_angles::yzx_angles( m, eps );
  }

  mat3< double >
  euler_angles_zyz_matrix(
      const double& az1,
      const double& ay,
      const double& az3 )
  {
    return euler_angles::zyz_matrix( az1, ay, az3 );
  }

  vec3< double >
  euler_angles_zyz_angles(
      const mat3< double >& m,
      const double& eps = 1.0e-12 )
  {
    return euler_angles::zyz_angles( m, eps );
  }

  BOOST_PYTHON_FUNCTION_OVERLOADS(
    euler_angles_xyz_angles_overloads, euler_angles_xyz_angles, 1, 2)
  BOOST_PYTHON_FUNCTION_OVERLOADS(
    euler_angles_yzx_angles_overloads, euler_angles_yzx_angles, 1, 2)
  BOOST_PYTHON_FUNCTION_OVERLOADS(
    euler_angles_zyz_angles_overloads, euler_angles_zyz_angles, 1, 2)

  BOOST_PYTHON_FUNCTION_OVERLOADS(
    gamma_complete_overloads,
    gamma::complete, 1, 2)
  BOOST_PYTHON_FUNCTION_OVERLOADS(
    gamma_incomplete_overloads,
    gamma::incomplete, 2, 3)
  BOOST_PYTHON_FUNCTION_OVERLOADS(
    gamma_incomplete_complement_overloads,
    gamma::incomplete_complement, 2, 3)

  BOOST_PYTHON_FUNCTION_OVERLOADS(lambertw_overloads, lambertw, 1, 2)

  BOOST_PYTHON_FUNCTION_OVERLOADS(
    signed_phase_error_overloads, signed_phase_error, 2, 3)
  BOOST_PYTHON_FUNCTION_OVERLOADS(
    phase_error_overloads, phase_error, 2, 3)
  BOOST_PYTHON_FUNCTION_OVERLOADS(
    nearest_phase_overloads, nearest_phase, 2, 3)

  void init_module()
  {
    using namespace boost::python;

    def("floating_point_epsilon_float_get",
      &floating_point_epsilon<float>::get);
    def("floating_point_epsilon_double_get",
      &floating_point_epsilon<double>::get);

    def("erf", (double(*)(double const&)) erf);
    def("erf", (scitbx::af::shared<double>(*)(scitbx::af::const_ref<double> const&)) erf);

    def("erfc", (double(*)(double const&)) erfc);
    def("erfcx", (double(*)(double const&)) erfcx);

    def("bessel_i1_over_i0", (double(*)(double const&)) bessel::i1_over_i0);
    def("bessel_i1_over_i0", (scitbx::af::shared<double>(*)(scitbx::af::const_ref<double> const&)) bessel::i1_over_i0);
    def("bessel_inverse_i1_over_i0",
      (double(*)(double const&)) bessel::inverse_i1_over_i0);
    def("inverse_bessel_i1_over_i0", (scitbx::af::shared<double>(*)(
         scitbx::af::const_ref<double> const&)) bessel::inverse_i1_over_i0);
    def("bessel_i0", (double(*)(double const&)) bessel::i0);
    def("bessel_i1", (double(*)(double const&)) bessel::i1);
    def("bessel_ln_of_i0", (double(*)(double const&)) bessel::ln_of_i0);
    def("ei1", (double(*)(double const&)) bessel::ei1);
    def("ei0", (double(*)(double const&)) bessel::ei0);



    def("gamma_complete", (double(*)(double const&, bool))
        gamma::complete,
        gamma_complete_overloads( (arg_("x"),
                                   arg_("minimax")=true)));
    def("gamma_incomplete", (double(*)(double const&,
                                       double const&,
                                       unsigned))
        gamma::incomplete,
        gamma_incomplete_overloads( (arg_("a"),
                                     arg_("x"),
                                     arg_("max_iterations")=500 )));
    def("gamma_incomplete_complement",(double(*)(double const&,
                                                 double const&,
                                                 unsigned))
        gamma::incomplete_complement,
        gamma_incomplete_complement_overloads( (arg_("a"),
                                                arg_("x"),
                                                arg_("max_iterations")=500 )));
    def("exponential_integral_e1z", (double(*)(double const&))
         gamma::exponential_integral_e1z );



    def("lambertw", (double(*)(double const&, unsigned)) lambertw,
      lambertw_overloads(
        (arg_("x"), arg_("max_iterations")=100)));

    eigensystem_real_symmetric_wrappers::wrap();

    wrap_basic_statistics();
    wrap_gaussian();
    wrap_golay();
    wrap_minimum_covering_sphere();
    wrap_principal_axes_of_inertia();
    wrap_row_echelon();
    wrap_tensor_rank_2();
    wrap_icosahedron();
    wrap_chebyshev_base();
    wrap_chebyshev_polynome();
    wrap_chebyshev_fitter();
    wrap_chebyshev_lsq();
    wrap_slatec();
    wrap_line_search();
    wrap_r3_rotation();
    wrap_resample();
    wrap_quadrature();
    wrap_unimodular_generator();
    wrap_halton();

    def("time_eigensystem_real_symmetric", time_eigensystem_real_symmetric);

    def("superpose_kearsley_rotation", superpose_kearsley_rotation, (
      arg_("reference_sites"), arg_("other_sites")));

    def( "euler_angles_xyz_matrix", euler_angles_xyz_matrix, (
      arg_("ax"), arg_("ay"), arg_("az")));
    def( "euler_angles_xyz_angles", euler_angles_xyz_angles,
      euler_angles_xyz_angles_overloads((
        arg_("m"), arg_("eps")=1.e-12)));

    def( "euler_angles_yzx_matrix", euler_angles_yzx_matrix, (
      arg_("ay"), arg_("az"), arg_("ax")));
    def( "euler_angles_yzx_angles", euler_angles_yzx_angles,
      euler_angles_yzx_angles_overloads((
        arg_("m"), arg_("eps")=1.e-12)));

    def( "euler_angles_zyz_matrix", euler_angles_zyz_matrix, (
      arg_("az1"), arg_("ay"), arg_("az3")));
    def( "euler_angles_zyz_angles", euler_angles_zyz_angles,
      euler_angles_zyz_angles_overloads((
        arg_("m"), arg_("eps")=1.e-12)));

    def("signed_phase_error",
      (double(*)(
        double const&, double const&, bool))
          math::signed_phase_error,
      signed_phase_error_overloads(
        (arg_("phi1"), arg_("phi2"), arg_("deg")=false)));
    def("signed_phase_error",
      (af::shared<double>(*)(
        af::const_ref<double> const&, af::const_ref<double> const&, bool))
          math::signed_phase_error,
      signed_phase_error_overloads(
        (arg_("phi1"), arg_("phi2"), arg_("deg")=false)));
    def("phase_error",
      (double(*)(
        double const&, double const&, bool))
          math::phase_error,
      phase_error_overloads(
        (arg_("phi1"), arg_("phi2"), arg_("deg")=false)));
    def("phase_error",
      (af::shared<double>(*)(
        af::const_ref<double> const&, af::const_ref<double> const&, bool))
          math::phase_error,
      phase_error_overloads(
        (arg_("phi1"), arg_("phi2"), arg_("deg")=false)));
    def("nearest_phase",
      (double(*)(
        double const&, double const&, bool))
          math::nearest_phase,
      nearest_phase_overloads(
        (arg_("reference"), arg_("other"), arg_("deg")=false)));
    def("nearest_phase",
      (af::shared<double>(*)(
        af::const_ref<double> const&, af::const_ref<double> const&, bool))
          math::nearest_phase,
      nearest_phase_overloads(
        (arg_("reference"), arg_("other"), arg_("deg")=false)));
    def("divmod", math::divmod);
  }

}}}} // namespace scitbx::math::boost_python::<anonymous>

BOOST_PYTHON_MODULE(scitbx_math_ext)
{
  scitbx::math::boost_python::init_module();
}
