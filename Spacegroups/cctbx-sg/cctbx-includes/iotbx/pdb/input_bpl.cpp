#include <cctbx/boost_python/flex_fwd.h>

#include <boost/python/class.hpp>
#include <boost/python/args.hpp>
#include <boost/python/overloads.hpp>
#include <boost/python/return_value_policy.hpp>
#include <boost/python/return_by_value.hpp>
#include <boost/python/dict.hpp>
#include <iotbx/pdb/input.h>
#include <iotbx/pdb/write_utils_bpl.h>

namespace iotbx { namespace pdb {
namespace {

  struct columns_73_76_evaluator_wrappers
  {
    typedef columns_73_76_evaluator w_t;

    static void
    wrap()
    {
      using namespace boost::python;
      class_<w_t>("columns_73_76_evaluator", no_init)
        .def(init<
          af::const_ref<std::string> const&,
          optional<
            unsigned,
            unsigned> >(
              (arg_("lines"),
               arg_("is_frequent_threshold_atom_records")=1000,
               arg_("is_frequent_threshold_other_records")=100)))
        .def_readonly("finding", &w_t::finding)
        .def_readonly("is_old_style", &w_t::is_old_style)
      ;
    }
  };

  struct input_atoms_with_labels_list : input_atoms_with_labels_generator
  {
    boost::python::list result;

    bool
    process_atom(hierarchy::atom_with_labels const& awl)
    {
      result.append(awl);
      return true;
    }
  };

  struct input_wrappers
  {
    typedef input w_t;

    static
    boost::python::dict
    record_type_counts_as_dict(w_t const& self)
    {
      using namespace boost::python;
      dict result;
      typedef w_t::record_type_counts_t rtct;
      rtct const& rtc = self.record_type_counts();
      for(rtct::const_iterator i=rtc.begin(); i!= rtc.end(); i++) {
        result[i->first.elems] = i->second;
      }
      return result;
    }

    static boost::python::list
    atoms_with_labels(
      w_t const& self)
    {
      input_atoms_with_labels_list g;
      g.run(self);
      return g.result;
    }

    static void
    as_pdb_string_cstringio(
      w_t const& self,
      boost::python::object cstringio,
      bool append_end=false,
      bool atom_hetatm=true,
      bool sigatm=true,
      bool anisou=true,
      bool siguij=true)
    {
      write_utils::cstringio_write write(cstringio.ptr());
      input_as_pdb_string(
        self,
        write,
        append_end,
        atom_hetatm,
        sigatm,
        anisou,
        siguij);
    }

    BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(
      construct_hierarchy_overloads, construct_hierarchy, 0, 1)

    static void
    wrap()
    {
      using namespace boost::python;
      typedef return_value_policy<return_by_value> rbv;
      class_<w_t, boost::shared_ptr<input> >("input", no_init)
        .def(init<
          std::string const&>((
            arg_("file_name"))))
        .def(init<
          const char*,
          af::const_ref<std::string> const&>((
            arg_("source_info"),
            arg_("lines"))))
        //
        .enable_pickling()
        .def("source_info", &w_t::source_info, rbv())
        .def("record_type_counts", record_type_counts_as_dict)
        .def("unknown_section", &w_t::unknown_section, rbv())
        .def("title_section", &w_t::title_section, rbv())
        .def("remark_section", &w_t::remark_section, rbv())
        .def("primary_structure_section",
          &w_t::primary_structure_section, rbv())
        .def("heterogen_section", &w_t::heterogen_section, rbv())
        .def("secondary_structure_section",
          &w_t::secondary_structure_section, rbv())
        .def("connectivity_annotation_section",
          &w_t::connectivity_annotation_section, rbv())
        .def("miscellaneous_features_section",
          &w_t::miscellaneous_features_section, rbv())
        .def("crystallographic_section", &w_t::crystallographic_section, rbv())
        .def("input_atom_labels_list", &w_t::input_atom_labels_list, rbv())
        .def("atoms", &w_t::atoms, rbv())
        .def("model_ids", &w_t::model_ids, rbv())
        .def("model_indices", &w_t::model_indices, rbv())
        .def("ter_indices", &w_t::ter_indices, rbv())
        .def("chain_indices", &w_t::chain_indices, rbv())
        .def("break_indices", &w_t::break_indices, rbv())
        .def("connectivity_section", &w_t::connectivity_section, rbv())
        .def("bookkeeping_section", &w_t::bookkeeping_section, rbv())
        .def("model_atom_counts", &w_t::model_atom_counts)
        .def("atoms_with_labels", atoms_with_labels)
        .def("_as_pdb_string_cstringio", as_pdb_string_cstringio, (
          arg_("self"),
          arg_("cstringio"),
          arg_("append_end"),
          arg_("atom_hetatm"),
          arg_("sigatm"),
          arg_("anisou"),
          arg_("siguij")))
        .def("_write_pdb_file", &w_t::write_pdb_file, (
          arg_("file_name"),
          arg_("open_append"),
          arg_("append_end"),
          arg_("atom_hetatm"),
          arg_("sigatm"),
          arg_("anisou"),
          arg_("siguij")))
        .def("construct_hierarchy", &w_t::construct_hierarchy,
          construct_hierarchy_overloads((
            arg_("residue_group_post_processing")=true)))
      ;
    }
  };

  void
  wrap_input_impl()
  {
    scitbx::boost_python::cstringio_import();
    columns_73_76_evaluator_wrappers::wrap();
    input_wrappers::wrap();
  }

} // namespace <anonymous>

namespace boost_python {

  void
  wrap_input() { wrap_input_impl(); }

}}} // namespace iotbx::pdb::boost_python
