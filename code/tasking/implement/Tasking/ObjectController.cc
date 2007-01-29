//# ObjectController.h: Link application objects to a server and the control bus
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
//# $Id: ObjectController.cc,v 19.10 2005/12/06 20:18:51 wyoung Exp $

#include <casa/version.h>

#include <tasking/Tasking/ObjectController.h>
#include <tasking/Tasking/ObjectDispatcher.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/ParameterSet.h>
#include <tasking/Tasking/ApplicationEnvironment.h>
#include <casa/System/ProgressMeter.h>
#include <casa/System/Choice.h>
#include <casa/System/PGPlotter.h>
#include <casa/System/AipsrcValue.h>
#include <tasking/Tasking/ObjectIDRecord.h>

#include <tasking/Glish/GlishRecord.h>
#include <casa/Arrays/Vector.h>
#include <tasking/Glish/GlishArray.h>
#include <casa/Exceptions/Error.h>
#include <casa/Utilities/Assert.h>

#include <casa/Logging/LogFilter.h>
#include <casa/Logging/StreamLogSink.h>
#include <tasking/Tasking/GlishLogSink.h>

#include <casa/OS/Memory.h>
#include <tables/Tables/Table.h>
#include <casa/OS/Path.h>

#include <casa/sstream.h>

#include <casa/stdexcept.h>


namespace casa { //# NAMESPACE CASA - BEGIN

Int ObjectController::basicTimeout = 5000;
Int ObjectController::longIdleTime = 60000;


void ObjectController::setIdleFunction(IdleFunction func)
{
    idle_func_p = func;
}

void ObjectController::setGlobalLogSink(LogSinkInterface *globalSink)
{
    if (globalSink == 0) {
        LogFilter filter(LogMessage::NORMAL);
	globalSink = new GlishLogSink(filter, event_source_p);
	AlwaysAssert(globalSink != 0, AipsError);
    }

    LogSink::globalSink(globalSink);
}

void ObjectController::init(int argc, char **argv,
			    LogSinkInterface *globalSink,
			    IdleFunction idleFunc)
{

    Memory::setMemoryOptions();
    event_source_p = new GlishSysEventSource(argc, argv);
    objects_p.resize(0);
    trace_p = False;
    server_name_p = argv[0];
    setIdleFunction(idleFunc);

    // Get the relinquish autolock period.
    Float relPeriod;
    AipsrcValue<Float>::find (relPeriod,
			      "table.relinquish.reqautolocks.interval", 5);
    if (relPeriod > 0) {
      basicTimeout = Int(1000 * relPeriod + 0.5);
    }
    AipsrcValue<Float>::find (relPeriod,
			      "table.relinquish.allautolocks.interval", 60);
    if (relPeriod > 0) {
      longIdleTime = Int(1000 * relPeriod + 0.5);
    }

    AlwaysAssert(!event_source_p.null(), AipsError);
    ApplicationEnvironment::the_controller_p = this;

    setGlobalLogSink(globalSink);
    log_p << LogOrigin("ObjectController", "ObjectController", WHERE) <<
	"Server started: " << server_name_p << 
	" (AIPS++ version: ";

    // Set the static functions in ProgressMeter so that they will actually
    // post progress events to the user
    ProgressMeter::creation_function_p = 
	ApplicationEnvironment::makeProgressDisplay;
    ProgressMeter::update_function_p = 
	ApplicationEnvironment::updateProgressDisplay;
    // Set the static choice function.
    Choice::setChoiceFunc (ApplicationEnvironment::choice);

    ostringstream buffer;
    VersionInfo::report(buffer);
    log_p << String(buffer) << ")" << LogIO::NORMAL << LogIO::POST;
}

ObjectController::ObjectController(int argc, char **argv,
				   LogSinkInterface *globalSink, 
				   IdleFunction idleFunc)
    : makers_p(static_cast<void *>(0))
{
    init(argc, argv, globalSink, idleFunc);
}
    

ObjectController::~ObjectController()
{
    // Probably Glish has gone away by the time the destructor is called. If
    // so, only pass SEVERE messages, since they are probably just getting dumped
    //  on the screen.
    if (! event_source_p->connected()) {
	LogSink::globalSink().filter(LogFilter(LogMessage::SEVERE));
    }

    log_p << LogOrigin("ObjectController", 
		     "~ObjectController()",
		       WHERE) << LogIO::NORMAL;
    log_p << "Shutting down server : " << server_name_p << endl;

    Int n = n_makers();
    while (--n >= 0) {
	ApplicationObjectFactory *ptr = maker(n);
	if (ptr) {
	    delete maker(n);
	}
    }
        

    makers_p.clear();
    n = objects_p.nelements();
    uInt count = 0;
    while (--n >= 0) {
	if (objects_p[n]) {
	    count++;
	    if (objects_p[n]) delete objects_p[n]; // The if shouldn't be needed
	    objects_p[n] = 0;
	}
    }
    log_p << "Shut down " << count << " active objects" << endl;
    objects_p.resize(0, True);
    ApplicationEnvironment::the_controller_p = 0;

    log_p << "Execution time : ";

    ostringstream buffer;

    total_timer_p.show(buffer);
    log_p << String(buffer) << LogIO::POST;

    LogSinkInterface *dummy = new StreamLogSink(LogMessage::NORMAL, &cerr);
    LogSink::globalSink(dummy);
}

ApplicationObjectFactory *ObjectController::maker(const String &which)
{
    void **ptrtoval = makers_p.isDefined(which);
    if (ptrtoval) {
        void *val = *ptrtoval;
	return (ApplicationObjectFactory *)val;
    } else {
        return 0;
    }
}

void ObjectController::addMaker(const String &typeName, 
				ApplicationObjectFactory *fromNew)
{
    AlwaysAssert(fromNew && (maker(typeName) == 0), AipsError);
    makers_p.define(typeName, fromNew);
}

ObjectID ObjectController::addObject(ApplicationObject *&fromNew)
{
    AlwaysAssert(fromNew, AipsError);
    ApplicationObject *object = fromNew;
    fromNew = 0; // Try to prevent double deletion

    ObjectID retval = object->id();
    Int sequence = retval.sequence();
    if (sequence+1 > Int(objects_p.nelements())) {
	uInt oldSize = objects_p.nelements();
	uInt newSize = 2*sequence + 1;
	objects_p.resize(newSize);
	for (uInt i=oldSize; i<newSize; i++) {
	    objects_p[i] = 0;
	}
    }
    objects_p[sequence] = new ObjectDispatcher(object);
    AlwaysAssert(objects_p[sequence], AipsError);

    return retval;
}

ObjectID ObjectController::createObject(const String &typeName,
			const String &whichCtor,
			GlishRecord *&inputValues, String &errorMsg)
{
    ObjectID retval(True); // Null initially
    ApplicationObjectFactory *creator = maker(typeName);
    if (!creator) {
	errorMsg = String("Do not know how to create type=") + typeName;
	return retval;
    }

    ParameterSet inputRecord;
    ApplicationObject *object;
    inputRecord.doSetup(True);
    MethodResult result = creator->make(object, whichCtor,
					inputRecord, False);
    if (!result.ok()) {
	errorMsg = result.errorMessage();
	return retval;
    }
    Bool error;
    inputRecord.setParameterRecord(inputValues, error, errorMsg);
    if (!error) {
	return retval;
    }
    inputRecord.doSetup(False);
    result = creator->make(object, whichCtor, inputRecord, True);
    if (!result.ok()) {
	errorMsg = result.errorMessage();
	return retval;
    }

    return addObject(object);
}

ApplicationObject *ObjectController::getObject(const ObjectID &id)
{
    uInt whichObj = id.sequence();

    ApplicationObject *retval = 0;
    if (whichObj < objects_p.nelements()) {
	ObjectDispatcher *object = 0;
	object = objects_p[whichObj];
	if (object != 0) {
	    ApplicationObject *candidate = object->object();
	    if (candidate->id() == id) {
		retval = candidate;
	    }
	}
    }
    return retval;
}

Vector<String> ObjectController::methods(const ObjectID &id)
{
    uInt whichObj = id.sequence();

    ObjectDispatcher *object = 0;
    if (whichObj < objects_p.nelements()) {
	object = objects_p[whichObj];
    }
    if (object == 0) {
	Vector<String> null(1);
	null = "";
        return null;
    }
    return object->methods();
}

MethodResult ObjectController::runMethod(uInt whichObj, const String &method,
					 GlishRecord *&fromNew,
					 CountedPtr<GlishRecord> &result)
{
    ObjectDispatcher *object = 0;
    if (whichObj < objects_p.nelements()) {
	object = objects_p[whichObj];
    }
    if (object == 0) {
	ostringstream buffer;
	buffer << "No such object (" << whichObj << ") has been created";
	return String(buffer);
    }

    return object->runMethod(method, fromNew, result);
}

Bool ObjectController::done(uInt &numleft, String &error, const ObjectID &id)
{
    uInt which = id.sequence();
    if (which >= objects_p.nelements()) {
	error = "No such object has ever been in this server";
	return False;
    }
    if (objects_p[which] == 0) {
	error = "Object does not exist, possible already deleted";
	return False;
    }
    // Compare the whole objectid to be safe;
    if (objects_p[which]->object()->id() != id) {
	error = "Object does not exist in server";
	return False;
    }

    // If the destructor throws an exception an upper level catch should get
    // it. But probably all hell will break loose anyway.
    delete objects_p[which];
    objects_p[which] = 0;

    numleft = 0;
    for (uInt i=0; i<objects_p.nelements(); i++) {
	if (objects_p[i]) numleft++;
    }
    return True;
}

ApplicationObjectFactory *ObjectController::maker(uInt which)
{
    AlwaysAssert(Int(which) < n_makers(), AipsError);
    return (ApplicationObjectFactory *)makers_p.getVal(which);
}

void ObjectController::postError(const String &errorMessage)
{
    GlishArray gerror(errorMessage);
    event_source_p->postEvent("error", gerror);
}

void ObjectController::loop()
{
    Int idletime = 0;
    Bool needidle = True;

    GlishSysEvent event;
    while (event_source_p->connected()) {
	try {
	    if (idle_func_p && needidle) {
		Bool gotevent = 
		    event_source_p->nextGlishEvent(event,basicTimeout);
		if (gotevent) {
		    idletime = 0;
		    handleEvent(event);
		} else {
		    idletime += basicTimeout;
		    needidle = (*idle_func_p)(idletime);
		}
	    } else {
		event = event_source_p->nextGlishEvent();
		handleEvent(event);
		idletime = 0;
		needidle = True;
	    }
	} catch (AipsError& x) {
	    String error = "Caught an exception! Event type=";
	    error += event.type();
	    error += String(" exception=") + x.getMesg();
	    postError(error);
	} catch (exception& x) {
	    String error = "Caught an std exception! Event type=";
	    error += event.type();
	    error += String(" exception=") + x.what();
	    postError(error);
	} catch (...) {
	    String error = "Caught an unknown exception! Event type=";
	    error += event.type();
	    postError(error);
	} 
    }
}

void ObjectController::trace(Bool doTrace)
{
    trace_p = doTrace;
    if (trace()) {
	LogSink::globalSink().filter(LogFilter(LogMessage::DEBUGGING));
    } else {
	LogSink::globalSink().filter(LogFilter(LogMessage::NORMAL));
    }
}

Bool ObjectController::makePlotterIfNecessary(String &error, const String &name,
					      uInt mincolors, uInt maxcolors,
                                              uInt sizex, uInt sizey)
{
    if (event_source_p.null() || ! event_source_p->connected()) {
	error = "ObjectController is not connected to Glish";
	return False;
    }


    // Send the create command to Glish
    Vector<Int> size(2);
    GlishRecord sendrec;
    sendrec.add("name", name).add("mincolors", Int(mincolors)).
	add("maxcolors", Int(maxcolors)).add("sizex", Int(sizex)).
        add ("sizey", Int(sizey));
    event_source_p->postEvent("makeplot", sendrec);

    // Attempt to get the response
    GlishSysEvent event;
    while(event_source_p->connected()) {
	event = event_source_p->nextGlishEvent();
	if (event.type() == "makeplot_result") {
	    return True;
	} else if (event.type() == "makeplot_error") {
	    GlishArray err = event.val();
	    err.get(error);
	    return False;
	} else {
	    handleEvent(event);
	}
    }

    return True;
}


Bool ObjectController::sendPlotCommands(String &error, GlishValue &out, 
					const String &plotName,
					const GlishRecord &plot)
{
    // This probably needs more development, i.e. it probably doesn't handle
    // waiting for events from multiple plots correctly if the events come
    // back out of order.

    if (event_source_p.null() || ! event_source_p->connected()) {
	error = "ObjectController is not connected to Glish";
	return False;
    }

    // Send the plot command to Glish
    GlishRecord sendrec;
    sendrec.add("name", plotName).add("plot", plot);
    event_source_p->postEvent("plot", sendrec);

    // Attempt to get the response
    GlishSysEvent event;
    while(event_source_p->connected()) {
	event = event_source_p->nextGlishEvent();
	if (event.type() == "plot_result") {
	    out = event.val();
	    break;
	} else if (event.type() == "plot_error") {
	    GlishArray err = event.val();
	    err.get(error);
	    return False;
	} else {
	    handleEvent(event);
	}
    }

    return True;
}

Bool ObjectController::view(String &name) 
{

    log_p << LogOrigin("ObjectController", 
		       "view(String &name)", WHERE);

    if (event_source_p.null() || ! event_source_p->connected()) {
	log_p << LogIO::DEBUGGING << 
	    "Not connected to Glish" << LogIO::POST;
	return False;
    }

    // Send the plot command to Glish
    GlishRecord sendrec;
    sendrec.add("name", name);
    event_source_p->postEvent("view", sendrec);

    return True;
}

String ObjectController::choice(const String &descriptiveText,
				const Vector<String> &choices)
{
    log_p << LogOrigin("ObjectController", 
		       "choice(const String &descriptiveText,"
		       "const Vector<String> &choices)", WHERE);

    if (choices.nelements() == 0) {
	log_p << LogIO::DEBUGGING << 
	    "No choices provided - returning empty string" << LogIO::POST;
	return "";
    }

    if (!event_source_p->connected()) {
	log_p << LogIO::DEBUGGING << 
	    "Not connected, returning first choice: " <<  choices(0) <<
	    LogIO::POST;
	return choices(0);
    }

    GlishRecord choicerec;
    choicerec.add("description", descriptiveText);
    choicerec.add("choices", choices);
    event_source_p->postEvent("get_choice", choicerec);

    GlishSysEvent event;
    String mychoice = choices(0);
    Bool found = False;
    while(event_source_p->connected()) {
	event = event_source_p->nextGlishEvent();
	if (event.type() == "choice") {
	    GlishArray gchoice = event.val();
	    gchoice.get(mychoice);
	    found = True;
	    break;
	} else {
	    handleEvent(event);
	}
    }

    if (! found) {
	log_p << LogIO::SEVERE << "No choice provided!! Returning: " <<
	    mychoice << LogIO::POST;
    } else {
	log_p << LogIO::DEBUGGING << "Returning choice: " << mychoice <<
	    LogIO::POST;
    }

	return mychoice;
}

Bool ObjectController::stop()
{
    log_p << LogOrigin("ObjectController", 
		       "Bool stop()", WHERE);

    if (!event_source_p->connected()) {
	log_p << LogIO::DEBUGGING << 
	  "Not connected, returning False",
	  LogIO::POST;
	return False;
    }

    GlishRecord stoprec;
    event_source_p->postEvent("get_stop", stoprec);

    GlishSysEvent event;
    Bool stop = False;
    while(event_source_p->connected()) {
	event = event_source_p->nextGlishEvent();
	if (event.type() == "stop") {
	    GlishArray gchoice = event.val();
	    gchoice.get(stop);
	    break;
	} else {
	    handleEvent(event);
	}
    }

    return stop;
}

Bool ObjectController::hasGUI()
{
    log_p << LogOrigin("ObjectController", 
		       "Bool hasGUI()", WHERE);

    if (!event_source_p->connected()) {
	log_p << LogIO::DEBUGGING << 
	  "Not connected, returning False",
	  LogIO::POST;
	return False;
    }

    GlishRecord rec;
    event_source_p->postEvent("get_hasGUI", rec);

    GlishSysEvent event;
    Bool isGUI = False;
    while(event_source_p->connected()) {
	event = event_source_p->nextGlishEvent();
	if (event.type() == "hasGUI") {
	    GlishArray gchoice = event.val();
	    gchoice.get(isGUI);
	    break;
	} else {
	    handleEvent(event);
	}
    }
//
    return isGUI;
}


void ObjectController::sendMemoryUse()
{
    if (!event_source_p.null() && event_source_p->connected()) {
        Double d = Memory::allocatedMemoryInBytes();
	d /= (1024.0*1024.0);
        GlishArray tmp(d);
	event_source_p->postEvent("memory", tmp);
    }
}

Int ObjectController::makeProgressDisplay(Double min, Double max, 
				const String &title, const String &subtitle,
				const String &minlabel, const String &maxlabel, 
				Bool estimateTime)
{
    log_p << LogOrigin("ObjectController", 
		       "makeProgressDisplay(...)", WHERE);

    if (event_source_p.null() || !event_source_p->connected()) {
	log_p << LogIO::DEBUGGING << 
	    "Not connected, returning null progress id" << LogIO::POST;
	return -1;
    }

    GlishRecord progressrec;
    progressrec.add("min", min);
    progressrec.add("max", max);
    progressrec.add("title", title);
    progressrec.add("subtitle", subtitle);
    progressrec.add("minlabel", minlabel);
    progressrec.add("maxlabel", maxlabel);
    progressrec.add("estimate", estimateTime);
    event_source_p->postEvent("get_progress", progressrec);

    GlishSysEvent event;
    Int id = -1;
    Bool found = False;
    while(event_source_p->connected()) {
	event = event_source_p->nextGlishEvent();
	if (event.type() == "progress_result") {
	    GlishArray gchoice = event.val();
	    gchoice.get(id);
	    found = True;
	    break;
	} else {
	    handleEvent(event);
	}
    }

    if (! found) {
	log_p << LogIO::SEVERE << "No progress id provided!! "
	    "Returning null id." << LogIO::POST;
    }

    return id;
}

// This might be called a lot, so avoid excess creation/destruction
static GlishRecord progressRec;
void ObjectController::updateProgressDisplay(Int id, Double value)
{
    static Timer timer;

    // When we are updating progress bars, send the memory use if more than
    // a second has passed, since otherwise this is a convenient way to get
    // memory usage to the user in what is otherwise a tight loop.
    if (timer.real() > 1.0) {
        sendMemoryUse();
	timer.mark();
    }

    if (id <= 0 || event_source_p.null() || !event_source_p->connected()) {
	return;
    }
    progressRec.add("id", id);
    progressRec.add("value", value);
    event_source_p->postEvent("progress", progressRec);
}


void ObjectController::handleEvent(GlishSysEvent &event)
{
    if (trace()) {
	log_p << LogOrigin("ObjectController",
	    "handleEvent(GlishSysEvent &event)", WHERE);
	ostringstream buffer; buffer << event.val();
	log_p << "C++ TRACE " << "event=" << event.type() << " value=" <<
	    String(buffer) << LogIO::DEBUGGING << LogIO::POST;
    }

    // Put the most frequently called events early in the if-chain for
    // efficiency
    if (event.type() == "run") {
	handleRun(event,False);
    } else if (event.type() == "run_async") {
	handleRun(event,True);
    } else if (event.type() == "create") {
	handleCreate(event);
    } else if (event.type() == "trace") {
	handleTrace(event);
    } else if (event.type() == "methods") {
	handleMethods(event);
    } else if (event.type() == "done") {
	handleDone(event);
    } else if (event.type() != "shutdown") {
	handleUnrecognized(event);
    }
}

void ObjectController::handleDone(GlishSysEvent &event)
{
    if (event.val().type() != GlishValue::RECORD) {
	postError("malformed done event, no ObjectID record");
	return;
    }
    GlishRecord idrec = event.val();

    ObjectID id(True);
    Bool ok;
    String error;
    ok = OIDfromRecord(id, error, idrec, "");
    if (!ok) {
	postError(String("malformed done event, invalid ObjectID record ") +
		  error);
	return;
    }

    uInt numleft;
    ok = done(numleft, error, id);
    if (!ok) {
	postError(String("Could not destruct object : ") + error);
	return;
    }

    Int n = Int(numleft);
    GlishArray num(n);
    event_source_p->postEvent(String("done_result"), num);
}

void ObjectController::handleMethods(GlishSysEvent &event)
{

    if (event.val().type() != GlishValue::RECORD) {
	postError("malformed methods event, no ObjectID record");
	return;
    }
    GlishRecord idrec = event.val();

    ObjectID id(True);
    Bool ok;
    String error;
    ok = OIDfromRecord(id, error, idrec, "");
    if (!ok) {
	postError(String("malformed methods event, invalid ObjectID record ") +
		  error);
	return;
    }

    Vector<String> objectMethods=methods(id);
    GlishArray gmethods(objectMethods);
    event_source_p->postEvent(String("methods_result"), gmethods);
}

void ObjectController::handleRun(GlishSysEvent &event, Bool async)
{
    // Avoid creating these every iteration of the event loop
    static GlishArray gsequence;
    static GlishArray gmethod;
    static GlishArray gjobid;
    static String method;
    static Int sequence;
    static Int jobid;
    static const String methodString = "_method";
    static const String sequenceString = "_sequence";
    static const String jobidString = "_jobid";
    static MethodResult result;


    if (event.val().type() != GlishValue::RECORD) {
	postError("malformed run event - must have record");
    }

    GlishRecord *invokeRecord = new GlishRecord(event.val());

    if ( (! invokeRecord->exists(methodString)) || 
	 (! invokeRecord->exists(sequenceString)) ) {
	postError("malformed run event - missing _method or _sequence field");
    }

    if (async) {
	if (! invokeRecord->exists(jobidString)) {
	    postError("malformed run event - missing _jobid");
	}
	gjobid = invokeRecord->get(jobidString);
	gjobid.get(jobid);
	if (jobid <= 0) {
	    postError("illegal jobid (<=0; must be positive)");
	}
    }

    gmethod = invokeRecord->get(methodString);
    gmethod.get(method);
    gsequence = invokeRecord->get(sequenceString);
    gsequence.get(sequence);
    CountedPtr<GlishRecord> resultRecord;
    result = runMethod(sequence, method, invokeRecord, resultRecord);
    if (result.ok()) {
	if (async) {
	    event_source_p->postEvent("run_result_async", *resultRecord);
	} else {
	    event_source_p->postEvent("run_result", *resultRecord);
	}
    } else {
	String message = String("Method ") + method + " fails!\n";
	message += result.errorMessage();
	postError(message);
    }
}

void ObjectController::handleCreate(GlishSysEvent &event)
{
    static GlishArray gtype;
    static String type;
    static const String typeString = "_type";
    static GlishArray gcreator;
    static String creator;
    static const String creatorString = "_creator";
    static ObjectID id;
    static String errorMsg;
    static GlishRecord result;
    
    if (event.val().type() != GlishValue::RECORD) {
	postError("malformed create event - must have record");
	return;
    }

    GlishRecord *invokeRecord = new GlishRecord(event.val());

    if ( (! invokeRecord->exists(typeString)) ) {
	postError("malformed create event - missing _type field");
	delete invokeRecord;
	return;
    }

    gtype = invokeRecord->get(typeString);
    gtype.get(type);

    if ( (! invokeRecord->exists(creatorString)) ) {
	creator = "";
    } else {
	gcreator = invokeRecord->get(creatorString);
	gcreator.get(creator);
    }

    id = createObject(type, creator, invokeRecord, errorMsg);
    if (id.isNull()) {
	postError(errorMsg);
	if (invokeRecord) {
	    delete invokeRecord;
	    invokeRecord = 0;
	}
    } else {
        OIDtoRecord(id, result);
	event_source_p->postEvent("create_result", result);
    }
}

void ObjectController::handleTrace(GlishSysEvent &event)
{
    // This is a low-volume operation
    GlishValue gval = event.val();
    Bool ok = False;
    if (gval.type() == GlishValue::ARRAY) {
	GlishArray ga = gval;
	if (ga.elementType() != GlishArray::STRING && ga.nelements() == 1) {
	    ok = True;
	    Bool doTrace;
	    ga.get(doTrace);
	    trace(doTrace);
	}
    }
    if (!ok) {
	postError("Illegal switch given to trace - must be T or F");
    }
}

void ObjectController::handleUnrecognized(GlishSysEvent &event)
{
    String message = "Do not recognize event : ";
    message += event.type();
    postError(message);
}

Int ObjectController::n_makers() const
{
    return makers_p.ndefined();
}

} //# NAMESPACE CASA - END

