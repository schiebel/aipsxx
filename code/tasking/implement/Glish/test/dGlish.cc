//# dGlish.cc: A small demonstration program of the Glish wrapper classes
//# Copyright (C) 1994,1995,1999,2000,2002
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: dGlish.cc,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

// Demonstration of AIPS++ Glish wrapper classes that sorts arrays (treating
// them as if they were 1-dimensional) and returns the result. Although this is 
// simple, Glish does not have built in sort functions so it is immediately 
// useful. Of course we should have options for specifying the order, what to do
// with duplicates, the type of sort to do, etc.
//
// This is set up to operate asynchronously, i.e. the result is sent via 
// postEvent rather than reply. This is probably in general the best thing
// to do, then the Glish user has the option if he wants to use the 
// functionality synchronously or asynchronously.
//
// Here's an example of how to package this demonstration to Glish users.
//
// __sort_client := client("dGlish");                                   #  1
// sort := function(const array)                                        #  2
// {                                                                    #  3
//    send __sort_client->sort(array);                                  #  4
//    await__sort_client->*; # Appears to operate synchronously         #  5
//    return $value;                                                    #  6
// }                                                                    #  7
//                                                                      #  8
// a := [100:1]                                                         #  9
// sort(a)                                                              # 10
// a[1:100] := 3+4i # complex                                           # 11
// sort(a)                                                              # 12
//
//  1 -  Create a client that will be used for communications with this
//       program, which  must be in the users PATH environment variable.
//       I use double underscores to prevent name collisions with user
//       variables (a convention).
//  2 -  Declare a Glish function named sort, with one argument named "array",
//       passed by const reference (i.e., it won't be changed).
//  4 -  Send the client an event named "sort" containing the array.
//  5 -  Although the underlying mechanism is asynchronously, this function
//       makes it appear to operate synchronously. If the user really wants
//       asynchronous sorts, he may use __sort_client explicitly, or the sort
//       function could be changed.
//  6 -  Return to the user the value returned by the server program, either
//       the sorted array or an error message.
//  9 -  Create an array with the values 100,99,98,...,1.
// 10 -  Sort the array; returns 1,2,...,99,100.
// 11 -  Create an array of complex numbers
// 12 -  Sort it; returns an error message (sorting of Complex is not defined
//       by this program).
//
// This small demonstration program of course cannot be an adequate tutorial
// for Glish programming in general. The glish distribution has an excellent
// user manual. The master version of Glish may be found at:
// ftp://ee.lbl.gov/glish/
//
// The AIPS++ version of Glish is found at:
// ftp::/aips2.cv.nrao.edu/pub/aips++/RELEASED/glish/
//
// At the time of this writing (27OCT94), the AIPS++ changes to Glish
// (multidimensional arrays, complex numbers, and command line editing) have
// not yet been merged back into the mainline Glish release.
//
// Event interface
// ---------------
//
// Name/Direction         Structure
// sort/IN                Array<T>
// sort_result/OUT        Vector<T> | ERROR message
//
// sort_error/OUT         ERROR message

#include <casa/BasicSL/String.h>
#include <tasking/Glish.h>
#include <casa/Arrays/ArrayIO.h>
#include <casa/Arrays/Vector.h>
#include <casa/Utilities/GenSort.h>
#include <casa/Exceptions/Error.h>
#include <casa/iostream.h>

#include <casa/namespace.h>
int main(int argc, char **argv)
{
    GlishSysEventSource eventStream(argc, argv);
    GlishSysEvent event;
    
    while(eventStream.connected()) {
	try {
	    event = eventStream.nextGlishEvent();   // Get an event - blocks
	    if (event.type() == "sort") {
		GlishValue sortVal = event.val();
		if (sortVal.type() != GlishValue::ARRAY) {
		    // Oops - we weren't sent an array; complain and continue
		    eventStream.postEvent("sort_error", 
					  "Non array sent for sort");
		}
		// OK; let's sort the array.
		GlishArray sortArray = sortVal;
		// OK; get it into an AIPS++ array and do the physical sort.
		// We could likely use a template function or macro to avoid
		// some code duplication below.
		switch(sortArray.elementType()) {
		case GlishArray::BOOL:
		    {
			Vector<Bool> vec(sortArray.nelements());
			sortArray.get(vec);
			GenSort<Bool>::sort(vec);
			eventStream.postEvent(String("sort_result"), vec);
			sortArray.reset();
		    }
		    break;
		case GlishArray::INT:
		    {
			Vector<Int> vec(sortArray.nelements());
			sortArray.get(vec);
			GenSort<Int>::sort(vec);
			eventStream.postEvent("sort_result", vec);
			sortArray.reset();
		    }
		    break;
		case GlishArray::FLOAT:
		    {
			Vector<Float> vec(sortArray.nelements());
			sortArray.get(vec);
			GenSort<Float>::sort(vec);
			eventStream.postEvent("sort_result", vec);
			sortArray.reset();
		    }
		    break;
		case GlishArray::DOUBLE:
		    {
			Vector<Double> vec(sortArray.nelements());
			sortArray.get(vec);
			GenSort<Double>::sort(vec);
			eventStream.postEvent("sort_result", vec);
			sortArray.reset();
		    }
		    break;
		case GlishArray::COMPLEX:
		case GlishArray::DCOMPLEX:
		    {
			// AIPS++ can sort an array of c omplex (based on the 
			// norm), but strictly speaking it doesn't make sense.
			eventStream.postEvent("sort_result", 
					      "Cannot sort complex");
		    }
		    break;
		case GlishArray::STRING:
		    {
			Vector<String> vec(sortArray.nelements());
			sortArray.get(vec);
			cout << "Unsorted : " << vec << endl;
			GenSort<String>::sort(vec);
			cout << "Sorted : " << vec << endl;
			eventStream.postEvent("sort_result", vec);
			sortArray.reset();
		    }
		    break;
		default:
		    eventStream.postEvent("sort_result", "unknown type");
		}
	    } else if (event.type() != "shutdown") {
		// We don't understand what this event is!
		eventStream.unrecognized();
	    }
	} catch (AipsError x) {
	    // We don't handle any exceptions; return them as an error
	    eventStream.postEvent("sort_error", x.getMesg());
	} 
    }
    return 0;
}
