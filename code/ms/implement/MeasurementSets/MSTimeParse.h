//# MSTimeParse.h: Classes to hold results from time grammar parser
//# Copyright (C) 1994,1995,1997,1998,1999,2000,2001,2003
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
//# $Id: MSTimeParse.h,v 19.15 2006/04/07 15:29:52 sbhatnag Exp $

#ifndef MS_MSTIMEPARSE_H
#define MS_MSTIMEPARSE_H

//# Includes
#include <ms/MeasurementSets/MSParse.h>
#include <measures/Measures/MEpoch.h>
// #include <synthesis/MeasurementComponents/Utils.h>
// #include <msvis/MSVis/VisibilityIterator.h>
// #include <msvis/MSVis/VisBuffer.h>
// #include <msvis/MSVis/VisSet.h>
#include <ms/MeasurementSets/MSTimeDefinitions.h>
#include <casa/Containers/Block.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Forward Declarations

// <summary>
// Class to hold values from time grammar parser
// </summary>

// <use visibility=local>

// <reviewed reviewer="" date="" tests="">
// </reviewed>

// <prerequisite>
//# Classes you should understand before using this one.
// </prerequisite>

// <etymology>
// MSTimeParse is the class used to parse a time command.
// </etymology>

// <synopsis>
// MSTimeParse is used by the parser of time sub-expression statements.
// The parser is written in Bison and Flex in files MSTimeGram.y and .l.
// The statements in there use the routines in this file to act
// upon a reduced rule.
// Since multiple tables can be given (with a shorthand), the table
// names are stored in a list. The variable names can be qualified
// by the table name and will be looked up in the appropriate table.
//
// The class MSTimeParse only contains information about a table
// used in the table command. Global variables (like a list and a vector)
// are used in MSTimeParse.cc to hold further information.
//
// Global functions are used to operate on the information.
// The main function is the global function msTimeCommand.
// It executes the given STaQL command and returns the resulting ms.
// This is, in fact, the only function to be used by a user.
// </synopsis>

// <motivation>
// It is necessary to be able to give a ms command in ASCII.
// This can be used in a CLI or in the table browser to get a subset
// of a table or to sort a table.
// </motivation>

//# <todo asof="$DATE:$">
//# A List of bugs, limitations, extensions or planned refinements.
//# </todo>


class MSTimeParse : public MSParse
{

public:
  // Default constructor
  MSTimeParse ();

  // Associate the ms and the shorthand.
  MSTimeParse (const MeasurementSet* ms);

  const TableExprNode *selectTime(const MEpoch& time,
				  bool daytime = false);
  const TableExprNode *selectTimeGT(const MEpoch& lowboundTime,
				    bool daytime = false);
  const TableExprNode *selectTimeLT(const MEpoch& upboundTime,
				    bool daytime = false);
  const TableExprNode *selectTimeRange(const MEpoch& lowboundTime, 
				       const MEpoch& upboundTime,
				       bool daytime = false);
  const TableExprNode *addCondition(TableExprNode& condition);

  /*
  static const MEpoch *dayTimeConvert(Int day=-1, Int hour = -1,
				      Int minute = -1, Int second = -1,
				      Int millisec = -1);
  */

  static void setDefaults(TimeFields& tf, Bool dataOrigin=True);
  static void copyDefaults(TimeFields& target, TimeFields& source);
  static const MEpoch *yearTimeConvert(Int year=-1, Int month=-1, Int day=-1,
				       Int hour = -1, Int minute = -1,
				       Int second = -1, Int millisec = -1);
  static const MEpoch *yearTimeConvert(const TimeFields& tf);

  // Get table expression node object.
  static const TableExprNode* node();

  const Int year0() {return defaultYear;};
  const Int month0() {return defaultMonth;};
  const Int day0() {return defaultDay;};
  const Int hour0() {return defaultHour;};
  const Int minute0() {return defaultMinute;};
  const Int second0() {return defaultSeconds;};
  const Int fractionalsec0() {return defaultFractionalSec;};
  const Double defaultInteg() {return defaultExposure;};

  static const void validate(const TimeFields& tf);
  static TableExprNode* node_p;
  //private:
  static const Double toTAIInSec(const MEpoch& time);
  static MEpoch* yeartime;
  static MEpoch* daytime;
  Int defaultYear, defaultMonth, defaultDay,
    defaultHour, defaultMinute, defaultSeconds, defaultFractionalSec;
  Double defaultExposure;
  const String colName;

};

} //# NAMESPACE CASA - END

#endif
