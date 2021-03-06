//# ExprDerArrayNode.cc: Nodes representing constant arrays in table select expression tree
//# Copyright (C) 1997,1998,1999,2000
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
//# $Id: ExprDerNodeArray.cc,v 19.3 2004/11/30 17:51:01 ddebonis Exp $

#include <tables/Tables/ExprDerNodeArray.h>
#include <tables/Tables/TableError.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Quanta/MVTime.h>


namespace casa { //# NAMESPACE CASA - BEGIN

TableExprNodeArrayConstBool::TableExprNodeArrayConstBool
                                                 (const Array<Bool>& val)
: TableExprNodeArray (NTBool, OtLiteral, val.shape()),
  value_p            (val)
{}
TableExprNodeArrayConstBool::~TableExprNodeArrayConstBool()
{}
Array<Bool> TableExprNodeArrayConstBool::getArrayBool (const TableExprId&)
    { return value_p; }


TableExprNodeArrayConstDouble::TableExprNodeArrayConstDouble
                                                 (const Array<Double>& val)
: TableExprNodeArray (NTDouble, OtLiteral, val.shape()),
  value_p            (val)
{}
TableExprNodeArrayConstDouble::TableExprNodeArrayConstDouble
                                                 (const Array<Float>& val)
: TableExprNodeArray (NTDouble, OtLiteral, val.shape()),
  value_p            (val.shape())
{
    convertArray (value_p, val);
}
TableExprNodeArrayConstDouble::TableExprNodeArrayConstDouble
                                                 (const Array<uInt>& val)
: TableExprNodeArray (NTDouble, OtLiteral, val.shape()),
  value_p            (val.shape())
{
    convertArray (value_p, val);
}
TableExprNodeArrayConstDouble::TableExprNodeArrayConstDouble
                                                 (const Array<Int>& val)
: TableExprNodeArray (NTDouble, OtLiteral, val.shape()),
  value_p            (val.shape())
{
    convertArray (value_p, val);
}
TableExprNodeArrayConstDouble::TableExprNodeArrayConstDouble
                                                 (const Array<uShort>& val)
: TableExprNodeArray (NTDouble, OtLiteral, val.shape()),
  value_p            (val.shape())
{
    convertArray (value_p, val);
}
TableExprNodeArrayConstDouble::TableExprNodeArrayConstDouble
                                                 (const Array<Short>& val)
: TableExprNodeArray (NTDouble, OtLiteral, val.shape()),
  value_p            (val.shape())
{
    convertArray (value_p, val);
}
TableExprNodeArrayConstDouble::TableExprNodeArrayConstDouble
                                                 (const Array<uChar>& val)
: TableExprNodeArray (NTDouble, OtLiteral, val.shape()),
  value_p            (val.shape())
{
    convertArray (value_p, val);
}
TableExprNodeArrayConstDouble::~TableExprNodeArrayConstDouble()
{}
Array<Double> TableExprNodeArrayConstDouble::getArrayDouble
                                                 (const TableExprId&)
    { return value_p; }
Array<DComplex> TableExprNodeArrayConstDouble::getArrayDComplex
                                                 (const TableExprId&)
{
    Array<DComplex> arr(value_p.shape());
    convertArray (arr, value_p);
    return arr;
}

TableExprNodeArrayConstDComplex::TableExprNodeArrayConstDComplex
                                                 (const Array<DComplex>& val)
: TableExprNodeArray (NTComplex, OtLiteral, val.shape()),
  value_p            (val)
{}
TableExprNodeArrayConstDComplex::TableExprNodeArrayConstDComplex
                                                 (const Array<Complex>& val)
: TableExprNodeArray (NTComplex, OtLiteral, val.shape()),
  value_p            (val.shape())
{
    convertArray (value_p, val);
}
TableExprNodeArrayConstDComplex::TableExprNodeArrayConstDComplex
                                                 (const Array<Double>& val)
: TableExprNodeArray (NTComplex, OtLiteral, val.shape()),
  value_p            (val.shape())
{
    convertArray (value_p, val);
}
TableExprNodeArrayConstDComplex::~TableExprNodeArrayConstDComplex()
{}
Array<DComplex> TableExprNodeArrayConstDComplex::getArrayDComplex
                                                 (const TableExprId&)
    { return value_p; }

TableExprNodeArrayConstString::TableExprNodeArrayConstString
                                                 (const Array<String>& val)
: TableExprNodeArray (NTString, OtLiteral, val.shape()),
  value_p            (val)
{}
TableExprNodeArrayConstString::~TableExprNodeArrayConstString()
{}
Array<String> TableExprNodeArrayConstString::getArrayString
                                                 (const TableExprId&)
    { return value_p; }

TableExprNodeArrayConstDate::TableExprNodeArrayConstDate
                                                 (const Array<MVTime>& val)
: TableExprNodeArray (NTDate, OtLiteral, val.shape()),
  value_p            (val)
{}
TableExprNodeArrayConstDate::~TableExprNodeArrayConstDate()
{}
Array<Double> TableExprNodeArrayConstDate::getArrayDouble (const TableExprId&)
{
    Array<Double> arr(value_p.shape());
    convertArray (arr, value_p);
    return arr;
}
Array<MVTime> TableExprNodeArrayConstDate::getArrayDate (const TableExprId&)
    { return value_p; }

} //# NAMESPACE CASA - END

