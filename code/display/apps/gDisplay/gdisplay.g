# gdisplay.g: display library widget loader
# Copyright (C) 1999,2000,2001,2002
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: gdisplay.g,v 19.2 2005/06/15 18:09:13 cvsmgr Exp $

pragma include once;

load_gdisplay := function(intowhichgtk) {

    local displayinit := func(whichgtk, ref rec) {
	
	# "pixelcanvas"
	pixelcanvas := func(parent, width=300, height=200, 
			    relief='sunken', borderwidth=2, 
			    padx=20, pady=20, foreground='white',
			    background='black', fill='both',
			    mincolors=32, maxcolors=96,
			    maptype='index')
	  whichgtk->pixelcanvas(parent, width, height, relief, borderwidth,
				padx, pady, foreground, background, fill,
				mincolors, maxcolors, maptype);
	rec.pixelcanvas := pixelcanvas;
	 
	# "displaydata"
	displaydata := func(displaytype, data, datatype)
	  whichgtk->displaydata(displaytype, data, datatype);
	rec.displaydata := displaydata;
	
	# "colormap"
	colormap := func(name='<default>')
	    whichgtk->colormap([a=name]);
	rec.colormap := colormap;
	
	# "pspixelcanvas"
	pspixelcanvas := func(filename='pspixelcanvas.ps', media='A4',
			      landscape=F, aspect=1.0, dpi=100, 
			      zoom=1.0, eps=F, colors=80, maptype='index')
	  whichgtk->pspixelcanvas(filename, media, landscape, aspect, dpi,
				  zoom, eps, colors, maptype);
	rec.pspixelcanvas := pspixelcanvas;
	
	# "drawingdisplaydata"
	drawingdisplaydata := func() 
	  whichgtk->drawingdisplaydata();
	rec.drawingdisplaydata := drawingdisplaydata;

	# "paneldisplay"
	paneldisplay := func(parent, nx=1, ny=1, xorigin=0.0,
			     yorigin=0.0, xsize=1.0, ysize=1.0,
			     dx=0.0, dy=0.0, foreground='white',
			     background='black')
	    whichgtk->paneldisplay(parent, nx, ny, xorigin, yorigin,
				   xsize, ysize, dx, dy, foreground,
				   background);
	rec.paneldisplay := paneldisplay;
	
	# "information"
	information := func()
	    whichgtk->information();
	rec.information := information;
	
	# "annotations"
	annotations := func(parent, mousebutton = Display::K_Pointer_Button1,
			    useEventHandlers = T)
	    whichgtk->annotations(parent, mousebutton,
				  useEventHandlers);
	rec.annotations := annotations;
	

	# "mwcanimator"
	mwcanimator := func()
	  whichgtk->mwcanimator();
	rec.mwcanimator := mwcanimator;

	slicepd := func(parent)
	  whichgtk->slicepd(parent);
	rec.slicepd := slicepd;
	
    }

    tmp := intowhichgtk.tk_load('gDisplay.__SFXSHAR', displayinit);
    if (is_fail(tmp)) {
	tmp2 := eval('include \'note.g\'');
	note(spaste('The AIPS++ Display Library could not be dynamically loaded:\n',
		    tmp::message), priority='SEVERE', origin='gdisplay.g');
    }

    return T;
}

load_gpgplot := function(intowhichgtk) {
    
    local pgplotinit := func(whichgtk, ref rec) {
	
	# "pgplot"
	pgplot := func(parent=spaste('"/tmp/pgplot',system.pid,'.ps"/PS'), 
		       width=200, height=150, region=[-100,100,-100,100], 
		       axis=-2, nxsub=1, nysub=1, relief='sunken', 
		       borderwidth=2, padx=20, pady=20,
		       foreground='white', background='black', fill='both', 
		       mincolors=2, maxcolors=100, cmapshare=F, cmapfail=F )
	    whichgtk->pgplot(parent, width, height, region, axis, nxsub,
			nysub, relief, borderwidth, padx, pady,
			foreground, background, fill, mincolors,
			maxcolors, cmapshare, cmapfail);
	rec.pgplot := pgplot;
    }

    tmp := intowhichgtk.tk_load('gPgplot.__SFXSHAR', pgplotinit, F);
    if (is_fail(tmp)) {
	tmp := eval('include \'note.g\'');
	note(spaste('The AIPS++ Display Library could not be dynamically ',
		    'loaded for unknown\nreason/s'), priority='SEVERE', 
	     origin='gdisplay.g');
    }

    return T;
}

# Enumerations from Display/DisplayEnums.h
Display := 1;
# Display::KeySym
const Display::K_Pointer_Button1 := 65257; # 0xFEE9
const Display::K_Pointer_Button2 := 65258; # 0xFEEA
const Display::K_Pointer_Button3 := 65259; # 0xFEEB
const Display::K_space := 32;              # 0x0020
# Display::DisplayDataType
const Display::Raster := 0;
const Display::Vector := 1;
const Display::Annotation := 2;
const Display::CanvasAnnotation := 3;
# make const
const Display := Display;

# load display library into default gtk (dgtk).  Remove this stmt
# when transition to dl-specific ddlgtk and ddlws is complete.  
# REMOVED DBARNES 2000/09/29 - fingers crossed that this works!!!
# tmp := load_gdisplay(dgtk);
