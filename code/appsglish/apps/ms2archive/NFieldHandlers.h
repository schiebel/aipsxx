//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997
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
//#
//# $Id: NFieldHandlers.h,v 19.6 2004/11/30 17:50:08 ddebonis Exp $

#ifndef APPSGLISH_NFIELDHANDLERS_H
#define APPSGLISH_NFIELDHANDLERS_H

#include <casa/aips.h>
#include <casa/BasicSL/String.h>
#include <casa/Arrays/Vector.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class RecordDesc;
class RecordInterface;
class MultiRecordFieldWriter;
} //# NAMESPACE CASA - END

class FieldCopier
{
public:
    FieldCopier();

    ~FieldCopier();
    
    void clear();

    void setupFieldHandling(RecordDesc &outputFields, 
			    RecordInterface &outputLengths,
			    RecordInterface &outputUnits,
			    const RecordDesc &inputFields,
			    const RecordInterface &inputLengths,
			    const RecordInterface &inputUnits);
    
    void setupCopiers(MultiRecordFieldWriter &copier,
		      RecordInterface &outRecord,
		      const RecordInterface &inRecord);

private:
    Vector<String> itsFields;
};

#endif
