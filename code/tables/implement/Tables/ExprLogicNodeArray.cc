//# ExprLogicNodeArray.cc: Nodes representing logical array operators in table select expression tree
//# Copyright (C) 1997,1998,1999,2000,2001
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
//# $Id: ExprLogicNodeArray.cc,v 19.3 2004/11/30 17:51:01 ddebonis Exp $

#include <tables/Tables/ExprLogicNodeArray.h>
#include <tables/Tables/TableError.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Quanta/MVTime.h>
#include <casa/Utilities/Regex.h>



namespace casa { //# NAMESPACE CASA - BEGIN

TableExprNodeArrayEQBool::TableExprNodeArrayEQBool
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtEQ)
{}
TableExprNodeArrayEQBool::~TableExprNodeArrayEQBool()
{}
Array<Bool> TableExprNodeArrayEQBool::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayBool (id) == rnode_p->getBool (id);
    case ScaArr:
	return lnode_p->getBool (id) == rnode_p->getArrayBool (id);
    default:
	break;
    }
    return lnode_p->getArrayBool (id) == rnode_p->getArrayBool (id);
}

TableExprNodeArrayEQDouble::TableExprNodeArrayEQDouble
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtEQ)
{}
TableExprNodeArrayEQDouble::~TableExprNodeArrayEQDouble()
{}
Array<Bool> TableExprNodeArrayEQDouble::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayDouble (id) == rnode_p->getDouble (id);
    case ScaArr:
	return lnode_p->getDouble (id) == rnode_p->getArrayDouble (id);
    default:
	break;
    }
    return lnode_p->getArrayDouble (id) == rnode_p->getArrayDouble (id);
}

TableExprNodeArrayEQDComplex::TableExprNodeArrayEQDComplex
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtEQ)
{}
TableExprNodeArrayEQDComplex::~TableExprNodeArrayEQDComplex()
{}
Array<Bool> TableExprNodeArrayEQDComplex::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayDComplex(id) == rnode_p->getDComplex(id);
    case ScaArr:
	return lnode_p->getDComplex(id) == rnode_p->getArrayDComplex(id);
    default:
	break;
    }
    return lnode_p->getArrayDComplex(id) == rnode_p->getArrayDComplex(id);
}

TableExprNodeArrayEQString::TableExprNodeArrayEQString
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtEQ)
{}
TableExprNodeArrayEQString::~TableExprNodeArrayEQString()
{}
Array<Bool> TableExprNodeArrayEQString::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayString (id) == rnode_p->getString (id);
    case ScaArr:
	return lnode_p->getString (id) == rnode_p->getArrayString (id);
    default:
	break;
    }
    return lnode_p->getArrayString (id) == rnode_p->getArrayString (id);
}

TableExprNodeArrayEQRegex::TableExprNodeArrayEQRegex
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtEQ)
{}
TableExprNodeArrayEQRegex::~TableExprNodeArrayEQRegex()
{}
Array<Bool> TableExprNodeArrayEQRegex::getArrayBool (const TableExprId& id)
{
    Bool deleteArr, deleteRes;
    Array<String> left = lnode_p->getArrayString(id);
    const String* arr = left.getStorage (deleteArr);
    Array<Bool> result(left.shape());
    Bool* res = result.getStorage (deleteRes);
    Regex regex = rnode_p->getRegex(id);
    uInt n = left.nelements();
    for (uInt i=0; i<n; i++) {
	res[i] = arr[i].matches(regex)  ?  True : False;
    }
    left.freeStorage (arr, deleteArr);
    result.putStorage (res, deleteRes);
    return result;
}

TableExprNodeArrayEQDate::TableExprNodeArrayEQDate
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtEQ)
{}
TableExprNodeArrayEQDate::~TableExprNodeArrayEQDate()
{}
Array<Bool> TableExprNodeArrayEQDate::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayDate(id) != rnode_p->getDate(id);
    case ScaArr:
	return lnode_p->getDate(id) != rnode_p->getArrayDate(id);
    default:
	break;
    }
    return lnode_p->getArrayDate(id) != rnode_p->getArrayDate(id);
}


TableExprNodeArrayNEBool::TableExprNodeArrayNEBool
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtNE)
{}
TableExprNodeArrayNEBool::~TableExprNodeArrayNEBool()
{}
Array<Bool> TableExprNodeArrayNEBool::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayBool (id) != rnode_p->getBool (id);
    case ScaArr:
	return lnode_p->getBool (id) != rnode_p->getArrayBool (id);
    default:
	break;
    }
    return lnode_p->getArrayBool (id) != rnode_p->getArrayBool (id);
}

TableExprNodeArrayNEDouble::TableExprNodeArrayNEDouble
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtNE)
{}
TableExprNodeArrayNEDouble::~TableExprNodeArrayNEDouble()
{}
Array<Bool> TableExprNodeArrayNEDouble::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayDouble (id) != rnode_p->getDouble (id);
    case ScaArr:
	return lnode_p->getDouble (id) != rnode_p->getArrayDouble (id);
    default:
	break;
    }
    return lnode_p->getArrayDouble (id) != rnode_p->getArrayDouble (id);
}

TableExprNodeArrayNEDComplex::TableExprNodeArrayNEDComplex
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtNE)
{}
TableExprNodeArrayNEDComplex::~TableExprNodeArrayNEDComplex()
{}
Array<Bool> TableExprNodeArrayNEDComplex::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayDComplex(id) != rnode_p->getDComplex(id);
    case ScaArr:
	return lnode_p->getDComplex(id) != rnode_p->getArrayDComplex(id);
    default:
	break;
    }
    return lnode_p->getArrayDComplex(id) != rnode_p->getArrayDComplex(id);
}

TableExprNodeArrayNEString::TableExprNodeArrayNEString
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtNE)
{}
TableExprNodeArrayNEString::~TableExprNodeArrayNEString()
{}
Array<Bool> TableExprNodeArrayNEString::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayString (id) != rnode_p->getString (id);
    case ScaArr:
	return lnode_p->getString (id) != rnode_p->getArrayString (id);
    default:
	break;
    }
    return lnode_p->getArrayString (id) != rnode_p->getArrayString (id);
}

TableExprNodeArrayNERegex::TableExprNodeArrayNERegex
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtNE)
{}
TableExprNodeArrayNERegex::~TableExprNodeArrayNERegex()
{}
Array<Bool> TableExprNodeArrayNERegex::getArrayBool (const TableExprId& id)
{
    Bool deleteArr, deleteRes;
    Array<String> left = lnode_p->getArrayString(id);
    const String* arr = left.getStorage (deleteArr);
    Array<Bool> result(left.shape());
    Bool* res = result.getStorage (deleteRes);
    Regex regex = rnode_p->getRegex(id);
    uInt n = left.nelements();
    for (uInt i=0; i<n; i++) {
	res[i] = arr[i].matches(regex)  ?  False : True;
    }
    left.freeStorage (arr, deleteArr);
    result.putStorage (res, deleteRes);
    return result;
}

TableExprNodeArrayNEDate::TableExprNodeArrayNEDate
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtNE)
{}
TableExprNodeArrayNEDate::~TableExprNodeArrayNEDate()
{}
Array<Bool> TableExprNodeArrayNEDate::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayDate(id) != rnode_p->getDate(id);
    case ScaArr:
	return lnode_p->getDate(id) != rnode_p->getArrayDate(id);
    default:
	break;
    }
    return lnode_p->getArrayDate(id) != rnode_p->getArrayDate(id);
}


TableExprNodeArrayGTDouble::TableExprNodeArrayGTDouble
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtGT)
{}
TableExprNodeArrayGTDouble::~TableExprNodeArrayGTDouble()
{}
Array<Bool> TableExprNodeArrayGTDouble::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayDouble(id) > rnode_p->getDouble(id);
    case ScaArr:
	return lnode_p->getDouble(id) > rnode_p->getArrayDouble(id);
    default:
	break;
    }
    return lnode_p->getArrayDouble(id) > rnode_p->getArrayDouble(id);
}

TableExprNodeArrayGTDComplex::TableExprNodeArrayGTDComplex
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtGT)
{}
TableExprNodeArrayGTDComplex::~TableExprNodeArrayGTDComplex()
{}
Array<Bool> TableExprNodeArrayGTDComplex::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayDComplex(id) > rnode_p->getDComplex(id);
    case ScaArr:
	return lnode_p->getDComplex(id) > rnode_p->getArrayDComplex(id);
    default:
	break;
    }
    return lnode_p->getArrayDComplex(id) > rnode_p->getArrayDComplex(id);
}

TableExprNodeArrayGTString::TableExprNodeArrayGTString
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtGT)
{}
TableExprNodeArrayGTString::~TableExprNodeArrayGTString()
{}
Array<Bool> TableExprNodeArrayGTString::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayString(id) > rnode_p->getString(id);
    case ScaArr:
	return lnode_p->getString(id) > rnode_p->getArrayString(id);
    default:
	break;
    }
    return lnode_p->getArrayString(id) > rnode_p->getArrayString(id);
}

TableExprNodeArrayGTDate::TableExprNodeArrayGTDate
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtGT)
{}
TableExprNodeArrayGTDate::~TableExprNodeArrayGTDate()
{}
Array<Bool> TableExprNodeArrayGTDate::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayDate(id) > rnode_p->getDate(id);
    case ScaArr:
	return lnode_p->getDate(id) > rnode_p->getArrayDate(id);
    default:
	break;
    }
    return lnode_p->getArrayDate(id) > rnode_p->getArrayDate(id);
}


TableExprNodeArrayGEDouble::TableExprNodeArrayGEDouble
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtGE)
{}
TableExprNodeArrayGEDouble::~TableExprNodeArrayGEDouble()
{}
Array<Bool> TableExprNodeArrayGEDouble::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayDouble(id) >= rnode_p->getDouble(id);
    case ScaArr:
	return lnode_p->getDouble(id) >= rnode_p->getArrayDouble(id);
    default:
	break;
    }
    return lnode_p->getArrayDouble(id) >= rnode_p->getArrayDouble(id);
}

TableExprNodeArrayGEDComplex::TableExprNodeArrayGEDComplex
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtGE)
{}
TableExprNodeArrayGEDComplex::~TableExprNodeArrayGEDComplex()
{}
Array<Bool> TableExprNodeArrayGEDComplex::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayDComplex(id) >= rnode_p->getDComplex(id);
    case ScaArr:
	return lnode_p->getDComplex(id) >= rnode_p->getArrayDComplex(id);
    default:
	break;
    }
    return lnode_p->getArrayDComplex(id) >= rnode_p->getArrayDComplex(id);
}

TableExprNodeArrayGEString::TableExprNodeArrayGEString
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtGE)
{}
TableExprNodeArrayGEString::~TableExprNodeArrayGEString()
{}
Array<Bool> TableExprNodeArrayGEString::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayString(id) >= rnode_p->getString(id);
    case ScaArr:
	return lnode_p->getString(id) >= rnode_p->getArrayString(id);
    default:
	break;
    }
    return lnode_p->getArrayString(id) >= rnode_p->getArrayString(id);
}

TableExprNodeArrayGEDate::TableExprNodeArrayGEDate
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtGE)
{}
TableExprNodeArrayGEDate::~TableExprNodeArrayGEDate()
{}
Array<Bool> TableExprNodeArrayGEDate::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayDate(id) >= rnode_p->getDate(id);
    case ScaArr:
	return lnode_p->getDate(id) >= rnode_p->getArrayDate(id);
    default:
	break;
    }
    return lnode_p->getArrayDate(id) >= rnode_p->getArrayDate(id);
}


TableExprNodeArrayINDouble::TableExprNodeArrayINDouble
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtIN)
{}
TableExprNodeArrayINDouble::~TableExprNodeArrayINDouble()
{}
Array<Bool> TableExprNodeArrayINDouble::getArrayBool (const TableExprId& id)
{
    return rnode_p->hasArrayDouble (id, lnode_p->getArrayDouble (id));
}

TableExprNodeArrayINDComplex::TableExprNodeArrayINDComplex
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtIN)
{}
TableExprNodeArrayINDComplex::~TableExprNodeArrayINDComplex()
{}
Array<Bool> TableExprNodeArrayINDComplex::getArrayBool (const TableExprId& id)
{
    return rnode_p->hasArrayDComplex (id, lnode_p->getArrayDComplex (id));
}

TableExprNodeArrayINString::TableExprNodeArrayINString
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtIN)
{}
TableExprNodeArrayINString::~TableExprNodeArrayINString()
{}
Array<Bool> TableExprNodeArrayINString::getArrayBool (const TableExprId& id)
{
    return rnode_p->hasArrayString (id, lnode_p->getArrayString (id));
}

TableExprNodeArrayINDate::TableExprNodeArrayINDate
                                            (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtIN)
{}
TableExprNodeArrayINDate::~TableExprNodeArrayINDate()
{}
Array<Bool> TableExprNodeArrayINDate::getArrayBool (const TableExprId& id)
{
    return rnode_p->hasArrayDate (id, lnode_p->getArrayDate (id));
}



TableExprNodeArrayOR::TableExprNodeArrayOR (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtOR)
{}
TableExprNodeArrayOR::~TableExprNodeArrayOR()
{}
Array<Bool> TableExprNodeArrayOR::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayBool(id) || rnode_p->getBool(id);
    case ScaArr:
	return lnode_p->getBool(id) || rnode_p->getArrayBool(id);
    default:
	break;
    }
    return lnode_p->getArrayBool(id) || rnode_p->getArrayBool(id);
}


TableExprNodeArrayAND::TableExprNodeArrayAND (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtAND)
{}
TableExprNodeArrayAND::~TableExprNodeArrayAND()
{}
Array<Bool> TableExprNodeArrayAND::getArrayBool (const TableExprId& id)
{
    switch (argtype_p) {
    case ArrSca:
	return lnode_p->getArrayBool(id) && rnode_p->getBool(id);
    case ScaArr:
	return lnode_p->getBool(id) && rnode_p->getArrayBool(id);
    default:
	break;
    }
    return lnode_p->getArrayBool(id) && rnode_p->getArrayBool(id);
}


TableExprNodeArrayNOT::TableExprNodeArrayNOT (const TableExprNodeRep& node)
: TableExprNodeArray (node, NTBool, OtNOT)
{}
TableExprNodeArrayNOT::~TableExprNodeArrayNOT()
{}
Array<Bool> TableExprNodeArrayNOT::getArrayBool (const TableExprId& id)
{
    return !(lnode_p->getArrayBool(id));
}

} //# NAMESPACE CASA - END

