//# DOVLAFiller.cc:
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
//# $Id: DOvlafiller.cc,v 19.7 2005/05/26 21:32:13 gli Exp $

#include <DOvlafiller.h>
#include <nrao/VLA/VLAArchiveInput.h>
#include <nrao/VLA/VLACalibratorFilter.h>
#include <nrao/VLA/VLADiskInput.h>
#include <nrao/VLA/VLAFiller.h>
#include <nrao/VLA/VLAFrequencyFilter.h>
#include <nrao/VLA/VLAOnlineInput.h>
#include <nrao/VLA/VLAProjectFilter.h>
#include <nrao/VLA/VLASourceFilter.h>
#include <nrao/VLA/VLASubarrayFilter.h>
#include <nrao/VLA/VLATapeInput.h>
#include <nrao/VLA/VLATimeFilter.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/Parameter.h>
#include <casa/Arrays/Vector.h>
#include <casa/Containers/Block.h>
#include <casa/Exceptions/Error.h>
#include <casa/Quanta/MVFrequency.h>
#include <casa/Quanta/Quantum.h>
#include <casa/Quanta/Unit.h>
#include <casa/BasicSL/Constants.h>
#include <casa/BasicMath/Math.h>
#include <casa/OS/Directory.h>
#include <casa/OS/File.h>
#include <casa/OS/Path.h>
#include <casa/OS/SymLink.h>
#include <casa/Utilities/Assert.h>
#include <ms/MeasurementSets/MSHistoryHandler.h>

vlafiller::vlafiller( Double freqTolerance )
  :itsDataInput(),
   itsInputFilter(),
   itsOutput(),
	itsFreqTolerance( freqTolerance )
{
  itsInputFilter.addFilter(VLAProjectFilter());
  itsInputFilter.addFilter(VLATimeFilter());
  itsInputFilter.addFilter(VLAFrequencyFilter());
  itsInputFilter.addFilter(VLASourceFilter());
  itsInputFilter.addFilter(VLASubarrayFilter());
  itsInputFilter.addFilter(VLACalibratorFilter());
  itsSourceOfData="";
  DebugAssert(DOok(), AipsError);
}

vlafiller::vlafiller(const vlafiller& other)
  :itsDataInput(other.itsDataInput),
   itsInputFilter(other.itsInputFilter),
   itsOutput(other.itsOutput), itsSourceOfData(other.itsSourceOfData),
	itsFreqTolerance(other.itsFreqTolerance)
{
  DebugAssert(DOok(), AipsError);
}

vlafiller::~vlafiller() {
}

vlafiller& vlafiller::operator=(const vlafiller& other) {
  if (this != &other) {
    itsDataInput = other.itsDataInput;
    itsInputFilter = other.itsInputFilter;
    itsOutput = other.itsOutput;
    itsSourceOfData=other.itsSourceOfData;
	 itsFreqTolerance=other.itsFreqTolerance;
  }
  DebugAssert(DOok(), AipsError);
  return *this;
}

Bool vlafiller::tapeinput(const String& device, const Vector<Int>& files) {
  const uInt nFiles = files.nelements();
  if (nFiles == 0) throw(AipsError("No tape file number specified."));
  Block<uInt> tapeFiles(nFiles);
  for (uInt i = 0; i < nFiles; i++) {
    if (files(i) < 0) throw(AipsError("A tape file number is negative."));
    tapeFiles[i] = files(i);
  }
  Path tapeName(device);
  String errorMessage;
  if (!checkName(errorMessage, tapeName)) {
    throw(AipsError(String("The specified tape ") + errorMessage));
  }
  if (!File(tapeName).isCharacterSpecial()) {
    throw(AipsError(String("The specified tape drive (") + 
		    tapeName.originalName() + 
		    String(") is not a device.")));
  }
  // This statement is necessary as it closes the tape device. This prevents
  // problems when trying to open a tape device that has already been opened.
  if (itsDataInput.isValid()) itsDataInput = VLALogicalRecord();
  itsDataInput = VLALogicalRecord(new VLATapeInput(tapeName, tapeFiles));
  itsSourceOfData = "Filled from tape";
  return True;
}

Bool vlafiller::diskinput(const String& filename) {
  Path fileName(filename);
  String errorMessage;
  if (!checkName(errorMessage, fileName)) {
    throw(AipsError(String("The specified file ") + errorMessage));
  }
  if (!File(fileName).isRegular()) {
    throw(AipsError(String("The specified file (") + 
		    fileName.originalName() + 
		    String(") is not a plain file. Is it a directory?")));
  }
  itsDataInput = VLALogicalRecord(new VLADiskInput(fileName));
  itsSourceOfData = "Filled from file " + filename;
  return True;
}

Bool vlafiller::onlineinput() {
  itsDataInput = VLALogicalRecord(new VLAOnlineInput());
  itsSourceOfData ="Filled from online system";
  return True;
}

Bool vlafiller::output(const String& msname, Bool overwrite) {
  Path fileName(msname);
  if (!fileName.isValid()) {
    throw(AipsError(String("The output measurement set name (") +
		    fileName.originalName() +
		    String(") is malformed.")));
  }
  File file(fileName);
  if (file.exists()) {
    if (!file.isWritable()) {
      throw(AipsError(String("The output measurement set name (") +
		      fileName.originalName() +
		      String(") is not writable.")));
    }
  } else {
    if (!file.canCreate()) {
      throw(AipsError(String("The output measurement set name (") +
		      fileName.originalName() +
		      String(") cannot be created.")));
    }
  }
  if (!itsOutput.isNull() && 
      fileName.absoluteName().matches
      (Path(itsOutput.tableName()).absoluteName())) {
    // Close the table to prevent trying to open a Table that is already open
    itsOutput = MeasurementSet();
  }
  itsOutput = VLAFiller::getMS(fileName, overwrite);
  return True;
}

Bool vlafiller::selectproject(const String& project) {
  VLAFilterSet newFilter;
  newFilter.addFilter(VLAProjectFilter(project));
  newFilter.addFilter(itsInputFilter.filter(1));
  newFilter.addFilter(itsInputFilter.filter(2));
  newFilter.addFilter(itsInputFilter.filter(3));
  newFilter.addFilter(itsInputFilter.filter(4));
  newFilter.addFilter(itsInputFilter.filter(5));
  itsInputFilter = newFilter;
  return True;
}

Bool vlafiller::selecttime(const MVEpoch& start, const MVEpoch& stop) {
  VLAFilterSet newFilter;
  newFilter.addFilter(itsInputFilter.filter(0));
  newFilter.addFilter(VLATimeFilter(start, stop));
  newFilter.addFilter(itsInputFilter.filter(2));
  newFilter.addFilter(itsInputFilter.filter(3));
  newFilter.addFilter(itsInputFilter.filter(4));
  newFilter.addFilter(itsInputFilter.filter(5));
  itsInputFilter = newFilter;
  return True;
}

Bool vlafiller::selectfrequency(const MVFrequency& refFrequency,
				const MVFrequency& bandwidth) {
  VLAFilterSet newFilter;
  newFilter.addFilter(itsInputFilter.filter(0));
  newFilter.addFilter(itsInputFilter.filter(1));
  newFilter.addFilter(VLAFrequencyFilter(refFrequency, bandwidth));
  newFilter.addFilter(itsInputFilter.filter(3));
  newFilter.addFilter(itsInputFilter.filter(4));
  newFilter.addFilter(itsInputFilter.filter(5));
  itsInputFilter = newFilter;
  return True;
}

Bool vlafiller::selectsource(const String& source, Int qualifier) {
  if (abs(qualifier) > SHRT_MAX) {
    qualifier = INT_MIN;
  }
  VLAFilterSet newFilter;
  newFilter.addFilter(itsInputFilter.filter(0));
  newFilter.addFilter(itsInputFilter.filter(1));
  newFilter.addFilter(itsInputFilter.filter(2));
  newFilter.addFilter(VLASourceFilter(source, qualifier));
  newFilter.addFilter(itsInputFilter.filter(4));
  newFilter.addFilter(itsInputFilter.filter(5));
  itsInputFilter = newFilter;
  return True;
}

Bool vlafiller::selectsubarray(const Int subarrayId) {
  if (subarrayId < 0) {
    throw(AipsError("The subarray id must be positive."));
  }
  
  VLAFilterSet newFilter;
  newFilter.addFilter(itsInputFilter.filter(0));
  newFilter.addFilter(itsInputFilter.filter(1));
  newFilter.addFilter(itsInputFilter.filter(2));
  newFilter.addFilter(itsInputFilter.filter(3));
  newFilter.addFilter(VLASubarrayFilter(static_cast<const uInt>(subarrayId)));
  newFilter.addFilter(itsInputFilter.filter(5));
  itsInputFilter = newFilter;
  return True;
}

Bool vlafiller::selectcalibrator(const String& calcode) {
  if (calcode.length() != 1) {
    throw(AipsError("The calcode must be a string of length one."));
  }
  VLAFilterSet newFilter;
  newFilter.addFilter(itsInputFilter.filter(0));
  newFilter.addFilter(itsInputFilter.filter(1));
  newFilter.addFilter(itsInputFilter.filter(2));
  newFilter.addFilter(itsInputFilter.filter(3));
  newFilter.addFilter(itsInputFilter.filter(4));
  newFilter.addFilter(VLACalibratorFilter(calcode.elem(0)));
  itsInputFilter = newFilter;
  return True;
}

Bool vlafiller::fill(Bool verbose) {
  if (!itsDataInput.isValid()) {
    throw(AipsError("The input data source has not been specified."));
  }
  if (itsOutput.isNull()) {
    throw(AipsError("The output measurement set has not been specified."));
  }
  VLAFiller filler(itsOutput, itsDataInput, itsFreqTolerance);
  filler.setFilter(itsInputFilter);
  const Int iverbose = verbose ? 1 : 0;
  filler.fill(iverbose);
  MSHistoryHandler::addMessage(itsOutput, itsSourceOfData, "vlafiller");
  itsDataInput = VLALogicalRecord();
  return True;
}

Bool vlafiller::DOok() const {
  return True;
}

Bool vlafiller::checkName(String& errorMessage, Path& fileName) {
  if (!fileName.isValid()) {
    errorMessage = "name (" + fileName.originalName() + ") is malformed.";
    return False;
  }
  File file(fileName);
  if (!file.exists()) {
    errorMessage = "(" + fileName.originalName() + ") does not exist";
    return False;
  }
  if (file.isSymLink()) {
    SymLink link(file);
    fileName = link.followSymLink();
    file = File(fileName);
    if (!file.exists()) {
      errorMessage = "(" +  fileName.originalName() + 
	") does not link to anywhere.";
      return False;
    }
  } 
  if (!file.isReadable()) {
      errorMessage = "(" +  fileName.originalName() + ") is not readable.";
    return False;
  }
  return True;
}
  
String vlafiller::className() const {
  return "vlafiller";
}

Vector<String> vlafiller::methods() const {
  Vector<String> method(NUM_METHODS);
  method(TAPEINPUT) = "tapeinput";
  method(DISKINPUT) = "diskinput";
  method(ONLINEINPUT) = "onlineinput";
  method(OUTPUT) = "output";
  method(FILL) = "fill";
  method(SELECTPROJECT) = "selectproject";
  method(SELECTTIME) = "selecttime";
  method(SELECTFREQUENCY) = "selectfrequency";
  method(SELECTSOURCE) = "selectsource";
  method(SELECTSUBARRAY) = "selectsubarray";
  method(SELECTCALIBRATOR) = "selectcalibrator";
  return method;
}

MethodResult vlafiller::runMethod(uInt which,
				  ParameterSet& parameters, 
				  Bool runMethod) {
  static const String bandwidthName = "bandwidth";
  static const String calcodeName = "calcode";
  static const String deviceName = "device";
  static const String filenameName = "filename";
  static const String filesName = "files";
  static const String msnameName = "msname";
  static const String overwriteName = "overwrite";
  static const String projectName = "project";
  static const String qualifierName = "qualifier";
  static const String refFrequencyName = "centerfrequency";
  static const String returnvalName = "returnval";
  static const String sourceName = "source";
  static const String startName = "start";
  static const String subarrayName = "subarray";
  static const String stopName = "stop";
  static const String verboseName = "verbose";
  switch (which) {
  case TAPEINPUT: {
    const Parameter<String> device(parameters, deviceName, 
				   ParameterSet::In);
    const Parameter<Vector<Int> > files(parameters, filesName, 
					ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = tapeinput(device(), files());
    }
  }
  break;
  case DISKINPUT: {
    const Parameter<String> filename(parameters, filenameName, 
				   ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = diskinput(filename());
    }
  }
  break;
  case ONLINEINPUT: {
    Parameter<Bool> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = onlineinput();
    }
  }
  break;
  case OUTPUT: {
    const Parameter<String> msname(parameters, msnameName, 
				   ParameterSet::In);
    const Parameter<Bool> overwrite(parameters, overwriteName, 
				    ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = output(msname(), overwrite());
    }
  }
  break;
  case FILL: {
    const Parameter<Bool> verbose(parameters, verboseName, 
				  ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = fill(verbose());
    }
  }
  break;
  case SELECTPROJECT: {
    const Parameter<String> project(parameters, projectName, 
				    ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = selectproject(project());
    }
  }
  break;
  case SELECTTIME: {
    const Parameter<Quantum<Double> > start(parameters, startName, 
					    ParameterSet::In);
    const Parameter<Quantum<Double> > stop(parameters, stopName, 
					   ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      const Quantum<Double>& t0 = start();
      if (t0.getFullUnit() != Unit("s")) {
	return error("start time must be in units with the same dimensions "
		     "as the day");
      }
      const Quantum<Double>& t1 = stop();
      if (t1.getFullUnit() != Unit("s")) {
	return error("stop time must be in units with the same dimensions "
		     "as the day");
      }
      returnval() = selecttime(MVEpoch(t0), MVEpoch(t1));
    }
  }
  break;
  case SELECTFREQUENCY: {
    const Parameter<Quantum<Double> > refFrequency(parameters,
						   refFrequencyName, 
						   ParameterSet::In);
    const Parameter<Quantum<Double> > bandwidth(parameters, bandwidthName, 
						ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      const Quantum<Double>& f0 = refFrequency();
      if (f0.getFullUnit() != Unit("Hz")) {
	return error("The reference frequency must be in units with the "
		     "same dimensions as the Hertz");
      }
      const Quantum<Double>& bw = bandwidth();
      if (bw.getFullUnit() != Unit("Hz")) {
	return error("bandwidth must be in units with the same dimensions "
		     "as the Hertz");
      }
      returnval() = selectfrequency(MVFrequency(f0), MVFrequency(bw));
    }
  }
  break;
  case SELECTSOURCE: {
    const Parameter<String> source(parameters, sourceName, 
				   ParameterSet::In);
    const Parameter<Int> qualifier(parameters, qualifierName, 
				   ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = selectsource(source(), qualifier());
    }
  }
  break;
  case SELECTSUBARRAY: {
    const Parameter<Int> subarray(parameters, subarrayName, 
				  ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = selectsubarray(subarray());
    }
  }
  break;
  case SELECTCALIBRATOR: {
    const Parameter<String> calcode(parameters, calcodeName, 
				    ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = selectcalibrator(calcode());
    }
  }
  break;
  default:
    return error("Unknown method");
  }
  return ok();
}

Vector<String> vlafiller::noTraceMethods() const {
  return methods();
}
// Local Variables: 
// compile-command: "gmake DOvlafiller"
// End: 
MethodResult vlafillerFactory::make (ApplicationObject*& newObject,
                      const String& whichConstructor,
                      ParameterSet& inpRec,
                      Bool runConstructor) {
   // Intialization
   MethodResult retval;
   newObject = 0;

   // Case (constructor_type) of:
   if (whichConstructor == "vlafiller") {
      Parameter <Double> freqTolerance (inpRec, "freqTolerance", ParameterSet::In);
      if (runConstructor) {
         newObject = new vlafiller ( freqTolerance() );
       }
    } else {
      retval = String ("Unknown constructor ") + whichConstructor;
    };

   if (retval.ok() && runConstructor && !newObject) {
      retval = "Memory allocation error";
    };
   return retval;
}

