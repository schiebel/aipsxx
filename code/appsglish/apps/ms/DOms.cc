//# DOms.cc: this implements the ms DO
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
//# $Id: DOms.cc,v 19.17 2006/08/16 22:02:20 gmoellen Exp $

#include <appsglish/ms/DOms.h>
#include <msfits/MSFits/MSFitsInput.h>
#include <msfits/MSFits/MSFitsOutput.h>
#include <ms/MeasurementSets/MSRange.h>
#include <ms/MeasurementSets/MSSummary.h>
#include <ms/MeasurementSets/MSLister.h> 
#include <ms/MeasurementSets/MSConcat.h>
#include <ms/MeasurementSets/MSContinuumSubtractor.h>
#include <msvis/MSVis/SubMS.h>
#include <tasking/Tasking/ApplicationEnvironment.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/NewFileConstraint.h>
#include <tasking/Tasking/ObjectController.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterSet.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Exceptions/Error.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishRecord.h>
#include <casa/Logging/LogOrigin.h>
#include <casa/OS/DOos.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/TableLock.h>
#include <tables/Tables/TableParse.h>
#include <casa/System/ObjectID.h>
#include <casa/Utilities/Assert.h>
#include <casa/BasicSL/String.h>
#include <tasking/Tasking/Index.h>

#include <tables/Tables/SetupNewTab.h>
#include <ms/MeasurementSets/MSHistoryHandler.h>

#include <casa/namespace.h>
// ms::ms() : itsMS(),itsSel(),itsFlag() {};

ms::ms(MeasurementSet& theMs)
  :itsMS(theMs),
   itsSel(itsMS),
   itsFlag(itsSel)
{
}

ms::ms(const String& msfile, const String& fitsfile,
       Bool readonly, Bool lock, Int obstype)
  :itsMS(),
   itsSel(),
   itsFlag()
{
  itsLog << LogOrigin("ms", "ms");
  try {
    MSFitsInput msfitsin(msfile, fitsfile);
    msfitsin.readFitsFile(obstype);
    itsLog << LogIO::NORMAL << "Flushing MS to disk" << LogIO::POST;
  }
  catch (AipsError x) {
    itsLog << LogIO::SEVERE << "FITS conversion failed, output may be corrupt"
	   << LogIO::POST;
    throw;
  }
  open(msfile, readonly, lock);
}

// ms::ms(const ms& other)
//   :itsMS(other),
//    itsSel(other),
//    itsFlag(itsSel)
// {
// }

// ms& ms::operator=(const ms& other) {
//   if (this != &other) {
//     itsMS = other.itsMS;
//     itsSel = other.itsSel;
//     itsFlag = other.itsFlag;
//   }
//   return *this;
// }

ms::~ms() {
}

uInt ms::nrow(Bool selected) const {
  if (!detached()) {
    if (!selected) {
      return itsMS.nrow();
    } else {
      return itsSel.nrow();
    }
  } else {
    return 0;
  }
}

Bool ms::iswritable() const {
  if (!detached()) {
    return itsMS.isWritable();
  } else {
    return False;
  }
}

void ms::open(const String& msfile, Bool readonly, Bool lock) {
  const Table::TableOption openOption = readonly ? Table::Old : Table::Update;
  TableLock tl;
  if (lock) tl = TableLock(TableLock::PermanentLocking);
  
  itsMS = MeasurementSet(msfile, tl, openOption);
  itsSel.setMS(itsMS);
  itsFlag.setMSSelector(itsSel);
}

void ms::close() {
  if (!detached()) {
    itsLog << LogOrigin("ms", "close");
    itsLog << LogIO::NORMAL;
    if (itsMS.isWritable()) {     
      itsLog << "Flushing data to disk and detaching from file.";
    }
    else {
      itsLog << "Readonly measurement set: just detaching from file.";
    }
    itsLog << LogIO::POST;
    itsMS = MeasurementSet();
    itsSel.setMS(itsMS);
    itsFlag.setMSSelector(itsSel);
  }
}

String ms::name() const {
  if (!detached()) {
    return itsMS.tableName();
  } else {
    return "none";
  }
}

void ms::summary(GlishRecord& header, Bool verbose) const {
  if (!detached()) {
    itsLog << LogOrigin("ms", "summary");
    MSSummary mss(itsMS);
    mss.list(itsLog, verbose);
    GlishRecord retval;
    retval.add("name", GlishArray(name()));
    retval.add("nrow", GlishArray(static_cast<Int>(nrow())));
    header = retval;
  }
}

void ms::listhistory() const {
  if (!detached()) {
    itsLog << LogOrigin("ms", "listhistory");
    MSSummary mss(itsMS);
    mss.listHistory(itsLog);
  }
}

void ms::tofits(const String& fitsfile, const String& column, 
		Vector<Int>& datafieldids, Vector<Int>& datadescids,
		Int startchan, Int nchan, Int chanstep,
		Bool writeSysCal, Bool multiSource, Bool combineSpw,
                Bool writeStation) const {
  if (!detached()) {
    try {
      
      // This section goes away when tofits make use of selectinit and
      // select for writing fits output
      //=================================================


      MeasurementSet *mssel;
      Bool nosubselect=False;
      // Now we make a condition to do the old FIELD_ID, SPECTRAL_WINDOW_ID
      // selection

      TableExprNode condition;
      String colf=MS::columnName(MS::FIELD_ID);
      String cols=MS::columnName(MS::DATA_DESC_ID);
      if(datafieldids.nelements()>0&&datadescids.nelements()>0){
	condition=itsMS.col(colf).in(datafieldids)&&
	  itsMS.col(cols).in(datadescids);
        itsLog << "Selecting on field and spectral window ids" << LogIO::POST;
      }
      else if(datadescids.nelements()>0) {
	condition=itsMS.col(cols).in(datadescids);
        itsLog << "Selecting on spectral window id" << LogIO::POST;
      }
      else if(datafieldids.nelements()>0) {
	condition=itsMS.col(colf).in(datafieldids);
        itsLog << "Selecting on field id" << LogIO::POST;
      }
      else{
	nosubselect=True;
      }
      
      if(nosubselect){
	mssel=new MeasurementSet(itsMS);
      }
      else{
	mssel = new MeasurementSet(itsMS(condition));
      }
      if(mssel->nrow()!= itsMS.nrow()) {
	itsLog << "By selection " << itsMS.nrow() 
	       <<  " rows to be converted are reduced to "
	       << mssel->nrow() << LogIO::POST;
      }


      if(mssel->nrow()==0) {
	delete mssel; mssel=0;
	itsLog << LogIO::WARN
	   << "No data for selection: will convert full MeasurementSet"
	       << LogIO::POST;
	mssel=new MeasurementSet(itsMS);
      }
      //==================================================   
      if (!MSFitsOutput::writeFitsFile(fitsfile, *mssel, column, startchan, 
				       nchan, chanstep, writeSysCal,
				       multiSource, combineSpw, writeStation)) {
	itsLog << LogIO::SEVERE << "Conversion to FITS failed"<< LogIO::POST;
      }
    } catch (AipsError x) {
      itsLog << LogIO::SEVERE 
	     << "Unexpected error, output may be corrupted : "
	     << x.getMesg() << LogIO::POST;
    }
  }
}

GlishRecord ms::range(const Vector<String>& items, Bool useflags, 
		      Int blockSizeMB) {
  GlishRecord retval;
  if (!detached()) {
    // need to ensure initialization of channel selection of MSSelector
    //    if (!itsSel.selected()) itsSel.initSelection();
    MSRange msrange(itsSel);
    msrange.setBlockSize(blockSizeMB);
    retval.fromRecord(msrange.range(items, useflags, True));
  }
  return retval;
}

void ms::lister(const String starttime, const String stoptime ) const {
    if (detached()) return;

    itsLog << LogOrigin("ms", "lister");

    MSLister msl(itsMS,itsLog);
    msl.list(starttime,stoptime);
}                                          


Bool ms::selectinit(const Vector<Int>& ddId, Bool reset) {
  Bool retval = False;
  if (!detached()) {
    Int n=ddId.nelements();
    if (n>0 && min(ddId)<0) {
      itsLog << "The data description id must be a list of "
	"positive integers" << LogIO::EXCEPTION;
    }
    if (n>0) {
      Vector<Int> tmp(ddId.nelements());
      tmp=ddId;
      tmp-=1;
      retval = itsSel.initSelection(tmp, reset);
    } else {
      retval = itsSel.initSelection(ddId, reset);
    }
  }
  return retval;
}

Bool ms::select(const GlishRecord& items) {
  Bool retval = False;
  if (!detached()) {
    Record myTmp;
    items.toRecord(myTmp);
    retval = itsSel.select(myTmp, True);
  }
  return retval;
}

Bool ms::selecttaql(const String& msselect) {
  Bool retval = False;
  if (!detached()) {
    retval = itsSel.select(msselect);
  }
  return retval;
}


Bool ms::selectchannel(Int nChan, Int start, Int width, Int inc) {
  Bool retval = False;
  if (!detached()) {
    retval = itsSel.selectChannel(nChan, start-1, width, inc);
  }
  return retval;
}

Bool ms::selectpolarization(const Vector<String>& wantedPol) {
  Bool retval = False;
  if (!detached()) {
    retval = itsSel.selectPolarization(wantedPol);
  }
  return retval;
}

GlishRecord ms::getdata(const Vector<String>& items, Bool ifraxis, 
			Int ifraxisgap, Int increment, Bool average) {
  GlishRecord retval;
  if (!detached()) {
    retval.fromRecord(itsSel.getData(items, ifraxis, ifraxisgap, increment, average, True));
  }
  return retval;
}

Bool ms::putdata(const GlishRecord& items) {
  Bool retval = False;
  if (!detached()) {
    Record myTmp;
    items.toRecord(myTmp);
    retval = itsSel.putData(myTmp);
  }
  return retval;
}

Bool ms::iterinit(const Vector<String>& columns, Double interval, Int maxrows,
		  Bool adddefaultsortcolumns){
  Bool retval = False;
  if (!detached()) {
    retval = itsSel.iterInit(columns, interval, maxrows, adddefaultsortcolumns);
  }
  return retval;
}

Bool ms::iterorigin() {
  Bool retval = False;
  if (!detached()) {
    retval = itsSel.iterOrigin();
  }
  return retval;
}

Bool ms::iternext() {
  Bool retval = False;
  if (!detached()) {
    retval = itsSel.iterNext();
  }
  return retval;
}

Bool ms::iterend() {
  Bool retval = False;
  if (!detached()) {
    retval = itsSel.iterEnd();
  }
  return retval;
}

Bool ms::createflaghistory(Int numlevel) {
  Bool retval = False;
  if (!detached()) {
    retval = itsFlag.createFlagHistory(numlevel);
  }
  return retval;
}

Bool ms::restoreflags(Int level) {
  Bool retval = False;
  if (!detached()) {
    retval = itsFlag.restoreFlags(level-1);
  }
  return retval;
}

Bool ms::saveflags(Bool newlevel) {
  Bool retval = False;
  if (!detached()) {
    retval = itsFlag.saveFlags(newlevel);
  }
  return retval;
}

Int ms::flaglevel() {
  Int retval = 1;
  if (!detached()) {
    retval = itsFlag.flagLevel() + 1;
  }
  return retval;
}

Bool ms::fillbuffer(const String& item, Bool ifraxis) {
  Bool retval = False;
  if (!detached()) {
    retval = itsFlag.fillDataBuffer(item, ifraxis);
  }
  return retval;
}

GlishRecord ms::diffbuffer(const String& direction, Int window, Bool domedian){
  GlishRecord retval;
  if (!detached()) {
    retval.fromRecord(itsFlag.diffDataBuffer(direction, window, domedian));
  }
  return retval;
}

GlishRecord ms::getbuffer() {
  GlishRecord retval;
  if (!detached()) {
    retval.fromRecord(itsFlag.getDataBuffer());
  }
  return retval;
}

Bool ms::clipbuffer(Float pixellevel, Float timelevel, Float channellevel) {
  Bool retval = False;
  if (!detached()) {
    retval = itsFlag.clipDataBuffer(pixellevel, timelevel, channellevel);
  }
  return retval;
}

Bool ms::setbufferflags(const GlishRecord& flags) {
  Bool retval = False;
  if (!detached()) {
    Record myTmp;
    flags.toRecord(myTmp);
    retval = itsFlag.setDataBufferFlags(myTmp);
  }
  return retval;
}

Bool ms::writebufferflags() {
  Bool retval = False;
  if (!detached()) {
    retval = itsFlag.writeDataBufferFlags();
  }
  return retval;
}

Bool ms::clearbuffer() {
  Bool retval = False;
  if (!detached()) {
    retval = itsFlag.clearDataBuffer();
  }
  return retval;
}

void ms::writehistory(String message, String parms, String origin,
		      String msname, String app){
  if (message.length() > 0 || parms.length() > 0) {
    MeasurementSet outMS;
    if (msname.length() > 0) {
      outMS = MeasurementSet(msname,TableLock::PermanentLocking,Table::Update);
    } else {
      outMS = MeasurementSet(ms::name(),
			     TableLock::PermanentLocking,Table::Update);
    }
    // make sure the MS has a HISTORY table
    if(!(Table::isReadable(outMS.historyTableName()))){
      TableRecord &kws = outMS.rwKeywordSet();
      SetupNewTable historySetup(outMS.historyTableName(),
				 MSHistory::requiredTableDesc(),Table::New);
      kws.defineTable(MS::keywordName(MS::HISTORY), Table(historySetup));
    }
    MSHistoryHandler::addMessage(outMS, message, app, parms, origin);
  }
}

void ms::concatenate(const String& msfile, Quantity& freqTol, Quantity& dirTol){
  if (!detached()) {
    itsLog << LogOrigin("ms", "concatenate");
//    if (itsMS.tableInfo().subType() != "UVFITS") {
//     itsLog << "The measurement set this tool is attached to was not created"
//	     << " from a UVFITS file" << endl
//	     << "The concatenate function can only oncatenate measurement sets"
//	     << " that have been created from UVFITS files" << endl
//	     << "This will be fixed in a future release of aips++"
//	     << LogIO::EXCEPTION;
//   }
    if (!Table::isReadable(msfile)) {
      itsLog << "Cannot read the measurement set called " << msfile
	     << LogIO::EXCEPTION;
    }
    if (DOos::totalSize(msfile, True) >
	DOos::freeSpace(Vector<String>(1, itsMS.tableName()), True)(0)) {
      itsLog << "There does not appear to be enough free disk space "
	     << "(on the filesystem containing " << itsMS.tableName()
	     << ") for the concatantion to succeed." << LogIO::EXCEPTION;
    }
    const MeasurementSet appendedMS(msfile);
//    if (appendedMS.tableInfo().subType() != "UVFITS") {
//      itsLog << "The measurement set you wish to concatenate was not created"
//	     << " from a UVFITS file" << endl
//	     << "The concatenate function can only oncatenate measurement sets"
//	     << " that have been created from UVFITS files" << endl
//	     << "This will be fixed in a future release of aips++"
//	     << LogIO::EXCEPTION;
//    }
    MSConcat mscat(itsMS);
    Double dirTolVal=dirTol.get("mas").getValue();
    Quantum<Double> dirtolerance(dirTolVal, "mas");
    Double freqTolVal=freqTol.get("Hz").getValue();
    Quantum<Double> freqtolerance(freqTolVal, "Hz");
    mscat.setTolerance(freqtolerance, dirtolerance);
    mscat.concatenate(appendedMS);
  }

  {
    String message = msfile + " appended to " + itsMS.tableName();
    ostringstream param;
    param << "msfile= " << msfile
	  << " freqTol='" << freqTol << "' dirTol='" << dirTol << "'";
    String paramstr=param.str();
    writehistory(message, paramstr, "ms::concatenate()");
  }
}

void ms::split(String& outputMS, Vector<Int>& fieldids, Vector<Int>& spwids, 
	       Vector<Int>& nchan, Vector<Int>& start,  
	       Vector<Int>& step,Vector<Int>& antennaids,
	       Vector<String>& antennanames, Quantity& timeBin, 
	       String& timeRange, String& which){

  itsLog << LogOrigin("ms", "split");

  if (nchan.nelements() != spwids.nelements()){
    if(nchan.nelements()==1){
      nchan.resize(spwids.nelements(), True);
      for(uInt k=1; k < spwids.nelements(); ++k){
	nchan[k]=nchan[0];
      }
    }
    else{
      itsLog << LogIO::SEVERE 
	 << "Vector of nchan has to be of size 1 or be of the same shape as spw " 
	 << LogIO::POST;
      return;
    }
  }


  if (start.nelements() != spwids.nelements()){
    if(start.nelements()==1){
      start.resize(spwids.nelements(), True);
      for(uInt k=1; k < spwids.nelements(); ++k){
	start[k]=start[0];
      }
    }
    else{
      itsLog << LogIO::SEVERE 
	 << "Vector of start has to be of size 1 or be of the same shape as spw " 
	 << LogIO::POST;
      return;
    }
  }

  

  if (step.nelements() != spwids.nelements()){
    if(step.nelements()==1){
      step.resize(spwids.nelements(), True);
      for(uInt k=1; k < spwids.nelements(); ++k){
	step[k]=step[0];
      }
    }
    else{
      itsLog << LogIO::SEVERE 
	 << "Vector of step has to be of size 1 or be of the same shape as spw " 
	 << LogIO::POST;
      return; 
    }
  }

  SubMS splitter(itsMS);
  splitter.selectSpw(spwids, nchan, start, step);
  splitter.selectSource(fieldids);
  splitter.selectAntenna(antennaids, antennanames);
  
  Double timeInSec=timeBin.get("s").getValue();
  splitter.selectTime(timeInSec, timeRange);
  if(!splitter.makeSubMS(outputMS, which)){
    return;
  }
  {// Update HISTORY table of newly created MS
    String message=outputMS + " split from " + itsMS.tableName();
    ostringstream param;
    param << "fieldids=" << fieldids << " spwids=" << spwids
	  << " nchan=" << nchan << " start=" << start << " step=" << step
	  << " which='" <<which <<"'";
    String paramstr=param.str();
    writehistory(message,paramstr,"ms::split()",outputMS);
  }

} 

void ms::continuumsub(Vector<Int>& fieldids, Vector<Int>& ddids, 
	       Vector<Int>& channels, Float solint, 
	       Int order, String& mode){

  itsLog << LogOrigin("ms", "continuumsub");
  itsLog << "continuumsub starting"<<LogIO::POST;

  try {
    
    MSContinuumSubtractor sub(itsMS);
    sub.setDataDescriptionIds(ddids);
    sub.setFields(fieldids);
    sub.setChannels(channels);
    sub.setSolutionInterval(solint);
    sub.setOrder(order);
    sub.setMode(mode);
    sub.subtract();
    itsLog << "continuumsub finished"<<LogIO::POST;  
  } catch (AipsError x) {
    itsLog << LogIO::SEVERE 
	   << x.getMesg() << LogIO::POST;
  }
} 

String ms::className() const {
  return "ms";
}

ObjectID ms::command(const String& msfile, const String& command,
		     Bool readonly) const {
  if (detached()) {
    return ObjectID(True);
  }

  itsLog << LogOrigin("ms", "command");

  String outfile = msfile;
  // Validate outfile
  if (outfile == "") {
    outfile = itsMS.tableName() + ".query";
  }

  try {
    Table subtable = tableCommand("select from " + itsMS.tableName() + 
				  " where " + command + " giving " + outfile);

    ObjectController* controller = ApplicationEnvironment::objectController();
    ApplicationObject* subobject = 0;
    if (controller) {
      // We have a controller, so we can return a valid object id after we
      // register the new object
      if(readonly) {
	MeasurementSet subms(subtable);
	subobject = new ms(subms);
      }
      else {
	subtable.flush();
	MeasurementSet subms(outfile, Table::Update);
	subobject = new ms(subms);
      }
      AlwaysAssert(subobject, AipsError);
      return controller->addObject(subobject);
    } else {
      return ObjectID(True); // null
    }
  } catch (AipsError x) {
    itsLog << LogIO::SEVERE << "Unexpected error, command failed: " <<
      x.getMesg() << LogIO::POST;
    return ObjectID(True);
  } 
  return ObjectID(True);
}

Vector<String> ms::methods() const {
  Vector<String> method(NUM_METHODS);
  // Table operations
  method(NROW) = "nrow";
  method(ISWRITABLE) = "iswritable";
  method(OPEN) = "open";
  method(CLOSE) = "close";
  method(NAME) = "name";
  method(COMMAND) = "command";
  // MSFitsOutput
  method(TOFITS) = "tofits";
  // MSSummary
  method(SUMMARY) = "summary";
  method(LISTHISTORY) = "listhistory";
  // MSRange
  method(RANGE) = "range";
  // MSLister
  method(LISTER) = "lister";
  // MSSelector
  method(SELECTINIT) = "selectinit";
  method(SELECT) = "select";
  method(SELECTTAQL) = "selecttaql";
  method(SELECTCHANNEL) = "selectchannel";
  method(SELECTPOLARIZATION) = "selectpolarization";
  method(GETDATA) = "getdata";
  method(PUTDATA) = "putdata";
  // MSIter
  method(ITERINIT) = "iterinit";
  method(ITERORIGIN) = "iterorigin";
  method(ITERNEXT) = "iternext";
  method(ITEREND) = "iterend";
  // MSFlagger
  method(CREATEFLAGHISTORY) = "createflaghistory";
  method(RESTOREFLAGS) = "restoreflags";
  method(SAVEFLAGS) = "saveflags";
  method(FLAGLEVEL) = "flaglevel";
  method(FILLBUFFER) = "fillbuffer";
  method(DIFFBUFFER) = "diffbuffer";
  method(GETBUFFER) = "getbuffer";
  method(CLIPBUFFER) = "clipbuffer";
  method(SETBUFFERFLAGS) = "setbufferflags";
  method(WRITEBUFFERFLAGS) = "writebufferflags";
  method(CLEARBUFFER) = "clearbuffer";
  method(WRITEHISTORY) = "writehistory";
  method(CONCATENATE) = "concatenate";
  method(SPLIT) = "split"; 
  method(CONTINUUMSUB) = "continuumsub";
  return method;
}

Vector<String> ms::noTraceMethods() const {
  return methods();
}

MethodResult ms::runMethod(uInt which, ParameterSet& inputRecord,
			   Bool runMethod) {
  itsLog << LogOrigin("ms", "runMethod");
  static String returnvalString = "returnval";
  
  switch (which) {
  case NROW: {
    Parameter<Int> returnval(inputRecord, returnvalString,
			     ParameterSet::Out);
    Parameter<Bool> selected(inputRecord, "selected", ParameterSet::In);

    if (runMethod) {
      returnval() = nrow(selected());
    }
  }
  break;
  case ISWRITABLE: {
    Parameter<Bool> returnval(inputRecord, returnvalString,
			      ParameterSet::Out);
    if (runMethod) {
      returnval() = iswritable();
    }
  }
  break;
  case OPEN: {
    static String themsString = "thems";
    Parameter<String> thems(inputRecord, themsString, ParameterSet::In);
    Parameter<Bool> readonly(inputRecord, "readonly", ParameterSet::In);
    Parameter<Bool> lock(inputRecord, "lock", ParameterSet::In);
    if (runMethod) {
      open(thems(), readonly(), lock());
    }
  }
  break;
  case CLOSE: {
    if (runMethod) {
      close();
    }
  }
  break;
  case NAME: {
    Parameter<String> returnval(inputRecord, returnvalString,
				ParameterSet::Out);
    if (runMethod) {
      returnval() = name();
    }
  }
  break;
  case COMMAND: {
    Parameter<ObjectID> returnval(inputRecord, returnvalString,
				  ParameterSet::Out);
    Parameter<String> msfile(inputRecord, "msfile", ParameterSet::In);
    Parameter<String> comm(inputRecord, "command", ParameterSet::In);
    Parameter<Bool> readonly(inputRecord, "readonly", ParameterSet::In);
    if (runMethod) {
      returnval() = command(msfile(), comm(), readonly());
    }
  }
  break;
  case TOFITS: {
    Parameter<String> fitsfile(inputRecord, "fitsfile", ParameterSet::In);
    fitsfile.setConstraint(NewFileConstraint());
    Parameter<String> column(inputRecord, "column", ParameterSet::In);
    Parameter<Vector<Index> > fieldids(inputRecord, "fieldid", 
				       ParameterSet::In);
    Parameter<Vector<Index> > spectralwindowids(inputRecord, "spwid",
						ParameterSet::In);
    Parameter<Int> start(inputRecord, "start", ParameterSet::In);
    Parameter<Int> nchan(inputRecord, "nchan", ParameterSet::In);
    Parameter<Int> width(inputRecord, "width", ParameterSet::In);
    Parameter<Bool> writeSysCal(inputRecord, "writesyscal", ParameterSet::In);
    Parameter<Bool> multiSource(inputRecord, "multisource", ParameterSet::In);
    Parameter<Bool> combineSpw(inputRecord, "combinespw", ParameterSet::In);
    Parameter<Bool> writeStation(inputRecord, "writestation", ParameterSet::In);
    

    uInt i;
    Vector<Int> spws(spectralwindowids().nelements());
    for (i=0;i<spws.nelements();i++) {
      spws(i)=spectralwindowids()(i).zeroRelativeValue();
    }
    Vector<Int> fids(fieldids().nelements());
    for (i=0;i<fids.nelements();i++) {
      fids(i)=fieldids()(i).zeroRelativeValue();
    }
    if (runMethod) {
      tofits(fitsfile(), column(), fids, 
	     spws, start(), nchan(), width(),
	     writeSysCal(), multiSource(), combineSpw(),writeStation());
    }
  }
  break;
  case SUMMARY: {
    static String headerString("header");
    Parameter<GlishRecord> header(inputRecord, headerString,
				  ParameterSet::Out);
    Parameter<Bool> verbose(inputRecord, "verbose", ParameterSet::In);
    if (runMethod) {
      summary(header(), verbose());
    }
  }
  break;
  case LISTHISTORY: {
    if (runMethod) {
      listhistory();
    }
  }
  break;
  case RANGE: {
    Parameter<GlishRecord> returnval(inputRecord, returnvalString,
				     ParameterSet::Out);
    Parameter<Vector<String> > items(inputRecord, "items", ParameterSet::In);
    Parameter<Bool> useflags(inputRecord, "useflags", ParameterSet::In);
    Parameter<Int> blocksize(inputRecord, "blocksize", ParameterSet::In);
    if (runMethod) {
	returnval() = range(items(),useflags(),blocksize());
    }
  }
  break;
  case LISTER: {
    Parameter<String> starttime(inputRecord, "starttime",
                                             ParameterSet::In);
    Parameter<String> stoptime(inputRecord, "stoptime",
                                             ParameterSet::In);
    if (runMethod) {
      lister(starttime(), stoptime());
    }
  }                                    
  break;
  case SELECTINIT: {
    Parameter<Bool> returnval(inputRecord, returnvalString,
			      ParameterSet::Out);
    Parameter<Vector<Int> > ddId(inputRecord, "datadescid", ParameterSet::In);
    Parameter<Bool> reset(inputRecord, "reset", ParameterSet::In);
    if (runMethod) {
      returnval() = selectinit(ddId(), reset());
    }
  }
  break;
  case SELECT: {
    Parameter<Bool> returnval(inputRecord, returnvalString,
			      ParameterSet::Out);
    Parameter<GlishRecord> items(inputRecord, "items", ParameterSet::In);
    if (runMethod) {
      returnval() = select(items());
    }
  }
  break;
  case SELECTTAQL: {
    Parameter<Bool> returnval(inputRecord, returnvalString,
			      ParameterSet::Out);
    Parameter<String> msselect(inputRecord, "msselect", ParameterSet::In);
    if (runMethod) {
      returnval() = selecttaql(msselect());
    }
  }
  break;
  case SELECTCHANNEL: {
    Parameter<Bool> returnval(inputRecord, returnvalString,
			      ParameterSet::Out);
    Parameter<Int> nChan(inputRecord, "nchan", ParameterSet::In);
    Parameter<Int> start(inputRecord, "start", ParameterSet::In);
    Parameter<Int> width(inputRecord, "width", ParameterSet::In);
    Parameter<Int> inc(inputRecord, "inc", ParameterSet::In);
    if (runMethod) {
      returnval() = selectchannel(nChan(), start(), width(), inc());
    }
  }
  break;
  case SELECTPOLARIZATION: {
    Parameter<Bool> returnval(inputRecord, returnvalString,
			      ParameterSet::Out);
    Parameter<Vector<String> > wantedPol(inputRecord, "wantedpol",
					 ParameterSet::In);
    if (runMethod) {
      returnval() = selectpolarization(wantedPol());
    }
  }
  break;
  case GETDATA: {
    Parameter<GlishRecord> returnval(inputRecord, returnvalString,
				     ParameterSet::Out);
    Parameter<Vector<String> > items(inputRecord, "items", ParameterSet::In);
    Parameter<Bool> ifraxis(inputRecord, "ifraxis", ParameterSet::In);
    Parameter<Int> ifraxisgap(inputRecord, "ifraxisgap", ParameterSet::In);
    Parameter<Int> increment(inputRecord, "increment", ParameterSet::In);
    Parameter<Bool> average(inputRecord, "average", ParameterSet::In);
    if (runMethod) {
      returnval() = getdata(items(), ifraxis(), ifraxisgap(), increment(), average());
    }
  }
  break;
  case PUTDATA: {
    Parameter<Bool> returnval(inputRecord, returnvalString, ParameterSet::Out);
    Parameter<GlishRecord> items(inputRecord, "items", ParameterSet::In);
    if (runMethod) {
      returnval() = putdata(items());
    }
  }
  break;
  case ITERINIT: {
    Parameter<Bool> returnval(inputRecord, returnvalString, ParameterSet::Out);
    Parameter<Vector<String> > columns(inputRecord, "columns",
				       ParameterSet::In);
    Parameter<Double> interval(inputRecord, "interval", ParameterSet::In);
    Parameter<Int> maxrows(inputRecord, "maxrows", ParameterSet::In);
    Parameter<Bool> adddefaultsortcolumns(inputRecord, "adddefaultsortcolumns",
					  ParameterSet::In);
    if (runMethod) {
      returnval() = iterinit(columns(), interval(), maxrows(),
			     adddefaultsortcolumns());
    }
  }
  break;
  case ITERORIGIN: {
    Parameter<Bool> returnval(inputRecord, returnvalString, ParameterSet::Out);
    if (runMethod) {
      returnval() = iterorigin();
    }
  }
  break;
  case ITERNEXT: {
    Parameter<Bool> returnval(inputRecord, returnvalString, ParameterSet::Out);
    if (runMethod) {
      returnval() = iternext();
    }
  }
  break;
  case ITEREND: {
    Parameter<Bool> returnval(inputRecord, returnvalString, ParameterSet::Out);
    if (runMethod) {
      returnval() = iterend();
    }
  }
  break;
  case CREATEFLAGHISTORY: {
    Parameter<Bool> returnval(inputRecord, returnvalString, ParameterSet::Out);
    Parameter<Int> numlevel(inputRecord, "numlevel", ParameterSet::In);
    if (runMethod) {
      returnval() = createflaghistory(numlevel());
    }
  }
  break;
  case RESTOREFLAGS: {
    Parameter<Bool> returnval(inputRecord, returnvalString, ParameterSet::Out);
    Parameter<Int> level(inputRecord, "level", ParameterSet::In);
    if (runMethod) {
      returnval() = restoreflags(level());
    }
  }
  break;
  case SAVEFLAGS: {
    Parameter<Bool> returnval(inputRecord, returnvalString, ParameterSet::Out);
    Parameter<Bool> newlevel(inputRecord, "newlevel", ParameterSet::In);
    if (runMethod) {
      returnval() = saveflags(newlevel());
    }
  }
  break;
  case FLAGLEVEL: {
    Parameter<Int> returnval(inputRecord, returnvalString, ParameterSet::Out);
    if (runMethod) {
      returnval() = flaglevel();
    }
  }
  break;
  case FILLBUFFER: {
    Parameter<Bool> returnval(inputRecord, returnvalString, ParameterSet::Out);
    Parameter<String> item(inputRecord, "item", ParameterSet::In);
    Parameter<Bool> ifraxis(inputRecord, "ifraxis", ParameterSet::In);
    if (runMethod) {
      returnval() = fillbuffer(item(), ifraxis());
    }
  }
  break;
  case DIFFBUFFER: {
    Parameter<GlishRecord> returnval(inputRecord, returnvalString,
				     ParameterSet::Out);
    Parameter<String> direction(inputRecord, "direction", ParameterSet::In);
    Parameter<Int> window(inputRecord, "window", ParameterSet::In);
    Parameter<Bool> domedian(inputRecord, "domedian", ParameterSet::In);
    if (runMethod) {
      returnval() = diffbuffer(direction(), window(), domedian());
    }
  }
  break;
  case GETBUFFER: {
    Parameter<GlishRecord> returnval(inputRecord, returnvalString, 
				     ParameterSet::Out);
    if (runMethod) {
      returnval() = getbuffer();
    }
  }
  break;
  case CLIPBUFFER: {
    Parameter<Bool> returnval(inputRecord, returnvalString, ParameterSet::Out);
    Parameter<Float> pixellevel(inputRecord, "pixellevel", ParameterSet::In);
    Parameter<Float> timelevel(inputRecord, "timelevel", ParameterSet::In);
    Parameter<Float> channellevel(inputRecord, "channellevel", 
				  ParameterSet::In);
    if (runMethod) {
      returnval() = clipbuffer(pixellevel(), timelevel(), channellevel());
    }
  }
  break;
  case SETBUFFERFLAGS: {
    Parameter<Bool> returnval(inputRecord, returnvalString, ParameterSet::Out);
    Parameter<GlishRecord> flags(inputRecord, "flags", ParameterSet::In);
    if (runMethod) {
      returnval() = setbufferflags(flags());
    }
  }
  break;
  case WRITEBUFFERFLAGS: {
    Parameter<Bool> returnval(inputRecord, returnvalString, ParameterSet::Out);
    if (runMethod) {
      returnval() = writebufferflags();
    }
  }
  break;
  case CLEARBUFFER: {
    Parameter<Bool> returnval(inputRecord, returnvalString, ParameterSet::Out);
    if (runMethod) {
      returnval() = clearbuffer();
    }
  }
  break;
  case WRITEHISTORY: {
    Parameter<String> message(inputRecord, "message", ParameterSet::In);
    Parameter<String> parms  (inputRecord, "parms",   ParameterSet::In);
    Parameter<String> origin (inputRecord, "origin",  ParameterSet::In);
    Parameter<String> msname (inputRecord, "msname",  ParameterSet::In);
    Parameter<String> app    (inputRecord, "app",     ParameterSet::In);
    if (runMethod) {
      writehistory(message(), parms(), origin(), msname(), app());
    }
  }
  break;
  case CONCATENATE: {
    Parameter<String> msfile(inputRecord, "msfile", ParameterSet::In);
    Parameter<Quantity> freqtolerance(inputRecord, "freqtol", ParameterSet::In);
    Parameter<Quantity> dirtolerance(inputRecord, "dirtol", ParameterSet::In);
    if (runMethod) {
      concatenate(msfile(), freqtolerance(), dirtolerance());
    }
  }
  break;
  case SPLIT: {
    Parameter<String> outputms(inputRecord, "outputms", ParameterSet::In);
    Parameter<Vector<Index> > fieldids(inputRecord, "fieldids", ParameterSet::In);
    Parameter<Vector<Index> > spectralwindowids(inputRecord, "spwids",
						  ParameterSet::In);
    Parameter<Vector<Int> > nchan(inputRecord, "nchan", ParameterSet::In);
    Parameter<Vector<Index> > start(inputRecord, "start", ParameterSet::In);
    Parameter<Vector<Int> > step(inputRecord, "step", ParameterSet::In);
    Parameter<Vector<Index> > antennaids(inputRecord, "antennaids", 
					 ParameterSet::In);
    Parameter<Vector<String> > antennanames(inputRecord, "antennanames", 
					    ParameterSet::In);
    Parameter<Quantity> timebin(inputRecord, "timebin", ParameterSet::In);
    Parameter<String> timerange(inputRecord, "timerange", ParameterSet::In);
    Parameter<String> which(inputRecord, "whichcol", ParameterSet::In);
    Vector<Int> spws(spectralwindowids().nelements());
    uInt i;
    for (i=0;i<spws.nelements();i++) {
      spws(i)=spectralwindowids()(i).zeroRelativeValue();
    }
    Vector<Int> antids(antennaids().nelements());
    for (i=0;i<antids.nelements();i++) {
      antids(i)=antennaids()(i).zeroRelativeValue();
    }

    Vector<Int> fids(fieldids().nelements());
    for (i=0;i<fids.nelements();i++) {
      fids(i)=fieldids()(i).zeroRelativeValue();
    }
    Vector<Int> chanstart(start().nelements());
    for (i=0;i<chanstart.nelements();i++) {
      chanstart(i)=start()(i).zeroRelativeValue();
    }
    if (runMethod) {
      split(outputms(), fids, spws, nchan(), chanstart, step(), antids, 
	    antennanames(), timebin(), timerange(), which());
    }

  }
  break; 
  case CONTINUUMSUB: {
    Parameter<Vector<Index> > fieldids(inputRecord, "fieldids", ParameterSet::In);
    Parameter<Vector<Index> > ddids(inputRecord, "ddids",
						  ParameterSet::In);
    Parameter<Vector<Index> > chans(inputRecord, "chans", ParameterSet::In);
    Parameter<Float> solint(inputRecord, "solint", ParameterSet::In);
    Parameter<Int> fitorder(inputRecord, "fitorder", ParameterSet::In);
    Parameter<String> mode(inputRecord, "mode", ParameterSet::In);
    Vector<Int> dds(ddids().nelements());
    uInt i;
    for (i=0;i<dds.nelements();i++) {
      dds(i)=ddids()(i).zeroRelativeValue();
    }
    Vector<Int> fids(fieldids().nelements());
    for (i=0;i<fids.nelements();i++) {
      fids(i)=fieldids()(i).zeroRelativeValue();
    }
    Vector<Int> channels(chans().nelements());
    for (i=0;i<channels.nelements();i++) {
      channels(i)=chans()(i).zeroRelativeValue();
    }
    if (runMethod) {
      continuumsub(fids, dds, channels, solint(), fitorder(), mode());
    }

  }
  break; 
  default:
    return error("No such method");
  }
  return ok();
}

Bool ms::detached() const {
  if (itsMS.isNull()) {
    itsLog << LogOrigin("ms", "detached");
    itsLog << LogIO::SEVERE
	   << "ms is not attached to a file - cannot perform operation.\n" 
	   << "Call ms.open('filename') to reattach." << LogIO::POST;
    return True;
  }
  return False;
}
// Local Variables: 
// compile-command: "gmake DOms"
// End: 
