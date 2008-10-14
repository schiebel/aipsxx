//# GBTFillerInputs.cc:  this handles the inputs for gbtfiller
//# Copyright (C) 1995,1996,1998,1999,2001
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
//# $Id: GBTFillerInputs.cc,v 19.3 2004/11/30 17:50:40 ddebonis Exp $

//# Includes

#include <GBTFillerInputs.h>
#include <casa/Inputs.h>
#include <casa/Arrays/IPosition.h>

#include <casa/namespace.h>
// this is a work around until the operator>> in Time is fixed to
// deal with leading zeros correctly

// I could just use the c library atoi, but this is probably appropriate
// although it clearly has problems - hopefully Time will be fixed
// before this needs to be checked in.

Int myatoi(const String& s)
{
   Int result = 0;
   Int factor = 1;
   const char zero = '0';
   const char nine = '9';
   uInt stopAt = 0;
   uInt startAt;
   Bool negative = False;

   if (s.length() > 0 && s.firstchar() == '-') {
       negative = True;
       stopAt = 1;
   }
   // skip any leading non-numerals
   for (;stopAt<s.length();stopAt++) {
       if (s[stopAt] >= zero) break;
   }

   // skip any trailing non-numerals
   for (startAt=s.length();startAt>0;startAt--) {
      if (s[startAt-1] >= zero) break;
   }

   // break out at the first non-numeric character
   for (uInt i=startAt;i>stopAt;i--) {
       if (s[i-1] < zero || s[i-1] > nine) break;
       result += (s[i-1]-zero) * factor;
       factor *= 10;
   }
   return result;
}


Time makeTime(const String &in)
{
    String s(in);

    // in has the form month/day/year,hour:min:sec
    uInt year=0, month=0, day=0, hour=0, min=0, sec=0;
    String sub;
    Int marker, position=0;

    // month, before the first slash
    marker = s.index("/", position);
    if (marker > position) {
	sub = s.at(position,(marker-position));
        month = uInt(myatoi(sub));
	position = marker + 1;
    }
    // day, until the next slash
    marker = s.index("/", position);
    if (marker > position) {
	sub = s.at(position,(marker-position));
	day = uInt(myatoi(sub));
	position = marker + 1;
    }
    // year, until the comma
    marker = s.index(",", position);
    if (marker > position) {
	sub = s.at(position,(marker-position));
	year = uInt(myatoi(sub));
	position = marker + 1;
    }
    // hour, until the next :
    marker = s.index(":",position);
    if (marker > position) {
	sub = s.at(position,(marker-position));
	hour = uInt(myatoi(sub));
	position = marker + 1;
    }
    // min, until the next :
    marker = s.index(":",position);
    if (marker > position) {
	sub = s.at(position,(marker-position));
	min = uInt(myatoi(sub));
	position = marker + 1;
    }
    // sec, everything that is left
    sub = s.from(position);
    sec = uInt(myatoi(sub));

    return Time(year, month, day, hour, min, Double(sec));
}

GBTFillerInputs::GBTFillerInputs(int argc, char ** argv) :
    inputs_p(0), start_time_p(1970,1,1), stop_time_p(3000,1,1),
    status_p(False)
{
    inputs_p = new Input(1);
    if (inputs_p == 0) {
	throw(AllocError("GBTFillerInputs::GBTFillerInputs(int argc, char **argv) : "
			 "could not allocate an Input object",1));
    }
    make_inputs();
    inputs_p->readArguments(argc, argv);

    // get the values from the inputs
    project_p = inputs_p->getString("project");
    backend_p = inputs_p->getString("backend");
    observer_p = inputs_p->getString("observer");
    table_p = File(inputs_p->getString("table_name"));
    String startTimeString = inputs_p->getString("start_time");
    String stopTimeString = inputs_p->getString("stop_time");
    if (!startTimeString.empty()) {
	start_time_p = makeTime(startTimeString);
    }
    if (!stopTimeString.empty()) {
	stop_time_p = makeTime(stopTimeString);
    }
    object_p = inputs_p->getString("object");
    set_status();
}

// this is useful, should possibly be a member fn of GlishArray
Bool isEmpty(GlishArray &garray)
{return (garray.shape().product() <= 0);}

GBTFillerInputs::GBTFillerInputs(GlishValue record) : 
    inputs_p(0), start_time_p(1970,1,1), stop_time_p(3000,1,1),
    status_p(False)
{
    // get the inputs from record, do default values if not there
    // this needs to be better coordinated with the default values in
    // make_inputs()
    GlishRecord values(record);

    if (values.exists("project")) {
	GlishArray gproject = values.get("project");
	if (!isEmpty(gproject)) {
	    gproject.get(project_p);
	}
    }

    if (values.exists("observer")) {
	GlishArray gobserver = values.get("observer");
	if (!isEmpty(gobserver)) {
	    gobserver.get(observer_p);
	}
    }

    if (values.exists("backend")) {
	GlishArray gbackend = values.get("backend");
	if (!isEmpty(gbackend)) {
	    gbackend.get(backend_p);
	}
    }

    String tableName;
    if (values.exists("table_name")) {
        GlishArray gtableName = values.get("table_name");
        if (!isEmpty(gtableName)) {
           gtableName.get(tableName);
	 }
    }
    table_p = File(tableName);

    String startTimeString, stopTimeString;
    if (values.exists("start_time")) {
	GlishArray gstartTime = values.get("start_time");
	if (!isEmpty(gstartTime)) {
	    gstartTime.get(startTimeString);
	}
    }

    if (!startTimeString.empty()) {
	start_time_p = makeTime(startTimeString);
    }

    if (values.exists("stop_time")) {
	GlishArray gstopTime = values.get("stop_time");
	if (!isEmpty(gstopTime)) {
	    gstopTime.get(stopTimeString);
	}
    }
    if (!stopTimeString.empty()) {
	stop_time_p = makeTime(stopTimeString);
    }

    if (values.exists("object")) {
	GlishArray gobject = values.get("object");
	if (!isEmpty(gobject)) {
	    gobject.get(object_p);
	}
    }

    set_status();
}

GBTFillerInputs::~GBTFillerInputs()
{
    delete inputs_p;
}

void GBTFillerInputs::set_status() 
{
    if (object_p.empty()) object_p = "*";
    objectRegex_p = Regex::fromPattern(object_p);

    if (project_p.empty() || backend_p.empty()) {
	errMsg_p =  "project and/or backend has not been specified";
	status_p = False;
    } else {
	errMsg_p = "";
	status_p = True;
	// set up project_directory_p
	File file(project());
	if (! file.isDirectory()) {
	    errMsg_p = project() + " is not a directory.";
	    status_p = False;
	} else {
	    project_directory_p = file;
	    backendName_p = project() + "/" + backend();
	    File back(backendName_p);
	    if (! back.isDirectory()) {
	        errMsg_p = backend() + " is not a valid backend.";
		status_p = False;
	    }

	    // if table_p was specified with an empty string
	    // construct a meaningfull one

	    if (status_p && table_p.path().originalName().empty() ||
		table_p.path().originalName() == ".") {
	      table_p = File(projectDir().path().baseName() + "_" +
			     backend() + ".table");
	    }
	}
    }
}

void GBTFillerInputs::make_inputs() 
{
    inputs_p->create("project",
		     "",
		     "The project identifier",
		     "String");
    inputs_p->create("observer",
		     "",
		     "The observer",
		     "String");
    inputs_p->create("backend",
		     "",
		     "The backend identifier",
		     "String");
    inputs_p->create("table_name",
                     "",
                     "The name of the table",
                     "String");
    inputs_p->create("start_time",
		     "",
		     "The start time for filling",
		     "String");
    inputs_p->create("stop_time",
		     "",
		     "The stop time for filling",
		     "String");
    inputs_p->create("object",
		     "",
		     "Object to search for, allows for wildcards",
		     "String");
}


