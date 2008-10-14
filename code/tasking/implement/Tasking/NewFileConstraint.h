//# NewFileConstraint: Constrain a string to be a new (non-existent) file
//# Copyright (C) 1996,1999,2002,2004
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
//# $Id: NewFileConstraint.h,v 19.6 2004/11/30 17:51:11 ddebonis Exp $

#ifndef TASKING_NEWFILECONSTRAINT_H
#define TASKING_NEWFILECONSTRAINT_H

#include <tasking/Tasking/ParameterConstraint.h>
#include <tables/LogTables/NewFile.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary>
// Constrain a string to be a new (non-existent) file
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class=ParameterConstraint>ParameterConstraint</linkto>
//   <li> <linkto class=Parameter>Parameter</linkto>
// </prerequisite>
//
// <etymology>
// Use this if you want a New File.
// </etymology>
//
// <synopsis>
// NewFileConstraint is a parameter constraint that is intended to be used
// for String parameters which are interpreted as output file names.
// It uses class <linkto class=NewFile>NewFile</linkto> to determine if the
// file has to be deleted before using it.
// </synopsis>
//
// <example>
// Parameter<String> outfile(inputRecord, "outfile", ParameterSet::In);
// outfile.setConstraint(NewFileConstraint());
// </example>
//
// <motivation>
// Output file names are fairly common parameters, this consolidates the error
// checking and "remove if it already exists" logic.
// </motivation>
//
// <todo asof="1996/12/10">
//   <li> We should probably make sure that the file is writable
// </todo>

class NewFileConstraint : public ParameterConstraint<String>
{
public:
// Currently the deleteIfExists argument has no affect
    NewFileConstraint(Bool deleteIfExists = True);

// Copy constructor (copy semantics)
    NewFileConstraint(const NewFileConstraint &other);

// Assignment (copy semantics)
    NewFileConstraint &operator=(const NewFileConstraint &other);

// Destructor
    ~NewFileConstraint();

// Indicates whether the specified string is a valid new file,
// invoking the choice GUI.  If it returns False, an error 
// message is returned.
    virtual Bool valueOK(const String &value, String &error) const;

// Set the constraint
    virtual ParameterConstraint<String> *clone() const;

private:
    NewFile itsNewFile;
};


} //# NAMESPACE CASA - END

#endif
