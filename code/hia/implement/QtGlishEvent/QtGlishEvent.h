//# QtGlishEvent.h: wrapper to combine Qt and Glish events
//# Copyright (C) 1994,1995,1997,1998,1999,2001
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

#if !defined(AIPS_QTGLISHEVENT_H)
#define AIPS_QTGLISHEVENT_H


#include <Glish/Client.h>
#include <casa/Exceptions/Error.h>
#include <tasking/Glish/GlishEvent.h>

#include <qapp.h>
#include <qwidget.h>
#include <qsocketnotifier.h>


#include <casa/namespace.h>
// <summary>
// wrapper class to combine Glish and Qt event handling
// </summary>
//
// <use visibility=export>
// <reviewed reviewer="" date="" tests="">
//
// <prerequisite>
//	<li> GlishSysEventSource
// </prerequisite>
//
// <etymology>
//	<em> A class to allow the combining of glish events with the Qt widget library </em>
// </etymology>
//
// <synopsis> 
//	This class provides a wrapper around glish and Qt events.
//
//      One can use this class to write glish clients that can interact with
//      a user by means of the Qt widget set <linkto http://www.trolltech.com</linkto>.
//
//      <note role=tip> This class is only useful if you wish to combine the Qt widget
//          with a compiled glish client that uses an event-driven interface.
//      </note>
//
// </synopsis> 
//
// <a name=event_example>
// <example>
//     This is an example of how this class might be used. It demonstrates
//     how Glish and Qt widget events can be cleanly combined into one event
//     stream. Sending a glish <src>make_button</src> event to this client will cause
//     a button labelled <src>quit</src> to appear on the screen. When the user clicks
//     on the button it will cause the client to exit.
// <srcblock>
// #include <qapplication.h>                           //   1
// #include <qpushbutton.h>                            // 
// #include <tasking/Glish.h>                             //
// #include <hia/QtGlishEvent/QtGlishEvent.h>          //    
//                                                     //
// QApplication *QAppAddress = NULL;                   //   2
// QPushButton *quit = NULL;                           //
//                                                     //
// Bool make_button(GlishSysEvent &event, void *)      //   3
// {                                                   //
//   if (!quit) {                                      //   4
//     quit = new QPushButton( "Quit", 0 );            //   5
//     QObject::connect( quit, SIGNAL(clicked()),      //   6
//       QAppAddress, SLOT(quit()) );                  //
//     (*quit).show();                                 //   7
//     GlishSysEventSource *src = event.glishSource(); //   8
//     src->postEvent ("created_button","");           //
//   }                                                 //
//   else{                                             //
//     GlishSysEventSource *src = event.glishSource(); //   9
//     src->postEvent ("already_created_button","");   //
//   }                                                 //
//   return True;                                      //
// }                                                   //
//                                                     //
// int main( int argc, char **argv )                   //   
// {                                                   //
//   QtGlishSysEventSource qt_stream(argc, argv);      //  10
//   qt_stream.addTarget (make_button, "make_button"); //  11
//   QAppAddress = new QApplication(argc, argv);       //  12
//   return (*QAppAddress).exec();                     //  13
// }                                                   //
// </srcblock>
// <ol>
//     <li> These are the Qt and glish related includes required by this 
//          particular example.
//     <li> Initialize global pointers to the Qt classes to NULL values. We define
//          these pointers outside the callback functions so that the widgets 
//          will remain alive when a callback is exited.
//     <li> This is the typical layout for a Glish callback. 
//     <li> A test to ensure that we only create a new button once.
//     <li> Create a new instance of a QPushButton and give it a <src>quit</src> label.
//     <li> A simple example of using the Qt signals and slots mechanism. Here we tell
//          the system that when a user clicks on the button labelled <src>quit</src> it 
//          should transfer control to the QApplication's quit function (and therefore 
//          close down this client).
//     <li> Cause the widget to be displayed on the screen.
//     <li> Post a glish event to let a calling script know that the button has been
//          created.
//     <li> If the button had already been created previously, post this message.
//     <li> Create a QtGlishSysEventSource object that can handle both Qt and
//          glish events.
//     <li> This line sets up the Glish callback. When the client receives 
//          a <src>make_button</src> event, control is transferred to the make_button 
//          callback.  
//     <li> Instantiate an instance of a QApplication and.
//          assign its address to the QAppAddress pointer so that the make_button
//          function knows where to connect the signals and slots.
//     <li> Start the Qt event loop. The QtGlishSysEventSource object ensures
//          that the Qt event loop also now handles and dispatches glish events
//          correctly.
// </ol>
// </example>
// </a>

class QtGlishSysEventSource : public QObject, public GlishSysEventSource {
        Q_OBJECT   // required for signals/slots


private:
	// data used in this class
	fd_set _glish_select_set; // active glish file descriptors
	Bool _First; // boolean to control updating of file descriptors

        // update list of glish file descriptors known to Qt
// <srcblock>
        // if _First == true
        //         set _First to false.
        //         zero the glish file descriptor set.
        //         find out which file descriptors have been opened by this client.
        //         Add the glish file descriptors to the list known to Qt
        // else
        //         use a temporary fd_set to find out which glish file
        //                 descriptors have just been set
        //         add the new file descriptors to the list known to Qt
        //         if new file descriptors were found, copy the temporary fd_set
        //                 to the permanent fd_set.
// </srcblock>
	void   update_glish_fds();
	
        // copy constructor set private: we should never need more than one
        // object of type QtGlishSysEventSource per client							   
	QtGlishSysEventSource(const QtGlishSysEventSource&); //copy constructor
        

public: 

	// constructor
// <srcblock>
        // pass argc and argv parameters to GlishSysEvent parent class.
        // set status variable _First to True.
        // call method update_glish_fds to add glish client file descriptor
        //         to list that Qt will handle.
// </srcblock>
    	QtGlishSysEventSource(int &argc,char **argv);

    	// destructor
	~QtGlishSysEventSource();

public slots:

        // handle an incoming glish event from Qt event loop
// <srcblock>
        // If the client is connected to glish
        //        handle the next glish event
        //        check if file descriptors should be updated
        // else
        //        a glish shutdown event was previously received, so exit

        // The Qt event handler is told to send control to this method when
        // any file descriptor associated with a glish event is active.
// </srcblock>
       	void QtHandleGlishSysEventSource();
};

#endif // if !defined(AIPS_QTGLISHEVENT_H)
