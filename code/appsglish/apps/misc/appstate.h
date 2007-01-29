//# appstate.h: for saving/restoring state in Glish applications.
//# Copyright (C) 1997-1998
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
//# $Id: appstate.h,v 19.5 2004/11/30 17:50:08 ddebonis Exp $

#ifndef APPSGLISH_APPSTATE_H
#define APPSGLISH_APPSTATE_H

#include <casa/aips.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <casa/Arrays/Vector.h>
#include <tasking/Glish/GlishRecord.h>
#include <casa/System/Aipsrc.h>

#include <casa/namespace.h>
// <summary>
// State-saving/restoring interface for Glish applications.
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> Distributed Objects
//   <li> Aipsrc
//   <li> Vectors
// </prerequisite>
//
// <etymology>
// "appstate" is short for "APPlication STATE."
// </etymology>
//
// <synopsis>
// This class provides a front-end to the Aipsrc class for saving and
// restoring state information within Glish applications.
//
// Currently, all state information is stored in:
// ~/aips++/parameters/<application>rc
// though this may be changed by various means.  [JAU: expand on this.]
// </synopsis>
//
// <example>
// include 'appstate.g';
//
// foo := appstate ();
// foo.init ('appname');			# Set name of application.
// foo.restore ();				# Read previous state.
//
// bar := foo.get (string, 'what.ever');	# Place value of what.ever
//						# in variable string.
//						# bar := T if found, F if
//						# not.  string also := F
//						# if not found.
//
// foo.set ('what.ever', 'Some value');		# Set what.ever to 2nd arg.
//
// foo.save ();					# Save current values.
//
// bar := foo.list ();				# bar := record containing
//						# all values for app.
//
// foo.unset ('what.ever');			# Remove definition of
//						# what.ever.
// </example>
//
// <motivation>
// We need a simple way of saving/restoring basic state information in
// Glish applications.
// </motivation>
//
// <todo asof="1998/05/07">
//   <li> More options for location of state file(s).
//   <li> Eliminate init() & have constructor take application name?
//   <li> Add a clear() function to reset application state?
// </todo>

class appstate : public ApplicationObject, private Aipsrc
{
public:
  appstate () {initialized = False;}
  ~appstate () {;}

  virtual String className () const;
  virtual Vector<String> methods () const;
  virtual Vector<String> noTraceMethods () const;
  virtual MethodResult runMethod (uInt which, ParameterSet &inputRecord,
				  Bool runMethod);

private:
  void init (const String &application);
  GlishRecord list ();
  Bool initialized;
  String stateDir;
  String stateFile;
  Vector<String> namlist;
  Vector<String> vallist;
};

#endif


// Local Variables:
// mode: c++
// End:
