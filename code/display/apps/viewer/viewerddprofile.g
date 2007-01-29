# viewerddprofile.g: Viewer Display Data Profile
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: viewerddprofile.g
#
# Emits events:


pragma include once

include 'clipboard.g'
include 'note.g'
include 'quanta.g'
include 'profilewidthentry.g'
include 'regionmanager.g'
include 'serverexists.g'
include 'unset.g'
#
include 'image.g'
include 'widgetserver.g'

## ************************************************************ ##
##                                                              ##
## VIEWERDDPROFILE SUBSEQUENCE                                  ##
##                                                              ##
## ************************************************************ ##
const viewerddprofile := subsequence (dd)
{
    if (!serverexists('dcb', 'clipboard', dcb)) {
       return throw('The clipboard server "dcb" is not running',
                     origin='viewerddprofile.g');
    }
    if (!serverexists('dq', 'quanta', dq)) {
       return throw('The clipboard server "dq" is not running',
                     origin='viewerddprofile.g');
    }
#
    its.dd := [=];          # display data to be profiled
    its.pdd := [=];         # Profile display data
    its.dp := [=];          # display panel for profiles

### Private methods

    const its.add := function (newdd) 
    {
	wider its;
# Add new Dd
	if(shape(its.dd) == 0) {
	    its.dd := newdd;
	} else {
	    fail;
	}
	title := paste('Profile Viewer:', its.dd.name());
	const pv := viewer(title);
	its.pdd := pv.loaddata(its.dd,'profile');
	if (is_fail(its.pdd) || !is_agent(its.pdd)) fail;
	return T;
    }

    
### Public methods
    
    const self.gui := function ()
    {
	wider its;

	if (shape(its.dd) == 0) {
	    return F;
	}

	if (!is_agent(its.dp)) {	# not created yet.
	    pv := its.pdd.viewer();
	    its.dp := pv.newdisplaypanel(width=500,height=300,nx=1,ny=1, show=F,
					 guihasmenubar=F, guihascontrolbox=F,
					 guihasanimator=F, hasdismiss=T,
					 hasdone=F);
	    its.dp.register(its.pdd);
	}

	its.dp.map();
	return T;
    }
###
    self.refresh := function ()
    {

	# Remove profile2dDD from the panel, create a new one and load
	# it into the panel.
	wider its;

	if (shape(its.dd) != 0) {
	    if (is_agent(its.dp)) {
		its.dp.disable();
		its.dp.unregister(its.pdd);
	    }
	    pv := its.pdd.viewer();
	    its.pdd.done();
	    its.pdd := pv.loaddata(its.dd,'profile');
	    if (is_agent(its.dp)) {
		its.dp.register(its.pdd);
		its.dp.enable();
	    }
	    return T;
	}
	else {
	    fail;
	}
    }
###
    const self.dismiss := function ()
    {
	wider its;
	if (is_agent(its.dp)) {
	    its.dp.dismiss();
	    return T;
	}
	else {
	    return F;
	}
    }
###
    const self.done := function () 
    {
	wider its, self;

	if (is_agent(its.dp)) {
	    its.dp.done();
	}
	its.dp := [=];

	if (shape(its.dd) != 0) {
	    its.dd := [=];
	}
	if (is_agent(its.pdd)) {
	    its.pdd.done();
	    its.pdd := [=];
	}

	val its := F;
	val self := F;
#
	return T;
    }
###
    const self.profileasrecord := function ()
    {
# save profile as record. Return record
	wider its;
	if (shape(its.pdd) == 0) {
	    fail;
	}
	rec := its.pdd.ddproxy()->getdata();
	return rec;
    }
###
    const self.profileasimage := function (filepath, overwrite=T, log=F)
    {
# Save profile as image. Return image tool
	wider its;

	rec := self.profileasrecord();
	if (is_fail(rec)) {
	    fail;
	}
	csys := coordsys();
	csys.fromrecord(rec.profile.cs.cs);
	size := len(rec.profile.y.data);
	data := rec.profile.y.data;
	im := imagefromarray(outfile=filepath, pixels=data, csys=csys,
			     overwrite=overwrite, log=log);
	# set the unit
	im.setbrightnessunit(rec.profile.y.unit);
	# return the image tool
	return im;
    }
### 
    const self.profileasascii := function (filepath, sep=' ',
					   maskvalue=0.0,
					   overwrite=T)
    {
# Save profile as an ascii file. Return T if succesful
	wider its;

	im := self.profileasimage(filepath='tmpimage', log=F);
	if (is_fail(im)) {
	    fail;
	}
	ok := im.toascii(outfile=filepath, sep=sep,
			     overwrite=overwrite);
	im.delete();
	if(is_fail(ok)) {
	    fail;
	}
	return T;
    }
###
    const self.displaydata := function ()
    {
	return its.dd;
    }
###
    const self.profiledd := function ()
    {
	return its.pdd;
    }

    tmp := its.add(dd);
    if (is_fail(tmp)) fail;
}
