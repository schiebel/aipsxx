//# GBTMSTypeSampFiller.h: used to fill the GBT_type_SAMPLER table
//# Copyright (C) 2000,2001,2002,2003
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
//# $Id: GBTMSTypeRecFiller.cc,v 19.1 2004/08/25 05:49:29 gvandiep Exp $

//# Includes

#include <nrao/GBTFillers/GBTMSTypeRecFiller.h>
#include <nrao/GBTFillers/GBTBackendFiller.h>

#include <casa/Containers/Record.h>
#include <casa/Exceptions/Error.h>
#include <tables/Tables/ArrColDesc.h>
#include <tables/Tables/ColumnsIndex.h>
#include <tables/Tables/ScaColDesc.h>
#include <tables/Tables/SetupNewTab.h>
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/TableRow.h>
#include <casa/Utilities/Assert.h>

GBTMSTypeSampFiller::GBTMSTypeSampFiller(const String &tableName) 
    : tab_p(0), tabRow_p(0), index_p(0), type_p("unknown")
{
    // extract the type name
    Int ndelim = tableName.freq("_");
    if (ndelim > 1) {
	String *fields = new String[ndelim+1];
	split(tableName, fields, (ndelim+1), "_");
	type_p = fields[ndelim];
        delete [] fields;
    }
    tab_p = new Table(tableName, GBTBackendFiller::tableLock(), 
    		      Table::Update);
    AlwaysAssert(tab_p, AipsError);
    updateTableRow();
    updateIndex();
    
}

GBTMSTypeSampFiller::GBTMSTypeSampFiller(Table &attachTable, const String &type)
    : tab_p(0), tabRow_p(0), index_p(0), type_p(type)
{
    // make a very bare bones table
    String tableName = "GBT_" + type + "_SAMPLER";
    SetupNewTable newtab(attachTable.tableName()+"/"+tableName, 
			 TableDesc(), Table::New);
    tab_p = new Table(newtab, GBTBackendFiller::tableLock());
    AlwaysAssert(tab_p, AipsError);
    attachTable.rwKeywordSet().defineTable(tableName, *tab_p);
    updateTableRow();
    updateIndex();
}

void GBTMSTypeSampFiller::fill(const Table &other)
{
    sampIds_p.resize(other.nrow());
    if (other.nrow() == 0) return;
	
    ROTableRow inTabRow(other, handledCols_p, True);
    checkRecord(inTabRow.get(0));

    for (uInt i=0; i< other.nrow(); i++) {
	Bool addIt = False;
	if (!index_p) {
	    addIt = True;
	} else {
	    Vector<uInt> rownrs = index_p->getRowNumbers(inTabRow.get(i));
	    if (rownrs.nelements() == 0) {
		addIt = True;
	    } else {
		// use the last one found
		sampIds_p(i) = rownrs(rownrs.nelements()-1);
	    }
	}
	if (addIt) {
	    sampIds_p(i) = tab_p->nrow();
	    tab_p->addRow(1);
	    tabRow_p->putMatchingFields((tab_p->nrow()-1), inTabRow.get(i));
	}
    }
}

void GBTMSTypeSampFiller::handleColumn(const String &colname)
{
    uInt newElem = handledCols_p.nelements();
    handledCols_p.resize(newElem+1, True);
    handledCols_p(newElem) = colname;
}

void GBTMSTypeSampFiller::checkRecord(const Record &other)
{
    Bool colsAdded = False;
    for (uInt i=0; i<other.nfields(); i++) {
	String name(other.name(i));
	if (!tab_p->tableDesc().isColumn(name)) {
	    colsAdded = True;
	    IPosition shape(other.shape(i));
	    String comment(other.comment(i));
	    switch (other.type(i)) {
	    case TpBool:
		tab_p->addColumn(ScalarColumnDesc<Bool>(name, comment), 
				 "IncrementalStMan", False);
		break;					      
	    case TpChar:				      
		tab_p->addColumn(ScalarColumnDesc<Char>(name, comment), 
				 "IncrementalStMan", False);
		break;					      
	    case TpUChar:				      
		tab_p->addColumn(ScalarColumnDesc<uChar>(name, comment), 
				 "IncrementalStMan", False);
		break;					      
	    case TpShort:				      
		tab_p->addColumn(ScalarColumnDesc<Short>(name, comment), 
				 "IncrementalStMan", False);
		break;					      
	    case TpUShort:				      
		tab_p->addColumn(ScalarColumnDesc<uShort>(name, comment), 
				 "IncrementalStMan", False);
		break;					      
	    case TpInt:					      
		tab_p->addColumn(ScalarColumnDesc<Int>(name, comment), 
				 "IncrementalStMan", False);
		break;					      
	    case TpUInt:				      
		tab_p->addColumn(ScalarColumnDesc<uInt>(name, comment), 
				 "IncrementalStMan", False);
		break;					      
	    case TpFloat:				      
		tab_p->addColumn(ScalarColumnDesc<Float>(name, comment), 
				 "IncrementalStMan", False);
		break;					      
	    case TpDouble:				      
		tab_p->addColumn(ScalarColumnDesc<Double>(name, comment), 
				 "IncrementalStMan", False);
		break;					      
	    case TpComplex:				      
		tab_p->addColumn(ScalarColumnDesc<Complex>(name, comment), 
				 "IncrementalStMan", False);
		break;					      
	    case TpDComplex:				      
		tab_p->addColumn(ScalarColumnDesc<DComplex>(name, comment), 
				 "IncrementalStMan", False);
		break;					      
	    case TpString:				      
		tab_p->addColumn(ScalarColumnDesc<String>(name, comment), 
				 "IncrementalStMan", False);
		break;
	    case TpArrayBool:
		tab_p->addColumn(ArrayColumnDesc<Bool>(name, comment), 
				 "IncrementalStMan", False);
		break;
	    case TpArrayChar:
		tab_p->addColumn(ArrayColumnDesc<Char>(name, comment), 
				 "IncrementalStMan", False);
		break;
	    case TpArrayUChar:
		tab_p->addColumn(ArrayColumnDesc<uChar>(name, comment), 
				 "IncrementalStMan", False);
		break;
	    case TpArrayShort:
		tab_p->addColumn(ArrayColumnDesc<Short>(name, comment), 
				 "IncrementalStMan", False);
		break;
	    case TpArrayUShort:
		tab_p->addColumn(ArrayColumnDesc<uShort>(name, comment), 
				 "IncrementalStMan", False);
		break;
	    case TpArrayInt:
		tab_p->addColumn(ArrayColumnDesc<Int>(name, comment), 
				 "IncrementalStMan", False);
		break;
	    case TpArrayUInt:
		tab_p->addColumn(ArrayColumnDesc<uInt>(name, comment), 
				 "IncrementalStMan", False);
		break;
	    case TpArrayFloat:
		tab_p->addColumn(ArrayColumnDesc<Float>(name, comment), 
				 "IncrementalStMan", False);
		break;
	    case TpArrayDouble:
		tab_p->addColumn(ArrayColumnDesc<Double>(name, comment), 
				 "IncrementalStMan", False);
		break;
	    case TpArrayComplex:
		tab_p->addColumn(ArrayColumnDesc<Complex>(name, comment), 
				 "IncrementalStMan", False);
		break;
	    case TpArrayDComplex:
		tab_p->addColumn(ArrayColumnDesc<DComplex>(name, comment), 
				 "IncrementalStMan", False);
		break;
	    case TpArrayString:
		tab_p->addColumn(ArrayColumnDesc<String>(name, comment), 
				 "IncrementalStMan", False);
		break;
	    default:
		// ignore these
		break;
	    }
	}
    }
    if (colsAdded) {
	updateTableRow();
	updateIndex();
    }
}


void GBTMSTypeSampFiller::updateTableRow()
{
    delete tabRow_p;
    tabRow_p = 0;
    tabRow_p = new TableRow(*tab_p);
    AlwaysAssert(tabRow_p, AipsError);
}

void GBTMSTypeSampFiller::updateIndex() {
    // all columns are in the index, don't do the index if any columns are non-scalar
    Vector<String> colNames = tab_p->tableDesc().columnNames();
    Bool okToIndex = True;
    for (uInt i=0;i<colNames.nelements();i++) {
	if (!tab_p->tableDesc().columnDesc(i).isScalar()) {
	    okToIndex = False;
	    break;
	}
    }
    delete index_p;
    index_p = 0;
    if (okToIndex) {
	index_p = new ColumnsIndex(*tab_p, colNames);
	AlwaysAssert(index_p, AipsError);
    }
}

GBTMSTypeSampFiller::~GBTMSTypeSampFiller() {
    delete tabRow_p;
    tabRow_p = 0;
    delete index_p;
    index_p = 0;
    delete tab_p;
    tab_p = 0;
}

