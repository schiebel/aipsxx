//# QtGlishEvent.cc: Wrapper for combined Qt and glish events
//# Copyright (C) 2000,2001
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
//# This particular code also subject to the conditions of the Q Public 
//# License (http://www.trolltech.com/qpl/index.html) as it contains 
//# components of the Qt widget library 

//# Includes

#include <casa/Containers/List.h>
#include <casa/Utilities/CountedPtr.h>
#include <hia/QtGlishEvent/QtGlishEvent.h>

//# To shut up cpp
#undef List

/*+
Routine name:
	QtGlishSysEventSource

Function:
	constructor

Method:
	pass argc and argv parameters to GlishSysEvent parent class.
	set status variable _First to True.
	call method update_glish_fds to add glish client file descriptor
		to list that Qt will handle.
Language:
	c++


Visibility:
	Public

Call:
	(void) qtGlishSysEventSource(argc, argv)

Parameters:   ( (I) Input)
(I) argc (int &) number of arguments
(I) argv (char **) argument parameters
*-
*/
QtGlishSysEventSource::QtGlishSysEventSource(int &argc,char **argv)
	:GlishSysEventSource(argc,argv) 
{
  
 try {
    _First = True;
    update_glish_fds();
  } catch (AipsError x) {
    String message = x.getMesg();
    message.prepend ("QtGlishSysEventSource::QtGlishSysEventSource|");
    throw (AipsError(message));
  }
}

/*+
Routine name:
	update_glish_fds

Function:
	updates list of glish file descriptors known to Qt

Method:
	if _First == true
		set _First to false.
		zero the glish file descriptor set.
		find out which file descriptors have been opened by this client.
		Add the glish file descriptors to the list known to Qt
	else
		use a temporary fd_set to find out which glish file
			descriptors have just been set
		add the new file descriptors to the list known to Qt
		if new file descriptors were found, copy the temporary fd_set
			to the permanent fd_set.
Language:
	c++

Visibility:
	Public

Call:
	(void) update_glish_fds()

Parameters:   ( (I) Input)
*-
*/
void QtGlishSysEventSource::update_glish_fds()
{
 try {
   if (_First) {
	_First = False;
	FD_ZERO(&_glish_select_set);
    	int num = client_->AddInputMask(&_glish_select_set);
    	for ( int cnt=0; num && cnt < FD_SETSIZE; ++cnt )
             if ( FD_ISSET(cnt,&_glish_select_set) )
                     {
   			QSocketNotifier *sn;
   			sn = new QSocketNotifier(cnt,QSocketNotifier::Read);
			QObject::connect(sn, SIGNAL(activated(int)),this,SLOT(QtHandleGlishSysEventSource()));
                        --num;
                     }
   }
   else {
	Bool updated = False;
   	fd_set temp_fd_set;
   	temp_fd_set = _glish_select_set;
   	int num = client_->AddInputMask(&temp_fd_set);
   	for ( int cnt=0; num && cnt < FD_SETSIZE; ++cnt ) {
		// if not set, go to next fd
		if ( !FD_ISSET(cnt,&temp_fd_set) ) continue;

		// if set, has it already been set previously
        	if ( FD_ISSET(cnt,&_glish_select_set ) )  continue;

		// not already set, so add a new QSocketNotifier
   		QSocketNotifier *sn;
   		sn = new QSocketNotifier(cnt,QSocketNotifier::Read);
		QObject::connect(sn, SIGNAL(activated(int)),this,SLOT(QtHandleGlishSysEventSource()));
		updated = True;
        	--num;
   	}
	if (updated)
   		_glish_select_set = temp_fd_set;
  }
  } catch (AipsError x) {
    String message = x.getMesg();
    message.prepend ("QtGlishSysEventSource::update_glish_fds|");
    throw (AipsError(message));
  }
}

/*+
Routine name:
	QtHandleGlishSysEventSource

Function:
	handle an incoming glish event from Qt event loop 

Method:
	If the client is connected to glish
		handle the next glish event
		check if file descriptors should be updated
	else
		a glish shutdown event was previously received, so exit

	The Qt event handler is told to send control to this method when
	any file descriptor associated with a glish event is active. 

Language:
	c++

Visibility:
	Public

Call:
	(void) QtHandleGlishSysEventSource()

Parameters:   ( (I) Input)
*-
*/
void QtGlishSysEventSource::QtHandleGlishSysEventSource()
{
 try {
// while connected to glish
   if (connected()) {
   	GlishEvent *ev;
   	int timedout;

   	ev = nextPrimitiveEvent(0, timedout);

// ignore events generated by 'link' operator
//	cout<<"QtGlish handling event "<<ev->Name()<<endl; cout.flush();
   	if (strcmp(ev->Name(),"*rendezvous-resp*" ) == 0 ) 
		update_glish_fds();
	else {
   		if ( ! invokeTarget(ev) && strcmp(ev->Name(),"shutdown" ) )
            		client_->Unrecognized();
		update_glish_fds();
	}
   }
   else
//  disconnected from glish so exit
	exit(0);
  } catch (AipsError x) {
    String message = x.getMesg();
    message.prepend ("QtGlishSysEventSource::QtHandleGlishSysEventSource|");
    throw (AipsError(message));
  }
}

// let destructors of parent classes do the work
QtGlishSysEventSource::~QtGlishSysEventSource() 
{
}
