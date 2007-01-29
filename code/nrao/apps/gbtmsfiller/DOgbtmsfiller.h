//# DOgbtmsfiller.h: this defines the gbtmsfiller DO
//# Copyright (C) 1999,2001,2002,2003
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
//# $Id: DOgbtmsfiller.h,v 19.10 2006/07/27 21:12:46 bgarwood Exp $

#ifndef NRAO_DOGBTMSFILLER_H
#define NRAO_DOGBTMSFILLER_H

#include <tasking/Tasking/ApplicationObject.h>
#include <casa/BasicSL/String.h>
#include <casa/OS/Directory.h>
#include <nrao/FITS/GBTScanLogReader.h>
#include <casa/Quanta/MVTime.h>
#include <casa/Utilities/Regex.h>
#include <casa/Containers/Block.h>
#include <casa/Containers/Record.h>
#include <casa/Containers/RecordField.h>
#include <nrao/GBTFillers/GBTMSFillOptions.h>

//# Forward Declarations
namespace casa { //# NAMESPACE CASA - BEGIN
template<class T> class Vector;
} //# NAMESPACE CASA - END
#include <casa/namespace.h>

class GBTDCRFiller;
class GBTHoloFiller;
class GBTSPFiller;
class GBTACSFiller;
class GBTBackendFiller;

// <summary>
// This is the distributed object (DO) for the GBT MS filler.
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class=ApplicationObject>ApplicationObject</linkto>
//   <li> <linkto class=MeasurementSet>MeasurementSet</linkto>
// </prerequisite>
//
// <etymology>
// This is the DO for the GBT MeasurementSet filler.
// </etymology>
//
// <synopsis>
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// The GBT MS filler needs to run from within Glish hence there
// needs to be a distributed object interface to the filler.
// </motivation>
//
// <todo asof="yyyy/mm/dd">
//   <li> Everything
// </todo>

class gbtmsfiller: public ApplicationObject
{
public:
    // the methods
    enum Methods {ISATTACHED=0, FILLNEXT, FILLALL, MORE, UPDATE, STATUS,
		  SETPROJECT, PROJECT, SETBACKEND, BACKEND, SETMSDIRECTORY, MSDIRECTORY,
		  SETMSROOTNAME, MSROOTNAME, SETMINTIME, MINTIME, 
		  SETMAXTIME, MAXTIME, SETOBJECT, OBJECT, SETMINSCAN, 
		  MINSCAN, SETMAXSCAN, MAXSCAN, NEWMS, SETFILLRAWPOINTING,
		  FILLRAWPOINTING, SETFILLRAWFOCUS, FILLRAWFOCUS, 
		  FILLLAGS, SETFILLLAGS, 
		  VV, SETVV, SMOOTH, SETSMOOTH, SETUSEHIGHCAL, USEHIGHCAL,
		  SETCOMPRESSCALCOLS, COMPRESSCALCOLS,
		  SETUSEBIAS, USEBIAS, SETONEACSMS, ONEACSMS,
		  SETDCBIAS, DCBIAS, SETMINBIASFACTOR, MINBIASFACTOR,
		  SETFIXBADLAGS, FIXBADLAGS,
		  NUMBER_METHODS};

    // an uninitiallized filler, it can not fill anything in this state
    gbtmsfiller();

    // a filler, ready to go (assuming the arguments are valid)
    gbtmsfiller(const String &project, const String &backend,
		const String &msrootname, const String &msdirectory,
                String mintime, String maxtime, const String &object,
		Int minscan, Int maxscan,
		Bool fillrawpointing, Bool fillrawfocus,
		Bool filllags, const String &vanVleckCorr,
		const String &smoothing,
		Bool useHighCal, Bool compressCalCols,
		Int vvSize, Bool usebias, Bool oneacsms,
		Double dcbias, Int minbiasfactor, Bool fixbadlags,
		Double sigmafactor, Int spikestart);

    ~gbtmsfiller();

    // is this filler attached to things - i.e. ready to fill
    // the silent flag is passed to init and is only intended to be used internally
    // the isattached DO method never sets that argument
    Bool isattached(Bool silent=False);

    // Start filling. This fills all of the files found in the
    // scan log, filling each of the ones with valid backends
    // subjects to the other constraints imposed on the filler
    // through other member functions.  If some filling has
    // already occured, any current backend and DAP FITS files
    // will be reopened to ensure that they are completed before
    // moving on to any new entries in the scan log.
    // This returns True unless there was an error.
    Bool fillall();

    // This just fills the next entry in the scan log.  As with
    // fillall, if some filling has already occured, any current
    // backend and DAP FITS files will be reopened to ensure that
    // they are complete before moving on to the next entry
    // in the scan log.
    // This returns True unless there was an error.  This even
    // returns true if the scan log is already at the end of 
    // the file.  Use the more() function to determine if there
    // are more scans to fill from the scan log.
    Bool fillnext();

    // Are there more scans to fill in the scan log.
    Bool more();

    // Update the scan log.  The scan log is closed and reopened
    // and set to point at its current location.  This is the
    // one of two ways that more can ever report True after it has
    // previously reported False (i.e. if the scan log has grown
    // since the last time the file was opened).  
    Bool update();

    // return the current status.  Status consists of a record
    // containing the next scan number, TIME and backends to be
    // filled, the names of any MeasurementSets currently being
    // filled and the fill constraints (project, object, min and max
    // time, min and max scan numbers, fillrawpointing and fillrawfocus).
    Record status();

    // Set the project directory. If any filling has already occurred,
    // any open MeasurementSets and FITS files are first closed.
    // Returns False if the project directory does not exist or it
    // can not be read.  If the project directory has changed, the
    // scan log is closed and the new scan log (if available) is
    // opened.
    Bool setproject(const String &project);

    // get the current project directory
    const String &project();

    // Set the backend type. 
    Bool setbackend(const String &backend);

    // get the current backend type
    const String backend();

    // Set the bottom level MeasurementSet directory
    Bool setmsdirectory(const String &msdirectory);

    // get the current MeasurementSet directory
    const String &msdirectory();

    // Set the root name used in all MeasurementSet names
    Bool setmsrootname(const String &msrootname);

    // get the current MeasurementSet root name
    const String &msrootname();

    // set the minimum start time
    Bool setmintime(const String &mintime);
  
    // get the current minimum start time
    const String mintime();

    // set the maximum start time
    Bool setmaxtime(const String &maxtime);
  
    // get the current maximum start time
    const String maxtime();

    // set the object name to fill
    Bool setobject(const String &object);

    // get the current object name
    const String &object();

    // set the minimum scan number to fill
    Bool setminscan(Int minscan);

    // get the minimum scan number to fill
    Int minscan();

    // set the maximum scan number to fill
    Bool setmaxscan(Int maxscan);

    // get the maximum scan number to fill
    Int maxscan();

    // set the flag to fill the raw pointing information
    Bool setfillrawpointing(Bool fillrawpointing) 
    {fillOptions_p.setFillRawPointing(fillrawpointing); return True;}

    // Get the value of the flag to fill raw pointing information
    Bool fillrawpointing() 
    {return fillOptions_p.fillRawPointing();}

    // set the flag to fill the raw focus information
    Bool setfillrawfocus(Bool fillrawfocus) 
    {fillOptions_p.setFillRawFocus(fillrawfocus); return True;}

    // Get the value of the flag to fill raw pointing information
    Bool fillrawfocus() {return fillOptions_p.fillRawFocus();}

    // Set the flag to fill lags when possible
    Bool setfilllags(Bool filllags) 
    {fillOptions_p.setFillLags(filllags); return True;}

    // Get the value of the flag to fill lags when possible
    Bool filllags() {return fillOptions_p.fillLags();}

    // Set the value of the vanVleck correction for ACS data
    Bool setvv(const String &vv) 
    {return fillOptions_p.setVanVleckCorr(vv);}

    // Get the value of the vanVleck correction for ACS data
    String vv() {return fillOptions_p.vanVleckCorrString();}

    // Set the value of the smoothing for ACS data
    Bool setsmooth(const String &smooth) 
    {return fillOptions_p.setSmoothing(smooth);}

    // Get the value of the vanVleck correction for ACS data
    String smooth() {return fillOptions_p.smoothingString();}

    // Set the flag to use (or not) the HIGH_CAL_TEMP when filling TCAL
    Bool setusehighcal(Bool usehighcal)
    {fillOptions_p.setUseHighCal(usehighcal); return True;}

    // Query to see which CAL_TEMP is being used
    Bool usehighcal()
    {return fillOptions_p.useHighCal();}

    // Set the flat to compress (or not) the calibration columns
    // This must be set before the MS is created as that is the only
    // time it is used.
    Bool setcompresscalcols(Bool compresscalcols)
    {fillOptions_p.setCompressCalCols(compresscalcols); return True;}

    // Query to see if the calibration columns will be compressed.
    Bool compresscalcols()
    {return fillOptions_p.compressCalCols();}

    // Set the vv table size - for the Schwab vv correction and
    // ACS data only - should be an odd number.
    Bool setvvsize(Int vvsize)
    {return fillOptions_p.setvvSize(vvsize);}

    // Retrieve the vv table size
    Int vvsize()
    {return fillOptions_p.vvSize();}

    // Should the filler use a derived approximation to the dcbias in
    // the vanVleck correction - schwab vv only
    Bool setusebias(Bool usebias)
    {fillOptions_p.setUseBias(usebias); return True;}

    // Is the dcbias to be used?
    Bool usebias()
    {return fillOptions_p.useBias();}

    // Should the filler fill multi bank ACS data to a single MS
    Bool setoneacsms(Bool oneacsms)
    {fillOptions_p.setOneacsms(oneacsms); return True;}

    // Is a single MS being filled for multi bank ACS data?
    Bool oneacsms()
    {return fillOptions_p.oneacsms();}

    // Set a specific dcbias to use.
    Bool setdcbias (Double dcbias)
    {return fillOptions_p.setDCBias(dcbias);}

    // Get the specific dcbias to use
    Double dcbias()
    { return fillOptions_p.dcbias();}

    // Set a minimum bias factor to use when offsetting the lags
    Bool setminbiasfactor (Int minbiasfactor)
    {return fillOptions_p.setMinbiasfactor(minbiasfactor);}

    // Get the minimum bias factor to use when offsetting the lags
    Int minbiasfactor ()
    { return fillOptions_p.minbiasfactor();}

    // Toggle the option to fix bad ACS lags, when possible
    Bool setfixbadlags (Bool fixbadlags)
    {fillOptions_p.setFixbadlags(fixbadlags); return True;}

    // What is the state of the fixbadlags toggle
    Bool fixbadlags()
    { return fillOptions_p.fixbadlags();}

    // force a new MeasurementSet
    Bool newms();

    // Check the internal data of this class for consistant and valid
    // values.  Returns True if everything is fine otherwise returns False.
    Bool DOok() const {return True;}

    // return the name of this object type the distributed object system.
    // This function is required as part of the DO system
    virtual String className() const {return "gbtmsfiller";}

    // the returned vector contains the names of all the methods which may be
    // used via the distributed object system.
    // This function is required as part of the DO system
    virtual Vector<String> methods() const;

    // the returned vector contains the names of all the methods which are to
    // trivial to warrent automatic logging.
    // This function is required as part of the DO system
    virtual Vector<String> noTraceMethods() const;

    // Run the specified method. This is the function used by the distributed
    // object system to invoke any of the specified member functions in thios
    // class.
    // This function is required as part of the DO system
    virtual MethodResult runMethod(uInt which, ParameterSet & parameters, 
				   Bool runMethod);
private:
    Directory projectDir_p, msDir_p;
    GBTScanLogReader::BACKENDS backend_p;
    String msroot_p, truemsroot_p;
    MVTime minTime_p, maxTime_p;
    String object_p;
    Regex objectRegex_p;
    GBTMSFillOptions fillOptions_p;
    Int initialMinScan_p, initialMaxScan_p;

    // a pointer to every possible filler
    GBTDCRFiller *dcrFiller_p;
    GBTSPFiller *spFiller_p;
    GBTHoloFiller *holoFiller_p;
    // acsFiller_p is used when oneacsms is true the
    // rest are used when oneacsms is false
    GBTACSFiller *acsFiller_p, *acsAFiller_p, *acsBFiller_p, *acsCFiller_p,
	*acsDFiller_p;
    // and to tell when its okay to fill each one
    // if any ACS is okay to fill, they all are (okToFillAcs_p)
    Bool okToFillDCR_p, okToFillSP_p, okToFillHolo_p, okToFillAcs_p;

    GBTScanLogReader *reader_p;

    Record status_p;
    RecordFieldPtr<Bool> attachedStatus_p, fillRawPointingStatus_p, 
	fillRawFocusStatus_p, fillLagsStatus_p, useHighCalStatus_p, 
	compressCalColStatus_p, useBiasStatus_p, oneacsmsStatus_p, 
	fixbadlagsStatus_p;
    RecordFieldPtr<Int> nextScanStatus_p, minScanStatus_p, maxScanStatus_p,
	dcrMSSize_p, holoMSSize_p, spMSSize_p, acsMSSize_p, 
	acsAMSSize_p, acsBMSSize_p, acsCMSSize_p, acsDMSSize_p,
	minbiasfactorStatus_p;
    RecordFieldPtr<Double> nextDmjdStatus_p, nextTimeStampStatus_p, 
	dcbiasStatus_p;
    RecordFieldPtr<String> projectStatus_p, objectStatus_p, backendTypeStatus_p,
	msDirStatus_p, minTimeStatus_p, maxTimeStatus_p, dcrMSStatus_p,
	holoMSStatus_p, spMSStatus_p, acsMSStatus_p, acsAMSStatus_p, 
	acsBMSStatus_p, acsCMSStatus_p, acsDMSStatus_p, 
	vvStatus_p, smoothStatus_p;

    Bool more_p;

    // initializes everything, if silent is True, suppress warning messages
    void init(Bool silent);

    // initializes the status record
    void initStatusRecord();

    // cleans up things
    void cleanup();

    // set the true msroot name
    void set_truemsroot();

    // convenience function
    Bool makeTime(MVTime &totime, const String &fromString);

    // see if the current scan is interesting, return True if at
    // least one backend is ok to fill.  The backends are returned
    // in the argument to avoid the need to construct that value twice.
    Bool isInteresting(Block<Int> &backends, Block<String> &backendFiles);

    // advance the reader to the next scan, set more_p as appropriate
    void next();

    // wraps up the call to the GBTACSFiller::fill so that
    // that code can be shared
    void acsFill(const Vector<String> &files, GBTACSFiller *filler);

    // used in filling the status record fields for the indicated filler
    void doStatus(GBTBackendFiller *filler,
		  RecordFieldPtr<String> &msStatusField,
		  RecordFieldPtr<Int> &msSizeField);

    // undefined and unavailable
    gbtmsfiller(const gbtmsfiller &other);
    gbtmsfiller &operator=(const gbtmsfiller &other);

};

#endif

