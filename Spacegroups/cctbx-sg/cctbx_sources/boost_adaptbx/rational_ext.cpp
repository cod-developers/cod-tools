#include <boost/python/module.hpp>
#include <boost/python/def.hpp>
#include <boost/python/class.hpp>
#include <boost/python/return_value_policy.hpp>
#include <boost/python/copy_const_reference.hpp>
#include <boost/python/tuple.hpp>
#include <boost/python/str.hpp>
#include <boost/python/operators.hpp>
#include <boost/rational.hpp>

namespace {

  struct rational_int_wrappers
  {
    typedef boost::rational<int> w_t;

    static int
    as_int(w_t const& o)
    {
      if (o.denominator() != 1) {
        throw std::runtime_error(
          "boost.rational: as_int() conversion error:"
          " denominator is different from one.");
      }
      return o.numerator();
    }

    static double
    as_double(w_t const& o)
    {
      return double(o.numerator()) / o.denominator();
    }

    static boost::python::tuple
    as_tuple(w_t const& o)
    {
      return boost::python::make_tuple(o.numerator(), o.denominator());
    }

    static boost::python::str
    as_str(w_t const& o)
    {
      using boost::python::str;
      if (o.denominator() == 1) {
        return str(o.numerator());
      }
      return str(str(o.numerator()) + "/" + str(o.denominator()));
    }

    static long
    hash(w_t const& o)
    {
      // http://docs.python.org/ref/customization.html
      // Python-2.4.3/Objects/intobject.c, int_hash()
      long result;
      if (o.denominator() == 1) {
        result = o.numerator();
      }
      else {
        result = o.denominator() << 16 ^ o.numerator();
      }
      if (result == -1) result = -2;
      return result;
    }

    static w_t
    abs(w_t const& o)
    {
      if (o < 0) return -o;
      return o;
    }

    static w_t div_rr(w_t const& lhs, w_t const& rhs) { return lhs/rhs; }
    static w_t div_ri(w_t const& lhs, int rhs) { return lhs/rhs; }
    static w_t rdiv_ir(w_t const& rhs, int lhs) { return lhs/rhs; }

    static bool eq_rr(w_t const& lhs, w_t const& rhs) { return lhs == rhs; }
    static bool ne_rr(w_t const& lhs, w_t const& rhs) { return lhs != rhs; }
    static bool lt_rr(w_t const& lhs, w_t const& rhs) { return lhs < rhs; }
    static bool gt_rr(w_t const& lhs, w_t const& rhs) { return lhs > rhs; }
    static bool le_rr(w_t const& lhs, w_t const& rhs) { return lhs <= rhs; }
    static bool ge_rr(w_t const& lhs, w_t const& rhs) { return lhs >= rhs; }

    static bool eq_ri(w_t const& lhs, int rhs) { return lhs == rhs; }
    static bool ne_ri(w_t const& lhs, int rhs) { return lhs != rhs; }
    static bool lt_ri(w_t const& lhs, int rhs) { return lhs < rhs; }
    static bool gt_ri(w_t const& lhs, int rhs) { return lhs > rhs; }
    static bool le_ri(w_t const& lhs, int rhs) { return lhs <= rhs; }
    static bool ge_ri(w_t const& lhs, int rhs) { return lhs >= rhs; }

    static void
    wrap()
    {
      using namespace boost::python;
      class_<w_t>("int")
        .def(init<w_t>())
        .def(init<int, optional<int> >())
        .def("numerator", &w_t::numerator)
        .def("denominator", &w_t::denominator)
        .def("__int__", as_int)
        .def("__float__", as_double)
        .def("as_tuple", as_tuple)
        .def("__str__", as_str)
        .def("__repr__", as_str)
        .def("__hash__", hash)
        .def("__abs__", abs)
        .def(-self)
        .def(self + self)
        .def(self - self)
        .def(self * self)
        .def("__div__", div_rr)
        .def("__truediv__", div_rr)
        .def("__floordiv__", div_rr)
        .def(self + int())
        .def(self - int())
        .def(self * int())
        .def("__div__", div_ri)
        .def("__truediv__", div_ri)
        .def("__floordiv__", div_ri)
        .def(int() + self)
        .def(int() - self)
        .def(int() * self)
        .def("__rdiv__", rdiv_ir)
        .def("__rtruediv__", rdiv_ir)
        .def("__rfloordiv__", rdiv_ir)
        .def("__eq__", eq_rr)
        .def("__ne__", ne_rr)
        .def("__lt__", lt_rr)
        .def("__gt__", gt_rr)
        .def("__le__", le_rr)
        .def("__ge__", ge_rr)
        .def("__eq__", eq_ri)
        .def("__ne__", ne_ri)
        .def("__lt__", lt_ri)
        .def("__gt__", gt_ri)
        .def("__le__", le_ri)
        .def("__ge__", ge_ri)
        .enable_pickling()
        .def("__getinitargs__", as_tuple)
      ;
    }
  };

  void init_module()
  {
    using namespace boost::python;

    rational_int_wrappers::wrap();
    def("gcd", (int(*)(int,int))boost::gcd);
    def("lcm", (int(*)(int,int))boost::lcm);
  }

} // namespace <anonymous>

BOOST_PYTHON_MODULE(boost_rational_ext)
{
  init_module();
}
