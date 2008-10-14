//# ObjectIDRecord.h: Convert ObjectID to/from GlishRecord
//# Copyright (C) 1996,1998,1999,2000,2001,2003
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
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: ObjectIDRecord.h,v 19.5 2004/11/30 17:51:11 ddebonis Exp $


#ifndef TASKING_OBJECTIDRECORD_H
#define TASKING_OBJECTIDRECORD_H

#include <casa/aips.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Forward declarations
class ObjectID;
class RecordInterface;
class GlishRecord;
class String;


// <summary> 
// Convert ObjectID to/from GlishRecord.
// </summary>

// <use visibility=export>

// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="tObjectIDRecord.cc" demos="">

// <prerequisite>
//   <li> <linkto class=ObjectID>ObjectID</linkto>
// </prerequisite>
//
// <synopsis> 
// This file contains functions to convert an ObjectID to and from a
// GlishRecord for the AIPS++ Tasking system.
// </synopsis> 
//
// <motivation>
// The ObjectID class should be independent of the Tasking system used.
// Therefore functions coverting to and from a GlishRecord have been put
// in this separate file.
// </motivation>

// <group name=ObjectIDRecord>

    // It is useful to be able to interconvert between ObjectID's and Records.
    // At present the Tasking system only uses GlishRecords, but we might want
    // to change this to RecordInterfaces at some point. Note that if you do
    // not call this function you will not link against Glish, as it is in its
    // own .cc file.
    //
    // Although you shouldn't need to know the exact form of the record, it is:
    // <srcblock>
    // [_seq=sequence, _pid=pid, _time=time, _host=hostname]
    // </srcblock>
    // Note that the prefix ("_") may be defined.
    //
    // This mapping may change with time. If any of the above fields already
    // exist they will be overwritten when writing. When reading, all fields
    // must be set. The field names begin with an underscore so that they may
    // may be set into the same record as "user" data.
    // <group>
    void OIDtoRecord (const ObjectID&, GlishRecord& out,
		      const char* prefix = "_");
    Bool OIDfromRecord (ObjectID&, String& error, const GlishRecord& in, 
			const char* prefix = "_");
    // </group>

// </group>



} //# NAMESPACE CASA - END

#endif

