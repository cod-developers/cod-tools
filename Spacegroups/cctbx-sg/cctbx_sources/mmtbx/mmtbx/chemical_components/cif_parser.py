import os, sys

cif_keyword_dictionary = {
  "_chem_comp" : {"id" : str,
                  "name" : str,
                  "type" : str,
                  "pdbx_type" : str,
                  "formula" : str,
                  "mon_nstd_parent_comp_id" : str,
                  "pdbx_synonyms" : str,
                  "pdbx_formal_charge" : int,
                  "pdbx_initial_date" : str,
                  "pdbx_modified_date" : str,
                  "pdbx_ambiguous_flag" : str,
                  "pdbx_release_status" : str,
                  "pdbx_replaced_by" : str,
                  "pdbx_replaces" : str,
                  "formula_weight" : float,
                  "one_letter_code" : str,
                  "three_letter_code" : str,
                  "pdbx_model_coordinates_details" : str,
                  "pdbx_model_coordinates_missing_flag" : str,
                  "pdbx_ideal_coordinates_details" : str,
                  "pdbx_ideal_coordinates_missing_flag" : str,
                  "pdbx_model_coordinates_db_code" : str,
                  "pdbx_processing_site" : str,
                  },
  "_chem_comp_atom" : {"comp_id": str,
                       "atom_id": str,
                       "alt_atom_id": str,
                       "type_symbol": str,
                       "charge" : int,
                       "pdbx_align": int,
                       "pdbx_aromatic_flag": str,
                       "pdbx_leaving_atom_flag": str,
                       "pdbx_stereo_config": str,
                       "model_Cartn_x": float,
                       "model_Cartn_y": float,
                       "model_Cartn_z": float,
                       "pdbx_model_Cartn_x_ideal": float,
                       "pdbx_model_Cartn_y_ideal": float,
                       "pdbx_model_Cartn_z_ideal": float,
                       "pdbx_ordinal" : int,
                       },
  "_chem_comp_bond" : {"comp_id": str,
                       "atom_id_1": str,
                       "atom_id_2": str,
                       "value_order": str,
                       "pdbx_aromatic_flag": str,
                       "pdbx_stereo_config": str,
                       "pdbx_ordinal": int,
                       },
  "_pdbx_chem_comp_descriptor" : {"comp_id" : str,
                                  "type" : str,
                                  "program" : str,
                                  "program_version" : str,
                                  "descriptor" : str,
                                  },
  "_pdbx_chem_comp_identifier" : {"comp_id" : str,
                                  "type" : str,
                                  "program" : str,
                                  "program_version" : str,
                                  "identifier" : str,
                                  },
  }

class empty(object):
  def __repr__(self):
    outl = "\nObject"
    for attr in self.__dict__:
      outl += "\n  %s : %s" % (attr, getattr(self, attr))
    return outl

  def __len__(self):
    return len(self.__dict__.keys())

def run(filename):
  if not os.path.exists(filename): return None
  lines = open(filename).read().splitlines()
  line_iter = iter(lines)

  complete_cif_data = {}
  loop_list = []
  non_loop = {}
  code = ""
  for line in line_iter:
    if line.find("#")==0: continue
    line = "%s  " % line
    while line.find('"')>-1:
      start = line.find('"')
      finish = line.find('"', start+1)
      if finish==-1: break
      line = "%s%s%s" % (line[:start],
                         line[start+1:finish].replace(" ", "_space_"),
                         line[finish+1:])
    if line.find("loop_")==0:
      loop_list = []
      continue
    if line.find(";")==0: continue
    if line.find("_")==0:
      for cif_key in cif_keyword_dictionary:
        if line.find(cif_key)==-1: continue
        for attr in cif_keyword_dictionary[cif_key]:
          test = "%s.%s " % (cif_key, attr)
          if line.find(test)>-1:
            loop_list.append(attr)
            if len(line.split())>1:
              non_loop[test] = line.split()[1:]
            break
        if line.find(test)>-1: break
    else:
      if loop_list:
        if code and line.find(code)!=0: continue
        obj = empty()
        for i, item in enumerate(line.split()):
          if loop_list[i]=="comp_id": code = item
          if item not in ["?", "."]:
            item = cif_keyword_dictionary[cif_key][loop_list[i]](item)
          if type(item)==type(""):
            if item[0]=='"' and item[-1]=='"':
              item = item[1:-1]
            item = item.replace("_space_", " ")
          setattr(obj, loop_list[i], item)
        complete_cif_data.setdefault(cif_key, [])
        complete_cif_data[cif_key].append(obj)
  # non loop parsing
  for cif_key in cif_keyword_dictionary:
    obj = empty()
    for key in non_loop:
      if key.find("%s." % cif_key)==0:
        if len(non_loop[key])==1:
          item = non_loop[key][0]
        else:
          assert 0
        sk = key.split(".")[1].strip()
        if item not in ["?", "."]:
          try: item = cif_keyword_dictionary[cif_key][sk](item)
          except:
            print key
            print sk
            print cif_key
            print cif_keyword_dictionary[cif_key].keys()
            raise
        setattr(obj, sk, item)
    if len(obj):
      complete_cif_data[cif_key] = [obj]

  return complete_cif_data

if __name__=="__main__":
  import os, sys
  cif = run(sys.argv[1])
  for key in cif:
    print '_'*80
    print key
    for item in cif[key]:
      print item
