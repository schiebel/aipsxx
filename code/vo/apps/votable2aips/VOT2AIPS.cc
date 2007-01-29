//# VOT2AIPS.cc:  this defines VOT2AIPS which makes an AIPS++ table from a VOTable tree.
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
//# $Id: VOT2AIPS.cc,v 19.4 2004/11/30 17:51:23 ddebonis Exp $
// Convert a VOTable tree to an AIPS++ table.

// TODO:
//  Error handling should be improved.

// If there is an unknown datatype, it is ignored, but the column's data will
// be used to fill the next column!

// Uses Xerces V2.2.
#include <stdio.h>
#include <casa/iostream.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <VOT2AIPS.h>

#include <casa/Arrays/IPosition.h>
#include <tables/Tables/SubTabDesc.h>
#include <tables/Tables/ScaRecordColData.h>
#include <casa/complex.h>
#include <casa/BasicSL/String.h>
#include <casa/Utilities/Regex.h>
#include <casa/Inputs.h>

#include <xercesc/dom/DOM.hpp>
#include <xercesc/util/PlatformUtils.hpp>
#include <xercesc/dom/DOM.hpp>
#include <xercesc/parsers/XercesDOMParser.hpp>
#include <casa/namespace.h>
using namespace xercesc;


// V2A version
// These should be ints since as of  9/9/02 tablebrowser or recordbrowser
// or ?? barfs on uInts.
static const Int V2AVERSION_MAJOR = 0;
static const Int V2AVERSION_MINOR = 4;

////////////////////////////////////////////////////////////////
/// Error logging help.
// Print error message when an AIPS++ error gets thrown. Argument is string
// giving name of current routine.
#define WARNINGSTRING(whr)  __FILE__ << ":" << __LINE__ << " " << whr << ": "

// Define if it's desired to write to cout rather than logio.
//#define V2A_DEBUG

#if defined(V2A_DEBUG)
#define	errorlog	cerr
#define AERR(whr, err) {errorlog << WARNINGSTRING(whr) << err.getMesg() << endl;}

#else

#include <casa/Logging/LogIO.h>
static LogIO errorlog;
#define AERR(whr, err) {errorlog << LogIO::SEVERE << WARNINGSTRING(whr) \
				 << err.getMesg() << LogIO::POST;}
#endif
////////////////////////////////////////////////////////////////

VOT2AIPS::VOT2AIPS()
{
  init();
}

VOT2AIPS::~VOT2AIPS()
{
#if 0
  // Don't need to delete since they're just pointers inside a tree.
  delete gtable_;
  delete firstTable_;
  delete firstvotTable_;
#endif
  init();
}

void VOT2AIPS::init()
{
  gtable_ = 0;
  firstTable_ = 0;
  firstvotTable_ = 0;
}

////////////////////////////////////////////////////////////////////////
// Utility routines to add various types of things to a TableRecord.
////////////////////////////////////////////////////////////////////////

// Add a keyword if it isn't empty. If force is true, add the keyword
// even if it isn't empty.
// NOTE: addKW is very similar to defineRecordValue below. The difference
// is that addKW will normally only add non empty keywords.
bool VOT2AIPS::addKW(TableRecord &rec, const char *kw, const String &value,
		     bool force)
{ bool added=false;

	if((value != "") || force)
	{	rec.define(kw, value);
		added=true;
	}
	return added;
}

// Add values to TableRecords.
void VOT2AIPS::defineRecordValue(TableRecord &rec, const String &name,
				 const String &value)
{ RecordFieldId rfid(name);
	rec.define(rfid, value);
}

// Don't use uInt.
void VOT2AIPS::defineRecordValue(TableRecord &rec, const String &name,
				 const Int value)
{ RecordFieldId rfid(name);
	rec.define(rfid, value);
}

void VOT2AIPS::defineRecordValue(TableRecord &rec, const String &name,
				 const TableRecord &value)
{ RecordFieldId rfid(name);
	rec.defineRecord(rfid, value);
}

// Add a table to a TableRecord.
void VOT2AIPS::defineRecordTable(TableRecord &rec, const String &name,
				 const Table &value)
{ RecordFieldId rfid(name);
	rec.defineTable(rfid, value);
}

// Debugging routine. Prints r's field names to cerr.
// If str is non 0, it's printed first.
void VOT2AIPS::pfields(const TableRecord &r, const char *str)
{
	if(str != 0)
	{	cerr << str << "  ";
	}
	cerr << "[";
	for(uInt i=0; i < r.nfields(); i++)
		cerr << " " << r.name(i);
	cerr << "]\n";
}

// Create an attributes record and populate it with node's attributes.
// The record is attached to the parent as "attributes".
bool VOT2AIPS::addAttributes(TableRecord &rec, votAttributeNode *node)
{
	if(node == 0)
		return false;

	votAttributeList *attrs = node->getAttributes();
	if(attrs == 0)
		return 0;

	uInt num = attrs->numAttributes();
	if(num == 0)
	{	delete attrs;
		return false;
	}

	TableRecord attr;
	for(uInt i=0; i < num; i++)
	{ string name, value;
		attrs->getAttribute(i, name, value);
		defineRecordValue(attr, name, value);
	}

	defineRecordValue(rec, "attributes", attr);

	delete attrs;
	return true;
}

////////////////////////////////////////////////////////////////////////
// Bunches of routines to add VOTABLE parts to table records.
////////////////////////////////////////////////////////////////////////

// Note:
//  A lot of these functions return true if they add a piece of data to
// a record. The first version of the software used the result to decide
// whether there was any data. The current version generally ignores this
// and writes table records even if they may be empty.

// Create a record containing a description. The reason for a separate
// record is that the tablebrowser may not show a long description otherwise.
bool VOT2AIPS::addDescription(TableRecord &rec, votDescription *node)
{ bool added = false;
  TableRecord desc;

	if(node == 0)
		return false;
	String description;
	node->getDescription(description);
#if 1
	added = addKW(desc, "DESCRIPTION", description);
//	added = addKW(desc, "", description);
	defineRecordValue(rec, "DESCRIPTION", desc);
#else
	added = addKW(rec, "DESCRIPTION", description);
#endif
	return added;
}

// Create a record, add COOSYS info to it then attach the record to the
// parent. coosysnum is used to create a name. If it's < 0, then the COOSYS
// is not part of a list and doesn't need a unique name.
bool VOT2AIPS::addCOOSYS(Int coosysnum, TableRecord &rec, votCOOSYS *node)
{bool added=false;
 String name;

	if(node==0)
		return false;
	String id, equinox, epoch, system;

	TableRecord coosys;


#if 0
	node->getID(id);
	node->getEquinox(equinox);
	node->getEpoch(epoch);
	node->getSystem(system);
	added |= addKW(coosys, "ID", id);
	added |= addKW(coosys, "equinox", equinox);
	added |= addKW(coosys, "epoch", epoch);
	added |= addKW(coosys, "system", system);
#endif
	added |= addAttributes(coosys, node);

	if(added)
	{	if(coosysnum < 0)
			name = "COOSYS";
		else
		{ char coname[32];
			sprintf(coname, "COOSYS:%02d", coosysnum);
			name = coname;
		}
		RecordFieldId rfid(name);
		rec.defineRecord(rfid, coosys);
	}
	//	pfields(rec, "addCOOSYS");
	return added;
}

bool VOT2AIPS::addCOOSYSList(TableRecord &rec, votCOOSYSList *list)
{bool added=false;

	if(list==0)
		return false;

	TableRecord coosyslist;
	uInt nelems = list->getLength();
	for( uInt i=0; i<nelems; i++)
	{ votCOOSYS *coosys = list->item(i);
		added |= addCOOSYS(i, coosyslist, coosys);
	}
	if(added)
	{ RecordFieldId rfid("COOSYSLIST");
		rec.defineRecord(rfid, coosyslist);
	}
	return added;
}

bool VOT2AIPS::addLink(uInt count, TableRecord &rec, votLink *node)
{bool added=false;
// String id, content_role, content_type, title, value, href, gref, action;

	if(node==0)
		return false;

	TableRecord link;

#if 0
	node->getID(id);
	node->getContent_role(content_role);
	node->getContent_type(content_type);
	node->getTitle(title);
	node->getValue(value);
	node->getHref(href);
	node->getGref(gref);
	node->getAction(action);
	added |= addKW(link, "ID", id);
	added |= addKW(link, "content_role", content_role);
	added |= addKW(link, "content_type", content_type);
	added |= addKW(link, "title", title);
	added |= addKW(link, "value", value);
	added |= addKW(link, "href", href);
	added |= addKW(link, "gref", gref);
	added |= addKW(link, "action", action);
#else
	added |= addAttributes(link, node);
#endif

	if(added)
	{ char linkn[32];
		sprintf(linkn, "LINK:%02d", count);
		defineRecordValue(rec, linkn, link);
	}
	return added;
}

bool VOT2AIPS::addLinkList(TableRecord &rec, votLinkList *list)
{bool added=false;

	if(list==0)
		return false;

	TableRecord linklist;
	uInt nelems = list->getLength();
	for( uInt i=0; i<nelems; i++)
	{ votLink *link = list->item(i);
		added |= addLink(i, linklist, link);
	}
	if(added)
	{ RecordFieldId rfid("LINKS");
		rec.defineRecord(rfid, linklist);
	}
	return added;
}

// Add a MIN or MAX record.
bool VOT2AIPS::addMinMax(TableRecord &rec, votMinMaxNode *node, const char *type)
{ bool added=false;
  String value, inclusive;
  TableRecord minmax;

	if(node == 0)
		return false;

#if 0
	node->getValue(value);
	node->getInclusive(inclusive);
	added |= addKW(minmax, "value", value);
	added |= addKW(minmax, "inclusive", inclusive);
#else
	added = addAttributes(minmax, node);
#endif

	if(added)
	{ RecordFieldId rfid(type);
		rec.defineRecord(rfid, minmax);
	}
	return added;
}

bool VOT2AIPS::addOPTION(uInt vnum, TableRecord &rec, votOption *node)
{ bool added=false;
  TableRecord option;

	added |= addAttributes(option, node);

	if(added)
	{char buf[32];
	 String oname;
		sprintf(buf, "OPTION:%02d", vnum);
		oname = buf;
		defineRecordValue(rec, oname, option);
	}

	return added;
}

bool VOT2AIPS::addOPTIONList(TableRecord &rec, votOptionList *list)
{ TableRecord options;
  uInt nelems;
  bool added;

	if((list == 0) || ((nelems = list->getLength())==0))
		return false;

	for(uInt i=0; i< nelems; i++)
	{ votOption *option = list->item(i);
		added |= addOPTION(i, options, option);
	}

	if(added)
	{ RecordFieldId rfid("OPTIONS");
		rec.defineRecord(rfid, options);
	}
	return added;
}



bool VOT2AIPS::addValues(uInt vnum, TableRecord &rec, votValues *node)
{ String id, type, Null, invalid, vname;
  bool added=false;
  TableRecord value;

#if 0
	node->getID(id);
	node->getType(type);
	node->getNull(Null);
	node->getInvalid(invalid);
	added |= addKW(value, "ID", id);
	added |= addKW(value, "type", type);
	added |= addKW(value, "null", Null);
	added |= addKW(value, "invalid", invalid);
#else
	added |= addMinMax(value, node->min(), "MIN");
	added |= addMinMax(value, node->max(), "MAX");
	added |= addOPTIONList(value, node->optionList());
	added |= addAttributes(value, node);
#endif

	if(added)
	{char buf[32];
		sprintf(buf, "VALUE:%02d", vnum);
		vname = buf;
		defineRecordValue(rec, vname, value);
	}

	return added;
}

bool VOT2AIPS::addValuesList(TableRecord &rec, votValuesList *list)
{ TableRecord values;
  uInt nelems;
  bool added;

	if((list == 0) || ((nelems = list->getLength())==0))
		return false;

	for(uInt i=0; i< nelems; i++)
	{ votValues *value = list->item(i);
		added |= addValues(i, values, value);
	}

	if(added)
	{ RecordFieldId rfid("VALUES");
		rec.defineRecord(rfid, values);
	}
	return added;
}

// Add a votField's info directly into the record.
// Called by addParam and handleField.
bool VOT2AIPS::addFieldKWs(TableRecord &field, votField *node)
{bool added=false;

	if(node==0)
		return false;

#if 0
	String id, unit;
	String datatype, arraysize, precision, width, ref, name, ucd, type;

	node->getID(id);
	node->getUnit(unit);
	node->getDatatype(datatype);
	node->getArraySize(arraysize);
	node->getPrecision(precision);
	node->getWidth(width);
	node->getRef(ref);
	node->getName(name);
	node->getUCD(ucd);
	node->getType(type);

	added |= addKW(field, "ID", id);
	added |= addKW(field, "unit", unit);
	added |= addKW(field, "datatype", datatype, true);
	added |= addKW(field, "arraysize", arraysize, true);
	added |= addKW(field, "precision", precision);
	added |= addKW(field, "width", width);
	added |= addKW(field, "ref", ref);
	added |= addKW(field, "name", name);
	added |= addKW(field, "ucd", ucd);
	added |= addKW(field, "type", type);
#endif
	added |= addDescription(field, node->description());
	added |= addValuesList(field, node->valuesList());
	added |= addLinkList(field, node->linkList());

	added |= addAttributes(field, node);
	return added;
}

bool VOT2AIPS::addParam(Int nparam, TableRecord &rec, votParam *node)
{bool added=false;

	if(node==0)
		return false;
	TableRecord field;
	added = addFieldKWs(field, node);

	String value;
	node->getValue(value);
	added |= addKW(field, "value", value);
	if(added)
	 if( nparam < 0)	// Don't add '%d' if it's not part of a list.
		defineRecordValue(rec, "PARAM", field);
	 else
	 { char buf[32];
		sprintf(buf, "PARAM:%02d", nparam);
		defineRecordValue(rec, buf, field);
	 }

	return added;
}

bool VOT2AIPS::addParamList(TableRecord &rec, votParamList *node)
{	if(node == 0)
		return false;
	bool added = false;
	TableRecord param;
	
	{ uInt nelems = node->getLength();
		for(uInt i=0; i< nelems; i++)
		{ votParam *pnode = node->item(i);
			added |= addParam(i, param, pnode);
		}
	}

	if(added)
		defineRecordValue(rec, "PARAM", param);

	return added;
}

bool VOT2AIPS::addDefinition(uInt defnum, TableRecord &rec, votDefinition *node)
{	if(node == 0)
		return false;
	bool added = false;
	TableRecord def;

	votCOOSYS *coosys = node->coosys();
	votParam *param = node->param();
	added |= addCOOSYS(-1, def, coosys);
	added |= addParam(-1, def, param);
	if(added)
	{ char buf[32];
		sprintf(buf, "DEFINITION:%02d", defnum);
		defineRecordValue(rec, buf, def);
	}
	return added;
}

bool VOT2AIPS::addDefinitionsList(TableRecord &rec, votDefinitionsList *node)
{	if(node == 0)
		return false;
	bool added = false;
	TableRecord def;
	
	{ uInt nelems = node->getLength();
		for(uInt i=0; i< nelems; i++)
		{ votDefinition *defnode = node->item(i);
			added |= addDefinition(i, def, defnode);
		}
	}

	if(added)
	{ RecordFieldId rfid("DEFINITIONS");
		rec.defineRecord(rfid, def);
	}
	return added;
}

bool VOT2AIPS::addInfo(uInt infoNum, TableRecord &rec, votInfo *node)
{	if(node == 0)
		return false;
	bool added = false;
	TableRecord info;

#if 0
	String id, name, value;
	node->getID(id);
	node->getName(name);
	node->getValue(value);
	added |= addKW(info, "ID", id);
	added |= addKW(info, "name", name);
	added |= addKW(info, "value", value);

	if(added)
	{ char buf[32];
		sprintf(buf, "INFO:%02d", infoNum);
		RecordFieldId rfid(buf);
		rec.defineRecord(rfid, info);
	}
#else
	added = addAttributes(info, node);
	if(added)
	{ char buf[32];
		sprintf(buf, "INFO:%02d", infoNum);
		RecordFieldId rfid(buf);
		rec.defineRecord(rfid, info);
	}
#endif
	return added;
}

bool VOT2AIPS::addInfoList(TableRecord &rec, votInfoList *node)
{	if(node == 0)
		return false;
	bool added = false;
	TableRecord info;
	
	{ uInt nelems = node->getLength();
		for(uInt i=0; i< nelems; i++)
		{ votInfo *infonode = node->item(i);
			added |= addInfo(i, info, infonode);
		}
	}

	if(added)
	{ RecordFieldId rfid("INFO");
		rec.defineRecord(rfid, info);
	}
	return added;
}

////////////////////////////////////////////////////////////////

// Adds field information to the table description.
void VOT2AIPS::handleField(uInt fieldNum, votField *field, TableDesc &td)
{
  votDescription *desc = field->description();
  //  votValuesList *valueslist = field->valuesList();
  const XMLCh *XMLdatatype = field->datatype();
  VOTable::PRIMITIVE dt = votNode::getPrimitiveID(XMLdatatype);
  String colName, comment, datatype, arraysize;
  bool haveArray = false;

	// Don't use 'name' for column name since it isn't guaranteed
	// to be unique.
	field->getID(colName);
	// If there is no ID field, create a name.
	if(colName == "")
	{ char buf[32];
		sprintf(buf, "FIELD:%02d", fieldNum);
		colName = buf;
	}

	field->getDatatype(datatype);
	field->getArraySize(arraysize);
	if(arraysize != "")
		haveArray = true;

	if(desc)
		desc->getDescription(comment);

	BaseColumnDesc *bcd=0;

	// Create the appropriate column description.
	switch(dt) {
	case VOTable::CHAR:	// Always a String.
		{	bcd = new ScalarColumnDesc<String>(colName, comment);
		}
		break;
	case VOTable::UNSIGNEDBYTE:	// Always a String.
		{	if(haveArray)
			  bcd = new ArrayColumnDesc<uChar>(colName, comment);
			else
			  bcd = new ScalarColumnDesc<uChar>(colName, comment);
		}
		break;
	case VOTable::SHORT:
		{	if(haveArray)
			  bcd = new ArrayColumnDesc<short>(colName, comment);
			else
			  bcd = new ScalarColumnDesc<short>(colName, comment);
		}
		break;
	case VOTable::INT:
		{	if(haveArray)
			   bcd = new ArrayColumnDesc<int>(colName, comment);
			else
			   bcd = new ScalarColumnDesc<int>(colName, comment);
		}
		break;

// This doesn't work. There isn't a prebuilt version and 2.95.3 gives an
// internal error with the 'templates' file.
// #define DO_LONG
#if defined(DO_LONG)
	case VOTable::LONG:
		{	if(haveArray)
			   bcd = new ArrayColumnDesc<long>(colName, comment);
			else
			   bcd = new ScalarColumnDesc<long>(colName, comment);
		}
		break;
#endif
	case VOTable::FLOAT:
		{	if(haveArray)
			  bcd = new ArrayColumnDesc<float>(colName, comment);
			else
			  bcd = new ScalarColumnDesc<float>(colName, comment);
		}
		break;
	case VOTable::DOUBLE:
		{	if(haveArray)
			 bcd = new ArrayColumnDesc<double>(colName, comment);
			else
			 bcd = new ScalarColumnDesc<double>(colName, comment);
		}
		break;
	case VOTable::BOOLEAN:
		{	if(haveArray)
			  bcd = new ArrayColumnDesc<bool>(colName, comment);
			else
			  bcd = new ScalarColumnDesc<bool>(colName, comment);
		}
		break;
	case VOTable::FLOATCOMPLEX:
		{	if(haveArray)
			  bcd = new ArrayColumnDesc<Complex>(colName, comment);
			else
			  bcd = new ScalarColumnDesc<Complex>(colName, comment);
		}
		break;
	case VOTable::DOUBLECOMPLEX:
		{	if(haveArray)
			  bcd = new ArrayColumnDesc<DComplex>(colName, comment);
			else
			  bcd = new ScalarColumnDesc<DComplex>(colName, comment);
		}
		break;
	default:
		errorlog << WARNINGSTRING("handleField") << endl;
		errorlog << "Unknown primitive type " << datatype << endl;
		break;
	}

	// Add keywords to the column description and add description to table.
	if(bcd != 0)
	{ TableRecord &kw = bcd->rwKeywordSet();
		addFieldKWs(kw, field);
		td.addColumn(*bcd);
		delete bcd;
	}
}

////////////////////////////////////////////////////////////////
/// Keep out of class for now.

static const char SEP='x';
// Break apart an arraysize string
static void tokinize(String arraysize, IPosition &dims, const char sep=SEP)
{ uInt nchars = arraysize.length();
  Int nentries = arraysize.freq(sep);

	if((nchars == 0) || (arraysize == ""))
	{	dims.resize(0);
		return;
	}

	nentries += 1;		// Allow for a trailing value.
	String sarray[nentries];

	int nelems = split(arraysize, sarray, nentries, sep);
	dims.resize(nelems);

	for(Int i=0; i< nelems; i++)
	{ const String &sentry = sarray[i].chars();
		if((i==(nelems-1))&&(sentry == "*"))
			dims(i) = -1;		// Flag as '*'.
		else
			dims(i) = (int)strtol(sentry.chars(), 0, 0);
	}
}
////////////////////////////////////////////////////////////////


// Add data for a column.
void VOT2AIPS::addColumnData(Table &tab, uInt colnum, votTRList *trlist)
{ const TableDesc &tdesc = tab.tableDesc();
  const ColumnDesc &cd = tdesc.columnDesc(colnum);
  const TableRecord &kw = cd.keywordSet();
  String datatype, arraysize;
  votNode::PRIMITIVE dtid;
  uInt numRows = trlist->getLength();
  const String colName = cd.name();
  IPosition dims;

#if 0
	try {
		kw.get("arraysize", arraysize);
		kw.get("datatype", datatype);
	}
	catch (const AipsError &err)
	{	AERR("addColumnData", err);
		throw;
	}
#else
	try { const TableRecord attr = kw.asRecord("attributes");
		if(attr.fieldNumber("arraysize") >= 0)
			attr.get("arraysize", arraysize);
		else
			arraysize = "";

		if(attr.fieldNumber("datatype") >= 0)
			attr.get("datatype", datatype);
		else
			datatype = "";
	}
	catch (const AipsError &err)
	{	AERR("addColumnData", err);
		throw;
	}
#endif

	// See if this column contains arrays;
	tokinize(arraysize, dims);
	int ndims = dims.nelements();

	// Treat as an array if the number of dimensions is > 1
	// or the value of the first entry isn't 1. (-1 or > 1).
	// A value of -1 in the last slot means variable.
	bool haveArray = ((ndims > 1) || ((ndims==1)&&(dims(0)) != 1));
	uInt lastI = ndims-1;		// Index of last dimension.
	Int div = dims.product();	// < 0 if variable array.
	bool haveVariableArray=false;
	if(div < 0)
	{	haveVariableArray = true;
		div = -div;
	}

	dtid = VOTable::getPrimitiveID(datatype.chars());

	try {
	switch(dtid) {
	case VOTable::CHAR:
		// Char is always treated as a string (array of chars).
		{ ScalarColumn<String> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  String v;
				td->getString(v);
				col.put(i,v);
			}
		}
		break;
	case VOTable::UNSIGNEDBYTE:
		if(haveArray)
		{ ArrayColumn<uChar> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  uInt nelems;
			  uChar *storage = td->getuByteArray(nelems);
				if(haveVariableArray)
					dims(lastI) = nelems/div;
				Array<uChar>data(dims, storage, TAKE_OVER);
				col.put(i, data);
			}
		}
		else
		{ ScalarColumn<uChar> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  uChar v;
				td->getuByte(v);
				col.put(i,v);
			}
		}
		break;
	case VOTable::SHORT:
		if(haveArray)
		{ ArrayColumn<Short> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  uInt nelems;
			  Short *storage = td->getShortArray(nelems);
				if(haveVariableArray)
					dims(lastI) = nelems/div;
				Array<Short>data(dims, storage, TAKE_OVER);
				col.put(i, data);
			}
		}
		else
		{ ScalarColumn<Short> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  Short v;
				td->getShort(v);
				col.put(i,v);
			}
		}
		break;
	case VOTable::INT:
		if(haveArray)
		{ ArrayColumn<Int> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  uInt nelems;
			  Int *storage = td->getIntArray(nelems);
				if(haveVariableArray)
					dims(lastI) = nelems/div;
				Array<Int>data(dims, storage, TAKE_OVER);
				col.put(i, data);
			}
		}
		else
		{ ScalarColumn<Int> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  Int v;
				td->getInt(v);
				col.put(i,v);
			}
		}
		break;
#if defined(DO_LONG)
	case VOTable::LONG:
		if(haveArray)
		{ ArrayColumn<Long> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  uInt nelems;
			  Long *storage = td->getLongArray(nelems);
				if(haveVariableArray)
					dims(lastI) = nelems/div;
				Array<Long>data(dims, storage, TAKE_OVER);
				col.put(i, data);
			}
		}
		else
		{ ScalarColumn<Long> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  Long v;
				td->getLong(v);
				col.put(i,v);
			}
		}
		break;
#endif
	case VOTable::FLOAT:
		if(haveArray)
		{ ArrayColumn<Float> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  uInt nelems;
			  Float *storage = td->getFloatArray(nelems);
				if(haveVariableArray)
					dims(lastI) = nelems/div;
				Array<Float>data(dims, storage, TAKE_OVER);
				col.put(i, data);
			}
		}
		else
		{ ScalarColumn<Float> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  Float v;
				td->getFloat(v);
				col.put(i,v);
			}
		}
		break;
	case VOTable::DOUBLE:
		if(haveArray)
		{ ArrayColumn<Double> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  uInt nelems;
			  Double *storage = td->getDoubleArray(nelems);
				if(haveVariableArray)
					dims(lastI) = nelems/div;
				Array<Double>data(dims, storage, TAKE_OVER);
				col.put(i, data);
			}
		}
		else
		{ ScalarColumn<Double> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  Double v;
				td->getDouble(v);
				col.put(i,v);
			}
		}
		break;
	case VOTable::BOOLEAN:
		if(haveArray)
		{ ArrayColumn<bool> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  uInt nelems;
			  bool *storage = td->getBoolArray(nelems);
				if(haveVariableArray)
					dims(lastI) = nelems/div;
				Array<bool>data(dims, storage, TAKE_OVER);
				col.put(i, data);
			}
		}
		else
		{ ScalarColumn<bool> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  bool v;
				td->getBool(v);
				col.put(i,v);
			}
		}
		break;
	case VOTable::FLOATCOMPLEX:
		if(haveArray)
		{ ArrayColumn<Complex> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  uInt nelems;
			  Complex *storage = td->getComplexArray(nelems);
				if(haveVariableArray)
					dims(lastI) = nelems/div;
				Array<Complex>data(dims, storage, TAKE_OVER);
				col.put(i, data);
			}
		}
		else
		{ ScalarColumn<Complex> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  Complex v;
				td->getComplex(v);
				col.put(i,v);
			}
		}
		break;
	case VOTable::DOUBLECOMPLEX:
		if(haveArray)
		{ ArrayColumn<DComplex> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  uInt nelems;
			  DComplex *storage = td->getDoubleComplexArray(nelems);
				if(haveVariableArray)
					dims(lastI) = nelems/div;
				Array<DComplex>data(dims, storage, TAKE_OVER);
				col.put(i, data);
			}
		}
		else
		{ ScalarColumn<DComplex> col(tab, colName);
			for(uInt i=0; i<numRows; i++)
			{ votTR *tr = trlist->item(i);
			  votTDList *tdl = tr->tdList();
			  votTD *td = tdl->item(colnum);
			  DComplex v;
				td->getDoubleComplex(v);
				col.put(i,v);
			}
		}
		break;
	default:
		errorlog << WARNINGSTRING("addColumnData") << endl;
		errorlog << "Unknown primitive type " << datatype << endl;
		break;
	}
	}
	catch (const AipsError &err)
	{	AERR("addColumnData", err);
		throw;
	}
}

// Add column descriptors and keywords.
uInt VOT2AIPS::createTableColumns(TableDesc &td, votTable *tbl)
{ votFieldList *fields = tbl->fieldList();
  uInt nfields = fields->getLength();
  votData *data = tbl->data();
  bool added = false;

	if(data == 0)
		return 0;
  votTableData *tbldta = data->tableData();
	if(tbldta == 0)
		return 0;

	{  String comment, id, name, ref;
	   votDescription *desc = tbl->description();
	   TableRecord &kw = td.rwKeywordSet();

		if(desc != 0)
		{	desc->getDescription(comment);
			td.comment() = comment;
		}

		tbl->getID(id);
		tbl->getName(name);
		tbl->getRef(ref);
	
		added |= addKW(kw, "ID", id);
		added |= addKW(kw, "name", name);
		added |= addKW(kw, "ref", name);
	}

	// Add a column descriptor for each field.
	for(uInt i=0; i< nfields; i++)
	{votField *field = fields->item(i);
		handleField(i, field, td);
	}
	return nfields;
}

// Given pointers to an AIPS++ table and a votTable, fill the AIPS++
// table. aipstbl must have its columns correctly setup.
// Returns true if any data were copied, else false.
bool VOT2AIPS::fillTable(Table *aipstbl, votTable *votbl)
{
	if((aipstbl == 0) || (votbl == 0))
		return false;

	votData *data = votbl->data();
	if(data == 0)
		return false;

	votTableData *tbldta = data->tableData();
	if(tbldta == 0)
		return false;

	votTRList *rowList = tbldta->rowList();
	if(rowList == 0)
		return false;

	// Write columns of data.
	const TableDesc& td = aipstbl->tableDesc();
	uInt ncolumns = td.ncolumn();
	for(uInt i=0; i<ncolumns; i++)
		addColumnData(*aipstbl, i, rowList);
	// Table gets written when aipstbl is destroyed.
	return (ncolumns > 0);
}

// Create the table from the descriptor and add data.
Table *VOT2AIPS::createTable(const String &tablename,
			     TableDesc &td, votTable *tbl)
{  votData *data = tbl->data();

	if(data == 0)
		return 0;
   votTableData *tbldta = data->tableData();
	if(tbldta == 0)
		return 0;

   votTRList *rowList = tbldta->rowList();
   uInt nrows = rowList->getLength();

	// Create table, then add columns of data.
	SetupNewTable newtab(tablename, td, Table::New);
	Table *tab = new Table(newtab, nrows);
	if(tab != 0)
	{	fillTable(tab, tbl);
		// Make sure data gets written.
		tab->flush(true);
	}
	return tab;
}

bool VOT2AIPS::addTableKeywords(TableRecord &kw, votTable *node)
{ String id, name, ref;
  bool added = false;

	if(node == 0)
		return false;

	added |= addDescription(kw, node->description());
	added |= addLinkList(kw, node->linkList());
#if 0
	node->getID(id);
	node->getName(name);
	node->getRef(ref);

	added |= addKW(kw, "ID", id);
	added |= addKW(kw, "name", name);
	added |= addKW(kw, "ref", ref);
#else
	addAttributes(kw, node);
#endif
	return added;
}

// Update main table's rows with info from a new table.
void VOT2AIPS::updateMainTable(const String name, const String id,
			       Table &atable)
{
	// If gtable_ is NULL, it probably means we're handling a "SIMPLE"
	// table.
	if(gtable_ == 0)
		return;

	ScalarColumn<String> namecol(*gtable_, "name");
	ScalarColumn<String> idcol(*gtable_, "ID");
	ScalarColumn<TableRecord> tblcol(*gtable_, "Table");

	  // Create a new row for this table's info.
	  uInt rownum = gtable_->nrow();
		gtable_->addRow(1);

	// Add name and ID.
	namecol.put(rownum,name);
	idcol.put(rownum, id);

	// And a reference to the table itself.
	TableRecord tr;
	defineRecordTable(tr, name, atable);
	tblcol.put(rownum, tr);
}

// Create an AIPS++ table with the given name using the votTable node.
// If the name includes subdirectories, they should already exist.
// Returns a pointer to the Table object.
//
// Create a table descriptor
// Add keywords.
// Create table columns.
// Create & populate the table.
Table *VOT2AIPS::createAIPSTable(const String &tableName, votTable *node)
{ Table *aipstable = 0;

	if(node == 0)
		return 0;

	try {TableDesc td("", "1", TableDesc::Scratch);
	     TableRecord &kw = td.rwKeywordSet();

		addTableKeywords(kw, node);	// Add keywords.
		createTableColumns(td, node);	// then columns.
		aipstable = createTable(tableName, td, node); // Then the tbl.
	    } catch (AipsError &aerr)
	{	AERR("createAIPSTable", aerr);
		throw;
	}

	return aipstable;
}

// Create an AIPS++ table given a pointer to a voTable node.
// On return tableName, is set to the name of the table which isn't
// necessarily the same as the name the table was created with.
// Besides no path info, the name will be from the ID attribute if it
// exists.
//
// (move count to table name and have caller supply it??)
Table *VOT2AIPS::addAIPSTable(uInt count, const String &rpath,
			      String &tableName, votTable *node)
{// bool added = false;
  TableRecord vot;
  String path;
  String tablename, id, name;
  Table *aipstable = 0;

	if(node == 0)
		return 0;

	node->getName(name);
	node->getID(id);

	// Create a default table name and use it with the pathname.
	// Then, possibly, use a different name for internal use.
	{ char buf[32];
		sprintf(buf, "TABLE:%02d", count);
		tablename = buf;
	}

	// Where to put table.
	if(rpath != "")
		path = rpath + "/" + tablename;
	else
		path = tablename;

	// More special case handling for "SIMPLE" tables. If this is set,
	// the table already exists. Just return the main table and its name.
	if( node == firstvotTable_)
	{	tableName = firstTable_->tableName();
		return firstTable_;
	}

	// What to call it internally.
	// Don't use name since it isn't guaranteed to be unique.
	if(id != "")
		tablename = id;

	aipstable = createAIPSTable(path, node);
	if(aipstable != 0)
	{	// Update main table's rows.
		updateMainTable(name, id, *aipstable);
		tableName = tablename;
	}

	return aipstable;
}

uInt VOT2AIPS::addAIPSTables(const String &rpath, TableRecord &parent,
			     votTableList *list)
{ uInt added=0, nelems=0;
  String path = rpath;
  TableRecord rec;

	if((list != 0) && ((nelems = list->getLength())>0))
	{	// Create place to put Tables.
		path += "/TABLES";
		mkdir(path.chars(), 0755);

		for(uInt i=0; i< nelems; i++)
		{ votTable *vtbl = list->item(i);
		  Table *atbl;
		  String tblname;

			if( (atbl=addAIPSTable(i, path, tblname, vtbl)) != 0)
			{	added += 1;
				defineRecordTable(rec, tblname, *atbl);
				// Special handling for "SIMPLE" case. If this
				// isn't the upper table, delete it so it gets
				// written out (and properly closed).
				if(atbl != firstTable_)
					delete atbl;
			}
		}
	}

	defineRecordValue(parent, "TABLES", rec);
	return added;
}

// Process a Resource. Create a record then add the resource's information
// to it. Then attach the record to the parent. resnum is used to
// make a unique (for the parent resource) name.
// A subdirectory of the parent's RESOURCES directory is created.
bool VOT2AIPS::addResource(uInt resnum, const String rpath,
			   TableRecord &parent,	votResource *node)
{ TableRecord res;
  String id;
  String resourceName, resourcePath=rpath;

	if(node == 0)
		return false;
	//	Attributes
	node->getID(id);

#if 0
//  String id, name, type;
	node->getName(name);

	node->getType(type);
	{ TableRecord attr;
		addKW(attr, "ID", id);
		addKW(attr, "name", name);
		addKW(attr, "type", type);
		defineRecordValue(res, "attributes", attr);
	}
	//#else
#endif

	{char buf[32];
		sprintf(buf, "RESOURCE:%02d", resnum);
		resourceName = buf;
	}

	resourcePath += "/" + resourceName;
	mkdir(resourcePath.chars(), 0755);
	// Don't use name since it isn't guaranteed to be unique.
	// And records could overwrite each other.
	if(id != "")
		resourceName = id;

	addDescription(res, node->description());
	addInfoList(res, node->infoList());
	addCOOSYSList(res, node->coosysList());

	addParamList(res, node->paramList());
	addLinkList(res, node->linkList());
	addAIPSTables(resourcePath, res, node->tableList());
	addResources(resourcePath, res, node->resourceList());
	addAttributes(res, node);

	defineRecordValue(parent, resourceName, res);

	return true;
}

// Process a RESOURCE list. Create a record then add each resource's
// information to it. Then attach the record to the parent. A
// subdirectory is created to store tables in.
// Returns the number of resources added.
uInt VOT2AIPS::addResources(const String rpath, TableRecord &parent,
			    votResourceList *list)
{ uInt nelems = 0, added = 0;
  String respath = rpath;
  TableRecord rec;

	if((list == 0) || ((nelems = list->getLength()) ==0))
		return 0;

	// Create place to put resources 
	respath += "/RESOURCES";
	mkdir(respath.chars(), 0755);

	for(uInt i=0; i< nelems; i++)
	{	if(addResource(i, respath, rec, list->item(i)))
			added++;
	}
	defineRecordValue(parent, "RESOURCES", rec);
	return added;
}

// Adds version info of this program to a table record:
//  record/
//	V2A/
//		V2A major version
//		V2A minor version
//		Table format: "GENERAL" or "SIMPLE"
void VOT2AIPS::addV2AInfo(TableRecord &rec, bool isSimple)
{
 TableRecord version, v2a;

	// What version of V2A created the AIPS++ table?
	defineRecordValue(v2a, "Major", V2AVERSION_MAJOR);
	defineRecordValue(v2a, "Minor", V2AVERSION_MINOR);
	// What V2A format is the AIPS++ table?
	defineRecordValue(v2a, "FORMAT", (isSimple) ? "SIMPLE" : "GENERAL");

	defineRecordValue(rec, "V2A", v2a);
}

// Adds a VOTABLE's attributes (version info) to a table record:
//  record/
//	attributes:	// Votable information
//		version
//		xmlns
// Add the Votable's attributes (ID & version) if they exist.
void VOT2AIPS::addVOTABLEattributes(TableRecord &kw, VOTable *tbl)
{// String id, version;
//  TableRecord docrec;

	if(tbl == 0)
		return;

	addAttributes(kw, tbl);

#if 0
	// VOTABLE Document information.
	votDocument *doc = tbl->document();
	if(doc != 0)
	{ String publicID, systemID, internalSubset;
	  bool added = false;

		doc->getPublicId(publicID);
		added |= addKW(docrec, "PublicId", publicID);
		doc->getSystemId(systemID);
		added |= addKW(docrec, "SystemID", systemID);
		doc->getInternalSubset(internalSubset);
		added |= addKW(docrec, "InternalSubset", internalSubset);
		if(added)
			defineRecordValue(kw, "DOCINFO", docrec);
	}
#endif
}

// Adds VOTABLE DOCUMENT information to a table record:
//  record/
//	DOCINFO:	// Document information
//		SystemID
void VOT2AIPS::addDOCINFO(TableRecord &kw, VOTable *tbl)
{
	if(tbl == 0)
		return;

	// VOTABLE Document information.
	votDocument *doc = tbl->document();
	if(doc != 0)
	{ String publicID, systemID, internalSubset;
	  TableRecord docrec;
	  bool added = false;

		doc->getPublicId(publicID);
		added |= addKW(docrec, "PublicID", publicID);
		doc->getSystemId(systemID);
		added |= addKW(docrec, "SystemID", systemID);
		doc->getInternalSubset(internalSubset);
		added |= addKW(docrec, "InternalSubset", internalSubset);
		if(added)
			defineRecordValue(kw, "DOCINFO", docrec);
	}
}

////////////////////////////////////////////////////////////////
// Checks for a 'SIMPLE' table.
// Which is defined as a single
//		VOTable/RESOURCE/TABLE
//  While ignoring
//		VOTable/RESOURCE/RESOURCE/.../TABLE
//
// A table is defined to be the existence of a TABLE element as represented
// by a votTable node. Whether the table contains data or not is not
// checked.

/* Count and return the number of tables in the list. If it's > 0,
sets tbl1 to point to the first table if tbl1 is 0. If it isn't 0,
don't change it.
*/
uInt VOT2AIPS::countTables(votTableList *tl, votTable * & tbl1)
{
	if(tl == 0)
		return 0;

	uInt count = tl->getLength();

	if((count > 0) && (tbl1 == 0))
		tbl1 = tl->item(0);

	return count;
}

// Recursively count the number of tables within a resource.
// maxdepth gives the maximum # of levels to count, including this one.
uInt VOT2AIPS::checkResource(votResource *res, votTable * &tbl1,
			     const uLong maxdepth)
{ uInt count;

	if((res == 0) || (maxdepth == 0))
		count = 0;
	else
	{	count = countTables(res->tableList(), tbl1);
		count += checkResources(res->resourceList(), tbl1,
					maxdepth-1);
	}
	return count;
}

uInt VOT2AIPS::checkResources(votResourceList *rl, votTable * & tbl1,
			      const uLong maxdepth)
{ uInt count = 0;

	if(rl != 0)
	{	for(uInt i=0; i<rl->getLength(); i++)
		{ votResource *res = rl->item(i);
			count += checkResource(res, tbl1, maxdepth);
		}
	}
	return count;
}

// Scan a VOTable tree and returns true if there is only one table
// otherwise false. Returns the number of tables and a pointer to the
// first votTable. maxdepth gives the maximum # of levels of RESOURCES to
// descend below the first RESOURCE.
bool VOT2AIPS::checkForSimple(VOTable *votable, votTable * & vtbl1,
			      uLong maxdepth)
{ uInt count;

	vtbl1 = 0;

	if(votable == 0)
		return false;
	count = checkResources(votable->resourceList(), vtbl1, maxdepth);
#if 0
	cout << "With maxdepth = " << maxdepth << " found " << count
	     << " tables\n";
#endif
	return (count == 1);
}

////////////////////////////////////////////////////////////////
// Add kewords for the main VOTABLE node.
void VOT2AIPS::addVOTABLEKeywords(TableRecord &rec, VOTable *vtbl)
{ TableRecord votr;

	if(vtbl == 0)
		return;
	// Add votable information to table's keywords.
	addDescription(votr, vtbl->description());
	addDefinitionsList(votr, vtbl->definitionsList());
	addInfoList(votr, vtbl->infoList());
	addVOTABLEattributes(votr, vtbl);
	defineRecordValue(rec, "VOTABLE", votr);
}

// Create and populate an AIPS++ output table.
// The contents of the upper level table controlled by whether the
// input table is "SIMPLE" or not.
// vtbl		- Pointer to VOTable tree containing VOTABLE table.
// tablename	- Output filename.
// maxdepth	- Max # of levels to descend for counting tables. Used
//		  to decide whether the VOTABLE is "SIMPLE" or not.
//		  Default is effectively all levels. The only other value
//		  ever used will be 1. (Although any value is valid).
void VOT2AIPS::buildAIPSTable(VOTable *vtbl, String &tablename,
			      uLong maxdepth)
{ votTable *vtable1;
  bool isSimple;
  Table *aipstable=0;

	if(vtbl == 0)
		return;

	isSimple = checkForSimple(vtbl, vtable1, maxdepth);

	if(!isSimple)	// Not simple, main table is a table of contents.
	 try {	TableDesc td("", "1", TableDesc::Scratch);

		td.addColumn(ScalarColumnDesc<String> ("name"));
		td.addColumn(ScalarColumnDesc<String> ("ID"));
		td.addColumn(ScalarRecordColumnDesc ("Table"));

		SetupNewTable newtab(tablename, td, Table::New);
		// Create table (for its directory).
		aipstable = new Table(newtab, 0);
		gtable_ = aipstable;
	 } catch (AipsError &aerr)
	 {
		AERR("buildAIPSTable", aerr);
		throw;
	 }
	else	// It is SIMPLE. (Only one table).
	  try {	aipstable = createAIPSTable(tablename, vtable1);
		firstvotTable_ = vtable1;	// Flag special case.
		firstTable_ = aipstable;
	      } catch (AipsError &aerr)
	      {
		AERR("buildAIPSTable", aerr);
		throw;
	      }

	if(aipstable != 0)
	 try {	aipstable->flush(true);	// Force a write to disk.
		TableRecord &kw2 = aipstable->rwKeywordSet();

		// Resources have to be added after table is created
		// since they use subdirectories of the table.
		addResources(tablename, kw2, vtbl->resourceList());
		// Add VOTABLE information to AIPS++ table's keywords.
		addVOTABLEKeywords(kw2, vtbl);
		// Add info about how the AIPS++ table was created.
		addV2AInfo(kw2, isSimple);
		// Information about the document itself is added here rather
		// than the VOTABLE node since it's used to create the VOTABLE
		// document when translating back from AIPS++ and nothing here
		// needs an existing document object.
		addDOCINFO(kw2, vtbl);

		aipstable->flush(true);
		delete aipstable;	// Flush to disk.
	 } catch (AipsError &aerr)
	      {
		AERR("buildAIPSTable", aerr);
		throw;
	      }
}
