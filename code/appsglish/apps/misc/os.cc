//# os.cc: glish client for executing os-specific commands
//# Copyright (C) 1999,2000,2001
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
//# $Id: os.cc,v 19.6 2005/06/21 14:17:16 ddebonis Exp $


#include <../misc/os.h>
#include <casa/OS/DOos.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/Parameter.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/String.h>
#include <casa/Quanta/MVTime.h>


#include <casa/namespace.h>
os::os()
{}

os::os (const os &other)
: ApplicationObject(other)
{}

os &os::operator=(const os &)
{
    return *this;
}

os::~os()
{}


String os::className() const
{
    return "os";
}

Vector<String> os::methods() const
{
    Vector<String> method(16);
    method(0) = "isvalidpathname";
    method(1) = "fileexists";
    method(2) = "filetype";
    method(3) = "dir";
    method(4) = "mkdir";
    method(5) = "fullname";
    method(6) = "dirname";
    method(7) = "basename";
    method(8) = "filetime";
    method(9) = "filetimestring";
    method(10) = "size";
    method(11) = "freespace";
    method(12) = "copy";
    method(13) = "move";
    method(14) = "remove";
    method(15) = "lockinfo";
    return method;
}

Vector<String> os::noTraceMethods() const
{
    return methods();
}


MethodResult os::runMethod (uInt which, 
			    ParameterSet &inputRecord,
			    Bool runMethod)
{
    switch(which) {
    case 0:
        {
	    Parameter<Vector<String> > pathName(inputRecord, "pathname",
						ParameterSet::In);
            Parameter<Vector<Bool> > returnval(inputRecord, "returnval",
					       ParameterSet::Out);
            if (runMethod) {
	        returnval() = DOos::isValidPathName (pathName());
            }
        }
    break;
    case 1:
        {
	    Parameter<Vector<String> > pathName(inputRecord, "pathname",
						ParameterSet::In);
	    Parameter<Bool> follow(inputRecord, "follow",
				   ParameterSet::In);
            Parameter<Vector<Bool> > returnval(inputRecord, "returnval",
					       ParameterSet::Out);
            if (runMethod) {
	        returnval() = DOos::fileExists (pathName(), follow());
            }
        }
    break;
    case 2:
        {
	    Parameter<Vector<String> > pathName(inputRecord, "pathname",
						ParameterSet::In);
	    Parameter<Bool> follow(inputRecord, "follow",
				   ParameterSet::In);
            Parameter<Vector<String> > returnval(inputRecord, "returnval",
					       ParameterSet::Out);
            if (runMethod) {
	        returnval() = DOos::fileType (pathName(), follow());
            }
        }
    break;
    case 3:
        {
	    Parameter<String> directory(inputRecord, "directory",
					ParameterSet::In);
	    Parameter<String> pattern(inputRecord, "pattern",
				      ParameterSet::In);
	    Parameter<String> types(inputRecord, "types",
				    ParameterSet::In);
	    Parameter<Bool> all(inputRecord, "all",
				ParameterSet::In);
	    Parameter<Bool> follow(inputRecord, "follow",
				   ParameterSet::In);
            Parameter<Vector<String> > returnval(inputRecord, "returnval",
						 ParameterSet::Out);
            if (runMethod) {
	        returnval() = DOos::fileNames (directory(), pattern(),
					       types(), all(), follow());
            }
        }
    break;
    case 4:
        {
	    Parameter<Vector<String> > directory(inputRecord, "directory",
						 ParameterSet::In);
	    Parameter<Bool> makeParent(inputRecord, "makeparent",
				       ParameterSet::In);
	    if (runMethod) {
	        DOos::makeDirectory (directory(), makeParent());
	    }
        }
    break;
    case 5:
        {
	    Parameter<Vector<String> > pathName(inputRecord, "pathname",
						ParameterSet::In);
            Parameter<Vector<String> > returnval(inputRecord, "returnval",
						 ParameterSet::Out);
	    if (runMethod) {
	        returnval() = DOos::fullName (pathName());
	    }
        }
    break;
    case 6:
        {
	    Parameter<Vector<String> > pathName(inputRecord, "pathname",
						ParameterSet::In);
            Parameter<Vector<String> > returnval(inputRecord, "returnval",
						 ParameterSet::Out);
	    if (runMethod) {
	        returnval() = DOos::dirName (pathName());
	    }
        }
    break;
    case 7:
        {
	    Parameter<Vector<String> > pathName(inputRecord, "pathname",
						ParameterSet::In);
            Parameter<Vector<String> > returnval(inputRecord, "returnval",
						 ParameterSet::Out);
	    if (runMethod) {
	        returnval() = DOos::baseName (pathName());
	    }
        }
    break;
    case 8:
        {
	    Parameter<Vector<String> > pathName(inputRecord, "pathname",
						ParameterSet::In);
	    Parameter<Int> whichTime(inputRecord, "whichtime",
				     ParameterSet::In);
	    Parameter<Bool> follow(inputRecord, "follow",
				   ParameterSet::In);
            Parameter<Vector<Double> > returnval(inputRecord, "returnval",
						 ParameterSet::Out);
	    if (runMethod) {
	        returnval() = DOos::fileTime (pathName(), whichTime(),
					      follow());
	    }
        }
    break;
    case 9:
        {
	    Parameter<Vector<String> > pathName(inputRecord, "pathname",
						ParameterSet::In);
	    Parameter<Int> whichTime(inputRecord, "whichtime",
				     ParameterSet::In);
	    Parameter<Bool> follow(inputRecord, "follow",
				   ParameterSet::In);
            Parameter<Vector<String> > returnval(inputRecord, "returnval",
						 ParameterSet::Out);
	    if (runMethod) {
	        Vector<Double> times = DOos::fileTime (pathName(), whichTime(),
						       follow());
		Vector<String>& str = returnval();
		str.resize (times.nelements());
		for (uInt i=0; i<times.nelements(); i++) {
		  str(i) = MVTime(times(i)).string(MVTime::DMY|MVTime::LOCAL,
						   0);
		}
	    }
        }
    break;
    case 10:
        {
	    Parameter<Vector<String> > pathName(inputRecord, "pathname",
						ParameterSet::In);
	    Parameter<Bool> follow(inputRecord, "follow",
				   ParameterSet::In);
            Parameter<Vector<Double> > returnval(inputRecord, "returnval",
						 ParameterSet::Out);
	    if (runMethod) {
	        returnval() = DOos::totalSize (pathName(), follow());
	    }
        }
    break;
    case 11:
        {
	    Parameter<Vector<String> > pathName(inputRecord, "pathname",
						ParameterSet::In);
	    Parameter<Bool> follow(inputRecord, "follow",
				   ParameterSet::In);
            Parameter<Vector<Double> > returnval(inputRecord, "returnval",
						 ParameterSet::Out);
	    if (runMethod) {
	        returnval() = DOos::freeSpace (pathName(), follow());
	    }
        }
    break;
    case 12:
        {
	    Parameter<String> target(inputRecord, "target",
				     ParameterSet::In);
	    Parameter<String> source(inputRecord, "source",
				     ParameterSet::In);
	    Parameter<Bool> overwrite(inputRecord, "overwrite",
				      ParameterSet::In);
	    Parameter<Bool> follow(inputRecord, "follow",
				   ParameterSet::In);
	    if (runMethod) {
	        DOos::copy (target(), source(), overwrite(), follow());
	    }
        }
    break;
    case 13:
        {
	    Parameter<String> target(inputRecord, "target",
				     ParameterSet::In);
	    Parameter<String> source(inputRecord, "source",
				     ParameterSet::In);
	    Parameter<Bool> overwrite(inputRecord, "overwrite",
				      ParameterSet::In);
	    Parameter<Bool> follow(inputRecord, "follow",
				   ParameterSet::In);
	    if (runMethod) {
	        DOos::move (target(), source(), overwrite(), follow());
	    }
        }
    break;
    case 14:
        {
	    Parameter<Vector<String> > pathName(inputRecord, "pathname",
						ParameterSet::In);
	    Parameter<Bool> recursive(inputRecord, "recursive",
				      ParameterSet::In);
	    Parameter<Bool> mustExist(inputRecord, "mustexist",
				      ParameterSet::In);
	    Parameter<Bool> follow(inputRecord, "follow",
				   ParameterSet::In);
	    if (runMethod) {
	        DOos::remove (pathName(), recursive(),
			      mustExist(), follow());
	    }
        }
    break;
    case 15:
        {
	    Parameter<String> tableName(inputRecord, "tablename",
					ParameterSet::In);
            Parameter<Vector<Int> > returnval(inputRecord, "returnval",
					      ParameterSet::Out);
	    if (runMethod) {
	        returnval() = DOos::lockInfo (tableName());
	    }
        }
    break;
    default:
        return error("Unknown method");
    }

    return ok();
}
