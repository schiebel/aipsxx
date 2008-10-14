//# GBTFillerState.h: this is what does all of the work of GBTFiller
//# Copyright (C) 1995,1996,1999,2001
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
//# $Id: GBTFillerState.h,v 19.4 2004/11/30 17:50:40 ddebonis Exp $

#ifndef NRAO_GBTFILLERSTATE_H
#define NRAO_GBTFILLERSTATE_H

#include <casa/aips.h>

#include <GBTFillerInputs.h>

#include <casa/Containers/Block.h>
#include <tasking/Glish.h>
#include <casa/OS/Time.h>
#include <casa/BasicSL/String.h>

#include <casa/namespace.h>

//# Forward Declarations
namespace casa { //# NAMESPACE CASA - BEGIN
class FITSMultiTable;
class FITSTimedTable;
class CopyRecordToTable;
class Table;
class TableDesc;

template <class T> class ROScalarColumn;
template <class T> class RORecordFieldPtr;
} //# NAMESPACE CASA - END



// <summary>
// GBTFillerState holds the state of the gbtfiller application.  It does all the work.
// </summary>

// <use visibility=local> 

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> Everything
//   <li> Or nothing
//   <li> You choose.
// </prerequisite>
//
// <etymology>
// Eww, bugs!  Oh, that's not what eymology means.  ...  oh ...
// nevermind.
// </etymology>
//
// <synopsis>
// I wish I knew.
// </synopsis>
//
// <example>
// Yeah, right.
// </example>
//
// <motivation>
// None.
// </motivation>
//
// <thrown>
//    <li>
//    <li>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
//   <li> add this feature
//   <li> fix this bug
//   <li> start discussion of this possible extension
// </todo>

class GBTFillerState
{
public:

    GBTFillerState(int argc, char ** argv);
    GBTFillerState(GlishValue record, GlishSysEventSource *eventStream);

    ~GBTFillerState();

    const GBTFillerInputs &inputs() const { return inputs_;}

    void update();

    // fillit always fills to the end of the indicated time range or
    // the end of the file, whichever comes first

    void fillit();

    // endOfTimeRange returns True if the fill has extended to the end
    // of the specified time range
    Bool endOfTimeRange() const {return endOfTimeRange_;}

    // change the name of the output table, close the current table, if opened,
    // and begin filling to indicated output table on next call to fillit()

    Bool changeOutputTable(const String& tabName);
    
private:

    // state at end of last fillit()
    Bool endOfTimeRange_;
    // Glish stream
    GlishSysEventSource *stream_p;

    GBTFillerInputs inputs_;

    // the files required to deal the specific backend
    FITSMultiTable *backTab_p;
    FITSTimedTable *timedBackTab_p;
    CopyRecordToTable *backCopier_p;
    Time lastBackTime_;

    // the files required to deal with the DAP
    // the number of different DAP types
    uInt ndap_;

    // A FITSMultiTable and a FITSTimedTable for each DAP type
    PtrBlock<FITSMultiTable *> dapTabs_;
    PtrBlock<FITSTimedTable *> timedDapTabs_;
    // base name for each DAP file
    Block<String> baseDapNames_;
    // a copier for each DAP type
    PtrBlock<CopyRecordToTable *> dapCopiers_;

    // output table
    Table *outTable_p;

    // counter for number of output table
    Int tableCounter_;

    // Time column
    ROScalarColumn<Double> *timeCol_p;
    // SCAN field
    RORecordFieldPtr<Int> *scanField_p;
    // OBJECT field
    RORecordFieldPtr<String> *objectField_p;

    // Inaccessible and unavailable
    GBTFillerState();
    GBTFillerState(const GBTFillerState &other);
    GBTFillerState& operator=(const GBTFillerState &other);

    // resize all the DAP blocks to 2x larger than current size and at least
    // minSize elements
    void setDAPSize(uInt minSize);

    // find anything in td not in outTable_p and add it in
    // make sure everything there is of the correct type
    void mergeTableDesc(const TableDesc& td);

    // create outTable_p as appropriate
    void setOutTable();

    // return an appropriate table name for this state
    String makeTableName();

    // set outTable_p appropriate for this state from scratch
    void buildTable(const String &tableName, const TableDesc &td);
};

#endif


