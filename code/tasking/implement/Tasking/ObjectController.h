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
//# $Id: ObjectController.h,v 19.5 2004/11/30 17:51:11 ddebonis Exp $

#ifndef TASKING_OBJECTCONTROLLER_H
#define TASKING_OBJECTCONTROLLER_H

#include <casa/aips.h>
#include <tasking/Glish/GlishEvent.h>
#include <casa/Utilities/CountedPtr.h>
#include <casa/Containers/SimOrdMap.h>
#include <casa/Containers/Block.h>
#include <casa/Logging/LogIO.h>
#include <casa/OS/Timer.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class ObjectID;
class ApplicationObjectFactory;
class ApplicationObject;
class ObjectDispatcher;
class MethodResult;
class GlishSysEvent;
template<class T> class Vector;
class LogSinkInterface;

// <summary>
// Link application objects to a server and the control bus
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class="ApplicationObjectFactory">ApplicationObjectFactory</linkto>
//   <li> General concepts about Glish and Application objects.
// </prerequisite>
//
// <etymology>
// This class <src>Control</src>s <src>Object</src>s embedded within it.
// </etymology>
//
// <synopsis>
// The tasking system ("distribute object" system) is fundamentally described
// in AIPS++ note #197. However, a few words here might be useful.
//
// The interaction with the application programmer will typically consist only
// of:
// <ol>
//    <li> Initializing the controller with <src>argc,argv</src> inside the
//         <src>main</src> program; and
//    <li> calling <src>addMaker()</src> for each class that you want to
//         allow the controller to be able to create.
// </ol>
//
// The ObjectController has the following "internal" functions as well:
// <ol>
//   <li> It handles the creation of distributed objects upon request
//        (i.e., over the Glish bus).
//   <li> Maintaining the list of created objects, and deleting them
//        when the controller exits.
//   <li> Hand off the parameters to the distributed object when a
//        method invocation is desired.
//   <li> Trap exceptions.
//   <li> Turn on and off tracing information for debugging.
//   <li> Attach the global logsink to 
//        <linkto class="GlishLogSink">GlishLogSink</linkto> so that log messages
//        will go to Glish, where they will typically appear in a GUI.
// </ol>
//
// At present, these internal functions are ordered up solely through
// events received over the Glish bus. We intend to allow unix command line
// control in the future. The events which are presently understood are:
// <center>
// <table border=1 width=0% cellpadding=6>
//    <tr bgcolor="#0000f0">
//       <th align=center colspan=5><font color="#FFFFFF">
//          <big>ObjectController Glish Protocol</big></font></th>
//    <tr bgcolor="#0000c0">
//      <th align=center colspan=2><font color="#ffffff"><b>Event (In)</b></font>
//      <th align=center><font color="#ffffff"><b>Value</b></font>
//      <th align=center><font color="#ffffff"><b>Event (Out)></b></font>
//      <th align=center><font color="#ffffff"><b>Value</b></font>
//   <tr>
//      <td><b>run</b>
//      <td> The run event is used to invoke ("run") a member function in
//           a distributed object. The object must already exist.
//      <td> A record, which must contain the sequence part of the ObjectID
//           in field _sequence, and the method name in _method. The other
//           fields of the record are the input arguments for the method.
//      <td><b>run_result</b>
//      <td> The same record with the output arguments filled in.
//   <tr>
//      <td><b>done/b>
//      <td> The done event is used to destruct an object which exists in
//           the current server.
//      <td> An ObjectID record.
//      <td><b>done_result</b>, an integer giving the number of remaining live
//          objects, or <b>error</b> if something has gone awry.
//      <td> The same record with the output arguments filled in.
//   <tr>
//      <td><b>run_async</b>
//      <td> Like run, except from the users point of view the method
//           is running asynchronously.
//      <td> Like run, with an additional _jobid field.
//      <td><b>run_result_async</b>
//      <td> The same as for run_result, except _jobid is reflected back as 
//           well.
//   <tr>
//      <td><b>create</b>
//      <td> Create an object of some class.
//      <td> A record. _type is the classname, _creator is the
//           constructor "name" (it can be ommitted if the default
//           constructor is the only one)
//      <td><b>create_result</b>
//      <td> A record containing the ObjectID mapped to _sequence, _pid,
//           _time and _host.
//   <tr>
//      <td><b>trace</b>
//      <td> Turn on (off) tracing information for debugging purposes. Also
//           sets the global logging filter to <b>DEBUGGING</b> (<b>NORMAL</b>).
//      <td> A Bool.
//      <td> None
//      <td> None
//   <tr>
//      <td>any
//      <td> After the controller discovers any error (e.g. exception),
//           it will return an error event. The value is a string with
//           the error message. 
//      <td>any
//      <td><b>error</b>
//      <td> String (error message)
//   <tr>
//      <td><b>choice</b>
//      <td> This event is in response to a get_choice event.
//      <td>The users choice (String)
//      <td><b>get_choice</b>
//      <td> [description=String, choices=StringVector]
//   <tr>
//      <td> <b>progress_result</b>
//      <td> This is in response to a get_progress event.
//      <td> A progress ID (integer).
//      <td> <b>get_progress</b>
//      <td> [min=double,max=double,title=string,subtitle=string,
//            minlabel=string, maxlabel=string, estimate=bool]
//   <tr>
// </table>
// </center>
// </synopsis>
//
// <example>
// Typically the use of this class will be when setting up an executable
// to serve one or more classes of distributed object.
// <srcBlock>
// #include <aips/Tasking.h>
// #include <your includes go here>
// 
// int main(int argc, char **argv)
// {
//     ObjectController controller(argc, argv);
//     controller.addMaker("squarer", new StandardObjectFactory<class1>);
//     controller.addMaker("squarer", new StandardObjectFactory<class2>);
//     controller.loop();
//     return 0;
// }
// </srcBlock>
// In the above example, this executable serves two classes, <src>class1</src>
// and <src>class2</src>. For more details read note #197.
// </example>
//
// <motivation>
// This class contains the fundamental connection between distributed objects and
// the communications system.
// </motivation>
//
// <todo asof="1997/05/19">
//   <li> Attach to the command line as well as to the Glish bus.
//   <li> Add explicit delete functionality when Glish gets something like
//        destructors.
//   <li> We might need to have more than one idle function at some point
//        in the future, or access to the object controller from within
//        the controller.
// </todo>

class ObjectController
{
public:
    // Implements an idle function protocol. If an idleFunction is set then it
    // is called every BasicTimeout when the server is otherwise idle.
    // The idleFunction return value indicates whether the idle function needs
    // to be called again (True). It is reset every time there is some activity.
    // The idle function can choose to do something more drastic if
    // LongIdleTime is exceeded.
    // 
    // Times are in millisec.
    // <group>
    typedef Bool (*IdleFunction)(Int elapsedTimeInMilliSec);
    void setIdleFunction(IdleFunction func = 0);
    // This function is called by the standard function. It relinquished locks
    // requested on Tables by other processes.
    static Bool relinquishLockIdleFunction(Int elapsedTime);
    // </group>


    // Initialize from the command line arguments. Also sets the global
    // LogSink to post messages to Glish, where they will typically
    // end up in a GUI.
    //
    // If globalSink is set, use if for the global sink, otherwise use
    // a GlishLogSink. The sink must come from the heap if it is set.
    //
    // The default constructor will automatically clear Table locks when idle,
    // however you can avoid this behaviour for servers with no tables
    // (i.e. avoid lining against tables) or other idle needs. If no idle loop
    // is needed, just set idleFunc to zero.
    // <group>
    ObjectController(int argc, char **argv, LogSinkInterface *globalSink=0);
    ObjectController(int argc, char **argv, LogSinkInterface *globalSink,
		     IdleFunction idleFunc);
    // </group>

    // Besides freeing up local resources, if Glish is no longer
    // connected to the process, sets the global LogSink to only pass SEVERE
    // messages, since the messages are just being dumped to stdout.
    ~ObjectController();

    // Add a maker (factory). Note that after calling addMaker, the controller
    // is responsible for deleting the pointer. You must not delete it yourself.
    // Besides the constructor, this is probably the only function you will
    // call.
    void addMaker(const String &typeName, ApplicationObjectFactory *fromNew);

    // If you want to, you can add a new object directory. This is typically
    // done by an object that wants to add another object to the controller.
    // The controller takes over responsibility for deleting the pointer, which
    // must have been allocated with new. The pointer is set to zero to reduce
    // the chances of it being accidentally deleted.
    ObjectID addObject(ApplicationObject *&fromNew);

    // Create an object of the given type and
    // constructor. <src>inputRecord</src> must have come from new, and will be
    // deleted by this function. If creation fails the returned ObjectID will be
    // null and errorMsg will be set.  Normally, application programmers will
    // not call this function.
    ObjectID createObject(const String &typeName, const String &whichCtor,
			  GlishRecord *&inputRecord, String &errorMsg);

    // Get the specified object. Returns a null pointer if it does not
    // exist. Do not delete the returned pointer! The object controller
    // will do it for you. Note that the entire object id must match, not
    // just the sequence number, which is all that is used by runMethod.
    // 
    // Normally, application programmers will not call this function.
    ApplicationObject *getObject(const ObjectID &id);

    // Return list of methods in this object
    Vector<String> methods(const ObjectID &id);

    // Normally, application programmers will not call this function.
    MethodResult runMethod(uInt whichObj, const String &method,
			   GlishRecord *&fromNew,
			   CountedPtr<GlishRecord> &result);

    // Destroy the given object if possible (i.e. if it exists). Returns the
    // number of remaining active objects.
    Bool done(uInt &numleft, String &error, const ObjectID &id);

    // Do we have a GUI available ? Usually False if environment
    // variable DISPLAY is not set.
    Bool hasGUI ();

    // Posts an "error" event containing <src>errorMessage.</src>
    // Normally, application programmers will not call this function.
    void postError(const String &errorMessage);

    // Run object methods until we're done
    // Normally, application programmers will not call this function.
    void loop();

    // Check or change the tracing status. Besides the controllers own
    // messages, Trace==True also puts the global log sink at DEBUG level. 
    // False turns it back to NORMAL
    // Normally, application programmers will not call this function.
    // <group>
    Bool trace() const;
    void trace(Bool doTrace);
    // </group>

    // Use the catalog viewer to view a file
    Bool view(String &name);

    // Attempt to make a plotter. If a plotter with the given name already
    // exists we return True (so that a plotter can be shared).
    Bool makePlotterIfNecessary(String &error, const String &name,
				uInt mincolors, uInt maxcolors,
                                uInt sizex, uInt sizey);

    // Send plot commands in the form created by
    // <linkto class="PGPlotterGlish">PGPlotterGlish</linkto>
    Bool sendPlotCommands(String &error, GlishValue &out, 
			  const String &plotName,
			  const GlishRecord &plot);

    // If isInteractive() and connected to Glish, get a choice from the user. IF
    // !isInteractive(), always return the first choice, so it should be the
    // default.  For example, if you are asking whether or not the user wants to
    // overwrite a file, the default should be "no". If choices is zero length,
    // always return the empty string.
    String choice(const String &descriptiveText, const Vector<String> &choices);

    // If isInteractive() and connected to Glish, get a choice from the user. If
    // !isInteractive(), always return False, else check to see if the user
    // has told this object to stop.
    Bool stop();

    // <group>
    Int makeProgressDisplay(Double min, Double max, 
			    const String &title, const String &subtitle,
			    const String &minlabel, const String &maxlabel, 
			    Bool estimateTime = True);
    void updateProgressDisplay(Int id, Double value);
    // </group>

    // Send our controlling process an event named memory with the value
    // of our memory use in MB.
    void sendMemoryUse();

    // Carry out the nitty-gritty details of handling the particular events.
    // Normally these methods will only be called from loop(), but they can
    // be called explicitly if desired for testing or other purposes.
    // Normally, application programmers will not call this function.
    // <group>
    void handleEvent(GlishSysEvent &event);
    void handleRun(GlishSysEvent &event, Bool async);
    void handleCreate(GlishSysEvent &event);
    void handleTrace(GlishSysEvent &event);
    void handleMethods(GlishSysEvent &event);
    void handleDone(GlishSysEvent &event);
    void handleUnrecognized(GlishSysEvent &event);
    // </group>

    // Under very rare conditions you might want to change the global logsink
    // after creation. You can do so with this function. The default (=0) is
    // to attach the global logsink to Glish (i.e. the normal logging function).
    void setGlobalLogSink(LogSinkInterface *globalSink=0);
private:
    // Common constructor code
    void init(int argc, char **argv, LogSinkInterface *globalSink,
	      IdleFunction idleFunc);

    CountedPtr<GlishSysEventSource> event_source_p;
    SimpleOrderedMap<String, void *> makers_p;


    // ObjectID.sequence() sets the location where the objects are stored.
    // Not a good strategy if sequence doesn't start near 0 and is nearly
    // contiguous, but that should be the case.
    PtrBlock<ObjectDispatcher *> objects_p;

    // Tracing name?
    Bool trace_p;
    
    // Only used on exit
    // <group>
    String server_name_p;
    Timer total_timer_p;
    // </group>

    // Get a factory by name.
    ApplicationObjectFactory *maker(const String &which);
    // Get a factory by (0-relative) index.
    ApplicationObjectFactory *maker(uInt which);
    // How many makers do we have anyway?
    Int n_makers() const;

    // Send log messages here.
    LogIO log_p;

    // Idle function
    IdleFunction idle_func_p;
    static Int basicTimeout;       // in millisec
    static Int longIdleTime;       // in millisec

    // Disallow copying and assignment
    // <group>
    ObjectController(const ObjectController &);
    ObjectController &operator=(const ObjectController &);
    // </group>

};

//# Inlines

inline Bool ObjectController::trace() const
{
    return trace_p;
}


} //# NAMESPACE CASA - END

#endif
