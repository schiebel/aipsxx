# imageviewersupport.g: Viewer support for Image tool
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#   $Id: 
#

pragma include once

include 'image.g'
include 'clipboard.g'
include 'coordsys.g'
include 'imagesupport.g'
include 'imagetemporary.g'
include 'misc.g';
include 'note.g'
include 'serverexists.g'
include 'unset.g'
include 'viewer.g'
include 'viewershowcomponentlist.g'
include 'widgetserver.g'



const imageviewersupport := subsequence (ref theImage, widgetset=ddlws)
{
    if (!serverexists('ddlws', 'widgetserver', ddlws)) {
       return throw('The widget server "ddlws" is not running',
                    origin='imagviewersupport.g');
    }
    if (!serverexists('defaultimagesupport', 'imagesupport', defaultimagesupport)) {
       return throw('The imagesupport server "defaultimagesupport" is not running',
                    origin='imageviewersupport.g');
    }
    if (!serverexists('dms', 'misc', dms)) {
       return throw('The misc server "dms" is not running',
                     origin='imageviewersupport.g');
    }
#
    its := [=];
    its.image := theImage;             # Image tool
    its.ndim := length(theImage.shape());
    its.csys := its.image.coordsys();  # Coordsys tool
    if (is_fail(its.csys)) fail;
#
# Create tool to handle persistent temporary images and make 
# name for temporary image
#
    its.itp := imagetemporary(its.image, directory='.');    # Imagetemporary tool
    if (is_fail(its.itp)) fail;
#
    its.parentIsAgent := [=];
    its.parent := F;
#
    its.viewer := [=];
    its.dp := [=];
    its.dp.panel := [=];                     # The display panel
    its.dp.break := [=];                     # The break button
#
    its.vscl := [=];
    its.id := [=];
    its.ddd := [=];
#
    its.raster := [=];
    its.raster.dd := [=];
    its.contour := [=];
    its.contour.dd := [=];
    its.vector := [=];
    its.vector.dd := [=];
    its.marker := [=];
    its.marker:= [=];
#
    its.whenevers := [=];
    its.whenevers.dp := [];
    its.whenevers.options := [=];
    its.whenevers.options.raster := F;
    its.whenevers.options.contour := F;
    its.whenevers.options.vector := F;
    its.whenevers.options.marker := F;
#
    its.isdismissed := T;
    its.lastregion := [=];    
    its.lastmask  := F;
    its.lastlabels := F;
    its.lastorder := [];
    its.lastincludepix := unset;
#

### Private methods


###
   const its.deactivate := function (which) 
   {
      if (is_integer(which)) {
         n := length(which);
         if (n>0) {
           for (i in 1:n) {
              ok := whenever_active(which[i])
              if (is_fail(ok)) {

# A fail means that the whenever has disappeared.  This can
# happen if the agent associated with the whenever is destroyed
# like the displaypanel

              } else {
                if (ok) {
                 deactivate which[i];
                }
              }
           }
         }
      }

      return T;
   }

###
   const its.viewerDisEnable := function (disable)
   {
      wider its;
      if (disable) {
         return its.viewer.disable();
      } else {
         return its.viewer.enable();
      }
      return T;
   }


###
   const its.doneDDs := function () 
   {
      wider its;
      if (is_agent(its.raster.dd)) {
         ok := its.raster.dd.done();
         if (is_fail(ok)) fail;
      }
      if (is_agent(its.contour.dd)) {
         ok := its.contour.dd.done();
         if (is_fail(ok)) fail;
      }
      if (is_agent(its.vector.dd)) {
         ok := its.vector.dd.done();
         if (is_fail(ok)) fail;
      }
      if (is_agent(its.marker.dd)) {
         ok := its.marker.dd.done();
         if (is_fail(ok)) fail;
      }
      return T;
   }




###
   const its.getOptions := function ()
#
# We keep the DDs in sync, so it doesn't matter
# which one we use to get the options.
#
   {
      local options := [=];
      if (is_agent(its.raster.dd)) return its.raster.dd.getoptions();   
#
      if (length(options)==0) {
         if (is_agent(its.contour.dd)) return its.contour.dd.getoptions();   
      }
#
      if (length(options)==0) {
         if (is_agent(its.vector.dd)) return its.vector.dd.getoptions();   
      }
#
      if (length(options)==0) {
         if (is_agent(its.marker.dd)) return its.marker.dd.getoptions();   
      }
      fail 'Internal error';
   }




###
   const its.handleTemporaryPersistentMask := function (fileName, mask)
#
# This is used to generate an insitu mask for the OTF mask
# keyword when used with image.view
#
   {
#
# Handle mask
#
      if (!is_unset(mask)) {
#
# Open temporary image.  It will have at most two masks.  
#
         _imagetemp := image(fileName);
         if (is_fail(_imagetemp)) fail;
#
# Delete mask1 if it exists
#
         ok := _imagetemp.maskhandler('delete', 'mask1');
         if (is_fail(ok)) fail;
# 
# Make sure there is a mask called 'mask0' and that it is the default
#
         maskNames := _imagetemp.maskhandler('get');
         if (is_fail(maskNames)) fail;
         if (length(maskNames)==0) {
            ok := _imagetemp.set(pixelmask=T);
            if (is_fail(ok)) fail;
         }                 
         maskNames := _imagetemp.maskhandler('get');
         if (is_fail(maskNames)) fail;
         if (length(maskNames)!=1) {
            return throw ('Unexpected number of masks in persistent image',
                          origin='imageviewersupport.handleTemporaryPersistent');
         }
         if (maskNames[1] != 'mask0') {
            ok := _imagetemp.maskhandler('rename', "maskNames[1] mask0");
            if (is_fail(ok)) fail;
         }
         ok := _imagetemp.maskhandler('set', 'mask0');
         if (is_fail(ok)) fail;
#
#        
# Create new 'mask1', applying 'mask0' first.  The new mask is the default.
# Here we apply the OTF mask by creating an in situe mask
         if (strlen(mask)>0) {
            expr := spaste ('mask("', fileName, '") && ', mask);
            _imagetemp.calcmask(mask=expr, name='mask1', default=T);
         }
#        
         if (is_fail(_imagetemp.done())) fail;
      }
      return T;
   }     



### 
   const its.findNext := function (used)
   {
     n := length(used);
     for (i in 1:n) {
        if (!used[i]) return i;
     }
   }

###
   const its.orderDDs := function (order) 
   {  
      wider its;
#
# User can only specify upto first three axes
#
      nPixAll := its.csys.naxes(world=F);
      used := array(F,nPixAll);
      shp := its.image.shape();

# Work out default order. We exclude dgenerate axes from
# display if possible and prefer Spectral to Stokes
#
      j := 1;
      defaultOrder := [];
      for (i in 1:length(shp)) {
        if (shp[i] > 1) {                 # Don't display degenerate axis
           defaultOrder[j] := i;
           j +:= 1;
        }
      }
#
      ctypes := its.csys.axiscoordinatetypes(F);
      iStokes := -1;
      iSpec := -1;
      for (i in 1:length(defaultOrder)) {
        axis := defaultOrder[i];
        if (ctypes[axis]=='Stokes') {
           iStokes := i;
        } else if (ctypes[axis]=='Spectral') {
           iSpec := i;
        }
      }
      if (iSpec!=-1 && iStokes!=-1) {

# Flip Spectral and Stokes if needed; we prefer Spectral

         vStokes := defaultOrder[iStokes];
         vSpec   := defaultOrder[iSpec];
         if (vStokes < vSpec) {
            defaultOrder[iStokes] := vSpec;
            defaultOrder[iSpec] := vStokes;
         }
      }
      if (length(defaultOrder) > 3) defaultOrder := defaultOrder[1:3];
#
      if (is_unset(order)) {
         if (length(its.lastorder)==0) {         # First time
            order := defaultOrder;
         } else {
            order := its.lastorder;
         }
      } else {
         n := length(order);
         if (n==0) {
           order := defaultOrder;
         } else {
           order := order[1:min(3,n)];
         }
      }
#
      n := length(order);
      used[order] := T;
      for (i in 1:n) {
         if (order[i]<1 || order[i]>nPixAll) {
            return throw('Illegal value in order vector',
                         origin='imageviewersupport.orderDDs');
         }
      }
#
# Even if the order is unchanged since last time, we must still issue
# the refresh event. This is because signifyImageHasCHanged may
# have destroyed the DDs and they only just got remade.  We don't
# have to worry about any hidden axes. The viewer will sort those
# out for us.
#
      p2w := its.csys.axesmap(toworld=T);
      worldNames := its.csys.names();
      pixelNames := worldNames[p2w];
#
      rec := [=];
      rec.xaxis := [=];
      rec.yaxis := [=];
      rec.xaxis.value := pixelNames[order[1]];
      if (n >= 2) {
         rec.yaxis.value := pixelNames[order[2]];
      } else {
         i := its.findNext(used);
         used[i] := T;
         rec.yaxis.value := pixelNames[i];
      }
      if (nPixAll>=3) {
         rec.zaxis := [=];
         if (n >=3) {
            rec.zaxis.value := pixelNames[order[3]];
         } else {
            i := its.findNext(used);
            used[i] := T;
            rec.zaxis.value := pixelNames[i];
         }
      }
#
# Direct the DDs to jiggle about
#
      if (is_agent(its.raster.dd)) {
         ok := its.raster.dd.setoptions(rec, emit=F);
         if (is_fail(ok)) fail;
      }
#
      if (is_agent(its.contour.dd)) {
         ok := its.contour.dd.setoptions(rec, emit=F);
         if (is_fail(ok)) fail;
      }
      if (is_agent(its.vector.dd)) {
         ok := its.vector.dd.setoptions(rec, emit=F);
         if (is_fail(ok)) fail;
      }
      if (is_agent(its.marker.dd)) {
         ok := its.marker.dd.setoptions(rec, emit=F);
         if (is_fail(ok)) fail;
      }
#
      its.lastorder := order;
#
      return T;
   }
   
   
###
   const its.makeDD := function (type, doIt, ref region, mask, axislabels, includepix,
                                 regionChanged, axisLabelsChanged, includepixChanged)
   {
      wider its;
#
      makeNewDD := F;
      hasDD := is_agent(its[type].dd);
      if (doIt) {
         if (!hasDD) makeNewDD := T;
         if ( (is_boolean(its.lastmask) && its.lastmask==F) ||
              (mask!=its.lastmask)) makeNewDD := T;
      }
#
      if (makeNewDD) {
#
# Kill off old one (kills adjust agent as well)
#
         its.deactivate (its.whenevers.options[type]);
         if (hasDD) {
            ok := its[type].dd.done();
            if (is_fail(ok)) fail;
         }
#
# Copy virtual images to temporary disk file
#
         local filename;
         if (its.image.ispersistent() && strlen(mask)==0) {
            filename := its.image.name(strippath=F);
         } else {
            filename := its.itp.access ();
            if (is_fail(filename)) fail;
            ok := its.handleTemporaryPersistentMask(filename, mask);
            if (is_fail(ok)) fail;
         }
#
# make DD
#
         its[type].dd := its.viewer.loaddata(filename, type);
         if (is_fail(its[type].dd)) fail;
#
# Set basic options record
#
         rec := [=];
         rec.region := region;
         if (axislabels) {
            rec.xgridtype := 'Full grid';
            rec.ygridtype := 'Full grid';
            rec.axislabelswitch := T;
         }
         if (type=='raster') {
            if (!is_unset(includepix)) {
               rec.datamin := includepix[1];
               rec.datamax := includepix[2];
            }
         }   
#
# Now it maybe that we are making this DD when the other already
# exists.  If the user has reordered the other DD interactively
# when we make this one we better keep it in sync
#
         op := its.getOptions();
         if (has_field(op, 'xaxis') && has_field(op, 'yaxis')) {
            rec.xaxis := op.xaxis.value;
            rec.yaxis := op.yaxis.value;
         }
         if (has_field(op, 'zaxis')) {
             rec.zaxis := op.zaxis.value;
         }
#
# Finally send the options string
#
         ok := its[type].dd.setoptions(rec);
         if (is_fail(ok)) fail;
#
         whenever its[type].dd->options do {
#
# Now keep the 'other' DDs in sync.  
#
            rec := [=];
            if (has_field($value, 'xaxis') &&
                has_field($value, 'yaxis')) {
               rec.xaxis := $value.xaxis.value;
               rec.yaxis := $value.yaxis.value;
            }
            if (has_field($value, 'zaxis')) {
               rec.zaxis := $value.zaxis.value;
            }
#	
            if (length(rec)>0) {
               othertypes := "";
               if (type=='raster') {
                  othertypes := "contour vector marker";
               } else if (type=='contour') {
                  othertypes := "raster vector marker";
               } else if (type=='vector') {
                  othertypes := "raster contour marker";
               } else if (type=='marker') {
                  othertypes := "raster contour vector";
               }
               for (t in othertypes) {
                  if (is_agent(its[t].dd)) {
                     ok := its[t].dd.setoptions(rec, emit=F);
                  }
               }
            }
         }
         its.whenevers.options[type] := last_whenever_executed();
      } else {
          op := [=];
          if (regionChanged) {
             op.reread := T;
             op.region := region;
          }
          if (axisLabelsChanged) {
             if (axislabels) {
                op.xgridtype := 'Full grid';
                op.ygridtype := 'Full grid';
                op.axislabelswitch := T;
             } else {
                op.axislabelswitch := F;
             }
          }
#
          if (type=='raster' && includepixChanged) {
             if (is_unset(includepix)) {
                op2 := its[type].dd.getoptions();
                op.datamin := op2.datamin.default;
                op.datamax := op2.datamax.default;
             } else {
                op.datamin := includepix[1];
                op.datamax := includepix[2];
             }   
          }
#
          if (hasDD && length(op)>0) {
             ok := its[type].dd.setoptions(op);
             if (is_fail(ok)) fail;
          }
      }
#
      return T;
   }


###
   const its.registerDD := function (type, showIt)
#
# Input
#   type          'raster', 'contour', 'vector', 'marker'
#   showIt        (show me the "type" [raster or contour]) T or F
#
#
# The raster and contour DD are always made.  showIt says what the
# user actually gets to see
#
   {
      wider its;
#
# Now register the DD if desired and if it exists
#
      if (!is_agent(its[type].dd)) return T;
      if (showIt) {
         ok := its.dp.panel.register(its[type]['dd']);
         if (is_fail(ok)) fail;
      } else {
         ok := its.dp.panel.unregister(its[type]['dd']);
         if (is_fail(ok)) fail;
      }
#
      return T;
   }



###
   const its.makeDisplayPanel := function (ref parent, hasDismiss)
   {
      wider its;

# Deactivate old DP whenevers

      its.deactivate(its.whenevers.dp);
      its.whenevers.dp := [];

# Destroy existing dp

      if (is_agent(its.dp.panel)) {
          if (is_fail(its.dp.panel.done())) fail;
      }

# Make new dp

      widgetset.tk_hold();
      its.dp.panel := 
         its.viewer.newdisplaypanel(parent=parent, hasdismiss=F, hasdone=F,
                                    hasgui=T, guihastracking=T,
                                    height=325, width=325);
      if (is_fail(its.dp.panel)) {
	  widgetset.tk_release();
	  fail;
      }
      its.dp.panel.unmap();
      widgetset.tk_release();
#
      its.dp.f0 := its.dp.panel.leftframe();
      its.dp.f1 := widgetset.frame(its.dp.f0, side='top');
#
      its.dp.break := widgetset.button(its.dp.f1, 'B\nr\ne\na\nk', font='bold');
      txt := spaste('- With the regionmanager GUI you can request an interactive\n',
                    '  region be created for an image.  This starts the viewer for\n',
                    '  that image.  Any region you make interactively with the \n',
                    '  viewer is then sent to the regionmanager for management !\n',
                    '  When you press the "break" button, the connection with \n',
                    '  the regionmanager GUI is sundered.  You can re-establish it\n',
                    '  from the regionmanager GUI as before');
      widgetset.popuphelp(its.dp.break, txt, 
                'Break connection with the current connected regionmanager',
                 combi=T, width=80);
      its.dp.break->disabled(T);
      its.dp.panel.map();
#
# Dismiss/done buttons.  I need to handle an argument hasdone=unset and make 
# new displaypanels if it changes from one call to the next
#
      its.doneframe := widgetset.frame(its.dp.panel.lowerframe(),
                                       side='right', expand='x', height=1);
      widx := 1;
      if (!is_agent(parent)) {
         if (hasDismiss) {
            its.dismiss := widgetset.button(its.doneframe, text='Dismiss',
                                            type='dismiss');
            txt := '- You can recover it by rerunning the view function';
            widgetset.popuphelp(its.dismiss, txt, 'Dismiss GUI', combi=T);
#
            whenever its.dismiss->press do {
               its.dp.panel.unmap();
               its.dismissed := T;
            }
            its.whenevers.dp[widx] := last_whenever_executed(); widx +:= 1;
         }
#
         its.done := widgetset.button(its.doneframe, text='Done', type='halt');
         txt := '- You can recreate it by rerunning the view function';
         widgetset.popuphelp(its.done, txt, 'Destroy GUI', combi=T);
#
         whenever its.done->press do {
            ok := its.doneDDs();              # Frees locks
            if (is_fail(ok)) {
               note (ok::message, priority='SEVERE', 
                     origin='imageviewersupport.makeDisplayPanel');
            } else {
               ok := its.dp.panel.done();              # Generates dp->done event, caught below
               if (is_fail(ok)) {
                  note (ok::message, priority='SEVERE', 
                        origin='imageviewersupport.makeDisplayPanel');
               }
            }
         }
         its.whenevers.dp[widx] := last_whenever_executed(); widx +:= 1;
      }
#
# Forward events; strip out ddname field
#
     whenever its.dp.panel->* do {
        if ($name=='region' || $name=='position' || $name=='statistics') {
           fns := field_names($value);
           r := [=];
           for (fn in fns) {
              if (fn!='ddname') {
                 r[fn] := $value[fn];
              }
           }
#
           self->[$name](r);
        }
     }
     its.whenevers.dp[widx] := last_whenever_executed(); widx +:= 1;
#
# Handle display panel done event.  This may come from the File menu
# 'done' or from the 'Done' button at the bottom of the GUI.
# We send out an event that enables the caller of the view 
# function to take any action that they  deem necessary (e.g. 
# catalog destroys the image that it has opened temporarily).  
#
      whenever its.dp.panel->done do {
         ok := its.doneDDs();              # Frees locks
         if (is_fail(ok)) {
            note (ok::message, priority='SEVERE', 
                  origin='imageviewersupport.makeDisplayPanel');
         }
#
         self->displaypanelisdone();
      }         
      its.whenevers.dp[widx] := last_whenever_executed(); widx +:= 1;
#
# Handle break event
#
      whenever its.dp.break->press do {
         self->breakfromviewer(T);
         its.dp.break->disabled(T);
      }
      its.whenevers.dp[widx] := last_whenever_executed(); widx +:= 1;
#
     return T;
   }


### Public methods


###
    const self.view := function(parent=F, raster=unset, contour=unset, 
                                vector=unset, marker=unset, region=unset, mask=unset, 
                                model=unset, adjust=F, axislabels=unset, includepix=unset,
                                activatebreak=unset, 
                                hasdismiss=T, order=unset)
    {
       wider its;
       its.parent := parent;
#
# Check region.  If it's unset, we get whatever there was last time.
#
       regionChanged := T;
       if (length(its.lastregion)==0) {
          region := defaultimagesupport.regioncheck(region, its.csys, torec=F);
          if (is_fail(region)) fail;
       } else {
         if (is_unset(region)) {
            region := its.lastregion;
            regionChanged := F;
         } else {
            region := defaultimagesupport.regioncheck(region, its.csys, torec=F);
            if (is_fail(region)) fail;
         }
       }
#
# Check mask.  mask operates a bit differently.  whatever value you give
# is honoured.  unset means no mask expressions.
#
       mask := defaultimagesupport.maskcheck(mask);
       if (is_fail(mask)) fail;
#
# Check axislabels.  If it's unset, we get whatever there was last time.
#
       axisLabelsChanged := T;
       if (is_unset(axislabels)) {
          axislabels := its.lastlabels;
          axisLabelsChanged := F;
       }
       its.lastlabels := axislabels;
#
# Check pixel range.  If it's unset, we get the full range
#
       if (!is_unset(includepix)) {
          ip := dms.tovector (includepix, 'float');
          if (is_fail(ip)) fail;
          if (length(ip)==1) {
             ip := [-abs(ip[1]), abs(ip[1])];
          }
          includepix := ip;
       }
#
       includepixChanged := F;
       if (is_unset(includepix) && is_unset(its.lastincludepix)) {
#
       } else {
          includepixChanged := !all(includepix==its.lastincludepix);
       }
       its.lastincludepix := includepix;
#
# Do we need to make the viewer ?  Either this is the first time, or the 
# user killed the viewer, the brute, somehow.
#
       if (!is_agent(its.viewer)) {
          title := spaste('view (', its.image.name(strippath=T), ')');
          its.viewer := viewer(title=title, widgetset=widgetset);
          if (is_fail(its.viewer)) {
             txt := spaste('Could not make a viewer.  It is possible that you do\n',
                           'not have the DISPLAY environment variable set. Otherwise\n',
                           its.viewer::message);
             fail txt;
          }
       }
#
# Do we need a new display panel ?  If parent changes, from agent to F or
# F to agent we remake it.  Kill off old one if need be. 
#
       parentChanged := F;
       if (has_field(its, 'parentIsAgent') && is_boolean(its.parentIsAgent)) {
          if ( (its.parentIsAgent==F && is_agent(its.parent))  ||
               (its.parentIsAgent==T && !is_agent(its.parent)) ) {
             parentChanged := T;
          }
       }
       if (is_agent(its.parent)) {
          its.parentIsAgent := T;
       } else {
          its.parentIsAgent := F;
       }
       if (!is_agent(its.dp.panel) || parentChanged) {
          ok := its.makeDisplayPanel (its.parent, hasdismiss);
          if (is_fail(ok)) fail;

# Make drawingdatadisplay and component list shower as needed

          if (is_agent(its.ddd)) {
             its.ddd.done();
          }
          its.ddd := its.dp.panel.annotationdd()
          if (is_agent(its.vscl)) {
             its.vscl.done();
          }
          its.vscl := viewershowcomponentlist(ddd=its.ddd, beam=theImage.restoringbeam());
       }
#
# De/activate the break button.  If unset, do nothing.
#
       if (is_unset(activatebreak)) {
       } else if (activatebreak==T) {
          its.dp.break->disabled(F);
          self->breakfromviewer(F);
       } else if (activatebreak==F) {
          its.dp.break->disabled(T);
          self->breakfromviewer(T);
       }
#
# Handle context dependent defaults for raster and contour arguments.  
# Because the user may have changed the registration via the GUI we 
# find out what is and isn't registered.  The raster and contour DDs 
# are always in existence
#
       isRasterRegistered := is_agent(its.raster.dd) && 
                             its.dp.panel.isregistered(its.raster.dd);
       isContourRegistered := is_agent(its.contour.dd) && 
                              its.dp.panel.isregistered(its.contour.dd);
       isVectorRegistered := is_agent(its.vector.dd) && 
                              its.dp.panel.isregistered(its.vector.dd);
       isMarkerRegistered := is_agent(its.marker.dd) && 
                              its.dp.panel.isregistered(its.marker.dd);
#
       if (is_unset(raster) && is_unset(contour) && is_unset(vector) && is_unset(marker)) {
          raster := F; contour := F; vector := F; marker := F;
          if (!isRasterRegistered && !isContourRegistered && !isVectorRegistered && !isMarkerRegistered) {
             raster := T;
          } else {
             if (isRasterRegistered) raster := T;
             if (isContourRegistered) contour := T;
             if (isVectorRegistered) vector := T;
             if (isMarkerRegistered) marker := T;
          }
       } else {
          if (is_unset(raster)) {
             raster := F;
             if (isRasterRegistered) raster := T;
          }         
          if (is_unset(contour)) {
             contour := F;
             if (isContourRegistered) contour := T;
          }
          if (is_unset(vector)) {
             vector:= F;
             if (isVectorRegistered) vector := T;
          }
          if (is_unset(marker)) {
             marker := F;
             if (isMarkerRegistered) vector := T;
          }
       }
#
       if (!is_boolean(raster)) {
          return throw ('The "raster" argument is invalid',
                        origin='imageviewersupport.view');
       }
       if (!is_boolean(contour)) {
          return throw ('The "contour" argument is invalid',
                        origin='imageviewersupport.view');
       }
       if (!is_boolean(vector)) {
          return throw ('The "vector" argument is invalid',
                        origin='imageviewersupport.view');
       }
       if (!is_boolean(marker)) {
          return throw ('The "marker" argument is invalid',
                        origin='imageviewersupport.view');
       }
#
# Make new raster and contour display datas as needed
# and set the options here
#
       ok := its.makeDD ('raster', raster, region, mask, axislabels, includepix,
                         regionChanged, axisLabelsChanged, includepixChanged);
       if (is_fail(ok)) fail;
       ok := its.makeDD ('contour', contour, region, mask, axislabels, includepix,
                         regionChanged, axisLabelsChanged, includepixChanged);
       if (is_fail(ok)) fail;
       ok := its.makeDD ('vector', vector, region, mask, axislabels, includepix, 
                         regionChanged, axisLabelsChanged, includepixChanged);
       if (is_fail(ok)) fail;
       ok := its.makeDD ('marker', marker, region, mask, axislabels, includepix, 
                         regionChanged, axisLabelsChanged, includepixChanged);
       if (is_fail(ok)) fail;
# 
# Set display order
#
       ok := its.orderDDs(order);
       if (is_fail(ok)) fail;
#
# Register DDs as required
#
       its.registerDD ('raster', raster);
       its.registerDD ('contour', contour);
       its.registerDD ('vector', vector);
       its.registerDD ('marker', marker);
#
# Show componentlist
#
       if (length(its.id) > 0) {
          its.vscl.hide(its.id);
       }
       if (!is_unset(model)) {
          its.id := its.vscl.show(list=model);
       } 
   
#
# Always remap the display panel
#
       its.dismissed := F;
       its.lastregion := region;
       its.lastmask := mask;
       its.dp.panel.gui();
#
# Make the adjust GUIs if needed (slow)
#
       if (adjust) its.dp.panel.adjust();
#
       return T;
   }

###
    const self.done := function()
    {
        wider its, self;
#
        local ok;
        if (length(its)>0) {
           if (is_agent(its.viewer)) {
              ok := its.deactivate(its.whenevers.dp);
              if (is_fail(ok)) {
                 note (ok::message, priority='SEVERE', origin='image.done');
                 note ('Trouble deactivating whenevers', priority='SEVERE', origin='imageviewersupport.done');
              }
              ok := its.viewer.done();            # Cleans up dp, dd
              if (is_fail(ok)) {
                 note (ok::message, priority='SEVERE', origin='image.done');
                 note ('Trouble destroying Viewer', priority='SEVERE', origin='imageviewersupport.done');
              }
           }
        }
#
# Delete the temporary image 
#
        ok := its.itp.done();
        if (is_fail(ok)) {
           note (ok::message, priority='SEVERE', origin='image.done');
           note ('Trouble deleting Temporary image', priority='SEVERE', origin='imageviewersupport.done');
        }

#
# Done internal copy of Coordinate System
#
        if (is_coordsys(its.csys)) {
           ok := its.csys.done();
           if (is_fail(ok)) {
              note (ok::message, priority='SEVERE', origin='image.done');
              note ('Trouble destroying Coordsys tool', priority='SEVERE', origin='imageviewersupport.done');
           }
        }
#
        if (is_agent(its.vscl)) {
           its.vscl.done();
        }
#
        val its := F;
        val self := F;
#
        return ok;
     }

###
   const self.signifyImageHasChanged := function ()
   {
      wider its;
#
# Delete any persistent image
#
      ok := its.itp.delete();
      if (is_fail(ok)) fail;
#
# Is there an active displaypanel ?
#
      alive := has_field(its, 'dp') && is_agent(its.dp.panel);
      if (!alive) return T;
#
# Force the DDs to be rebuilt.  
#
      its.lastmask := F;
      if (is_agent(its.raster.dd)) {
         ok := its.raster.dd.done();
         if (is_fail(ok)) fail;
      }
      if (is_agent(its.contour.dd)) {
         ok := its.contour.dd.done();
         if (is_fail(ok)) fail;
      }
      if (is_agent(its.vector.dd)) {
         ok := its.vector.dd.done();
         if (is_fail(ok)) fail;
      }
      if (is_agent(its.marker.dd)) {
         ok := its.marker.dd.done();
         if (is_fail(ok)) fail;
      }
#
# Redisplay ourselves
#
      ok := self.view(parent=its.parent);
      if (is_fail(ok)) fail;
#
      its.viewerDisEnable (F);
      return T;
   }
}
