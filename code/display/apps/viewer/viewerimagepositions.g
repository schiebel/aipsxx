# viewerimagepositions.g: Viewer support for position/profile handling in images
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003,2004
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
#   $Id: viewerimagepositions.g
#
# Emits events:
#
#   Name              Value
#  position          rec.ddname
#                    rec.position
#                    rec.profile

pragma include once

include 'clipboard.g'
include 'note.g'
include 'quanta.g'
include 'profilewidthentry.g'
include 'regionmanager.g'
include 'serverexists.g'
include 'unset.g'
#
include 'imageprofilesupport.g'
include 'image.g'
include 'widgetserver.g'
#
include 'viewerddprofile.g'

const viewerimagepositions := subsequence (parent, widgetset=dws)
{
    if (!serverexists('dcb', 'clipboard', dcb)) {
       return throw('The clipboard server "dcb" is not running',
                     origin='viewerimagepositions.g');
    }
    if (!serverexists('dq', 'quanta', dq)) {
       return throw('The clipboard server "dq" is not running',
                     origin='viewerimagepositions.g');
    }
#
    its := [=];
    its.ws := widgetset;

# Callback functions

    its.getImageTool := [=];                  # Get Image tool from ddname 
    its.getZoomedRegion := [=];               # Get zoomed region
    its.pseudoToWorldRegion := [=];           # Convert pseudo to world region
    its.getMovieAxis := [=];                  # Get movie axis from ddname
    its.pseudoPositionToAbsolutePixel := [=]; # Convert pseudo to abspix position
    its.getMoviePixel := [=];                 # Find absolute pixel of movie axis
    its.computeProfileBox := [=];             # Compute profile box from position
#
    its.profileCallBacks := [=];              # Callbacks closures for imageprofilesupport 
#
    its.ips := [=];                        # Imageprofilesupport tools, indexed by ddname
    its.pwe := [=];                        # profilewidthentry tools, indexed by ddname
    its.csys := [=];                       # Coordsys tools, indexed by ddname
#
    its.td := [=];                         # Tab dialog
    its.tabs := [=];                       # The tabs, indexed by ddname
#
    its.tabnames := "";                    # The tab names (indexed by integer)
    its.ddnames := "";                     # DisplayData names
    its.index := [=];                      # Tabs index. Indexed by ddname
    its.active := [=];                     # Activity status, indexed by ddname
#
    its.position := [=];                   # Holds data, indexed by ddname
    its.plotter := [=];                    # Plotter names, indexexed by ddname
    its.madeprofilemenus := [=];           # Have we made the plotter menu, indexed by ddname ?
#
    its.region := [=];   
#
    its.vddp := [=];
    its.dds := [=];

### Private subsequence

   its.profileCallBack := subsequence (ddname, getImageCallBack)
   {
      its := [=];
      its.ddname := ddname;
      its.range := [=];
#
      const self.callback := function ()
      {
         wider its;
#
         if (!has_field(its.range, ddname)) {
            im := getImageCallBack(its.ddname);
            if (is_fail(im)) fail;
#
            local ss;
            ok := im.statistics(statsout=ss, list=F, async=F);
            if (is_fail(ok)) fail;
            its.range[ddname] := [ss.min,ss.max];
         }
#
         return its.range[ddname];
      }
#
      self.done := function ()
      {
         wider its, self;
#
         val its := F;
         val self := F;
      }
   }


### Private methods


###
   const its.addOneTab := function (ddname)
   {
      wider its;

# Overwrite if name exists, else we get in big logic tangles.
      
      if (has_field(its.index, ddname)) {
         n := its.index[ddname];
      } else {
         n := length(its.tabnames) + 1;
      }
#  
      tabname := ddname;
      its.tabnames[n] := tabname;
      its.ddnames[n] := ddname;
      its.index[ddname] := n;

# Create TAB, indexed by string converted integer
# and add it to the tabdialog widget

      ok := its.makeTab(n, ddname, tabname);
      if (is_fail(ok)) fail;
#
      return ok;
   }

###
   const its.assembleEvent := function (ddname)
   {
      wider its;
#

	    if (is_agent(its.vddp[ddname])) {
		data := its.vddp[ddname].profileasrecord();
		r := [ddname=ddname, position=data.position,
		      region=data.region, profile=data.profile];
		return r;
		if (is_fail(data)) {
		    fail;
		}
	    } else {
		r := [ddname=ddname, position=its.position[ddname].data,
		      profile=its.position[ddname].profile];
		return r;
	    }
   }


###
    const its.clearGui := function (ref rec)
    {
       rec.f3.value->delete('start', 'end');
       rec.f4.pixel->delete('start', 'end');
       rec.f5.world->delete('start', 'end');
#
       return T;
    }

###
   const its.getMeasures := function (pos, im, csys)
   {
# 
# Convert to measures
#
      rec := [=];
      rec.pixel := pos;
      rec.world := csys.toworld(pos, 'smqn');
      if (is_fail(rec.world)) fail;
#
# Add value
#
      rec.intensity := im.pixelvalue (as_integer(pos+0.5));  
      if (is_fail(rec.intensity)) fail;
#
      return rec;
   }

### 
   const its.makeNonTab := function ()
   {
       wider its;
#
       its.f0.check := its.ws.button(its.f0, type='check', text='Combine');
       its.ws.popuphelp(its.f0.check, 'When checked indicates all profiles are plotted together');
#
       return T;
   }

###
    const its.makeTab := function (idx, ddname, tabname)
    {
       wider its;
       its.ws.tk_hold();
#
       its.tabs[ddname] := its.ws.frame(its.tdf, side='top', relief='raised');

# Get Image tool

       im := its.getImageTool(ddname);    # A reference
       if (is_fail(im)) fail;
       its.csys[ddname] := im.coordsys();             # Not a reference (needs to be doned)
       if (is_fail(its.csys[ddname])) fail;
       shp := im.shape();
       if (is_fail(shp)) fail;
#
       ndim := length(shp);
       its.ips[ddname] := [=];            # Imageprofilesupport
       its.pwe[ddname] := [=];            # Profilewidthentry
       its.position[ddname] := [=];

# Buttons


       if (ndim > 2) {
# create 'plot' button if the image is > 2d	   
	   its.tabs[ddname].f1 := its.ws.frame(its.tabs[ddname], side='left');
	   its.tabs[ddname].f1.plot := its.ws.button(its.tabs[ddname].f1, type='action', text='plot');  
	   its.ws.popuphelp(its.tabs[ddname].f1.plot, 'Plot profile');
	   
# disable the button if the axes are not supported by profile2dDD
	   if (!its.axessupported(ddname)) {
	       its.tabs[ddname].f1.plot->disabled(T);
	   }
	   
# Profile x-axis labels. We have to defer making the profile support tool
# until now because we have to give it a widget set.
	   
	   its.ips[ddname] := imageprofilesupport(csys=its.csys[ddname], shp=shp, 
						  multiabcissa=F, widgetset=its.ws);
	   if (is_fail(its.ips[ddname])) fail;
	   movieAxis := its.getMovieAxis (ddname);
	   if (is_fail(movieAxis)) fail;
	   ok := its.ips[ddname].setprofileaxis(movieAxis);
	   if (is_fail(ok)) fail;
       } else {
	   its.tabs[ddname].f1 := [=];
	   its.tabs[ddname].f1.plot := [=];
#          its.tabs[ddname].f1.autoplot := [=];
       }

       if (is_agent(its.tabs[ddname].f1.plot)) {
	   whenever its.tabs[ddname].f1.plot->press do {
	       ddn := its.td.which().name;
	       its.tabs[ddn]->disable();
	       ok := its.plot(ddn);
	       if (is_fail(ok)) {
		   note (ok::message, priority='SEVERE', origin='viewerimagepositions.makeTab');
	       }
	       its.tabs[ddn]->enable();
	   }
       }
# Clipboard buttons + plot autoscale

       its.tabs[ddname].f0 := its.ws.frame(its.tabs[ddname], side='left');
       its.tabs[ddname].f0.copy := its.ws.button(its.tabs[ddname].f0, type='action', text='copy');
       its.ws.popuphelp(its.tabs[ddname].f0.copy, 'Copy position and profile to clipboard');
       its.tabs[ddname].f0.autocopy := its.ws.button(its.tabs[ddname].f0, type='check', text='Auto-copy', width=9);
       its.ws.popuphelp(its.tabs[ddname].f0.autocopy, 'Always copy position and profile to clipboard');
#
       its.tabs[ddname].f0.space := its.ws.frame(its.tabs[ddname].f0, expand='x', height=1, width=5);

# Autocopy state

       whenever its.tabs[ddname].f0.autocopy->press do {
          ddn := its.td.which().name;
          if (its.tabs[ddn].f0.autocopy->state()) { 
             its.tabs[ddn].f0.copy->disabled(T);
          } else {
             its.tabs[ddn].f0.copy->disabled(F);
          }
       }   

# Copy position and profile to clipboard

       whenever its.tabs[ddname].f0.copy->press do {
         ddn := its.td.which().name;
         r := its.assembleEvent (ddn);
         dcb.copy(r);
       }

# Autoplot state

       if (ndim > 2) {

# Make profile width entry widget

	   its.pwe[ddname] := profilewidthentry(parent=its.tabs[ddname], widgetset=its.ws,
						relief='flat');
	   if (is_fail(its.pwe[ddname])) fail;
	   whenever its.pwe[ddname]->value do {
	       ok := self.insertposition();
	       if (is_fail(ok)) {
		   note (ok::message, priority='SEVERE', origin='viewerimagepositions.makeTab');
	       }
	   }
       }
       
# Value

       its.tabs[ddname].f3 := its.ws.frame(its.tabs[ddname], side='left');
       its.tabs[ddname].f3.label := its.ws.label(its.tabs[ddname].f3, 'Value');
       its.tabs[ddname].f3.value := its.ws.listbox(its.tabs[ddname].f3, height=1, width=20, fill='none');
       longtxt := spaste('\nIf you generated the profile from a region \n',
                         'rather than the position cursor, then the \n',
                         'location reflects the center of the bounding \n',
                         'box of the region.  Of course, this may not \n',
                         'actually be in the region !');
       its.ws.popuphelp(its.tabs[ddname].f3.label, longtxt, 'Image value under position cursor',
                        combi=T, width=80);

# Absolute pixel

       its.tabs[ddname].f4 := its.ws.frame(its.tabs[ddname], side='left');
       its.tabs[ddname].f4.l0 := its.ws.label(its.tabs[ddname].f4, 'Pixel', width=5);
       its.tabs[ddname].f4.pixel := its.ws.listbox(its.tabs[ddname].f4, height=1, width=45, fill='none');
       its.ws.popuphelp(its.tabs[ddname].f4.l0, longtxt, 
                        'Absolute pixel coordinate of position cursor', combi=T, width=80);

# World

       its.tabs[ddname].f5 := its.ws.frame(its.tabs[ddname], expand='x', side='left');
       its.tabs[ddname].f5.l0 := its.ws.label(its.tabs[ddname].f5, 'World', width=5);
       its.tabs[ddname].f5.world := its.ws.listbox(its.tabs[ddname].f5, height=1, width=45, fill='none');
       its.ws.popuphelp(its.tabs[ddname].f5.l0, longtxt, 
                        'Absolute world coordinate of position cursor', combi=T, width=80);

# Add new TAB to the tabdialog widget

       ok := its.td.add(its.tabs[ddname], tabname);
       if (is_fail(ok)) fail;
       if (length(its.td.list())==1)  its.td.front(tabname);
#
       its.ws.tk_release();
#
       return T;
    }


###
   const its.plot := function (ddname, which=unset)
   {
      wider its;

      if (!is_agent(its.vddp[ddname])) {
 	  its.vddp[ddname] := viewerddprofile(its.dds[ddname]);
	  if (is_fail(its.vddp[ddname])) {
	      its.vddp[ddname] := [=];
	      fail;
	  }
      }
      its.vddp[ddname].gui();

      return T;
   }

###
    const its.writeGui := function (rec, data)
#
#
# data.intensity
#           .mask
#           .value
#                 .value
#                 .unit
# data.pixel
# data.world.measure
#           .quantity
#           .numeric
#           .string
    {
       wider its;
#
       its.ws.tk_hold();
       its.clearGui (rec);
#
       v := dq.getvalue(data.intensity.value);
       u := dq.getunit(data.intensity.value);
       s := spaste(as_string(v), ' ', u);
       rec.f3.value->insert(s);
#
       rec.f4.pixel->insert(paste(as_string(as_integer(data.pixel+0.5))));
       rec.f5.world->insert(paste(data.world.string));
#
       its.ws.tk_release();
       return T;
    }


### Public methods

###
    const self.add := function (ddname, newdd) 
    {
       wider its;
#
       its.vddp[ddname] := [=];
       its.dds[ddname] := [=];
       its.dds[ddname] := newdd;

       whenever newdd->contextoptions do {
# The axes order may have changed so we need to redraw the the profile and its axes.
	   if (its.axessupported(ddname)) {
	       if (is_agent(its.vddp[ddname])) {
		   ok := its.vddp[ddname].refresh();
	       }
	       if (is_agent(its.tabs[ddname].f1.plot)) {
		   its.tabs[ddname].f1.plot->disabled(F);
	       }
	   } else {
	       if (is_agent(its.vddp[ddname])) {
		   ok := its.vddp[ddname].done();
		   its.vddp[ddname] := [=];
	       }
	       if (is_record(its.tabs[ddname].f1) &&
	           is_agent(its.tabs[ddname].f1.plot)) {
		   its.tabs[ddname].f1.plot->disabled(T);
	       }     
	   }
       }

#
       if (has_field(its.index, ddname) && its.active[ddname]) {
          return throw (spaste('Entry ', ddname, ' is already active'),
                        origin='viewerimagepositions.add');
       }

# Add TAB

       ok := its.addOneTab(ddname); 
       if (is_fail(ok)) fail;
       its.active[ddname] := T;

# Set min/max callback for imageprofilesupport tool (only exists for > 2D data)

       its.profileCallBacks[ddname] := [=];
       if (is_agent(its.ips[ddname])) {
          its.profileCallBacks[ddname] := its.profileCallBack (ddname, its.getImageTool);
          if (is_fail(its.profileCallBacks[ddname])) fail;
          ok := its.ips[ddname].setyrangecallback(its.profileCallBacks[ddname].callback)
          if (is_fail(ok)) fail;
       }
#

       return T;
    }
###

    const its.axessupported := function (ddname) {

	# check if zlength is greater than 2
	if(!is_function(its.dds[ddname].zlength) || 
			its.dds[ddname].zlength() < 2) {
	    return F;
	}

	# check whether the coordinate type of the z axis is supported
	options := its.dds[ddname].getoptions();
	tmp := options['zaxis'];
	if (is_record(tmp)) {
	    zaxisname := tmp.value;
	    waxisnames := its.csys[ddname].names();
	    axisnames := waxisnames[its.csys[ddname].axesmap()];
	    idxvec := ind(axisnames);
	    zaxis := idxvec[axisnames==zaxisname];
	    local coord, aic;
	    its.csys[ddname].findaxis(coord, aic, F, zaxis);
	    cname := its.csys[ddname].coordinatetype(coord);
	    
	    if (cname == 'Spectral' ||
		cname == 'Direction') {
		return T;
	    } else {
		return F;
	    }
	}
    }

###
    const self.delete := function (ddname) 
    {
       wider its;
#
       if (has_field(its.active, ddname) && !its.active[ddname]) {
           return throw (spaste('Entry ', ddname, ' is not active'),
                         origin='viewerimagepositions.delete');   
       }
#
       idx := its.index[ddname];
       tabname := its.tabnames[idx];
       its.active[ddname] := F;
#
       ok := its.td.delete(tabname); 
       if (is_fail(ok)) fail;
       its.tabs[ddname] := F;
#
       if (is_agent(its.ips[ddname])) {
          ok := its.ips[ddname].done();
       }
       if (is_agent(its.pwe[ddname])) {
          ok := its.pwe[ddname].done();
       }
       if (is_agent(its.csys[ddname])) {
          ok := its.csys[ddname].done();
       }
#
       if (is_agent(its.profileCallBacks[ddname])) {
          ok := its.profileCallBacks[ddname].done();
       }
       its.madeprofilemenus[ddname] := F;
#

       if (is_agent(its.vddp[ddname]) && shape(its.vddp[ddname]) != 0) {
	   its.vddp[ddname].done();
       }
       its.dds[ddname] := [=];

       return T;
    }


###
    const self.done := function () 
    {
       wider its, self;
#
       ok := its.td.done();
#
       for (ddname in its.ddnames) {
	   if (its.active[ddname]) {
	       
	     if (is_agent(its.vddp[ddname])) {
		 ok := its.vddp[ddname].done();
	     }
	     its.dds[ddname] := [=];

             if (is_agent(its.ips[ddname])) {
                ok := its.ips[ddname].done();
             }
             if (is_agent(its.pwe[ddname])) {
                ok := its.pwe[ddname].done();
             }
             if (is_agent(its.csys[ddname])) {
                ok := its.csys[ddname].done();
             }
             if (is_agent(its.profileCallBacks[ddname])) {
                ok := its.profileCallBacks[ddname].done();
             }
#
             its.tabs[ddname] := F;
             its.active[ddname] := F;
          }
       }
#
       val its := F;
       val self := F;

#
       return T;
    }

###
   self.insertposition := function (pseudoposition=unset)
   {
      wider its;

# Distribute over DDs

      for (ddname in its.ddnames) {
         if (its.active[ddname]) {

# Get Image tool and coordsys

            im := its.getImageTool(ddname);
            if (is_fail(im)) fail;
            csys := its.csys[ddname];
#
            shp := im.shape();
            if (is_fail(shp)) fail;
            ndim := length(shp);

# Get averaging width

            width := -1;
            if (ndim > 2) {
               width := its.pwe[ddname].getvalue().value;
               if (is_fail(width)) fail;
            }

# Convert pseudoposition to absolute pixel coordinate via callback
# If there is no pseudoposition, just use the last location, if there
# is one, and update the profile box for the current width.

            local absPix;
            if (is_unset(pseudoposition)) {
               if (length(its.position[ddname].data) > 0) {
                  absPix := its.position[ddname].data.pixel;
                  its.position[ddname].box := 
                      its.computeProfileBox (absPix, width, ddname, asregion=F);
               } else {
                  note ('There is no previous position to reuse',
                        priority='WARN', origin='viewerimagepositions.insertposition');
                  return F;
               }
            } else {
               its.position[ddname].box := [=];
               absPix := its.pseudoPositionToAbsolutePixel (its.position[ddname].box, 
                                                            pseudoposition, width, ddname,
                                                            asregion=F);
               if (is_fail(absPix)) fail;

# Convert location to measures
     
               its.position[ddname].data := its.getMeasures (absPix, im, csys);
               if (is_fail(its.position[ddname].data)) fail; 
            }

# Generate abcissa and ordinate

            if (ndim > 2) {
               ok:= its.ips[ddname].makeabcissa (absPix);
               if (is_fail(ok)) fail;
               idx := its.ips[ddname].makeordinate(im, its.position[ddname].box, 
                                                   which=1);
               if (is_fail(idx)) fail;
#
               s1 := paste(its.position[ddname].data.world.string);     # Vector to string
               s2 := spaste ('  (', as_string(absPix), ')');
               its.ips[ddname].settitle (spaste(s1, s2), 1);
            }

# Write position to GUI

            its.writeGui (its.tabs[ddname], its.position[ddname].data);

# Assemble position and profile record

            its.position[ddname].profile := [=];
            if (ndim > 2) {
               its.position[ddname].profile := [x=its.ips[ddname].getabcissa(),
                                                y=its.ips[ddname].getordinate(which=idx)];
            }
            r := its.assembleEvent (ddname);

# Auto copy to clipboard

            if (its.tabs[ddname].f0.autocopy->state()) dcb.copy(r);

# Send out event.  

            self->position(r);
         }
      }
      return T;
   }


###
   self.insertregion := function (region, true=F)
#
# true = T means the inserted region is a true region
#        F means the inserted region is a Viewer pseudo region record
#
   {
t := time();

      wider its;
      if (true && !is_region(region)) {
         return throw ('Specified region variable is not a valid region tool',
                       origin='viewerimagepositions.insertregion');
      }

# Distribute over DDs

      local profile, profilemask;
      for (ddname in its.ddnames) {
         if (its.active[ddname]) {

# Get Image tool and coordsys

            im := its.getImageTool(ddname);
            if (is_fail(im)) fail;
            csys := its.csys[ddname];
#
            shp := im.shape();
            if (is_fail(shp)) fail;
            ndim := length(shp);
#
            profileAxis := its.getMovieAxis(ddname);
#
            if (true) {

# Extend the true region over the movie axis if there is one

               if (profileAxis > 0) {
                  blc := '1pix';
                  trc := spaste(shp[profileAxis], 'pix');
                  wbox := drm.wbox(csys=csys, blc=blc, trc=trc,
                                   pixelaxes=[profileAxis]);
                  if (is_fail(wbox)) fail;
                  r2d := drm.extension(wbox, region);
                  if (is_fail(r2d)) fail;
               } else {
                  r2d := region;
               }
            } else {

# Generate region (2d average), using autoextend to extend over 
# other axes

               r2d := its.pseudoToWorldRegion (ddname, region, intersect=F);
               if (is_fail(r2d)) fail;
            }

# Find bounding box

            bb := im.boundingbox(r2d);
            if (is_fail(bb)) fail;

# Find center of region; might not be in region !

            absPix := as_float(bb.trc + bb.blc) / 2.0;
            if (profileAxis > 0) {
               absPix[profileAxis] := its.getMoviePixel();
            }

# Convert center location to measures

            its.position[ddname].data := its.getMeasures(absPix, im, csys);
            if (is_fail(its.position[ddname].data)) fail; 
#
            its.tabs[ddname]->disable();
            if (ndim > 2) {

# Generate abcissa

               ok:= its.ips[ddname].makeabcissa (absPix);
               if (is_fail(ok)) {
                  its.tabs[ddname]->enable();
                  fail; 
               }

# Generate ordinate, average over all axes but the profile axis

               axes := [];
               j := 1;
               for (i in 1:ndim) {
                  if (i!=profileAxis) {
      	             axes[j] := i;
                     j +:= 1;
                  }
               }
               ok := im.getregion(profile, profilemask, r2d, axes, dropdeg=T);
               if (is_fail(ok)) {
                  its.tabs[ddname]->enable();
                  fail;
               }

# Set the ordinate

               idx := its.ips[ddname].setordinate(profile, profilemask, which=1);
               if (is_fail(idx)) {
                  its.tabs[ddname]->enable();
                  fail; 
               }

# Title
               s1 := paste(its.position[ddname].data.world.string);     # Vector to string
               s2 := spaste ('  (', as_string(absPix), ')');
               its.ips[ddname].settitle (spaste(s1, s2), 1);
            }

# Write to GUI

            its.writeGui(its.tabs[ddname], its.position[ddname].data);

# Auto plot profile

#             if (ndim>2 && its.tabs[ddname].f1.autoplot->state()) {
#                ok := its.plot(ddname, 1);
#                if (is_fail(ok)) {
#                   its.tabs[ddname]->enable();
#                   fail;
#                }
#             }

# Assemble position and profile record

            its.position[ddname].profile := [=];
            if (ndim > 2) {
               its.position[ddname].profile := [x=its.ips[ddname].getabcissa(),
                                                y=its.ips[ddname].getordinate(which=idx)];
            }
            r := its.assembleEvent (ddname);

# Auto copy to clipboard

            if (its.tabs[ddname].f0.autocopy->state()) dcb.copy(r);

# Send out event.  

            self->position(r);
            its.tabs[ddname]->enable(); 
         }
      }
   }


###
   const self.setcallbacks := function (callback1=unset, callback2=unset,
                                        callback3=unset, callback4=unset,
                                        callback5=unset, callback6=unset,
                                        callback7=unset)
#
# The idea is to get viewerimageanalysis to do as much of the
# work as possible. So we use callbacks, inserted by viewerimageanalysis
# to do the work for us.
#
   {
      wider its;

# Arg. ddname, returns image Tool

      if (is_function(callback1)) {
         its.getImageTool := callback1;
      } else {
         if (!is_unset(callback1)) {
            return throw ('callback1 is not a function',
                           origin='viewerimagepositions.setcallbacks');
         }
      }

# Arg. ddname, returns zoomed region of display

      if (is_function(callback2)) {
         its.getZoomedRegion := callback2;
      } else {
         if (!is_unset(callback2)) {
            return throw ('callback2 is not a function',
                           origin='viewerimagepositions.setcallbacks');
         }
      }

# Arg. ddname, pseudoregion, & intersect returns world region

      if (is_function(callback3)) {
         its.pseudoToWorldRegion := callback3;
      } else {
         if (!is_unset(callback3)) {
            return throw ('callback3 is not a function',
                           origin='viewerimagepositions.setcallbacks');
         }
      }

# Arg. ddname, returns movie axis

      if (is_function(callback4)) {
         its.getMovieAxis := callback4;
      } else {
         if (!is_unset(callback4)) {
            return throw ('callback4 is not a function',
                           origin='viewerimagepositions.setcallbacks');
         }
      }

# Arg. box, pseudoposition, ddname, returns abspix

      if (is_function(callback5)) {
         its.pseudoPositionToAbsolutePixel := callback5;
      } else {
         if (!is_unset(callback5)) {
            return throw ('callback5 is not a function',
                           origin='viewerimagepositions.setcallbacks');
         }
      }

# Arg. ddname; returns abspix of profile/movie axis

      if (is_function(callback6)) {
         its.getMoviePixel := callback6;
      } else {
         if (!is_unset(callback6)) {
            return throw ('callback6 is not a function',
                           origin='viewerimagepositions.setcallbacks');
         }
      }
#
# Arg. position, width, ddname, returns profile box
#
      if (is_function(callback7)) {
         its.computeProfileBox := callback7;
      } else {
         if (!is_unset(callback7)) {
            return throw ('callback7 is not a function',
                           origin='viewerimagepositions.setcallbacks');
         }
      }

      return T;
   }


###
   const self.update := function (ddname) 
   {
      wider its;
#
      if (has_field(its.active, ddname) && !its.active[ddname]) {
         return throw (spaste('Entry ', ddname, ' is not active'),
                       origin='viewerimagepositions.update');   
      }

# Will only be an active agent if dim > 2

      if (is_agent(its.ips[ddname])) {
         ok := its.ips[ddname].setprofileaxis(its.getMovieAxis(ddname));
         if (is_fail(ok)) fail;
      }
#
      return T;
   }

### Constructor

# Frame for non-tab stuff

#   its.f0 := its.ws.frame (parent, side='left');
#   ok := its.makeNonTab();
#   if (is_fail(ok)) fail;

# Imageprofilesupport tool when plotting all together

#   its.ips.combined := imageprofilesupport(its.csys[ddname], shp, its.ws);
#   if (is_fail(its.ips[ddname])) fail;
#   movieAxis := its.getMovieAxis (ddname);

# Tab dialog 

   its.td := its.ws.tabdialog(parent, colmax=3, title=unset);
   if (is_fail(its.td)) fail;

# Frame to put all the TABS in

   its.tdf := its.td.dialogframe();
   if (is_fail(its.tdf)) fail;
}
