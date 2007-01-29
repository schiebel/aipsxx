//# DOms.h: the implementation of the ms DO
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
//# $Id: DOms.h,v 19.10 2005/11/24 00:50:12 kgolap Exp $

#ifndef APPSGLISH_DOMS_H
#define APPSGLISH_DOMS_H

#include <casa/aips.h>
#include <ms/MeasurementSets/MSFlagger.h>
#include <ms/MeasurementSets/MSSelector.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <casa/Logging/LogIO.h>


#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class MethodResult;
class ObjectId;
class ParameterSet;
class String;
class GlishRecord;
template <class T> class Vector;
} //# NAMESPACE CASA - END


// <summary> Implementation of the ms DO
// </summary>

// <visibility=local>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> MeasurementSet
//   <li> MS helper classes
// </prerequisite>
//
// <etymology>
// This is the Distributed Object for the MeasurementSet
// </etymology>
//
// <synopsis>
// This class is the interface to glish for the various MS related classes
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// It is handy to have all MS related operations together in one interface.
// </motivation>
//
// <thrown>
//    <li>
//    <li>
// </thrown>
//
// <todo asof="1998/10/31">
//   <li> add this feature
//   <li> fix this bug
//   <li> start discussion of this possible extension
// </todo>

class ms: public ApplicationObject
{
public:
  // Create a ms object from a measurement set Table. 
  ms(MeasurementSet& thems);

  // Create a ms object from a uvfits file. The FITS file is read and
  // translated into a measurement set table. The resultant table is then used.
  // Set lock=True to permanently lock the measurement set table.
  // Specify obstype to specify the tiling scheme (MSTileLayout::ObsType)
  ms(const String& msfile, const String& fitsfile, Bool readonly, Bool lock,
     Int obstype);

  // The destructor is fairly trivial
  ~ms();

  // Returns the number of rows in the measurement set or zero if the ms is not
  // attached to a table. If selected == True, return the number of rows in
  // the currently selected table.
  uInt nrow(Bool selected=False) const;

  // Returns True if the measurementset has been opened for writing
  Bool iswritable() const;

  // Close the current ms, and replace it with the supplied ms.
  void open(const String& msfile, Bool readonly, Bool lock);

  // Flush the ms to disk and detach from the ms file. All function
  // calls after this will return default values.
  void close();

  // Return the file name of the measurement set.
  String name() const;

  // Create a new ms from Table Query Language command.
  ObjectID command(const String& msfile, const String& command,
		   Bool readonly) const;

  // Write the measurement set to the specified uv fits file???
  void tofits(const String& fitsfile, const String& column, 
	      Vector<Int>& fieldids, Vector<Int>& spectralwindowids,
	      Int startchan, Int nchan, Int chanstep,
	      Bool writeSysCal, Bool multiSource, Bool combineSpw,
              Bool writeStation) const; 

  // Return a record with fields name and nrow containing the measurement set
  // name, & number of rows. Also sends a more detailed summary of the
  // measurement set to the logger.
  void summary(GlishRecord& header, Bool verbose) const;

  // Send history of the measurement set to the logger
  void listhistory() const;

  // Write to HISTORY table of MS
  void writehistory(String message, String parms="",
		    String origin="ms::writehistory()",
		    String msname="", String app="ms");

  // Returns the ranges of the items specified in the Vector. When
  // useflags is True, flagged data is excluded from the range.
  // (Only the FLAG column is checked and only DATA related 
  //  items are affected.)
  // Set the blockSizeMB argument to set the memory buffer size in MB during
  // operation - increase for large datasets on large memory machines.
  GlishRecord range(const Vector<String>& items, Bool useflags,
		    Int blockSizeMB=10);

  // List the ms by rows in the logger, given start/stop times
  void lister(String starttime, String stoptime) const; 

  // Initialises the selected Measurement set to contain data with only the
  // specified data description id. The ddId argument must be positive and the
  // first data description id is numbered one. Setting ddId to zero will
  // select all the entire MS if the data shape is constant otherwise it will
  // select the first ddId and return False. Setting reset to True will discard
  // all selections.
  Bool selectinit(const Vector<Int>& ddId, Bool reset);
  
  // Makes a selection, you can use range to get a record with items, then 
  // restrict the range of them and feed it back to select.
  Bool select(const GlishRecord& items);

  // Makes a selection based on a TaQL string
  Bool selecttaql(const String& msselect);

  // Select a range of channels
  Bool selectchannel(Int nChan, Int start, Int width, Int inc);

  // Select a range of polarizations
  Bool selectpolarization(const Vector<String>& wantedPol);

  // get out the data items specified, add an interferometer axis if
  // ifraxis is True, put a gap in the ifr axis whenever antenna1 changes with
  // ifraxisgap >0, set increment to >1 to skip rows, set average to
  // True to average data in the row or time direction.
  GlishRecord getdata(const Vector<String>& items, Bool ifraxis,
		      Int ifraxisgap, Int increment, Bool average);

  // put the data back in to the MS, generally the items arguments would be
  // a modified version of the one returned by getdata.
  Bool putdata(const GlishRecord& items);

  // Initialise the iterator
  Bool iterinit(const Vector<String>& columns, Double interval, Int maxrows,
		Bool adddefaultsortcolumns);

  // Reset the iterator
  Bool iterorigin();

  // Move the iteraror to the next chunk
  Bool iternext();

  // Move the iterator to the end
  Bool iterend();

  // Create the flag history
  Bool createflaghistory(Int numlevel);

  // Restore the flag
  Bool restoreflags(Int level);

  // Save the flags
  Bool saveflags(Bool newlevel);

  // return the flag level
  Int flaglevel();

  // Fill the buffer
  Bool fillbuffer(const String& item, Bool ifraxis);

  // Difference the buffer
  GlishRecord diffbuffer(const String& direction, Int window, Bool domedian);

  // Get the buffer
  GlishRecord getbuffer();

  // Clip the buffer
  Bool clipbuffer(Float pixellevel, Float timelevel, Float channellevel);

  // Set the buffer flags
  Bool setbufferflags(const GlishRecord& flags);

  // Write the buffer flags
  Bool writebufferflags();

  // Clear the buffer
  Bool clearbuffer();

  // Append the specified measurement set to the current one. This copies all
  // data.
  void concatenate(const String& msfile, Quantity& freqTol, Quantity& dirTol);
  
  
  // Function to make a new ms which is a subset of current one
  void split(String& outputMS, Vector<Int>& fieldids, Vector<Int>& spwids, 
	     Vector<Int>& nchan, Vector<Int>& start, Vector<Int>& step,
	     Vector<Int>& antennaids, Vector<String>& antennanames,
	     Quantity& timeBin, String& timeRange, 
	     String& which);

  //Subtract a continuum fit from selected spectra
  void continuumsub(Vector<Int>& fieldids, Vector<Int>& ddids, 
	            Vector<Int>& channels, Float solint, 
	            Int order, String& mode);
 
  // return the name of this object type the distributed object system.
  // This function is required as part of the DO system
  virtual String className() const;
  
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
  virtual MethodResult runMethod(uInt which, 
				 ParameterSet& inputRecord,
				 Bool runMethod);
private:
  //# The default constructor is private and undefined
  ms();
  //# The copy constructor is private and undefined
  ms(const ms& other);
  //# The assignment operator is private and undefined
  ms& operator=(const ms& other);

  enum methods {NROW=0, ISWRITABLE, OPEN, CLOSE, NAME, COMMAND, TOFITS,
		SUMMARY, LISTHISTORY, RANGE, LISTER,
		SELECTINIT, SELECT, SELECTTAQL, SELECTCHANNEL, 
		SELECTPOLARIZATION,
		GETDATA, PUTDATA,
		ITERINIT, ITERORIGIN, ITERNEXT, ITEREND,
		CREATEFLAGHISTORY, RESTOREFLAGS, SAVEFLAGS, FLAGLEVEL,
		FILLBUFFER, DIFFBUFFER, GETBUFFER, CLIPBUFFER, SETBUFFERFLAGS,
		WRITEBUFFERFLAGS, CLEARBUFFER, WRITEHISTORY,
		CONCATENATE, SPLIT, CONTINUUMSUB,
		NUM_METHODS};

  MeasurementSet itsMS;
  MSSelector itsSel;
  MSFlagger itsFlag;
  //# This is mutable so that const functions can still send log messages.
  mutable LogIO itsLog;
  //# Prints an error message if the ms DO is detached and returns True.
  Bool detached() const;
};

#endif
