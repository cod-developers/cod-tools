#include <iotbx/pdb/hierarchy.h>

namespace iotbx { namespace pdb { namespace hierarchy {

namespace {

  void
  append_range(
    std::vector<unsigned>& v,
    unsigned i_seq,
    unsigned i_seq_end)
  {
    for(;i_seq!=i_seq_end;i_seq++) v.push_back(i_seq);
  }

  template <typename StrType>
  void
  map_array_transfer(
    std::map<StrType, std::vector<unsigned> >& map_s,
    std::map<std::string, std::vector<unsigned> >& map)
  {
    typedef typename std::map<StrType, std::vector<unsigned> >::iterator it;
    it i_end = map_s.end();
    for(it i=map_s.begin();i!=i_end;i++) {
      map[i->first.elems].swap(i->second);
    }
  }

} // namespace <anonymous>

  atom_selection_cache::atom_selection_cache(
    hierarchy::root const& root,
    bool altloc_only)
  {
    std::map<str8, std::vector<unsigned> > model_id_s;
    std::map<str4, std::vector<unsigned> > name_s;
    std::map<str1, std::vector<unsigned> > altloc_s;
    std::map<str3, std::vector<unsigned> > resname_s;
    std::map<str2, std::vector<unsigned> > chain_id_s;
    std::map<str4, std::vector<unsigned> > resseq_s;
    std::map<str1, std::vector<unsigned> > icode_s;
    std::map<str5, std::vector<unsigned> > resid_s;
    std::map<str4, std::vector<unsigned> > segid_s;
    std::map<str2, std::vector<unsigned> > element_s;
    std::map<str2, std::vector<unsigned> > charge_s;
    unsigned i_seq = 0;
    std::vector<model> const& models = root.models();
    unsigned n_mds = root.models_size();
    for(unsigned i_md=0;i_md<n_mds;i_md++) {
      unsigned model_i_seq_start = i_seq;
      model const& mo = models[i_md];
      unsigned n_chs = mo.chains_size();
      std::vector<chain> const& chains = mo.chains();
      for(unsigned i_ch=0;i_ch<n_chs;i_ch++) {
        unsigned chain_i_seq_start = i_seq;
        chain const& ch = chains[i_ch];
        unsigned n_rgs = ch.residue_groups_size();
        std::vector<residue_group> const& rgs = ch.residue_groups();
        for(unsigned i_rg=0;i_rg<n_rgs;i_rg++) {
          unsigned rg_i_seq_start = i_seq;
          residue_group const& rg = rgs[i_rg];
          unsigned n_ags = rg.atom_groups_size();
          std::vector<atom_group> const& ags = rg.atom_groups();
          for(unsigned i_ag=0;i_ag<n_ags;i_ag++) {
            unsigned ag_i_seq_start = i_seq;
            atom_group const& ag = ags[i_ag];
            unsigned n_ats = ag.atoms_size();
            if (!altloc_only) {
              std::vector<atom> const& ats = ag.atoms();
              for(unsigned i_at=0;i_at<n_ats;i_at++,i_seq++) {
                atom const& a = ats[i_at];
                atom_data const& ad = *a.data;
                name_s[ad.name].push_back(i_seq);
                segid_s[ad.segid].push_back(i_seq);
                element_s[ad.element].push_back(i_seq);
                charge_s[ad.charge].push_back(i_seq);
                if (a.uij_is_defined()) anisou.push_back(i_seq);
              }
              append_range(resname_s[ag.data->resname], ag_i_seq_start, i_seq);
            }
            else {
              i_seq += n_ats;
            }
            append_range(altloc_s[ag.data->altloc], ag_i_seq_start, i_seq);
          }
          if (!altloc_only) {
            append_range(resseq_s[rg.data->resseq], rg_i_seq_start, i_seq);
            append_range(icode_s[rg.data->icode], rg_i_seq_start, i_seq);
            append_range(resid_s[rg.resid_small_str()], rg_i_seq_start, i_seq);
          }
        }
        if (!altloc_only) {
          append_range(chain_id_s[ch.data->id], chain_i_seq_start, i_seq);
        }
      }
      if (!altloc_only) {
        append_range(model_id_s[mo.data->id], model_i_seq_start, i_seq);
      }
    }
    n_seq = i_seq;
    if (!altloc_only) {
      if (altloc_s.find(str1("")) != altloc_s.end()) {
        std::vector<unsigned> const& s0 = altloc_s[str1("")];
        std::vector<unsigned>& s1 = altloc_s[str1(" ")];
        s1.insert(s1.end(), s0.begin(), s0.end());
        altloc_s.erase(str1(""));
      }
      map_array_transfer(model_id_s, model_id);
      map_array_transfer(name_s, name);
      map_array_transfer(resname_s, resname);
      map_array_transfer(chain_id_s, chain_id);
      map_array_transfer(resseq_s, resseq);
      map_array_transfer(icode_s, icode);
      map_array_transfer(resid_s, resid);
      map_array_transfer(segid_s, segid);
      map_array_transfer(element_s, element);
      map_array_transfer(charge_s, charge);
    }
    map_array_transfer(altloc_s, altloc);
  }

}}} // namespace iotbx::pdb::hierarchy
