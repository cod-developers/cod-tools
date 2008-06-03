#include <scitbx/boost_python/utils.h>
#include <scitbx/error.h>

namespace scitbx { namespace boost_python {

  boost::python::handle<>
  import_module(const char* module_name)
  {
    using namespace boost::python;
#if PY_VERSION_HEX >= 0x02050000
    return handle<>(PyImport_ImportModule(module_name));
#else
    return handle<>(PyImport_ImportModule(const_cast<char*>(module_name)));
#endif
  }

  void
  raise_index_error()
  {
    PyErr_SetString(PyExc_IndexError, "Index out of range.");
    boost::python::throw_error_already_set();
  }

  boost::python::object
  range(long start, long len, long step)
  {
    SCITBX_ASSERT(step != 0);
    SCITBX_ASSERT(len >= 0);
    return boost::python::object(boost::python::handle<>(
#if PY_VERSION_HEX >= 0x02030000
        PyObject_CallFunction(
          (PyObject*) (void*) &PyRange_Type,
          "lll", start, start+len*step, step)
#else
        PyRange_New(start, len, step, 1)
#endif
      ));
  }

  boost::python::object
  range(long len)
  {
    return range(0, len);
  }

}} // namespace scitbx::boost_python
