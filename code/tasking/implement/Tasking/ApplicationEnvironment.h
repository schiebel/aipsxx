//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,1998,2000,2001,2002
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
//# $Id: ApplicationEnvironment.h,v 19.6 2004/11/30 17:51:11 ddebonis Exp $

#ifndef TASKING_APPLICATIONENVIRONMENT_H
#define TASKING_APPLICATIONENVIRONMENT_H

#include <casa/aips.h>
namespace casa { //# NAMESPACE CASA - BEGIN

class ObjectController;
template<class T> class Vector;
class String;
class PGPlotter;
class ObjectID;

//# Do not depend on this typedef, it might change!
typedef String PlotDevice;

// <summary>
// </summary>

// <use visibility=local>   or   <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
//   <li> SomeOtherClass
//   <li> some concept
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//
// <templating arg=T>
//    <li>
//    <li>
// </templating>
//
// <thrown>
//    <li>
//    <li>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
//   <li> add this feature
//   <li> fix this bug
//   <li> start discussion of this possible extension
// </todo>

class ApplicationEnvironment
{
public:
    // Hints
    static Bool isInteractive();

    // Do we have a GUI available ?  Usually False if DISPLAY environment variable is unset.
    static Bool hasGUI();

    // View a table
    static Bool view(String &name);

    // If isInteractive() and connected to Glish, get a choice from the user. If
    // !isInteractive(), always return False, else check to see if the user
    // has told this object to stop.
    static Bool stop();

    // If isInteractive() and connected to Glish, get a choice from the
    // user. IF !isInteractive(), always return the first choice, so it should
    // be the default.  For example, if you are asking whether or not the user
    // wants to overwrite a file, the default should be "no". If choices is
    // zero length, always return the empty string.
    static String choice(const String &descriptiveText,
			 const Vector<String> &choices);

    // Register the create function for a PGPlotter object, so it is
    // created in the correct way.
    // It has to be done for each Glish client using PGPlotter.
    static void registerPGPlotter();

    // Get the default device specification that corresponds to
    // some ObjectID.
    // 
    // Presently, the rules are as follows:
    // <ol>
    //    <li> If aipsrc variable user.plot.device is found, it is used. 
    //         It is a PGPLOT style device representation, with the additional
    //         "device"<src>/glish</src>, which sends the plot commands to a
    //         Glish PGPlotter if possible. Question marks (?) are turned into
    //         unique file names, e.g. <src>plot_?.ps/ps</src> becomes
    //         <src>plot_1.ps</src>, <src>plot_2.ps</src> etc. for
    //         consecutive plots.
    //    <li> If a user device isn't specified, 
    //         <src>aipsplot_?.plot/glish</src> is tried if we are attached
    //         to glish, otherwise <src>/XS</src> (X-windows server) is tried,
    //         otherwise <src>aipsplot_?.ps/cps</src> is tried if no DISPLAY
    //         environment variable is set.
    //    <li> If all else fails, use /NULL.
    // </ol>
    static PlotDevice defaultPlotter(const ObjectID &id);

    // Get the plotter corresponding to the device specification. Applications
    // should be able to deal with the case where plotting isn't possible for
    // some reason, i.e. you should check that <src>isAttached()</src> is
    // <src>True.</src>
    static PGPlotter getPlotter(const PlotDevice &which);

    // Create a PGPlotter object according to the given device and so.
    // It is a function which can be registered in PGPlotter as the create
    // function.
    // <br>Open "device", which must be a valid PGPLOT style device.
    // For example, <src>/cps</src> for colour postscript,
    // (or <src>myfile.ps/cps</src> if you want to name the file),
    // or <src>/xs</src> or <src>/xw</src> for an X-windows display.
    //
    // If your plot cannot back-off gracefully to black and white, you should
    // set <src>mincolors</src> to the minimum number of colors your plot
    // needs to succeed. Generally you should only need to do this for
    // color-raster displays. Similarly, if you know the maximum number of
    // colors you will use, you can prevent colormap flashing by setting
    // <src>maxcolors</src>. If the device cannot supply at least
    // <src>mincolors</src>, <src>isAttached</src> will return False.
    // <thrown>
    //   <li> An <linkto class="AipsError">AipsError</linkto> will be thrown
    //        if the underlying PGPLOT open fails for some reason.
    // </thrown>
    static PGPlotter createPlotter (const String &device,
				    uInt mincolors=2, uInt maxcolors=100,
				    uInt sizex=600, uInt sizey=450);

    // So you can get DO's, etc. Returns null if this process does not have
    // a controller. If the process has more than one controller returns the
    // most recent one created. Do not delete this pointer.
    static ObjectController *objectController();
    
    friend class ObjectController;
private:
    static ObjectController *the_controller_p;


    // <src>makeProgressDisplay</src> returns an id for a "progress bar" which
    // can be updated with </src>updateProgressDisplay</src>. If the session is
    // not interactive, a null id will be returned and updates will be no-ops.
    // Null strings for the various labels will result in default labels. In
    // particular, if minlabel and maxlabel are empty they will be set to the
    // min and max values.
    //
    // Progress bar updates are relatively inefficient, so you should try not
    // to send them at the rate of more than probably few a second. The
    // progress bar will automatically remove itself when it hits
    // <src>max</src>, so updates after an update of "max" has been sent will
    // not be visible.
    //
    // Note that if min is in fact larger than max, the progress bar will still
    // work correctly (counting down instead of up).
    // <group>
    static Int makeProgressDisplay(Double min, Double max, 
			   const String &title, const String &subtitle,
			   const String &minlabel, const String &maxlabel, 
			   Bool estimateTime = True);
    static void updateProgressDisplay(Int id, Double value);
    // </group>
};

//# Inlines -----------------------------------------------------------------
inline ObjectController *ApplicationEnvironment::objectController()
{
    return the_controller_p;
}


} //# NAMESPACE CASA - END

#endif
