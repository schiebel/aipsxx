//# CalHistoryBuffer.h: Calibration table cal_history buffer
//# Copyright (C) 1996,1997,1998,2001,2003
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
//# Correspondence concerning AIPS++ should be adressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//#
//# $Id: CalHistoryBuffer.h,v 19.4 2004/11/30 17:50:11 ddebonis Exp $

#ifndef CALIBRATION_CALHISTORYBUFFER_H
#define CALIBRATION_CALHISTORYBUFFER_H

#include <calibration/CalTables/CalIterBase.h>
#include <calibration/CalTables/CalTable.h>
#include <calibration/CalTables/CalHistoryColumns.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary> 
// CalHistoryBuffer: Calibration table cal_history buffer
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="" tests="" demos="">

// <prerequisite>
//   <li> <linkto class="CalTable">CalTable</linkto> module
//   <li> <linkto class="CalIterBase">CalIterBase</linkto> module
// </prerequisite>
//
// <etymology>
// From "calibration history sub-table" and "buffer"
// </etymology>
//
// <synopsis>
// The CalHistoryBuffer class holds a buffer for the cal_history
// sub-table, optionally connected to a calibration table 
// iterator (of base type CalIterBase). 
// </synopsis>
//
// <example>
// <srcblock>
// </srcblock>
// </example>
//
// <motivation>
// Encapsulate calibration table cal_history data buffer.
// </motivation>
//
// <todo asof="01/12/26">
// (i) Deal with non-standard columns.
// </todo>

class CalHistoryBuffer 
{
 public:
  // Default constructor. No connection to an underlying
  // calibration table iterator in this case.
  CalHistoryBuffer();

  // Construct from a calibration table iterator. The calibration
  // buffer will remain synchronized with the iterator.
  CalHistoryBuffer (CalIterBase& calIter);

  // Default destructor
  virtual ~CalHistoryBuffer();

  // Invalidate the current calibration buffer. This signals
  // that a re-read is required as the iterator has advanced.
  virtual void invalidate();

  // Write the current buffer at the end of a specified 
  // cal_history table (NYI)
  virtual void append (CalTable& calTable) {};

  // Data field accessors
  Vector<String>& calParms();
  Vector<String>& calTables();
  Vector<String>& calSelect();
  Vector<String>& calNotes();

 protected:
  // Factory method to create a columns accessor object of the appropriate type
  virtual CalHistoryColumns* newCalHistoryCol (CalTable& calTable)
    {return new CalHistoryColumns (calTable);};

  // Access to the columns accessor object
  virtual CalHistoryColumns* calHistCol() {return calHistCol_p;};

  // Is the buffer connected to an underlying iterator ?
  Bool connectedToIter() {return connectedToIter_p;};

 private:
  // True if connected to underlying iterator
  Bool connectedToIter_p;

  // Ptr to cal_history columns accessor
  CalHistoryColumns* calHistCol_p;

  // Buffer fields
  Vector<String> calParms_p;
  Vector<String> calTables_p;
  Vector<String> calSelect_p;
  Vector<String> calNotes_p;

  // Buffer field status flags
  Bool calParmsOK_p;
  Bool calTablesOK_p;
  Bool calSelectOK_p;
  Bool calNotesOK_p;
};


} //# NAMESPACE CASA - END

#endif
   
  



