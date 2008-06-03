#ifndef IOTBX_PDB_COMMON_RESIDUE_NAMES_H
#define IOTBX_PDB_COMMON_RESIDUE_NAMES_H

#include <iotbx/pdb/small_str.h>
#include <scitbx/array_family/ref.h>
#include <string>
#include <set>

namespace iotbx { namespace pdb { namespace common_residue_names {

  static const char* amino_acid[] = {
    "GLY",
    "ALA",
    "VAL",
    "LEU",
    "ILE",
    "MET",
    "MSE",
    "PRO",
    "PHE",
    "TRP",
    "SER",
    "THR",
    "ASN",
    "GLN",
    "TYR",
    "CYS",
    "LYS",
    "ARG",
    "HIS",
    "ASP",
    "GLU",
    0
  };

  static const char* rna_dna[] = {
    "A  ",
    "C  ",
    "G  ",
    "T  ",
    "U  ",
    "  A",
    "  C",
    "  G",
    "  T",
    "  U",
    "+A ",
    "+C ",
    "+G ",
    "+T ",
    "+U ",
    " +A",
    " +C",
    " +G",
    " +T",
    " +U",
    "DA ", // PDB-V3
    "DC ", // PDB-V3
    "DG ", // PDB-V3
    "DT ", // PDB-V3
    " DA", // PDB-V3
    " DC", // PDB-V3
    " DG", // PDB-V3
    " DT", // PDB-V3
    "ADE", // CNS dna-rna.top
    "CYT", // CNS dna-rna.top
    "GUA", // CNS dna-rna.top
    "THY", // CNS dna-rna.top
    "URI", // CNS dna-rna.top
    0
  };

  static const char* ccp4_mon_lib_rna_dna[] = {
    "AD ",
    "AR ",
    "CD ",
    "CR ",
    "GD ",
    "GR ",
    "TD ",
    "UR ",
    " AD",
    " AR",
    " CD",
    " CR",
    " GD",
    " GR",
    " TD",
    " UR",
    "Ad ",
    "Ar ",
    "Cd ",
    "Cr ",
    "Gd ",
    "Gr ",
    "Td ",
    "Ur ",
    " Ad",
    " Ar",
    " Cd",
    " Cr",
    " Gd",
    " Gr",
    " Td",
    " Ur",
    0
  };

  static const char* water[] = {
    "HOH",
    "H2O",
    "OH2",
    "DOD",
    "D2O",
    "OD2",
    "WAT",
    "TIP",
    "SOL",
    0
  };

  static const char* small_molecule[] = {
    "GOL",
    "PO4",
    "SO4",
    0
  };

  /* Survey of PDB as of 2006/05/25.

     The following element names appear as HETATM residue names, but do
     not correspond to isolated atoms or ions:

     Frequency Element HETNAM
     in PDB    symbol
       36        NO    NITROGEN OXIDE
        1        AS    ADENOSINE-5'-THIO-MONOPHOSPHATE
        1        NP    4-HYDROXY-3-NITROPHENYLACETYL-EPSILON-AMINOCAPROIC ACID
        1        SC    CYTIDINE-5'-THIO-MONOPHOSPHATE
        1        PU    PUROMYCIN-N-AMINOPHOSPHONIC ACID
        1        Y     2'-DEOXY-N6-(S)STYRENE OXIDE ADENOSINE MONOPHOSPHATE

     The element names AS, CM, H, I, IN, N, O, P, S appear as residue
     names but not on HETATM records.

     The following element names appear exclusively as HETATM residue
     names for isolated atoms or ions (these are the only names
     included in the element_set below):

     Frequency Element
     in PDB    symbol
      2579       ZN
      2577       CA
      2376       MG
      1581       CL
      1188       NA
       743       MN
       501       K
       386       FE
       319       CU
       312       CD
       215       HG
       214       NI
       165       CO
        62       BR
        47       XE
        41       SR
        33       CS
        31       PT
        25       BA
        23       TL
        23       PB
        19       SM
        19       AU
        15       RB
        14       YB
        13       LI
        12       KR
        10       MO
         7       LU
         7       CR
         6       OS
         6       GD
         4       TB
         4       LA
         4       F
         4       AR
         4       AG
         3       HO
         3       GA
         3       CE
         2       W
         2       SE
         2       RU
         2       RE
         2       PR
         2       IR
         2       EU
         2       AL
         1       V
         1       TE
         1       SB
         1       PD
   */
  static const char* element[] = {
    "ZN ",
    " ZN",
    "CA ",
    " CA",
    "MG ",
    " MG",
    "CL ",
    " CL",
    "NA ",
    " NA",
    "MN ",
    " MN",
    "K  ",
    "  K",
    "FE ",
    " FE",
    "CU ",
    " CU",
    "CD ",
    " CD",
    "HG ",
    " HG",
    "NI ",
    " NI",
    "CO ",
    " CO",
    "BR ",
    " BR",
    "XE ",
    " XE",
    "SR ",
    " SR",
    "CS ",
    " CS",
    "PT ",
    " PT",
    "BA ",
    " BA",
    "TL ",
    " TL",
    "PB ",
    " PB",
    "SM ",
    " SM",
    "AU ",
    " AU",
    "RB ",
    " RB",
    "YB ",
    " YB",
    "LI ",
    " LI",
    "KR ",
    " KR",
    "MO ",
    " MO",
    "LU ",
    " LU",
    "CR ",
    " CR",
    "OS ",
    " OS",
    "GD ",
    " GD",
    "TB ",
    " TB",
    "LA ",
    " LA",
    "F  ",
    "  F",
    "AR ",
    " AR",
    "AG ",
    " AG",
    "HO ",
    " HO",
    "GA ",
    " GA",
    "CE ",
    " CE",
    "W  ",
    "  W",
    "SE ",
    " SE",
    "RU ",
    " RU",
    "RE ",
    " RE",
    "PR ",
    " PR",
    "IR ",
    " IR",
    "EU ",
    " EU",
    "AL ",
    " AL",
    "V  ",
    "  V",
    "TE ",
    " TE",
    "SB ",
    " SB",
    "PD ",
    " PD",
    0
  };

  inline
  void
  initialize_set(
    std::set<str3>& name_set,
    const char** names)
  {
    if (name_set.size() != 0) return;
    for(const char** n=names; *n; n++) name_set.insert(str3(*n));
  }

  inline
  str3
  std_string_as_str3(std::string const& name)
  {
    if (name.size() > 3) {
      throw std::runtime_error(
        "residue name with more than 3 characters: \""+name+"\"");
    }
    return str3(name.data(), name.size(), /*i_begin*/ 0, /*pad_with*/ ' ');
  }

  inline
  void
  initialize_set(
    std::set<str3>& name_set,
    scitbx::af::const_ref<std::string> const& names)
  {
    for(std::size_t i=0;i<names.size();i++) {
      name_set.insert(std_string_as_str3(names[i]));
    }
  }

  inline
  const std::set<str3>&
  amino_acid_set()
  {
    static std::set<str3> result;
    initialize_set(result, amino_acid);
    return result;
  }

  inline
  const std::set<str3>&
  rna_dna_set()
  {
    static std::set<str3> result;
    initialize_set(result, rna_dna);
    return result;
  }

  inline
  const std::set<str3>&
  ccp4_mon_lib_rna_dna_set()
  {
    static std::set<str3> result;
    initialize_set(result, ccp4_mon_lib_rna_dna);
    return result;
  }

  inline
  const std::set<str3>&
  water_set()
  {
    static std::set<str3> result;
    initialize_set(result, water);
    return result;
  }

  inline
  const std::set<str3>&
  small_molecule_set()
  {
    static std::set<str3> result;
    initialize_set(result, small_molecule);
    return result;
  }

  inline
  const std::set<str3>&
  element_set()
  {
    static std::set<str3> result;
    initialize_set(result, element);
    return result;
  }

  inline
  std::string const&
  get_class(str3 const& name, bool consider_ccp4_mon_lib_rna_dna=false)
  {
    static const std::set<str3>& aa_set = amino_acid_set();
    static const std::set<str3>& na_set = rna_dna_set();
    static const std::set<str3>& ml_na_set = ccp4_mon_lib_rna_dna_set();
    static const std::set<str3>& w_set = water_set();
    static const std::set<str3>& sm_set = small_molecule_set();
    static const std::set<str3>& e_set = element_set();
    static const std::string common_amino_acid("common_amino_acid");
    static const std::string common_rna_dna("common_rna_dna");
    static const std::string ccp4_mon_lib_rna_dna("ccp4_mon_lib_rna_dna");
    static const std::string common_water("common_water");
    static const std::string common_small_molecule("common_small_molecule");
    static const std::string common_element("common_element");
    static const std::string other("other");
    if (aa_set.find(name) != aa_set.end()) {
      return common_amino_acid;
    }
    if (na_set.find(name) != na_set.end()) {
      return common_rna_dna;
    }
    if (   consider_ccp4_mon_lib_rna_dna
        && ml_na_set.find(name) != ml_na_set.end()) {
      return ccp4_mon_lib_rna_dna;
    }
    if (w_set.find(name) != w_set.end()) {
      return common_water;
    }
    if (sm_set.find(name) != sm_set.end()) {
      return common_small_molecule;
    }
    if (e_set.find(name) != e_set.end()) {
      return common_element;
    }
    return other;
  }

  inline
  std::string const&
  get_class(std::string const& name, bool consider_ccp4_mon_lib_rna_dna=false)
  {
    return get_class(std_string_as_str3(name), consider_ccp4_mon_lib_rna_dna);
  }

}}} // namespace iotbx::pdb::common_residue_names

#endif // IOTBX_PDB_COMMON_RESIDUE_NAMES_H
