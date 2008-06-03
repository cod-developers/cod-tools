#include <scitbx/array_family/boost_python/flex_wrapper.h>
#include <scitbx/array_family/boost_python/flex_pickle_single_buffered.h>
#include <scitbx/array_family/boost_python/range_wrappers.h>
#include <scitbx/math/utils.h>
#include <boost/python/args.hpp>
#include <boost/python/overloads.hpp>
#include <boost/python/make_constructor.hpp>
#include <vector>
#include <set>
#include "flex_helpers.h"

namespace scitbx { namespace af {

namespace {

  flex<double>::type*
  from_stl_vector_double(std::vector<double> const& v)
  {
    shared<double> result(reserve(v.size()));
    for(std::size_t i=0;i<v.size();i++) {
      result.push_back(v[i]);
    }
    return new flex<double>::type(result, result.size());
  }

  flex<double>::type*
  from_list_or_tuple_of_lists_or_tuples(PyObject* matrix_ptr)
  {
    static const char* argument_error
      = "argument must be a Python list or tuple of lists or tuples.";
    static const char* column_size_error
      = "matrix columns must have identical sizes.";
    shared<double> result;
    std::size_t n_rows = 0;
    std::size_t n_columns = 0;
    if (PyList_Check(matrix_ptr)) {
      n_rows = PyList_GET_SIZE(matrix_ptr);
      for(std::size_t i_row=0;i_row<n_rows;i_row++) {
        PyObject* row = PyList_GET_ITEM(matrix_ptr, i_row);
        if (PyList_Check(row)) {
          if (i_row == 0) {
            n_columns = PyList_GET_SIZE(row);
            result.reserve(n_rows*n_columns);
          }
          else {
            if (PyList_GET_SIZE(row) != n_columns) {
              throw std::runtime_error(column_size_error);
            }
          }
          for(std::size_t i_column=0;i_column<n_columns;i_column++) {
            PyObject* elem = PyList_GET_ITEM(row, i_column);
            double value = PyFloat_AsDouble(elem);
            if (PyErr_Occurred()) boost::python::throw_error_already_set();
            result.push_back(value);
          }
        }
        else if (PyTuple_Check(row)) {
          if (i_row == 0) {
            n_columns = PyTuple_GET_SIZE(row);
          }
          else {
            if (PyTuple_GET_SIZE(row) != n_columns) {
              throw std::runtime_error(column_size_error);
            }
          }
          for(std::size_t i_column=0;i_column<n_columns;i_column++) {
            PyObject* elem = PyTuple_GET_ITEM(row, i_column);
            double value = PyFloat_AsDouble(elem);
            if (PyErr_Occurred()) boost::python::throw_error_already_set();
            result.push_back(value);
          }
        }
        else if (i_row == 0) {
          result.reserve(n_rows);
          for (;i_row<n_rows;i_row++) {
            PyObject* elem = PyList_GET_ITEM(matrix_ptr, i_row);
            double value = PyFloat_AsDouble(elem);
            if (PyErr_Occurred()) boost::python::throw_error_already_set();
            result.push_back(value);
          }
          return new flex<double>::type(result, flex_grid<>(n_rows));
        }
        else {
          throw std::runtime_error(argument_error);
        }
      }
    }
    else if (PyTuple_Check(matrix_ptr)) {
      n_rows = PyTuple_GET_SIZE(matrix_ptr);
      for(std::size_t i_row=0;i_row<n_rows;i_row++) {
        PyObject* row = PyTuple_GET_ITEM(matrix_ptr, i_row);
        if (PyList_Check(row)) {
          if (i_row == 0) {
            n_columns = PyList_GET_SIZE(row);
            result.reserve(n_rows*n_columns);
          }
          else {
            if (PyList_GET_SIZE(row) != n_columns) {
              throw std::runtime_error(column_size_error);
            }
          }
          for(std::size_t i_column=0;i_column<n_columns;i_column++) {
            PyObject* elem = PyList_GET_ITEM(row, i_column);
            double value = PyFloat_AsDouble(elem);
            if (PyErr_Occurred()) boost::python::throw_error_already_set();
            result.push_back(value);
          }
        }
        else if (PyTuple_Check(row)) {
          if (i_row == 0) {
            n_columns = PyTuple_GET_SIZE(row);
          }
          else {
            if (PyTuple_GET_SIZE(row) != n_columns) {
              throw std::runtime_error(column_size_error);
            }
          }
          for(std::size_t i_column=0;i_column<n_columns;i_column++) {
            PyObject* elem = PyTuple_GET_ITEM(row, i_column);
            double value = PyFloat_AsDouble(elem);
            if (PyErr_Occurred()) boost::python::throw_error_already_set();
            result.push_back(value);
          }
        }
        else if (i_row == 0) {
          result.reserve(n_rows);
          for (;i_row<n_rows;i_row++) {
            PyObject* elem = PyTuple_GET_ITEM(matrix_ptr, i_row);
            double value = PyFloat_AsDouble(elem);
            if (PyErr_Occurred()) boost::python::throw_error_already_set();
            result.push_back(value);
          }
          return new flex<double>::type(result, flex_grid<>(n_rows));
        }
        else {
          throw std::runtime_error(argument_error);
        }
      }
    }
    else {
      throw std::runtime_error(argument_error);
    }
    if (n_rows == 0) {
      return new flex<double>::type(result, flex_grid<>(0));
    }
    return new flex<double>::type(result, flex_grid<>(n_rows, n_columns));
  }

  flex<double>::type*
  from_list_of_lists_or_tuples(boost::python::list const& matrix)
  {
    return from_list_or_tuple_of_lists_or_tuples(matrix.ptr());
  }

  flex<double>::type*
  from_tuple_of_lists_or_tuples(boost::python::tuple const& matrix)
  {
    return from_list_or_tuple_of_lists_or_tuples(matrix.ptr());
  }

  shared<double>
  extract_double_attributes(
    boost::python::object array,
    const char* attribute_name,
    boost::python::object none_substitute)
  {
    PyObject* array_ptr = array.ptr();
#if PY_VERSION_HEX >= 0x02050000
    const char* attr_name = attribute_name;
#else
    char* attr_name = const_cast<char*>(attribute_name);
#endif
    PyObject* none_substitute_ptr = none_substitute.ptr();
    if (PyList_Check(array_ptr)) {
      std::size_t len_array = PyList_GET_SIZE(array_ptr);
      shared<double> result((reserve(len_array)));
      for(std::size_t i=0;i<len_array;i++) {
        PyObject* elem = PyList_GET_ITEM(array_ptr, i);
        PyObject* elem_attr = PyObject_GetAttrString(elem, attr_name);
        if (!elem_attr) boost::python::throw_error_already_set();
        if (elem_attr == Py_None) elem_attr = none_substitute_ptr;
        double value = PyFloat_AsDouble(elem_attr);
        if (PyErr_Occurred()) boost::python::throw_error_already_set();
        result.push_back(value);
      }
      return result;
    }
    if (PyTuple_Check(array_ptr)) {
      std::size_t len_array = PyTuple_GET_SIZE(array_ptr);
      shared<double> result((reserve(len_array)));
      for(std::size_t i=0;i<len_array;i++) {
        PyObject* elem = PyTuple_GET_ITEM(array_ptr, i);
        PyObject* elem_attr = PyObject_GetAttrString(elem, attr_name);
        if (!elem_attr) boost::python::throw_error_already_set();
        if (elem_attr == Py_None) elem_attr = none_substitute_ptr;
        double value = PyFloat_AsDouble(elem_attr);
        if (PyErr_Occurred()) boost::python::throw_error_already_set();
        result.push_back(value);
      }
      return result;
    }
    throw error("array must be a Python list or tuple.");
  }

  versa<std::complex<double>, flex_grid<> >
  mul_ar_sc(
    versa<double, flex_grid<> > const& self,
    std::complex<double> const& rhs)
  {
    versa<std::complex<double>, flex_grid<> > result(
      self.accessor(),
      init_functor_null<std::complex<double> >());
    std::complex<double>* r = result.begin();
    const double* s = self.begin();
    const double* s_end = self.end();
    while (s != s_end) {
      *r++ = (*s++) * rhs;
    }
    return result;
  }

  bool
  all_approx_equal_a_a(
    const_ref<double> const& self,
    const_ref<double> const& other,
    double tolerance=1.e-6)
  {
    return self.all_approx_equal(other, tolerance);
  }

  bool
  all_approx_equal_a_s(
    const_ref<double> const& self,
    double other,
    double tolerance=1.e-6)
  {
    return self.all_approx_equal(other, tolerance);
  }

  shared<double>
  round(
    const_ref<double> const& self,
    int n_digits=0)
  {
    shared<double> result(self.size(), init_functor_null<double>());
    for(std::size_t i=0;i<self.size();i++) {
      result[i] = math::round(self[i], n_digits);
    }
    return result;
  }

  shared<double>
  select_stl_set_unsigned(
    const_ref<double> const& self,
    std::set<unsigned> const& selection)
  {
    shared<double> result(selection.size(), init_functor_null<double>());
    std::set<unsigned>::const_iterator sel_end = selection.end();
    double* r = result.begin();
    for(std::set<unsigned>::const_iterator
          sel=selection.begin();sel!=sel_end;sel++) {
      SCITBX_ASSERT(*sel < self.size());
      *r++ = self[*sel];
    }
    SCITBX_ASSERT(r == result.end());
    return result;
  }

} // namespace <anonymous>

namespace boost_python {

  BOOST_PYTHON_FUNCTION_OVERLOADS(
    all_approx_equal_a_a_overloads, all_approx_equal_a_a, 2, 3)
  BOOST_PYTHON_FUNCTION_OVERLOADS(
    all_approx_equal_a_s_overloads, all_approx_equal_a_s, 2, 3)

  BOOST_PYTHON_FUNCTION_OVERLOADS(round_overloads, round, 1, 2)

  void
  wrap_flex_double_matrix(
    flex_wrapper<double>::class_f_t& class_f_t);

  void wrap_flex_double()
  {
    using namespace boost::python;

    typedef flex_wrapper<double> f_w;
    f_w::class_f_t class_f_t(f_w::numeric("double", scope()));
    class_f_t
      .def_pickle(flex_pickle_single_buffered<double>())
      .def("__init__", make_constructor(
        from_stl_vector_double, default_call_policies()))
      .def("__init__", make_constructor(
        from_list_of_lists_or_tuples, default_call_policies()))
      .def("__init__", make_constructor(
        from_tuple_of_lists_or_tuples, default_call_policies()))
      .def("__mul__", mul_ar_sc)
      .def("__rmul__", mul_ar_sc)
      .def("__mul__", f_w::mul_a_s) // re-define so it is found first
      .def("__rmul__", f_w::mul_a_s) // re-define so it is found first
      .def("add_selected",
        (object(*)(
          object const&,
          const_ref<std::size_t> const&,
          const_ref<double> const&)) add_selected_unsigned_a,
        (arg_("self"), arg_("indices"), arg_("values")))
      .def("all_approx_equal",
        all_approx_equal_a_a,
        all_approx_equal_a_a_overloads((
          arg_("self"),
          arg_("other"),
          arg_("tolerance")=1.e-6)))
      .def("all_approx_equal",
        all_approx_equal_a_s,
        all_approx_equal_a_s_overloads((
          arg_("self"),
          arg_("other"),
          arg_("tolerance")=1.e-6)))
      .def("round", round, round_overloads((
        arg_("self"),
        arg_("n_digits")=0)))
      .def("select", select_stl_set_unsigned, (arg_("selection")))
    ;
    range_wrappers<double, long>::wrap("double_range");

    typedef return_value_policy<return_by_value> rbv;
    typedef af::min_max_mean<double> mmm;
    class_<mmm>("min_max_mean_double", no_init)
      .def(init<af::const_ref<double> const&>((arg_("values"))))
      .def_readonly("n", &mmm::n)
      .add_property("min", make_getter(&mmm::min, rbv()))
      .add_property("max", make_getter(&mmm::max, rbv()))
      .add_property("sum", make_getter(&mmm::sum, rbv()))
      .add_property("mean", make_getter(&mmm::mean, rbv()))
    ;

    def("extract_double_attributes", extract_double_attributes,
      (arg_("array"), arg_("attribute_name"), arg_("none_substitute")));

    wrap_flex_double_matrix(class_f_t);
  }

}}} // namespace scitbx::af::boost_python
