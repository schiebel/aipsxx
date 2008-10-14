//# PKSMultiBeamDD.cc: Base class for Parkes Multibeam DisplayData objects
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003,2004
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
//# $Id: PKSMultiBeamDD.cc,v 19.9 2005/06/15 18:00:45 cvsmgr Exp $
//
#include <display/DisplayDatas/PKSMultiBeamDD.h>
#include <display/DisplayDatas/ScrollingRasterDM.h>


#include <casa/aips.h>
#include <casa/iostream.h>
#include <casa/sstream.h>

#include <casa/BasicSL/String.h>
#include <casa/BasicSL/Constants.h>

#include <casa/Quanta/MVTime.h>
#include <casa/OS/Time.h>

#include <casa/Exceptions/Error.h>

#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/Slicer.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Arrays/ArrayIter.h>
#include <casa/Arrays/Cube.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/ArrayMath.h>

#include <casa/Utilities/Assert.h>
#include <casa/Containers/Record.h>

#include <tasking/Glish.h>
#include <tasking/Glish/GlishValue.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>

#include <lattices/Lattices/ArrayLattice.h>


#include <lattices/Lattices/SubLattice.h>
#include <lattices/Lattices/LatticeConcat.h>
#include <lattices/Lattices/MaskedLattice.h>
#include <lattices/Lattices/LatticeStatistics.h>

#include <coordinates/Coordinates/CoordinateSystem.h>
#include <coordinates/Coordinates/LinearCoordinate.h>
#include <coordinates/Coordinates/SpectralCoordinate.h>
#include <coordinates/Coordinates/DirectionCoordinate.h>

#include <display/DisplayCanvas/WCResampleHandler.h>
#include <display/Display/Attribute.h>

namespace casa {

//#define CDEBUG 1

// --------------------------------------------------------------------------------
// MonitorData class is used to parse glish records received from pksmonitor
//

class MonitorData {
public:
  MonitorData();
  virtual ~MonitorData();
  CoordinateSystem *getCoordinateSystem();
  Bool getData(Array<Float> &);

  Bool getMonitorHeader(GlishRecord &);
  Bool getMonitorHeader(const Record &);

  Bool getMonitorData(GlishRecord &);
  Bool getMonitorData(const Record &);
  
  Bool computeCoordinateSystem();

  Float getDataMax() { return itsDataMax; }
  Float getDataMin() { return itsDataMin; }
  uInt getScanNumber() { return itsScanNumber; }
  uInt getChannelNumber() { return itsData.shape()[0]; }
  uInt getBeamNumber() { return itsData.shape()[1]; }
  uInt getSpecNumber() { return itsData.shape()[2]; }

protected:
  GlishRecord & arg2();
  Bool getHeader();
  void computeMinMax();

private:
  //
  // getParm function taken from:
  //
  //# pksmb_support.h,v 19.1 2004/02/26 00:28:41 mcalabre 
  //---------------------------------------------------------------------------
  
  template<class T> Bool getParm(const GlishRecord &parms,
				 const String &item,
				 const T &default_val, T &value);
  template<class T> Bool getParm(const GlishRecord &parms,
				 const String &item,
				 const T &default_val,
				 Array<T> &value);
  template<class T> Bool getParm(const GlishRecord &parms,
				 const String &item,
				 const Array<T> &default_val,
				 Array<T> &value);
  
  Int itsArg1;
  GlishRecord itsArg2;

  GlishRecord itsHArg1;
  Int itsHArg2;

  GlishRecord itsHeader;
  Array<Int> itsBeamNo;
  Array<Double> itsRAvsBeam;
  Array<Double> itsDECvsBeam;
  Array<Float> itsData;

  Array<Int> itsImageShape;
  Array<String> itsAxisNames;
  Array<Double> itsRefPixels;
  Array<Double> itsRefValues;
  Array<Double> itsDeltas;
  Array<Double> itsPCMatrix;
  Array<Double> itsProjParams;
  Double itsLongPole;
  String itsDataUnits;
  Float itsBlankVal;

  CoordinateSystem itsCoordinateSystem;

  Int itsScanNumber;
  Float itsDataMax;
  Float itsDataMin;

  Bool itsFreqAxis;
};

// --------------------------------------------------------------------------------

PKSMultiBeamDD::PKSMultiBeamDD(uInt scanNo):
  ScrollingRasterDD(4, IPosition(4, 512, 1, 1, 1),
    Vector<String>(4, ""), Vector<String>(4, ""), 3, scanNo)
{

  Vector<String> axisVec(4);
  axisVec(0) = "Frequency";
  axisVec(1) = "Time";
  axisVec(2) = "IF number";
  axisVec(3) = "Beam No.";

  Vector<String> unitVec(4);

  unitVec(0) = "GHz";
  unitVec(1) = "s";
  unitVec(2) = "";
  unitVec(3) = "";
#ifdef CDEBUG
  cerr << "PKSMultiBeamDD::PKSMultiBeamDD - creating CSys ...";
#endif
  CoordinateSystem cs = coordinateSystem();
  cs.setWorldAxisNames(axisVec);
  cs.setWorldAxisUnits(unitVec);
  setCoordinateSystem(cs);  
#ifdef CDEBUG
  cerr << " ... set." << endl;
#endif  
  setup(fixedPos());
  getMinAndMax();
  setupElements();
  setDefaultOptions();
}

void PKSMultiBeamDD::initLattice(const Record &rec)
{
  static MonitorData mondata;

  mondata.getMonitorHeader(rec);

  setHeaderMin(mondata.getDataMin()); 
  setHeaderMax(mondata.getDataMax()); 
  setScanNumber(mondata.getScanNumber()); 

  setLatticeShape(IPosition (4, 
  	                     mondata.getChannelNumber(),
  	                     1, // nPol or nIF ?
	                     mondata.getSpecNumber(),
                             mondata.getBeamNumber()
		            ));
#ifdef CDEBUG
  cerr << "PKSMultiBeamDD::initLattice(Record) - itsLatticeShape set to " 
       << latticeShape() << endl;
#endif
  setHeaderReceived(True);
  
  ScrollingRasterDD::initLattice(rec);
}
void PKSMultiBeamDD::updateLattice(const Record &rec)
{
  static MonitorData mondata;
  mondata.getMonitorData(rec);
  
  Array<Float> arr;

  if (!mondata.getData(arr)) {
    throw AipsError("MonitorData::getData failed!");
  }

  IPosition arrShape = arr.shape();
  IPosition baseShape = latticesShape(); 

/* not really needed - this axis is not used for determining if resize is needed
  baseShape(itsShiftAxis) = 0;
  for (uInt i=0; i<itsLatticesNo; i++)
    baseShape(itsShiftAxis) += itsLattices[i]->shape()(itsShiftAxis);
*/
  setNeedResize(False);

  uInt i = 0;
  while ((i < arr.ndim()) && (!needResize())) {
    if (i != shiftAxis()) {
      setNeedResize(needResize() || ( arrShape(i) != baseShape(i) )); 
    }
    i++;
  }
#ifdef CDEBUG
  if (needResize()) {
    cerr << "new Shape is = " << arrShape << endl;
  }
#endif  
  mondata.computeCoordinateSystem();

  updateLatticeConcat(&arr, mondata.getCoordinateSystem());

  String attString;

  attString = "newCoordinates";
  Attribute newcoordAttr (attString, True); 
  setAttributeOnPrimaryWCHs(newcoordAttr);
	
  attString = "resetCoordinates";
  Attribute resetAttr (attString, True);
  setAttributeOnPrimaryWCHs(resetAttr);
}

const Unit PKSMultiBeamDD::dataUnit(){
  Unit JyPerBeam ("Jy/beam");
  return JyPerBeam;
}

String PKSMultiBeamDD::showValue(const Vector<Double> &world) {
  Vector<Double> fullWorld, fullPixel;
  String retval;
  if (!getFullCoord(fullWorld, fullPixel, world)) {
    retval = "invalid";
    return retval;
  }
  Int length = fullPixel.shape()(0);
  IPosition ipos(length);
  for (Int i = 0; i < length; i++) {
    ipos(i) = Int(fullPixel(i) + 0.5);
    if ( (ipos(i) < 0) || (ipos(i) >= dataShape()(i)) ) {
      retval = "invalid";
      return retval;
    }
  }
  if (!maskValue(ipos)) {
    retval = "masked";
    return retval;
  }
  ostringstream oss;
  oss.setf(ios::scientific, ios::floatfield);
  oss.setf(ios::showpos);
  oss.precision(3);
  Quantum<Float> qtm(dataValue(ipos), dataUnit());
  qtm.print(oss);
  retval = String(oss);
  
  return retval;
}

// (Required) copy constructor.
PKSMultiBeamDD::PKSMultiBeamDD(const PKSMultiBeamDD &other) {
}

// (Required) copy assignment.
void PKSMultiBeamDD::operator=(const PKSMultiBeamDD &other) {
}

PKSMultiBeamDD::~PKSMultiBeamDD(){
#ifdef CDEBUG
  cerr << "PKSMultiBeamDD::~PKSMultiBeamDD() called." << endl;
#endif
}


// implementation section of MonitorData:


MonitorData::MonitorData():
  itsScanNumber(100),
  itsDataMax(-C::dbl_max),
  itsDataMin(C::dbl_max)
{
}

Bool MonitorData::getHeader() {
  getParm(itsHeader, "imageShape", 0, itsImageShape);
  getParm(itsHeader, "axisNames", String(""), itsAxisNames);
  getParm(itsHeader, "referencePixels", 0.0, itsRefPixels);
  getParm(itsHeader, "referenceValues", 0.0, itsRefValues);
  getParm(itsHeader, "deltas", 0.0, itsDeltas);
  getParm(itsHeader, "pcmatrix", 0.0, itsPCMatrix);
  getParm(itsHeader, "projectionParameters", 0.0, itsProjParams);
  getParm(itsHeader, "longpole", 0.0, itsLongPole);
  getParm(itsHeader, "dataUnits", String(""), itsDataUnits);
  getParm(itsHeader, "blankVal", 0.0f, itsBlankVal);
#ifdef CDEBUG
  cerr << "itsImageShape = " << itsImageShape << " added." << endl;
  cerr << "itsAxisNames = " << itsAxisNames << " added." << endl;
  cerr << "itsRefPixels = " << itsRefPixels << " added." << endl;
  cerr << "itsRefValues = " << itsRefValues << " added." << endl;
  cerr << "itsDeltas = " << itsDeltas << " added." << endl;
  cerr << "itsPCMatrix = " << itsPCMatrix << " added." << endl;
  cerr << "itsProjParams = " << itsProjParams<< " added." << endl;
  cerr << "itsLongPole = " << itsLongPole << " added." << endl;
  cerr << "itsDataUnits = " << itsDataUnits << " added." << endl;
  cerr << "itsBlankVal = " << itsBlankVal << " added." << endl;
#endif 
  return True;
}

Bool MonitorData::getMonitorHeader(const Record &rec) {
  GlishRecord grec;
  grec.fromRecord(rec);
  
  Bool retval = getMonitorHeader(grec); 
  computeMinMax();

  return retval;
}

Bool MonitorData::getMonitorHeader(GlishRecord &rec) {
#ifdef CDEBUG
  cerr << "MonitorData - constructing header from a glish record:" << endl;
  cerr << rec.description() << endl;
#endif

  //arg1:SUBRECORD, arg2:Int

  if (!rec.exists("arg1")) {
    throw AipsError("MonitorData - arg1 not found in header.");
  }
  if (!rec.exists("arg2")) {
    throw AipsError("MonitorData - arg2 not found in header.");
  }
  if (rec.get("arg1").type() != GlishValue::RECORD) {
    throw AipsError("MonitorData - header.arg1 is not a subrecord.");
  }
    
  // arg1, arg2
  itsHArg1 = rec.get("arg1");
  getParm(rec, "arg2", 0, itsHArg2);

#ifdef CDEBUG
  cerr << "itsHArg1 = " << itsHArg1.description() << " added." << endl;
  cerr << "itsHArg2 = " << itsHArg2 << " added." << endl;
#endif
  itsScanNumber = itsHArg2;

  // arg1.header 

  itsHeader = itsHArg1.get("header");
#ifdef CDEBUG
  cerr << "HEADER: itsHeader = " 
       << itsHeader.description()  
       << " found." 
       << endl;
#endif

  // fetch header variables
  getHeader();  // <------  H E A D E R
    
  // arg1.BeamNo

  getParm(itsHArg1, "BeamNo", 0, itsBeamNo);
#ifdef CDEBUG
  cerr << "HEADER: itsBeamNo = " << itsBeamNo << " added." << endl;
#endif

    // arg1.RAvsBeam, arg1.DECvsBeam

  getParm(itsHArg1, "RAvsBeam", 0.0, itsRAvsBeam);
#ifdef CDEBUG
  cerr << "HEADER: itsRAvsBeam = " << itsRAvsBeam << " added." << endl;
#endif

  getParm(itsHArg1, "DECvsBeam", 0.0, itsDECvsBeam);
#ifdef CDEBUG
  cerr << "HEADER: itsDECvsBeam = " << itsDECvsBeam << " added." << endl;
#endif
   
  // arg2.data

  getParm(itsHArg1, "data", 0.0f, itsData);
#ifdef CDEBUG
  cerr << "HEADER: itsData (shape = " << itsData.shape() << ") added." << endl;
#endif

  return True;
}

Bool MonitorData::getMonitorData(const Record &rec)
{
  GlishRecord grec;
  grec.fromRecord(rec);

  return getMonitorData(grec);
}

Bool MonitorData::getMonitorData(GlishRecord &rec)
{
#ifdef CDEBUG
  cerr << "MonitorData - constructing data from a GLISH RECORD:" << endl;
  cerr << rec.description() << endl;
#endif
  if (!rec.exists("arg1")){
    throw AipsError("MonitorData - arg1 not found in glish record.");
  }
  if (!rec.exists("arg2")){
    throw AipsError("MonitorData - arg2 not found in glish record.");
  }
  if (rec.get("arg2").type() != GlishValue::RECORD){
    throw AipsError("MonitorData - arg2 is not a subrecord.");
  }

  // arg1, arg2
  getParm(rec, "arg1", 0, itsArg1);
#ifdef CDEBUG
  cerr << "itsArg1 = " << itsArg1 << " added." << endl;
#endif  
  itsArg2 = rec.get("arg2");
#ifdef CDEBUG
  cerr << "itsArg2 = " << itsArg2.description() << " added." << endl;
#endif
   
  // arg2.header 

  itsHeader = itsArg2.get("header");
#ifdef CDEBUG
  cerr << "itsHeader = " << itsHeader.description() << " found." << endl;
#endif

  // fetch header variables
  getHeader();  // <------  H E A D E R
    
  // arg2.BeamNo

  getParm(itsArg2, "BeamNo", 0, itsBeamNo);
#ifdef CDEBUG
  cerr << "itsBeamNo = " << itsBeamNo << " added." << endl;
#endif

  // arg2.RAvsBeam, arg2.DECvsBeam

  getParm(itsArg2, "RAvsBeam", 0.0, itsRAvsBeam);
  getParm(itsArg2, "DECvsBeam", 0.0, itsDECvsBeam);
#ifdef CDEBUG
  cerr << "itsRAvsBeam = " << itsRAvsBeam << " added." << endl;
#endif
#ifdef CDEBUG
  cerr << "itsDECvsBeam = " << itsDECvsBeam << " added." << endl;
#endif
   
  // arg2.data
   
  getParm(itsArg2, "data", 0.0f, itsData);
#ifdef CDEBUG
  cerr << "itsData (shape = " << itsData.shape() << ") added." << endl;
#endif
  return True;
}

Bool MonitorData::computeCoordinateSystem() {
  //SpectralCoordinate fcoord(MFrequency::TOPO, itsRefValues[0], 
    //itsDeltas[0], itsRefPixels[0], 1.420405752E9);

// in its... members: FREQ, BEAM, TIME, we are adding POL at the end
// in data array we need: FREQ, TIME, POL, BEAM -> will have to transpose
  
  Vector<Int> newOrder(4);
  newOrder(0) = 0; newOrder(1) = 2; newOrder(2) = 3; newOrder(3) = 1;

#ifdef CDEBUG
  cerr << "Computing crpix...";
#endif
  Vector<Double> crpix(4); 
    for (uInt i=0; i<3; i++) {
      crpix[i] = itsRefPixels.operator()(IPosition(1,i));
    }
    crpix[3] = 1.0;
#ifdef CDEBUG
  cerr << " done." << endl;;
  cerr << "Computing crval...";
#endif
  Vector<Double> crval(4); 
    for (uInt i=0; i<3; i++) {
      crval[i] = itsRefValues.operator()(IPosition(1,i));
    }
    crval[3] = 1.0;
#ifdef CDEBUG
  cerr << " done." << endl;;
  cerr << "Computing cdelt...";
#endif
  Vector<Double> cdelt(4);
    for (uInt i=0; i<3; i++) {
      cdelt[i] = itsDeltas.operator()(IPosition(1,i));
    }
    cdelt[3] = 1.0;
#ifdef CDEBUG
  cerr << " done." << endl;;
  cerr << "Computing pc...";
#endif

  Matrix<Double> pc(4,4); pc = 0.0; pc.diagonal() = 1.0;

#ifdef CDEBUG
  cerr << "pc = " << pc;

  cerr << " done." << endl;
  cerr << "Computing names...";
#endif

  Vector<String> names(4);
    for (uInt i=0; i<3; i++) {
      names[i] = itsAxisNames.operator()(IPosition(1,i));
    }
    names[3] = "POL";

#ifdef CDEBUG
  cerr << " done." << endl;;
  cerr << "Computing units...";
#endif

  Vector<String> units(4);
  // 1 - Beam No., 3 - POL
  units[0] = "GHz"; units[1] = ""; units[2] = "s"; units[3] = "";

#ifdef CDEBUG
  cerr << " done." << endl;;
#endif

//    Matrix<Double> pc(1,1); pc= 0; pc.diagonal() = 1.0;
//    LinearCoordinate lin(names, units, crval, cdelt, pc, crpix);

#ifdef CDEBUG
  cerr << "newOrder not yet applied." << endl;

  cerr << "Creating lcoord...:" << endl;
  cerr << "names = " << names << endl;
  cerr << "units = " << units << endl;
  cerr << "crval = " << crval << endl;
  cerr << "cdelt = " << cdelt << endl;
  cerr << "pc = " << pc << endl;
  cerr << "crpix = " << crpix << endl;
#endif

  Double crval_Freq = crval(0);
  Double cdelt_Freq = cdelt(0);
  Double crpix_Freq = crpix(0);


  Vector<String> names_Lin(3); 
  for (uInt i=0; i<3; i++) {
    names_Lin(i) = names(i+1);
  }

  Vector<String> units_Lin(3); 
  for (uInt i=0; i<3; i++) {
    units_Lin(i) = units(i+1);
  }

  Matrix<Double> pc_Lin(3,3); pc_Lin = 0.0; pc_Lin.diagonal() = 1.0;

  Vector<Double> crval_Lin(3); 
  for (uInt i=0; i<3; i++) {
    crval_Lin(i) = crval(i+1);
  }

  Vector<Double> cdelt_Lin(3); 
  for (uInt i=0; i<3; i++) {
    cdelt_Lin(i) = cdelt(i+1);
  }

  Vector<Double> crpix_Lin(3); 
  for (uInt i=0; i<3; i++) {
    crpix_Lin(i) = crpix(i+1);
  }


  Double restFrequency = 1.420405752e9; // HI here - should not hardcode this...
  					// - take this from the header

  MVTime valTime(crval_Lin(1)/24.0/3600.0);
  valTime.setFormat(MVTime::FITS);
  Time tLin = valTime.getTime();

#ifdef CDEBUG
  cerr << "MVTime computed from " << crval_Lin(1) 
       << " (" << crval_Lin(1)/24.0/3600.0 << ") is" << endl
       << valTime << "..." << endl;
  cerr << " = " << tLin.hours()
       << ":" << tLin.minutes()
       << ":" << tLin.seconds() << "....." 
       << endl;
#endif
       
  // move from s to hr
  crval_Lin(1) = tLin.hours() + 
                 tLin.minutes()/60.0 + 
		 tLin.seconds()/3600.0;

#ifdef CDEBUG 
  cerr << "new crval_Lin(1) = " << crval_Lin(1) << "..." << endl;
#endif

  units_Lin(1) = "h";
  cdelt_Lin(1) /= 3600.0;
  pc_Lin(1,1) = -1; 

#ifdef CDEBUG
  cerr << "After computing _Lin arrays:" << endl;
  cerr << "crval_Lin = " << crval_Lin << endl;
  cerr << "cdelt_Lin = " << cdelt_Lin << endl;
  cerr << "units_Lin = " << units_Lin << endl;
  cerr << "pc_Lin    = " << pc_Lin << endl;
  cerr << "crpix_Lin = " << crpix_Lin << endl;
#endif

  Vector<String> units_Spec(1); units_Spec[0] = units[0];
  SpectralCoordinate scoord(MFrequency::TOPO, 
    crval_Freq, cdelt_Freq, crpix_Freq, restFrequency);
  if (!scoord.setWorldAxisUnits(units_Spec)) {
    throw AipsError ("MonitorData:: cannot setWorldAxisUnits for spectral coordinate.");
  }

  LinearCoordinate lcoord(names_Lin, units_Lin, 
    crval_Lin, cdelt_Lin, pc_Lin, crpix_Lin);


#ifdef CDEBUG
  cerr << "lcoord created." << endl;
#endif

  // somehow clear & refresh CoordinateSystem here... -> ???

  CoordinateSystem newCoordinateSystem;
  itsCoordinateSystem = newCoordinateSystem;
  itsCoordinateSystem.addCoordinate(scoord);
  itsCoordinateSystem.addCoordinate(lcoord);

  Vector<String> tempvec(4);
  //tempvec(0) = "Frequency";
  tempvec(0) = "Frequency"; // should depend on obsmode record
                                   // got from pksmonitor 
  tempvec(1) = "Beam No.";
  tempvec(2) = "Time";
  tempvec(3) = "Polarisation";

  itsCoordinateSystem.setWorldAxisNames(tempvec);
#ifdef CDEBUG
  cerr << "  coordinates added." << endl;
#endif

  itsCoordinateSystem.transpose(newOrder, newOrder);
  
#ifdef CDEBUG
  cerr << " and newOrder now applied:" << endl;

  for (uInt i=0; i<itsCoordinateSystem.nCoordinates(); i++)
  {
    cerr << "i = " << i << endl
         << "  type: " << itsCoordinateSystem.showType(i) << endl
	 << "  axes: " << itsCoordinateSystem.coordinate(i).worldAxisNames() << endl
	 << "  units:" << itsCoordinateSystem.coordinate(i).worldAxisUnits() << endl;
  }
#endif

  return True;
}

MonitorData::~MonitorData() { }

CoordinateSystem *MonitorData::getCoordinateSystem()
{
  return &itsCoordinateSystem;
}

Bool MonitorData::getData(Array<Float> &arr)
{
//const uInt freqAxis = 0; const uInt timeAxis = 1;
//const uInt polAxis  = 2; const uInt beamAxis = 3;

  IPosition imgShape(itsImageShape); // NFREQ x NBEAM x NTIME
//IPosition dataShape(4, imgShape(0), imgShape(1), 1, imgShape(2));
  IPosition dataShape(4, imgShape(0), imgShape(2), 1, imgShape(1));
                                        // NFREQ x NTIME x NPOL=1 x NBEAM
  arr.resize(dataShape);              
#ifdef CDEBUG
  cerr << "MonitorData::getData :" << endl;
  cerr << "  imgShape = " << imgShape << endl;
  cerr << "  dataShape = " << dataShape << endl;
#endif
// Cube axes: FREQ, BEAM, TIME
  Cube<Float> cube; cube.reference(itsData);

#ifdef CDEBUG      
  cerr << "Cube referencing itsData made." << endl;
#endif
//iStart - iEnd -> whole array
  IPosition iStart = dataShape; iStart = 0; IPosition iEnd = dataShape - 1;

#ifdef CDEBUG
  cerr << "DATA CUBE HAS " << cube.nplane() << " PLANES..." << endl;
#endif

  for (uInt t=0; t<cube.nplane(); t++){
    iStart(1) = iEnd(1) = t; // time slice No. t
    iStart(2) = iEnd(2) = 0; // only pol=0  -> pols are split by pksmonitor
#ifdef CDEBUG      
    cerr << "Cube time slice(" << t << ") --->" << endl;
    cerr << " iStart = " << iStart << endl;
    cerr << " iEnd = " << iEnd << endl;
#endif
    Array<Float> sliceArr = arr(iStart, iEnd).reform(cube.xyPlane(t).shape());
#ifdef CDEBUG
    cerr << " sliceArr(" << sliceArr.shape() << ") selected." << endl;
#endif
    sliceArr = (cube.xyPlane(t)).copy();
#ifdef CDEBUG
    cerr << "   and copied." << endl;
#endif
  }
  return True;
}

void MonitorData::computeMinMax() {
  minMax(itsDataMin, itsDataMax, itsData); 
}

//
// getParm function taken from:
//
//# pksmb_support.cc,v 19.4 2004/04/05 06:32:20 mcalabre 
//----------------------------------------------------------------------------

template<class T>
Bool MonitorData::getParm(const GlishRecord &parms,
             const String &item,
             const T &default_val,
             T &value)
{
  if (parms.exists(item)) {
    GlishArray tmp = parms.get(item);
    tmp.get(value);
    return True;
  } else {
    value = default_val;
    return False;
  }
}

template Bool MonitorData::getParm(const GlishRecord &parms, 
				   const String &item,
				   const Bool &default_val, Bool &value);
template Bool MonitorData::getParm(const GlishRecord &parms,
				   const String &item,
				   const Int &default_val, Int &value);
template Bool MonitorData::getParm(const GlishRecord &parms,
				   const String &item,
				   const Float &default_val, Float &value);
template Bool MonitorData::getParm(const GlishRecord &parms,
				   const String &item,
				   const Double &default_val, Double &value);
template Bool MonitorData::getParm(const GlishRecord &parms,
				   const String &item,
				   const Complex &default_val, Complex &value);
template Bool MonitorData::getParm(const GlishRecord &parms,
				   const String &item,
				   const String &default_val, String &value);

template<class T>
Bool MonitorData::getParm(const GlishRecord &parms,
			  const String &item,
			  const T &default_val,
             Array<T> &value)
{
  if (parms.exists(item)) {
    GlishArray tmp = parms.get(item);
    tmp.get(value);
    return True;
  } else {
    value = default_val;
    return False;
  }
}

template Bool MonitorData::getParm(const GlishRecord &parms,
				   const String &item,
				   const Bool &default_val,
				   Array<Bool> &value);
template Bool MonitorData::getParm(const GlishRecord &parms,
				   const String &item,
				   const Int &default_val, Array<Int> &value);
template Bool MonitorData::getParm(const GlishRecord &parms,
				   const String &item,
				   const Float &default_val,
				   Array<Float> &value);
template Bool MonitorData::getParm(const GlishRecord &parms,
				   const String &item,
				   const Double &default_val,
				   Array<Double> &value);
template Bool MonitorData::getParm(const GlishRecord &parms,
				   const String &item,
				   const Complex &default_val,
				   Array<Complex> &value);
template Bool MonitorData::getParm(const GlishRecord &parms,
				   const String &item,
				   const String &default_val,
				   Array<String> &value);

template<class T>
Bool MonitorData::getParm(const GlishRecord &parms,
			  const String &item,
			  const Array<T> &default_val,
			  Array<T> &value)
{
  if (parms.exists(item)) {
    GlishArray tmp = parms.get(item);
    tmp.get(value);
    return True;
  } else {
    value = default_val;
    return False;
  }
}

template Bool MonitorData::getParm(const GlishRecord &parms,
				   const String &item,
				   const Array<Bool> &default_val,
				   Array<Bool> &value);
template Bool MonitorData::getParm(const GlishRecord &parms,
				   const String &item,
				   const Array<Int> &default_val,
				   Array<Int> &value);
template Bool MonitorData::getParm(const GlishRecord &parms,
				   const String &item,
				   const Array<Float> &default_val,
				   Array<Float> &value);
template Bool MonitorData::getParm(const GlishRecord &parms,
				   const String &item,
				   const Array<Double> &default_val,
				   Array<Double> &value);
template Bool MonitorData::getParm(const GlishRecord &parms,
				   const String &item,
				   const Array<Complex> &default_val,
				   Array<Complex> &value);
template Bool MonitorData::getParm(const GlishRecord &parms,
				   const String &item,
				   const Array<String> &default_val,
				   Array<String> &value);

} //#End namespace casa
