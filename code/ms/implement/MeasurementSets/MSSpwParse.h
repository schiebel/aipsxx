//# MSSpwParse.h: Classes to hold results from spw grammar parser
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
//# $Id: MSSpwParse.h,v 1.7 2006/09/28 07:11:06 sbhatnag Exp $

#ifndef MS_MSSPWPARSE_H
#define MS_MSSPWPARSE_H

//# Includes
#include <ms/MeasurementSets/MSParse.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Forward Declarations


// <summary>
// Class to hold values from field grammar parser
// </summary>

// <use visibility=local>

// <reviewed reviewer="" date="" tests="">
// </reviewed>

// <prerequisite>
//# Classes you should understand before using this one.
// </prerequisite>

// <etymology>
// MSSpwParse is the class used to parse a spectral window selection command.
// </etymology>

// <synopsis> MSSpwParse is used by the parser of spectral window
// (Spw) sub-expression statements.  The parser is written in Bison
// and Flex in files MSSpwGram.y and .l.  The statements in there use
// the routines in this file to act upon a reduced rule.  Since
// multiple tables can be given (with a shorthand), the table names
// are stored in a list. The variable names can be qualified by the
// table name and will be looked up in the appropriate table.
//
// The class MSSpwParse only contains information about a table
// used in the table command. Global variables (like a list and a vector)
// are used in MSSpwParse.cc to hold further information.
//
// Global functions are used to operate on the information.
// The main function is the global function msSpwCommand.
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


class MSSpwParse : public MSParse
{
public:
  // Default constructor
  MSSpwParse ();

  // Associate the ms and the shorthand.
  MSSpwParse (const MeasurementSet* ms);

  const TableExprNode *selectSpwIdsFromIDList(const Vector<Int>& fieldIds);
  const TableExprNode *selectSpwIdsFromFreqList(const Vector<Float>& fieldIds,
						const Float factor);
  //    const TableExprNode *selectSpwOrSource(const String& fieldName);

  // Get table expression node object.
  static const TableExprNode* node();
  static MSSpwParse* thisMSSParser;

private:
  static TableExprNode* node_p;
};

} //# NAMESPACE CASA - END

#endif
