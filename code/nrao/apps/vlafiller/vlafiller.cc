//# vlafiller.cc:
//# Copyright (C) 1999,2001
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
//# $Id: vlafiller.cc,v 19.12 2005/05/31 15:45:04 gli Exp $

#include <casa/aips.h>
#include <tasking/Tasking/ObjectController.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <DOvlafiller.h>
#include <nrao/VLA/VLAFillerTask.h>
#include <casa/Inputs.h>
#include <casa/Containers/RecordField.h>
#include <casa/namespace.h>

int CLvlafiller(int argc, char **argv);

int main(int argc, char **argv) {
  // this is a kludge - ObjectController needs to be changed to
  // optionally execute a function when there is no interpreter
  // present
  const Bool 
    hasInterpreter = ((argc > 6 && String(argv[6]).matches("-interpreter")) ||
		      (argc > 7 && String(argv[7]).matches("-interpreter")));
  if (hasInterpreter) {
    ObjectController controller(argc, argv);
    //controller.addMaker("vlafiller", new StandardObjectFactory<vlafiller>);
	 controller.addMaker("vlafiller", new vlafillerFactory());
    controller.loop();
    return 0;
  } else {
    return CLvlafiller(argc, argv);
  }
}

static void convert(Input &tpset, Record &pset) {
   try {
      RecordFieldPtr<String> inputfile(pset, RecordFieldId("inputfile"));
      inputfile.define(tpset.getString("input"));

      RecordFieldPtr<String> msname(pset, RecordFieldId("msname"));
      msname.define(tpset.getString("output"));

      RecordFieldPtr<Bool> overwrite(pset, RecordFieldId("overwrite"));
      overwrite.define(tpset.getBool("overwrite"));

      RecordFieldPtr<String> start(pset, RecordFieldId("start"));
      start.define(tpset.getString("starttime"));

      RecordFieldPtr<String> stop(pset, RecordFieldId("stop"));
      stop.define(tpset.getString("stoptime"));

      RecordFieldPtr<String> project(pset, RecordFieldId("project"));
      project.define(tpset.getString("project"));

      RecordFieldPtr<String> centerfreq(pset, RecordFieldId("centerfreq"));
      centerfreq.define(tpset.getString("centerfrequency"));

      RecordFieldPtr<String> bandwidth(pset, RecordFieldId("bandwidth"));
      bandwidth.define(tpset.getString("bandwidth"));

      RecordFieldPtr<String> calList(pset, RecordFieldId("calList"));
      calList.define(tpset.getString("source"));
   } catch (AipsError x) {
     cerr << x.getMesg() << endl;
     cout << "FAIL" << endl;
   } catch(...) {
     cerr << "Something really bad has happened" << endl;
   }
}

int CLvlafiller(int argc, char **argv) {
  try {
    VLAFillerTask task;
    Record pset(task.getParams());

    Input tpset(1);
    tpset.create("input", "",
                 "Input Archive ie., a file or device name");
    tpset.create("output", "",
                 "Output measurement set ie., a file name");
    tpset.create("overwrite", "F",
                 "Complain if the output file exists");
    tpset.create("files", "0",
                 "tape files to read, 0 -> next file");
    tpset.create("project", "",
                 "project name, blank -> all projects");
    tpset.create("starttime", "",
                 "start time, blank -> a long time ago");
    tpset.create("stoptime", "",
                 "stop time, blank -> a long time in the future");
    tpset.create("centerfrequency", "",
                 "center frequency in Hz, blank -> all frequencies");
    tpset.create("bandwidth", "",
                 "bandwidth in Hz, blank -> all frequencies");
    tpset.create("source", "",
                 "source name, blank -> all sources");
    tpset.create("qualifier", "",
                 "source name qualifier, blank -> all qualifiers");
    tpset.create("subarray", "",
                 "0 -> all subarrays");
    tpset.create("verbose", "T",
                 "print progress messages");
    tpset.readArguments (argc, argv);

    convert(tpset, pset);

    task.setParams(pset);
    task.fill();
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
// compile-command: "gmake OPTLIB=1 vlafiller"
// End: 
