/*! \file ccp4/ccp4_map_io.h
    Header file for reflection data map importer
*/
//C Copyright (C) 2000-2004 Kevin Cowtan and University of York
//C Copyright (C) 2000-2005 Kevin Cowtan and University of York
//L
//L  This library is free software and is distributed under the terms
//L  and conditions of version 2.1 of the GNU Lesser General Public
//L  Licence (LGPL) with the following additional clause:
//L
//L     `You may also combine or link a "work that uses the Library" to
//L     produce a work containing portions of the Library, and distribute
//L     that work under terms of your choice, provided that you give
//L     prominent notice with each copy of the work that the specified
//L     version of the Library is used in it, and that you include or
//L     provide public access to the complete corresponding
//L     machine-readable source code for the Library including whatever
//L     changes were used in the work. (i.e. If you make changes to the
//L     Library you must distribute those, but you do not need to
//L     distribute source or object code to those portions of the work
//L     not covered by this licence.)'
//L
//L  Note that this clause grants an additional right and does not impose
//L  any additional restriction, and so does not affect compatibility
//L  with the GNU General Public Licence (GPL). If you wish to negotiate
//L  other terms, please contact the maintainer.
//L
//L  You can redistribute it and/or modify the library under the terms of
//L  the GNU Lesser General Public License as published by the Free Software
//L  Foundation; either version 2.1 of the License, or (at your option) any
//L  later version.
//L
//L  This library is distributed in the hope that it will be useful, but
//L  WITHOUT ANY WARRANTY; without even the implied warranty of
//L  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//L  Lesser General Public License for more details.
//L
//L  You should have received a copy of the CCP4 licence and/or GNU
//L  Lesser General Public License along with this library; if not, write
//L  to the CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
//L  The GNU Lesser General Public can also be obtained by writing to the
//L  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
//L  MA 02111-1307 USA


#ifndef CLIPPER_CCP4_MAP_IO
#define CLIPPER_CCP4_MAP_IO


#include "../core/container_map.h"


namespace clipper
{

  //! MAP import/export parent class for clipper objects
  /*! This is the import/export class which can be linked to a CCP4 map
    file and be used to transfer data into or out of a Clipper
    data structure. */
  class CCP4MAPfile
  {
   public:
    //! Constructor: does nothing
    CCP4MAPfile();
    //! Destructor: close any file that was left open
    ~CCP4MAPfile();

    //! Open a file for read access
    void open_read( const String filename_in );
    //! Close a file after reading
    void close_read();
    //! Open a file for read access
    void open_write( const String filename_out );
    //! Close a file after reading
    void close_write();

    //! set cell desription (NXmap write only)
    void set_cell( const Cell& cell );

    //! get file spacegroup
    const Spacegroup& spacegroup() const;
    //! get file cell
    const Cell& cell() const;
    //! get file grid_sampling
    const Grid_sampling& grid_sampling() const;
    //! import data to Xmap
    template<class T> void import_xmap( Xmap<T>& xmap ) const;
    //! export data from Xmap
    template<class T> void export_xmap( const Xmap<T>& xmap );
    //! import data to NXmap
    template<class T> void import_nxmap( NXmap<T>& nxmap ) const;
    //! export data from NXmap
    template<class T> void export_nxmap( const NXmap<T>& nxmap );

  protected:
    enum MAPmode { NONE, READ, WRITE };
    String filename;  //!< filename
    MAPmode mode;     //!< mode

    // header info
    Spacegroup spacegroup_;   //!< map spacegroup
    Cell cell_;               //!< map cell
    Grid_sampling grid_sam_;  //!< cell grid sampling
    Grid_range grid_map_;       //!< map grid extent
  };


} // namespace clipper

#endif
