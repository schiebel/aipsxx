//# GSDDataSource.cc : class for access to GSD datasets from the JCMT
//# Copyright (C) 1996,1997,1998,2002,2003
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: GSDDataSource.cc,v 19.3 2006/05/31 14:15:09 gvandiep Exp $

#include <hia/GSDDataSource/GSDDataSource.h>
#include <casa/iostream.h>
#include <casa/Arrays/ArrayIter.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayUtil.h>
#include <ms/MeasurementSets.h>
#include <measures/Measures.h>
#include <measures/Measures/MeasTable.h>
#include <tables/Tables.h>

extern "C" {
  #include <gsdlib/gsd.h>
}

GSDDataSource::GSDDataSource (const String gsdin) :
 _file (gsdin)
{
  try {
// 
// Open the GSD file
//
    int gsdOpen = gsdOpenRead (const_cast<char *> (_file.c_str()),
      &_version, _label, &_numItems,&_filePtr, &_fileDesc, &_itemDesc, 
      &_dataPtr);
    switch (gsdOpen) {
      case 0:
        break;
      case 1:
        throw(AipsError(String(" Failure to open named file")));
      case 2:
        throw(AipsError(String(" Failure to read file_dsc from file")));
      case 3:
        throw(AipsError(
         String(" Failure to allocate memory for item_dsc")));
      case 4:
        throw(AipsError(String(" Failure to read item_dsc from file")));
      case 6:
        throw(AipsError(String(" Failure to read data_ptr from file")));
      case 7:
        throw(AipsError(
         String(" Failure to allocate memory for data_ptr")));
      default:
        throw(AipsError(String(" Unknown error opening file")));
    }
//
// Read and report some general parameters.
//
    cout << String ("GSD version is ") << _version << endl;
    int itemp;
    String name, units;
    getItem ("C1TEL", name, units);
    getItem("C1SNO", itemp, units);
    getItem("C6ST", _obsType, units);
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::GSDDataSource|");
    throw (AipsError (message));
  }
}


GSDDataSource::~GSDDataSource() 
{
  try {
//
// Close the GSD file.
//
    int gsdclose = gsdClose (_filePtr, _fileDesc, _itemDesc, _dataPtr);
    switch (gsdclose) {
      case 0:
        break;
      default:
        throw(AipsError(" Error closing GSD file"));
    }
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::~GSDDataSource|");
    throw (AipsError (message));
  }
}


void GSDDataSource::copyData52 (MeasurementSet& measurementSet,
 Array<Float>& gsdData, Array<Int>& c3lspc) {
  try {
    cout << "-- filling MAIN Table" << endl;
//
// Get day on which data were taken.
//
    String units;
    Double c3dat, c3ut;
    getItem ("C3DAT", c3dat, units);
    getItem ("C3UT", c3ut, units);
    Int year = ifloor (c3dat);
    c3dat -= year;
    c3dat *= 100.0;
    Int month = ifloor (c3dat);
    c3dat -= month;
    Double day = c3dat * 100.0;
    MVTime dayMV (year, month, day);
    MEpoch dayEpoch (dayMV.get(), MEpoch::Ref (MEpoch::UT1 + 
     MEpoch::RAZE));
//    MEpoch::Convert ut12gmst1(MEpoch::UT1,MEpoch::GMST1);
//    cout << ut12gmst1(dayEpoch) << endl;
//
// Get the scan table containing the LST for start of each scan.
//
    vector<String> dimNames;
    Array<Double> c12scan_table_1;
    getArray ("C12SCAN_TABLE_1", c12scan_table_1, dimNames);
//
// Calculate the integration time per point.
//
    Int c3mxp;
    getItem ("C3MXP", c3mxp, units);
    Double c3srt;
    getItem ("C3SRT", c3srt, units);
    Quantity intTime (c3srt/c3mxp, "s");
//
// Generate the reference for the MEpoch to be used to describe the
// time the data were obtained. It uses dayEpoch as an offset. Also
// make the converter from LMST to UT1.
//
    MEpoch::Ref lstRef (MEpoch::LMST, MeasFrame (_obsPosition), dayEpoch);
    MEpoch::Convert lmst2ut1 (lstRef, MEpoch::UT1);
//
// Some test code that tries to convert from c3lst to c3ut and from 
// RA2000 Dec2000 to alt-az. The time calculation agrees with the 
// Astronomical Almanac but differs from c3ut by about 1.6 sec. The
// alt and az differ from the file header values by ~0.05 degree. Don't 
// know what calculates these things at the telescope so don't know
// if this is serious.
//
//    Double c3lst;
//    getItem ("C3LST", c3lst, units);
//    Quantity startlst (c3lst - 1.62 / 3600.0, "h");
//    MEpoch startut1 = lmst2ut1 (MEpoch (startlst, lstRef));
//    MeasFrame thisFrame = _frame;
//    thisFrame.set (startut1);
//    MDirection::Convert toAltAz (MDirection::J2000, 
//     MDirection::Ref (MDirection::AZEL, thisFrame));
//    MDirection altaz = toAltAz (_sourceDirection);
//    cout.precision (12);
//    cout << startut1.getValue().get() << endl;
//    cout << _sourceDirection.getValue().get() << endl;
//    cout << altaz.getValue().get() << endl;

// Get pointers to column fields, except TIME as can't figure out how
// to compile a RecordFieldPtr<MEpoch>.
//
    TableRow tableRow (measurementSet, stringToVector (
     MS::columnName (MS::DATA_DESC_ID) + "," +
     MS::columnName (MS::FEED1) + "," +
     MS::columnName (MS::FEED2) + "," +
     MS::columnName (MS::FIELD_ID) + "," +
     MS::columnName (MS::FLOAT_DATA) + "," +
     MS::columnName (MS::FLAG) + "," +
     MS::columnName (MS::SCAN_NUMBER)));
    RecordFieldPtr<Int> dataDescPtr (tableRow.record(),
     MS::columnName (MS::DATA_DESC_ID));
    RecordFieldPtr<Int> feed1Ptr (tableRow.record(), 
     MS::columnName (MS::FEED1));
    RecordFieldPtr<Int> feed2Ptr (tableRow.record(), 
     MS::columnName (MS::FEED2));
    RecordFieldPtr<Int> fieldIdPtr (tableRow.record(), 
     MS::columnName (MS::FIELD_ID));
    RecordFieldPtr<Array<Float> > floatDataPtr (tableRow.record(), 
     MS::columnName (MS::FLOAT_DATA));
    RecordFieldPtr<Array<Bool> > flagPtr (tableRow.record(), 
     MS::columnName (MS::FLAG));
    RecordFieldPtr<Int> scanPtr (tableRow.record(), 
     MS::columnName (MS::SCAN_NUMBER));

    ArrayIterator<Float> dataIter (gsdData, 1);   
    IPosition dataShape = gsdData.shape();
    Int row = 0;
    Int scan = 0;
    for (; !dataIter.pastEnd (); dataIter.next ()) {
//
// Get data.
//
      Array<Float> integration = dataIter.array();
      Int dataStart = 0;
      Int dataEnd = -1;
//
// Get time of data. Take care to convert integration time to sidereal
// seconds.
//
      Int gsdScan = scan / c3mxp;
      Int gsdMeasurement = scan % c3mxp;
//
// If the LST of scan start is 0 then this scan was not actually done.
//
      if (!near (c12scan_table_1 (IPosition(2,0,gsdScan)), 0.0)) { 
        Quantity lstStart (c12scan_table_1 (IPosition(2,0,gsdScan)), "h");
        Quantity measTime = Quantity (gsdMeasurement + 0.5) * intTime /
         0.9972695663;
        measTime.convert ("h");
        MVEpoch mvLST (lstStart + measTime);
        MEpoch timeut1 = lmst2ut1 (MEpoch (mvLST, lstRef));
//      if (first) {
//        cout << gsdScan << endl;
//        cout << gsdMeasurement << endl;
//        cout << mvLST << endl;
//        cout << lstRef << endl;
//        cout << time << endl;
//        cout << timeut1 << endl;
//        first = False;
//      }

        for (Int section=0; section < c3lspc.shape()(0); section++) {
          measurementSet.addRow ();
          *dataDescPtr = _section2DataDesc [section];
          dataStart = dataEnd + 1;
          dataEnd = dataStart + c3lspc (IPosition (1, section)) - 1;
          *floatDataPtr = integration.reform (IPosition (2,1,dataShape(0)))(
           IPosition (2, 0, dataStart), IPosition (2, 0, dataEnd));
          *flagPtr = Array<Bool> (IPosition (2,1,dataShape(0)), False) (
           IPosition (2, 0, dataStart), IPosition (2, 0, dataEnd));
          *fieldIdPtr = scan;
          *scanPtr = scan;
          *feed1Ptr = _desc2Pol [_section2DataDesc [section]];
          *feed2Ptr = _desc2Pol [_section2DataDesc [section]];

          tableRow.put (row);

          MSMainColumns columns (measurementSet);

          columns.timeMeas().put (row, timeut1);
          columns.timeCentroidMeas().put (row, timeut1);
          ++row;
        }
        _scanTime.push_back (timeut1); 
        ++scan;
      }
    }
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::copyData52|");
    throw (AipsError (message));
  }
}


void GSDDataSource::fill (const String msname) {
//  cout << "GSDDataSource::fill called" << endl;
  try {
    String units;
//
// Get the observatory position.
//
    if (MeasTable::Observatory (_obsPosition, "JCMT")) {
      cout << "Using JCMT position from Observatory Table" << endl;
    } else {
      cout << "setting JCMT position from GSD file" << endl;  
      Double c1lat, c1long, c1hgt;
      getItem ("C1LONG", c1long, units);
      getItem ("C1LAT", c1lat, units);
      getItem ("C1HGT", c1hgt, units);
      _obsPosition = MPosition (Quantity (c1hgt, "km"),
       Quantity (-c1long, "deg"), Quantity (c1lat, "deg"));
    }
//
// Get the date and time of the observation start.
//
    Double c3dat, c3ut;
    getItem ("C3DAT", c3dat, units);
    getItem ("C3UT", c3ut, units);
    Int year = ifloor (c3dat);
    c3dat -= year;
    c3dat *= 100.0;
    Int month = ifloor (c3dat);
    c3dat -= month;
    Double day = floor (c3dat * 100.0);
    day += c3ut / 24.0;
    MVTime mvTime (year, month, day);
    _startEpoch = MEpoch (mvTime.get(), MEpoch::UT1);
//
// Get the source direction. Solar system objects not handled.
//
    double ra2000, dec2000;
    getItem ("C4RA2000", ra2000, units);
    getItem ("C4EDEC2000", dec2000, units);
    _sourceDirection = MDirection (Quantity (ra2000,"deg"),
     Quantity (dec2000,"deg"), MDirection::J2000);
//
// Construct a frame for the observatory.
//
    _frame = MeasFrame (_startEpoch, _obsPosition, _sourceDirection);
//
// Get the source velocity and set it in the frame.
//
    String c12vref;
    getItem ("C12VREF", c12vref, units);
    int lsrpos = c12vref.find ("LSR");
    int barypos = c12vref.find ("Barycentric");
    int heliopos = c12vref.find ("HELIO");
    int geopos = c12vref.find ("GEO");
    AlwaysAssert ((lsrpos!=-1) || (barypos!=-1) || (heliopos!=-1) ||
     (geopos!=-1), AipsError);
    double c7vr;
    getItem ("C7VR", c7vr, units);
    if (lsrpos != -1) {
      _sourceVelocity = MRadialVelocity (MVRadialVelocity (c7vr * 1e3),
       MRadialVelocity::LSRK);
    }
    if (barypos != -1) {
      _sourceVelocity = MRadialVelocity (MVRadialVelocity (c7vr * 1e3),
       MRadialVelocity::Ref (MRadialVelocity::BARY, _frame));
    }
    if (heliopos != -1) {
      _sourceVelocity = MRadialVelocity (MVRadialVelocity (c7vr * 1e3),
       MRadialVelocity::Ref (MRadialVelocity::BARY, _frame));
    }
    if (geopos != -1) {
      _sourceVelocity = MRadialVelocity (MVRadialVelocity (c7vr * 1e3),
       MRadialVelocity::Ref (MRadialVelocity::GEO, _frame));
    }
    _frame.set (_sourceVelocity);

//
// OK, create and fill the data part of the MS.
//
    MeasurementSet measurementSet;
    String::size_type ipos = _obsType.find ("RASTER");
    if (ipos != String::npos) {
      fillRasterData (msname, measurementSet);
    }
    ipos = _obsType.find ("SAMPLE");
    if (ipos != String::npos) {
      fillSampleData (msname, measurementSet);
    }
// validate causes a seg fault if used on a default constructed
// MeasurementSet.
    if (!measurementSet.validate()) {
      String message = "bad observation type: " + String
       (_obsType.c_str());
      throw (AipsError (message));
    }
//
// Set the FLAG column of the MS.
//
    
//
// Set the values of MAIN Table columns whose entries are all the same.
//
    MSColumns msColumns (measurementSet);
//
// Putting 0 in antenna1 and antenna2 is the recommended thing to do
// for single dish.
//
    msColumns.antenna1().fillColumn (0);
    msColumns.antenna2().fillColumn (0);
//
// Single-dish data so no ARRAY subTable.
//
    msColumns.arrayId().fillColumn (-1);
//
// The integration/exposure time for each measurement. For normal maps
// this equals the total time per scan (C3SRT) divided by the number of
// samples along the scan (C6XNP). For on-the-fly maps Remo has the SPECX
// reader do something that I don't understand 
//
    Double c3srt;
    getItem ("C3SRT", c3srt, units);
    Int c6xnp;
    getItem ("C6XNP", c6xnp, units);
    Double exposure = c3srt / c6xnp;
    for (uInt row=0; row < measurementSet.nrow(); ++row) {
      msColumns.exposureQuant().put (row, Quantum<Double> (exposure,"s"));
    }
    msColumns.flagRow().fillColumn (False);
//
// Make the interval (specified time per sample) the same as exposure
// (actual time spent measuring sample).
//
    for (uInt row=0; row < measurementSet.nrow(); ++row) {
      msColumns.intervalQuant().put (row, Quantum<Double> (exposure,"s"));
    }
    msColumns.sigma().fillColumn (Array<Float> (IPosition(1,1), 1.0));
    msColumns.weight().fillColumn (Array<Float> (IPosition(1,1), 1.0));
//
// Set the values in the sub-Tables.
//
    fillAntenna (measurementSet);
    fillDataDescription (measurementSet);
//    fillDoppler (measurementSet);
    fillFeed (measurementSet);
    fillField (measurementSet);
    fillObservation (measurementSet);
    msColumns.observationId().fillColumn (0);
    fillPointing (measurementSet);
    fillPolarization (measurementSet);
    fillProcessor (measurementSet);
    msColumns.processorId().fillColumn (0);
    fillSource (measurementSet);
    fillState (measurementSet);
    msColumns.stateId().fillColumn (0);
    fillSysCal (measurementSet);
    fillWeather (measurementSet);
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::fill|");
    throw (AipsError (message));
  }
}


void GSDDataSource::fillAntenna (MeasurementSet& measurementSet) const {
  try {
    cout << "-- filling ANTENNA sub-Table" << endl;
    MSAntenna msAntenna = measurementSet.antenna ();
    msAntenna.addRow ();
    MSAntennaColumns columns (msAntenna);
    columns.dishDiameterQuant().put (0, Quantum<Double> ((Double) 15.0,
     Unit ("m")));
    columns.flagRow().put (0, False);
    columns.mount().put (0, "ALT-AZ");
    columns.name().put (0, "JCMT");
    columns.offset().put (0, Array<Double> (IPosition (1, 3), (Double)
     0.0));
    columns.positionMeas().put (0, _obsPosition);
    columns.station().put (0, "JCMT");
    columns.type().put (0, "GROUND-BASED");
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::fillAntenna|");
    throw (AipsError (message));
  }
}


void GSDDataSource::fillDataDescription (MeasurementSet& measurementSet)
 const {
  try {
    cout << "-- filling DATA_DESCRIPTION sub-Table" << endl;
    MSDataDescription msDataDescription = measurementSet.dataDescription ();
    MSDataDescColumns columns (msDataDescription);
    for (uInt desc=0; desc<_desc2Pol.size(); ++desc) {
      msDataDescription.addRow ();
      columns.polarizationId().put (desc, _desc2Pol[desc]);
      columns.spectralWindowId().put (desc, _desc2spwId[desc]); 
      columns.flagRow().put (0, False);
    }
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::fillDataDescription|");
    throw (AipsError (message));
  }
}


/*
void GSDDataSource::fillDoppler (MeasurementSet& measurementSet) const {
  try {
    cout << "-- filling DOPPLER sub-Table" << endl;
//
// DOPPLER is an optional sub-Table not constructed by
// createDefaultSubtables, we must build it manually.
//
    TableDesc tableDesc = MSDoppler::requiredTableDesc ();
    SetupNewTable maker (measurementSet.dopplerTableName(), tableDesc,
     Table::New);
//
// Create the MS.
//
    MSDoppler msDoppler (maker);
    MSDopplerColumns columns (msDoppler);
    msDoppler.addRow ();
    columns.dopplerId().put (0, 0);
    columns.sourceId().put (0, 0);
    columns.transitionId().put (0, 0);
//
// Calculate the ratio of radial velocity to that of light.
//
    Quantum<Double> qc = QC::c;
    qc.convert ("m/s");
    Double c = qc.getValue ();
    Double v = _sourceVelocity.getValue().getValue();
    columns.velDefMeas().put (0, MDoppler (MVDoppler (v/c)));
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::fillDoppler|");
    throw (AipsError (message));
  }
}
*/


void GSDDataSource::fillFeed (MeasurementSet& measurementSet)
 const {
  try {
    cout << "-- filling FEED sub-Table" << endl;
//
// Get the time at which the observation started.
//
    MSMainColumns mainColumns (measurementSet);
    MEpoch first;
    mainColumns.timeMeas().get (0, first);
//
// Now fill the FEED table.
//
    MSFeed msFeed = measurementSet.feed ();
    MSFeedColumns columns (msFeed);
//
// The number of subsystems (Pol) is assumed to be the number of receptors
// in the receiver. Each receptor is assumed to lie in a separate feed.
//
    for (uInt pol=0; pol<_polVal.size(); ++pol) {
      msFeed.addRow ();
      columns.feedId().put (pol, pol);
      columns.timeMeas().put (pol, first); 
    }
    columns.antennaId().fillColumn (0);
    columns.spectralWindowId().fillColumn (-1);
    columns.interval().fillColumn (0);
    columns.numReceptors().fillColumn (1);
    columns.beamId().fillColumn (-1);
    columns.beamOffset().fillColumn (Array<Double> (IPosition(2, 2, 1), 0.0));
    columns.polarizationType().fillColumn (
     Array<String> (IPosition(1,1), "X")); 
    columns.polResponse().fillColumn (Array<Complex> (IPosition(2,1,1),
     Complex(1.0)));
    columns.position().fillColumn (Array<Double> (IPosition(1,3), 0.0));
    columns.receptorAngle().fillColumn (
     Array<Double> (IPosition(1,1), 0.0));
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::fillFeed|");
    throw (AipsError (message));
  }
}


void GSDDataSource::fillField (MeasurementSet& measurementSet)
 const {
  try {
    cout << "-- filling FIELD sub-Table" << endl;
//
// Get the time at which the observation started.
//
    MSMainColumns mainColumns (measurementSet);
    MEpoch first;
    mainColumns.timeMeas().get (0, first);
//
// Access FIELD table.
//
    MSField msField = measurementSet.field ();
    MSFieldColumns columns (msField);
//
// Get the centre and local coord systems, check they're the same or the
// simple method used below won't work.
//
    String units;
    String c4csc, c4lsc;
    getItem ("C4CSC", c4csc, units);
    getItem ("C4LSC", c4lsc, units);
    c4csc.gsub (RXwhite, "");
    c4lsc.gsub (RXwhite, "");
//
// Get x and y cell sizes.
//
    Double temp;
    getItem ("C6DX", temp, units);
    Quantity c6dx (temp, "\"");
    getItem ("C6DY", temp, units);
    Quantity c6dy (temp, "\"");
//
// Get angles between vertical an cell axes.
//
    getItem ("CELL_V2Y", temp, units);
    Quantity v2y (temp, "deg");
    getItem ("C4AXY", temp, units);
    Quantity x2y (temp, "deg");
//
// Get the pointing history array.
//
    vector<String> dimNames;
    Array<Float> pointingHistory;
    getArray ("C14PHIST", pointingHistory, dimNames);

    for (Int field=0; field<pointingHistory.shape()(1); ++field) {
      msField.addRow ();
      columns.name().put (field, "map position");
      columns.code().put (field, "SOURCE");
//
// Just put the time of the first measurement here, I don't think it
// will be used as we have constant directions for each field position
// rather than a polynomial in time.
//
      columns.timeMeas().put (field, first);
      columns.numPoly().put (field, 0);
//
// The directions of the field positions are calculated by using the
// shift() method which (I believe) is not the same as doing the proper
// tangent plane calculation. Shift() moves a point through an angular
// distance rather than along the plane. The 2 are equivalent at the
// field centre but diverge as x versus tanx as you move away. Even
// for an offset of 1 degree the error is 1 in 10^4, or 0.4arcsec.
//
      Quantity x_offset =
       Quantity (pointingHistory (IPosition(2,0,field))) * c6dx;
      Quantity y_offset = 
       Quantity (pointingHistory (IPosition(2,1,field))) * c6dy;
      Quantity dlong = sin(v2y-x2y) * x_offset + sin(v2y) * y_offset;
      Quantity dlat = cos(v2y-x2y) * x_offset + cos(v2y) * y_offset;
//
// Convert the source direction to the local coord system at this time.
//
      MDirection fieldDirection;
      if (c4lsc == c4csc) {
        fieldDirection  = _sourceDirection;
        fieldDirection.shift (dlong, dlat, True);
      } else if (c4lsc == "AZ") {
        MeasFrame scanFrame = _frame;
        scanFrame.set (_scanTime [field]);
        MDirection::Convert toLocal (MDirection::J2000, 
         MDirection::Ref (MDirection::AZEL, scanFrame));
        MDirection::Convert fromLocal ( 
         MDirection::Ref (MDirection::AZEL, scanFrame),
         MDirection::J2000);
        MDirection altaz = toLocal (_sourceDirection);
        altaz.shift (dlong, dlat, True);
        fieldDirection = fromLocal (altaz);
      } else if (c4lsc == "RJ") {
//
// Field centre is stored as J2000 which is the same as RJ.
//
        fieldDirection  = _sourceDirection;
        fieldDirection.shift (dlong, dlat, True);
      } else {
        throw (AipsError ("cannot handle " + c4lsc));
      }
//      cout.precision (12);
//      cout << _sourceDirection.getValue().get() << endl;
//      cout << fieldDirection.getValue().get() << endl;

      columns.phaseDirMeasCol().put (field, 
       Array<MDirection> (IPosition(1,1), fieldDirection));
      columns.delayDirMeasCol().put (field, 
       Array<MDirection> (IPosition(1,1), fieldDirection));
      columns.referenceDirMeasCol().put (field, 
       Array<MDirection> (IPosition(1,1), fieldDirection));
      columns.sourceId().put (field, 0);
      columns.flagRow().put (0, False);
    }
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::fillField|");
    throw (AipsError (message));
  }
}


void GSDDataSource::fillObservation (MeasurementSet& measurementSet)
 const {
  try {
    cout << "-- filling OBSERVATION sub-Table" << endl;
    MSObservation msObservation = measurementSet.observation ();
    msObservation.addRow ();
    MSObservationColumns columns (msObservation);
    columns.flagRow().put (0, False);
    columns.log().put (0, Array<String> (IPosition (1,1), "none"));
    String observer, units;
    getItem ("C1OBS", observer, units);
    columns.observer().put (0, observer.c_str());
    String project;
    getItem ("C1PID", project, units);
    columns.project().put (0, project.c_str());
//
// The release date for the data is set to 1 year after the observing
// date.
//
    Quantity release = _startEpoch.get("d");
    release += Quantity (365, "d");
    columns.releaseDateQuant().put (0, release);
    columns.schedule().put (0, Array<String> (IPosition(1,1), "none"));
    columns.scheduleType().put (0, "none");
    columns.telescopeName().put (0, "JCMT");
//
// Start and stop times are the times of the first and last measurements.
//
    Array<MEpoch> startstop (IPosition (1,2));
    MSMainColumns mainColumns (measurementSet);
    mainColumns.timeMeas().get (0, startstop (IPosition(1,0)));
    startstop (IPosition(1,1)) = startstop (IPosition(1,0));
    for (Int mainRow=0; mainRow < static_cast<Int>(measurementSet.nrow());
     ++mainRow) {
      MEpoch temp;
      mainColumns.timeMeas().get (mainRow, temp);
      if (temp.getValue().get() > 
          startstop (IPosition(1,1)).getValue().get()) {
        startstop (IPosition(1,1)) = temp;
      }
    }
    columns.timeRangeMeas().put (0, startstop); 
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::fillObservation|");
    throw (AipsError (message));
  }
}


void GSDDataSource::fillPointing (MeasurementSet& measurementSet)
 const {
  try {
    cout << "-- filling POINTING sub-Table" << endl;
    MSPointing msPointing = measurementSet.pointing ();
    MSPointingColumns columns (msPointing);
//
// Fill in the antenna pointing entries by getting the TIME and INTERVAL
// from the MAIN table and the MDirection from the FIELD sub-Table.
//
    Int lastScan = -1;
    Int pointing = 0;
    for (Int mainRow=0; mainRow < static_cast<Int> (measurementSet.nrow()); 
     ++mainRow) {
      MSMainColumns mainColumns (measurementSet);
      Int scan;
      mainColumns.scanNumber().get (mainRow, scan);
      if (scan != lastScan) {
        lastScan = scan;
        msPointing.addRow ();
        MEpoch time;
        mainColumns.timeMeas().get (mainRow, time);
        columns.timeMeas().put (pointing, time);
        Quantity interval;
        mainColumns.intervalQuant().get (mainRow, interval);
        columns.intervalQuant().put (pointing, interval);
        columns.timeOriginMeas().put (pointing, time);
        Int fieldId;
        mainColumns.fieldId().get (mainRow, fieldId);
        MSField msField = measurementSet.field();
        MSFieldColumns fieldColumns (msField);
        Array<MDirection> direction;
        fieldColumns.delayDirMeasCol().get (fieldId, direction);
        columns.directionMeasCol().put (pointing, direction);
        columns.targetMeasCol().put (pointing, direction); 
        ++pointing;
      }
    }
//
// Fill columns whose values don't change.
//
    columns.antennaId().fillColumn (0);
    columns.name().fillColumn ("source offset");
    columns.numPoly().fillColumn (0);
    columns.tracking().fillColumn (True);
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::fillPointing|");
    throw (AipsError (message));
  }
}


void GSDDataSource::fillPolarization (MeasurementSet& measurementSet)
 const {
  try {
    cout << "-- filling POLARIZATION sub-Table" << endl;
//
// For the time being assume that the number of Subsystems reflects the
// number of receptors in the receiver.
//
    MSPolarization msPolarization = measurementSet.polarization ();
    MSPolarizationColumns columns (msPolarization);
    for (uInt pol=0; pol <_polVal.size(); ++pol) {
      msPolarization.addRow ();
      columns.corrProduct().put (pol, Array<Int> (IPosition(2,2,1), 0));
      columns.corrType().put (pol, Array<Int> (IPosition(1,1),
       Stokes::I));
      columns.flagRow().put (pol, False);
      columns.numCorr().put (pol, 1);
    }
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::fillPolarization|");
    throw (AipsError (message));
  }
}


void GSDDataSource::fillProcessor (MeasurementSet& measurementSet)
 const {
  try {
    cout << "-- filling PROCESSOR sub-Table" << endl;
    MSProcessor msProcessor = measurementSet.processor ();
    MSProcessorColumns columns (msProcessor);
    msProcessor.addRow ();
    columns.type().put (0, "SPECTROMETER");
    String backend, units;
    getItem ("C1BKE", backend, units); 
    columns.subType().put (0, backend.c_str());
    columns.typeId().put (0, -1);
    columns.modeId().put (0, -1);
    columns.flagRow().put (0, False);
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::fillProcessor|");
    throw (AipsError (message));
  }
}


void GSDDataSource::fillRasterData (const String msname, MeasurementSet&
 measurementSet) {
  cout << "GSDDataSource::fillRasterData called" << endl;
  try {
//
// Decipher number of sections, data description, feeds, etc.
//
    getConfiguration ();
    if (_version < 5.2) {
      throw (AipsError ("GSD version < 5.2"));
    } else {
      vector<String> dimNames;
//
// Get array describing data array shapes.
//
      Array<Int> c3lspc;
      getArray ("C3LSPC", c3lspc, dimNames);
//
// Get the data array from the GSD file and check that it has the
// expected shape etc.
//
      Array<Float> gsdData;
      getArray("C13DAT", gsdData, dimNames);
      AlwaysAssert (dimNames.size() == 3, AipsError);
      AlwaysAssert (dimNames[0] == "C3NCH", AipsError);
      AlwaysAssert (dimNames[1] == "C3MXP", AipsError);
      AlwaysAssert (dimNames[2] == "C3NIS", AipsError);
      IPosition dataShape = gsdData.shape();
//
// Construct the MS with a FLOAT_DATA column. Make this a hypercolumn
// so that it can be handled by a Tiled Storage Manager.
//
      TableDesc tableDesc = MS::requiredTableDesc ();
      IPosition spShape = c3lspc.shape ();
      if (allEQ (c3lspc, c3lspc (IPosition(1,0)))) {
        MS::addColumnToDesc (tableDesc, MS::FLOAT_DATA, 
         IPosition (2, 1, c3lspc(IPosition(1,0))), ColumnDesc::Direct);
      } else {
        MS::addColumnToDesc (tableDesc, MS::FLOAT_DATA, 
         IPosition (2, 1, c3lspc(IPosition(1,0))), ColumnDesc::Undefined);
      }
      tableDesc.defineHypercolumn (MS::columnName (MS::FLOAT_DATA), 3,
       stringToVector (MS::columnName (MS::FLOAT_DATA)));
      SetupNewTable maker (String (msname.c_str()), tableDesc,
       Table::New);
      StManAipsIO stManAipsIO;
//
// Setup a TiledStMan for FLOAT_DATA with the 'tile' large
// enough to contain 100 column entries.
//        
      const ColumnDesc columnDesc = 
       tableDesc.columnDesc (MS::columnName (MS::FLOAT_DATA));
      IPosition shape = columnDesc.shape ();
      IPosition extender = IPosition (1, 100);
      IPosition tileShape = shape.concatenate (extender);
      if (allEQ (c3lspc, c3lspc (IPosition(1,0)))) {
        TiledColumnStMan tiledSM (MS::columnName(MS::FLOAT_DATA),
         tileShape);
        maker.bindColumn (MS::columnName(MS::FLOAT_DATA), tiledSM);
      } else {
        TiledShapeStMan tiledSM (MS::columnName(MS::FLOAT_DATA),
         tileShape);
        maker.bindColumn (MS::columnName(MS::FLOAT_DATA), tiledSM);
      }
//
// Create the MS.
//
      measurementSet = MeasurementSet (maker);
      measurementSet.createDefaultSubtables (Table::New);
//
// Fill the MS FLOAT_DATA column.
//
      copyData52 (measurementSet, gsdData, c3lspc);
//
// Fill the spectral window subTable.
//
      fillSpectralWindow (measurementSet);
    }
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::fillRasterData|");
    throw (AipsError (message));
  }
}


void GSDDataSource::fillSampleData (const String msname, MeasurementSet&
 measurementSet) {
  cout << "GSDDataSource::fillSampleData called" << endl;
  try {
//
// Decipher number of sections, data description, feeds, etc.
//
    getConfiguration ();
    if (_version < 5.2) {
      throw (AipsError ("GSD version < 5.2"));
    } else {
//
// Get array describing data array shapes.
//
      vector<String> dimNames;
      Array<Int> c3lspc;
      getArray ("C3LSPC", c3lspc, dimNames);
// 
// Get the data array from the GSD file and check that it has the
// expected shape etc. Some data files have axes ..,C3NIS,C3MXP others
// ..,C3MXP,C3NIS - don't understand why at present.
//
      Array<Float> gsdData;
      getArray("C13DAT", gsdData, dimNames);
      AlwaysAssert (dimNames.size() == 3, AipsError);
      AlwaysAssert (dimNames[0] == "C3NCH", AipsError);
      AlwaysAssert ((dimNames[1] == "C3NIS" && dimNames[2] == "C3MXP") || 
       (dimNames[1] == "C3MXP" && dimNames[2] == "C3NIS"), AipsError);
      IPosition dataShape = gsdData.shape();
      AlwaysAssert (dataShape(1) == 1, AipsError);
      AlwaysAssert (dataShape(2) == 1, AipsError);
//
// Construct the MS with a FLOAT_DATA column. If all subsystems have the
// same size data array then have 'Direct' storage, else 'Indirect'.
//
      TableDesc tableDesc = MS::requiredTableDesc ();
      IPosition spShape = c3lspc.shape ();
      if (allEQ (c3lspc, c3lspc (IPosition(1,0)))) {
        MS::addColumnToDesc (tableDesc, MS::FLOAT_DATA,
         IPosition (2, 1, c3lspc(IPosition(1,0))), ColumnDesc::Direct);
      } else {
        MS::addColumnToDesc (tableDesc, MS::FLOAT_DATA,
         IPosition (2, 1, c3lspc(IPosition(1,0))), ColumnDesc::Undefined);
      }
      SetupNewTable maker (String (msname.c_str()), tableDesc, 
       Table::New);
//
// Create the MS.
//
      measurementSet = MeasurementSet (maker);
      measurementSet.createDefaultSubtables (Table::New);
//
// Fill the MS FLOAT_DATA column.
//
      copyData52 (measurementSet, gsdData, c3lspc);
//
// Fill the spectral window subTable.
//
      fillSpectralWindow (measurementSet);
    }
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::fillSampleData|");
    throw (AipsError (message));
  }
}


void GSDDataSource::fillSource (MeasurementSet& measurementSet) const {
  try {
    cout << "-- filling SOURCE sub-Table" << endl;
//    cout << "GSDDataSource::fillSource called" << endl;
//
// SOURCE is an optional sub-Table not constructed by
// createDefaultSubtables, we must build it manually.
//
    TableDesc tableDesc = MSSource::requiredTableDesc ();
    MSSource::addColumnToDesc (tableDesc, MSSource::REST_FREQUENCY, 
     IPosition (1,1), ColumnDesc::Direct);
    MSSource::addColumnToDesc (tableDesc, MSSource::SYSVEL, 
     IPosition (1,1), ColumnDesc::Direct);
    SetupNewTable maker (measurementSet.sourceTableName(), tableDesc,
     Table::New);
//
// Create the MS.
//
    measurementSet.rwKeywordSet().defineTable 
     (MS::keywordName(MS::SOURCE), Table (maker));
    MSSource msSource (measurementSet.keywordSet().asTable("SOURCE"));
    MSSourceColumns columns (msSource);
//
// Get the time of the obs start.
//
    MEpoch time;
    MSMainColumns(measurementSet).timeMeas().get (0,time);
//
// The number of rows equals the number of spectral-windows.
// 
    for (uInt spw = 0; spw<_spectralWindow.size(); ++spw) {
      msSource.addRow ();
      columns.timeMeas().put (spw, time);
      columns.spectralWindowId().put (spw, spw);
      MFrequency::Ref sourceRef (MFrequency::REST, _frame);
      MVFrequency mvFrequency (_spectralWindow[spw].restFreq());
      MFrequency mFrequency (mvFrequency, sourceRef);
//      cout << mvFrequency << endl;
//      cout << mFrequency << endl;
      columns.restFrequencyMeas().put (spw, Array<MFrequency>
       (IPosition(1,1), mFrequency));
      Array<MFrequency> temp;
      columns.restFrequencyMeas().get (spw, temp);
//      cout << temp(IPosition(1,0)) << endl;
      columns.directionMeas().put (spw, _sourceDirection);
      Array<MRadialVelocity> velocities (IPosition(1,1), _sourceVelocity);
      columns.sysvelMeas().put (spw, velocities); 
    }
//
// Now fill columns whose values don't change.
//
// Set keys first. -1 as spec. wind. Id means valid for all spw.
//
    columns.sourceId().fillColumn (0);
    columns.interval().fillColumn (-1.0);
//
// Data description.
//
    columns.numLines().fillColumn (1);
//
// Data.
//
    String name1, name2, units;
    getItem ("C1SNA1", name1, units);
    getItem ("C1SNA2", name2, units);
    String name (name1.c_str());
    name += name2.c_str();
    columns.name().fillColumn (name);
    columns.calibrationGroup().fillColumn (-1);
    columns.code().fillColumn ("source observation");
    columns.properMotion().fillColumn (Array<Double> (IPosition(1,2), 0e0));
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::fillSource|");
    throw (AipsError (message));
  }
}


void GSDDataSource::fillSpectralWindow (MeasurementSet& measurementSet) const {
  try {
    cout << "-- filling SPECTRAL_WINDOW sub-Table" << endl;
//    cout << "GSDDataSource::fillSpectralWindow called" << endl;
    MSSpectralWindow msSpectralWindow = measurementSet.spectralWindow ();
    MSSpWindowColumns columns (msSpectralWindow);
//
// The SpectralWindow associated with a spectrum in the MAIN Table
// supplies the frequency information for the spectrum. The frequency
// information in the GSD file seems to be limited to the rest
// frequency of the observed line and the channel-width/bandwidth of
// of the spectrum (presumably the raw hardware values).
//
// We can't store the raw TOPO frequencies with each spectrum as these
// change with time and would require one number for each spectral point.
// Instead we store the the frequency of each channel relative to a
// fixed reference frame. The first frame tried was the REST frame,
// which seemed to map most naturally from the data stored in the GSD
// file. However, this did not sit well with some of the existing 
// aips++ utilities. Instead we convert the frequencies to the LSRK frame.
//
    for (uInt spw=0; spw<_spectralWindow.size(); ++spw) {
//
// construct the Reference and Measure of the marker channel. This
// is a REST frequency read from the GSD file.
//
      MFrequency::Ref restFrame (MFrequency::REST, _frame);
      MVFrequency vCFrest (_spectralWindow[spw].centreFreq());
      MFrequency mCFrest (vCFrest, restFrame);
//
// construct the TOPO Reference of the hardware channels, giving the 
// REST frequency of the marker channel as an offset.
//
      MFrequency::Ref topoFrame (MFrequency::TOPO, _frame, mCFrest);
// 
// Construct a conversion engine to convert hardware channels to LSRK 
// frequencies.
//
      MFrequency::Ref lsrkFrame (MFrequency::LSRK, _frame);
      MFrequency::Convert topo2lsrk (topoFrame, lsrkFrame);
//
// Now start filling in columns.
//
      msSpectralWindow.addRow ();
      columns.numChan().put (spw, _spectralWindow[spw].nchan());
      columns.name().put (spw, "reduced spectrum");
//
// Marker channel is middle channel for odd number length, first channel
// of second half for even.
//
      Int marker = 0;
      switch (_spectralWindow[spw].nchan() % 2) {
        case 0 :
          marker = _spectralWindow[spw].nchan() / 2;
          break;
        case 1 :
          marker = (_spectralWindow[spw].nchan() - 1) / 2;
          break;
        default :
          throw (AipsError("this should never happen"));
      }
//      cout << "marker channel is " << marker << endl;
      Array<MFrequency> chanFreqArray (IPosition 
       (1,_spectralWindow[spw].nchan()), MFrequency());
//
// Construct the frequency of each spectral point.
// This is done by calculating the TOPO frequency of each point
// from the channel number, marker channel and channel width. The
// frame for this MFrequency carries the offset of the REST frequency
// attached to 'topoFrame'.
//
// Each TOPO frequency is then converted to the value in the LSRK frame.
//
      for (Int chan=0; chan<_spectralWindow[spw].nchan(); ++chan) {
        MVFrequency mvChanFreq = (chan - marker) * 
         _spectralWindow[spw].channelWidth().get("Hz").getValue();
        MFrequency mChanFreq (mvChanFreq, topoFrame);
        chanFreqArray (IPosition(1,chan)) = topo2lsrk (mChanFreq);
      }

      columns.chanFreqMeas().put (spw, chanFreqArray);
      Array<Quantity> chanWidthArray (
       IPosition(1,_spectralWindow[spw].nchan()),
       chanFreqArray(IPosition(1,marker)).getValue() - 
       chanFreqArray(IPosition(1,marker-1)).getValue());
      columns.chanWidthQuant().put (spw, chanWidthArray);
      columns.effectiveBWQuant().put (spw, chanWidthArray);
      columns.resolutionQuant().put (spw, chanWidthArray);
      columns.totalBandwidthQuant().put (spw, 
       _spectralWindow[spw].bandwidth());
      columns.netSideband().put (spw, _spectralWindow[spw].sideband());
      columns.freqGroup().put (spw, -1);
      columns.freqGroupName().put (spw, "unused");
      columns.ifConvChain().put (spw, -1);
      columns.flagRow().put (spw, False);
    }
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::fillSpectralWindow|");
    throw (AipsError (message));
  }
}


void GSDDataSource::fillState (MeasurementSet& measurementSet) const {
  try {    
    cout << "-- filling STATE sub-Table" << endl;
    MSState msState = measurementSet.state ();
    MSStateColumns columns (msState);
    msState.addRow ();
    columns.sig().put (0, True);
    columns.ref().put (0, False);
    columns.cal().put (0, 0.0);
    columns.load().put (0, 0.0);
    columns.subScan().put (0, 0);
    columns.obsMode().put (0, "ON_SPECTRUM");
    columns.flagRow().put (0, False);
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::fillState|");
    throw (AipsError (message));
  }
}


void GSDDataSource::fillSysCal (MeasurementSet& measurementSet) const {
  try {
    cout << "-- filling SYSCAL sub-Table" << endl;
//    cout << "GSDDataSource::fillSysCal called" << endl;
//
// SYSCAL is an optional sub-Table not constructed by
// createDefaultSubtables, we must build it manually.
//
    TableDesc tableDesc = MSSysCal::requiredTableDesc ();

    MSSysCal::addColumnToDesc (tableDesc, MSSysCal::TRX, 
     IPosition (1,1), ColumnDesc::Direct);
    MSSysCal::addColumnToDesc (tableDesc, MSSysCal::TSKY, 
     IPosition (1,1), ColumnDesc::Direct);
    MSSysCal::addColumnToDesc (tableDesc, MSSysCal::TSYS, 
     IPosition (1,1), ColumnDesc::Direct);
    tableDesc.addColumn (ArrayColumnDesc<Float> ("NS_JCMT_TTEL",
     "Telescope temp from last skydip", ColumnDesc::Direct));
    tableDesc.addColumn (ArrayColumnDesc<Float> ("NS_JCMT_GAIN",
     "Gain of Rx channel", ColumnDesc::Direct));
    tableDesc.addColumn (ArrayColumnDesc<Float> ("NS_JCMT_WO",
     "Water Opacity", ColumnDesc::Direct));
    tableDesc.addColumn (ArrayColumnDesc<Float> ("NS_JCMT_ETASKY",
     "Sky transmission", ColumnDesc::Direct));
    tableDesc.addColumn (ArrayColumnDesc<Float> ("NS_JCMT_ALPHA",
     "Ratio of signal sideband to image sideband sky transmission", 
     ColumnDesc::Direct));
    tableDesc.addColumn (ArrayColumnDesc<Float> ("NS_JCMT_ETATEL",
     "Telescope transmission", ColumnDesc::Direct));
    
    SetupNewTable maker (measurementSet.sysCalTableName(), tableDesc,
     Table::New);
//
// Create the MS.
//
    measurementSet.rwKeywordSet().defineTable 
     (MS::keywordName(MS::SYSCAL), Table (maker));
    MSSysCal msSysCal (measurementSet.keywordSet().asTable("SYSCAL"));
    MSSysCalColumns columns (msSysCal);
//
// Get the time at which the observation started.
//
    MSMainColumns mainColumns (measurementSet);
    MEpoch first;
    mainColumns.timeMeas().get (0, first);
//
// Get the Cal data. The dimensions of these data can vary from
// file to file.
//
// First items that always seem to be of dimension C3NRS (number of
// backend sections).
//
    vector<String> dimNames;
    Array<Double> c12rt;
    getArray ("C12RT", c12rt, dimNames);
    AlwaysAssert (dimNames.size() == 1, AipsError);
    AlwaysAssert (dimNames[0] == "C3NRS", AipsError);
    Array<Double> c12gains;
    getArray ("C12GAINS", c12gains, dimNames);
    Array<Double> c12ttel;
    getArray ("C12TTEL", c12ttel, dimNames);
    Array<Double> c12wo;
    getArray ("C12WO", c12wo, dimNames);
    Array<Double> c12alpha;
    getArray ("C12ALPHA", c12alpha, dimNames);
    Array<Double> c12etatel;
    getArray ("C12ETATEL", c12etatel, dimNames);
//
// Now items that are usually C3NRS but sometimes [C3NRS,C3NIS].
//
    Array<Double> c12tsky;
    getArray ("C12TSKY", c12tsky, dimNames);
    uInt sometimes = dimNames.size();
    AlwaysAssert (sometimes < 3, AipsError);
    if (dimNames.size() == 1) {
      AlwaysAssert (dimNames[0] == "C3NRS", AipsError);
    } else {
      AlwaysAssert (dimNames[1] == "C3NIS", AipsError);
    }
    Array<Double> c12sst;
    getArray ("C12SST", c12sst, dimNames);
    AlwaysAssert (dimNames.size() == sometimes, AipsError);
    if (sometimes == 1) {
      AlwaysAssert (dimNames[0] == "C3NRS", AipsError);
    } else {
      AlwaysAssert (dimNames[0] == "C3NRS", AipsError);
      AlwaysAssert (dimNames[1] == "C3NIS", AipsError);
    }
    Array<Double> c12etasky;
    getArray ("C12ETASKY", c12etasky, dimNames);
    AlwaysAssert (dimNames.size() == sometimes, AipsError);
    if (sometimes == 1) {
      AlwaysAssert (dimNames[0] == "C3NRS", AipsError);
    } else {
      AlwaysAssert (dimNames[0] == "C3NRS", AipsError);
      AlwaysAssert (dimNames[1] == "C3NIS", AipsError);
    }
//
// Fill the SYSCAL columns.
//
// The number of subsystems (Pol) is assumed to be the number of receptors
// in the receiver. Each receptor is assumed to lie in a separate feed.
//
    Int nScan = 1;
    if (sometimes == 2) {
      nScan = c12tsky.shape()[1];
    }
//
// TIME is wrong if nScan > 1, needs more work if this ever happens.
//
    AlwaysAssert (nScan == 1, AipsError);
    for (Int scan = 0; scan < nScan; ++scan) {
      for (uInt desc=0; desc<_desc2Pol.size(); ++desc) {
        msSysCal.addRow ();
        columns.antennaId().put (desc, 0);
        columns.feedId().put (desc, _desc2Pol[desc]);
        columns.spectralWindowId().put (desc, _desc2spwId[desc]); 
        columns.timeMeas().put (desc, first);
        columns.interval().put (desc, -1.0);
        columns.trxQuant().put (desc, Array<Quantum<Float> > (
         IPosition (1,1), Quantum<Float> (c12rt (IPosition (1,desc)), "K")));
        columns.tskyQuant().put (desc, Array<Quantum<Float> > ( 
         IPosition (1,1), 
         Quantum<Float> (c12tsky (IPosition (2,desc,scan)), "K")));
        columns.tsysQuant().put (desc, Array<Quantum<Float> > ( 
         IPosition (1,1), 
         Quantum<Float> (c12sst (IPosition (2,desc,scan)), "K")));
        {
          ArrayColumn<Float> column (msSysCal, "NS_JCMT_TTEL");
          column.put (desc, Array<Float> (IPosition (1,1), 
           c12ttel (IPosition (1,desc))));
        }
        {
          ArrayColumn<Float> column (msSysCal, "NS_JCMT_GAIN");
          column.put (desc, Array<Float> (IPosition (1,1), 
           c12gains (IPosition (1,desc))));
        }
        {
          ArrayColumn<Float> column (msSysCal, "NS_JCMT_WO");
          column.put (desc, Array<Float> (IPosition (1,1), 
           c12wo (IPosition (1,desc))));
        }
        {
          ArrayColumn<Float> column (msSysCal, "NS_JCMT_ETASKY");
          column.put (desc, Array<Float> (IPosition (1,1), 
           c12etasky (IPosition (2,desc,scan))));
        }
        {
          ArrayColumn<Float> column (msSysCal, "NS_JCMT_ALPHA");
          column.put (desc, Array<Float> (IPosition (1,1), 
           c12alpha (IPosition (1,desc))));
        }
        {
          ArrayColumn<Float> column (msSysCal, "NS_JCMT_ETATEL");
          column.put (desc, Array<Float> (IPosition (1,1), 
           c12etatel (IPosition (1,desc))));
        }
      }
    }
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::fillSysCal|");
    throw (AipsError (message));
  }
}


void GSDDataSource::fillWeather (MeasurementSet& measurementSet) const {
  try {
    cout << "-- filling WEATHER sub-Table" << endl;
//    cout << "GSDDataSource::fillWeather called" << endl;
//
// WEATHER is an optional sub-Table not constructed by
// createDefaultSubtables, we must build it manually.
//
    TableDesc tableDesc = MSWeather::requiredTableDesc ();
    MSWeather::addColumnToDesc (tableDesc, MSWeather::PRESSURE);
    MSWeather::addColumnToDesc (tableDesc, MSWeather::REL_HUMIDITY);
    MSWeather::addColumnToDesc (tableDesc, MSWeather::TEMPERATURE);
    SetupNewTable maker (measurementSet.weatherTableName(), tableDesc,
     Table::New);
//
// Create the MS.
//
    measurementSet.rwKeywordSet().defineTable 
     (MS::keywordName(MS::WEATHER), Table (maker));
    MSWeather msWeather (measurementSet.keywordSet().asTable("WEATHER"));
    MSWeatherColumns columns (msWeather);
//
// Fill the columns.
//
    msWeather.addRow ();
//
// Get the first TIME from the MAIN Table and put it here.
//
    MEpoch time;
    MSMainColumns(measurementSet).timeMeas().get (0,time);
    columns.timeMeas().put (0,time);
    columns.interval().put (0,-1.0);
    Double weatherItem;
    String units;
    getItem ("C5PRS", weatherItem, units);
    columns.pressureQuant().put (0, Quantum<Float> 
     (weatherItem, "mbar"));
    getItem ("C5AT", weatherItem, units);
    weatherItem += 273.0;
    columns.temperatureQuant().put (0, Quantum<Float> 
     (weatherItem, "K"));
    getItem ("C5RH", weatherItem, units);
    columns.relHumidity().put (0, weatherItem);
  } catch (AipsError x) {
    String message = x.getMesg ();
    message.prepend ("GSDDataSource::fillWeather|");
    throw (AipsError (message));
  }
}


template <class T> void GSDDataSource::getItem (const String itemName, 
 T& value, String& units) const { 
  try { 
    int itemno;
    char unit [11];
    char itype;
    char iarray;
    int gsdfind = gsdFind(_fileDesc, _itemDesc, 
     const_cast<char *> (itemName.c_str()), &itemno, unit, &itype,
     &iarray);
    switch (gsdfind) {
      case 0:
        break;
      case 1:
        throw (AipsError(" Named item not found"));
      default:
        throw (AipsError(" Unknown error in gsdFind"));
    }

    int result = gsdGet (itemno, value);
    switch (result) {
      case 0:
        units = unit;
        break;
      case 1:
        throw (AipsError(" Failed to read value of item"));
      case 2:
        throw (AipsError(" Numbered item cannot be found"));
      case 3:
        throw (AipsError(" Item is not scalar"));
      default:
        throw (AipsError(" Unknown error in gsdGet"));
    } 
  } catch (AipsError x) {
    String message = "GSDDataSource::getItem|" + x.getMesg ();
    throw (AipsError (message));
  }
}


template <class T> void GSDDataSource::getArray (const String itemName, 
 Array<T>& data, vector<String>& dNames) const { 
  try {
    data.resize ();
    dNames.clear ();
//
// Find the array.
//
    int itemno;
    char unit[11];
    char itype;
    char iarray;
    int gsdfind = gsdFind (_fileDesc, _itemDesc, 
     const_cast<char *> (itemName.c_str()), &itemno, unit, &itype,
     &iarray);
    switch (gsdfind) {
      case 0:
        break;
      case 1:
        throw (AipsError(" Named item not found"));
      default:
        throw (AipsError(" Unknown error in gsdFind"));
    }
//
// Get its dimensions.
//
    const int MAXDIMS = 5;
    char dimNames[MAXDIMS][17];
    char dimUnits[MAXDIMS][11];
    char *dN[MAXDIMS];
    char *dU[MAXDIMS];
    Int i;
    for (i = 0; i < MAXDIMS; i++) {
       dN[i] = &dimNames[i][0];
       dU[i] = &dimUnits[i][0];
    }    
    Int dimVals[MAXDIMS];
    Int actDims;
    Int size;
    int gsdinqsize = gsdInqSize (_fileDesc, _itemDesc, _dataPtr,
     itemno, MAXDIMS, dN, dU, dimVals, &actDims, &size);
    switch (gsdinqsize) {
      case 0:
        break;
      case 1:
        throw (AipsError(" Failed to get a dimension value and name"));
      case 2:
        throw (AipsError(" Numbered item cannot be found"));
      case 3:
        throw (AipsError(
          " Array has more dimensions than accomodated by calling  routine"));
      default:
        throw (AipsError(" Unknown error in gsdInqSize"));
    }
//
// Put dim names into String vector.
//
    for (i = 0; i < actDims; ++i) {
      String temp (dN[i]);
      temp.gsub (RXwhite, "");
      dNames.push_back (temp);
    }
// 
// Read the data array in. Note that the array indices required for
// the call to gsdGet1r start at 1 not 0 (Fortran rather than C).
//
    Int start[MAXDIMS], end[MAXDIMS];
    for (i = 0; i < actDims; i++) {
      start[i] = 1;
      end[i] = dimVals[i];
    }
    T *values;
    Int actVals;
    values = new T [size];
    Int gsdget1i = gsdGet (itemno, actDims, dimVals, start, end, 
     values, actVals);
    switch (gsdget1i) {
      case 0: 
        break;
      case 1:
        delete values; 
        throw (AipsError(" Failure to read the item values"));
      case 2:
        delete values; 
        throw (AipsError(" Numbered items cannot be found"));
      case 4:
        delete values; 
        throw (AipsError(" Given start and end are inconsistent"));
      default:
        delete values; 
        throw (AipsError(" Unknown error in gsdGet1i"));
    }
//
// Construct an Array of the correct shape around the data.
//
    IPosition arrayShape (actDims, dimVals[0], dimVals[1], dimVals[2],
      dimVals[3], dimVals[4]);
    data = Array<T> (arrayShape, values, TAKE_OVER);
  } catch (AipsError x) {
    String message = "GSDDataSource::getArray|" + x.getMesg ();
    throw (AipsError (message));
  }
}


void GSDDataSource::getConfiguration () {
  try {
    if (_version < 5.2) {
      throw (AipsError ("GSD version < 5.3"));
    } else {
//
// Get number of BE sections and which sub-system each is associated with.
//
      String units;
      vector<String> dimNames;
      Int c3nrs;
      getItem ("C3NRS", c3nrs, units);
      AlwaysAssert (c3nrs > 0, AipsError);
      Array<Int> c3besspec (IPosition (1,c3nrs));
      getArray ("C3BESSPEC", c3besspec, dimNames);
//
// The 'connection' arrays that are supposed to describe the signal
// route from detector to BE section are missing or unreliable. I'll
// follow the SPECX reader in using the number of DAS sub-systems as
// an indicator of how many distinct detectors there are.
//
      _polVal.push_back (c3besspec (IPosition (1,0)));
      for (Int j=1; j < c3nrs; ++j) {
        Bool match = False;
        for (uInt i=0; i < _polVal.size(); ++i) {
          if (_polVal[i] == static_cast<uInt> (c3besspec(IPosition(1,j)))) {
            match = True;
          }
        }
        if (!match) {
          _polVal.push_back (c3besspec( IPosition(1,j)));
        }
      }
//
// Now find out how many distinct spectral windows there are. This is done
// by checking the number of points (C3LSPC), centre frequencies (C12CF)
// and frequency resolution.
//
      Array<Int> c3lspc (IPosition (1,c3nrs));
      getArray ("C3LSPC", c3lspc, dimNames);
      Array<Double> c12cf (IPosition (1,c3nrs));
      getArray ("C12CF", c12cf, dimNames);
      Array<Double> c12fr (IPosition (1,c3nrs));
      getArray ("C12FR", c12fr, dimNames);
      Array<Double> c12rf (IPosition (1,c3nrs));
      getArray ("C12RF", c12rf, dimNames);
      Array<Double> c12bw (IPosition (1,c3nrs));
      getArray ("C12BW", c12bw, dimNames);
      Array<Double> c3befenulo (IPosition (1,c3nrs));
      getArray ("C3BEFENULO", c3befenulo, dimNames);
      Array<Double> c3betotif (IPosition (1,c3nrs));
      getArray ("C3BETOTIF", c3betotif, dimNames);
      Array<Int> c3befesb (IPosition (1,c3nrs));
      getArray ("C3BEFESB", c3befesb, dimNames);

      _spectralWindow.push_back (
       GSDspectralWindow (c3lspc (IPosition (1,0)),
       Quantity (c12cf (IPosition (1,0)), "GHz"), 
       Quantity (c12fr (IPosition (1,0)), "MHz"),
       Quantity (c12rf (IPosition (1,0)), "GHz"),
       Quantity (c12bw (IPosition (1,0)), "MHz"),
       Quantity (c3befenulo (IPosition (1,0)), "GHz"),
       Quantity (c3betotif (IPosition (1,0)), "GHz"),
       c3befesb (IPosition (1,0))));

      vector<uInt> section2Window (c3nrs);
      section2Window[0] = 0;

      for (Int section=1; section < c3nrs; ++section) {
        Bool match = False;
        GSDspectralWindow temp (c3lspc (IPosition (1,section)),
         Quantity (c12cf (IPosition (1,section)), "GHz"), 
         Quantity (c12fr (IPosition (1,section)), "MHz"),
         Quantity (c12rf (IPosition (1,section)), "GHz"),
         Quantity (c12bw (IPosition (1,section)), "MHz"),
         Quantity (c3befenulo (IPosition (1,section)), "GHz"),
         Quantity (c3betotif (IPosition (1,section)), "GHz"),
         c3befesb (IPosition (1,section)));
        for (uInt spw=0; spw<_spectralWindow.size(); ++spw) {
          if (_spectralWindow[spw] == temp) {
            match = True;
            section2Window [section] = spw;
          }
        }
        if (!match) {
          section2Window [section] = _spectralWindow.size();
          _spectralWindow.push_back (temp);
        }
      }
      cout << "n spectral windows is " << _spectralWindow.size() << endl;
//      cout << "section2window" << endl;
//      vector<uInt>::const_iterator iter;
//      for (iter = section2Window.begin(); iter != section2Window.end(); 
//       ++iter) {
//        cout << *iter << endl;
//      }
//
// Now construct an array containing the DATA_DESC_ID for each 
// back-end section.
//
// First declare arrays to have max possible size.
//
      _section2DataDesc.resize (c3nrs);
//
// Then loop through sections.
//
      for (Int section=0; section<c3nrs; ++section) {
        Bool match = False;
//
// See if section conforms to already known data description. If so, store
// that desc Id.
//
        for (uInt desc=0; desc<_desc2Pol.size(); ++desc) {
          if (c3besspec(IPosition(1,section)) ==  
           static_cast<Int> (_polVal[_desc2Pol[desc]]) &&
              section2Window [section] == _desc2spwId[desc]) { 
             _section2DataDesc [section] = desc;
             match = True;
             break;
          }
        }
//
// If description not known then construct it and point the section to it.
//
        if (!match) {
          _section2DataDesc [section] = _desc2Pol.size();
          for (uInt pol=0; pol<_polVal.size(); ++pol) {
            if (static_cast<Int> (_polVal [pol]) == c3besspec 
             (IPosition(1,section))) {
              _desc2Pol.push_back (pol);
            }
          } 
          for (uInt spw=0; spw<_spectralWindow.size(); ++spw) {
            if (spw == section2Window [section]) { 
              _desc2spwId.push_back (spw);
              break;
            }
          }                         
        }
      }

//      vector<uInt>::iterator iter;
//      cout << "_section2DataDesc" << endl;
//      for (iter = _section2DataDesc.begin();
//       iter != _section2DataDesc.end(); ++iter) {
//        cout << *iter << endl;
//      }
//      cout << "_desc2Pol" << endl;
//      for (iter = _desc2Pol.begin(); iter != _desc2Pol.end(); ++iter) {
//        cout << *iter << endl;
//      }
//      cout << "_desc2spwId" << endl;
//      for (iter = _desc2spwId.begin(); iter != _desc2spwId.end(); ++iter) {
//        cout << *iter << endl;
//      }
    }
  } catch (AipsError x) {
    String message = "GSDDataSource::getConfiguration|" + x.getMesg ();
    throw (AipsError (message));
  }
}


template <> int GSDDataSource::gsdGet<> (int itemno, Double& value) const {
  int result;
  try {
    result = gsdGet0d (_fileDesc, _itemDesc, _dataPtr, itemno,
     &value);  
  } catch (AipsError x) {
    String message = "GSDDataSource::gsdGet<double>|" + x.getMesg ();
    throw (AipsError (message));
  }
  return result;
}


template <> int GSDDataSource::gsdGet<> (int itemno, Int& value) const {
  int result;
  try {
    result = gsdGet0i (_fileDesc, _itemDesc, _dataPtr, itemno,
     &value);  
  } catch (AipsError x) {
    String message = "GSDDataSource::gsdGet<int>|" + x.getMesg ();
    throw (AipsError (message));
  }
  return result;
}


template <> int GSDDataSource::gsdGet<> (int itemno, String& value) const {
  int result;
  try {
    char buffer [17];
    result = gsdGet0c (_fileDesc, _itemDesc, _dataPtr, itemno, buffer);
    value = buffer;  
  } catch (AipsError x) {
    String message = "GSDDataSource::gsdGet<String>|" + x.getMesg ();
    throw (AipsError (message));
  }
  return result;
}


template <> int GSDDataSource::gsdGet<> (int itemno, int& actDims,
 int *dimVals, int *start, int *end, int *values, int& actVals) const {
  int result;
  try {
    result = gsdGet1i (_fileDesc, _itemDesc, _dataPtr,
      itemno, actDims, dimVals, start, end, values, &actVals);
  } catch (AipsError x) {
    String message = "GSDDataSource::gsdGet<intarray>|" + x.getMesg ();
    throw (AipsError (message));
  }
  return result;
}


template <> int GSDDataSource::gsdGet<> (int itemno, int& actDims,
 int *dimVals, int *start, int *end, float *values, int& actVals) const {
  int result;
  try {
    result = gsdGet1r (_fileDesc, _itemDesc, _dataPtr,
      itemno, actDims, dimVals, start, end, values, &actVals);
  } catch (AipsError x) {
    String message = "GSDDataSource::gsdGet<floatarray>|" + x.getMesg ();
    throw (AipsError (message));
  }
  return result;
}


template <> int GSDDataSource::gsdGet<> (int itemno, int& actDims,
 int *dimVals, int *start, int *end, double *values, int& actVals) const {
  int result;
  try {
    result = gsdGet1d (_fileDesc, _itemDesc, _dataPtr,
      itemno, actDims, dimVals, start, end, values, &actVals);
  } catch (AipsError x) {
    String message = "GSDDataSource::gsdGet<doublearray>|" + x.getMesg ();
    throw (AipsError (message));
  }
  return result;
}

