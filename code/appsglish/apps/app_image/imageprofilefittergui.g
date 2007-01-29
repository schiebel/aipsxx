# imageprofilefittergui.g: Primary GUI for imageprofilefitter.g
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
#   $Id: imageprofilefittergui.g,v 19.2 2004/08/25 00:59:12 cvsmgr Exp $
#
#
#
#      Event              value               Description
#     position                             2D world coordinate of position 
#     region
#     mode                 mode             Selected mode
# 
pragma include once
include 'note.g'
include 'viewer.g'
include 'widgetserver.g'
include 'profilewidthentry.g'


const imageprofilefittergui := subsequence (parent=F, imageobject, widgetset=ddlws)
{
#
   its := [=];
#
   its.image := imageobject;                  # A reference
   its.csys := its.image.coordsys();
   if (is_fail(its.csys)) fail;
   its.profilewidthentry := [=];
   its.ws := widgetset;
#
   its.frames := [=];       # Frames
   its.frames.enabled := F;
#
   its.viewer := [=];
   its.dp := [=];           # Display panel
   its.dd := [=];           # Display data
#
   its.mode := [=];         # Interactive or auto menu
   its.method := "";        # Fit or Robust menu
   its.msg := '';           # Messageline widget
#
   its.position := [=];     # 
   its.position.event := [=]; # Last position event record
   its.position.busy := F;    # Are we already dealing with a position event
#
   its.handlePosition := [=];   # Callback
   its.handleRegion := [=];   # Callback
#
   its.region := [=];
   its.region.event := [=];   # Last region event record
   its.region.busy := F;
   its.regioncontrol := [=];  # What do with regions

### Private functions

###
   const its.makedd := function ()
   {
     wider its;

     if (length(its.dd) > 0) its.dd.done();
#
     its.dd := its.viewer.loaddata (its.image, 'raster');
     if (is_fail(its.dd)) fail;
#
     op := [=];
     op.xgridtype := 'Tick marks';
     op.ygridtype := 'Tick marks';
     op.axislabelswitch := T;
     op.labelcharsize.value := 1.0;
     ok := its.dd.setoptions(op);
     if (is_fail(ok)) fail;
#
     ok := its.dp.register (its.dd);
     if (is_fail(ok)) fail;
   }


###
   const its.postMessage := function (text)
   {
      wider its;
      its.msg->clear();
      its.msg->postnoforward(text);
      return T;
   }

###
    const its.pseudoPositionToWorld := function (pseudopositionvalue, ddoptions)
    {
       wider its;
#   
       axisNames := its.csys.names();        # World axis order
       if (is_fail(axisNames)) fail;
#
       xAxisName := ddoptions.xaxis.value;
       yAxisName := ddoptions.yaxis.value;
       worldAxes := [];
       i := 1;
       for (name in axisNames) {
          if (name==xAxisName) {
             worldAxes[1] := i;
          } else if (name==yAxisName) {
             worldAxes[2] := i;
          }
          i +:= 1;
       }
#
       xypos := pseudopositionvalue.world;
       xyposunits := pseudopositionvalue.units;
#
       u := its.csys.units();
       w := its.csys.referencevalue();
       q := dq.quantity(xypos[1], xyposunits[1]);
       w[worldAxes[1]] := dq.getvalue(dq.convert(q, u[worldAxes[1]]));
       q := dq.quantity(xypos[2], xyposunits[2]);
       w[worldAxes[2]] := dq.getvalue(dq.convert(q, u[worldAxes[2]]));
#
       p := its.csys.topixel (w);
       if (is_fail(p)) fail;
       r := its.csys.toworld(p, 'ms');
       if (is_fail(r)) fail;
#
       rec := [=];
       rec.measure := r.measure;
       rec.string := r.string;
       rec.width := its.profilewidthentry.getvalue().value;
#   
       return rec;
    }

### Public functions


###
   const self.done := function ()
   {
      wider its;
      wider self;

#  User could 'done' these via File menu

      if (is_agent(its.dd)) its.dd.done();
      if (is_agent(its.dp)) its.dp.done();
      if (is_agent(its.viewer)) its.viewer.done();

#      its.mode.done();
#      its.method.done();
#
      its.csys.done();
      its.msg.done();
      its.profilewidthentry.done();
#
      popupremove(its.frames);
      val its := F;
      val self := F;
#
      return T;
   }

###
   self.disable := function ()
   {
      wider its;
      if (its.frames.enabled) {
         its.frames.enabled := F;
         return its.frames.f0->disable();
      }
      return T;
   }

###
   self.dismiss := function ()
   {
      wider its;
      its.frames.f0->unmap();
   }

###
   self.gui := function ()
   {
      wider its;
      its.frames.f0->map();
   }

###
   self.enable := function ()
   {
      wider its;
      if (!its.frames.enabled) {
         its.frames.enabled := T;
         return its.frames.f0->enable();
      }
      return T;
   }

###
   const self.getmethod := function ()
   {
      wider its;
      return its.method.getvalue();   
   }

###
   const self.getmode := function ()
   {
      wider its;
      return its.mode.getvalue();
   }

###
   its.handlePositionEvent := function (eventValue)
   {
      wider its;
#
      options := its.dd.getoptions();
      if (is_fail(options)) fail;      

# Convert pseudo position to world position

      its.position.event := its.pseudoPositionToWorld (eventValue, options);
      if (is_fail(its.position.event)) fail;

# Handle through callback

      ok := its.handlePosition (its.position.event);
      if (is_fail(ok)) fail;
#
      return T;
   }



###
   its.handleRegionEvent := function (eventValue)
   {
      wider its;

# Convert pseudo to world region

      options := its.dd.getoptions();
      if (is_fail(options)) fail;
#
      its.region.event := [=];
      its.region.event.region := drm.pseudotoworldregion(its.image, eventValue, options);

# Are we averaging the profiles in the region

      doAverage := its.regioncontrol.getvalue();         

# Handle event through callback

      ok := its.handleRegion (doAverage, its.region.event);
      if (is_fail(ok)) fail;
#
      return T;
   }

###
   const self.setcallbacks := function (callback1=unset, callback2=unset)
   {
      wider its;
      if (!is_unset(callback1)) {
         its.handlePosition := callback1;
      }
      if (!is_unset(callback2)) {
         its.handleRegion := callback2;
      }
#
      return T;
   }


###
   const self.setimage := function (imageobject)
   {
      wider its;
#
      its.csys.done();
      its.image := imageobject;    # Reference
      its.csys := its.image.coordsys();
      if (is_fail(its.csys)) fail;
#
      return its.makedd();
   }


### Constructor 

   if (!have_gui()) {
      return throw ('No display is currently available (is DISPLAY set ?)',
                     origin='imageprofilefittergui.g');
   }
# 
   its.image := imageobject;                  # A reference
   its.csys := its.image.coordsys();
   if (is_fail(its.csys)) fail;

# Make viewer and set profile button to be active

   its.ws.tk_hold();
   its.viewer := viewer(widgetset=its.ws, deleteatexit=F);
   if (is_fail(its.viewer)) fail;
   toolKit := its.viewer.toolkit();
   toolKit.toolkitchange([key='Button 3', tool='Positioning']);

# See if we need a private color map or not by making a dummy displaypanel 

   newcmap := F;
   its.dp := its.viewer.newdisplaypanel(show=F, newcmap=unset);
   if (!is_fail(its.dp)) { 
       newcmap := its.dp.newcmap();
       its.dp.done();
   } else {
       its.ws.tk_release();
       return throw('Unable to make any viewer displaypanels',
                    origin='imageprofilefittergui.g');
   }

# Main frame

   its.frames.f0 := its.ws.frame(parent, expand='both', side='top',
                                 title='Image Profile Fitter', relief='raised',
                                 newcmap=newcmap);
   if (!is_agent(parent) && !parent) its.frames.f0->unmap();
   its.ws.tk_release();

# Frame for image display

   its.frames.f0.f0 := its.ws.frame(its.frames.f0, side='top');

# Menubar

   its.frames.f0.f0.menubar := its.ws.frame(its.frames.f0.f0, side='left',
                                             relief='raised', expand='x');
#
   its.frames.f0.f0.menubar.file  := its.ws.button(its.frames.f0.f0.menubar, type='menu',
                                                    text='File', relief='flat');
   t := its.ws.resources('button', 'dismiss');
   its.frames.f0.f0.menubar.file.dismiss := its.ws.button(its.frames.f0.f0.menubar.file,
                                                   text='Dismiss window', background=t.background,
                                                   foreground=t.foreground);
   whenever its.frames.f0.f0.menubar.file.dismiss->press do {
      self.dismiss();
   }
   t := its.ws.resources('button', 'halt');
   its.frames.f0.f0.menubar.file.done := its.ws.button(its.frames.f0.f0.menubar.file,
                                                   text='Done window & tool', background=t.background,
                                                   foreground=t.foreground);
   whenever its.frames.f0.f0.menubar.file.done->press do {
      self->done();
      self.done();
   }
#
   its.frames.f0.f0.menubar.spacer := its.ws.frame(its.frames.f0.f0.menubar, expand='x',
                                                    height=1);
#
   its.frames.f0.f0.menubar.help := its.ws.helpmenu(parent=its.frames.f0.f0.menubar,
                              menuitems="Imageprofilefitter Images Viewer",
                              refmanitems=['Refman:imageprofilefitter', 'Refman:images', 'Refman:viewer'],
                              helpitems=['about the imagefitter','about images', 'about the Viewer']);

# Make display panel   

   its.dp := its.viewer.newdisplaypanel(parent=its.frames.f0.f0, hasdismiss=F, 
                                        hasdone=F, hasgui=T, guihastracking=T,
                                        guihasmenubar=F,
                                        guihasanimator=F,
                                        height=350, width=350);
   if (is_fail(its.dp)) fail;

# Make and register DisplayData

   ok := its.makedd();
   if (is_fail(ok)) fail;

#
   its.frames.f0.f1 := its.ws.frame(its.frames.f0, side='left', expand='x');
#
# Profile width control

   its.profilewidthentry := profilewidthentry(its.frames.f0.f1, relief='raised', 
                                              width=10, widgetset=its.ws);
   if (is_fail(its.profilewidthentry)) fail;

# Handle <CR> in width entry. Just poke in the new width and
# reemit the position event.

   whenever its.profilewidthentry->value do {
      if (length(its.position.event) > 0) {         # event has been previously stored
         its.position.event.width := $value;
         ok := its.handlePosition (its.position.event);
         if (is_fail(ok)) {
            note(ok::message, priority='SEVERE',
                 origin='imageprofilefittergui.g');
         }
      }
   }

# Menu to control whether the profile is formed from an average of
# the region, or whether all profiles in region are fit

   its.frames.f0.f1.f0 := its.ws.frame(its.frames.f0.f1, side='top', expand='x', relief='raised');
   its.frames.f0.f1.label := its.ws.label(its.frames.f0.f1.f0, 'Region Usage');
   longTxt := spaste ('When you generate a region, you can either\n',
                      'average the spectrum in the region over the \n',
                      'displayed axes, or fit each profile in the \n',
                      'region and write out images of the fit and \n',
                      'residual.  This menu lets you control this choice');
   its.ws.popuphelp(its.frames.f0.f1.label, longTxt, 
                    'Average profiles in region or fit each separately', combi=T);
   its.regioncontrol := its.ws.optionmenu(its.frames.f0.f1.f0,
                                          labels=['Average', 'Fit All'],
                                          values=[T,F]);
   whenever its.regioncontrol->select do {
      if (length(its.region.event) > 0) {
         doAverage := its.regioncontrol.getvalue();         
         ok := its.handleRegion (doAverage, its.region.event);
         if (is_fail(ok)) {
            note(ok::message, priority='SEVERE',
                 origin='imageprofilefittergui.g');
         }
      }
   }
#
#   its.frames.f0.f1.spacer := its.ws.frame(its.frames.f0.f1, side='left', expand='x', width=10);

# Frame for mode/method

   its.frames.f0.f2 := its.ws.frame(its.frames.f0, side='top', relief='raised', expand='x');

# Mode menu

#   its.frames.f0.f2.f0 := its.ws.frame(its.frames.f0.f2, side='left')
#   its.frames.f0.f2.f0.f0 := its.ws.frame(its.frames.f0.f2.f0, side='top')
#   l1 := its.ws.label (its.frames.f0.f2.f0.f0, 'Mode');
#   its.mode := its.ws.optionmenu (its.frames.f0.f2.f0.f0, labels="Interactive Automatic",
#                                  values="interactive automatic");
#   its.mode := its.ws.optionmenu (its.frames.f0.f2.f0.f0, labels="Interactive",
#                                  values="interactive");
# Method menu

#   its.frames.f0.f2.f0.f1 := its.ws.frame(its.frames.f0.f2.f0, side='top')
#   l2 := its.ws.label (its.frames.f0.f2.f0.f1, 'Method');
#   its.method := its.ws.optionmenu (its.frames.f0.f2.f0.f1, labels="Fit Robust",
#                                    values="fit robust");
#   its.method := its.ws.optionmenu (its.frames.f0.f2.f0.f1, labels="Fit",
#                                    values="fit");

# Message line, done button

   its.frames.f0.f2.f1 := its.ws.frame(its.frames.f0.f2, side='left', expand='x');
   its.msg := its.ws.messageline(its.frames.f0.f2.f1, width=50);
   its.postMessage('Select region/position & emit (double click within)');
#
   its.frames.f0.f2.f1.spacer := widgetset.frame(its.frames.f0.f2.f1, width=1, 
                                                 expand='x', height=1);
   its.done := its.ws.button (its.frames.f0.f2.f1, text='Done', type='halt');
   widgetset.popuphelp(its.done, 'Destroy this GUI and its parent imageprofilefitter tool');
   whenever its.done->press do {
      self->done();
      self.done();
   }

# Handle mode change

#   whenever its.mode->select do {
#      if ($value.value=='automatic') {
#         its.postMessage('Select region and emit (double click)');
#      } else {
#         its.postMessage('Select position and emit (double click)');
#      }
#   }

# Handle pseudoregion event

   whenever its.dp->pseudoregion do {
      if(!its.region.busy) {
         its.region.busy := T;
         ok := its.handleRegionEvent ($value);
         if (is_fail(ok)) {
            note(ok::message, priority='SEVERE',
                 origin='imageprofilefittergui.g');
         }
         its.region.busy := F;
      }
   }

# Handle position event

   whenever its.dp->pseudoposition do {
      if(!its.position.busy && $value.evtype!='up') {
         its.position.busy := T;
         ok := its.handlePositionEvent ($value);
         if (is_fail(ok)) {
            note(ok::message, priority='SEVERE',
                 origin='imageprofilefittergui.g');
         }
         its.position.busy := F;
      }
   }
#
   ok := its.frames.f0->map();
}
