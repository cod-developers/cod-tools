/*
     ccp4_vars.h: Standard strings for certain quantites
     Copyright (C) 2002  CCLRC, Martyn Winn

     This library is free software and is distributed under the terms and
     conditions of the CCP4 licence agreement as `Part 0' (Annex 2)
     software, which is version 2.1 of the GNU Lesser General Public
     Licence (LGPL) with the following additional clause:

        `You may also combine or link a "work that uses the Library" to
        produce a work containing portions of the Library, and distribute
        that work under terms of your choice, provided that you give
        prominent notice with each copy of the work that the specified
        version of the Library is used in it, and that you include or
        provide public access to the complete corresponding
        machine-readable source code for the Library including whatever
        changes were used in the work. (i.e. If you make changes to the
        Library you must distribute those, but you do not need to
        distribute source or object code to those portions of the work
        not covered by this licence.)'

     Note that this clause grants an additional right and does not impose
     any additional restriction, and so does not affect compatibility
     with the GNU General Public Licence (GPL). If you wish to negotiate
     other terms, please contact the maintainer.

     You can redistribute it and/or modify the library under the terms of
     the GNU Lesser General Public License as published by the Free Software
     Foundation; either version 2.1 of the License, or (at your option) any
     later version.

     This library is distributed in the hope that it will be useful, but
     WITHOUT ANY WARRANTY; without even the implied warranty of
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
     Lesser General Public License for more details.

     You should have received a copy of the CCP4 licence and/or GNU
     Lesser General Public License along with this library; if not, write
     to the CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
     The GNU Lesser General Public can also be obtained by writing to the
     Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
     MA 02111-1307 USA
*/
/*
*/

/* Author: Martyn Winn */

/* Standard strings for certain quantites - for future use */

#ifndef __CCP4_VARS__
#define __CCP4_VARS__

#define MTZFILENAME "data::mtzfile::filename"
#define MTZTITLE "data::mtzfile::title"
#define MTZSPACEGROUP "data::mtzfile::spacegroup_num"
#define MTZNUMREFLS "data::mtzfile::num_reflections"
#define MTZMNF "data::mtzfile::missing_number_flag"
#define MTZSORTORDER "data::mtzfile::sort_order"

#define CRYSTALXTALNAME "data::crystal::crystal_name"
#define CRYSTALPNAME "data::crystal::project_name"
#define CRYSTALCELL "data::crystal::cell"

#define DATASETDNAME "data::crystal::dataset::dataset_name"
#define DATASETWAVELENGTH "data::crystal::dataset::wavelength"

#define COLUMNLABEL "data::crystal_i::dataset_i::column_i::label"
#define COLUMNTYPE "data::crystal_i::dataset_i::column_i::type"

#endif  /*!__CCP4_VARS__ */
