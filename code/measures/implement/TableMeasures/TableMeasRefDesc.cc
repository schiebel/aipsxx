//# TableMeasRefDef.cc: Definition of a MeasRef in a Table.
//# Copyright (C) 1997,1999,2000,2001
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
//# $Id: TableMeasRefDesc.cc,v 19.3 2004/11/30 17:50:35 ddebonis Exp $


//# Includes
#include <measures/TableMeasures/TableMeasRefDesc.h>
#include <measures/TableMeasures/TableMeasDescBase.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/TableRecord.h>
#include <casa/Exceptions/Error.h>


namespace casa { //# NAMESPACE CASA - BEGIN

TableMeasRefDesc::TableMeasRefDesc (uInt referenceCode)
: itsRefCode(referenceCode),
  itsOffset (0)
{}

TableMeasRefDesc::TableMeasRefDesc (uInt referenceCode, 
				    const TableMeasOffsetDesc& offset)
: itsRefCode(referenceCode),
  itsOffset (new TableMeasOffsetDesc(offset))
{}

TableMeasRefDesc::TableMeasRefDesc (const TableDesc &td, const String& column)
: itsRefCode(0),
  itsColumn (column),
  itsOffset (0)
{
  checkColumn (td);
}

TableMeasRefDesc::TableMeasRefDesc (const TableDesc &td, const String& column,
				    const TableMeasOffsetDesc& offset)
: itsRefCode(0),
  itsColumn (column),
  itsOffset (new TableMeasOffsetDesc(offset))
{
  checkColumn (td);
}

TableMeasRefDesc::TableMeasRefDesc (const TableMeasRefDesc& that)
: itsOffset(0)
{
  operator= (that);
}
    
TableMeasRefDesc& TableMeasRefDesc::operator= (const TableMeasRefDesc& that)
{
  if (this != &that) {
    delete itsOffset;
    itsRefCode = that.itsRefCode;
    itsColumn  = that.itsColumn;
    itsOffset  = that.itsOffset;
    if (itsOffset != 0) {
      itsOffset = new TableMeasOffsetDesc(*itsOffset);
    }
  }
  return *this;
}

TableMeasRefDesc::~TableMeasRefDesc()
{
  delete itsOffset;
}

TableMeasRefDesc::TableMeasRefDesc (const TableRecord& measInfo,
				    const Table& tab,
				    const TableMeasDescBase& mDesc)
: itsRefCode(0),
  itsOffset (0)
{
  Int fnr;
  fnr = measInfo.fieldNumber("Ref");
  if (fnr >= 0) {
    itsRefCode = mDesc.refCode (measInfo.asString(fnr));
  }
  fnr = measInfo.fieldNumber("VarRefCol");
  if (fnr >= 0) {
    itsColumn = measInfo.asString(fnr);
  }
  itsOffset = TableMeasOffsetDesc::reconstruct (measInfo, "RefOff", tab);
}

void TableMeasRefDesc::write (TableDesc& td, TableRecord& measInfo, 
			      const TableMeasDescBase& measDesc)
{
  writeKeys (measInfo, measDesc);
  if (itsOffset != 0) {
    itsOffset->write (td, measInfo, "RefOff");
  }
}

void TableMeasRefDesc::write (Table& tab, TableRecord& measInfo, 
			      const TableMeasDescBase& measDesc)
{
  writeKeys (measInfo, measDesc);
  if (itsOffset != 0) {
    itsOffset->write (tab, measInfo, "RefOff");
  }
}

void TableMeasRefDesc::writeKeys (TableRecord& measInfo, 
				  const TableMeasDescBase& measDesc)
{
  if (isRefCodeVariable()) {
    measInfo.define ("VarRefCol", itsColumn);
  } else {
    measInfo.define ("Ref", measDesc.refType (itsRefCode));
  } 
}

void TableMeasRefDesc::checkColumn (const TableDesc& td) const
{
  if (! td.isColumn(itsColumn)) {
    throw (AipsError ("TableMeasRefDesc::checkColumn; No such column: "
		      + itsColumn));
  } else if ((td.columnDesc(itsColumn).dataType() != TpInt) &&
	     (td.columnDesc(itsColumn).dataType() != TpString)) {
    throw (AipsError ("TableMeasRefDesc::checkColumn; Reference column's "
		      "type must be Int or String: " + itsColumn));
  }
}

void TableMeasRefDesc::resetRefCode (uInt refCode)
{
  if (isRefCodeVariable()) {
    throw (AipsError ("tableMeasRefDesc::resetRefCode cannot be done;"
		      "the refcode is not fixed for the entire column"));
  }
  itsRefCode = refCode;
}

void TableMeasRefDesc::resetOffset (const Measure& offset)
{
  if (itsOffset == 0) {
    itsOffset = new TableMeasOffsetDesc (offset);
  } else {
    itsOffset->resetOffset (offset);
  }
    if (isOffsetVariable()) {
      throw (AipsError ("tableMeasRefDesc::resetOffset cannot be done;"
			"the offset is not fixed for the entire column"));
    }
}

} //# NAMESPACE CASA - END

