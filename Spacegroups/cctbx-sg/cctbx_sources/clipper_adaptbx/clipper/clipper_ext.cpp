#include <boost/python/module.hpp>
#include <boost/static_assert.hpp>

#if defined(__linux__) && defined(__GNUC__) \
 && __GNUC__ == 2 && __GNUC_MINOR__ == 96
# undef isnan
#endif

#if defined(__linux__) && defined(__GNUC__) \
 && __GNUC__ == 4 && __GNUC_MINOR__ == 0 && __GNUC_PATCHLEVEL__ == 0
# include <iostream>
# define CLIPPER_EXT_GCC400_WORKAROUND
#endif

#include <clipper/core/clipper_util.h>
#include <cctbx/error.h>
#include <scitbx/constants.h>

namespace clipper {

namespace boost_python {

  void wrap_hendrickson_lattman();
  void wrap_sigmaa();

}

namespace {

  template <typename FloatType>
  struct sanity_check
  {
    sanity_check(FloatType x)
    {
      BOOST_STATIC_ASSERT(sizeof(ftype32) == 4);
      BOOST_STATIC_ASSERT(sizeof(ftype64) == 8);
      BOOST_STATIC_ASSERT(sizeof(ftype32) == sizeof(uitype32));
      BOOST_STATIC_ASSERT(sizeof(ftype64) == sizeof(uitype64));
      BOOST_STATIC_ASSERT(sizeof(ftype32) == sizeof(itype32));
      BOOST_STATIC_ASSERT(sizeof(ftype64) == sizeof(itype64));
      CCTBX_ASSERT(Util::is_nan(x));
      CCTBX_ASSERT(Util::isnan(x));
      Util::set_null(x);
      CCTBX_ASSERT(Util::is_nan(x));
      CCTBX_ASSERT(Util::isnan(x));
      CCTBX_ASSERT(Util::is_null(x));
      for(int i=-10;i<10;i++) {
#if defined(CLIPPER_EXT_GCC400_WORKAROUND)
        std::cout << std::flush;
#endif
        FloatType x = i;
        CCTBX_ASSERT(!Util::is_nan(x));
        CCTBX_ASSERT(!Util::isnan(x));
        CCTBX_ASSERT(!Util::is_null(x));
        x *= i * scitbx::constants::pi;
        CCTBX_ASSERT(!Util::is_nan(x));
        CCTBX_ASSERT(!Util::isnan(x));
        CCTBX_ASSERT(!Util::is_null(x));
      }
    }
  };

  void init_module()
  {
    sanity_check<ftype32> check32(Util::nanf());
    sanity_check<ftype64> check64(Util::nand());
    boost_python::wrap_hendrickson_lattman();
    boost_python::wrap_sigmaa();
  }

}} // namespace clipper::<anonymous>

BOOST_PYTHON_MODULE(clipper_ext)
{
  clipper::init_module();
}
