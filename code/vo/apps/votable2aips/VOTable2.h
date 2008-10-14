//# VOTable2.h: this defines VOTable2, which implements votNodeList and votNodeMap.
//# Copyright (C) 2003
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
//#! ========================================================================
//# $Id: VOTable2.h,v 19.3 2004/11/30 17:51:23 ddebonis Exp $

// <summary>
// VOTable2 implements votNodeList and votNodeMap.
// </summary>

// <use visibility=local>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
// VOTable
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// Nothing in VOTable2 is meant to be directly accessed.
// The XMLChComp class is only defined outside of the VOTable2 file so
// it can be referenced by the AIPS++ "templates" file.
// </synopsis>
//
//
// <thrown>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
// </todo>

#ifndef VO_VOTABLE2_H
#define VO_VOTABLE2_H
#include <vector>
#include <map>
// This file is only needed for the templates.
#include <VOTable.h>

#include <casa/namespace.h>
// This provides the comparision function for use with maps dealing with
// XMLCh strings.
class XMLChComp {
  public:
	bool operator()(const XMLCh *a, const XMLCh *b)const
	{ int islower = XMLString::compareIString(a, b);
		return (islower < 0);
	}
};


#endif
