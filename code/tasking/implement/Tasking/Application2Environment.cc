//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,1998,2000,2001,2002,2003
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
//# $Id: Application2Environment.cc,v 19.8 2005/12/06 20:18:51 wyoung Exp $

#include <tasking/Tasking/ApplicationEnvironment.h>
#include <casa/System/PGPlotter.h>
#include <graphics/Graphics/PGPlotterLocal.h>
#include <tasking/Tasking/PGPlotterGlish.h>
#include <casa/System/Aipsrc.h>
#include <casa/Arrays/Vector.h>
#include <casa/OS/EnvVar.h>
#include <casa/OS/File.h>
#include <casa/OS/RegularFile.h>
#include <casa/Utilities/Regex.h>

#include <casa/Logging/LogIO.h>
#include <casa/Utilities/Assert.h>
#include <casa/Exceptions/Error.h>

#include <casa/sstream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

void ApplicationEnvironment::registerPGPlotter()
{
    // Set the static PGPlotter create function.
    PGPlotter::setCreateFunction (ApplicationEnvironment::createPlotter);
}

PlotDevice ApplicationEnvironment::defaultPlotter(const ObjectID &)
{
    PlotDevice plotter;

    // Force a reread of aipsrc variables in case the user is using them
    // to change plot devices interactively.
    Aipsrc::reRead();

    Aipsrc::find(plotter, "user.plot.device", "aipsplot_?.plot/glish");

    if (plotter.contains("/glish") || plotter.contains("/GLISH")) {
	if (!objectController()) {
	    plotter = "/xs"; // Alas, try X
	}
    }

    if (plotter == "/XS" || plotter == "/xs") {
	// Make sure that we have a DISPLAY environment variable. If not, use
	// /NULL.
	// Who knows why the strdup is necessary!
 	String display(EnvironmentVariable::get("DISPLAY"));
 	if (display.empty()) {
	    // Alas, try colour postscript
 	    plotter = "aipsplot_?/cps";
 	}
    }

    Regex device("/[a-zA-Z]*$");
    String originalfile = plotter.before(device);
    String file = originalfile;
    if (file != "") {
	String question = "?";
	uInt count = 0;
	if (originalfile.contains(question)) {
	    while (++count) {
		ostringstream str;
		str << count;
		file = originalfile;
		file.gsub(question, String(str));
		if (!File(file).exists()) {
		    // Cool, we finally found a unique name
		    break;
		}
	    }
	}
	// OK, "touch" the file to make sure that nobody else tries to
	// take it. Subject to a slight race condition.
	plotter.gsub(originalfile, file);
	RegularFile newfile(file);
	try {
	    newfile.create(False);
	} catch (AipsError x) {
	    LogIO os(LogOrigin("ApplicationEnvironment", "defaultPlotter",
			       WHERE));
	    os << LogIO::SEVERE << "Cannot create file " << plotter <<
		" using /NULL plot device." << LogIO::POST;
	    plotter = "/NULL";
	} 
    }

    return plotter;
}

PGPlotter ApplicationEnvironment::getPlotter(const PlotDevice &device)
{
    return PGPlotter::create (device);
}

PGPlotter ApplicationEnvironment::createPlotter(const String &device,
						uInt mincolors, uInt maxcolors,
						uInt sizex, uInt sizey)
{
    LogIO os(LogOrigin("ApplicationEnvironment", "createPlotter", WHERE));

    Regex glish("/[Gg][Ll][Ii][Ss][Hh]");
    PGPlotterInterface *worker = 0;

    if (maxcolors < mincolors) maxcolors = mincolors; // Fix silently
    if (mincolors < 2) {
	os << "PGPlotter::PGPlotter - require at least 2 colors" << 
	    LogIO::EXCEPTION;
    }
    if (device.contains(glish)) {
	String name = device;
	name.gsub(glish, "");
	worker = new PGPlotterGlish(name, mincolors, maxcolors, sizex, sizey);
    } else {
	worker = new PGPlotterLocal(device);
    }
    AlwaysAssert(worker != 0, AipsError);

    Vector<Int> colors = worker->qcol();
    uInt ncol = colors(1) - colors(0) + 1;
    if (ncol < mincolors) {
	os << LogIO::WARN << "Could not open device with at least " <<
	    mincolors << " colors (got " << ncol << ")" << LogIO::POST;
	worker = 0; // Detach
    }
    return PGPlotter(worker);
}

} //# NAMESPACE CASA - END

