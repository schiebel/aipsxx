//# sditeratorDO.cc: this defines sditerator, which is the DO interface to SDIterator
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
//# $Id: sditeratorDO.cc,v 19.4 2004/11/30 17:50:09 ddebonis Exp $

//# Includes

#include <sditeratorDO.h>
#include <dish/SDIterators/SDTableIterator.h>
#include <dish/SDIterators/SDMSIterator.h>
#include <tasking/Tasking.h>
#include <casa/Containers/Record.h>
#include <casa/OS/File.h>
#include <casa/BasicSL/String.h>
#include <casa/Utilities/Assert.h>
#include <casa/Arrays/Vector.h>
#include <tasking/Glish/GlishRecord.h>
#include <casa/Logging.h>

namespace casa {
sditerator::sditerator(const String& tableName, const String &type,
		       const String &lockoptions)
    : iter_p(0)
{
    Record emptyRec;
    File file(tableName);
    if (file.exists()) {
	throw(AipsError(tableName + " already exists!"));
    }
    TableLock::LockOption lockopt = translateOption(lockoptions);
    if (type == "Table") {
	iter_p = new SDTableIterator(tableName, emptyRec, Table::New, lockopt);
    } else if (type == "MeasurementSet") {
	iter_p = new SDMSIterator(tableName, emptyRec, Table::New, lockopt);
    } else {
	throw(AipsError("Only Tables and MeasurementSets are supported."));
    }
    AlwaysAssert(iter_p, AipsError);
}

sditerator::sditerator(const String& tableName, 
		       Bool readOnly,
		       const GlishRecord& selection,
		       const String &lockoptions,
		       Bool correcteddata)
    : iter_p(0)
{
    Record selRec;
    selection.toRecord(selRec);
    Table::TableOption opt = Table::Update;
    if (readOnly) opt = Table::Old;
    TableLock::LockOption lockopt = translateOption(lockoptions);
    String type(deduceType(tableName));
    if (type == "Table") {
	// ignore correcteddata argument here - table-based is never calibrated
	iter_p = new SDTableIterator(tableName, selRec, opt, lockopt);
    } else if (type == "MeasurementSet") {
	iter_p = new SDMSIterator(tableName, selRec, opt, lockopt,
				  correcteddata);
    } else {
	throw(AipsError(String("Only Tables and MeasurementSets are supported. ") + 
			tableName + String(" appears to be a ") + type));
    }
    AlwaysAssert(iter_p, AipsError);
}

sditerator::sditerator(const sditerator& other, const GlishRecord& selection)
    : iter_p(0)
{
    Record selRec;
    selection.toRecord(selRec);
    String mytype(other.type());
    if (mytype == "Table") {
	iter_p = new SDTableIterator(*(static_cast<SDTableIterator *>(other.iter_p)), selRec);
    } else if (mytype == "MeasurementSet") {
	iter_p = new SDMSIterator(*(static_cast<SDMSIterator *>(other.iter_p)), selRec);
    } else {
	throw(AipsError(String("Only Tables and MeasurementSets are supported. ") + 
			other.name() + String(" appears to be a ") + mytype));
    }
    AlwaysAssert(iter_p, AipsError);
}

sditerator::sditerator(const sditerator &other)
    : iter_p(0)
{
    String mytype(other.type());
    if (mytype == "Table") {
	iter_p = new SDTableIterator(*(static_cast<SDTableIterator *>(other.iter_p)));
    } else if (mytype == "MeasurementSet") {
	iter_p = new SDMSIterator(*(static_cast<SDMSIterator *>(other.iter_p)));
    } else {
	throw(AipsError(String("Only Tables and MeasurementSets are supported. ") + 
			other.name() + String(" appears to be a ") + mytype));
    }
    AlwaysAssert(iter_p, AipsError);
}

ObjectID sditerator::select(const GlishRecord& selection)
{
    ObjectController *controller = ApplicationEnvironment::objectController();
    if (controller == 0) {
	LogMessage msg;
	msg.message("No controller is running, no selection possible").priority(LogMessage::SEVERE);
	LogSink::postGlobally(msg);
	return ObjectID(True);
    } 
    ApplicationObject *newIterObj = new sditerator(*this, selection);
    return controller->addObject(newIterObj);
}

sditerator& sditerator::operator=(const sditerator& other)
{
    if (this != &other) {
	if (other.type() != this->type()) {
	    throw(AipsError("sditerator::operator=(const sditerator &other): types do not match"));
	}
	*iter_p = *other.iter_p;
    }
    return *this;
}

sditerator::~sditerator()
{
    if (iter_p->type() == "Table") {
	delete static_cast<SDTableIterator *>(iter_p);
    } else if (iter_p->type() == "MeasurementSet") {
	delete static_cast<SDMSIterator *>(iter_p);
    } else {
	// this should never happen
	throw(AipsError(String("Severe unexpected error in sditerator, unexpected type :") + iter_p->type()));
    }
    iter_p = 0;
}

Index sditerator::location() 
{
    Index loc(iter_p->where());
    return loc;
}

Bool sditerator::setlocation(Index index)
{
    Int loc = index();
    if (loc < 0 || loc >= length()) return False;

    if (loc < Int(iter_p->where())) {
	if (loc == 0) {
	    origin();
	} else {
	    while(loc < Int(iter_p->where())) previous();
	}
    } else {
	while (loc > Int(iter_p->where())) next();
    }
    return True;
}

GlishRecord sditerator::get()
{
    GlishRecord grec;
    grec.fromRecord(getsdrecord());
    return grec;
}

Bool sditerator::getempty(GlishRecord &rec, Int nchan, Int nstokes)
{
    if (nchan < 0) nchan = 0;
    if (nstokes < 0) nstokes = 0;
    SDRecord sdrec;
    sdrec.resize(IPosition(2,nstokes, nchan));
    rec.fromRecord(sdrec);
    return True;
}

const SDRecord &sditerator::getsdrecord()
{
    return iter_p->get();
}

Bool sditerator::put(const GlishRecord& rec)
{
    Record theRec;
    rec.toRecord(theRec);
    SDRecord sdRec(theRec);
    return iter_p->put(theRec);
}

Bool sditerator::appendRec(const GlishRecord &rec)
{
    Record theRec;
    rec.toRecord(theRec);
    SDRecord sdRec(theRec);
    return iter_p->appendRec(theRec);
}

Bool sditerator::deleteRec()
{
    return iter_p->deleteRec();
}

GlishRecord sditerator::getheader()
{
    GlishRecord grec;
    grec.fromRecord(getHeader());
    return grec;
}

GlishRecord sditerator::getother()
{
    GlishRecord grec;
    grec.fromRecord(getOther());
    return grec;
}
GlishRecord sditerator::getdata()
{
    GlishRecord grec;
    grec.fromRecord(getData());
    return grec;
}

GlishRecord sditerator::getdesc()
{
    GlishRecord grec;
    grec.fromRecord(iter_p->getData().subRecord("desc"));
    return grec;
}

GlishRecord sditerator::getvectors(const GlishRecord& recTemplate)
{
    Record temp;
    GlishRecord result;
    recTemplate.toRecord(temp);
    result.fromRecord(iter_p->get_vectors(temp));
    return result;
}

const Record &sditerator::getData()
{
    return iter_p->getData();
}

const Record &sditerator::getHeader()
{
    return iter_p->getHeader();
}

const Record &sditerator::getOther()
{
    return iter_p->getOther();
}

GlishRecord sditerator::stringfields()
{
    GlishRecord grec;
    grec.fromRecord(iter_p->stringFields());
    return grec;
}

Vector<String> sditerator::methods() const
{
    Vector<String> method(NUMBER_METHODS);
    method(SELECT) = "select";
    method(RESYNC) = "resync";
    method(FLUSH) = "flush";
    method(RESELECT) = "reselect";
    method(DEEPCOPY) = "deepcopy";
    method(UNLOCK) = "unlock";
    method(LOCK) = "lock";
    method(ORIGIN) = "origin";
    method(MORE) = "more";
    method(NEXT) = "next";
    method(PREVIOUS) = "previous";
    method(SETLOCATION) = "setlocation";
    method(LOCATION) = "location";
    method(LENGTH) = "length";
    method(ISWRITABLE) = "iswritable";
    method(GET) = "get";
    method(GETEMPTY) = "getempty";
    method(PUT) = "put";
    method(APPENDREC) = "appendrec";
    method(DELETEREC) = "deleterec";
    method(GETHEADER) = "getheader";
    method(GETOTHER) = "getother";
    method(GETDATA) = "getdata";
    method(GETDESC) = "getdesc";
    method(GETVECTORS) = "getvectors";
    method(NAME) = "name";
    method(TYPE) = "type";
    method(STRINGFIELDS) = "stringfields";
    method(USECORRECTEDDATA) = "usecorrecteddata";
    method(CORRECTEDDATA) = "correcteddata";

    return method;
}

Vector<String> sditerator::noTraceMethods() const
{
    // don't trace anything
    return methods();
}

MethodResult sditerator::runMethod(uInt which,
				   ParameterSet &inputRecord,
				   Bool runMethod)
{
    static String returnvalString = "returnval";

    switch (which) {
    case SELECT:
	{
	    Parameter<ObjectID> returnval(inputRecord, returnvalString,
					  ParameterSet::Out);
	    static String selectionString = "selection";
	    Parameter<GlishRecord> selection(inputRecord, selectionString, 
					     ParameterSet::In);
	    if (runMethod) returnval() = select(selection());
	}
    case RESYNC:
	{
	    if (runMethod) resync();
	}
	break;
    case FLUSH:
	{
	    if (runMethod) flush();
	}
	break;
    case RESELECT:
	{
	    if (runMethod) reselect();
	}
	break;
    case DEEPCOPY:
	{
	    static String newnameString = "newname";
	    Parameter<String> newName(inputRecord, newnameString, 
				      ParameterSet::In);
	    if (runMethod) deepcopy(newName());
	}
	break;
    case UNLOCK:
	{
	    Parameter<Bool> returnval(inputRecord, returnvalString, 
				      ParameterSet::Out);
	    if (runMethod) returnval() = unlock();
	}
	break;
    case LOCK:
	{
	    static String nattString = "nattempts";
	    Parameter<Bool> returnval(inputRecord, returnvalString, 
				      ParameterSet::Out);
	    Parameter<Int> nattempts(inputRecord, nattString,
				     ParameterSet::In);
	    if (runMethod) {
		uInt natt = 0;
		if (nattempts() > 0) natt = nattempts();
		returnval() = lock(natt);
	    }
	}
	break;
    case ORIGIN:
	{
	    if (runMethod) origin();
	}
	break;
    case MORE:
	{
	    Parameter<Bool> returnval(inputRecord, returnvalString, 
				      ParameterSet::Out);
	    if (runMethod) returnval() = more();
	}
	break;
    case NEXT:
	{
	    if (runMethod) next();
	}
	break;
    case PREVIOUS:
	{
	    if (runMethod) previous();
	}
	break;
    case SETLOCATION:
	{
	    static String locString = "location";
	    Parameter<Bool> returnval(inputRecord, returnvalString, 
				      ParameterSet::Out);
	    Parameter<Index> loc(inputRecord, locString,
				 ParameterSet::In);
	    if (runMethod) returnval() = setlocation(loc());
	}
	break;
    case LOCATION:
	{
	    Parameter<Index> returnval(inputRecord, returnvalString, 
				       ParameterSet::Out);
	    if (runMethod) returnval() = location();
	}
	break;
    case LENGTH:
	{
	    Parameter<Int> returnval(inputRecord, returnvalString, 
				      ParameterSet::Out);
	    if (runMethod) returnval() = length();
	}
	break;
    case ISWRITABLE:
	{
	    Parameter<Bool> returnval(inputRecord, returnvalString, 
				      ParameterSet::Out);
	    if (runMethod) returnval() = iswritable();
	}
	break;
    case GET:
	{
	    Parameter<GlishRecord> returnval(inputRecord, returnvalString, 
					     ParameterSet::Out);
	    if (runMethod) returnval() = get();
	}
	break;
    case GETEMPTY:
	{
	    static String recString = "rec";
	    static String nchanString = "nchan";
	    static String nstokesString = "nstokes";
	    Parameter<Bool> returnval(inputRecord, returnvalString, 
				      ParameterSet::Out);
	    Parameter<GlishRecord> rec(inputRecord, recString,
				       ParameterSet::Out);
	    Parameter<Int> nchan(inputRecord, nchanString,
				 ParameterSet::In);
	    Parameter<Int> nstokes(inputRecord, nstokesString,
				   ParameterSet::In);
	    if (runMethod) returnval() = getempty(rec(), nchan(), nstokes());
	}
	break;
    case PUT:
	{
	    static String recString = "rec";
	    Parameter<Bool> returnval(inputRecord, returnvalString, 
				      ParameterSet::Out);
	    Parameter<GlishRecord> rec(inputRecord, recString,
				       ParameterSet::In);
	    if (runMethod) returnval() = put(rec());
	}
	break;
    case APPENDREC:
	{
	    static String recString = "rec";
	    Parameter<Bool> returnval(inputRecord, returnvalString, 
				      ParameterSet::Out);
	    Parameter<GlishRecord> rec(inputRecord, recString,
				       ParameterSet::In);
	    if (runMethod) returnval() = appendRec(rec());
	}
	break;
    case DELETEREC:
	{
	    Parameter<Bool> returnval(inputRecord, returnvalString, 
				      ParameterSet::Out);
	    if (runMethod) returnval() = deleteRec();
	}
	break;
    case GETHEADER:
	{
	    Parameter<GlishRecord> returnval(inputRecord, returnvalString, 
					     ParameterSet::Out);
	    if (runMethod) returnval() = getheader();
	}
	break;
    case GETOTHER:
	{
	    Parameter<GlishRecord> returnval(inputRecord, returnvalString, 
					     ParameterSet::Out);
	    if (runMethod) returnval() = getother();
	}
	break;
    case GETDATA:
	{
	    Parameter<GlishRecord> returnval(inputRecord, returnvalString, 
					     ParameterSet::Out);
	    if (runMethod) returnval() = getdata();
	}
	break;
    case GETDESC:
	{
	    Parameter<GlishRecord> returnval(inputRecord, returnvalString, 
					     ParameterSet::Out);
	    if (runMethod) returnval() = getdesc();
	}
	break;
    case GETVECTORS:
	{
	    static String templateString = "template";
	    Parameter<GlishRecord> returnval(inputRecord, returnvalString, 
					     ParameterSet::Out);
	    Parameter<GlishRecord> recTemplate(inputRecord, templateString, 
					     ParameterSet::In);
	    if (runMethod) returnval() = getvectors(recTemplate());
	}
	break;
    case NAME:
	{
	    Parameter<String> returnval(inputRecord, returnvalString,
					ParameterSet::Out);
	    if (runMethod) returnval() = name();
	}
	break;
    case TYPE:
	{
	    Parameter<String> returnval(inputRecord, returnvalString,
					ParameterSet::Out);
	    if (runMethod) returnval() = type();
	}
	break;
    case STRINGFIELDS:
	{
	    Parameter<GlishRecord> returnval(inputRecord, returnvalString,
					     ParameterSet::Out);
	    if (runMethod) returnval() = stringfields();
	}
	break;
    case USECORRECTEDDATA:
	{
	    static String correcteddataString = "correcteddata";
	    Parameter<Bool> correctedData(inputRecord, correcteddataString,
					  ParameterSet::In);
	    Parameter<Bool> returnval(inputRecord, returnvalString,
				      ParameterSet::Out);
	    if (runMethod) returnval() = usecorrecteddata(correctedData());
	}
	break;
    case CORRECTEDDATA:
	{
	    Parameter<Bool> returnval(inputRecord, returnvalString,
				      ParameterSet::Out);
	    if (runMethod) returnval() = correcteddata();
	}
	break;
    default:
	return error("No such method");
    }
    return ok();
}


String sditerator::deduceType(const String &fileName)
{
    String ttype = Table::tableInfo(fileName).type();
    if (ttype == TableInfo::type(TableInfo::MEASUREMENTSET)) {
	ttype = "MeasurementSet";
    } else if (ttype == TableInfo::type(TableInfo::PAGEDIMAGE)) {
	ttype = "Image";
    } else {
	ttype = "Table";
    }
    return ttype;
}

MethodResult sditeratorFactory::make(ApplicationObject *&newObject,
				    const String& whichConstructor,
				    ParameterSet &inputRecord,
				    Bool runConstructor)
{
    MethodResult retval;
    newObject = 0;

    if (whichConstructor == "sditerator") {
	Parameter<String> filename(inputRecord, "filename",
				   ParameterSet::In);
	Parameter<Bool> readonly(inputRecord, "readonly",
				 ParameterSet::In);
	Parameter<GlishRecord> selection(inputRecord, "selection",
						 ParameterSet::In);
	Parameter<String> lockoptions(inputRecord, "lockoptions",
				      ParameterSet::In);
	Parameter<Bool> correcteddata(inputRecord, "correcteddata",
				       ParameterSet::In);
	if (runConstructor) {
	    newObject = new sditerator(filename(), readonly(), selection(),
				       lockoptions(), correcteddata());
	    if (newObject &&
		!((sditerator *)newObject)->iterOK()) {
		// problems during construction
		retval = String("A problem occured during construction");
	    }
	}
    } else if (whichConstructor == "newsditerator") {
	Parameter<String> filename(inputRecord, "filename",
				   ParameterSet::In);
	Parameter<String> type(inputRecord, "type",
			       ParameterSet::In);
	Parameter<String> lockoptions(inputRecord, "lockoptions",
				      ParameterSet::In);
	if (runConstructor) {
	    newObject = new sditerator(filename(), type(), lockoptions());
	    if (newObject &&
		!((sditerator *)newObject)->iterOK()) {
		// problems during construction
		retval = String("A problem occured during creation");
	    }
	}
    } else {
	retval = String("unknown constructor ") + whichConstructor;
    }

    if (retval.ok() && runConstructor && !newObject) {
	retval = "Memory allocation error";
    }
    return retval;
}

TableLock::LockOption sditerator::translateOption(const String &lockoptions)
{
    TableLock::LockOption opt;
    String str = lockoptions;
    str.downcase();
    if (str == "default") {
	opt = TableLock::DefaultLocking;
    } else if (str == "auto") {
	opt = TableLock::AutoLocking;
    } else if (str == "autonoread") {
	opt = TableLock::AutoNoReadLocking;
    } else if (str == "user") {
	opt = TableLock::UserLocking;
    } else if (str == "usernoread") {
	opt = TableLock::UserNoReadLocking;
    } else if (str == "permanent") {
	opt = TableLock::PermanentLocking;
    } else if (str == "permanentwait") {
	opt = TableLock::PermanentLockingWait;
    } else {
	String message = "'" + str + "' is an unknown lock option; valid are "
	 "default,auto,autonoread,user,usernoread,permanent,permanentwait";
	// probably not the best way to handle this
	throw(AipsError(message));
    }
    return opt;
}
}
