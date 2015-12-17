/*---------------------------------------------------------------------------*\
**$Author: saulius $
**$Date: 2015-12-10 17:03:25 +0200 (Thu, 10 Dec 2015) $ 
**$Revision: 226 $
**$URL: svn+ssh://saulius-grazulis.lt/home/saulius/svn-repositories/tests/spglib-perl/SPGLib.h $
\*---------------------------------------------------------------------------*/

#ifndef __SPGLIB_H
#define __SPGLIB_H

#include <EXTERN.h>
#include <perl.h>

SV* get_spacegroup( SV* cell_constant_ref, SV* atom_position_ref );

#endif
