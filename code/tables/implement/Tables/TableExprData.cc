//# TableExprData.cc: Abstract base class for data object in a TaQL expression
//# Copyright (C) 2000
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
//# $Id: TableExprData.cc,v 19.3 2004/11/30 17:51:08 ddebonis Exp $


#include <tables/Tables/TableExprData.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Exceptions/Error.h>


namespace casa { //# NAMESPACE CASA - BEGIN

TableExprData::~TableExprData()
{}

IPosition TableExprData::shape (const Block<Int>&) const
{
  return IPosition();
}

Bool     TableExprData::getBool     (const Block<Int>&) const
{
  throw (AipsError ("TableExprData::getBool not implemented"));
}

Double   TableExprData::getDouble   (const Block<Int>&) const
{
  throw (AipsError ("TableExprData::getDouble not implemented"));
}

DComplex TableExprData::getDComplex (const Block<Int>& fieldNrs) const
{
  return getDouble (fieldNrs);
}

String   TableExprData::getString   (const Block<Int>&) const
{
  throw (AipsError ("TableExprData::getString not implemented"));
}

Array<Bool>     TableExprData::getArrayBool     (const Block<Int>&) const
{
  throw (AipsError ("TableExprData::getArrayBool not implemented"));
}

Array<Double>   TableExprData::getArrayDouble   (const Block<Int>&) const
{
  throw (AipsError ("TableExprData::getArrayDouble not implemented"));
}

Array<DComplex> TableExprData::getArrayDComplex
                                            (const Block<Int>& fieldNrs) const
{
  Array<Double> tmp = getArrayDouble (fieldNrs);
  Array<DComplex> result(tmp.shape());
  convertArray (result, tmp);
  return result;
}

Array<String>   TableExprData::getArrayString   (const Block<Int>&) const
{
  throw (AipsError ("TableExprData::getArrayString not implemented"));
}

} //# NAMESPACE CASA - END

