/*! \file lib/hkl_lookup.h
    Header file for reflection lookup class
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


#ifndef CLIPPER_HKL_LOOKUP
#define CLIPPER_HKL_LOOKUP


#include "coords.h"


namespace clipper
{

  //! Fast reflection lookup object
  /*! This version uses a ragged array index to get reflection indices
    from Miller indices. */

  class HKL_lookup {
   public:
    //! initialise: make a reflection index for a list of HKLs
    void init(const std::vector<HKL>& hkl);

    //! lookup function
    int index_of(const HKL& rfl) const;

    void debug();

    struct llookup { int min, max; std::vector<int> p;
                     llookup() {min=32000;max=-32000;} };  //!< lookup on l
    struct klookup { int min, max; std::vector<llookup> p;
                     klookup() {min=32000;max=-32000;} };  //!< lookup on k
    struct hlookup { int min, max; std::vector<klookup> p;
                     hlookup() {min=32000;max=-32000;} };  //!< lookup on h
  private:
    //! pointer to first list
    hlookup h_ptr;
  };


} // namespace clipper

#endif
