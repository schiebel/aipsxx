//# VisJonesDesc.h: Define the format of VisJones calibration tables
//# Copyright (C) 1996,1997,2003
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
//# License for more details.
//#
//# You should have received a copy of the GNU Library General Public License
//# along with this library; if not, write to the Free Software Foundation,
//# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be adressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//#
//# $Id: VisJonesDesc.h,v 19.4 2004/11/30 17:50:13 ddebonis Exp $

#ifndef CALIBRATION_VISJONESDESC_H
#define CALIBRATION_VISJONESDESC_H

#include <calibration/CalTables/CalTableDesc.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary> 
// VisJonesDesc: Define the format of VisJones calibration tables
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="" tests="" demos="">

// <prerequisite>
//   <li> <linkto class="CalTableDesc">CalTableDesc</linkto> module
// </prerequisite>
//
// <etymology>
// From "VisJones" and "descriptor".
// </etymology>
//
// <synopsis>
// VisJonesDesc defines the format of VisJones calibration tables in terms
// of table descriptors <linkto class="TableDesc">TableDesc</linkto>, as
// used in the Table system. Specializations for time-variable and
// solvable VisJones calibration tables are provided through inheritance.
// At present, this set of classes returns only the default table formats.
// </etymology>
//
// <example>
// <srcblock>
// </srcblock>
// </example>
//
// <motivation>
// See CalTableDesc.
// </motivation>
//
// <todo asof="98/01/01">
// Generate calibration table descriptors from a VisSet or VisBuffer object
// </todo>

class VisJonesDesc : public CalTableDesc
{
 public:
   // Default null constructor, and destructor
   VisJonesDesc();
   virtual ~VisJonesDesc() {};

   // Construct from the Jones table type
   VisJonesDesc (const String& type);

};


} //# NAMESPACE CASA - END

#endif
   
  



