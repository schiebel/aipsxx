//# GBTFillerInputs.h: handles the inputs for gbtfiller
//# Copyright (C) 1995,1999
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
//# $Id: GBTFillerInputs.h,v 19.4 2004/11/30 17:50:40 ddebonis Exp $

#ifndef NRAO_GBTFILLERINPUTS_H
#define NRAO_GBTFILLERINPUTS_H

#include <casa/aips.h>
#include <tasking/Glish.h>
#include <casa/BasicSL/String.h>
#include <casa/Utilities/Regex.h>
#include <casa/OS/File.h>
#include <casa/OS/Time.h>
#include <casa/OS/Directory.h>

#include <casa/namespace.h>
//# Forward Declarations
namespace casa { //# NAMESPACE CASA - BEGIN
class Input;
} //# NAMESPACE CASA - END

// <summary>
// </summary>

// <use visibility=local> 

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//
// <thrown>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
// </todo>

class GBTFillerInputs
{
public:

    GBTFillerInputs(int argc, char ** argv);
    GBTFillerInputs(GlishValue record);

    ~GBTFillerInputs();

    Bool ok() const {return status_p;}

    const String& errorMsg() const {return errMsg_p;}

    const String& project() const {return project_p;}
    const String& observer() const {return observer_p;}
    const String& backend() const {return backend_p;}
    const File& tableFile() const {return table_p;}
    const Time& startTime() const {return start_time_p;}
    const Time& stopTime() const {return stop_time_p;}
    const String& backendName() const {return backendName_p;}
    const Directory& projectDir() const {return project_directory_p;}
    const String& object() const {return object_p;}
    const Regex& objectRegex() const {return objectRegex_p;}
    const Input &inputs() const {return *inputs_p;}

private:

    Input *inputs_p;

    String project_p, observer_p, backend_p, errMsg_p, backendName_p;
    File table_p;
    Time start_time_p, stop_time_p;
    Bool status_p;
    String object_p;
    Regex objectRegex_p;

    Directory project_directory_p;

    // Inaccessible and unavailable
    GBTFillerInputs();
    GBTFillerInputs(const GBTFillerInputs &other);
    GBTFillerInputs operator=(const GBTFillerInputs &other);

    void make_inputs();
    void set_status();
};

#endif


