//# pytable.cc: python module for TableProxy object.
//# Copyright (C) 2006
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
//# $Id: pytable.cc,v 1.3 2006/09/26 04:28:23 gvandiep Exp $

#include <tables/Tables/TableProxy.h>
#include <appspython/Converters/PycBasicData.h>
#include <appspython/Converters/PycValueHolder.h>
#include <appspython/Converters/PycRecord.h>
#include <boost/python.hpp>
#include <boost/python/args.hpp>

using namespace boost::python;

namespace casa { namespace appspython {

  void pytable()
  {
    class_<TableProxy> ("Table",
            init<String, Record, int>())
      .def (init<String, Record, String, String, int, Record, Record>())
      .def (init<String, std::vector<TableProxy> >())
      .def (init<String, String, String, Bool, IPosition, String, String ,int, int>())
      .def (init<TableProxy>())

      .def ("flush", &TableProxy::flush,
	    (boost::python::arg("recursive")=false))
      .def ("resync", &TableProxy::resync)
      .def ("_copy", &TableProxy::copy,
 	    (boost::python::arg("newtablename"),
 	     boost::python::arg("memorytable"),
	     boost::python::arg("deep"),
 	     boost::python::arg("valuecopy"),
 	     boost::python::arg("endian"),
 	     boost::python::arg("dminfo"),
 	     boost::python::arg("copynorows")))
      .def ("copyrows", &TableProxy::copyRows,
 	    (boost::python::arg("outtable"),
 	     boost::python::arg("startrowin")=1,
 	     boost::python::arg("startrowout")=-1,
 	     boost::python::arg("nrow")=-1))
      .def ("_selectrows", &TableProxy::selectRows,
 	    (boost::python::arg("rownrs"),
 	     boost::python::arg("name")))
      .def ("iswritable", &TableProxy::isWritable)
      .def ("endianformat", &TableProxy::endianFormat)
      .def ("lock", &TableProxy::lock,
 	    (boost::python::arg("write")=true,
 	     boost::python::arg("nattempts")=0))
      .def ("unlock", &TableProxy::unlock)
      .def ("datachanged", &TableProxy::hasDataChanged)
      .def ("lock", &TableProxy::lock,
 	    (boost::python::arg("write")=true,
 	     boost::python::arg("nattempts")=0))
      .def ("haslock", &TableProxy::hasLock,
 	    (boost::python::arg("write")=true))
      .def ("lockoptions", &TableProxy::lockOptions)
      .def ("ismultiused", &TableProxy::isMultiUsed,
 	    (boost::python::arg("checksubtables")=false))
      .def ("name", &TableProxy::tableName)
      .def ("info", &TableProxy::tableInfo)
      .def ("putinfo", &TableProxy::putTableInfo,
 	    (boost::python::arg("value")))
      .def ("addreadmeline", &TableProxy::addReadmeLine,
 	    (boost::python::arg("value")))
      .def ("setmaxcachesize", &TableProxy::setMaximumCacheSize,
	    (boost::python::arg("columnname"),
	     boost::python::arg("nbytes")))
      .def ("rownumbers", &TableProxy::rowNumbers)
      .def ("colnames", &TableProxy::columnNames)
      .def ("isscalarcol", &TableProxy::isScalarColumn,
	    (boost::python::arg("columnname")))
      .def ("coldatatype", &TableProxy::columnDataType,
	    (boost::python::arg("columnname")))
      .def ("colarraytype", &TableProxy::columnArrayType,
	    (boost::python::arg("columnname")))
      .def ("ncols", &TableProxy::ncolumns)
      .def ("nrows", &TableProxy::nrows)
      .def ("__len__", &TableProxy::nrows)
      .def ("addcols", &TableProxy::addColumns,
	    (boost::python::arg("desc"),
	     boost::python::arg("dminfo")=Record()))
      .def ("renamecol", &TableProxy::renameColumn,
	    (boost::python::arg("oldname"),
	     boost::python::arg("newname")))
      .def ("removecols", &TableProxy::removeColumns,
	    (boost::python::arg("columnnames")))
      .def ("addrows", &TableProxy::addRow,
	    (boost::python::arg("nrows")=1))
      .def ("removerows", &TableProxy::removeRow,
	    (boost::python::arg("rownrs")))
      .def ("iscelldefined", &TableProxy::cellContentsDefined,
	    (boost::python::arg("columnname"),
	     boost::python::arg("rownr")))
      .def ("getcell", &TableProxy::getCell,
	    (boost::python::arg("columnname"),
	     boost::python::arg("rownr")))
      .def ("_getcellslice", &TableProxy::getCellSlice,
	    (boost::python::arg("columnname"),
	     boost::python::arg("rownr"),
	     boost::python::arg("blc"),
	     boost::python::arg("trc"),
	     boost::python::arg("inc")))
      .def ("getcol", &TableProxy::getColumn,
	    (boost::python::arg("columnname"),
	     boost::python::arg("startrow")=0,
	     boost::python::arg("nrow")=-1,
	     boost::python::arg("rowincr")=1))
      .def ("getvarcol", &TableProxy::getVarColumn,
	    (boost::python::arg("columnname"),
	     boost::python::arg("startrow")=0,
	     boost::python::arg("nrow")=-1,
	     boost::python::arg("rowincr")=1))
      .def ("_getcolslice", &TableProxy::getColumnSlice,
	    (boost::python::arg("columnname"),
	     boost::python::arg("blc"),
	     boost::python::arg("trc"),
	     boost::python::arg("inc"),
	     boost::python::arg("startrow"),
	     boost::python::arg("nrow"),
	     boost::python::arg("rowincr")))
      .def ("_putcell", &TableProxy::putCell,
	    (boost::python::arg("columnname"),
	     boost::python::arg("rownr"),
	     boost::python::arg("value")))
      .def ("_putcellslice", &TableProxy::putCellSlice,
	    (boost::python::arg("columnname"),
	     boost::python::arg("rownr"),
	     boost::python::arg("value"),
	     boost::python::arg("blc"),
	     boost::python::arg("trc"),
	     boost::python::arg("inc")))
      .def ("putcol", &TableProxy::putColumn,
	    (boost::python::arg("columnname"),
	     boost::python::arg("value"),
	     boost::python::arg("startrow")=0,
	     boost::python::arg("nrow")=-1,
	     boost::python::arg("rowincr")=1))
      .def ("putvarcol", &TableProxy::putVarColumn,
	    (boost::python::arg("columnname"),
	     boost::python::arg("value"),
	     boost::python::arg("startrow")=0,
	     boost::python::arg("nrow")=-1,
	     boost::python::arg("rowincr")=1))
      .def ("_putcolslice", &TableProxy::putColumnSlice,
	    (boost::python::arg("columnname"),
	     boost::python::arg("value"),
	     boost::python::arg("blc"),
	     boost::python::arg("trc"),
	     boost::python::arg("inc"),
	     boost::python::arg("startrow"),
	     boost::python::arg("nrow"),
	     boost::python::arg("rowincr")))
      .def ("_getcolshapestring", &TableProxy::getColumnShapeString,
	    (boost::python::arg("columnname"),
	     boost::python::arg("startrow"),
	     boost::python::arg("nrow"),
	     boost::python::arg("rowincr"),
	     boost::python::arg("reverseaxes")))
      .def ("_getkeyword", &TableProxy::getKeyword,
	    (boost::python::arg("columnname"),
	     boost::python::arg("keyword"),
	     boost::python::arg("keywordindex")))
      .def ("_getkeywords", &TableProxy::getKeywordSet,
	    (boost::python::arg("columnname")))
      .def ("_putkeyword", &TableProxy::putKeyword,
	    (boost::python::arg("columnname"),
	     boost::python::arg("keyword"),
	     boost::python::arg("keywordindex"),
	     boost::python::arg("makesubrecord"),
	     boost::python::arg("value")))
      .def ("_putkeywords", &TableProxy::putKeywordSet,
	    (boost::python::arg("columnname"),
	     boost::python::arg("value")))
      .def ("_removekeyword", &TableProxy::removeKeyword,
	    (boost::python::arg("columnname"),
	     boost::python::arg("keyword"),
	     boost::python::arg("keywordindex")))
      .def ("_getfieldnames", &TableProxy::getFieldNames,
	    (boost::python::arg("columnname"),
	     boost::python::arg("keyword"),
	     boost::python::arg("keywordindex")))
      .def ("getdminfo", &TableProxy::getDataManagerInfo)
      .def ("getdesc", &TableProxy::getTableDescription,
	    (boost::python::arg("actual")=true,
	     boost::python::arg("_cOrder")=true))
      .def ("getcoldesc", &TableProxy::getColumnDescription,
	    (boost::python::arg("columnname"),
 	     boost::python::arg("actual")=true,
	     boost::python::arg("_cOrder")=true))
      .def ("_getasciiformat", &TableProxy::getAsciiFormat)
      .def ("_getcalcresult", &TableProxy::getCalcResult)
      ;
  }
    
}}
