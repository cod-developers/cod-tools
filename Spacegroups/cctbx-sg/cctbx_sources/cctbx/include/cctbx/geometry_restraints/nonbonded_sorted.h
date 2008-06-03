#ifndef CCTBX_GEOMETRY_RESTRAINTS_NONBONDED_SORTED_H
#define CCTBX_GEOMETRY_RESTRAINTS_NONBONDED_SORTED_H

#include <cctbx/geometry_restraints/nonbonded.h>
#include <cctbx/crystal/pair_tables.h>

namespace cctbx { namespace geometry_restraints {

  //! Generation of sorted nonbonded proxies.
  class nonbonded_sorted_asu_proxies : public nonbonded_sorted_asu_proxies_base
  {
    public:
      //! Default constructor. Some data members are not initialized!
      nonbonded_sorted_asu_proxies() {}

      //! Initialization with asu_mappings.
      nonbonded_sorted_asu_proxies(
        boost::shared_ptr<
          direct_space_asu::asu_mappings<> > const& asu_mappings)
      :
        nonbonded_sorted_asu_proxies_base(asu_mappings),
        n_1_3(0),
        n_1_4(0),
        n_nonbonded(0),
        n_unknown_nonbonded_type_pairs(0),
        min_vdw_distance(-1),
        max_vdw_distance(-1)
      {}

      //! Generation of nonbonded proxies.
      /*! Bonds (1-2) interactions are defined by shell_asu_tables[0]
          and are used at the same time as nonbonded exclusions.

          1-3 interactions are defined by shell_asu_tables[1]
          and are used as nonbonded exclusions.

          1-4 interactions are defined by shell_asu_tables[2]
          and are used to attenuate nonbonded energies according to
          nonbonded_params.
       */
      nonbonded_sorted_asu_proxies(
        af::const_ref<std::size_t> const& model_indices,
        af::const_ref<std::size_t> const& conformer_indices,
        geometry_restraints::nonbonded_params const& nonbonded_params,
        af::const_ref<std::string> const& nonbonded_types,
        double nonbonded_distance_cutoff_plus_buffer,
        std::vector<crystal::pair_asu_table<> > const& shell_asu_tables)
      :
        nonbonded_sorted_asu_proxies_base(shell_asu_tables[0].asu_mappings()),
        n_1_3(0),
        n_1_4(0),
        n_nonbonded(0),
        n_unknown_nonbonded_type_pairs(0),
        min_vdw_distance(-1),
        max_vdw_distance(-1)
      {
        CCTBX_ASSERT(model_indices.size() == 0
                  || model_indices.size() == nonbonded_types.size());
        CCTBX_ASSERT(conformer_indices.size() == 0
                  || conformer_indices.size() == nonbonded_types.size());
        CCTBX_ASSERT(shell_asu_tables.size() > 0);
        for(unsigned i=0; i<shell_asu_tables.size(); i++) {
          CCTBX_ASSERT(shell_asu_tables[i].table().size()
                    == nonbonded_types.size());
        }
        unsigned shell_asu_tables_size = shell_asu_tables.size();
        for(unsigned i=1; i<shell_asu_tables_size; i++) {
          CCTBX_ASSERT(shell_asu_tables[i].asu_mappings().get()
                    == shell_asu_tables[0].asu_mappings().get());
        }
        bool minimal = false;
        crystal::neighbors::fast_pair_generator<> pair_generator(
          shell_asu_tables[0].asu_mappings(),
          nonbonded_distance_cutoff_plus_buffer,
          minimal);
        while (!pair_generator.at_end()) {
          direct_space_asu::asu_mapping_index_pair_and_diff<>
            pair = pair_generator.next();
          if (shell_asu_tables[0].contains(pair)) {
            continue;
          }
          if (   shell_asu_tables_size > 1
              && shell_asu_tables[1].contains(pair)) {
            n_1_3++;
            continue;
          }
          if (   model_indices.size() != 0
              && model_indices[pair.i_seq] != model_indices[pair.j_seq]) {
            continue;
          }
          if (   conformer_indices.size() != 0
              && conformer_indices[pair.i_seq] != 0
              && conformer_indices[pair.j_seq] != 0
              && conformer_indices[pair.i_seq]
              != conformer_indices[pair.j_seq]) {
            continue;
          }
          if (   shell_asu_tables_size > 2
              && shell_asu_tables[2].contains(pair)) {
            nonbonded_asu_proxy proxy = make_nonbonded_asu_proxy(
              nonbonded_params, nonbonded_types, pair, true);
            if (min_vdw_distance < 0 || min_vdw_distance > proxy.vdw_distance){
              min_vdw_distance = proxy.vdw_distance;
            }
            if (max_vdw_distance < proxy.vdw_distance) {
              max_vdw_distance = proxy.vdw_distance;
            }
            process(proxy);
            n_1_4++;
            continue;
          }
          {
            nonbonded_asu_proxy proxy = make_nonbonded_asu_proxy(
              nonbonded_params, nonbonded_types, pair, false);
            if (min_vdw_distance < 0 || min_vdw_distance > proxy.vdw_distance){
              min_vdw_distance = proxy.vdw_distance;
            }
            if (max_vdw_distance < proxy.vdw_distance) {
              max_vdw_distance = proxy.vdw_distance;
            }
            process(proxy);
            n_nonbonded++;
          }
        }
      }

      //! For internal use only.
      nonbonded_asu_proxy
      make_nonbonded_asu_proxy(
        geometry_restraints::nonbonded_params const& nonbonded_params,
        af::const_ref<std::string> const& nonbonded_types,
        direct_space_asu::asu_mapping_index_pair const& pair,
        bool is_1_4_interaction)
      {
        std::string const& type_i = nonbonded_types[pair.i_seq];
        std::string const& type_j = nonbonded_types[pair.j_seq];
        double distance = nonbonded_params.get_nonbonded_distance(
          type_i, type_j);
        if (distance != -1) {
          return nonbonded_asu_proxy(
            pair,
            nonbonded_params.adjust_nonbonded_distance(
              distance, is_1_4_interaction));
        }
        if (nonbonded_params.default_distance > 0) {
          n_unknown_nonbonded_type_pairs++;
          return nonbonded_asu_proxy(
            pair,
            nonbonded_params.adjust_nonbonded_distance(
              nonbonded_params.default_distance, is_1_4_interaction));
        }
        throw error(
          "Unknown nonbonded type pair (incomplete nonbonded_distance_table): "
          + type_i + " - " + type_j);
      }

      //! Number of 1-3 interactions excluded from nonbonded proxies.
      unsigned n_1_3;
      //! Number of attenuated 1-4 interactions.
      unsigned n_1_4;
      //! Total number of full strength (not attenuated) nonbonded terms.
      unsigned n_nonbonded;
      /*! \brief Number of unknown nonbonded type pairs (nonbonded proxies
          with default distance).
       */
      unsigned n_unknown_nonbonded_type_pairs;

      //! Smallest VdW distance encountered.
      double min_vdw_distance;
      //! Largest VdW distance encountered.
      double max_vdw_distance;
  };

}} // namespace cctbx::geometry_restraints

#endif // CCTBX_GEOMETRY_RESTRAINTS_NONBONDED_SORTED_H
