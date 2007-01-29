//# DramaGlishEvent.h: Drama + Glish event wrappers
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

#if !defined(AIPS_DRAMAGLISHEVENT_H)
#define AIPS_DRAMAGLISHEVENT_H

// DRAMA crap
#include <DitsTypes.h>      /* For basic Dits types */
#include <DitsSys.h>        /* For Dits system routines         */
#include <DitsFix.h>        /* Fixed part details   */
#include <Ers.h>            /* For Ers routines     */
#include <mess.h>           /* For Mess routines    */
#include <DitsMsgOut.h>     /* for MsgOut                       */
#include <DitsInteraction.h>             

#include <Glish/Client.h>
#include <tasking/Glish/GlishEvent.h>

#include <casa/namespace.h>
//<summary>
// wrapper class to combine Drama and Glish event handling
//</summary>

// <etymology>
//      <em> A class to allow the combining of DRAMA and glish events </em>
// </etymology>

// <synopsis>
//      This class provides a wrapper around glish and DRAMA events.

//	This class inherits from GlishSysEventSource and allows one
//	to combine Drama and glish event looping under overall
//	control of the Drama DitsAltInLoop function.
// </synopsis>                           

class DramaGlishSysEventSource : public GlishSysEventSource 
{
private:
	// data elements
	fd_set _glish_select_set;   // active glish file descriptors
	int _num_glish_connects;    // number of glish file descriptors connected
	Bool   _First;  // boolean to control updating of file descriptors        
	DitsAltInType _DramaFd;     // file descriptor type for Drama                                                      


public: 
	// constructor
//<srcblock>
	// pass argc and argv parameters to GlishSysEvent parent class.
        // set status variable First to True.
        // call method update_glish_fds to add glish client file descriptor
        //       to list that Drama will handle.
//</srcblock>
    	DramaGlishSysEventSource(int &argc,char **argv, StatusType* status);

	// destructor - does nothing so destruction handled by parent class
    	~DramaGlishSysEventSource();

        // handle combined glish and Drama event looping
//<srcblock>
        // call Drama function DitsAltInLoop to do looping               
//</srcblock>
    	Bool loop(StatusType* status);

        // update list of glish file descriptors known to Drama
//<srcblock>
	// if First == true
        //    set First to false.
        //      zero the glish file descriptor set.
        //      find out which file descriptors have been opened by this client.
        //        clear the DitsAltInType variable v.
        //        Add the glish file descriptors to the list known to Drama
        // else
        //        use a temporary fd_set to find out which glish file
        //                descriptors have just been set
        //        add the new file descriptors to the list known to Drama
        //        if new file descriptors were found, copy the temporary fd_set
        //                to the permanent fd_set.
//</srcblock>
    	void update_glish_fds(StatusType* status);

	//delete knowledge of Glish file descriptors from DRAMA
	void delete_glish_fds(StatusType* status);
};

#endif //define AIPS_DRAMAGLISHEVENT_H 

