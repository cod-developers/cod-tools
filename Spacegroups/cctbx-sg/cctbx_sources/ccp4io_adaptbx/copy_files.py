import shutil
import sys, os
source_root = sys.argv[1]
for path in ["academic_software_licence.pdf",
             "lib/src/library_err.c",
             "lib/src/library_file.c",
             "lib/src/library_utils.c",
             "lib/src/ccp4_array.c",
             "lib/src/ccp4_parser.c",
             "lib/src/ccp4_unitcell.c",
             "lib/src/cvecmat.c",
             "lib/src/cmtzlib.c",
             "lib/src/csymlib.c",
             "lib/src/ccp4_array.h",
             "lib/src/ccp4_sysdep.h",
             "lib/src/ccp4_errno.h",
             "lib/src/ccp4_parser.h",
             "lib/src/ccp4_spg.h",
             "lib/src/ccp4_utils.h",
             "lib/src/library_file.h",
             "lib/src/ccp4_types.h",
             "lib/src/ccp4_vars.h",
             "lib/src/cmtzlib.h",
             "lib/src/mtzdata.h",
             "lib/src/ccp4_unitcell.h",
             "lib/src/cvecmat.h",
             "lib/src/csymlib.h",
             "lib/src/ccp4_file_err.h",
             "lib/data/symop.lib",
            ]:
  print path
  dir = os.path.split(path)[0]
  if (dir != "" and not os.path.isdir(dir)):
    os.makedirs(dir)
  lines = []
  for line in open(os.path.join(source_root, path), "rb"):
    if (line.lstrip().startswith("static char rcsid")): continue
    lines.append(line)
  f = open(path, "wb")
  for line in lines:
    f.write(line)
  f.close()
