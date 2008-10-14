//# appstate.cc: Class/DO to save and restore state in Glish applications.
//# Copyright (C) 1997-1998,2000,2001,2002
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
//# $Id: appstate.cc,v 19.3 2004/11/30 17:50:08 ddebonis Exp $

#include <../misc/appstate.h>
#include <casa/Exceptions.h>
#include <casa/OS/Directory.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/Parameter.h>
#include <casa/iostream.h>


#include <casa/namespace.h>
// Need to decide where to look for these files, and where to default to
// for creating new ones.
//
// Also: eliminate init() & have constructor handle this?
void appstate::init (const String &application)
{
  stateDir = Aipsrc::aipsHome () + String ("/parameters");
  stateFile = stateDir + String ("/") + application + String ("rc");
  initialized = True;
}

GlishRecord appstate::list ()
{
  GlishRecord record;

  for (Int i = namlist.nelements () - 1; i >= 0; i--) {
    record.add (namlist(i).chars(), vallist(i).chars());
  }
  return record;
}

// Required routines for DO linkage.

String appstate::className () const
{
  return "appstate";
}

Vector<String> appstate::methods () const
{
  Vector<String> names(7);
  names (0) = "restore";
  names (1) = "get";
  names (2) = "set";
  names (3) = "save";
  names (4) = "init";
  names (5) = "list";
  names (6) = "unset";

  return names;
}

Vector<String> appstate::noTraceMethods () const
{
  Vector<String> names(7);
  names (0) = "restore";
  names (1) = "get";
  names (2) = "set";
  names (3) = "save";
  names (4) = "init";
  names (5) = "list";
  names (6) = "unset";

  return names;
}

MethodResult appstate::runMethod (uInt which, ParameterSet &inputRecord,
				  Bool runMethod)
{
  switch (which)
    {
    case 0:			// restore.
      if (runMethod) {
	if (!initialized) {
	  return error ("Not initialized");
	}
	genRestore (namlist, vallist, stateFile);
      }
      break;

    case 1:			// get.
      {
	static String returnvalString = "returnval";
	static String valueString = "value";
	static String keywordString = "keyword";

	Parameter<Bool> returnval (inputRecord, returnvalString,
				   ParameterSet::Out);
	Parameter<String> value (inputRecord, valueString, ParameterSet::Out);
	Parameter<String> keyword (inputRecord, keywordString,
				   ParameterSet::In);
	if (runMethod) {
	  if (!initialized) {
	    return error ("Not initialized");
	  }
	  returnval () = genGet (value (), namlist, vallist, keyword ());
	}
      }
      break;

    case 2:			// set.
      {
	static String valueString = "value";
	static String keywordString = "keyword";

	Parameter<String> keyword (inputRecord, keywordString,
				   ParameterSet::In);
	Parameter<String> value (inputRecord, valueString, ParameterSet::In);

	if (runMethod) {
	  if (!initialized) {
	    return error ("Not initialized");
	  }
	  genSet (namlist, vallist, keyword (), value ());
	}
      }
      break;

    case 3:			// save.
      if (runMethod) {
	if (!initialized) {
	  return error ("Not initialized");
	}
	File stateDirF (stateDir);

	if (!stateDirF.isDirectory ()) {
	  try {
	    Directory stateDirD (stateDir);
	    stateDirD.create (False); // Don't zorch things.
	  } catch (AipsError x) {
	    // 	    os << "Exception: " << x.getMesg () << LogIO::EXCEPTION;
	    cerr << "Cannot save state: " << x.getMesg () << endl;
	    return error ("Cannot save state");
	  } 
	}
	genSave (namlist, vallist, stateFile); // Need a catch here too.
      }
      break;

    case 4:			// init.
      {
	static String applicationString = "application";

	Parameter<String> application (inputRecord, applicationString,
				       ParameterSet::In);
	if (runMethod) {
	  init (application ());
	}
      }
      break;

    case 5:			// list.
      {
	static String returnvalString = "returnval";

	Parameter<GlishRecord> returnval (inputRecord, returnvalString,
					  ParameterSet::Out);
	if (runMethod) {
	  if (!initialized) {
	    return error ("Not initialized");
	  }
	  returnval () = list ();
	}
      }
      break;

    case 6:			// unset.
      {
	static String returnvalString = "returnval";
	static String keywordString = "keyword";

	Parameter<Bool> returnval (inputRecord, returnvalString,
				   ParameterSet::Out);
	Parameter<String> keyword (inputRecord, keywordString,
				   ParameterSet::In);
	if (runMethod) {
	  if (!initialized) {
	    return error ("Not initialized");
	  }
	  returnval () = genUnSet (namlist, vallist, keyword ());
	}
      }
      break;

    default:
      return error ("Unknown method");
    }
  return ok ();
}
