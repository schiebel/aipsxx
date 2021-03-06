//# EPointTable.h: SolvableVisJones calibration table access and creation
//# Copyright (C) 1996,1997,1998,1999,2001,2003
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
//# $Id: EPointTable.h,v 1.1 2005/05/29 04:20:42 sbhatnag Exp $

#ifndef CALIBRATION_EPOINTTABLE_H
#define CALIBRATION_EPOINTTABLE_H

#include <calibration/CalTables/TimeVarVJTable.h>
#include <calibration/CalTables/SolvableVJTable.h>
#include <calibration/CalTables/EPointDesc.h>
namespace casa {
class EPointTable : public SolvableVisJonesTable
{
 public:
   // Default null constructor, and destructor
   EPointTable();
   virtual ~EPointTable() {};

   // Construct from a specified table name and table access option. 
   // Used for creating new tables or opening existing tables.
   EPointTable (const String& tableName, 
		Table::TableOption access = Table::Old);
   EPointTable (const String& tableName, 
		const String& type,
		Table::TableOption access = Table::Old);

 private:
   EPointDesc itsEPointDesc;
};
}
#endif
