//# DOcomponentlist.cc:  this defines DOcomponentlist.cc
//# Copyright (C) 1997,1998,1999,2000,2001,2003
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
//# $Id: DOcomponentlist.cc,v 19.8 2006/06/02 00:56:25 mvoronko Exp $

#include <appsglish/componentlist/DOcomponentlist.h>
#include <components/ComponentModels/ComponentShape.h>
#include <components/ComponentModels/ComponentType.h>
#include <components/ComponentModels/ConstantSpectrum.h>
#include <components/ComponentModels/Flux.h>
#include <components/ComponentModels/SkyComponent.h>
#include <components/ComponentModels/SpectralModel.h>
#include <tasking/Tasking/ApplicationEnvironment.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/NewFileConstraint.h>
#include <tasking/Tasking/ObjectController.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterSet.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/Vector.h>
#include <casa/Containers/Record.h>
#include <casa/Containers/RecordFieldId.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <casa/Logging/LogIO.h>
#include <casa/Logging/LogOrigin.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MFrequency.h>
#include <casa/OS/Path.h>
#include <casa/Utilities/MUString.h>
#include <casa/Quanta/MVAngle.h>
#include <casa/Quanta/MVDirection.h>
#include <casa/Quanta/MVFrequency.h>
#include <casa/Quanta/Quantum.h>
#include <casa/Quanta/Unit.h>
#include <casa/Quanta/UnitVal.h>
#include <tasking/Tasking/Index.h>
#include <casa/System/ObjectID.h>
#include <casa/Utilities/Assert.h>
#include <casa/BasicSL/String.h>
#include <casa/sstream.h>
#include <casa/iomanip.h>

#include <components/ComponentModels/TwoSidedShape.h>
#include <casa/Quanta/QuantumHolder.h>

#include <casa/namespace.h>
namespace casa {

componentlist::componentlist()
  :itsList(),
   itsBin()
{
  DebugAssert(DOok(), AipsError);
}

componentlist::componentlist(const String& filename, const Bool& readonly)
  :itsList(Path(filename), readonly),
   itsBin()
{
  DebugAssert(DOok(), AipsError);
}

componentlist::componentlist(const componentlist& other)
  :itsList(other.itsList),
   itsBin(other.itsBin)
{
  DebugAssert(DOok(), AipsError);
}

componentlist::~componentlist() {
}

componentlist& componentlist::operator=(const componentlist& other) {
  if (this != &other) {
    itsList = other.itsList;
    itsBin = other.itsBin;
  }
  DebugAssert(DOok(), AipsError);
  return *this;
}

void componentlist::add(SkyComponent component) {
  itsList.add(component);
  DebugAssert(DOok(), AipsError);
}

casa::SkyComponent componentlist::component(const Index& which) const {
  DebugAssert(DOok(), AipsError);
  const Int c = checkIndex(which, "component");
  const SkyComponent& listRef(itsList.component(c));
  return listRef.copy();
}

void componentlist::replace(const Vector<Index>& which, const ObjectID& list,
			    const Vector<Index>& whichones) {
  const uInt nComp = which.nelements();
  if (nComp != whichones.nelements()) {
    LogIO logErr(LogOrigin("componentlist", "replace"));
    logErr << "Cannot replace " << nComp << " component(s) with "
	   <<  whichones.nelements() << " component(s)" 
	   << LogIO::EXCEPTION;
  }
  ObjectController* ctrPtr = ApplicationEnvironment::objectController();
  AlwaysAssert(ctrPtr != 0, AipsError);
  ApplicationObject* appPtr = ctrPtr->getObject(list);
  AlwaysAssert(appPtr != 0, AipsError);
  AlwaysAssert(appPtr->className() == "componentlist", AipsError);
  const componentlist otherList(*dynamic_cast<componentlist*>(appPtr));
  
  const Vector<Int> replaced = checkIndicies(which, "replace", 
					     "No components replaced");
  for (uInt i = 0; i < nComp; i++) {
    const Int c = whichones(i).oneRelativeValue();
    if (c < 1 || c > otherList.length()) {
      LogIO logErr(LogOrigin("componentlist", "concatenate"));
      logErr << "Index out of range." << endl
 	     << "A component number is less than one or greater than "
 	     << "the list length" << endl
 	     <<	"No components replaced"
 	     << LogIO::EXCEPTION;
    }
  }
  
  for (uInt i = 0; i < nComp; i++) {
    itsList.component(replaced(i)) = otherList.component(whichones(i)).copy();
  }
  
  DebugAssert(DOok(), AipsError);
}

void componentlist::concatenate(const ObjectID& list, 
				const Vector<Index>& which) {
  ObjectController* ctrPtr = ApplicationEnvironment::objectController();
  AlwaysAssert(ctrPtr != 0, AipsError);
  ApplicationObject* appPtr = ctrPtr->getObject(list);
  AlwaysAssert(appPtr != 0, AipsError);
  AlwaysAssert(appPtr->className() == "componentlist", AipsError);
  const componentlist otherList(*dynamic_cast<componentlist*>(appPtr));
  const uInt nComp = which.nelements();
  const Int otherLength = otherList.length();
  for (uInt i = 0; i < nComp; i++) {
    const Int c = which(i).oneRelativeValue();
    if (c < 1 || c > otherLength) {
      LogIO logErr(LogOrigin("componentlist", "concatenate"));
      logErr << "Index out of range." << endl
 	     << "A component number is less than one or greater than "
 	     << "the list length" << endl
 	     <<	"No components concatenated"
 	     << LogIO::EXCEPTION;
    }
  }
  for (uInt i = 0; i < nComp; i++) {
    itsList.add(otherList.component(which(i)).copy());
  }
  DebugAssert(DOok(), AipsError);
}

void componentlist::remove(const Vector<Index>& which) {
  const Vector<Int> intVec = 
    checkIndicies(which, "remove", "No components removed");
  for (uInt c = 0; c < intVec.nelements(); c++) {
    itsBin.add(itsList.component(intVec(c)));
  }
  itsList.remove(intVec);
  DebugAssert(DOok(), AipsError);
}

void componentlist::purge() {
  Vector<Int> indices(itsBin.nelements());
  indgen(indices);
  itsBin.remove(indices);
  DebugAssert(DOok(), AipsError);
}

void componentlist::recover() {
  uInt i = itsBin.nelements();
  while (i > 0) {
    i--;
    itsList.add(itsBin.component(i));
  }
  purge();
  DebugAssert(DOok(), AipsError);
}

Int componentlist::length() const {
  DebugAssert(DOok(), AipsError);
  return itsList.nelements();
}

Vector<Index> componentlist::indices() const {
  DebugAssert(DOok(), AipsError);
  Vector<Int> intVec(length());
  indgen(intVec);
  Vector<Index> retVal(itsList.nelements());
  Index::convertVector(retVal, intVec);
  return retVal;
}

void componentlist::sort(const String& criteria) {
  ComponentList::SortCriteria sortEnum = ComponentList::type(criteria);
  if (sortEnum == ComponentList::UNSORTED) {
    LogIO logErr(LogOrigin("componentlist", "sort"));
      logErr << "Bad sort criteria." << endl
	     << "Allowed values are: 'flux', 'position' & 'polarization'"
	     << endl <<	"No sorting done."
	     << LogIO::EXCEPTION;
  }
  itsList.sort(sortEnum);
  DebugAssert(DOok(), AipsError);
}

Vector<Double> componentlist::
sample(const MDirection& sampleDir, 
       const MVAngle& pixelLatSize, const MVAngle& pixelLongSize, 
       const MFrequency& centerFreq) const {
  DebugAssert(DOok(), AipsError);
  Flux<Double> flux = itsList.sample(sampleDir, pixelLatSize, pixelLongSize,
				     centerFreq);
  flux.convertUnit(Unit("Jy"));
  Vector<Double> intensity(4);
  flux.value(intensity);
  return intensity;
}

Bool componentlist::is_physical(const Vector<Index>& which) const {
  DebugAssert(DOok(), AipsError);
  const Vector<Int> intVec = 
    checkIndicies(which, "is_physical", "Not checking any components");
  return itsList.isPhysical(intVec);
}

void componentlist::rename(const String& newName) {
  itsList.rename(Path(newName), Table::NewNoReplace);
  DebugAssert(DOok(), AipsError);
}

void componentlist::close() {
  itsList = ComponentList();
  itsBin = ComponentList();
  DebugAssert(DOok(), AipsError);
}

Bool componentlist::DOok() const {
  return itsList.ok() && itsBin.ok();
}

void componentlist::select(const Vector<Index>& which) {
  const Vector<Int> intVec = 
    checkIndicies(which, "select", "No components selected");
  itsList.select(intVec);
  DebugAssert(DOok(), AipsError);
}

void componentlist::deselect(const Vector<Index>& which) {
  const Vector<Int> intVec = 
    checkIndicies(which, "deselect", "No components deselected");
  itsList.deselect(intVec);
  DebugAssert(DOok(), AipsError);
}

Vector<Index> componentlist::selected() const {
  DebugAssert(DOok(), AipsError);
  Vector<Index> retVal(itsList.nelements());
  Index::convertVector(retVal, itsList.selected());
  return retVal;
}

String componentlist::getlabel(const Index& which) const {
  DebugAssert(DOok(), AipsError);
  const Int c = checkIndex(which, "getlabel");
  return itsList.component(c).label();
};

void componentlist::setlabel(const Vector<Index>& which,
			     const String& label) {
  const Vector<Int> intVec = 
    checkIndicies(which, "setlabel", "No labels changed");
  itsList.setLabel(intVec, label);
  DebugAssert(DOok(), AipsError);
};

Vector<DComplex> componentlist::getfluxvalue(const Index& which) const {
  DebugAssert(DOok(), AipsError);
  const Int c = checkIndex(which, "getfluxvalue");
  return itsList.component(c).flux().value();
}

String componentlist::getfluxunit(const Index& which) const {
  DebugAssert(DOok(), AipsError);
  const Int c = checkIndex(which, "getfluxunit");
  return itsList.component(c).flux().unit().getName();
}

String componentlist::getfluxpol(const Index& which) const {
  DebugAssert(DOok(), AipsError);
  const Int c = checkIndex(which, "getfluxpol");
  return ComponentType::name(itsList.component(c).flux().pol());
}

Vector<DComplex> componentlist::getfluxerror(const Index& which) const {
  DebugAssert(DOok(), AipsError);
  const Int c = checkIndex(which, "getfluxerror");
  return itsList.component(c).flux().errors();
}

void componentlist::setflux(const Vector<Index>& which,
			    const Vector<DComplex>& values,
			    const String& unitString, 
			    const String& polString,
			    const Vector<DComplex>& errors) {
  Flux<Double> newFlux;
  const ComponentType::Polarisation pol = checkFluxPol(polString);
  newFlux.setPol(pol);

  const Unit fluxUnit(unitString);
  if (fluxUnit != Unit("Jy")) {
    LogIO logErr(LogOrigin("componentlist", "setflux"));
    logErr << "The flux units must have the same dimensions as the Jansky"
	   << endl << "Flux not changed on any components"
           << LogIO::EXCEPTION;
  }
  newFlux.setUnit(fluxUnit);

  if ((values.nelements() == 1) &&  (pol == ComponentType::STOKES)) {
    newFlux.setValue(values(0).real());
  } else if (values.nelements() == 4) {
    newFlux.setValue(values);
  } else {
    LogIO logErr(LogOrigin("componentlist", "setflux"));
    logErr << "The flux must have one or four elements," << endl
	   << "one element can only be used if the polarization is 'Stokes'."
	   << endl << "Flux not changed on any components"
           << LogIO::EXCEPTION;
  }
  if (values.nelements() == 4) {
    newFlux.setErrors(errors(0), errors(1), errors(2), errors(3));
  } else {
    LogIO logErr(LogOrigin("componentlist", "setflux"));
    logErr << "The flux error must have four elements" 
	   << endl << "Flux not changed on any components"
           << LogIO::EXCEPTION;
  }
  const Vector<Int> intVec = 
    checkIndicies(which, "setflux", "Flux not changed on any components");
  itsList.setFlux(intVec, newFlux);
  DebugAssert(DOok(), AipsError);
}

void componentlist::convertfluxunit(const Vector<Index>& which,
				    const String& unitString) {
  const Unit fluxUnit(unitString);
  if (fluxUnit != Unit("Jy")) {
    LogIO logErr(LogOrigin("componentlist", "convertfluxunit"));
    logErr << "The flux units must have the same dimensions as the Jansky"
	   << endl << "Flux not changed on any components"
           << LogIO::EXCEPTION;
  }
  const Vector<Int> intVec = 
    checkIndicies(which, "convertfluxunit", 
		  "Flux not changed on any components");
  itsList.convertFluxUnit(intVec, fluxUnit);
  DebugAssert(DOok(), AipsError);
}

void componentlist::convertfluxpol(const Vector<Index>& which,
				   const String& polString) {
  const Vector<Int> intVec = 
    checkIndicies(which, "convertfluxunit",
		  "Flux not changed on any components");
  itsList.convertFluxPol(intVec, checkFluxPol(polString));
  DebugAssert(DOok(), AipsError);
}

MDirection componentlist::getrefdir(const Index& which) const {
  DebugAssert(DOok(), AipsError);
  const Int c = checkIndex(which, "getrefdir");
  return itsList.component(c).shape().refDirection();
}

String componentlist::getrefdirra(const Index& which,
 				  const String& unit, const Int prec) const {
  DebugAssert(DOok(), AipsError);
  String lcunit = unit; 
  lcunit.downcase();
  const Quantum<Vector<Double> > radec = getrefdir(which).getAngle();
  Double ra;
  if (lcunit == String("time") || lcunit == String("angle")) {
    ra = radec.get("rad").getValue()(0);
  } else {
    const Unit angleUnit(unit);
    if (angleUnit != Unit("rad")) {
      LogIO logErr(LogOrigin("componentlist", "getrefdirra"));
      logErr << "The ra units must have angular units or be 'time' or 'angle'"
	     << LogIO::EXCEPTION;
    }
    ra = radec.get(angleUnit).getValue()(0);
  }
  return formatAngle(ra, lcunit, prec);
}

String componentlist::getrefdirdec(const Index& which,
				   const String& unit, const Int prec) const {
  DebugAssert(DOok(), AipsError);
  String lcunit = unit; 
  lcunit.downcase();
  const Quantum<Vector<Double> > radec = getrefdir(which).getAngle();
  Double dec;
  if (lcunit == String("time") || lcunit == String("angle")) {
    dec = radec.get("rad").getValue()(1);
  } else {
    const Unit angleUnit(unit);
    if (angleUnit != Unit("rad")) {
      LogIO logErr(LogOrigin("componentlist", "getrefdirdec"));
      logErr << "The dec units must have angular units or be 'time' or 'angle'"
	     << LogIO::EXCEPTION;
    }
    dec = radec.get(unit).getValue()(1);
  }
  return formatAngle(dec, lcunit, prec);
}

String componentlist::formatAngle(const Double angle,
				  const String& unit, const Int prec) const {
  if (unit == String("time")) {
    const MVAngle mvangle(angle);
    return mvangle.string(MVAngle::TIME, prec);
  } else if (unit == String("angle")) {
    const MVAngle mvangle(angle);
    return mvangle.string(MVAngle::ANGLE, prec);
  } else {
    ostringstream os;
    os << setprecision(prec) << angle;
    return String(os);
  }
  return ("0");
}

String componentlist::getrefdirframe(const Index& which) const {
  DebugAssert(DOok(), AipsError);
  return getrefdir(which).getRefString();
}

void componentlist::setrefdir(const Vector<Index>& which,
			      const String& raval, const String& raunit, 
			      const String& decval, const String& decunit) {
  Quantum<Double> ra;
  String lcunit = raunit;
  lcunit.downcase();
  Bool readOK = False;
  if ((lcunit == String("angle") || lcunit == String("time"))) {
    // Construct an MUString to generate an error if the string is not 
    // properly formatted
    MUString mus(raval);
    readOK = MVAngle::read(ra, mus);
  } else {
    readOK = MVAngle::read(ra, raval);
    if (readOK) ra.setUnit(lcunit);
  }
  if (!readOK) {
    LogIO logErr(LogOrigin("componentlist", "setrefdir"));
    logErr << "Could not parse the 'RA' string" << endl
	   << "Direction not changed on any components"
           << LogIO::EXCEPTION;
  }

  Quantum<Double> dec;
  lcunit = decunit;
  lcunit.downcase();
  if ((lcunit == String("angle") || lcunit == String("time"))) {
    MUString mus(decval);
    readOK = MVAngle::read(dec, mus);
  } else {
    readOK = MVAngle::read(dec, decval);
    if (readOK) dec.setUnit(lcunit);
  }
  if (!readOK) {
    LogIO logErr(LogOrigin("componentlist", "setrefdir"));
    logErr << "Could not parse the declination string" << endl
	   << "Direction not changed on any components"
           << LogIO::EXCEPTION;
  }

  const MVDirection newDir(ra, dec);

  const Vector<Int> intVec = 
    checkIndicies(which, "setrefdir", 
		  "Direction not changed on any components");
  itsList.setRefDirection(intVec, newDir);
  DebugAssert(DOok(), AipsError);
}

void componentlist::setrefdirframe(const Vector<Index>& which,
				   const String& frame) {
  MDirection::Types newFrame;
  if (!MDirection::getType(newFrame, frame)) {
    LogIO logErr(LogOrigin("componentlist", "setrefdirframe"));
    logErr << "Could not parse the 'frame' string: Direction frame not changed"
           << LogIO::EXCEPTION;
  }
  Vector<Int> intVec(which.nelements());
  Index::convertVector(intVec, which);
  itsList.setRefDirectionFrame(intVec, newFrame);
  DebugAssert(DOok(), AipsError);
}

  
void componentlist::convertrefdir(const Vector<Index>& which,
				  const String& frame) {
  MDirection::Types newFrame;
  if (!MDirection::getType(newFrame, frame)) {
    LogIO logErr(LogOrigin("componentlist", "convertrefdir"));
    logErr << "Could not parse the 'frame' string: Direction frame not changed"
           << LogIO::EXCEPTION;
  }
  Vector<Int> intVec(which.nelements());
  Index::convertVector(intVec, which);
  itsList.convertRefDirection(intVec, newFrame);
  DebugAssert(DOok(), AipsError);
}

String componentlist::shapetype(const Index& which) {
  DebugAssert(DOok(), AipsError);
  return ComponentType::name(itsList.component(which.zeroRelativeValue())
			     .shape().type());
}

GlishRecord componentlist::getshape(const Index& which) const {
  DebugAssert(DOok(), AipsError);
  const ComponentShape& shape = 
    itsList.component(which.zeroRelativeValue()).shape();
  Record rec;
  String errorMessage;
  if (!shape.toRecord(errorMessage, rec)) {
    LogIO logErr(LogOrigin("componentlist", "getshape"));
    logErr << "Could not get the component shape because:" << endl
 	   << errorMessage 
	   << "Empty record returned" << LogIO::EXCEPTION;
  }
  rec.removeField(RecordFieldId("type"));
  rec.removeField(RecordFieldId("direction"));
  GlishRecord retVal;
  retVal.fromRecord(rec);
  return retVal;
}

GlishRecord componentlist::getshapeerror(const Index& which) const {
  DebugAssert(DOok(), AipsError);
  const ComponentShape& shape = 
    itsList.component(which.zeroRelativeValue()).shape();
  // This is a bit of a kludge but it will do for now.
  GlishRecord retVal;
  if (shape.type() != ComponentType::POINT) {
    const TwoSidedShape& tsShape = dynamic_cast<const TwoSidedShape&>(shape);
    Record record;
    {
      const QuantumHolder majorQh(tsShape.majorAxisError());
      const QuantumHolder minorQh(tsShape.minorAxisError());
      const QuantumHolder paQh(tsShape.positionAngleError());
      Record majorRec, minorRec, paRec;
      String errorMessage;
      if (!majorQh.toRecord(errorMessage, majorRec) ||
	  !minorQh.toRecord(errorMessage, minorRec) ||
	  !paQh.toRecord(errorMessage, paRec)) {
	LogIO logErr(LogOrigin("componentlist", "getshapeerror"));
	logErr << "Could not get the component shape because:" << endl
	       << errorMessage 
	       << "Empty record returned" << LogIO::EXCEPTION;
      }
      record.defineRecord(RecordFieldId("majoraxis"), majorRec);
      record.defineRecord(RecordFieldId("minoraxis"), minorRec);
      record.defineRecord(RecordFieldId("positionangle"), paRec);
    }
    retVal.fromRecord(record);
  }
  return retVal;
}

void componentlist::setshape(const Vector<Index>& which,
			     const String& newType,
			     const GlishRecord& parameters) {
  ComponentType::Shape reqShape = ComponentType::shape(newType);
  ComponentShape* shapePtr = ComponentType::construct(reqShape);
  if (shapePtr == 0) {
    LogIO logErr(LogOrigin("componentlist", "setshape"));
    logErr << "Could not translate the shape type to a known value." << endl
 	   << "Known types are:" << endl;
    
    for (uInt i = 0; i < ComponentType::NUMBER_SHAPES - 1; i++) {
      reqShape = (ComponentType::Shape) i;
      logErr <<  ComponentType::name(reqShape) + String("\n");
    }
    logErr << "Shape not changed." << LogIO::EXCEPTION;
  }
  String errorMessage;
  Record rec;
  parameters.toRecord (rec);
  if (!shapePtr->fromRecord(errorMessage, rec)) {
     LogIO logErr(LogOrigin("componentlist", "setshape"));
     logErr << "Could not parse the shape parameters. The error was:" << endl
	    << errorMessage
	    << "Shape not changed." << LogIO::EXCEPTION;
  }
  Vector<Int> intVec(which.nelements());
  Index::convertVector(intVec, which);
  itsList.setShapeParms(intVec, *shapePtr);
  delete shapePtr;
  DebugAssert(DOok(), AipsError);
}

void componentlist::convertshape(const Vector<Index>& which,
				 const GlishRecord& parameters) {
  String errorMessage;
  Record record;
  parameters.toRecord(record);
  for (uInt i = 0; i < which.nelements(); i++) {
    ComponentShape& shape = 
      itsList.component(which(i).zeroRelativeValue()).shape();
    if (!shape.convertUnit(errorMessage, record)) {
      LogIO logErr(LogOrigin("componentlist", "convertshape"));
      logErr << "Could not convert the shape parameters. The error was:"<< endl
	     << errorMessage;
      if (i == 0) {
	logErr << "Shapes not changed." << LogIO::EXCEPTION;
      } else {
	logErr << "Not all shapes changed." << LogIO::EXCEPTION;
      }
    }
  }
  DebugAssert(DOok(), AipsError);
}

casa::String componentlist::spectrumtype(const Index& which) {
  DebugAssert(DOok(), AipsError);
  return ComponentType::name(itsList.component(which.zeroRelativeValue())
			     .spectrum().type());
}

casa::GlishRecord componentlist::getspectrum(const Index& which) const {
  DebugAssert(DOok(), AipsError);
  const SpectralModel& spectrum = 
    itsList.component(which.zeroRelativeValue()).spectrum();
  casa::GlishRecord retVal;
  casa::String errorMessage;
  casa::Record rec;
  if (!spectrum.toRecord(errorMessage, rec)) {
    LogIO logErr(LogOrigin("componentlist", "getspectrum"));
    logErr << "Could not get the component spectrum because:" << endl
 	   << errorMessage 
	   << "Empty record returned" << LogIO::EXCEPTION;
  }
  retVal.fromRecord (rec);
  return retVal;
}

void componentlist::setspectrum(const Vector<Index>& which,
				const String& newType,
				const GlishRecord& parameters) {
  ComponentType::SpectralShape reqSpectrum = 
    ComponentType::spectralShape(newType);
  SpectralModel* spectrumPtr = ComponentType::construct(reqSpectrum);
  if (spectrumPtr == 0) {
    LogIO logErr(LogOrigin("componentlist", "setspectrum"));
    logErr << "Could not translate the spectral type to a known value." << endl
  	   << "Known types are:" << endl;
    for (uInt i = 0; i < ComponentType::NUMBER_SPECTRAL_SHAPES - 1; i++) {
      reqSpectrum = (ComponentType::SpectralShape) i;
      logErr <<  ComponentType::name(reqSpectrum) + String("\n");
    }
    logErr << "Spectrum not changed." << LogIO::EXCEPTION;
  }
  String errorMessage;
  Record rec;
  parameters.toRecord (rec);
  if (!spectrumPtr->fromRecord(errorMessage, rec)) {
    LogIO logErr(LogOrigin("componentlist", "setspectrum"));
    logErr << "Could not parse the spectrum parameters. The error was:" << endl
	   << errorMessage << endl
  	   << "Spectrum not changed." << LogIO::EXCEPTION;
  }
  Vector<Int> intVec(which.nelements());
  Index::convertVector(intVec, which);
  itsList.setSpectrumParms(intVec, *spectrumPtr);
  delete spectrumPtr;
  DebugAssert(DOok(), AipsError);
}

void componentlist::convertspectrum(const Vector<Index>& which,
				    const GlishRecord& parameters) {
  String errorMessage;
  Record record;
  parameters.toRecord(record);
  for (uInt i = 0; i < which.nelements(); i++) {
    SpectralModel& spectrum 
      = itsList.component(which(i).zeroRelativeValue()).spectrum();
    if (!spectrum.convertUnit(errorMessage, record)) {
      LogIO logErr(LogOrigin("componentlist", "convertspectrum"));
      logErr << "Could not convert the spectrum parameters. The error was:"
	     << endl << errorMessage;
      if (i == 0) {
	logErr << "Spectra not changed." << LogIO::EXCEPTION;
      } else {
	logErr << "Not all spectra changed." << LogIO::EXCEPTION;
      }
    }
  }
  DebugAssert(DOok(), AipsError);
}

MFrequency componentlist::getfreq(const Index& which) const {
  DebugAssert(DOok(), AipsError);
  return itsList.component(which.zeroRelativeValue()).spectrum().refFrequency();
}

Double componentlist::getfreqvalue(const Index& which) const {
  DebugAssert(DOok(), AipsError);
  return getfreq(which).getValue().get().getValue(Unit(getfrequnit(which)));
}

String componentlist::getfrequnit(const Index& which) const {
  DebugAssert(DOok(), AipsError);
  return itsList.component(which.zeroRelativeValue()).spectrum()
    .frequencyUnit().getName();
}

String componentlist::getfreqframe(const Index& which) const {
  DebugAssert(DOok(), AipsError);
  return getfreq(which).getRefString();
}

void componentlist::setfreq(const Vector<Index>& which,
			    const Double& value, const String& unit) {
  const MVFrequency newFreq(Quantum<Double>(value, unit));
  Vector<Int> intVec(which.nelements());
  Index::convertVector(intVec, which);
  itsList.setRefFrequency(intVec, newFreq);
  convertfrequnit(which, unit);
  DebugAssert(DOok(), AipsError);
}

void componentlist::setfreqframe(const Vector<Index>& which,
				 const String& frame) {
  MFrequency::Types newFrame;
  if (!MFrequency::getType(newFrame, frame)) {
    LogIO logErr(LogOrigin("componentlist", "setfreqframe"));
    logErr << "Could not parse the 'frame' string: Frequency frame not changed"
           << LogIO::EXCEPTION;
  }
  Vector<Int> intVec(which.nelements());
  Index::convertVector(intVec, which);
  itsList.setRefFrequencyFrame(intVec, newFrame);
  DebugAssert(DOok(), AipsError);
}

void componentlist::convertfrequnit(const Vector<Index>& which,
				    const String& unit) {
  Vector<Int> intVec(which.nelements());
  Index::convertVector(intVec, which);
  itsList.setRefFrequencyUnit(intVec, Unit(unit));
  DebugAssert(DOok(), AipsError);
}

void componentlist::simulate(const Int howMany) {
  AlwaysAssert(howMany >= 0, AipsError);
  for (Int i = 0; i < howMany; i++) {
    itsList.add(SkyComponent());
  }
  DebugAssert(DOok(), AipsError);
}

String componentlist::className() const {
  return "componentlist";
}

Vector<String> componentlist::methods() const {
  Vector<String> method(NUM_METHODS);
  method(ADD) = "add";
  method(COMPONENT) = "component";
  method(REPLACE) = "replace";
  method(CONCATENATE) = "concatenate";
  method(REMOVE) = "remove";
  method(PURGE) = "purge";
  method(RECOVER) = "recover";
  method(LENGTH) = "length";
  method(INDICES) = "indices";
  method(SORT) = "sort";
  method(SAMPLE) = "sample";
  method(IS_PHYSICAL) = "is_physical";
  method(RENAME) = "rename";
  method(CLOSE) = "close";
  method(SELECT) = "select";
  method(DESELECT) = "deselect";
  method(SELECTED) = "selected";
  method(GETFLUXVALUE) = "getfluxvalue";
  method(GETFLUXUNIT) = "getfluxunit";
  method(GETFLUXPOL) = "getfluxpol";
  method(GETFLUXERROR) = "getfluxerror";
  method(SETFLUX) = "setflux";
  method(CONVERTFLUXUNIT) = "convertfluxunit";
  method(CONVERTFLUXPOL) = "convertfluxpol";
  method(SIMULATE) = "simulate";
  method(GETREFDIR) = "getrefdir";
  method(GETREFDIRRA) = "getrefdirra";
  method(GETREFDIRDEC) = "getrefdirdec";
  method(GETREFDIRFRAME) = "getrefdirframe";
  method(SETREFDIR) = "setrefdir";
  method(SETREFDIRFRAME) = "setrefdirframe";
  method(CONVERTREFDIR) = "convertrefdir";
  method(SHAPETYPE) = "shapetype";
  method(SPECTRUMTYPE) = "spectrumtype";
  method(GETLABEL) = "getlabel";
  method(SETLABEL) = "setlabel";
  method(SETSHAPE) = "setshape";
  method(SETSPECTRUM) = "setspectrum";
  method(GETSHAPE) = "getshape";
  method(GETSHAPEERROR) = "getshapeerror";
  method(CONVERTSHAPE) = "convertshape";
  method(GETSPECTRUM) = "getspectrum";
  method(CONVERTSPECTRUM) = "convertspectrum";
  method(GETFREQ) = "getfreq";
  method(GETFREQVALUE) = "getfreqvalue";
  method(GETFREQUNIT) = "getfrequnit";
  method(GETFREQFRAME) = "getfreqframe";
  method(SETFREQ) = "setfreq";
  method(SETFREQFRAME) = "setfreqframe";
  method(CONVERTFREQUNIT) = "convertfrequnit";
  return method;
}

MethodResult componentlist::runMethod(uInt which,
				      ParameterSet& parameters, 
				      Bool runMethod) {
  static const String componentName = "component";
  static const String criteriaName = "criteria";
  static const String decName = "dec";
  static const String decunitName = "decunit";
  static const String directionName = "direction";
  static const String filenameName = "filename";
  static const String frameName = "frame";
  static const String frequencyName = "frequency";
  static const String howmanyName = "howmany";
  static const String imageName = "imagefilename";
  static const String listName = "list";
  static const String overwriteName = "overwrite";
  static const String pixellatsizeName = "pixellatsize";
  static const String pixellongsizeName = "pixellongsize";
  static const String polName = "polarization";
  static const String precName = "precision";
  static const String raName = "ra";
  static const String raunitName = "raunit";
  static const String returnvalName = "returnval";
  static const String shapeName = "shape";
  static const String spectrumName = "spectrum";
  static const String typeName = "type";
  static const String unitName = "unit";
  static const String valueName = "value";
  static const String whichName = "which";
  static const String whichonesName = "whichones";
  static const String errorName = "error";

  switch (which) {
  case ADD: {
    const Parameter<SkyComponent> component(parameters, componentName, 
					    ParameterSet::In);
    if (runMethod) {
      add(component());
    }
  }
  break;
  case COMPONENT: {
    const Parameter<Index> which(parameters, whichName, ParameterSet::In);
    Parameter<SkyComponent> returnval(parameters, returnvalName, 
				      ParameterSet::Out);
    if (runMethod) {
      returnval() = component(which());
    }
  }
  break;
  case REPLACE: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					  ParameterSet::In);
    const Parameter<ObjectID> list(parameters, listName, ParameterSet::In);
    const Parameter<Vector<Index> > whichones(parameters, whichonesName,
 					      ParameterSet::In);
    if (runMethod) {
      replace(which(), list(), whichones());
    }
  }
  break;
  case CONCATENATE: {
    const Parameter<ObjectID> list(parameters, listName, ParameterSet::In);
    const Parameter<Vector<Index> > which(parameters, whichName,
					  ParameterSet::In);
    if (runMethod) {
      concatenate(list(), which());
    }
  }
  break;
  case REMOVE: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					  ParameterSet::In);
    if (runMethod) {
      remove(which());
    }
  }
  break;
  case PURGE: {
    if (runMethod) {
      purge();
    }
  }
  break;
  case RECOVER: {
    if (runMethod) {
      recover();
    }
  }
  break;
  case LENGTH: {
    Parameter<Int> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = length();
    }
  }
  break;
  case INDICES: {
    Parameter<Vector<Index> > returnval(parameters, 
					returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval().resize(length()); // THIS WORKAROUND IS INCLUDED
				    // BECAUSE THE RETURNVAL VECTOR
				    // MAY NOT BE THE RIGHT SIZE!
      returnval() = indices();
    }
  }
  break;
  case SORT: {
    const Parameter<String> criteria(parameters, criteriaName,
				     ParameterSet::In);
    if (runMethod) {
      sort(criteria());
    }
  }
  break;
  case SAMPLE: {
    const Parameter<MDirection> direction(parameters, directionName, 
					  ParameterSet::In);
    const Parameter<Quantum<Double> > pixelLatSize(parameters, 
						   pixellatsizeName, 
						   ParameterSet::In);
    const Parameter<Quantum<Double> > pixelLongSize(parameters,
						    pixellongsizeName, 
						    ParameterSet::In);
    const Parameter<MFrequency> frequency(parameters, frequencyName, 
					  ParameterSet::In);
    Parameter<Vector<Double> > returnval(parameters, returnvalName, 
					 ParameterSet::Out);
    if (runMethod) {
      if (!(pixelLatSize().check(UnitVal::ANGLE) &&
	    pixelLongSize().check(UnitVal::ANGLE))) {
	return error("the pixel size does not have angular units");
      }
      const MVAngle pixelLatAngle(pixelLatSize());
      const MVAngle pixelLongAngle(pixelLongSize());
      returnval().resize(4);
      returnval() = sample(direction(), pixelLatAngle, pixelLongAngle, 
			   frequency());
    }
  }
  break;
  case IS_PHYSICAL: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					  ParameterSet::In);
    Parameter<Bool> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = is_physical(which());
    }
  }
  break;
  case RENAME: {
    Parameter<String> filename(parameters, filenameName, ParameterSet::In);
    filename.setConstraint(NewFileConstraint());
    if (runMethod) {
      rename(filename());
    }
  }
  break;
  case CLOSE: {
    if (runMethod) {
      close();
    }
  }
  break;
  case SELECT: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					  ParameterSet::In);
    if (runMethod) {
      select(which());
    }
  }
  break;
  case DESELECT: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					  ParameterSet::In);
    if (runMethod) {
      deselect(which());
    }
  }
  break;
  case SELECTED: {
    Parameter<Vector<Index> > returnval(parameters, returnvalName, 
					ParameterSet::Out);
    if (runMethod) {
      returnval().resize(selected().nelements());
      returnval() = selected();
    }
  }
  break;
  case GETFLUXVALUE: {
    const Parameter<Index> which(parameters, whichName, ParameterSet::In);
    Parameter<Vector<DComplex> > returnval(parameters, 
					   returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval().resize(4);
      returnval() = getfluxvalue(which());
    }
  }
  break;
  case GETFLUXUNIT: {
    const Parameter<Index> which(parameters, whichName, ParameterSet::In);
    Parameter<String> returnval(parameters, 
				returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = getfluxunit(which());
    }
  }
  break;
  case GETFLUXPOL: {
    const Parameter<Index> which(parameters, whichName, ParameterSet::In);
    Parameter<String> returnval(parameters, 
				returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = getfluxpol(which());
    }
  }
  break;
  case GETFLUXERROR: {
    const Parameter<Index> which(parameters, whichName, ParameterSet::In);
    Parameter<Vector<DComplex> > returnval(parameters, 
					   returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = getfluxerror(which());
    }
  }
  break;
  case SETFLUX: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					  ParameterSet::In);
    const Parameter<Vector<DComplex> > value(parameters, valueName,
					     ParameterSet::In);
    const Parameter<String> unit(parameters, unitName, ParameterSet::In);
    const Parameter<String> pol(parameters, polName, ParameterSet::In);
    const Parameter<Vector<DComplex> > errors(parameters, errorName,
					      ParameterSet::In);
    if (runMethod) {
      setflux(which(), value(), unit(), pol(), errors());
    }
  }
  break;
  case CONVERTFLUXUNIT: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					  ParameterSet::In);
    const Parameter<String> unit(parameters, unitName, ParameterSet::In);
    if (runMethod) {
      convertfluxunit(which(), unit());
    }
  }
  break;
  case CONVERTFLUXPOL: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					  ParameterSet::In);
    const Parameter<String> pol(parameters, polName, ParameterSet::In);
    if (runMethod) {
      convertfluxpol(which(), pol());
    }
  }
  break;
  case SIMULATE: {
    const Parameter<Int> howMany(parameters, howmanyName, ParameterSet::In);
    if (runMethod) {
      simulate(howMany());
    }
  }
  break;
  case GETREFDIR: {
    const Parameter<Index> which(parameters, whichName, ParameterSet::In);
    Parameter<MDirection> returnval(parameters, 
				    returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = getrefdir(which());
    }
  }
  break;
  case GETREFDIRRA: {
    const Parameter<Index> which(parameters, whichName, ParameterSet::In);
    const Parameter<Int> prec(parameters, precName, ParameterSet::In);
    const Parameter<String> unit(parameters, unitName, ParameterSet::In);
    Parameter<String> returnval(parameters, 
				returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = getrefdirra(which(), unit(), prec());
    }
  }
  break;
  case GETREFDIRDEC: {
    const Parameter<Index> which(parameters, whichName, ParameterSet::In);
    const Parameter<Int> prec(parameters, precName, ParameterSet::In);
    const Parameter<String> unit(parameters, unitName, ParameterSet::In);
    Parameter<String> returnval(parameters, 
				returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = getrefdirdec(which(), unit(), prec());
    }
  }
  break;
  case GETREFDIRFRAME: {
    const Parameter<Index> which(parameters, whichName, ParameterSet::In);
    Parameter<String> returnval(parameters, 
				returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = getrefdirframe(which());
    }
  }
  break;
  case SETREFDIR: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					  ParameterSet::In);
    const Parameter<String> ra(parameters, raName, ParameterSet::In);
    const Parameter<String> raunit(parameters, raunitName, ParameterSet::In);
    const Parameter<String> dec(parameters, decName, ParameterSet::In);
    const Parameter<String> decunit(parameters, decunitName, ParameterSet::In);
    if (runMethod) {
      setrefdir(which(), ra(), raunit(), dec(), decunit());
    }
  }
  break;
  case SETREFDIRFRAME: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					  ParameterSet::In);
    const Parameter<String> frame(parameters, frameName, ParameterSet::In);
    if (runMethod) {
      setrefdirframe(which(), frame());
    }
  }
  break;
  case CONVERTREFDIR: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					  ParameterSet::In);
    const Parameter<String> frame(parameters, frameName, ParameterSet::In);
    if (runMethod) {
      convertrefdir(which(), frame());
    }
  }
  break;
  case SHAPETYPE: {
    const Parameter<Index> which(parameters, whichName,
				 ParameterSet::In);
    Parameter<String> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = shapetype(which());
    }
  }
  break;
  case SPECTRUMTYPE: {
    const Parameter<Index> which(parameters, whichName,
				 ParameterSet::In);
    Parameter<String> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = spectrumtype(which());
    }
  }
  break;
  case GETLABEL: {
    const Parameter<Index> which(parameters, whichName,
				 ParameterSet::In);
    Parameter<String> returnval(parameters, returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = getlabel(which());
    }
  }
  break;
  case SETLABEL: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					  ParameterSet::In);
    const Parameter<String> value(parameters, valueName,
				  ParameterSet::In);
    if (runMethod) {
      setlabel(which(), value());
    }
  }
  break;
  case SETSHAPE: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					  ParameterSet::In);
    const Parameter<String> type(parameters, typeName,
				 ParameterSet::In);
    const Parameter<GlishRecord> shape(parameters, shapeName,
				       ParameterSet::In);
    if (runMethod) {
      setshape(which(), type(), shape());
    }
  }
  break;
  case SETSPECTRUM: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					  ParameterSet::In);
    const Parameter<String> type(parameters, typeName,
				 ParameterSet::In);
    const Parameter<GlishRecord> spectrum(parameters, spectrumName,
					  ParameterSet::In);
    if (runMethod) {
      setspectrum(which(), type(), spectrum());
    }
  }
  break;
  case GETSHAPE: {
    const Parameter<Index> which(parameters, whichName,
				 ParameterSet::In);
    Parameter<GlishRecord> returnval(parameters,
				     returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = getshape(which());
    }
  }
  break;
  case GETSHAPEERROR: {
    const Parameter<Index> which(parameters, whichName,
				 ParameterSet::In);
    Parameter<GlishRecord> returnval(parameters,
				     returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = getshapeerror(which());
    }
  }
  break;
  case CONVERTSHAPE: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					  ParameterSet::In);
    const Parameter<GlishRecord> shape(parameters, shapeName,
				       ParameterSet::In);
    if (runMethod) {
      convertshape(which(), shape());
    }
  }
  break;
  case GETSPECTRUM: {
    const Parameter<Index> which(parameters, whichName,
				 ParameterSet::In);
    Parameter<GlishRecord> returnval(parameters,
				     returnvalName, ParameterSet::Out);
    if (runMethod) {
      returnval() = getspectrum(which());
    }
  }
  break;
  case CONVERTSPECTRUM: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					  ParameterSet::In);
    const Parameter<GlishRecord> spectrum(parameters, spectrumName,
					  ParameterSet::In);
    if (runMethod) {
      convertspectrum(which(), spectrum());
    }
  }
  break;
  case GETFREQ: {
    const Parameter<Index> which(parameters, whichName,
				 ParameterSet::In);
    Parameter<GlishRecord> returnval(parameters, returnvalName,
				     ParameterSet::Out);
    if (runMethod) {
      // This is a real kludge! It would be far nicer if MFrequencies could
      // return their values in specified units.
      ConstantSpectrum spectrum;
      const Index w = which();
      spectrum.setRefFrequency(getfreq(w));
      spectrum.convertFrequencyUnit(Unit(getfrequnit(w)));
      String errorMessage;
      GlishRecord gRec;
      Record rec;
      if (!spectrum.toRecord(errorMessage, rec)) {
	error(errorMessage);
      }
      gRec.fromRecord (rec);
      if (gRec.exists("frequency") && 
	  gRec.get("frequency").type() == GlishValue::RECORD) {
	returnval() = gRec.get("frequency");
      } else {
	error("DOcomponentlist - Problem extracting the frequency record");
      }
    }
  }
  break;
  case GETFREQVALUE: {
    const Parameter<Index> which(parameters, whichName,
				 ParameterSet::In);
    Parameter<Double> returnval(parameters, returnvalName,
				ParameterSet::Out);
    if (runMethod) {
      returnval() = getfreqvalue(which());
    }
  }
  break;
  case GETFREQUNIT: {
    const Parameter<Index> which(parameters, whichName,
				 ParameterSet::In);
    Parameter<String> returnval(parameters, returnvalName,
				ParameterSet::Out);
    if (runMethod) {
      returnval() = getfrequnit(which());
    }
  }
  break;
  case GETFREQFRAME: {
    const Parameter<Index> which(parameters, whichName,
				 ParameterSet::In);
    Parameter<String> returnval(parameters, returnvalName,
				ParameterSet::Out);
    if (runMethod) {
      returnval() = getfreqframe(which());
    }
  }
  break;
  case SETFREQ: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					 ParameterSet::In);
    const Parameter<Double> value(parameters, valueName, ParameterSet::In);
    const Parameter<String> unit(parameters, unitName, ParameterSet::In);
    if (runMethod) {
      setfreq(which(), value(), unit());
    }
  }
  break;
  case SETFREQFRAME: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					 ParameterSet::In);
    const Parameter<String> frame(parameters, frameName, ParameterSet::In);
    if (runMethod) {
      setfreqframe(which(), frame());
    }
  }
  break;
  case CONVERTFREQUNIT: {
    const Parameter<Vector<Index> > which(parameters, whichName,
					 ParameterSet::In);
    const Parameter<String> unit(parameters, unitName, ParameterSet::In);
    if (runMethod) {
      convertfrequnit(which(), unit());
    }
  }
  break;
  default:
    return error("Unknown method");
  }
  return ok();
}

Vector<String> componentlist::noTraceMethods() const {
  return methods();
}

ComponentType::Polarisation componentlist::
checkFluxPol(const String& polString) {
  const ComponentType::Polarisation
    pol(ComponentType::polarisation(polString));
  if (pol == ComponentType::UNKNOWN_POLARISATION) {
    LogIO logErr(LogOrigin("componentlist", "checkFluxPol"));
    logErr << "Unknown polarization. Possible values are:" << endl;
    for (uInt i = 0; i < ComponentType::NUMBER_POLARISATIONS - 1; i++) {
      logErr << " '"
	     <<ComponentType::name(static_cast<ComponentType::Polarisation>(i))
	     << "' ";
    }
    logErr << LogIO::EXCEPTION;
  }
  return pol;
}

Int componentlist::
checkIndex(const Index& which, const String& function) const {
  const Int c = which.zeroRelativeValue();
  if (c < 0 || c >= static_cast<Int>(itsList.nelements())) {
    LogIO logErr(LogOrigin("componentlist", function));
    logErr << "Index out of range." << endl
	   << "The component number is less than one or greater than"
	   << " the list length"
	   << LogIO::EXCEPTION;
  }
  return c;
}

Vector<Int> componentlist::
checkIndicies(const Vector<Index>& which, const String& function,
	      const String& message) const {
  Vector<Int> intVec(which.nelements());
  Index::convertVector(intVec, which);
  const Int listLength = itsList.nelements();
  const uInt whichLength = which.nelements();
  for (uInt c = 0; c < whichLength; c++) {
    if (intVec(c) < 0 || intVec(c) >= listLength) {
      LogIO logErr(LogOrigin("componentlist", function));
      logErr << "Index out of range." << endl
	     << "A component number is less than one or greater than"
	     << " the list length" << endl
	     <<	message
	     << LogIO::EXCEPTION;
    }
  }
  return intVec;
}

}
// Local Variables: 
// compile-command: "gmake DOcomponentlist"
// End: 
