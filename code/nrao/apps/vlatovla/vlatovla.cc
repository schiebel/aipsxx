//# vlatovla.cc:
//# Copyright (C) 2000,2001,2003
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
//# $Id: vlatovla.cc,v 19.4 2004/11/30 17:50:41 ddebonis Exp $

#include <casa/aips.h>
#include <casa/Exceptions/Error.h>
#include <casa/BasicSL/String.h>
#include <casa/iostream.h>

#include <casa/Inputs/Input.h>
#include <casa/OS/File.h>
#include <casa/OS/Path.h>
#include <casa/OS/RegularFile.h>
#include <casa/IO/RegularFileIO.h>
#include <casa/OS/SymLink.h>
#include <casa/Quanta/MVEpoch.h>
#include <casa/Quanta/MVTime.h>
#include <casa/Utilities/Assert.h>
#include <nrao/VLA/VLADiskInput.h>
#include <nrao/VLA/VLALogicalRecord.h>
#include <nrao/VLA/VLAFilterSet.h>
#include <nrao/VLA/VLAProjectFilter.h>
#include <nrao/VLA/VLATimeFilter.h>

#include <casa/namespace.h>
int main(int argc, char** argv) {
  try {
    VLALogicalRecord logRec;
    VLADiskInput* diskIn;
    VLAFilterSet filters;
    Block<uChar> buffer;
    Input inputs(1);
    inputs.create("input", "",
		  "File name of the input VLA archive");
    inputs.create("project", "",
		  "which project to copy, blank -> all projects");
    inputs.create("output", "",
		  "File name of the output VLA archive");
    inputs.create("overwrite", "F",
		  "Complain if the output file exists");
    inputs.create("starttime", "",
	          "start time, blank -> a long time ago");
    inputs.create("stoptime", "",
	          "stop time, blank -> a long time in the future");

    inputs.readArguments (argc, argv);
    
    Path fileName = inputs.getString("output");
    AlwaysAssert(fileName.isValid(), AipsError);
    RegularFile file(fileName);
    ByteIO::OpenOption option = ByteIO::New;
    if (inputs.getBool("overwrite") == False) {
      if (file.exists()) {
	option = ByteIO::Update;
      } else {
	option = ByteIO::NewNoReplace;
      }
    }
    RegularFileIO sink(file, option);
    sink.seek(0, ByteIO::End);
    fileName = inputs.getString("input");
    AlwaysAssert(fileName.isValid(), AipsError);
    file = RegularFile(fileName);
    AlwaysAssert(file.exists(), AipsError);
    diskIn = new VLADiskInput(fileName);
    logRec = VLALogicalRecord(diskIn);
    RegularFileIO source(file);
    const String project = inputs.getString("project");
    if (! project.empty()) {
      filters.addFilter(VLAProjectFilter(project));
    }
    {
       VLATimeFilter tf;
       Quantum<Double> t;
       Bool timeFiltering = False;
       const String startTime = inputs.getString("starttime");
       if (! startTime.empty()) {
          if (MVTime::read(t, startTime)) {
             tf.startTime(MVEpoch(t));
             timeFiltering = True;
          } else {
             throw(AipsError("Cannot parse the start time"));
          }
       }
       const String stopTime = inputs.getString("stoptime");
       if (! stopTime.empty()) {
          if (MVTime::read(t, stopTime)) {
             tf.stopTime(MVEpoch(t));
             timeFiltering = True;
          } else {
             throw(AipsError("Cannot parse the stop time"));
          }
       }
       if (timeFiltering) filters.addFilter(tf);
    }

    uInt prevPos = diskIn->bytesRead();
    uInt recordsCopied = 0;
    while (logRec.read()) {
      if (filters.passThru(logRec)) {
 	const uInt curPos = diskIn->bytesRead();
 	const uInt length = curPos - prevPos;
 	buffer.resize(length);
 	source.seek(Int64(prevPos));
 	source.read(length, buffer.storage());
 	sink.write(length, buffer.storage());
	recordsCopied++;
      }
      prevPos = diskIn->bytesRead();
    }
  }
  catch (AipsError x) {
    cerr << x.getMesg() << endl;
    cout << "FAIL" << endl;
    return 1;
  }
  catch (...) {
    cerr << "Exception not derived from AipsError" << endl;
    cout << "FAIL" << endl;
    return 2;
  }
  return 0;
}
// Local Variables: 
// compile-command: "gmake OPT=1 vlatovla"
// End: 
