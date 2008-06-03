#ifndef SCITBX_ARRAY_FAMILY_TINY_TYPES_H
#define SCITBX_ARRAY_FAMILY_TINY_TYPES_H

#include <scitbx/array_family/tiny.h>

namespace scitbx { namespace af {

  typedef tiny<int, 3> int3;
  typedef tiny<int, 9> int9;
  typedef tiny<long, 3> long3;
  typedef tiny<double, 2> double2;
  typedef tiny<double, 3> double3;
  typedef tiny<double, 6> double6;
  typedef tiny<double, 9> double9;

}} // namespace scitbx::af

#if !defined(BOOST_NO_TEMPLATE_PARTIAL_SPECIALIZATION)

namespace boost {

  template<>
  struct has_trivial_destructor<scitbx::af::int3> {
    static const bool value = true;
  };

  template<>
  struct has_trivial_destructor<scitbx::af::int9> {
    static const bool value = true;
  };

  template<>
  struct has_trivial_destructor<scitbx::af::long3> {
    static const bool value = true;
  };

  template<>
  struct has_trivial_destructor<scitbx::af::double2> {
    static const bool value = true;
  };

  template<>
  struct has_trivial_destructor<scitbx::af::double3> {
    static const bool value = true;
  };

  template<>
  struct has_trivial_destructor<scitbx::af::double6> {
    static const bool value = true;
  };

  template<>
  struct has_trivial_destructor<scitbx::af::double9> {
    static const bool value = true;
  };

}

#endif // !defined(BOOST_NO_TEMPLATE_PARTIAL_SPECIALIZATION)

#endif // SCITBX_ARRAY_FAMILY_TINY_TYPES_H
